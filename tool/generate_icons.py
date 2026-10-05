#!/usr/bin/env python3
"""Generate every launcher/app icon from the extracted brand logo.

Run after tool/extract_logo.py:

    tool/extract_logo.py <source.png> assets/brand/logo.png
    tool/generate_icons.py

The wordmark is far too wide to survive a 48dp launcher icon, so the icons use
only the "G" mark cropped from the same artwork. The full lockup stays for
in-app use.
"""

import json
import pathlib

from PIL import Image, ImageDraw, ImageFilter

ROOT = pathlib.Path(__file__).resolve().parent.parent
LOGO = ROOT / "assets" / "brand" / "logo.png"
MARK = ROOT / "assets" / "brand" / "logo_mark.png"
LOCKUP = ROOT / "assets" / "brand" / "logo_lockup.png"

# x=279 is the gap between the mark and the wordmark in logo.png.
MARK_RIGHT = 279
MARK_INSET = 40  # skip the sign's own frame

BACKGROUND = (11, 19, 38)  # #0B1326, the app background
GLOW = (124, 58, 237)  # #7C3AED


def load_mark() -> Image.Image:
    logo = Image.open(LOGO).convert("RGBA")
    region = logo.crop(
        (MARK_INSET, MARK_INSET, MARK_RIGHT, logo.height - MARK_INSET)
    )
    bbox = region.getchannel("A").point(lambda v: 255 if v > 110 else 0).getbbox()
    mark = region.crop(bbox) if bbox else region
    mark.save(MARK)
    return mark


def save_lockup() -> None:
    """The sign's contents without its frame — legible in a 36px header,
    where the framed lockup would shrink the wordmark to nothing."""
    logo = Image.open(LOGO).convert("RGBA")
    inner = logo.crop(
        (MARK_INSET + 2, MARK_INSET + 2, logo.width - MARK_INSET - 2,
         logo.height - MARK_INSET - 2)
    )
    bbox = inner.getchannel("A").point(lambda v: 255 if v > 110 else 0).getbbox()
    if bbox:
        pad = 6
        inner = inner.crop(
            (
                max(0, bbox[0] - pad),
                max(0, bbox[1] - pad),
                min(inner.width, bbox[2] + pad),
                min(inner.height, bbox[3] + pad),
            )
        )
    inner.save(LOCKUP)
    print(f"lockup {inner.size[0]}x{inner.size[1]} -> {LOCKUP.relative_to(ROOT)}")


def canvas(size: int, mark: Image.Image, *, scale: float, opaque: bool) -> Image.Image:
    """Mark centred on the brand background, occupying `scale` of the side."""
    base = Image.new("RGBA", (size, size), (*BACKGROUND, 255 if opaque else 0))

    # Soft violet bloom so the icon does not read as a flat dark square.
    if opaque:
        bloom = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(bloom)
        r = size * 0.34
        draw.ellipse(
            (size / 2 - r, size / 2 - r, size / 2 + r, size / 2 + r),
            fill=(*GLOW, 90),
        )
        bloom = bloom.filter(ImageFilter.GaussianBlur(size * 0.11))
        base.alpha_composite(bloom)

    target = size * scale
    ratio = min(target / mark.width, target / mark.height)
    w, h = max(1, round(mark.width * ratio)), max(1, round(mark.height * ratio))
    resized = mark.resize((w, h), Image.LANCZOS)
    base.alpha_composite(resized, (round((size - w) / 2), round((size - h) / 2)))
    return base


def monochrome(size: int, mark: Image.Image, scale: float) -> Image.Image:
    """White silhouette on transparent, for Android 13+ themed icons."""
    base = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    target = size * scale
    ratio = min(target / mark.width, target / mark.height)
    w, h = max(1, round(mark.width * ratio)), max(1, round(mark.height * ratio))
    resized = mark.resize((w, h), Image.LANCZOS)
    white = Image.new("RGBA", resized.size, (255, 255, 255, 0))
    white.putalpha(resized.getchannel("A"))
    base.alpha_composite(white, (round((size - w) / 2), round((size - h) / 2)))
    return base


