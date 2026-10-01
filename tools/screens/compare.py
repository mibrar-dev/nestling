#!/usr/bin/env python3
"""Side-by-side design-vs-app comparison for one screen.

    tools/screens/compare.py <design_png> <app_png> <out_png>

Writes a 390-wide-per-panel sheet: design | app | diff heat-map, with a
caption row. Prints the mean pixel difference % and a per-band (8 horizontal
bands) difference table to locate spacing drift.

Bands are numbered 0..7 top to bottom; each row prints the band's vertical
range and its mean difference %. A high band pinpoints where the layout
drifts (e.g. band 0 = header/status area, band 7 = tab bar/CTA).
"""
from __future__ import annotations

import pathlib
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFont, ImageStat

PANEL_W = 390
PANEL_H = 844
GUTTER = 16
MARGIN = 24
CAPTION_H = 34
BG = (24, 26, 30)
FG = (236, 238, 241)
MUTED = (150, 155, 163)
FONT = "/System/Library/Fonts/Helvetica.ttc"
BANDS = 8


def font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    try:
        return ImageFont.truetype(FONT, size, index=1 if bold else 0)
    except OSError:
        return ImageFont.load_default()


def load(png: str) -> Image.Image:
    with Image.open(png) as im:
        frame = im.convert("RGB")
    # Normalise to the 390x844 design frame (simulator shots share the same
    # aspect ratio, so this is a pure scale).
    return frame.resize((PANEL_W, PANEL_H), Image.LANCZOS)


def heat(diff: Image.Image) -> Image.Image:
    """Red heat-map: brighter red = larger pixel difference."""
    gray = diff.convert("L")
    red = Image.new("RGB", diff.size, (20, 20, 24))
    mask = gray.point(lambda v: min(255, v * 2))
    hot = Image.new("RGB", diff.size, (235, 70, 70))
    return Image.composite(hot, red, mask)


def band_stats(diff: Image.Image) -> list[tuple[int, int, float]]:
    gray = diff.convert("L")
    px = gray.load()
    w, h = gray.size
    rows: list[tuple[int, int, float]] = []
    for band in range(BANDS):
        y0 = band * h // BANDS
        y1 = (band + 1) * h // BANDS
        total = 0
        for y in range(y0, y1):
            for x in range(w):
                total += px[x, y]
        mean = total / ((y1 - y0) * w) / 255 * 100
        rows.append((y0, y1, mean))
    return rows


def main(argv: list[str]) -> int:
    if len(argv) != 4:
        print("usage: tools/screens/compare.py <design_png> <app_png> <out_png>")
        return 2
    design_path, app_path, out_path = argv[1], argv[2], argv[3]
    for label, path in (("design", design_path), ("app", app_path)):
        if not pathlib.Path(path).is_file():
            print(f"compare: no such {label} file: {path}")
            return 2

    design = load(design_path)
    app = load(app_path)
    diff = ImageChops.difference(design, app)
    hot = heat(diff)

    mean = ImageStat.Stat(diff.convert('L')).mean[0] / 255 * 100
    bands = band_stats(diff)

    sheet_w = MARGIN * 2 + PANEL_W * 3 + GUTTER * 2
    sheet_h = MARGIN * 2 + CAPTION_H * 2 + PANEL_H
    sheet = Image.new("RGB", (sheet_w, sheet_h), BG)
    draw = ImageDraw.Draw(sheet)
    title_f = font(20, bold=True)
    cap_f = font(15)

    draw.text(
        (MARGIN, MARGIN + 4),
        f"{pathlib.Path(design_path).stem}  vs  {pathlib.Path(app_path).stem}  —  mean diff {mean:.2f}%",
        font=title_f,
        fill=FG,
    )
    panels = (("design", design), ("app", app), ("diff", hot))
    for i, (label, panel) in enumerate(panels):
        x = MARGIN + i * (PANEL_W + GUTTER)
        y = MARGIN + CAPTION_H
        draw.text((x + 2, y), label, font=cap_f, fill=MUTED)
        sheet.paste(panel, (x, y + CAPTION_H - 8))
    sheet.save(out_path)

    print(f"mean diff: {mean:.2f}%")
    print("band  y-range    diff%")
    for band, (y0, y1, pct) in enumerate(bands):
        print(f"  {band}   {y0:>4}-{y1:<4}  {pct:5.2f}%")
    print(f"sheet: {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
