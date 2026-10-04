# K04 Quest detail — Stage 4 QA code review (iteration 1)

Scope reviewed: `git diff main...HEAD` limited to kid_home feature files:
`app/lib/features/kid_home/presentation/bloc/kid_home_bloc.dart`,
`app/lib/features/kid_home/presentation/views/quest_detail_view.dart`,
`app/test/features/kid_home/{k03_bugs_test,kid_home_view_test,quest_detail_geometry_test,quest_detail_view_test}.dart`,
plus `docs/screens/K04/**` notes.

Method: read the full view diff, the plan (`1_plan.md`), the build notes
(`2a_build_logic.md`, `2b_build_ui.md`), the test diffs for the two modified
test files, `RULES.md`, `DESIGN_SPEC.md` §5, `spacing.dart`, and
`nest_kid_button.dart`. Ran `flutter analyze` on the touched feature + tests:
**No issues found.** No code was edited (review only).

## Findings

1. **minor — `_kStepDivider` duplicates a spacing token.**
   `quest_detail_view.dart:48` defines `const double _kStepDivider = 2;` but
   `NestSpacing.gap2` (= 2) already exists in `tokens/spacing.dart` for
   exactly this "sub-4pt design px" role. Fix: replace the constant with
   `NestSpacing.gap2` and drop the local (keep the PNG-cited comment).

2. **minor — copy-parity test folded, not a separate file.**
   `1_plan.md` §f item 3 asked for
   `quest_detail_copy_parity_test.dart`. The copy-parity assertions
   ("Tick each bit off…", "Pip cheering you on", "I did it!",
   "Plus 15 coins", "Clothes in the basket", …) live instead as
   `group('K04 quest detail — copy parity')` inside
   `quest_detail_view_test.dart:579`. Coverage is equivalent; no action
   required beyond noting the plan/ filename drift.

3. **minor — `_resolveQuest` silently falls back on a childId mismatch.**
   `quest_detail_view.dart:117-134`: if `extra.childId` does not equal the
   active child, the questId branch is skipped and the view falls through to
   the design-quest/first-to-do fallback rather than showing
   `_QuestMissing`. This matches the plan (§b item 1) and items shown always
   belong to the active child, but the code comment at line 105-108 ("an id
   that no longer resolves is an unknown quest, NOT a licence to show a
   different one") does not cover the mismatched-childId path. Consider
   either extending the comment or treating a foreign-child `extra` as
   `_QuestMissing`. Non-blocking.

4. **minor — `_StepRow` reports `enabled: true` unconditionally.**
   `quest_detail_view.dart:668`: the Semantics node always announces the row
   enabled, even when the quest is done (`_isDone`) and by product the
   checklist is informational. Deterministic and tappable-to-review is
   arguably intended (matches the plan); a `enabled: !_isDone` would
   communicate more accurately to AT. Optional.

## Checks that passed

- **RULES §1 paths**: diff touches only
  `app/lib/features/kid_home/presentation/{bloc,views}/**`,
  `app/test/features/kid_home/**`, `docs/screens/K04/**`. No shared
  (`core/`, `app/`, other features, `tools/`) edits; no SHARED_REQUEST needed
  per plan §g.
- **Architecture**: BLoC-per-screen preserved (`KidHomeBloc`); the only bloc
  change is the documented one-line `stepsFor` pass-through getter with no
  event/state additions; domain/data untouched; no navigation inside the
  bloc; views never read `GetIt` (only tests do, via `registerSingleton`).
- **Design-system reuse / tokens**: tile, rows, dots, buttons, coin pill,
  bubble, empty state, toast, icon button all reuse shared components;
  colours/radii/shadows come from `tokens.*` (`peachTint`, `kidShadow`,
  `ink/line/leaf/onLeaf/surface`); `Colors.transparent` is the same
  established pattern as K03; spacing comes from `NestSpacing` (s1/s3/s4/s8,
  gap6/gap10 jibes via the shadow-room comment). Documented design-px
  literals (120/40/60/64/22) are named and commented with their PNG origin,
  matching the K03 precedent. No `google_fonts`/`GoogleFonts`, no
  `DateTime.now()`, no `name[0]`, no `subscription_status` writes, no
  clock-derived ids anywhere in the diff.
- **PIP rule**: the view renders the child's own `PipAvatar` from DB fields
  via `pipStyleOf/pipSkinOf/pipAccessoryOf` with `stage: pipStage.clamp(1,4)`
  (`quest_detail_view.dart` cheer row, failure, missing states); no
  `pip_stage_*.svg` in product code.
- **Bottom edge (owner rule)**: the kid-bar `Container` paints
  `tokens.surface` behind `SafeArea(top: false)`, so the surface runs to the
  physical edge in light and dark; geometry test pins the bar rect.
- **Accessibility**: every custom control (step rows) exposes
  `Semantics(button: true, toggled:, onTap:, label:)`; disabled primary
  passes no tap and reports `enabled: false`; tests assert
  `hasAction(SemanticsAction.tap)` + `performAction` behaviour.
- **Error handling / tap guards**: `_busy` + post-frame release +
  `completionToken` reset mirror the K03-BUG-1/6/9/11 fixes; failure toasts
  and success rides `justCompletedQuestId` only; `Try again` re-dispatches
  `KidHomeLoadRequested`.
- **Performance**: `_ticked` is a local `Set<int>` (no stream churn),
  `stepsFor` is pure/sync called once per build, no animation controllers,
  `Clipping: Clip.hardEdge` on the card, no rebuild-storm patterns; the
  loading/failure branches are small const widget trees.
- **Children's Code**: kid mode surfaces no analytics, no ads, no external
  links, no money in £ (coins only: `+15`), no negative framing copy.
- **Tests**: new `quest_detail_view_test.dart` (629 lines) and
  `quest_detail_geometry_test.dart` (294 lines) cover copy parity, checklist
  toggle via semantics, double-tap once-dispatch, success navigation, error
  toast, done-state disable, 320 px + 1.3 text overflow, geometry pins and
  bar-to-edge. The two edited legacy tests were updated to the new copy
  anchor — strictly stronger than before (they also assert a stacked second
  route does not render, and that one Back leaves the detail).

## Verdict

No blocker/major findings. Four minors (one token duplication, one
plan/filename drift, one comment-coverage gap, one optional AT accuracy
tune).

VERDICT: PASS
