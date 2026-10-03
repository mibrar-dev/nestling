# P14 · Rewards manager — Stage 2a build logic (iteration 1)

Owner: logic builder. Layer: `domain/**`, `data/**`, `presentation/bloc/**`,
DI/route registration, and unit/bloc tests. Views/widgets untouched (UI
builder owns them).

## CONTRACT CHANGES

None. Events/states match `docs/screens/P14/1_plan.md` §2 exactly, so the UI
builder can code against the plan: `RewardsNeedsOkChanged(id, needsOk)`,
`RewardsCreateRequested(title, coinPrice, needsOk, icon)`,
`RewardsUpdateRequested(reward)`, `RewardsDeleteRequested(id)`; state stays
`RewardsStatus{initial,loading,loaded,failure}` + `RewardsState(items,
errorMessage)`; `RewardsLoadRequested` unchanged.

## Files changed

- `app/lib/features/rewards/presentation/bloc/rewards_event.dart` — added the
  four write events above (plan §2 signatures verbatim).
- `app/lib/features/rewards/presentation/bloc/rewards_bloc.dart` — added the
  four write handlers. Each awaits the repository call and emits `failure`
  with the message on error (`emit.isDone` guard after the await). Success
  emits nothing: the `watchItems` stream re-emits after every write and the
  existing `emit.forEach` subscription delivers the new list (same pattern as
  `PocketMoneyBloc` write handlers). `RewardsCreateRequested` builds
  `Reward(id: '', …, detail: '{price} coins')`; the impl generates
  `reward-{ms}`.
- `app/test/features/rewards/rewards_bloc_test.dart` (new) — state/event
  unit tests; load test (6 demo rows, price order
  50/60/80/90/100/150, ids/titles, all `needsOk` true); toggle/create/update/
  delete round-trips through the real DB via `setUpTestScope` (order moves
  and DB verification included); failure tests via a throwing fake
  (all four writes → `failure` with message; stream error → `failure`,
  retry resubscribes to `loaded`).
- `app/test/features/rewards/rewards_repository_test.dart` (new) —
  repository contract: price order + titles, `getItems` == watched list,
  `detail` == `'{price} coins'`, `setNeedsOk` flips one row only,
  create (generated id + explicit id + price-order position), update
  (rewrite + resort), delete.

Not changed (already per plan, verified): `domain/` entities + repository
interface, `data/rewards_repository_impl.dart` (all five P14 methods present;
`watchItems` is `coinPrice ASC`), `rewards_di.dart` (Drift-backed),
`rewards_routes.dart` (`/rewards`), `RewardModel`. Redemption methods
(`watchRequests`/`approveRedemption`/`denyRedemption`) are the K08 path —
out of scope, left untouched and untested here.

## Verification

- `dart format lib/features/rewards test/features/rewards` clean.
- `flutter analyze lib/features/rewards test/features/rewards` → No issues
  found (one ambiguous `Reward` import fixed with `hide Reward`).
- `flutter test test/features/rewards/rewards_repository_test.dart
  test/features/rewards/rewards_bloc_test.dart` → All tests passed (21/21).
- No `google_fonts`, no `letterSpacing`, no view/widget edits, no simulator
  use, no shared-code edits.

## LEFT FOR NEXT ITERATION

Nothing in this layer. UI builder owns `presentation/views/**` +
`presentation/widgets/**` (RewardCard list, editor bottom sheet, empty/
loading/error surfaces) against the contract above.

VERDICT: PASS
