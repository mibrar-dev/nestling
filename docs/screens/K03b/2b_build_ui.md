# 2b BUILD UI — K03b Kid home all done (iteration 2)

UI chunk of the parallel build. Owns only `presentation/views/**`,
`presentation/widgets/**` and view/widget tests. Re-read
`docs/screens/K03b/1_plan.md` and `docs/screens/K03b/2a_build_logic.md`
(iteration 2, VERDICT PASS) before finishing; codes against its CONTRACT
CHANGES: `KidQuest.needsApproval` (default true) and creation-order
`state.items` (title sort dropped in the repository).

## Files changed (UI layer only)

- `app/lib/features/kid_home/presentation/views/kid_home_view.dart`
  - `_AllDoneBody` geometry (FIXES_1 review finding 1 / K03B-BUG-1 / 04:52 D1):
    bubble → `SizedBox(s4=16)` (`.scroll > * + *` on `.k3-stage`), then
    `Stack(clipBehavior: Clip.none)` (confetti is `position: absolute`, never
    sizes the Stack; `Clip.none` reproduces the 14 px CSS overflow).
    Inside, `NestPetStage` wrapped in `Padding(top: gap14)` (`.k3-pet`
    margin 14), so bubble→pet = 16 + 14 = 30 and confetti `top: 4` measures
    from the design stage origin. Bubble-bottom→title-box is the design 272
    (16+14+226+16).
  - Nest art (K03B-BUG-3): new all-done-local `_kAllDoneNestBoxWidth/_kAllDoneNestBoxHeight`
    = 226/226 (browser `meet` square, letterboxed 17 px each side). K03's
    `_kNestBoxWidth/_kNestBoxHeight` (236/188) untouched — K03 must not move.
  - Shared slot bug (K03B-BUG-2) worked around feature-side per D1 (no touch
    of `nest_pet_stage.dart`/`pip_rive.dart`): added `_kAllDonePipBottom = 92`
    (HTML `.k3-pet .pip { bottom: 92px }`) as `pipBottom`, which takes the
    `explicitGeometry` early return that honours `slotHeight` (final return
    adds `_explicitBleed` → 257.4). `226 − 92 − 152 = −18` lands Pip at
    −18…134 vs design −16…134. Stage block is 226; Stack is 14+226 = 240, so
    the 250-tall confetti at top 4 overflows 14 past the stage like the CSS.
  - ROW META view branch (orchestrator 04:52, uses logic's `needsApproval`):
    not done → `+N` chip; done + no approval → `+N` chip (no status chip);
    `done_pending` + approval → `Waiting for Mum`; `approved` + approval →
    `Mum said yes!`. `_statusText` mirrors it (waiting → thumbs-up line,
    approved + approval → `Mum said yes!`, done + no approval → `Done`).
    K03 shares `_QuestCard`: demo waiting/to-do rows unchanged; approved
    demo rows move `Done` → `Mum said yes!` by mandate.
  - K03 not-done branch, header, dock, `_AllDoneBar`, copy, tokens all
    untouched. No `google_fonts`, no `DateTime.now()`, no `name[0]`.
- `app/test/features/kid_home/k03b_all_done_view_test.dart` (contains `view`):
  meta pin 2×`Done` → 2×`Mum said yes!`; order pin alphabetical →
  creation (dishwasher, reading, bins, tidy, hoover, table); fake
  `_allDoneItems` reordered to creation order; card semantics
  `Put the bins out, Done` → `…, Mum said yes!`. Kept the parallel
  logic-builder loop refactor (one test per control) intact.
- `app/test/features/kid_home/kid_home_view_test.dart` (contains `view`):
  order group → creation order (card 1 still dishwasher, so K03 design pin
  holds); 3 approved-chip pins `Done` → `Mum said yes!`; card semantics
  `Put the bins out, Done` → `…, Mum said yes!`; fake `_mayaItems`
  reordered to creation order. Out-of-period `Done`-findsNothing pins kept
  (to-do still shows `+N`).
- Did NOT touch: `domain/`, `data/`, `bloc/`, `k03b_bugs_test.dart`
  (bugs stage owned), `app/lib/core/**`, seed, analysis options.

## Verification (this stage ran; no simulator, no whole-app test)

- `flutter analyze lib/features/kid_home
  test/features/kid_home/k03b_all_done_view_test.dart
  test/features/kid_home/kid_home_view_test.dart` → No issues found.
- `flutter test --timeout 120s test/features/kid_home/k03b_all_done_view_test.dart`
  → All passed (54). `kid_home_view_test.dart` → All passed (88).
  `kid_home_geometry_test.dart` + `k03_bugs_test.dart` → All passed (70+2 skipped,
  K03 unmoved).
- Parked-proof spot checks (`--run-skipped`, not un-skipped — file not owned):
  BUG-1 gap 30 + rows on design row → pass; BUG-3 226×226 → pass;
  BUG-5 creation order → pass; BUG-4 no-approval `+15` → pass.
  BUG-4 approved-needs-approval finds 3×`Mum said yes!` (bins, hoover +
  newly approved reading) but the parked test expects exactly 1 — test
  expectation bug (kidAllDone already holds 2 approved from demo);
  integrator should assert the reading card specifically or `findsNWidgets(3)`.
  BUG-2 unit (`explicitGeometry` without `pipBottom`) still returns 257.4 —
  shared bug, superseded by the D1 feature-side correction; needs a
  SHARED_REQUEST from the orchestrator if the unit contract must change.

## LEFT FOR NEXT ITERATION

- Integrator: un-skip + fix the two parked-test expectations above
  (BUG-4 count, BUG-2 shared unit), run the full `kid_home` suite and the
  stage-5 UI check against title 469.3 / progress 513.0 / card1 545.0.
- D2 bubble alignment already on main (`NestSpeechBubble` uses
  `TextAlign.start`); bottom edge, gutters, PipAvatar, copy verified by the
  passing view suites.

VERDICT: PASS
