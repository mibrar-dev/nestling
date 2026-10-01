#!/usr/bin/env python3
"""Debug render: character over a 20px coordinate grid with axis labels."""
import io, os, sys
import cairosvg
from PIL import Image, ImageDraw, ImageFont

d = sys.argv[1]; out = sys.argv[2]; names = sys.argv[3:]
S = 480
try: f = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 11)
except Exception: f = ImageFont.load_default()
tiles = []
for n in names:
    b = cairosvg.svg2png(url=os.path.join(d, n), write_to=None, output_width=S, output_height=S, background_color=None)
    im = Image.open(io.BytesIO(b)).convert('RGBA')
    t = Image.new('RGBA', (S, S), (255, 255, 255, 255))
    dr = ImageDraw.Draw(t)
    for x in range(0, 241, 20):
        col = (255, 0, 0) if x in (120, 214) else (220, 220, 235)
        dr.line([(x * S / 240, 0), (x * S / 240, S)], fill=col, width=1)
        dr.text((x * S / 240 + 2, 2), str(x), fill=(150, 150, 170), font=f)
    for y in range(0, 241, 20):
        col = (255, 0, 0) if y in (214,) else (220, 220, 235)
        dr.line([(0, y * S / 240), (S, y * S / 240)], fill=col, width=1)
        dr.text((2, y * S / 240 + 2), str(y), fill=(150, 150, 170), font=f)
    t.paste(im, (0, 0), im)
    tiles.append(t)
W = S * len(tiles)
sheet = Image.new('RGBA', (W, S + 20), (255, 255, 255, 255))
dr = ImageDraw.Draw(sheet)
for i, n in enumerate(names):
    dr.text((i * S + 4, 4), n, fill=(0, 0, 0), font=f)
    sheet.paste(tiles[i], (i * S, 20))
sheet.convert('RGB').save(out)
print('grid', out, sheet.size)
