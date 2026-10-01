#!/usr/bin/env python3
"""Compare two simulator screenshot runs, section by section.

    tools/sim_compare.py <labelA> <labelB>

Writes design/qa/sim/compare_<A>_vs_<B>.png: one row per section slug found in
both runs, A on the left, B on the right, at the same scale, with a pixel
difference percentage in the gutter so a regression stands out without opening
the files. Sections missing from either run are listed on the sheet instead of
being silently skipped.
"""
from __future__ import annotations

import pathlib
import sys

from PIL import Image, ImageChops, ImageDraw, ImageFont

CELL_W = 390
GUTTER = 24
MARGIN = 24
LABEL_W = 190
ROW_H = 56
HEADER_H = 116
BG = (24, 26, 30)
FG = (236, 238, 241)
MUTED = (150, 155, 163)
SAME = (110, 190, 130)
CHANGED = (240, 170, 90)
MISSING = (235, 110, 110)

REPO = pathlib.Path(__file__).resolve().parent.parent
SIM = REPO / "design" / "qa" / "sim"
FONT = "/System/Library/Fonts/Helvetica.ttc"
# The test captures light first, then dark; keep the sheet in that order.
THEME_ORDER = {"light": 0, "dark": 1}


def font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    try:
        return ImageFont.truetype(FONT, size, index=1 if bold else 0)
    except OSError:
        return ImageFont.load_default()


def index(label: str) -> dict[tuple[str, str], tuple[int, pathlib.Path]]:
    """Map (theme, slug) -> (capture number, file) for one run."""
    run_dir = SIM / label
    if not run_dir.is_dir():
        sys.exit(f"no such run: {run_dir}")
    out: dict[tuple[str, str], tuple[int, pathlib.Path]] = {}
    for png in sorted(run_dir.glob("*.png")):
        if png.name.startswith(("SHEET_", "compare_")):
            continue
        parts = png.stem.split("_", 2)
        if len(parts) != 3 or not parts[1].isdigit():
            continue
        out[(parts[0], parts[2])] = (int(parts[1]), png)
    if not out:
        sys.exit(f"no screenshots in {run_dir}")
    return out


def capture_order(
    *runs: dict[tuple[str, str], tuple[int, pathlib.Path]],
) -> list[tuple[str, str]]:
    """(theme, slug) pairs in the order the test captured them."""
    order: list[tuple[str, str]] = []
    for run in runs:
        for key, _ in sorted(
            run.items(),
            key=lambda kv: (kv[1][0], THEME_ORDER.get(kv[0][0], 9), kv[0][0]),
        ):
            if key not in order:
                order.append(key)
    return order


def load(png: pathlib.Path) -> Image.Image:
    with Image.open(png) as im:
        return im.convert("RGB").resize(
            (CELL_W, round(im.height * CELL_W / im.width)),
            Image.LANCZOS,
        )


def diff_pct(a: Image.Image, b: Image.Image) -> float:
    """Percentage of pixels that differ beyond a small anti-aliasing margin."""
    if a.size != b.size:
        return 100.0
    delta = ImageChops.difference(a, b).convert("L")
    changed = sum(delta.histogram()[25:])
    return changed * 100.0 / (a.width * a.height)


def main() -> int:
    if len(sys.argv) != 3:
        sys.exit(f"usage: sim_compare.py <labelA> <labelB>\navailable: "
                 f"{sorted(p.name for p in SIM.iterdir() if p.is_dir())}")

    a_label, b_label = sys.argv[1], sys.argv[2]
    a, b = index(a_label), index(b_label)

    slugs = capture_order(a, b)
    common = [k for k in slugs if k in a and k in b]
    rows = []
    cell_h = 0
    for theme, slug in common:
        ia, ib = load(a[(theme, slug)][1]), load(b[(theme, slug)][1])
        cell_h = max(cell_h, ia.height)
        rows.append((theme, slug, ia, ib, diff_pct(ia, ib)))
    if not rows:
        sys.exit("the two runs share no sections")

    width = MARGIN * 2 + LABEL_W + CELL_W * 2 + GUTTER * 3
    height = HEADER_H + len(rows) * (cell_h + ROW_H) + MARGIN
    out = Image.new("RGB", (width, height), BG)
    draw = ImageDraw.Draw(out)

    title, sub, name_font, diff_font = (
        font(30, bold=True),
        font(17),
        font(19),
        font(19, bold=True),
    )
    draw.text((MARGIN, 20), f"{a_label} vs {b_label}", font=title, fill=FG)
    draw.text(
        (MARGIN, 56),
        f"{len(rows)} sections in both runs · {CELL_W}px wide · diff is % of "
        f"pixels changed",
        font=sub,
        fill=MUTED,
    )
    col_a = MARGIN + LABEL_W + GUTTER
    col_b = col_a + CELL_W + GUTTER
    draw.text((col_a, HEADER_H - 26), a_label, font=font(18, bold=True), fill=FG)
    draw.text((col_b, HEADER_H - 26), b_label, font=font(18, bold=True), fill=FG)

    y = HEADER_H
    for theme, slug, ia, ib, pct in rows:
        draw.text((MARGIN, y + 6), f"{theme} · {slug.replace('_', ' ')}",
                  font=name_font, fill=FG)
        draw.text((MARGIN, y + 30), f"{pct:.2f}% changed", font=diff_font,
                  fill=SAME if pct < 0.5 else CHANGED)
        out.paste(ia, (col_a, y))
        out.paste(ib, (col_b, y))
        draw.rectangle(
            [col_a, y, col_a + CELL_W, y + cell_h], outline=(70, 74, 82)
        )
        draw.rectangle(
            [col_b, y, col_b + CELL_W, y + cell_h], outline=(70, 74, 82)
        )
        y += cell_h + ROW_H

    only = [f"{t}/{s}" for t, s in slugs if (t, s) not in common]
    if only:
        text = f"missing from one run: {', '.join(sorted(only))}"
        draw.text((MARGIN, height - MARGIN + 6), text[:110], font=font(16), fill=MISSING)

    path = SIM / f"compare_{a_label}_vs_{b_label}.png"
    out.save(path, optimize=True)
    print(path.relative_to(REPO))
    changed = [r for r in rows if r[4] >= 0.5]
    print(f"{len(rows)} sections compared, {len(changed)} changed over 0.5%")
    for theme, slug, _, _, pct in sorted(changed, key=lambda r: -r[4])[:12]:
        print(f"  {pct:6.2f}%  {theme}/{slug}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
