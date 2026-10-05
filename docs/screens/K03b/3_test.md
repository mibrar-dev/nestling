# 3 TEST — K03b Kid home all done (iteration 3)

Stage 3. Iteration-3 scope: the 06:44 orchestrator decision (K03B-BUG-6 —
terminal `completeQuest` for `needsApproval == false`) plus every remaining
BLoC event/state path that can touch the shared kid home while it celebrates.
No screen code touched (one new test file only); no simulator booted; no
`flutter clean`; no global kills.

## Tests added

New file `app/test/features/kid_home/k03b_iteration3_stage_test.dart`
(16 tests, all green). Existing suites already cover the matrix
(`k03b_all_done_view_test.dart`: light+dark × 320/390/430 × 1.0/1.3,
empty/loading/error, taps, semantics, ≥56 targets), the truth table + live
paths (`k03b_all_done_bloc_test.dart`), geometry/ROW rules
(`k03b_bugs_test.dart`), the BUG-6 write contract
(`kid_home_repository_test.dart`) and every event for the K03 shape
(`kid_home_bloc_test.dart`) — this file closes only the iteration-3 gaps:

- A. Roster/selection/PIN preserve the celebration (fake repo, all-done
  items): blocTest correct-PIN → checking → pinPassed with allDone true;
  blocTest wrong-PIN → `pinWrongNonce` 1 with allDone true; plain bloc
  proofs that a profiles push, a mid-session profiles error, profile
  select + `SelectionHandled`, a direct `KidHomeDataReceived` with a
  terminal (approved + `needsApproval: false`) row, and a mid-session
  `KidHomeStreamFailed` all keep `loaded` + 6 of 6 + allDone; and that a
  profiles-only emission on `initial` sets the roster without celebrating.
- B. DB-backed terminal pair (`Seed.demo`, writes before pump): no-approval
  `q-tidy` completes as `approved` + `decidedAt` with exactly one 15p
  `quest_bonus` credit; terminal + pending pair lands 6 of 6 in creation
  order with `q-tidy` approved/unflagged; P11 queue gains `q-reading`,
  never `q-tidy`; terminal retry credits nothing more and stays celebrated;
  bloc load after the pair lands on allDone.
- C. DB-backed widget proofs of the terminal shape: light shows `All done!`,
  `6 of 6 done`, `120`, `Visit Pip` (no dock), the tidy card with the `+15`
  coin chip and no status chip, 2 × `Mum said yes!`, 3 × `Waiting for Mum`;
  dark 320 px / 1.3 renders all 6 cards with no `£` and no overflow, lock +
  CTA ≥ 56; `Visit Pip` exposes `SemanticsAction.tap` and `performAction`
  reaches `/pip`; `Grown-ups` label present.
- D. Source hygiene over the touched feature files (view, state, repo impl,
  routes): no `google_fonts`/`GoogleFonts`, no `DateTime.now()`,
  `/kid-home-done` renders `KidHomeView`, no `KidHomeDoneView` reference.

Two test-authoring fixes during development (not screen bugs): the PIN
blocTests needed the `loading → loading-with-roster → loaded` prefix the
fake's stream order produces; `drift` import needed
`BooleanExpressionOperators` for the `&` combinator. `flutter analyze`
clean before and after.

## Results

- `flutter analyze` → `No issues found!`
- New file → `+16: All tests passed!`
- `flutter test --timeout 120s test/features/kid_home/` → `+798 ~7: All tests passed!`
- Full `flutter test --timeout 120s` → `+5042 ~16: All tests passed!`
  (re-run; first full run showed one transient failure in
  `test/features/rewards/rewards_write_failures_test.dart` — another
  feature, out of scope per RULES §1, never touched by this stage: it
  passes in isolation and in the full re-run, so flake, not a regression —
  my change only ADDS one file under `kid_home/`).
- K03 (demo 4 of 6) unchanged: all existing `kid_home_view`, geometry and
  `k03_bugs` suites green in the runs above.

## Bugs found

My 16 tests exposed no screen bug. One real bug was verified in-tree (found
and parked by the concurrent bugs stage, uncommitted in this worktree —
recorded here with repro, not patched):

- K03B-BUG-7 (`app/test/features/kid_home/k03b_bugs_test.dart:523`,
  `skip: true` at :555): turning a quest's "Needs my approval" OFF after its
  `done_pending` completion leaves the row in the P11 queue while the kid
  row flips to the `+N` chip. Repro: `Seed.kidAllDone`, set `q-reading`
  `needsApproval=false`, pump `/kid-home-done` → reading card shows `+10`
  but `ApprovalsRepository.getItems()` still contains `q-reading`. Verified
  real: `flutter test --timeout 120s
  test/features/kid_home/k03b_bugs_test.dart --plain-name "K03B-BUG-7"
  --run-skipped` → fails as parked; plain suite stays green. Needs
  orchestrator triage (fix vs backlog, same standing as the parked
  K03B-BUG-2 latent shared `_explicitBleed` at `:220`, which stays
  `skip: true` per the 06:44 ruling). Precedent (iteration-2 loop line:
  test/review/ui PASS with BUG-6 parked) is that parked proofs do not fail
  this gate — the bugs stage owns the open-bug verdict.

Note: the loop sync also landed a `terminal completion money path` group in
`k03b_bugs_test.dart:376` (5 tests: terminal credit in pence, racing double,
same-period retry, approval quest stays pending, credit survives reopen) —
all green; group B above complements it at bloc + widget level rather than
duplicating it.

VERDICT: PASS
