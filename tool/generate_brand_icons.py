#!/usr/bin/env python3
"""Draws every GudangGames icon from one design: a "GG" monogram on a white
disc over the gold header gradient. The first G is ink and the second red,
as the in-app wordmark writes "Gudang" and "Games", in the same Sora Bold.

    python3 tool/generate_brand_icons.py

Needs Pillow. Writes the Android launcher, adaptive and splash images, the
web icons, assets/brand/, and the backend's favicon and site logos.
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / 'android/app/src/main/res'
WORD_FONT = ROOT / 'assets/fonts/Sora-700.ttf'

# lib/theme/app_colors.dart
GOLD = (0xD9, 0xBC, 0x80)
GOLD_MID = (0xE6, 0xCF, 0x9C)
GOLD_LIGHT = (0xF3, 0xE4, 0xBF)
INK = (0x22, 0x1C, 0x15)
RED = (0xB3, 0x19, 0x1E)
WHITE = (255, 255, 255)

MASTER = 1024
DENSITIES = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}


def lerp(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def diagonal_gradient(size, stops):
    """Top-left to bottom-right, like TopBar.gradient."""
    w, h = size
    img = Image.new('RGB', size)
    px = img.load()
    for y in range(h):
        for x in range(w):
            t = (x + y) / (w + h - 2)
            for i in range(len(stops) - 1):
                lo, hi = i / (len(stops) - 1), (i + 1) / (len(stops) - 1)
                if t <= hi:
                    px[x, y] = lerp(stops[i], stops[i + 1], (t - lo) / (hi - lo))
                    break
    return img


def monogram(size, first=INK, second=RED):
    """"GG" in Sora Bold, centred in a size² square: the first G in ink and
    the second in red, as the wordmark writes "Gudang" and "Games"."""
    font = ImageFont.truetype(str(WORD_FONT), round(size * 0.66))
    overlap = size * 0.015  # tight, so the two letters read as one mark
    g_left, g_top, g_right, g_bottom = font.getbbox('G')
    g_w = g_right - g_left
    total = g_w * 2 - overlap
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    x = (size - total) / 2 - g_left
    y = (size - (g_bottom - g_top)) / 2 - g_top
    draw.text((x, y), 'G', font=font, fill=first)
    draw.text((x + g_w - overlap, y), 'G', font=font, fill=second)
    return img


def badge(canvas, disc, glyph, shadow=True):
    """White disc with the GG mark, centred on a transparent canvas² square."""
    img = Image.new('RGBA', (canvas, canvas), (0, 0, 0, 0))
    c = canvas / 2
    box = [c - disc / 2, c - disc / 2, c + disc / 2, c + disc / 2]
    if shadow:
        blur = Image.new('RGBA', img.size, (0, 0, 0, 0))
        offset = disc * 0.03
        ImageDraw.Draw(blur).ellipse(
            [box[0], box[1] + offset, box[2], box[3] + offset],
            fill=(90, 66, 32, 70),
        )
        img = Image.alpha_composite(img, blur.filter(ImageFilter.GaussianBlur(disc * 0.04)))
    ImageDraw.Draw(img).ellipse(box, fill=WHITE + (255,))
    art = monogram(round(glyph))
    img.alpha_composite(art, (round(c - glyph / 2), round(c - glyph / 2)))
    return img


def save(img, path, size):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.resize((size, size), Image.LANCZOS).save(path)


def rounded_square(img, radius):
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.size[0] - 1, img.size[1] - 1], radius, fill=255)
    out = img.convert('RGBA')
    out.putalpha(mask)
    return out


def main():
    gold = diagonal_gradient((MASTER, MASTER), [GOLD, GOLD_MID, GOLD_LIGHT])

    # Adaptive foreground: a 108dp canvas whose middle 66dp always shows.
    foreground = badge(MASTER, MASTER * 52 / 108, MASTER * 33 / 108)
    # Monochrome: the system tints it, so only the shape matters.
    mono = Image.new('RGBA', (MASTER, MASTER), (0, 0, 0, 0))
    glyph = round(MASTER * 46 / 108)
    mono.alpha_composite(monogram(glyph, WHITE, WHITE),
                         ((MASTER - glyph) // 2, (MASTER - glyph) // 2))
    # Legacy launchers draw the file as it is: the whole icon, shape included.
    legacy = gold.convert('RGBA')
    legacy.alpha_composite(badge(MASTER, MASTER * 0.64, MASTER * 0.40))
    legacy = rounded_square(legacy, MASTER * 0.22)
    # Android 12 splash: a 288dp image of which the middle 192dp circle shows.
    splash = badge(MASTER, MASTER * 168 / 288, MASTER * 104 / 288)

    for name, scale in DENSITIES.items():
        save(foreground, RES / f'drawable-{name}/ic_launcher_foreground.png', round(108 * scale))
        save(mono, RES / f'drawable-{name}/ic_launcher_monochrome.png', round(108 * scale))
        save(splash, RES / f'drawable-{name}/splash_icon.png', round(288 * scale))
        save(legacy, RES / f'mipmap-{name}/ic_launcher.png', round(48 * scale))

    # Web: plain icons carry their own shape, maskable ones fill the square.
    save(legacy, ROOT / 'web/icons/Icon-192.png', 192)
    save(legacy, ROOT / 'web/icons/Icon-512.png', 512)
    maskable = gold.convert('RGBA')
    maskable.alpha_composite(badge(MASTER, MASTER * 0.56, MASTER * 0.35))
    save(maskable, ROOT / 'web/icons/Icon-maskable-192.png', 192)
    save(maskable, ROOT / 'web/icons/Icon-maskable-512.png', 512)
    save(legacy, ROOT / 'web/favicon.png', 64)

    # In-app brand files: the round mark, and the white wordmark pill.
    save(legacy, ROOT / 'assets/brand/logo.png', 512)
    save(badge(MASTER, MASTER * 0.92, MASTER * 0.58, shadow=False), ROOT / 'assets/brand/logo_mark.png', 512)
    lockup().save(ROOT / 'assets/brand/logo_lockup.png')

    # The backend's landing page and admin: favicon and site logos.
    site = ROOT / 'backend/public'
    save(legacy, site / 'images/site/logo-mark.png', 256)
    lockup().save(site / 'images/site/logo-lockup.png')
    legacy.resize((256, 256), Image.LANCZOS).save(
        site / 'favicon.ico', sizes=[(16, 16), (32, 32), (48, 48), (64, 64)],
    )


def lockup():
    """"GudangGames" in a white pill, led by the GG mark on a gold disc."""
    h = 256
    font = ImageFont.truetype(str(WORD_FONT), round(h * 0.42))
    gudang_w = font.getlength('Gudang')
    games_w = font.getlength('Games')
    glyph = round(h * 0.52)
    pad_l, gap, pad_r = h * 0.30, h * 0.14, h * 0.40
    w = round(pad_l + glyph + gap + gudang_w + games_w + pad_r)
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(img).rounded_rectangle([0, 0, w - 1, h - 1], h / 2, fill=WHITE + (255,))
    disc = diagonal_gradient((glyph, glyph), [GOLD, GOLD_MID, GOLD_LIGHT]).convert('RGBA')
    round_mask = Image.new('L', (glyph, glyph), 0)
    ImageDraw.Draw(round_mask).ellipse([0, 0, glyph - 1, glyph - 1], fill=255)
    disc.putalpha(round_mask)
    inner = round(glyph * 0.8)
    disc.alpha_composite(monogram(inner), ((glyph - inner) // 2, (glyph - inner) // 2))
    img.alpha_composite(disc, (round(pad_l), (h - glyph) // 2))
    draw = ImageDraw.Draw(img)
    x = pad_l + glyph + gap
    _, top, _, bottom = font.getbbox('GudangGames')
    y = (h - (bottom - top)) / 2 - top
    draw.text((x, y), 'Gudang', font=font, fill=INK)
    draw.text((x + gudang_w, y), 'Games', font=font, fill=RED)
    return img


if __name__ == '__main__':
    main()
