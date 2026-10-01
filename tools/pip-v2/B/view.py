#!/usr/bin/env python3
"""Big QA render: cairosvg at exact size, side by side, light/dark halves, 48px chip."""
import io, os, sys
import cairosvg
from PIL import Image

d = sys.argv[1]; out = sys.argv[2]; cell = int(sys.argv[3]) if len(sys.argv) > 3 else 400
names = sys.argv[4:] or sorted(f for f in os.listdir(d) if f.endswith('.svg'))
CELL_SVG = 240
LIGHT = (251, 247, 240, 255); DARK = (21, 19, 31, 255)

def png(path, size):
    b = cairosvg.svg2png(url=path, write_to=None, output_width=size, output_height=size,
                        background_color=None)
    return Image.open(io.BytesIO(b)).convert('RGBA')

tiles = []
for n in names:
    p = os.path.join(d, n)
    big = png(p, cell)
    half = cell // 2
    t = Image.new('RGBA', (cell, cell), LIGHT)
    t.paste(Image.new('RGBA', (cell, half), DARK), (0, half))
    t.paste(big, (0, 0), big)
    chip = Image.new('RGBA', (48, 48), (124, 108, 242, 255))
    s = png(p, 44); chip.paste(s, (2, 2), s)
    t.paste(chip, (4, 4), chip)
    tiles.append(t)

W = cell * len(tiles); H = cell + 22
sheet = Image.new('RGBA', (W, H), (255, 255, 255, 255))
from PIL import ImageDraw, ImageFont
d_ = ImageDraw.Draw(sheet)
try: f = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 13)
except Exception: f = ImageFont.load_default()
for i, (n, t) in enumerate(zip(names, tiles)):
    d_.rectangle([i * cell, 0, i * cell + cell, 22], fill=(233, 228, 247, 255))
    d_.text((i * cell + 6, 5), n.replace('.svg', ''), font=f, fill=(30, 27, 58, 255))
    sheet.paste(t, (i * cell, 22))
sheet.convert('RGB').save(out)
print('view', out, sheet.size)
