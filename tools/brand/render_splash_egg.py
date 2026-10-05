"""Render the native-splash egg PNG from the approved Pip art.

Reads the designer-approved PipAvatar fallback for mochi/sunny stage 1
(`app/assets/illustrations/pip_v2/mochi/s1_idle_1.svg` — the `PipEgg` look,
sunny is the drawn palette so no recolour is applied) and writes a 1024x1024
transparent PNG to `app/assets/brand/splash_egg.png` for `flutter_native_splash`.

Same art, no redraw: the SVG is rasterised as-is, scaled to fill the 1024
canvas (the source viewBox is square, so aspect is preserved).

Re-runnable: `python3 tools/brand/render_splash_egg.py` from the repo root.
Requires `cairosvg` (`pip install cairosvg`).
"""

from __future__ import annotations

import sys
from pathlib import Path

SIZE = 1024

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "app" / "assets" / "illustrations" / "pip_v2" / "mochi" / "s1_idle_1.svg"
DST = ROOT / "app" / "assets" / "brand" / "splash_egg.png"


def main() -> int:
    try:
        import cairosvg
    except ImportError:
        print("render_splash_egg: cairosvg is not installed (pip install cairosvg)", file=sys.stderr)
        return 1
    if not SRC.is_file():
        print(f"render_splash_egg: missing source art: {SRC}", file=sys.stderr)
        return 1
    DST.parent.mkdir(parents=True, exist_ok=True)
    cairosvg.svg2png(
        url=str(SRC),
        write_to=str(DST),
        output_width=SIZE,
        output_height=SIZE,
    )
    print(f"render_splash_egg: wrote {DST} ({SIZE}x{SIZE})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
