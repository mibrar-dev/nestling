"""Generate Nestling Android adaptive + monochrome icon assets.

Reads the designer-approved foreground
(`design/flutter-asset-pack/assets/brand/app_icon_foreground.png`, 1024px,
transparent) and writes, without redrawing the art:

- `app/assets/brand/app_icon_foreground_adaptive.png`: the foreground scaled
  about its centre so every opaque pixel fits inside the central 66 % safe
  circle (radius 338 px of 1024) with ~4 % margin.
- `app/assets/brand/app_icon_monochrome.png`: Android 13 themed-icon
  silhouette — pixels whose colour is the ink #1E1B3A (+/-40 per channel)
  become opaque white keeping their alpha; everything else transparent.

Re-runnable: `python3 tools/brand/generate_icons.py` from the repo root.
"""

from __future__ import annotations

import sys
from pathlib import Path

import numpy as np
from PIL import Image

SIZE = 1024
CENTER = SIZE / 2
SAFE_RADIUS = 338.0  # 66 % / 2 of 1024
MARGIN = 0.96  # ~4 % margin inside the safe circle
ALPHA_THRESHOLD = 8
INK = (30, 27, 58)  # #1E1B3A
INK_TOLERANCE = 40

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "design" / "flutter-asset-pack" / "assets" / "brand"
DST = ROOT / "app" / "assets" / "brand"
FOREGROUND_SRC = SRC / "app_icon_foreground.png"
FOREGROUND_ADAPTIVE = DST / "app_icon_foreground_adaptive.png"
MONOCHROME = DST / "app_icon_monochrome.png"


def max_opaque_distance(arr: np.ndarray) -> float:
    """Max distance from the centre among pixels with alpha > threshold."""
    ys, xs = np.where(arr[:, :, 3] > ALPHA_THRESHOLD)
    if len(xs) == 0:
        return 0.0
    return float(np.sqrt((xs - CENTER) ** 2 + (ys - CENTER) ** 2).max())


def main() -> int:
    fg = Image.open(FOREGROUND_SRC).convert("RGBA")
    assert fg.size == (SIZE, SIZE), f"unexpected foreground size {fg.size}"
    arr = np.array(fg)

    dist = max_opaque_distance(arr)
    print(f"foreground opaque max distance from centre: {dist:.2f} px")
    scale = (SAFE_RADIUS * MARGIN) / dist
    assert 0.0 < scale <= 1.0, f"unexpected scale {scale}"
    print(f"scale about centre: {scale:.4f}")

    # Same art, just scaled: resize about the centre onto a 1024 canvas.
    small_side = max(1, round(SIZE * scale))
    small = fg.resize((small_side, small_side), Image.LANCZOS)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    offset = (SIZE - small_side) // 2
    canvas.paste(small, (offset, offset), small)

    canvas_arr = np.array(canvas)
    check = max_opaque_distance(canvas_arr)
    print(f"adaptive opaque max distance from centre: {check:.2f} px")
    assert check <= SAFE_RADIUS, f"safe-zone breach: {check} > {SAFE_RADIUS}"

    DST.mkdir(parents=True, exist_ok=True)
    canvas.save(FOREGROUND_ADAPTIVE)
    print(f"wrote {FOREGROUND_ADAPTIVE.relative_to(ROOT)}")

    # Monochrome: ink outlines only, recoloured white, alpha preserved.
    r = canvas_arr[:, :, 0].astype(np.int16)
    g = canvas_arr[:, :, 1].astype(np.int16)
    b = canvas_arr[:, :, 2].astype(np.int16)
    ink = (
        (np.abs(r - INK[0]) <= INK_TOLERANCE)
        & (np.abs(g - INK[1]) <= INK_TOLERANCE)
        & (np.abs(b - INK[2]) <= INK_TOLERANCE)
    )
    mono = np.zeros_like(canvas_arr)
    mono[:, :, 3] = np.where(ink, canvas_arr[:, :, 3], 0).astype(np.uint8)
    mono[:, :, 0] = 255
    mono[:, :, 1] = 255
    mono[:, :, 2] = 255
    kept = int(ink.sum())
    total = int((canvas_arr[:, :, 3] > ALPHA_THRESHOLD).sum())
    print(f"monochrome keeps {kept} of {total} opaque pixels")
    assert kept > 0, "monochrome would be empty"
    Image.fromarray(mono).save(MONOCHROME)
    print(f"wrote {MONOCHROME.relative_to(ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