def write(path: pathlib.Path, image: Image.Image, *, flatten: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if flatten:
        flat = Image.new("RGB", image.size, BACKGROUND)
        flat.paste(image, mask=image.getchannel("A"))
        flat.save(path)
    else:
        image.save(path)
    print(f"  {path.relative_to(ROOT)}  {image.size[0]}px")


def android(mark: Image.Image) -> None:
    res = ROOT / "android" / "app" / "src" / "main" / "res"
    densities = {
        "mdpi": 1.0,
        "hdpi": 1.5,
        "xhdpi": 2.0,
        "xxhdpi": 3.0,
        "xxxhdpi": 4.0,
    }

    print("android launcher icons")
    for name, factor in densities.items():
        legacy = round(48 * factor)
        write(
            res / f"mipmap-{name}" / "ic_launcher.png",
            canvas(legacy, mark, scale=0.62, opaque=True),
        )

        # Adaptive layers are 108dp; only the middle 66dp is guaranteed visible.
        adaptive = round(108 * factor)
        write(
            res / f"drawable-{name}" / "ic_launcher_foreground.png",
            canvas(adaptive, mark, scale=0.40, opaque=False),
        )
        write(
            res / f"drawable-{name}" / "ic_launcher_monochrome.png",
            monochrome(adaptive, mark, 0.40),
        )

    # Android 12+ draws the splash itself and ignores the bitmap layer of
    # windowBackground, so the splash icon is a separate drawable. The system
    # reserves a 288dp canvas with roughly the middle two thirds visible.
    for name, factor in densities.items():
        write(
            res / f"drawable-{name}" / "splash_icon.png",
            canvas(round(288 * factor), mark, scale=0.42, opaque=False),
        )

    (res / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
    (res / "mipmap-anydpi-v26" / "ic_launcher.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        '<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n'
        '    <background android:drawable="@color/ic_launcher_background" />\n'
        '    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n'
        '    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />\n'
        "</adaptive-icon>\n"
    )
    print("  mipmap-anydpi-v26/ic_launcher.xml")

    (res / "values" / "ic_launcher_background.xml").write_text(
        '<?xml version="1.0" encoding="utf-8"?>\n'
        "<resources>\n"
        '    <color name="ic_launcher_background">#0B1326</color>\n'
        "</resources>\n"
    )
    print("  values/ic_launcher_background.xml")


def ios(mark: Image.Image) -> None:
    appicon = (
        ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset"
    )
    contents = json.loads((appicon / "Contents.json").read_text())

    print("ios app icons")
    seen = set()
    for entry in contents["images"]:
        name = entry["filename"]
        if name in seen:
            continue
        seen.add(name)
        base = float(entry["size"].split("x")[0])
        px = round(base * float(entry["scale"].rstrip("x")))
        # iOS icons must not carry an alpha channel.
        write(appicon / name, canvas(px, mark, scale=0.62, opaque=True), flatten=True)


def web(mark: Image.Image) -> None:
    icons = ROOT / "web" / "icons"
    print("web icons")
    for size in (192, 512):
        write(icons / f"Icon-{size}.png", canvas(size, mark, scale=0.62, opaque=True))
        # Maskable icons are cropped to a circle: keep the mark well inside.
        write(
            icons / f"Icon-maskable-{size}.png",
            canvas(size, mark, scale=0.44, opaque=True),
        )
    write(ROOT / "web" / "favicon.png", canvas(32, mark, scale=0.70, opaque=True))


def main() -> None:
    mark = load_mark()
    print(f"mark {mark.size[0]}x{mark.size[1]} -> {MARK.relative_to(ROOT)}")
    save_lockup()
    print()
    android(mark)
    ios(mark)
    web(mark)


if __name__ == "__main__":
    main()
