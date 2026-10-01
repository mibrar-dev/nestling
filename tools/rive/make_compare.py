#!/usr/bin/env python3
"""
make_compare.py - build design/animations/rive/v2/COMPARE.png.

Left column  : the brand SVG, rasterised with cairosvg (the ground truth).
Right column : the same artboard rendered by the Rive CLI from pip.riv.
Row label    : the artboard name, plus the mood/state driven for that shot.

Also writes one PNG per shot into design/animations/rive/v2/.
"""

from __future__ import annotations

import os
import subprocess
import sys

import cairosvg
from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
SVG_DIR = os.path.join(ROOT, "app", "assets", "illustrations")
OUT = os.path.join(ROOT, "design", "animations", "rive", "v2")
# Screenshots come from the throwaway preview project, which is the same RML
# plus an opaque backdrop. `rive --screenshot` always renders on black, which
# makes a side-by-side against a transparent SVG useless.
PIP = os.path.join(ROOT, "tools", "rive", "pip-preview")

# (label, svg, artboard, rive data flags, rive advance, viewport)
# The viewport matches each artboard's aspect so the screenshot has no
# letterbox bars to confuse the eye.
# Column 3 is a second, later frame of the same mood, so a one-shot that looks
# fine on its first frame but breaks on its peak is visible side by side.
SHOTS = [
    ("stage 1  egg", "pip_stage_1.svg", "PipEgg", [], "1", "240x240", "90"),
    ("stage 2  hatchling", "pip_stage_2.svg", "PipHatchling", [], "1", "240x240", "90"),
    ("stage 3  fledgling", "pip_stage_3.svg", "PipFledgling", [], "1", "240x240", "90"),
    ("stage 4  songbird", "pip_stage_4.svg", "PipSongbird", [], "1", "240x240", "90"),
    ("stage 3  blink", "pip_stage_3.svg", "PipFledgling", [], "134", "240x240", "139"),
    ("stage 3  happy", "pip_stage_3.svg", "PipFledgling", ["--data=mood=1"], "12", "240x240", "24"),
    ("stage 3  eating", "pip_stage_3.svg", "PipFledgling", ["--data=mood=2"], "10", "240x240", "34"),
    ("stage 3  evolve", "pip_stage_3.svg", "PipFledgling", ["--data=evolve=1"], "16", "240x240", "36"),
    ("stage 4  happy", "pip_stage_4.svg", "PipSongbird", ["--data=mood=1"], "12", "240x240", "24"),
    ("stage 4  evolve", "pip_stage_4.svg", "PipSongbird", ["--data=evolve=1"], "16", "240x240", "36"),
    ("jar  fill 0.20", "jar_coins.svg", "Jar", ["--data=fill=0.2"], "1", "200x236", "1"),
    ("jar  fill 0.62", "jar_coins.svg", "Jar", ["--data=fill=0.62"], "1", "200x236", "1"),
    ("jar  fill 1.00", "jar_coins.svg", "Jar", ["--data=fill=1.0"], "1", "200x236", "1"),
    ("jar  drop", "jar_coins.svg", "Jar", ["--data=drop=1"], "40", "200x236", "60"),
]

CELL = 240
RENDER = 480
PAD = 16
LABEL_W = 190
ROW_H = CELL + 30
BG = (255, 252, 246)
INK = (30, 27, 58)
MUTED = (124, 108, 242)
GRID = (226, 219, 210)


def rive_shot(artboard, flags, advance, viewport, path):
    # --fit=contain at a fixed viewport puts both columns on the same pixel
    # grid, so the comparison is genuinely 1:1 rather than two thumbnails.
    vw, vh = viewport.split("x")
    cmd = ["rive", PIP, f"--artboard={artboard}",
           f"--screenshot={path}", f"--advance={advance}",
           f"--viewport={int(vw)*2}x{int(vh)*2}", "--fit=contain"] + flags
    subprocess.run(cmd, check=True, capture_output=True)


