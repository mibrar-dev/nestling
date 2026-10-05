# K03b · Stage 2b — build UI (iteration 1)

UI layer for the all-done state of kid home implemented. All logic
delegated to the BLoC state (§b of 1_plan.md): the only state addition is
the `allDone` getter, and no events/states/repository were touched.

Changes:

- `presentation/bloc/kid_home_state.dart` — added
  `bool get allDone => totalCount > 0 && doneCount == totalCount;`
  (pure getter; technically a state file but feature-owned and listed in
  the builder checklist of the plan as the agreed logic touch-point).
- `presentation/views/kid_home_view.dart` — `_KidHomeBody` now branches on
  `state.allDone`:
  - Header sub-line: `All done!` in `tokens.leafInk` (was `$done done
    today` / ink2); semantics label `Hi $nickname, all done!`.
  - `_AllDoneBody`: centred `NestSpeechBubble` "You did everything today!
    Pip is so proud.", 14 gap, `NestPetStage` slot (nest 236×188, fixedPip
    152, slotHeight 226) with the child's own PipAvatar
    (`mochi/sunny/amaya row, stage clamp 1..4, PipMood.happy`) rotated
    −7°, confetti plate (`NestlingIllustrations.confetti`, 320×250,
    `FittedBox.scaleDown`, top 4, `IgnorePointer`+`ExcludeSemantics`),
    section row (`NestBalancedText` "Today's quests" + `KidStatusChip`
    "$done of $total done"), `NestProgress(kid: true)` at fraction 1.0,
    then the same `_QuestCard` list as K03 (display-only checks since all
    statuses are done).
  - `_AllDoneBar` replaces the 3-button dock when all done: surface
    Container with 3 px ink top border, `SafeArea(top:false)`,
    `NestKidButton` lilac "Visit Pip" with `NestIcon(check)` →
    `context.go(PipRoutePaths.nest)`, `NestHomeIndicator` inside the
    surface (bottom-edge owner rule: no meadow strip under the bar).
  - K03 not-done branch renders exactly as before (dock, hearts, bubble
    via `NestPetStage`).
- `kid_home_routes.dart` — `kidHomeDoneRoute` now builds
  `KidHomeView()` (same bloc provider as `kidHomeRoute`); path/name
  constants unchanged.
- Deleted `presentation/views/kid_home_done_view.dart` (placeholder
  AppBar "K03b Kid home done"); barrel export removed.
- Tests: new `test/features/kid_home/k03b_all_done_view_test.dart`
  (8 tests): `allDone` getter truth table, all-done pump finds `All
  done!` / bubble / `6 of 6 done` / `Visit Pip` and not the dock/hearts/
  K03 pet bubble, partial pump keeps K03 untouched, Visit Pip exposes
  `SemanticsAction.tap`, 320-wide + textScale 1.3 pump has no overflow,
  `/kid-home-done` renders `KidHomeView` (no placeholder AppBar).
  Follows the kid_home_view_test.dart patterns (fake repository,
  `setUpTestScope`, `disposeApp`, `--timeout 120s`).

Verification:

- `flutter analyze lib/features/kid_home` + new test file: clean.
- `kid_home_view_test.dart` (88 tests), `k03_bugs_test.dart` +
  `kid_home_geometry_test.dart` (72), `k03b_all_done_view_test.dart` (8):
  all green. Full-suite kid_home run left to the integrator.

LEFT FOR NEXT ITERATION:

- `SEED=kid_all_done` is not yet on main (orchestrator-owned, branch
  `shared/kid_all_done_seed`); widget tests use a fake repository, so
  only the UI-check stage (stage 5) needs it. Not edited here.
- 2a logic-stage notes (`docs/screens/K03b/2a_build_logic.md`) not yet
  present — re-read before finishing integration; no CONTRACT CHANGES
  were anticipated by the plan.

VERDICT: PASS
