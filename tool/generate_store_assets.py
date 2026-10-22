#!/usr/bin/env python3
"""Draws the Google Play listing graphics in the app icon's style.

    python3 tool/generate_store_assets.py

Writes store/play/icon-512.png (the hi-res app icon: 512x512, full bleed,
Play rounds the corners itself) and store/play/feature-graphic.png (the
1024x500 banner, no transparency).
"""

from PIL import Image, ImageDraw, ImageFilter, ImageFont

from generate_brand_icons import (
    GOLD, GOLD_LIGHT, GOLD_MID, INK, MASTER, RED, ROOT, WHITE, WORD_FONT,
    badge, diagonal_gradient,
)

OUT = ROOT / 'store/play'
BODY_FONT = ROOT / 'assets/fonts/HankenGrotesk-500.ttf'
ICON_FONT = ROOT / 'assets/fonts/MaterialSymbolsOutlined.ttf'

# lib/widgets/category_card.dart accents, with the category icons beside them.
TILES = [
    ('', (0x2E, 0x9E, 0x5B)),  # sports_esports
    ('', (0xC6, 0x28, 0x28)),  # trophy
    ('', (0xE0, 0x7A, 0x1F)),  # chess
    ('', (0xA3, 0x19, 0x5B)),  # sports_soccer
    ('', (0xB8, 0x91, 0x3F)),  # bolt
    ('', (0x2E, 0x9E, 0x5B)),  # magic_button
]


def play_icon():
    """Full-bleed square: Play masks it, so no corners or outer shadow."""
    img = diagonal_gradient((MASTER, MASTER), [GOLD, GOLD_MID, GOLD_LIGHT]).convert('RGBA')
    img.alpha_composite(badge(MASTER, MASTER * 0.66, MASTER * 0.41))
    return img.resize((512, 512), Image.LANCZOS).convert('RGB')


def tile(size, glyph, accent):
    """A white rounded card with a category icon, like the Home chips."""
    pad = round(size * 0.18)
    img = Image.new('RGBA', (size + pad * 2, size + pad * 2), (0, 0, 0, 0))
    box = [pad, pad, pad + size, pad + size]
    shadow = Image.new('RGBA', img.size, (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle(
        [box[0], box[1] + size * 0.06, box[2], box[3] + size * 0.06],
        size * 0.28, fill=(90, 66, 32, 60),
    )
    img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(size * 0.07)))
    draw = ImageDraw.Draw(img)
    draw.rounded_rectangle(box, size * 0.28, fill=WHITE + (255,))
    disc = size * 0.66
    c = pad + size / 2
    draw.ellipse([c - disc / 2, c - disc / 2, c + disc / 2, c + disc / 2],
                 fill=accent + (36,))
    font = ImageFont.truetype(str(ICON_FONT), round(size * 0.44))
    draw.text((c, c), glyph, font=font, fill=accent, anchor='mm')
    return img


def feature_graphic():
    w, h = 1024, 500
    scale = 2  # draw large, shrink once: smoother edges and text
    W, H = w * scale, h * scale
    img = diagonal_gradient((W // 4, H // 4), [GOLD, GOLD_MID, GOLD_LIGHT])
    img = img.resize((W, H), Image.BILINEAR).convert('RGBA')

    # Soft light rings behind the tiles, echoing the round badge.
    glow = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    g = ImageDraw.Draw(glow)
    for cx, cy, r, a in [(1560, 500, 520, 70), (1560, 500, 360, 60), (1900, 120, 220, 50)]:
        g.ellipse([cx - r, cy - r, cx + r, cy + r], fill=WHITE + (a,))
    img = Image.alpha_composite(img, glow.filter(ImageFilter.GaussianBlur(6)))

    # Category tiles, scattered on the right like a game shelf.
    for (glyph, accent), (x, y, s) in zip(TILES, [
        (1330, 170, 230), (1620, 300, 270), (1380, 520, 210),
        (1700, 640, 180), (1850, 140, 160), (1190, 420, 150),
    ]):
        t = tile(s, glyph, accent)
        img.alpha_composite(t, (x - t.width // 2 + s // 2, y - t.height // 2 + s // 2))

    # Left: badge, wordmark, tagline.
    left = 110
    mark = 260
    img.alpha_composite(badge(mark, mark * 0.92, mark * 0.58, shadow=True),
                        (left - 10, 150))
    draw = ImageDraw.Draw(img)
    word = ImageFont.truetype(str(WORD_FONT), 132)
    y = 440
    draw.text((left, y), 'Gudang', font=word, fill=INK)
    draw.text((left + word.getlength('Gudang'), y), 'Games', font=word, fill=RED)
    body = ImageFont.truetype(str(BODY_FONT), 56)
    draw.text((left + 4, 620), 'Puluhan game seru,', font=body, fill=INK + (215,))
    draw.text((left + 4, 690), 'main langsung di satu aplikasi', font=body, fill=INK + (215,))

    # Red pill, like the Play Now button.
    pill = ImageFont.truetype(str(WORD_FONT), 46)
    label = 'Main Sekarang'
    pw = round(pill.getlength(label)) + 130
    px, py, ph = left, 800, 104
    draw.rounded_rectangle([px, py, px + pw, py + ph], ph / 2, fill=RED + (255,))
    icon = ImageFont.truetype(str(ICON_FONT), 56)
    draw.text((px + 58, py + ph / 2), '', font=icon, fill=WHITE, anchor='mm')
    draw.text((px + 96, py + ph / 2), label, font=pill, fill=WHITE, anchor='lm')

    return img.resize((w, h), Image.LANCZOS).convert('RGB')


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    play_icon().save(OUT / 'icon-512.png', optimize=True)
    feature_graphic().save(OUT / 'feature-graphic.png', optimize=True)


if __name__ == '__main__':
    main()
