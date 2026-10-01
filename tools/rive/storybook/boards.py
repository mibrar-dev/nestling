#!/usr/bin/env python3
"""boards.py — strips, MOTION_BOARD, mp4s, motion % metrics, skin/acc grid."""
import os
import subprocess
import sys

from PIL import Image, ImageDraw

OUT = sys.argv[1] if len(sys.argv) > 1 else "design/animations/rive/storybook"
FR = os.path.join(OUT, "frames")
BG = (251, 247, 240)  # #FBF7F0 contract light
FFMPEG = "/opt/homebrew/bin/ffmpeg"
MOODS = ["idle", "happy", "eat", "sleepy", "surprised", "proud", "evolve"]
PCTS = [0, 15, 30, 45, 60, 75, 90]
TILE = 240


def load(p):
    im = Image.open(p).convert("RGB")
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            if px[x, y] == (0, 0, 0):
                px[x, y] = BG
    return im


def motion_pct(a, b, thresh=12):
    """% of pixels whose grayscale differs by more than thresh."""
    a = a.convert("L")
    b = b.convert("L")
    if a.size != b.size:
        b = b.resize(a.size)
    da = list(a.getdata())
    db = list(b.getdata())
    n = len(da)
    dif = sum(1 for x, y in zip(da, db) if abs(x - y) > thresh)
    return 100.0 * dif / n


metrics = {}
# ---- strips: one row of 7 frames per stage x mood
for s in (1, 2, 3, 4):
    for m in MOODS:
        tiles = [load(os.path.join(FR, f"s{s}_{m}_{p}.png")) for p in PCTS]
        strip = Image.new("RGB", (TILE * len(tiles), TILE), BG)
        for i, t in enumerate(tiles):
            strip.paste(t.resize((TILE, TILE)), (i * TILE, 0))
        strip.save(os.path.join(OUT, f"strip_s{s}_{m}.png"))
        ms = [motion_pct(tiles[i], tiles[i + 1]) for i in range(len(tiles) - 1)]
        metrics[(s, m)] = sum(ms) / len(ms)

# ---- MOTION_BOARD: rows = mood x (fledgling, songbird), cols = frames
rows = []
for m in MOODS:
    for s in (3, 4):
        rows.append([load(os.path.join(FR, f"s{s}_{m}_{p}.png")) for p in PCTS])
board = Image.new("RGB", (TILE * len(PCTS), TILE * len(rows)), BG)
d = ImageDraw.Draw(board)
for ri, tiles in enumerate(rows):
    for ci, t in enumerate(tiles):
        board.paste(t.resize((TILE, TILE)), (ci * TILE, ri * TILE))
    m = MOODS[ri // 2]
    s = (3, 4)[ri % 2]
    d.text((6, ri * TILE + 6), f"s{s} {m}", fill=(30, 27, 58))
for ci, p in enumerate(PCTS):
    d.text((ci * TILE + 6, 6), f"{p}%", fill=(30, 27, 58))
board.save(os.path.join(OUT, "MOTION_BOARD.png"))

# ---- mp4s per mood (stage 3, 30 fps)
for m in MOODS:
    pat = os.path.join(FR, f"mp3_{m}_%03d.png")
    mp4 = os.path.join(OUT, f"pip_storybook_s3_{m}.mp4")
    subprocess.run([FFMPEG, "-y", "-loglevel", "error", "-framerate", "30",
                    "-pattern_type", "glob", "-i", pat.replace("%03d", "*"),
                    "-pix_fmt", "yuv420p", mp4], check=True)

# ---- skins x accessories grid (stage 3 idle)
cells = []
for sk in ("sunny", "berry", "sky", "mint"):
    row = []
    for a in ("none", "bow", "cap", "scarf", "glasses"):
        row.append(load(os.path.join(FR, f"skinacc_{sk}_{a}.png")))
    cells.append(row)
grid = Image.new("RGB", (TILE * 5, TILE * 4), BG)
gd = ImageDraw.Draw(grid)
for ri, row in enumerate(cells):
    for ci, t in enumerate(row):
        grid.paste(t.resize((TILE, TILE)), (ci * TILE, ri * TILE))
grid.save(os.path.join(OUT, "SKIN_ACC.png"))

print("per-mood mean frame-to-frame motion % (stage 3 / stage 4):")
for m in MOODS:
    print(f"  {m:>9}  s3 {metrics[(3, m)]:5.2f}%   s4 {metrics[(4, m)]:5.2f}%")
print("stage means:")
for s in (1, 2, 3, 4):
    vals = [metrics[(s, m)] for m in MOODS]
    print(f"  stage {s}: {sum(vals) / len(vals):.2f}%")
