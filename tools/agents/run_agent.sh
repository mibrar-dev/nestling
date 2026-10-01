#!/bin/bash
# run_agent.sh NAME MODEL BRIEF_FILE [SESSION_ID|-] [TITLE]
# Runs one opencode sub-agent with retries; writes status + events for monitoring.
NAME="$1"; MODEL="$2"; BRIEF="$3"; SID="${4:--}"; TITLE="${5:-$NAME}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ST="$ROOT/docs/pip-v2/status"; mkdir -p "$ST"
LOG="$ST/$NAME.log"; EV="$ST/events.log"
ev() { echo "$(date +%H:%M:%S) $1 $NAME ${2:-}" >> "$EV"; echo "$1" > "$ST/$NAME.status"; }
cd "$ROOT"
ev START "model=$MODEL"
for i in 1 2 3 4 5; do
  if [ "$SID" != "-" ]; then
    opencode run --auto -s "$SID" -m "$MODEL" "$(cat "$BRIEF")" < /dev/null > "$LOG" 2>&1
  else
    opencode run --auto --title "$TITLE" -m "$MODEL" "$(cat "$BRIEF")" < /dev/null > "$LOG" 2>&1
  fi
  rc=$?
  if grep -qE "temporarily overloaded|ENOTFOUND|ECONNRESET|socket connection was closed|rate limit|usage limit|Invalid upload request" "$LOG"; then
    ev RETRY "attempt=$i reason=$(grep -oE 'temporarily overloaded|ENOTFOUND|ECONNRESET|socket connection was closed|rate limit|usage limit|Invalid upload request' "$LOG" | head -1 | tr ' ' '_')"
    [ "$SID" = "-" ] && SID=$(opencode session list 2>/dev/null | grep "$TITLE" | head -1 | awk '{print $1}')
    [ -z "$SID" ] && SID="-"
    sleep 120; continue
  fi
  [ $rc -eq 0 ] && { ev DONE "bytes=$(wc -c <"$LOG" | tr -d ' ')"; exit 0; }
  ev FAILED "rc=$rc"; exit $rc
done
ev FAILED "retries_exhausted"; exit 1
