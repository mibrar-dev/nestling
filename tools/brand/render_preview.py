"""Render the app-icon preview sheet for orchestrator review.

Reads the generated launcher art and writes `docs/brand/icon_preview.png`:
- iOS rounded square at 180 px (from app_icon.png),
- Android adaptive icon at 192 px full-bleed with the visible-mask circle,
  then circle- and squircle-masked,
- monochrome silhouette on a dark tile.

Re-runnable: `python3 tools/brand/render_preview.py` from the repo root.
"""

from __future__ import annotations

import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
BRAND = ROOT / "app" / "assets" / "brand"
OUT = ROOT / "docs" / "brand" / "icon_preview.png"

IOS_SIZE = 180
DROID_SIZE = 192
MASK_DIAMETER_RATIO = 72 / 108  # visible mask of the 108 dp layer
TILE = 250
TILE_ART_Y = 10
TILE_LABEL_Y = 222
TOP_STRIP = 64
BG = (245, 243, 238)
INK = (30, 27, 58)
ACCENT = (23, 128, 79)


def circle_mask(size: int, diameter: float) -> Image.Image:
    r = diameter / 2
    c = size / 2
    yy, xx = np.ogrid[:size, :size]
    m = ((xx - c) ** 2 + (yy - c) ** 2) <= r * r
    return Image.fromarray((m * 255).astype(np.uint8))


def squircle_mask(size: int, diameter: float, n: float = 4.0) -> Image.Image:
    r = diameter / 2
    c = size / 2
    yy, xx = np.ogrid[:size, :size]
    m = (np.abs(xx - c) ** n + np.abs(yy - c) ** n) <= r**n
    return Image.fromarray((m * 255).astype(np.uint8))


def ios_mask(size: int) -> Image.Image:
    # iOS squircle approximated with a rounded rect, corner radius ~22.5 %.
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle(
        [0, 0, size - 1, size - 1], radius=int(size * 0.225), fill=255
    )
    return m


def tile_base(draw: ImageDraw.ImageDraw, x: int, label: str, font: ImageFont.ImageFont) -> None:
    draw.text((x + 12, TILE_LABEL_Y), label, fill=INK, font=font)


def main() -> int:
    brand_icon = Image.open(BRAND / "app_icon.png").convert("RGB")
    bg = Image.open(BRAND / "app_icon_background.png").convert("RGB").resize((DROID_SIZE, DROID_SIZE), Image.LANCZOS)
    fg = (
        Image.open(BRAND / "app_icon_foreground_adaptive.png")
        .convert("RGBA")
        .resize((DROID_SIZE, DROID_SIZE), Image.LANCZOS)
    )
    mono = (
        Image.open(BRAND / "app_icon_monochrome.png")
        .convert("RGBA")
        .resize((DROID_SIZE, DROID_SIZE), Image.LANCZOS)
    )
    adaptive = bg.copy()
    adaptive.paste(fg, (0, 0), fg)

    sheet = Image.new("RGB", (TILE * 5, TILE + TOP_STRIP), BG)
    draw = ImageDraw.Draw(sheet)
    try:
        title_font = ImageFont.load_default(size=22)
        font = ImageFont.load_default(size=15)
    except TypeError:  # very old Pillow
        title_font = ImageFont.load_default()
        font = ImageFont.load_default()
    draw.text((16, 14), "Nestling app icon - preview (generated, do not hand-edit)", fill=INK, font=title_font)
    draw.text(
        (16, 38),
        "iOS 180px - adaptive 192px, mask = inner 72/108 dp - safe circle r = 338/1024",
        fill=(110, 106, 138),
        font=font,
    )

    y0 = TOP_STRIP

    # 1. iOS rounded square.
    ios = brand_icon.resize((IOS_SIZE, IOS_SIZE), Image.LANCZOS)
    tile = Image.new("RGB", (TILE, TILE), BG)
    m = ios_mask(IOS_SIZE)
    tile.paste(ios, ((TILE - IOS_SIZE) // 2, TILE_ART_Y + 4), m)
    sheet.paste(tile, (0, y0))
    tile_base(ImageDraw.Draw(sheet), 0, "1 - iOS rounded square", font)

    # 2. Adaptive full-bleed + visible-mask circle outline.
    tile = Image.new("RGB", (TILE, TILE), BG)
    tile.paste(adaptive, ((TILE - DROID_SIZE) // 2, TILE_ART_Y))
    ox = (TILE - DROID_SIZE) // 2
    d = DROID_SIZE * MASK_DIAMETER_RATIO
    c = TILE_ART_Y + DROID_SIZE / 2
    ImageDraw.Draw(tile).ellipse(
        [ox + (DROID_SIZE - d) / 2, c - d / 2, ox + (DROID_SIZE + d) / 2, c + d / 2],
        outline=(201, 58, 58),
        width=3,
    )
    sheet.paste(tile, (TILE, y0))
    tile_base(ImageDraw.Draw(sheet), TILE, "2 - adaptive + mask circle", font)

    # 3. Circle mask.
    masked = adaptive.copy()
    masked.putalpha(circle_mask(DROID_SIZE, d))
    tile = Image.new("RGB", (TILE, TILE), BG)
    tile.paste(masked, ((TILE - DROID_SIZE) // 2, TILE_ART_Y), masked)
    sheet.paste(tile, (TILE * 2, y0))
    tile_base(ImageDraw.Draw(sheet), TILE * 2, "3 - Android circle", font)

    # 4. Squircle mask.
    masked = adaptive.copy()
    masked.putalpha(squircle_mask(DROID_SIZE, d * 1.06))
    tile = Image.new("RGB", (TILE, TILE), BG)
    tile.paste(masked, ((TILE - DROID_SIZE) // 2, TILE_ART_Y), masked)
    sheet.paste(tile, (TILE * 3, y0))
    tile_base(ImageDraw.Draw(sheet), TILE * 3, "4 - Android squircle", font)

    # 5. Monochrome on a dark tile.
    dark = Image.new("RGB", (DROID_SIZE, DROID_SIZE), (26, 24, 40))
    dark.paste(mono, (0, 0), mono)
    tile = Image.new("RGB", (TILE, TILE), BG)
    tile.paste(dark, ((TILE - DROID_SIZE) // 2, TILE_ART_Y))
    sheet.paste(tile, (TILE * 4, y0))
    tile_base(ImageDraw.Draw(sheet), TILE * 4, "5 - themed (mono) on dark", font)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(OUT)
    print(f"wrote {OUT.relative_to(ROOT)} ({sheet.size[0]}x{sheet.size[1]})")
    # Fail loudly if Pip got clipped by the mask: the masked circle must
    # still contain opaque art near its edge band (i.e. art fills the mask).
    edge = np.array(circle_mask(DROID_SIZE, d)).astype(bool) & (
        np.array(Image.open(BRAND / "app_icon_foreground_adaptive.png").convert("RGBA").resize((DROID_SIZE, DROID_SIZE)))[:, :, 3]
        > 8
    )
    frac = edge.mean()
    print(f"masked-icon opaque fraction: {frac:.3f}")
    assert 0.05 < frac < 0.9, "masked adaptive icon looks empty or full-bleed"
    return 0


if __name__ == "__main__":
    sys.exit(main())
