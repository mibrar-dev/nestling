#!/usr/bin/env python3
"""Render design/pip-v2 board PNG with labels (Pillow + cairosvg). v2 fixed layout."""
import os, io, textwrap
import cairosvg
from PIL import Image, ImageDraw, ImageFont

ROOT = "/Users/ibrar/Desktop/infinora.noworkspace/nestling-pip-v2"
PV2 = os.path.join(ROOT, "design/pip-v2")
OUT = os.path.join(PV2, "PIP_V2_DIRECTIONS.png")

PITCH = {
    "A": ("A · MOCHI", "Rounder Pokemon / Sanrio-cute. Squishy circle, tiny stubs, pastel belly. Giant eyes + blush carry 48px."),
    "B": ("B · BOLT", "Duolingo-like bold flat. Tall oval, 8px line, geometric beak, white belly. Loudest silhouette."),
    "C": ("C · STORYBOOK", "Soft-shaded premium. Pear body, wispy tuft, feather lines, thin 5px line + warm side shade."),
}
COLS = [
    ("fledgling_front.svg", "front"),
    ("fledgling_threequarter.svg", "3/4"),
    ("expr_idle.svg", "idle"),
    ("expr_blink.svg", "blink"),
    ("expr_happy.svg", "happy"),
    ("expr_eating.svg", "eating"),
    ("expr_sleepy.svg", "sleepy"),
    ("expr_surprised.svg", "wow"),
    ("expr_proud.svg", "proud"),
    ("stage_1_egg.svg", "st1 egg"),
    ("stage_2_hatchling.svg", "st2 hatch"),
    ("stage_3_fledgling.svg", "st3 fledg"),
    ("stage_4_songbird.svg", "st4 song"),
]

def svg_png(path, size):
    png = cairosvg.svg2png(url=path, write_to=None, output_width=size, output_height=size,
                           background_color="transparent")
    return Image.open(io.BytesIO(png)).convert("RGBA")

def font(sz, bold=False):
    cands = (["/System/Library/Fonts/Supplemental/Arial-Bold.ttf" if bold else "/System/Library/Fonts/Supplemental/Arial.ttf",
              "/System/Library/Fonts/Helvetica.ttc",
              "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"])
    for p in cands:
        if os.path.exists(p):
            try: return ImageFont.truetype(p, sz)
            except Exception: pass
    return ImageFont.load_default()

THUMB=150; GAP=10; LABEL_W=330; TOP=150
W = LABEL_W + len(COLS)*(THUMB+GAP) + GAP
H = TOP + 3*(THUMB+72) + 60
LIGHT=(251,247,240,255)

board = Image.new("RGBA",(W,H),LIGHT)
dr = ImageDraw.Draw(board)
dr.rectangle([0,0,W,TOP], fill=(30,27,58,255))
dr.text((24,22),"PIP V2 — character directions (100% original art)",font=font(38,True),fill=(255,255,255,255))
dr.text((24,78),"A = Mochi round  ·  B = Bolt bold flat  ·  C = Storybook soft  ·  moods must read at 48px, on light + dark",font=font(22),fill=(201,196,220,255))
for i,(_,lab) in enumerate(COLS):
    x = LABEL_W + GAP + i*(THUMB+GAP) + THUMB//2
    dr.text((x,TOP-36),lab,font=font(20,True),fill=(30,27,58,255),anchor="mm")

y = TOP
for row,d in enumerate("ABC"):
    title,sub = PITCH[d]
    dr.rectangle([0,y,W,y+THUMB+72],fill=LIGHT if row%2==0 else (243,238,229,255))
    dr.text((24,y+10),title,font=font(24,True),fill=(30,27,58,255))
    for k,ln in enumerate(textwrap.wrap(sub, width=32)[:4]):
        dr.text((24,y+42+k*22),ln,font=font(18),fill=(74,70,104,255))
    for i,(fn,lab) in enumerate(COLS):
        x = LABEL_W + GAP + i*(THUMB+GAP)
        thumb = svg_png(os.path.join(PV2,d,fn), THUMB)
        tile = Image.new("RGBA",(THUMB,THUMB),(31,28,62,255) if (i%2==1) else (255,255,255,255))
        tile.paste(thumb,(0,0),thumb)
        board.paste(tile,(x,y))
        small = svg_png(os.path.join(PV2,d,fn), 44)
        dot = Image.new("RGBA",(48,48),(124,108,242,255))
        dot.paste(small,(2,2),small)
        board.paste(dot,(x+THUMB-50,y+THUMB-50),dot)
    y += THUMB+72

dr.text((24,H-38),"48px lilac chips = small-size proof · dark tiles = dark-bg proof · ink outlines · ≤1 soft highlight · Rive-ready groups · no text/gradients",font=font(18),fill=(110,106,138,255))
board.convert("RGB").save(OUT)
print("wrote",OUT,board.size)
