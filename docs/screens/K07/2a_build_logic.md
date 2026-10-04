# K07 · 2a BUILD LOGIC (iteration 1) — non-UI layer of feature `pip`

## CONTRACT CHANGES

None. Public names are exactly as `1_plan.md` §(b) specified:
`PipEvolution`, `PipRepository.watchEvolution()`,
`PipState.evolution` + `copyWithEvolution`,
`PipEvolutionReceived` / `PipEvolutionFailed`. The UI builder can code
against the plan unchanged.

Two plan-text deviations (implementation detail, no contract impact):

- The plan says the bloc currently uses `emit.forEach` on `watchItems`
  and asks for a "private items-received/failed pair" to replace it.
  The bloc in this worktree already subscribes to `watchNest()` with an
  explicit `_nestSub` + public `PipNestReceived`/`PipNestFailed` pair
  (no `forEach` anywhere), so there was nothing to replace: the
  evolution half mirrors the existing nest pair with public
  `PipEvolutionReceived`/`PipEvolutionFailed` under its own `_evolutionSub`.
- `PipState` has no generic `copyWith`, so the plan's "copyWith + props"
  is `copyWithEvolution` (mirrors `copyWithLoaded`: restores `loaded`,
  carries the other stream's data + the action outcome, clears the stale
  load error) plus a `withStreamError` helper for the keep-loaded path.
  `toLoading`/`withActionStarted`/`withActionFailed` carry `evolution`
  through; `evolution` is in `props`.

## Files changed

- `app/lib/features/pip/domain/entities/pip_evolution.dart` (new):
  `PipEvolution { profile, questsDone }`, Equatable.
- `app/lib/features/pip/domain/pip_repository.dart`:
  `Stream<PipEvolution?> watchEvolution()` (+ import).
- `app/lib/features/pip/data/pip_repository_impl.dart`: `watchEvolution`
  via the feature-local `_switchMap` + `combineLatest2(watchProfile,
  watchCompletionsForChild)` from the active `app_state` row; null with
  no active child or a gone child row. `questsDone` counts
  `done_pending` + `approved` completions, all time — lifetime milestone,
  so the PERIODS ruling does not apply; `to_do`/`not_yet` never count;
  no clock read at all.
- `app/lib/features/pip/presentation/bloc/pip_event.dart`:
  `PipEvolutionReceived(PipEvolution?)`, `PipEvolutionFailed(Object)`.
- `app/lib/features/pip/presentation/bloc/pip_state.dart`: `evolution`
  field, `copyWithEvolution`, `withStreamError`, evolution carried by
  every constructor, in `props`. `items` (K06 wardrobe) untouched.
- `app/lib/features/pip/presentation/bloc/pip_bloc.dart`: `PipLoadRequested`
  starts BOTH subscriptions under separate null-guards (live ⇒ ignore;
  never re-add load events); each error releases only its own sub so
  `Try again` reloads; mid-session error with `nest` or `evolution`
  shown keeps the loaded screen (K03 review-finding-6), only
  nothing-to-show becomes failure; `close()` cancels both. Care/wardrobe
  paths untouched.
- DI/routes: unchanged (`registerPip` already wires repo + bloc;
  `pipEvolutionRoute` already provides `PipBloc` + `PipLoadRequested`).
- `app/test/features/pip/pip_evolution_repository_test.dart` (new, 8
  tests): Maya `{stage 3, totalCoins 175, coins 120, questsDone 4}` with
  look `mochi/sunny/none`; Leo `{stage 2, totalCoins 60, questsDone 2}`;
  approved and done_pending inserts re-emit +1 (single live subscription
  + poll-wait, no `skip(1)` race); `to_do`/`not_yet` never count; null
  and unknown active child → null; Leo rows do not leak into Maya.
- `app/test/features/pip/pip_evolution_bloc_test.dart` (new, 13 tests):
  state unit tests (defaults, `copyWithEvolution`, evolution carried by
  `copyWithLoaded`, `withStreamError`, `toFailure` drops data, event
  equality) + controlled broadcast-fake bloc tests (load → loaded with
  evolution; error-with-nothing-shown → failure; mid-session errors on
  either stream keep loaded; retry reloads and clears the error; double
  load ignored; `close()` leaves both controllers listener-free) + one
  Seed.demo end-to-end (Maya stage 3, 175 coins, 4 helped times).
- `app/test/features/pip/pip_bloc_test.dart`: exact-sequence K06 tests
  now run against `_EvolutionSilentRepository` (evolution stream silent),
  and `_FailingNestRepository` extends it — so their sequences read
  exactly as before. No expectation changed.

## Items done (plan §(b) + §(f) items 1–2)

Entity, `watchEvolution` (repo interface + Drift impl), bloc state +
events + dual subscriptions, DI/routes verified unchanged, repository
and bloc tests written. `flutter analyze` on the logic scope
(domain + data + bloc + DI/routes + the three test files): No issues
found. `flutter test --timeout 120s` on
`pip_evolution_repository_test` + `pip_evolution_bloc_test` +
`pip_bloc_test`: 41/41 pass. No `google_fonts`, no `DateTime.now()`,
tokens untouched (no UI in this layer).

Note: `flutter analyze lib/features/pip` currently also reports errors
in `presentation/views/pip_evolution_view.dart` and
`presentation/widgets/pip_evolution_*.dart` — that is the parallel UI
builder's iteration-1 work in progress, outside this layer; not touched.

## LEFT FOR NEXT ITERATION

Nothing in this layer. The view/CTA/lock wiring (§(a), §(c)–§(e)) and
the view/a11y/responsive/copy tests (§(f) items 3–6) belong to the UI
builder.

VERDICT: PASS
