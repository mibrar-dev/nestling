#!/usr/bin/env bash
# One-command visual QA for the design-system gallery.
#
#   tools/sim_shots.sh <label>
#
# Drives the app on the booted iPhone 16e simulator, screenshots every
# `ds-section-*` block in light and dark, writes the PNGs to
# design/qa/sim/<label>/, and builds a contact sheet per theme.
#
# Compare two runs with:  tools/sim_compare.py <labelA> <labelB>
set -euo pipefail

LABEL="${1:-}"
if [ -z "$LABEL" ]; then
  echo "usage: tools/sim_shots.sh <label>" >&2
  exit 2
fi

DEVICE="${QA_DEVICE:-604697A9-11DA-462F-9837-396E9CA2493A}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="$ROOT/design/qa/sim/$LABEL"

if [ ! -d "$ROOT/app" ]; then
  echo "no app/ next to tools/ — run this from the repo root" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
export RUN_LABEL="$LABEL"

echo "── design-system shots ──────────────────────────────"
echo "  run     $LABEL"
echo "  device  $DEVICE"
echo "  output  design/qa/sim/$LABEL/"

cd "$ROOT/app"
# Builds the app; takes a few minutes on a cold build directory.
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/gallery_shots_test.dart \
  -d "$DEVICE"

cd "$ROOT"
python3 tools/sim_sheet.py "$LABEL"

SHOTS=$(find "$OUT_DIR" -maxdepth 1 -name '*.png' ! -name 'SHEET_*' | wc -l | tr -d ' ')
echo "── done ────────────────────────────────────────────"
echo "  $SHOTS screenshots in design/qa/sim/$LABEL/"
ls -1 "$OUT_DIR"/SHEET_*.png 2>/dev/null || true
echo
echo "  compare with a later run:"
echo "    tools/sim_compare.py $LABEL <next-label>"
