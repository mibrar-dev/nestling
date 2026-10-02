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
  local out="$WT/docs/screens/$ID/${tpl%.md}.md" mark="$WT/docs/screens/$ID/.start_${name}"
  touch "$mark"
  STATUS_DIR="$ST" WORKDIR="$WT" "$MAIN/tools/agents/run_agent.sh" "${ID}_${name}_i${it}" "$model" "$brief" "${sid:--}" "$title"
  # The stage must (re)write its report with a VERDICT line; nudge once if not.
  if [ ! -f "$out" ] || [ "$out" -ot "$mark" ] || ! grep -qE "^VERDICT: (PASS|FAIL)" "$out"; then
    local nudge="$WT/docs/screens/$ID/.brief_${name}_nudge.md"
    { echo "You ended without writing docs/screens/$ID/${tpl} for iteration $it. Write it NOW from your findings; its last line must be exactly VERDICT: PASS or VERDICT: FAIL. Original brief:"; echo; cat "$brief"; } > "$nudge"
    sid=$(opencode session list 2>/dev/null | grep -F "$title" | head -1 | awk '{print $1}')
    ev NUDGE "${name}_i${it} missing_report"
    STATUS_DIR="$ST" WORKDIR="$WT" "$MAIN/tools/agents/run_agent.sh" "${ID}_${name}_i${it}_nudge" "$model" "$nudge" "${sid:--}" "$title"
  fi
}
verdict() { # file -> PASS/FAIL
  local f="$WT/docs/screens/$ID/$1"
  [ -f "$f" ] && grep -E "^VERDICT: (PASS|FAIL)" "$f" | tail -1 | awk '{print $2}' || echo FAIL
}


# --- simulator pool: SIM=pool borrows a simulator only for the UI stage ---
POOL_FILE="$MAIN/docs/screens/SIM_POOL.txt"; LOCKS="$ST/simlock"; mkdir -p "$LOCKS"
HELD_SIM=""
acquire_sim() {
  while true; do
    for u in $(grep -v '^#' "$POOL_FILE"); do
      if mkdir "$LOCKS/$u" 2>/dev/null; then echo "$ID $$" > "$LOCKS/$u/owner"; HELD_SIM="$u"; return 0; fi
      # stale lock: owner loop gone
      o=$(awk '{print $2}' "$LOCKS/$u/owner" 2>/dev/null); if [ -n "$o" ] && ! kill -0 "$o" 2>/dev/null; then rm -rf "$LOCKS/$u"; fi
    done
    sleep 15
  done
}
release_sim() { [ -n "$HELD_SIM" ] && rm -rf "$LOCKS/$HELD_SIM"; HELD_SIM=""; }
trap release_sim EXIT

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
  stage test  "$BUNNY" 3_test.md   "$IT"   # owner: Space Bunny max is fast at code
  stage review "$BUNNY" 4_review.md "$IT"
  if [ "$SIM" = "pool" ]; then acquire_sim; ev SIM_ACQUIRED "$HELD_SIM"; SIM_SAVE="$SIM"; SIM="$HELD_SIM"; fi
  stage ui    "$MUSE"  5_ui.md     "$IT"
  if [ -n "$HELD_SIM" ]; then release_sim; SIM="$SIM_SAVE"; fi
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
