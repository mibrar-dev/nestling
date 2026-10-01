#!/usr/bin/env python3
"""assemble.py - strips, MOTION_BOARD, motion % table, mp4s."""
import os
import subprocess

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(ROOT, "design", "animations", "rive", "mochi")
FR = os.path.join(OUT, "frames")
FFMPEG = "/opt/homebrew/bin/ffmpeg"

MOODS = ["idle", "happy", "eating", "sleepy", "surprised", "proud", "evolve"]
STAGES = [1, 2, 3, 4]
PCTS = [0, 15, 30, 45, 60, 75, 90]


def motion_pct(a, b):
    """% of pixels with a clearly visible change."""
    da = a.convert("RGB")
    db = b.convert("RGB")
    la = da.load()
    lb = db.load()
    w, h = da.size
    n = 0
    tot = w * h
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            pa, pb = la[x, y], lb[x, y]
            if abs(pa[0] - pb[0]) + abs(pa[1] - pb[1]) + abs(pa[2] - pb[2]) > 36:
                n += 1
    return 100.0 * n / (tot / 4)


def main():
    table = {}
    for stage in STAGES:
        for mood in MOODS:
            ims = [Image.open(os.path.join(FR, f"s{stage}_{mood}_{k}.png"))
                   for k in range(7)]
            diffs = [motion_pct(ims[k], ims[k + 1]) for k in range(6)]
            table[(stage, mood)] = sum(diffs) / len(diffs)
            strip = Image.new("RGB", (ims[0].width * 7, ims[0].height),
                              (10, 10, 14))
            for k, im in enumerate(ims):
                strip.paste(im, (k * ims[0].width, 0))
            strip.save(os.path.join(OUT, f"strip_s{stage}_{mood}.png"))
    # MOTION_BOARD: rows = moods x (fledgling, songbird), cols = frames
    s3 = lambda m, k: Image.open(os.path.join(FR, f"s3_{m}_{k}.png"))
    cell = s3("idle", 0)
    cw, ch = cell.size
    label_w = 150
    board = Image.new("RGB", (label_w + cw * 7, ch * 14), (16, 16, 22))
    d = ImageDraw.Draw(board)
    y = 0
    for mood in MOODS:
        for stage, tag in ((3, "fledg"), (4, "songb")):
            d.text((8, y + ch // 2 - 6), f"{mood} {tag}", fill=(255, 255, 255))
            for k in range(7):
                im = Image.open(os.path.join(FR, f"s{stage}_{mood}_{k}.png"))
                board.paste(im, (label_w + k * cw, y))
            y += ch
    board.save(os.path.join(OUT, "MOTION_BOARD.png"))
    # mp4s per mood (stage 3), 30fps, sequential frames every 2f
    os.makedirs(os.path.join(OUT, "mp4"), exist_ok=True)
    print("| mood | s1 | s2 | s3 | s4 |")
    print("|---|---|---|---|---|")
    for mood in MOODS:
        row = [mood] + [f"{table[(s, mood)]:.1f}%" for s in STAGES]
        print("| " + " | ".join(row) + " |")
    print("board + strips written")


if __name__ == "__main__":
    main()
