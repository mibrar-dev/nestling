#!/bin/bash
# loop.sh SCREEN_ID SIM_UDID [MAX_ITER]
# Runs plan -> build -> test -> qa-review -> ui-check -> find-bug -> (fixes) -> build ...
# for one screen on its own branch/worktree until every stage passes or MAX_ITER is hit.
# Events go to docs/screens/_status/events.log (watched by tools/agents/watch.sh).
set -u
ID="$1"; SIM="$2"; MAX="${3:-4}"
MAIN="$(cd "$(dirname "$0")/../.." && pwd)"
ROW=$(awk -F'\t' -v id="$ID" '$1==id' "$MAIN/docs/screens/SCREENS.tsv")
[ -z "$ROW" ] && { echo "unknown screen $ID"; exit 2; }
IFS=$'\t' read -r _ SLUG TITLE FEATURE ROUTE MODE SEED CHILD <<< "$ROW"
WT="$(dirname "$MAIN")/nestling-screens/$ID"
ST="$MAIN/docs/screens/_status"; mkdir -p "$ST"
EV="$ST/events.log"
ev() { echo "$(date +%H:%M:%S) $1 $ID ${2:-}" >> "$EV"; echo "$1 ${2:-}" > "$ST/$ID.loop"; }

MUSE="opencode-go/muse-spark-1.3-contributor#xhigh"
BUNNY="opencode-go/space-bunny-free#max"
DEEP="opencode-go/deepseek-v4.1-flash#max"

if [ ! -d "$WT" ]; then
  git -C "$MAIN" worktree add -q "$WT" -b "screen/$ID" main || git -C "$MAIN" worktree add -q "$WT" "screen/$ID"
fi
mkdir -p "$WT/docs/screens/$ID/ui"
# keep untracked large outputs out of git
grep -q "^app/build" "$WT/.gitignore" 2>/dev/null || true

render() { # stage_file iter fixes -> prompt on stdout
  local f="$1" it="$2" fx="$3"
  cat "$MAIN/tools/screens/stages/common.md" "$MAIN/tools/screens/stages/$f" | sed \
    -e "s|{ID}|$ID|g" -e "s|{ID_LOWER}|$(echo "$ID" | tr 'A-Z' 'a-z')|g" -e "s|{SLUG}|$SLUG|g" \
    -e "s|{TITLE}|$TITLE|g" -e "s|{FEATURE}|$FEATURE|g" -e "s|{ROUTE}|$ROUTE|g" -e "s|{MODE}|$MODE|g" \
    -e "s|{SEED}|$SEED|g" -e "s|{CHILD}|$CHILD|g" -e "s|{SIM}|$SIM|g" -e "s|{ITER}|$it|g" -e "s|{FIXES}|$fx|g"
}
stage() { # name model template iter fixes
  local name="$1" model="$2" tpl="$3" it="$4" fx="${5:-}"
  local title="$ID $name (screen loop)"
  local brief="$WT/docs/screens/$ID/.brief_${name}.md"
  render "$tpl" "$it" "$fx" > "$brief"
  local sid; sid=$(opencode session list 2>/dev/null | grep -F "$title" | head -1 | awk '{print $1}')
  STATUS_DIR="$ST" WORKDIR="$WT" "$MAIN/tools/agents/run_agent.sh" "${ID}_${name}_i${it}" "$model" "$brief" "${sid:--}" "$title"
}
verdict() { # file -> PASS/FAIL
  local f="$WT/docs/screens/$ID/$1"
  [ -f "$f" ] && grep -E "^VERDICT: (PASS|FAIL)" "$f" | tail -1 | awk '{print $2}' || echo FAIL
}

ev LOOP_START "feature=$FEATURE route=$ROUTE sim=$SIM"
FIXES=""
START="${START_IT:-1}"
if [ "$START" -gt 1 ]; then
  FIXES=" AND fix EVERY item in docs/screens/$ID/FIXES_$((START-1)).md (also un-skip and pass any skipped bug tests it references)"
fi
for IT in $(seq "$START" "$MAX"); do
  [ "$IT" -eq 1 ] && stage plan "$MUSE" 1_plan.md "$IT"
  # pick up shared fixes landed on main (orchestrator) before each build
  git -C "$WT" add -A >/dev/null 2>&1; git -C "$WT" commit -q -m "$ID: wip before sync" >/dev/null 2>&1
  git -C "$WT" merge -q --no-edit main >/dev/null 2>&1 || { git -C "$WT" merge --abort >/dev/null 2>&1; ev SYNC_CONFLICT "main"; }
  stage build "$MUSE" 2_build.md "$IT" "$FIXES"
  stage test  "$DEEP"  3_test.md   "$IT"
  stage review "$BUNNY" 4_review.md "$IT"
  stage ui    "$MUSE"  5_ui.md     "$IT"
  stage bugs  "$DEEP"  6_bugs.md   "$IT"
  B=$(verdict 2_build.md); T=$(verdict 3_test.md); R=$(verdict 4_review.md); U=$(verdict 5_ui.md); G=$(verdict 6_bugs.md)
  echo "iter $IT build=$B test=$T review=$R ui=$U bugs=$G" >> "$WT/docs/screens/$ID/LOOP.md"
  git -C "$WT" add -A app docs/screens/$ID >/dev/null 2>&1
  git -C "$WT" reset -q -- app/build >/dev/null 2>&1
  git -C "$WT" commit -q -m "$ID: loop iteration $IT (build=$B test=$T review=$R ui=$U bugs=$G)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" >/dev/null 2>&1
  ev ITER "i=$IT build=$B test=$T review=$R ui=$U bugs=$G"
  if [ "$B$T$R$U$G" = "PASSPASSPASSPASSPASS" ]; then ev READY "iterations=$IT"; exit 0; fi
  F="$WT/docs/screens/$ID/FIXES_$IT.md"
  { echo "# Fix list after iteration $IT"; for s in 2_build 3_test 4_review 5_ui 6_bugs; do
      v=$(verdict "$s.md"); [ "$v" = PASS ] && continue
      echo; echo "## From $s.md"; sed '/^VERDICT:/d' "$WT/docs/screens/$ID/$s.md" 2>/dev/null; done; } > "$F"
  FIXES=" AND fix EVERY item in docs/screens/$ID/FIXES_$IT.md (also un-skip and pass any skipped bug tests it references)"
done
ev NEEDS_REVIEW "max_iterations=$MAX"
exit 1
