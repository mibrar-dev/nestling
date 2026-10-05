# 2a BUILD LOGIC — K03b Kid home all done (iteration 3)

## CONTRACT CHANGES

`KidHomeRepository.completeQuest` behavior change (signature unchanged, so
the UI builder and bloc need no changes): when the quest row has
`needsApproval == false`, the completion is terminal — status `approved`
(+ `decidedAt`/`decidedAtTz`) with a `quest_bonus` ledger credit
(1 coin = 1p, note = quest title) in the same transaction, mirroring
`ApprovalsRepositoryImpl.approve`. Approval quests keep the `done_pending`
write with no ledger row. Effects the UI builder relies on: the kid row
flips to done (stream status `approved` counts as done, celebration flow
unchanged), the view's done+no-approval `+N` chip path is now reachable in
production, and the P11 queue (lists `done_pending` only) never sees these
rows. No new events, states, entities, or route/DI changes.

## Files changed (logic layer only)

- `app/lib/features/kid_home/data/kid_home_repository_impl.dart` —
  K03B-BUG-6 fix: `terminal = !quest.needsApproval` branches both the flip
  path (existing `to_do`/`not_yet` row) and the insert path to `approved` +
  decidedAt + `_creditQuestBonus`; flip hardened to compare-and-set
  (`WHERE id + status IN (to_do, not_yet)`, credit only when a row flips —
  approvals BUG-P11-1 shape) so a racing retry credits exactly once.
- `app/test/features/kid_home/kid_home_repository_test.dart` — new group
  `K03B-BUG-6 terminal completion` (4 tests); drift import hides
  `isNotNull`/`isNull` (matcher clash).
- Did NOT touch: `presentation/views/**`, `presentation/widgets/**`,
  `k03b_bugs_test.dart` (integrator owns the un-skip), `app/lib/core/**`,
  `app/lib/app/**`, seed, analysis options.

## Items done

- K03B-BUG-6 fixed per the orchestrator's suggested option A (completeQuest
  writes terminal + credits; no approvals-repo change needed — verified the
  P11 queue predicate is `status == done_pending` via `watchPendingApprovals`).
- Verified generated companions accept the new columns
  (`decidedAt`/`decidedAtTz` on completions insert; `familyId/childId/type/
  amountPence/note/date/dateTz` on ledger insert — same columns `approve` uses).
- `dart format` clean, `flutter analyze` → No issues found.
- Owned suites green: `kid_home_repository_test` 17/17 (flip/insert/retry/
  approval-path), `kid_home_bloc_test` + `quest_detail_bloc_test` 62/62.
  Two test-authoring catches fixed along the way (drift/matcher import clash;
  seed history already holds a 28p 'Tidy your bedroom' bonus, so ledger
  assertions use before/after deltas).
- No `google_fonts`, no `DateTime.now()` (uses `appNowUtc()`), no `pkill`,
  no simulator, no whole-app test run.

## FIXES_2 disposition (only logic-layer items acted on)

- K03B-BUG-1/2/3/4/5: already fixed in iteration 2, proofs un-skipped and
  green per 6_bugs.md — untouched.
- K03B-BUG-2 (latent, shared): `explicitGeometry` quirk acknowledged;
  D1 forbids touching `core/**` — correctly left parked for the orchestrator.
- K03B-BUG-6 parked widget test (`k03b_bugs_test.dart:342`, still
  `skip: true`): left skipped ON PURPOSE to avoid a same-file parallel-edit
  clash — it is a widget test outside my owned set, and it now passes on
  logic grounds (verified premise: `completeQuest('maya','q-tidy')` with
  `needsApproval=false` leaves zero `done_pending` rows for the quest, which
  is exactly what the test asserts). Integrator: un-skip with
  `flutter test --timeout 120s --run-skipped --plain-name K03B-BUG-6`.

## LEFT FOR NEXT ITERATION

- None in the logic layer. Integrator: un-skip + run the K03B-BUG-6 proof,
  then the full `kid_home` suite.

VERDICT: PASS
