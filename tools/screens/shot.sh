#!/usr/bin/env bash
# Screenshot one screen on the iOS simulator, non-interactively.
#
#   tools/screens/shot.sh <worktree_app_dir> <route> <out_png> <sim_udid> \
#       [theme] [seed] [mode] [child]
#
# Launches the app with compile-time launch flags and waits until the frame
# is visually stable (two consecutive identical captures, max 25 s), then
# saves the PNG. Never runs an interactive `flutter run`: stdin is /dev/null,
# the tool is backgrounded, and the app is terminated afterwards.
#
# Defaults: theme=light seed=demo mode=parent child=maya.
# DISABLE_ANIMATIONS=1 is always passed for deterministic frames.
set -euo pipefail

if [ "$#" -lt 4 ]; then
  echo "usage: tools/screens/shot.sh <worktree_app_dir> <route> <out_png> <sim_udid> [theme] [seed] [mode] [child]" >&2
  exit 2
fi

APP_DIR="$1"; ROUTE="$2"; OUT="$3"; UDID="$4"
THEME="${5:-light}"; SEED="${6:-demo}"; MODE="${7:-parent}"; CHILD="${8:-maya}"
BUNDLE="uk.co.getnestling.app"

if [ ! -d "$APP_DIR" ]; then
  echo "shot: no such app dir: $APP_DIR" >&2
  exit 2
fi
mkdir -p "$(dirname "$OUT")"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# Boot the simulator if needed.
STATE="$(xcrun simctl list devices | grep "$UDID" | sed 's/.*(\(.*\))[^)]*$/\1/' | tail -n 1)"
if [ "$STATE" != "Booted" ]; then
  echo "shot: booting $UDID …"
  xcrun simctl boot "$UDID" >/dev/null 2>&1 || true
  open -a Simulator >/dev/null 2>&1 || true
fi

# Kill any previous copy of the app so the launch flags take effect.
xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true

LOG="$TMP/run.log"
cd "$APP_DIR"
# Cold builds take minutes; the tool runs detached and we poll below.
flutter run -d "$UDID" --debug --no-resident \
  --dart-define=SEED="$SEED" \
  --dart-define=INITIAL_ROUTE="$ROUTE" \
  --dart-define=THEME="$THEME" \
  --dart-define=APP_MODE="$MODE" \
  --dart-define=CHILD="$CHILD" \
  --dart-define=DISABLE_ANIMATIONS=1 \
  </dev/null >"$LOG" 2>&1 &
RUN_PID=$!
trap 'kill "$RUN_PID" >/dev/null 2>&1 || true; rm -rf "$TMP"' EXIT

echo "shot: route=$ROUTE theme=$THEME seed=$SEED mode=$MODE child=$CHILD"

# Phase 1: wait for the app process (build can take minutes cold).
READY=0
for _ in $(seq 1 300); do
  if ! kill -0 "$RUN_PID" 2>/dev/null; then
    echo "shot: flutter run exited early — log tail:" >&2
    tail -n 30 "$LOG" >&2 || true
    exit 1
  fi
  if xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -q "$BUNDLE"; then
    READY=1
    break
  fi
  sleep 2
done
if [ "$READY" != "1" ]; then
  echo "shot: app never launched (600 s) — log tail:" >&2
  tail -n 30 "$LOG" >&2 || true
  exit 1
fi

# Phase 2: wait until the drawn frame is stable (max 25 s).
PREV=""
STABLE=0
SHOT_OK=0
for _ in $(seq 1 25); do
  sleep 1
  xcrun simctl io "$UDID" screenshot "$TMP/cur.png" >/dev/null 2>&1 || continue
  CUR="$(md5 -q "$TMP/cur.png")"
  if [ -n "$PREV" ] && [ "$CUR" = "$PREV" ]; then
    STABLE=1
    break
  fi
  PREV="$CUR"
  cp "$TMP/cur.png" "$TMP/last.png" 2>/dev/null || true
done

if [ "$STABLE" = "1" ]; then
  cp "$TMP/cur.png" "$OUT"
  echo "shot: stable frame saved to $OUT"
else
  cp "$TMP/last.png" "$OUT" 2>/dev/null || true
  echo "shot: WARNING — frame never stabilised in 25 s; saved last capture to $OUT" >&2
  exit 1
fi

# Clean up: stop the tool and the app so the next shot starts fresh.
kill "$RUN_PID" >/dev/null 2>&1 || true
xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
trap - EXIT
rm -rf "$TMP"
