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
# Rate-limit cooldown shared by all agents: a model that rate-limited in the
# last 2 h is skipped in favour of Space Bunny (file: _status/cooldown/<model>).
CD="$ST/cooldown"; mkdir -p "$CD"; CDF="$CD/$(echo "$MODEL" | tr '/#' '__')"
# First model not in cooldown, in preference order (Muse is the last resort).
pick_model() { for m in "opencode-go/space-bunny-free#max" "opencode-go/deepseek-v4.1-flash#max" "opencode-go/muse-spark-1.3-contributor#xhigh"; do
  [ "$m" = "$1" ] && continue; f="$CD/$(echo "$m" | tr '/#' '__')"
  if [ ! -f "$f" ] || [ $(( $(date +%s) - $(cat "$f") )) -ge 7200 ]; then echo "$m"; return; fi; done; echo "opencode-go/muse-spark-1.3-contributor#xhigh"; }
if [ -f "$CDF" ] && [ $(( $(date +%s) - $(cat "$CDF") )) -lt 7200 ]; then
  ORIG="$MODEL"; MODEL="$(pick_model "$MODEL")"; SID="-"
  ev START "model=$MODEL cooldown_from=$ORIG"
else
  ev START "model=$MODEL"
fi
for i in 1 2 3 4 5; do
  # Orchestrator pause (e.g. provider account out of funds): wait, keep the loop alive.
  while [ -f "$ST/PAUSE" ]; do sleep 60; done
  if [ "$SID" != "-" ]; then
    opencode run --auto -s "$SID" -m "$MODEL" "$(cat "$BRIEF")" < /dev/null > "$LOG" 2>&1 &
  else
    opencode run --auto --title "$TITLE" -m "$MODEL" "$(cat "$BRIEF")" < /dev/null > "$LOG" 2>&1 &
  fi
  OC=$!
  # Idle watchdog: an agent whose log has not grown for IDLE_MAX seconds is
  # stuck (hung tool call, dead socket). Kill it; the retry resumes the same
  # session, so the work already done is kept.
  IDLE_MAX="${IDLE_MAX:-1200}"; idle=0; last=-1
  while kill -0 $OC 2>/dev/null; do
    sleep 30
    sz=$(wc -c < "$LOG" 2>/dev/null | tr -d ' ')
    if [ "$sz" = "$last" ]; then idle=$((idle+30)); else idle=0; last=$sz; fi
    # A run that has printed NOTHING for 5 min is a dead session resume: kill it
    # early and retry in a FRESH session (new title) instead of the same one.
    if [ "${sz:-0}" = 0 ] && [ $idle -ge 300 ]; then
      kill $OC 2>/dev/null; pkill -P $OC 2>/dev/null; FRESH=1; break
    fi
    if [ $idle -ge $IDLE_MAX ]; then
      pkill -P $OC 2>/dev/null; kill $OC 2>/dev/null; echo "Error: idle watchdog killed the agent after ${idle}s" >> "$LOG"; break
    fi
  done
  wait $OC; rc=$?
  if [ "${FRESH:-0}" = 1 ]; then FRESH=0; ev RETRY "attempt=$i reason=empty_session_fresh"; SID="-"; TITLE="$TITLE (fresh $(date +%H%M))"; continue; fi
  # Reap flutter_tester processes this agent orphaned in its worktree (killed
  # test runs leave them parented to launchd, eating memory and CPU).
  WD="$(pwd)"; for tp in $(pgrep -f flutter_tester); do
    [ "$(ps -p "$tp" -o ppid= | tr -d ' ')" = 1 ] && lsof -p "$tp" 2>/dev/null | awk '$4=="cwd"{print $9}' | grep -q "^$WD" && kill "$tp" 2>/dev/null
  done
  if grep -q "idle watchdog killed" "$LOG"; then
    ev RETRY "attempt=$i reason=idle_${IDLE_MAX}s"
    [ "$SID" = "-" ] && SID=$(opencode session list 2>/dev/null | grep -F "$TITLE" | head -1 | awk '{print $1}')
    [ -z "$SID" ] && SID="-"
    BRIEF_ORIG="${BRIEF_ORIG:-$BRIEF}"; CONT="$ST/$NAME.continue.md"
    { echo "CONTINUE: your previous run stalled and was restarted (work on disk is kept). Check what you already changed (git status/diff), avoid the step that hung (e.g. a never-ending command), and finish the task:"; echo; cat "$BRIEF_ORIG"; } > "$CONT"; BRIEF="$CONT"
    continue
  fi
  if [ $rc -ne 0 ] && [ "$SID" != "-" ] && tail -40 "$LOG" | grep -qE "has expired|Session not found|reasoning item .* was not found"; then
    ev RETRY "session_expired=$SID starting_fresh"; SID="-"; continue
  fi
  # Only a failed exit whose LAST lines show a provider error counts; agent
  # output (ps listings, docs) may mention "rate limit" harmlessly.
  if [ $rc -ne 0 ] && tail -40 "$LOG" | grep -qiE "temporarily overloaded|ENOTFOUND|ECONNRESET|ETIMEDOUT|socket connection was closed|rate limit|usage limit|Invalid upload request|not valid JSON|Upstream|502 Bad Gateway|503 Service|504 Gateway|Internal Server Error|fetch failed"; then
    ev RETRY "attempt=$i reason=$(tail -40 "$LOG" | grep -oiE 'temporarily overloaded|ENOTFOUND|ECONNRESET|ETIMEDOUT|socket connection was closed|rate limit|usage limit|Invalid upload request|not valid JSON|Upstream|502 Bad Gateway|503 Service|504 Gateway|Internal Server Error|fetch failed' | head -1 | tr ' ' '_')"
    [ "$SID" = "-" ] && SID=$(opencode session list 2>/dev/null | grep "$TITLE" | head -1 | awk '{print $1}')
    [ -z "$SID" ] && SID="-"
    # Free models rate-limit hard: after two rate limits, fall back to Space Bunny (same session title, fresh session).
    if tail -40 "$LOG" | grep -qiE "rate limit|usage limit|Upstream|502 Bad Gateway|503 Service|504 Gateway"; then
      RL=$(( ${RL:-0} + 1 )); date +%s > "$CD/$(echo "$MODEL" | tr '/#' '__')"
      if [ "$RL" -ge 2 ]; then
        NEW="$(pick_model "$MODEL")"; ev RETRY "fallback_model=$NEW from=$MODEL"; MODEL="$NEW"; SID="-"; RL=0
      fi
    fi
    sleep 120; continue
  fi
  # A "successful" run that printed almost nothing ended after its first
  # message (provider hiccup, no tool calls). Retry; after two, switch model
  # (Space Bunny -> DeepSeek, others -> Space Bunny) and cool the bad one down.
  if [ $rc -eq 0 ] && [ "$(wc -c < "$LOG" | tr -d ' ')" -lt 400 ]; then
    EMPTY=$(( ${EMPTY:-0} + 1 )); ev RETRY "attempt=$i reason=empty_run model=$MODEL"
    if [ "$EMPTY" -ge 2 ]; then
      date +%s > "$CD/$(echo "$MODEL" | tr '/#' '__')"
      NEW="$(pick_model "$MODEL")"
      ev RETRY "fallback_model=$NEW from=$MODEL"; MODEL="$NEW"; SID="-"; EMPTY=0
    fi
    sleep 20; continue
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