def fit(img, box):
    img = img.convert("RGBA")
    img.thumbnail(box, Image.LANCZOS)
    return img


def main():
    os.makedirs(OUT, exist_ok=True)
    # Regenerate + build both projects so the sheet can never show stale art.
    subprocess.run([sys.executable, os.path.join(HERE, "gen_pip.py")], check=True,
                   capture_output=True)
    subprocess.run([sys.executable, "-c",
                    "import gen_pip,os;gen_pip.emit_preview(os.path.join("
                    "os.path.dirname(os.path.abspath('gen_pip.py')),'pip-preview'))"],
                   check=True, cwd=HERE, capture_output=True)
    env = dict(os.environ)
    env["RIVE_HOME"] = os.path.join(ROOT, "tools", "rive", ".rive")
    env["PATH"] = os.path.join(ROOT, "tools", "rive", "bin") + os.pathsep + env["PATH"]
    os.environ.update(env)
    subprocess.run(["rive", PIP, "--once"], check=True, capture_output=True)

    rows = []
    for label, svg, artboard, flags, advance, viewport, mid in SHOTS:
        stem = label.replace(" ", "_").replace(".", "_")
        svg_png = os.path.join(OUT, f"ref_{stem}.png")
        riv_png = os.path.join(OUT, f"rive_{stem}.png")
        mid_png = os.path.join(OUT, f"mid_{stem}.png")
        vw, vh = (int(v) for v in viewport.split("x"))
        cairosvg.svg2png(url=os.path.join(SVG_DIR, svg), write_to=svg_png,
                         output_width=vw * 2, output_height=vh * 2,
                         background_color=None)
        rive_shot(artboard, flags, advance, viewport, riv_png)
        rive_shot(artboard, flags, mid, viewport, mid_png)
        rows.append((label, svg_png, riv_png, mid_png))

    head = 56
    width = LABEL_W + CELL * 3 + PAD * 4
    height = head + len(rows) * ROW_H + PAD
    sheet = Image.new("RGBA", (width, height), BG + (255,))
    d = ImageDraw.Draw(sheet)

    d.text((PAD, 14), "Nestling  -  Pip Rive rebuild vs brand SVG", fill=INK + (255,))
    d.text((PAD, 30), "art generated from app/assets/illustrations/*.svg by "
                      "tools/rive/gen_pip.py + svg2rml.py, so both columns "
                      "share one source of truth", fill=MUTED + (255,))
    col0 = PAD + LABEL_W
    d.text((col0, 14), "left: brand SVG (cairosvg)", fill=INK + (255,))
    d.text((col0 + CELL + PAD, 14),
           "right: pip.riv rendered by the Rive CLI", fill=INK + (255,))
    d.text((col0 + (CELL + PAD) * 2, 14),
           "mid-animation (later frame of the same mood)",
           fill=INK + (255,))
    d.line([(PAD, head - 10), (width - PAD, head - 10)], fill=GRID + (255,), width=2)

    y = head
    for label, svg_png, riv_png, mid_png in rows:
        for i, p in enumerate((svg_png, riv_png, mid_png)):
            x = col0 + i * (CELL + PAD)
            cell = Image.new("RGBA", (CELL, CELL), (255, 255, 255, 255))
            im = fit(Image.open(p), (CELL, CELL))
            cell.alpha_composite(im, ((CELL - im.width) // 2,
                                      (CELL - im.height) // 2))
            sheet.alpha_composite(cell, (x, y))
            d.rectangle([x, y, x + CELL, y + CELL], outline=GRID + (255,))
        d.text((PAD, y + CELL // 2 - 14), label, fill=INK + (255,))
        d.text((PAD, y + CELL // 2 + 4),
               os.path.basename(svg_png).replace("ref_", "").replace(".png", ""),
               fill=MUTED + (255,))
        y += ROW_H

    out = os.path.join(OUT, "COMPARE.png")
    sheet.convert("RGB").save(out)
    print("wrote", out, sheet.size)


if __name__ == "__main__":
    sys.exit(main())
