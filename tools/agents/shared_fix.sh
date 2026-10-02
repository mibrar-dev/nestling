#!/bin/bash
# shared_fix.sh NAME TASK_FILE [MODEL]
# Delegates a shared/foundation fix to an OpenCode agent on branch shared/NAME.
# The orchestrator reviews docs/screens/_shared/NAME_REPORT.md + the diff, then merges.
set -u
NAME="$1"; TASK="$2"; MODEL="${3:-opencode-go/muse-spark-1.3-contributor#xhigh}"
MAIN="$(cd "$(dirname "$0")/../.." && pwd)"
WT="$(dirname "$MAIN")/nestling-screens/_shared_$NAME"
[ -d "$WT" ] || git -C "$MAIN" worktree add -q "$WT" -b "shared/$NAME" main
BRIEF="$WT/docs/screens/_shared/.brief_$NAME.md"; mkdir -p "$(dirname "$BRIEF")"
{ sed "s|{NAME}|$NAME|g" "$MAIN/docs/screens/_shared/HEADER.md"; cat "$TASK"; } > "$BRIEF"
STATUS_DIR="$MAIN/docs/screens/_status" WORKDIR="$WT" "$MAIN/tools/agents/run_agent.sh" "shared_$NAME" "$MODEL" "$BRIEF" - "Nestling shared fix $NAME"
