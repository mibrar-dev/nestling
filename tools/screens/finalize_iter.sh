#!/bin/bash
# finalize_iter.sh ID N — close an iteration that was interrupted (restart,
# crash): commit the worktree, append the verdict line to LOOP.md and write
# FIXES_N.md exactly as loop.sh would. Then resume with:
#   START_IT=$((N+1)) bash tools/screens/loop.sh ID SIM [MAX]
set -u
ID="$1"; N="$2"
MAIN="$(cd "$(dirname "$0")/../.." && pwd)"
WT="$(dirname "$MAIN")/nestling-screens/$ID"
D="$WT/docs/screens/$ID"
verdict() { local f="$D/$1"; [ -f "$f" ] && grep -E "^VERDICT: (PASS|FAIL)" "$f" | tail -1 | awk '{print $2}' || echo FAIL; }
B=$(verdict 2_build.md); T=$(verdict 3_test.md); R=$(verdict 4_review.md); U=$(verdict 5_ui.md); G=$(verdict 6_bugs.md)
echo "iter $N build=$B test=$T review=$R ui=$U bugs=$G (finalized after interruption)" >> "$D/LOOP.md"
{ echo "# Fix list after iteration $N"; for s in 2_build 3_test 4_review 5_ui 6_bugs; do
    v=$(verdict "$s.md"); [ "$v" = PASS ] && continue
    echo; echo "## From $s.md"
    if [ -f "$D/$s.md" ]; then sed '/^VERDICT:/d' "$D/$s.md"; else echo "(stage did not run in iteration $N — run it fully next iteration)"; fi
  done; } > "$D/FIXES_$N.md"
git -C "$WT" add -A app docs/screens/$ID >/dev/null 2>&1
git -C "$WT" reset -q -- app/build >/dev/null 2>&1
git -C "$WT" commit -q -m "$ID: loop iteration $N finalized after interruption (build=$B test=$T review=$R ui=$U bugs=$G)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" >/dev/null 2>&1
echo "$ID iter $N: build=$B test=$T review=$R ui=$U bugs=$G -> FIXES_$N.md"
