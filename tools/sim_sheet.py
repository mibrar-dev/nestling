#!/usr/bin/env python3
"""Build a contact sheet from a simulator screenshot run.

    tools/sim_sheet.py <label>

Reads design/qa/sim/<label>/<theme>_<nn>_<slug>.png (written by
app/test_driver/integration_test.dart) and writes one sheet per theme:

    design/qa/sim/<label>/SHEET_light.png
    design/qa/sim/<label>/SHEET_dark.png

Four columns, each shot scaled to 390 wide (the design width the gallery is
built against), captioned with the section slug. The sheets are one image per
theme so the whole run can be eyeballed in a single glance.
"""
from __future__ import annotations

import pathlib
import sys

from PIL import Image, ImageDraw, ImageFont

CELL_W = 390
COLS = 4
GUTTER = 18
MARGIN = 24
LABEL_H = 34
HEADER_H = 76
BG = (24, 26, 30)
FG = (236, 238, 241)
MUTED = (150, 155, 163)

REPO = pathlib.Path(__file__).resolve().parent.parent
FONT_REGULAR = "/System/Library/Fonts/Helvetica.ttc"
FONT_BOLD = "/System/Library/Fonts/Helvetica.ttc"


def font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    """A system font, so the sheet does not depend on a Pillow font bundle."""
    try:
        return ImageFont.truetype(FONT_BOLD if bold else FONT_REGULAR, size, index=1 if bold else 0)
    except OSError:
        return ImageFont.load_default()


def runs(label: str) -> dict[str, list[pathlib.Path]]:
    """Group a run's PNGs by theme, keeping capture order."""
    run_dir = REPO / "design" / "qa" / "sim" / label
    if not run_dir.is_dir():
        sys.exit(f"no such run: {run_dir}")
    by_theme: dict[str, list[pathlib.Path]] = {}
    for png in sorted(run_dir.glob("*.png")):
        if png.name.startswith(("SHEET_", "compare_")):
            continue
        theme = png.name.split("_", 1)[0]
        by_theme.setdefault(theme, []).append(png)
    if not by_theme:
        sys.exit(f"no screenshots in {run_dir}")
    return by_theme


def sheet(label: str, theme: str, shots: list[pathlib.Path]) -> pathlib.Path:
    title = font(30, bold=True)
    caption = font(19)
    sub = font(17)

    frames = []
    for png in shots:
        with Image.open(png) as im:
            im = im.convert("RGB")
            h = round(im.height * CELL_W / im.width)
            frames.append((png, im.resize((CELL_W, h), Image.LANCZOS)))

    cell_h = max(f.height for _, f in frames) + LABEL_H
    rows = (len(frames) + COLS - 1) // COLS
    width = MARGIN * 2 + CELL_W * COLS + GUTTER * (COLS - 1)
    height = HEADER_H + rows * cell_h + GUTTER * (rows - 1) + MARGIN

    out = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(out)

    draw.text((MARGIN, 20), f"{label} · {theme}", font=title, fill=FG)
    draw.text(
        (MARGIN, 52),
        f"{len(frames)} sections · {CELL_W}px wide · 3x simulator captures",
        font=sub,
        fill=MUTED,
    )

    y = HEADER_H
    for i, (png, frame) in enumerate(frames):
        col, row = i % COLS, i // COLS
        x = MARGIN + col * (CELL_W + GUTTER)
        if row:
            y = HEADER_H + row * (cell_h + GUTTER)
        slug = png.stem.split("_", 2)[2].replace("_", " ")
        draw.text((x + 2, y + 4), f"{i + 1:02d}  {slug}", font=caption, fill=FG)
        out.paste(frame, (x, y + LABEL_H))

    path = REPO / "design" / "qa" / "sim" / label / f"SHEET_{theme}.png"
    out.save(path, optimize=True)
    return path


def main() -> int:
    label = sys.argv[1] if len(sys.argv) > 1 else None
    if label is None:
        sim = REPO / "design" / "qa" / "sim"
        runs_available = sorted(p.name for p in sim.iterdir() if p.is_dir())
        sys.exit(f"usage: sim_sheet.py <label>\navailable: {runs_available}")

    for theme, shots in runs(label).items():
        path = sheet(label, theme, shots)
        print(path.relative_to(REPO))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
