# P17 Parental gate — 2a build logic (iteration 2)

Scope: non-UI layer only — `domain/**`, `data/**`,
`presentation/bloc/**`, plus unit/bloc tests whose names contain
`bloc`/`repository`/`data`, plus the two un-skipped bug proofs in
`p17_bugs_test.dart` (explicitly authorised by this stage's brief).
No view/widget edits; no DI/route edits; no simulator use.

## CONTRACT CHANGES

No shape changes — the UI builder's contract from iteration 1 stands
(events `ParentalGateDigitEntered`/`ParentalGateDeletePressed`/
`ParentalGateUnlockAcknowledged`; state `entered`/`attempts`/`unlocked`
+ `challenge`/`expectedLength`/`isComplete`). Two additive,
backward-compatible internals:

1. `ParentalGateState.copyWith` gains optional `clearError: false`
   (PaywallState precedent) so a retry can drop a stale `errorMessage`.
   No call-site changes needed in the view.
2. `challengeFor(DateTime utc)` now interprets the instant's calendar day
   in the family zone (Europe/London) instead of UTC (P17-BUG-2). Same
   signature, same return type; the pinned demo day still yields
   `three times nine`, so no view/test copy changes.

Behaviour the view should know (no action needed — the existing
`listenWhen` edge guards already handle it): when the live challenge id
changes, the bloc now also resets `unlocked` to false alongside
`entered`/`attempts`, so the one-shot can never re-fire `_unlock`
against a new question.

## Files changed

- `app/lib/features/parental_gate/data/parental_gate_repository_impl.dart`
  — P17-BUG-2: `challengeFor` derives the day key and `id` from
  `toFamilyZone(utc, defaultFamilyZoneId)` (PERIODS ruling; same pattern
  as `Seed.anchorDay`). `watchItems` already used `appNowUtc()` (CLOCK
  rule was already satisfied).
- `app/lib/features/parental_gate/domain/parental_gate_repository.dart`
  — doc only: `challengeFor` takes a UTC instant, day read in London.
- `app/lib/features/parental_gate/presentation/bloc/parental_gate_state.dart`
  — `copyWith` gains `clearError` (additive).
- `app/lib/features/parental_gate/presentation/bloc/parental_gate_bloc.dart`
  — P17-BUG-3: `onData` resets `entered`/`attempts`/`unlocked` when
  `items.first.id` differs from the current challenge (same-challenge
  re-emits keep the half-typed entry and emit nothing new); loading and
  loaded emissions clear a stale `errorMessage` (3_test §3.3.3 / 6_bugs
  obs 3 — the "sticky error" minor).
- `app/test/features/parental_gate/parental_gate_bloc_test.dart`
  (25 tests, was 23) — retry test now asserts the error is cleared on
  loading/loaded (stale comment corrected); new: challenge swap resets
  entry + attempts (P17-BUG-3), same-challenge re-emit preserves entry.
- `app/test/features/parental_gate/parental_gate_repository_test.dart`
  (13 tests, was 11) — 4_review finding 3: one shared memory DB for the
  pure `challengeFor` group (was one per test); new: BST London-day
  proof (23:30Z 3 Oct == 11:00Z 4 Oct → `2026-10-4` `four times nine`)
  and one-UTC-date/two-London-days split.
- `app/test/features/parental_gate/p17_bugs_test.dart` — removed `skip:`
  from the P17-BUG-2 and P17-BUG-3 proofs (both now pass); P17-BUG-1
  stays skipped (shared `router.dart`, out of layer, still in
  SHARED_REQUEST.md); group renamed to say so.

## FIXES_1 items in my layer — all done

- P17-BUG-2 (minor, data): fixed + proof un-skipped and green.
- P17-BUG-3 (minor, bloc): fixed + proof un-skipped and green.
- Sticky `errorMessage` (3_test §3.3.3): fixed via `clearError`.
- 4_review finding 3 (shared DB): fixed. Findings 2/4/5 are view-layer
  (UI builder); finding 1 is SHARED_REQUEST process; finding 6 is BUG-2.
- 3_test §3.1 (pushed unlock) and §3.2 (geometry) are view-layer (UI
  builder). P17-BUG-1 is shared router (orchestrator). 34 pre-existing
  whole-suite reds are untouched (process items, not findings).
- `ParentalGateChallengeModel` left in place (6_bugs obs 4): it is part
  of the per-feature ARCHITECTURE shape (models with fromJson/toJson)
  and has a round-trip test — not mine to delete.

## Verification

- `dart format` clean (0 unrelated changes).
- `flutter analyze lib/features/parental_gate
  test/features/parental_gate` → No issues found!
- `flutter test` on my three files → +48 ~1, all pass (only ~1 is the
  still-skipped shared-router BUG-1 proof).
- `flutter test test/core/data/repositories_test.dart` → +22, all pass
  (shared parental-gate determinism test unaffected: 00:00Z 3 Oct is
  01:00 BST 3 Oct, still `three times nine`).
- No `google_fonts`, no letterSpacing, no `DateTime.now()` in lib, no
  simulator.

## LEFT FOR NEXT ITERATION

- Known limitation (noted, not proven by any test): a gate left open
  across the London midnight does not re-key by itself — the settings
  stream only re-emits on a settings write. Re-keying needs a midnight
  tick the plan's repository contract (Drift-only, no timers) does not
  provide; flagged for the orchestrator, not smuggled into this stage.
- Nothing else in this layer. UI builder owns views/widgets + 3.1/3.2;
  integrator owns the full suite + screenshots.

VERDICT: PASS
