#!/usr/bin/env bash
# Render the PipStage artboard for every growth stage into /tmp/ps<N>.png.
#
# --advance matters: without it the CLI captures frame 0, which is the REST
# pose and hides every rig. 40 frames (0.67s) also lets the stage layer finish
# its 120ms visibility blend.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
export RIVE_HOME="$ROOT/tools/rive/.rive"
export PATH="$ROOT/tools/rive/bin:$PATH"

cd "$ROOT/tools/rive"
python3 gen_pip.py >/dev/null
python3 -c "import gen_pip, os; gen_pip.emit_preview(os.path.join(os.getcwd(), 'pip-preview'))"

cd "$ROOT"
rive tools/rive/pip --verify --format=json >/dev/null
rive tools/rive/pip --once --format=json >/dev/null
rive tools/rive/pip-preview --once >/dev/null 2>&1

out="${1:-/tmp}"
for s in 1 2 3 4; do
  rive tools/rive/pip-preview --artboard=PipStage \
      --screenshot="$out/ps$s.png" --advance=40 \
      --viewport=350x260 --fit=contain --data="stage=$s" >/dev/null 2>&1
done
md5 "$out"/ps1.png "$out"/ps2.png "$out"/ps3.png "$out"/ps4.png
