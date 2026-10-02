#!/bin/bash
# run_agent.sh NAME MODEL BRIEF_FILE [SESSION_ID|-] [TITLE]
# Runs one opencode sub-agent with retries; writes status + events for monitoring.
NAME="$1"; MODEL="$2"; BRIEF="$(cd "$(dirname "$3")" && pwd)/$(basename "$3")"; SID="${4:--}"; TITLE="${5:-$NAME}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ST="${STATUS_DIR:-$ROOT/docs/screens/_status}"; mkdir -p "$ST"
LOG="$ST/$NAME.log"; EV="$ST/events.log"
ev() { echo "$(date +%H:%M:%S) $1 $NAME ${2:-}" >> "$EV"; echo "$1" > "$ST/$NAME.status"; }
cd "${WORKDIR:-$ROOT}"
[ -s "$BRIEF" ] || { ev FAILED "empty_or_missing_brief=$BRIEF"; exit 2; }
ev START "model=$MODEL"
for i in 1 2 3 4 5; do
  if [ "$SID" != "-" ]; then
    opencode run --auto -s "$SID" -m "$MODEL" "$(cat "$BRIEF")" < /dev/null > "$LOG" 2>&1
  else
    opencode run --auto --title "$TITLE" -m "$MODEL" "$(cat "$BRIEF")" < /dev/null > "$LOG" 2>&1
  fi
  rc=$?
  if [ $rc -ne 0 ] && [ "$SID" != "-" ] && tail -40 "$LOG" | grep -qE "has expired|Session not found|reasoning item .* was not found"; then
    ev RETRY "session_expired=$SID starting_fresh"; SID="-"; continue
  fi
  # Only a failed exit whose LAST lines show a provider error counts; agent
  # output (ps listings, docs) may mention "rate limit" harmlessly.
  if [ $rc -ne 0 ] && tail -40 "$LOG" | grep -qE "temporarily overloaded|ENOTFOUND|ECONNRESET|ETIMEDOUT|socket connection was closed|rate limit|usage limit|Invalid upload request|not valid JSON|Upstream|502 Bad Gateway|503 Service|504 Gateway|Internal Server Error|fetch failed"; then
    ev RETRY "attempt=$i reason=$(tail -40 "$LOG" | grep -oE 'temporarily overloaded|ENOTFOUND|ECONNRESET|ETIMEDOUT|socket connection was closed|rate limit|usage limit|Invalid upload request|not valid JSON|Upstream|502 Bad Gateway|503 Service|504 Gateway|Internal Server Error|fetch failed' | head -1 | tr ' ' '_')"
    [ "$SID" = "-" ] && SID=$(opencode session list 2>/dev/null | grep "$TITLE" | head -1 | awk '{print $1}')
    [ -z "$SID" ] && SID="-"
    sleep 120; continue
  fi
  # Killed by the OS (memory pressure) or interrupted: retry, never treat as done.
  if [ $rc -eq 137 ] || [ $rc -eq 143 ] || [ $rc -eq 130 ] || [ $rc -eq 9 ]; then
    ev RETRY "attempt=$i reason=killed_rc$rc"
    [ "$SID" = "-" ] && SID=$(opencode session list 2>/dev/null | grep "$TITLE" | head -1 | awk '{print $1}')
    [ -z "$SID" ] && SID="-"
    sleep 60; continue
  fi
  [ $rc -eq 0 ] && { ev DONE "bytes=$(wc -c <"$LOG" | tr -d ' ')"; exit 0; }
  ev FAILED "rc=$rc"; exit $rc
done
ev FAILED "retries_exhausted"; exit 1
