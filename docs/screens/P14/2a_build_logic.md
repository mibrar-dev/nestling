# P14 · Rewards manager — Stage 2a build logic (iteration 3)

Owner: logic builder. Layer: `domain/**`, `data/**`, `presentation/bloc/**`,
DI/route registration, plus unit/bloc tests (`bloc`/`repository` names). No
views/widgets edits, no simulator use.

## CONTRACT CHANGES

None. No event/state/DI/route shape changed. The only lib edit is internal
to `RewardsBloc._onLoadRequested` (see below); every existing call site
compiles and behaves identically except the fixed defect.

## Files changed

- `app/lib/features/rewards/presentation/bloc/rewards_bloc.dart` — the
  `watchItems()` stream now goes through `_closeOnError` (house pattern,
  copied from TodayBloc/PocketMoneyBloc): the first stream error is
  forwarded and then the subscription closes, so `emit.forEach` completes
  and cancels. Without this, a stream error after data (P14-B06 shape) left
  the dead subscription alive and every `Try again` stacked another
  subscription on it. This is the **logic half** of P14-B06; the view half
  (remove the `state.items.isNotEmpty` short-circuit so the failure surface
  with `Try again` actually renders) is the UI builder's layer —
  `rewards_view.dart:53-62`, untouched here.
- `app/test/features/rewards/rewards_bloc_test.dart` — new
  `_DieAfterDataRepository` (rows, then stream death, then recovery) and test
  `a stream error after data keeps the rows and Try again recovers`:
  loading → loaded(1) → failure (rows retained, `stream died` message) →
  loading → loaded(1), with `watches == 2` proving exactly one recovery
  subscription and no stacked leak.

Not changed (verified, no work needed): entities, repository interface +
impl (creation-order query + delete cascade from iteration 2, still
correct), `RewardModel`, DI, routes, write-event result channels.

## FIXES_2.md items — triage for this layer

- P14-B06 (minor): logic half DONE (above). View half + un-skipping the
  `[P14-B06]` proof in `rewards_write_failures_test.dart` belongs to the UI
  builder (the skip stays until their branch fix lands; un-skipping now
  would turn the suite red).
- P14-B07 (live-region caption), P14-B08 (sheet chrome overflow): sheet
  widget layer — not mine, not touched.
- Test-harness notes (fonts, `pumpAndSettle`, `runAsync`): no logic impact.
- ORCHESTRATOR_NOTES re-verification: creation order, Baking OFF, no price
  sort — all still hold; nothing to change.

## Verification

- `dart format lib/features/rewards test/features/rewards` clean.
- `flutter analyze lib/features/rewards test/features/rewards` → No issues
  found.
- `flutter test test/features/rewards/rewards_repository_test.dart
  test/features/rewards/rewards_bloc_test.dart` → 27/27 pass (11 + 16,
  incl. the new B06-shape test).
- No `google_fonts`, no `letterSpacing`, no shared-code edits, no simulator.

## LEFT FOR NEXT ITERATION

Nothing in this layer. Open and owned elsewhere: P14-B06 view half +
un-skip (UI builder, same worktree); P14-B07/B08 sheet fixes (UI builder,
B08 may need a SHARED_REQUEST if `showNestBottomSheet` chrome is shared —
their call); full-suite green is the integrator's gate.

VERDICT: PASS
