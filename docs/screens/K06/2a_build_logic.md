# K06 · 2a BUILD LOGIC (iteration 3)

## CONTRACT CHANGES

One signature change, required by the K06-BUG-7 fix (FIXES_2). The UI
builder does not call the repository directly (views talk to the bloc),
so view code is unaffected — but three test spies needed the new
signature (updated here, see Files):

- `PipRepository.buyItem` now returns `Future<PipBuyResult>` instead of
  `Future<void>`. New enum in `domain/pip_repository.dart`:
  `bought | cannotAfford | alreadyOwned | unavailable`. Only
  `cannotAfford` produces the kind toast; the rest stay event-free.
- `PipState.copyWithLoaded` now **carries a pending action outcome
  through** instead of clearing it. Rationale: in a tap burst the refused
  tap's toast must survive the sibling write's stream refresh (that is the
  whole of BUG-7). The outcome still clears on the next attempt via
  `withActionStarted`, so repeats are announced again and the pinned
  `1 → 0 → 1` nonce sequence is unchanged. No field was added or removed.

## FIXES_2 items in this layer — fixed, proof un-skipped

- **K06-BUG-7 (minor) — a buy refused by the fresh balance is silent.**
  The bloc pre-checks cached coins, but in a burst the cache is stale for
  the second tap while the atomic `buyItem` correctly refuses on the fresh
  balance — and `void` gave the bloc nothing to announce. Now the bloc
  switches on the result and emits `withActionFailed(kPipNotEnoughCoins)`
  on `cannotAfford`; `bought`/`alreadyOwned`/`unavailable` stay silent
  (success re-emits through the stream; already-owned tiles dispatch
  Equip, not Buy, so `alreadyOwned` here means a lost same-item race).
  The pre-check stays as the fast path for visibly-unaffordable tiles.
  Proof `K06-BUG-7` in `k06_bugs_test.dart` un-skipped and green; plus a
  deterministic bloc-level pin (`_RefusingBuyRepository`) in
  `pip_bloc_test.dart`, and result assertions (`bought`/`cannotAfford`/
  `alreadyOwned`/`unavailable`) in `pip_repository_test.dart`.
- Iteration-1/2 regressions still green: BUG-1 burst math, BUG-2
  overspend guard (premise re-based, see below), atomic groups.

## Shared seed change landed mid-iteration (not a bug — premises moved)

`main` merged shared batch 7: the demo seed adopted the design prices
(Wellies 30, Crown 60 — was 40/120), resolving `SHARED_REQUEST.md` §6 on
the orchestrator's side. DATA OVER MOCKS now means 30/60, so every
hard-coded 40/120 expectation is honestly red. Premise updates made HERE
(minimum to keep my layer + its proofs green):

- `pip_repository_test.dart`: DB prices/names (30/60), wellies buy lands
  at 90, same-item double-buy charges once (90), overspend probe re-based
  to a 70-coin balance (only one of 30+60 fits) with result assertions.
- `pip_bloc_test.dart`: affordable-buy stream lands at 90; new
  race-refusal pin.
- `k06_bugs_test.dart`: BUG-2 proof re-based to 70 coins (only one fits);
  BUG-7 proof given a 70-coin balance (at 120 both tiles fit now, so no
  refusal could occur); two-thumb burst probe re-based to 70
  (1 owned, 40-or-10 left by winner); reopen probe lands at 85
  (120 − 5 − 30); stale header comment corrected.
- Compilation-only: the three `buyItem` spy overrides
  (`pip_bloc_actions_test.dart` ×2, `pip_nest_interactions_test.dart` ×1)
  now return `PipBuyResult` (+1 import); behaviour untouched.

## Deliberately NOT touched (other layers' work, in flight or scheduled)

- BUG-3/4/5/6, D1, ORCHESTRATOR_NOTES item 1: views/widgets — the parallel
  UI builder's layer. No `views/**` or `widgets/**` file edited.
- Glyph assets + any remaining price-value assertions in test-stage files
  (`pip_nest_interactions_test`, `pip_nest_states_test`,
  `pip_nest_view_test`, `pip_orchestrator_notes_test`,
  `pip_atomic_writes_test`, `pip_iter2_fixes_test` price spots): another
  stage is already sweeping these (its uncommitted 30/60 edits are in
  this worktree, e.g. `pip_nest_view_test.dart`); touching them here would
  collide. 14 failures there are all `Expected 80/40/120, Actual 90/30/60`
  premises — verified by inspection, none is a logic regression (the one
  ambiguous case, states phantom-button, fails only on the renamed
  `Wellies, 30 coins` label; the unwearable-tile case only on 80-vs-90).
- `test/core/data/repositories_test.dart` pip group (expects 75 = 115−40,
  now 85): shared test dir, outside RULES §1 for this screen — flagged
  for the orchestrator/integrator, not edited.
- DI/routes: no change (`PipBloc(repository:)` unchanged).

## Files changed

- `app/lib/features/pip/domain/pip_repository.dart`: `PipBuyResult`
  enum + `buyItem` returns it (docs updated).
- `app/lib/features/pip/data/pip_repository_impl.dart`: `buyItem`
  returns the outcome (`unavailable`/`alreadyOwned`/`cannotAfford`/
  lost-race-refund→`alreadyOwned`/`bought`); `_care` untouched.
- `app/lib/features/pip/presentation/bloc/pip_bloc.dart`:
  `_onBuyRequested` announces `cannotAfford` with `kPipNotEnoughCoins`.
- `app/lib/features/pip/presentation/bloc/pip_state.dart`:
  `copyWithLoaded` carries the action outcome (doc updated).
- Tests: `pip_repository_test.dart` (results + 30/60 + 70-coin probe),
  `pip_bloc_test.dart` (90 landing + refusal pin + carry-through unit
  test), `k06_bugs_test.dart` (BUG-7 un-skipped, BUG-2/burst/reopen
  premises re-based), spy signatures in `pip_bloc_actions_test.dart` and
  `pip_nest_interactions_test.dart`.

## Verification (logic-stage scope — no full-app test, no simulator)

- `dart format` on touched files → clean.
- `flutter analyze lib/features/pip test/features/pip` → No issues found.
- `flutter test --timeout 120s test/features/pip/pip_repository_test.dart
  test/features/pip/pip_bloc_test.dart test/features/pip/pip_bloc_actions_test.dart`
  → All tests passed (59).
- `flutter test --timeout 120s test/features/pip/k06_bugs_test.dart` →
  All tests passed (+24, zero skips).
- `--run-skipped --plain-name K06-BUG-7` → passed.
- Whole `test/features/pip/` → 14 failures, ALL in other stages' files
  and ALL price premises (80→90, 40→30, 120→60); none involves logic
  behaviour. Listed above for the test-stage sweep.
- No `google_fonts`, no `DateTime.now()`, no new ids, no `core/` or `app/`
  edits, no views/widgets edits, no simulator.

## LEFT FOR NEXT ITERATION

- Nothing unfinished in the logic layer. Test stage: sweep the 14
  price-premise assertions + the shared `repositories_test.dart` pip group
  (75 → 85). UI builder: BUG-3/4/5/6 + D1 as before.

VERDICT: PASS
