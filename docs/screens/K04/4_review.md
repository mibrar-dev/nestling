# K04 Quest detail — Stage 4 QA code review (iteration 2)

Scope reviewed: `git diff main...HEAD` for the kid_home feature, this time
including the iteration-2 fixes from `6_bugs.md` / `FIXES_1.md` and the
new orchestrator mandate in `ORCHESTRATOR_NOTES.md`:
`app/lib/features/kid_home/presentation/bloc/kid_home_bloc.dart`,
`app/lib/features/kid_home/presentation/views/quest_detail_view.dart`,
`app/lib/core/design_system/components/nest_balanced_text.dart` (flagged,
see finding 1), `app/test/features/kid_home/{k03_bugs_test,k04_bugs_test,kid_home_view_test,quest_detail_geometry_test,quest_detail_view_test}.dart`.

Method: read the updated diffs, `ORCHESTRATOR_NOTES.md`,
`SHARED_REQUEST.md`, `6_bugs.md`, `FIXES_1.md`, and re-checked the
iteration-1 minors. Ran `flutter analyze` on the touched core file,
feature and tests: **No issues found.** No code was edited (review only).

## Findings

1. **minor — shared file edited under a SHARED_REQUEST that says "applied
   locally".** RULES §1 bars screen agents from touching `app/lib/core/**`,
   but `nest_balanced_text.dart` was edited on `screen/K04` and only then
   recorded in `SHARED_REQUEST.md`. The change itself is correct and
   well-scoped (K04-BUG-1: probe with the natural line count instead of the
   maxLines-capped one; fall back to full-width `Text` when the natural
   layout exceeds the cap), and the request is properly filed for the
   orchestrator to merge upstream deliberately. Process-wise, the fix
   should have been filed first and applied verbatim after the orchestrator
   merge, or explicitly sanctioned. Not a blocker: the behaviour is right,
   covered by `k04_bugs_test.dart`, and other callers only gain the
   readable-full-width path.

2. **minor — K04-BUG-2 resolution narrowed the fallbacks but the plan
   (`1_plan.md` §b) still says the q-tidy fallback applies "when it is
   among the child's quests … else first `to_do`".** The code now treats any
   string `questId` as authoritative (`_resolveQuest` returns null — the
   `_QuestMissing` screen — when it misses), and only a questId-less extra
   hits the direct-launch fallbacks. That is the safer behaviour the bug
   hunt wanted; the plan text is now stale. Fix: annotate §b with
   "superseded by K04-BUG-2 fix in iteration 2".

3. **minor — the step-row Semantics still report `enabled: true`
   unconditionally** (`quest_detail_view.dart` `_StepRow`, unchanged from
   iteration 1). After done, the checklist is informational; passing
   `enabled: !done` would tell AT more accurately. Deliberate-per-plan, so
   a polish item only.

## Checks that passed

- **Orchestrator mandates**: `ORCHESTRATOR_NOTES.md` (14:28) now satisfied —
  `_iconFor` maps `bed/sofa → NestIcons.questBed`, `dishwasher/plate →
  questDishes`, `hoover → questHoover`, `bin(s)/shirt/bag → questBins`,
  `book → NestIcons.book`, `paw/leaf → NestIcons.paw`, `_ => questCard`,
  the same mapping as P09's tiles; K04-BUG-3 proof covers it.
- **K04-BUG-1 fixed**: `NestBalancedText` binary-search now probes with the
  natural line count, and `build` returns the full-width `Text` (with its
  own maxLines ellipsis) when the natural count exceeds the cap — a
  DB-driven title longer than three lines can no longer collapse to a
  0.1 px invisible gap. K04-BUG-1 proofs are un-skipped and passing.
- **K04-BUG-2 fixed**: `_resolveQuest` (quest_detail_view.dart:115-139)
  returns null (honest `_QuestMissing`) when `extra.childId` names another
  child or `extra.questId` doesn't resolve; the q-tidy/first-to-do
  fallbacks only serve the direct-launch (no-questId) path.
- **Paths**: besides the documented shared-component edit, everything else
  is inside `app/lib/features/kid_home/presentation/**`,
  `app/test/features/kid_home/**`, `docs/screens/K04/**`.
- **Architecture**: BLoC-per-screen intact; no new events/state; bloc still
  just passes `stepsFor` through; no navigation in the bloc; views never
  read `GetIt`.
- **Design-system usage**: all screen chrome reuses shared components and
  tokens (tile, dots, rows, `NestKidButton`, `NestCoinPill.large`,
  `NestSpeechBubble`, `PipAvatar`, `NestLockButton`, `NestHomeIndicator`,
  `NestEmptyState`, `showNestToast`); no hard-coded colours/fonts;
  documented design-px literals named and PNG-cited; `Colors.transparent`
  matches the K03 pattern.
- **Owner rules**: kid bar paints `tokens.surface` through the bottom
  `SafeArea` inset to the physical edge (geometry-pinned); 20 px gutters
  consistent across tile/card/bar; the child's own PipAvatar on every state
  (failure/missing/cheer) from DB `pip_*` fields; Pip rule, Clock rule,
  `nestAvatarInitial`, `newId`, periods, chip-wrap, letter-spacing — all
  re-verified, none regressed.
- **Accessibility**: step rows expose `Semantics(button: true, toggled:,
  onTap:, label:)` with tests asserting `hasAction(tap)` and state flips;
  disabled primary button reports `enabled: false` and no tap.
- **Error handling / guards**: `_busy` + post-frame release + token reset;
  failure toasts and success rides `justCompletedQuestId` only; retry
  re-dispatches load; gate lock has the double-tap guard.
- **Children's Code**: no analytics/ads/external calls; coins only; no
  nagging copy.
- **Tests**: `k04_bugs_test.dart` bug proofs run (un-skipped per
  `SHARED_REQUEST.md`) and pass; `flutter analyze` clean; no
  `google_fonts`/`GoogleFonts`, no `DateTime.now()` in the diff.

## Verdict

No blocker/major findings. Three minor items (shared-file process note,
stale plan §b text, optional `enabled` semantics).

VERDICT: PASS
