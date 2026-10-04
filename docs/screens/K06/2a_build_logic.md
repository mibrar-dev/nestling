# K06 · 2a BUILD LOGIC (iteration 1)

## CONTRACT CHANGES

The plan (§2) is the contract; these are the deliberate additions the UI
builder codes against (all in `presentation/bloc/`):

- New events `PipNestReceived(PipNest?)` / `PipNestFailed(error)` are
  bloc-internal (same K03-BUG-15 pattern as `KidHomeDataReceived`): the bloc
  raises them from its own `watchNest()` subscription so a reload guards on
  the live subscription instead of stacking handlers. Views never send them.
  Observable behaviour is exactly the plan: load → loading → loaded(nest),
  error → failure.
- New const `kPipNotEnoughCoins = 'Not enough coins yet — keep going!'`
  (U+2019 ’, U+2014 —) in `pip_bloc.dart`: the unaffordable-buy toast copy
  from plan §1f. The view shows `state.actionError` verbatim in a toast.
- `PipState` keeps `errorMessage` (load failure) plus a backwards-compatible
  `items` getter (`nest?.items ?? []`) so the K06/K07 placeholder views keep
  compiling until the UI builder replaces them. New code reads `state.nest`.
- Equip mapping lives in the bloc: `scarf` → accessory `scarf`,
  `sunhat` → accessory `cap`; `wellies`/`crown` have no accessory node and
  are a silent no-op (no DB write, no error). If the UI wants an
  informational toast for those two tiles, add it locally in the view —
  the bloc deliberately emits nothing.
- `PipNest.growthFraction` and pip-local `pipStageName(int)` (1 Egg,
  2 Hatchling, 3 Fledgling, 4 Songbird — do NOT import kid_home/family
  helpers) live in `domain/entities/pip_nest.dart` for the view to use.

## Files changed (logic layer only — no views/widgets touched)

- `app/lib/features/pip/domain/entities/pip_nest.dart` (NEW): `PipNest`
  {`PipProfile profile`, `List<PipStage> items`} + `growthFraction` +
  `pipStageName`.
- `app/lib/features/pip/domain/pip_repository.dart`: added
  `watchActiveChildId()` and `watchNest()`; care docs now read feed 5 /
  bath 3 / play free, no-op when unaffordable.
- `app/lib/features/pip/data/pip_repository_impl.dart`:
  `bathCostCoins = 3`, `bathe()` uses it (CONFLICT 1); wardrobe mapped to
  design names Scarf / Sun hat / Wellies / Crown (CONFLICT 4) and re-sorted
  to explicit scarf/sunhat/wellies/crown order (CONFLICT 3, DB prices kept
  per CONFLICT 2); `watchNest()` = switchMap(activeChildId) →
  combineLatest2(profile, ordered wardrobe), null child → null; `watchItems`
  serves the same ordered strip and now follows child switches; local
  `_switchMap` helper (feature-local, no cross-feature import, no core edit).
- `app/lib/features/pip/presentation/bloc/pip_event.dart`: added
  `PipCareRequested(kind)`, `PipWardrobeBuyRequested(item)`,
  `PipWardrobeEquipRequested(item)` + internal `PipNestReceived/Failed`.
- `app/lib/features/pip/presentation/bloc/pip_state.dart`: new shape
  {status, `PipNest? nest`, errorMessage, actionError, actionNonce} with
  `toLoading` / `copyWithLoaded` (clears transient outcomes + stale error) /
  `toFailure` / `withActionStarted` / `withActionFailed` (nonce-bumped).
- `app/lib/features/pip/presentation/bloc/pip_bloc.dart`: guarded live
  subscription (reloads ignored while live, released on error/close, so
  Try-again works); care/buy/equip resolve the child id from the last nest
  emission (null → ignore); unaffordable buy → `kPipNotEnoughCoins` toast,
  no DB write; successes need no event (stream re-emits).
- `app/test/features/pip/pip_repository_test.dart` (NEW, 14 tests):
  seed truth (Maya mochi/sunny/none/stage 3, 175/250, 0.7), design order +
  names + DB prices (0/0/40/120), child switching maya → leo → null,
  feed 5 / play free / bath 3 with +1 happiness, clamp at 5, insufficient
  no-ops, unknown-child no-op, buy deducts DB price, unaffordable/already-
  owned no-ops, updateLook scarf/cap, `pipStageName` map.
- `app/test/features/pip/pip_bloc_test.dart` (NEW, 19 tests): state value
  semantics, load → loading → loaded with ordered nest, live-reload guard,
  load failure + retry reloads, feed/bathe/play through the stream, care
  before load ignored, thrown write → actionError/nonce, affordable buy
  (two emissions: coins write then owned flag), unaffordable buy → kind
  toast + no write, equip scarf/cap, wellies/crown no-op.
- DI/routes (`pip_di.dart`, `pip_routes.dart`): NO change needed —
  `PipBloc(repository:)` signature is unchanged and both routes already
  dispatch `PipLoadRequested`.

## Verification (logic-stage scope only — no full-app test, no simulator)

- `dart format lib/features/pip test/features/pip` → clean (0 changed).
- `flutter analyze lib/features/pip test/features/pip` → No issues found.
- `flutter test test/features/pip/pip_repository_test.dart
  test/features/pip/pip_bloc_test.dart` → All tests passed (33).
- Shared regression: `repositories_test.dart` “pip care, wardrobe and
  look” → passed (feed 115, wellies 40 → 75, look write all unchanged).
- No `google_fonts`, no `DateTime.now()`, no new ids, no `core/` or `app/`
  edits, no views/widgets edits.

## LEFT FOR NEXT ITERATION

- Nothing in the logic layer is unfinished. UI builder owns views/widgets
  (title, pet slot, growth card, care row, wardrobe grid, caption, loading /
  failure / no-child states, toasts, navigation) against the contract above.
- Integrator: run the full `flutter test` + light/dark `shot.sh` UI check.

VERDICT: PASS
