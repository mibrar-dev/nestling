#!/usr/bin/env python3
"""48 px proof: render each peak pose at exactly 48 px, then nearest-upscale so the
actual small-size pixels are visible. Mood must be identifiable from these alone."""
import io, os, sys
import cairosvg
from PIL import Image, ImageDraw, ImageFont

SRC = sys.argv[1]
OUT = sys.argv[2]
MOODS = ['idle', 'blink', 'happy', 'eating', 'sleepy', 'surprised', 'proud']
PEAK = {1: dict(idle=1, blink=2, happy=3, eating=3, sleepy=3, surprised=2, proud=2),
        2: dict(idle=1, blink=2, happy=3, eating=4, sleepy=3, surprised=3, proud=2),
        3: dict(idle=1, blink=2, happy=3, eating=4, sleepy=3, surprised=3, proud=2),
        4: dict(idle=1, blink=2, happy=3, eating=4, sleepy=3, surprised=3, proud=2)}
UP = 7          # upscale factor
CELL = 48 * UP
try:
    f = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial-Bold.ttf', 13)
except Exception:
    f = ImageFont.load_default()

stages = [int(x) for x in (sys.argv[3].split(',') if len(sys.argv) > 3 else ['3', '4'])]
W = len(MOODS) * CELL + 150
H = 22 + len(stages) * (CELL + 6)
out = Image.new('RGB', (W, H), (255, 255, 255, 255))
d = ImageDraw.Draw(out)
d.rectangle([0, 0, W, 20], fill=(30, 27, 58))
d.text((6, 4), '48 px proof — rendered at 48, nearest-upscaled x%d' % UP, font=f, fill=(255, 255, 255))
for c, m in enumerate(MOODS):
    d.text((150 + c * CELL + CELL // 2 - 20, 4), m.upper(), font=f, fill=(200, 195, 225))
for r, st in enumerate(stages):
    y = 22 + r * (CELL + 6)
    d.text((6, y + CELL // 2 - 8), 'stage %d' % st, font=f, fill=(30, 27, 58))
    for c, m in enumerate(MOODS):
        n = f's{st}_{m}_{PEAK[st][m]}.svg'
        b = cairosvg.svg2png(url=os.path.join(SRC, n), write_to=None, output_width=48, output_height=48,
                             background_color=None)
        im = Image.open(io.BytesIO(b)).convert('RGBA')
        tile = Image.new('RGBA', (48, 48), (251, 247, 240, 255))
        tile.paste(Image.new('RGBA', (48, 24), (21, 19, 31, 255)), (0, 24))
        tile.paste(im, (0, 0), im)
        big = tile.resize((CELL, CELL), Image.NEAREST)
        out.paste(big.convert('RGB'), (150 + c * CELL, y))
out.save(OUT)
print('48px proof', OUT, out.size)
