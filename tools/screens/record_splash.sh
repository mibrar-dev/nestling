#!/usr/bin/env bash
# Record a cold-start launch (native splash -> in-app hatch) on the iOS
# simulator, non-interactively.
#
#   tools/screens/record_splash.sh <worktree_app_dir> <sim_udid> <out_mp4> \
#       [extra flutter-run args...]
#
# Launches WITHOUT INITIAL_ROUTE so the in-app launch splash shows (shot.sh
# always forces a route, which skips it). Never runs an interactive
# `flutter run`: stdin is /dev/null, the tool is backgrounded, and the app is
# terminated afterwards. Extra args can pass dart-defines, e.g.
# `--dart-define=DISABLE_ANIMATIONS=1` for the Reduce Motion still path.
set -euo pipefail

if [ "$#" -lt 3 ]; then
  echo "usage: tools/screens/record_splash.sh <worktree_app_dir> <sim_udid> <out_mp4> [extra args...]" >&2
  exit 2
fi

APP_DIR="$1"; UDID="$2"; OUT="$3"; shift 3
BUNDLE="uk.co.getnestling.app"

if [ ! -d "$APP_DIR" ]; then
  echo "record: no such app dir: $APP_DIR" >&2
  exit 2
fi
mkdir -p "$(dirname "$OUT")"
TMP="$(mktemp -d)"
cleanup() {
  if [ -n "${RUN_PID:-}" ]; then
    kill "$RUN_PID" >/dev/null 2>&1 || true
    sleep 2
    if kill -0 "$RUN_PID" 2>/dev/null; then
      kill -9 "$RUN_PID" >/dev/null 2>&1 || true
    fi
  fi
  if [ -n "${REC_PID:-}" ]; then
    kill -INT "$REC_PID" >/dev/null 2>&1 || true
    sleep 1
  fi
  xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
  rm -rf "$TMP"
}
trap cleanup EXIT

# Fresh process so this is a real cold start (native splash included).
xcrun simctl terminate "$UDID" "$BUNDLE" >/dev/null 2>&1 || true
rm -f "$OUT"

xcrun simctl io "$UDID" recordVideo --codec=h264 "$OUT" </dev/null >"$TMP/rec.log" 2>&1 &
REC_PID=$!
sleep 1

cd "$APP_DIR"
# shellcheck disable=SC2086
flutter run -d "$UDID" --debug --no-resident \
  --dart-define=SEED=demo \
  $* </dev/null >"$TMP/run.log" 2>&1 &
RUN_PID=$!

READY=0
for _ in $(seq 1 150); do
  if xcrun simctl spawn "$UDID" launchctl list 2>/dev/null | grep -q "$BUNDLE"; then
    READY=1
    break
  fi
  sleep 2
done
if [ "$READY" != "1" ]; then
  echo "record: app never launched (300 s) — log tail:" >&2
  tail -n 30 "$TMP/run.log" >&2 || true
  exit 1
fi

# Splash (1.6 s) + landing on the first route, with margin.
sleep 6

# Stop the recording and VERIFY it actually stopped: `simctl io recordVideo`
# may fork, so $REC_PID can point at an already-dead parent while the
# recorder keeps running. Match our own invocation (UDID + outfile) and
# escalate INT -> TERM -> KILL until it is gone.
stop_recording() {
  local sig="$1"
  local pid
  pid="$(pgrep -f "simctl io $UDID recordVideo.*$OUT" || true)"
  if [ -z "$pid" ]; then
    return 0
  fi
  kill "-$sig" "$pid" >/dev/null 2>&1 || true
  return 1
}
for _ in $(seq 1 50); do
  if stop_recording INT; then
    break
  fi
  sleep 0.2
done
for _ in $(seq 1 25); do
  if stop_recording TERM; then
    break
  fi
  sleep 0.2
done
stop_recording KILL || true
sleep 1
REC_PID=""

cleanup
trap - EXIT
echo "record: saved $OUT"
