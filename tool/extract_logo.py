#!/usr/bin/env python3
"""Recover the BandarGames logo from a checkerboard-backed PNG.

The supplied artwork has no alpha channel: the "transparency" checkerboard is
painted into the RGB pixels. Every pixel is the logo composited over a known
grey:

    P = C*a + B*(1-a)

B is reconstructed analytically from the checker geometry, including the
anti-aliased cell borders — a hard two-level model leaves a visible grid of
ghost lines exactly where the borders fall. Alpha is then how far the pixel
rises above its own background, and the colour is un-premultiplied.

Usage: tool/extract_logo.py <source.png> <out_rgba.png>
"""

import sys

from PIL import Image

# Measured from pure-background regions of the source.
DARK = 4.1
LIGHT = 99.3
CELLS = 50  # checker cells across the image
EDGE_SOFT = 1.3  # px of anti-aliasing on a cell border
NOISE_FLOOR = 7  # levels of render noise on the flat background
ALPHA_FLOOR = 0.18  # below this the signal is residual checker, not artwork
CROP_MARGIN = 4  # px of breathing room kept around the sign


def _ramp(pos: float, cell: float) -> float:
    """Smoothed indicator of "second half of the 2-cell period"."""
    period = 2 * cell
    t = pos % period

    def edge(distance: float) -> float:
        # 0 -> 1 across EDGE_SOFT pixels, centred on the border.
        return min(1.0, max(0.0, 0.5 + distance / EDGE_SOFT))

    if t < cell:
        # Rising across the border at 0, falling across the one at `cell`.
        return edge(t) * edge(cell - t)
    return 1.0 - edge(t - cell) * edge(period - t)


def background(x: float, y: float, cell: float) -> float:
    u = _ramp(x, cell)
    v = _ramp(y, cell)
    # XOR for continuous values: 1 where exactly one axis is in its high half.
    checker = u + v - 2 * u * v
    return DARK + (LIGHT - DARK) * checker


def extract(src_path: str) -> Image.Image:
    src = Image.open(src_path).convert("RGB")
    w, h = src.size
    cell = w / CELLS
    px = src.load()

    out = Image.new("RGBA", (w, h))
    op = out.load()

    # The pattern only depends on position within one 2-cell period.
    ramp_x = [_ramp(x + 0.5, cell) for x in range(w)]
    ramp_y = [_ramp(y + 0.5, cell) for y in range(h)]

    for y in range(h):
        v = ramp_y[y]
        for x in range(w):
            u = ramp_x[x]
            b = DARK + (LIGHT - DARK) * (u + v - 2 * u * v)

            r, g, bl = px[x, y]
            rise = max(r, g, bl) - b - NOISE_FLOOR
            if rise <= 0:
                op[x, y] = (0, 0, 0, 0)
                continue

            a = min(rise / (255.0 - b - NOISE_FLOOR), 1.0)

            # Residual checker never exceeds alpha ~0.15 while the artwork
            # sits well above 0.6, so a floor clears the last of the grid.
            a = (a - ALPHA_FLOOR) / (1.0 - ALPHA_FLOOR)
            if a <= 0:
                op[x, y] = (0, 0, 0, 0)
                continue

            keep = b * (1.0 - a)
            op[x, y] = (
                max(0, min(255, int(round((r - keep) / a)))),
                max(0, min(255, int(round((g - keep) / a)))),
                max(0, min(255, int(round((bl - keep) / a)))),
                int(round(a * 255)),
            )

    return out


def main() -> None:
    if len(sys.argv) != 3:
        print(__doc__)
        raise SystemExit(2)

    logo = extract(sys.argv[1])

    # Crop to the solid sign. A loose threshold would keep the outermost
    # halo, which the alpha floor has already chopped into dashes.
    mask = logo.getchannel("A").point(lambda v: 255 if v > 120 else 0)
    bbox = mask.getbbox()
    if bbox:
        left, top, right, bottom = bbox
        logo = logo.crop(
            (
                max(0, left - CROP_MARGIN),
                max(0, top - CROP_MARGIN),
                min(logo.width, right + CROP_MARGIN),
                min(logo.height, bottom + CROP_MARGIN),
            )
        )
    logo.save(sys.argv[2])
    print(f"wrote {sys.argv[2]} {logo.size}")


if __name__ == "__main__":
    main()
