# P11 · Approvals — Stage 2a build logic (iteration 1)

Non-UI layer only. Views/widgets untouched (UI builder owns them).

## CONTRACT CHANGES

None. Events/states match `1_plan.md` §2 exactly:
`ApprovalsApproveRequested(completionId:)`,
`ApprovalsNotYetRequested(completionId:)`, `ApprovalsApproveAllRequested()`,
`ApprovalsActionErrorConsumed()`; state gains `busyIds` (default
`const <int>{}`), `approveAllBusy` (false), `actionError` (null).
`copyWith` takes an extra `clearActionError: false` flag so the bloc can
reset `actionError` to null (`actionError: null` alone means “unchanged”).

## Files changed

- `app/lib/features/approvals/domain/entities/approval.dart` — added
  required `createdAtTz: String` (zone-correct day/time labels), in `props`.
- `app/lib/features/approvals/data/models/approval_model.dart` — same field
  in ctor + `fromJson`/`toJson`.
- `app/lib/features/approvals/data/approvals_repository_impl.dart` —
  populates `createdAtTz` from `QuestCompletion.createdAtTz`. `getItems`/
  `watchItems`/`approve`/`markNotYet`/`approveAll` otherwise unchanged.
- `app/lib/features/approvals/presentation/bloc/approvals_event.dart` —
  4 new events (above).
- `app/lib/features/approvals/presentation/bloc/approvals_state.dart` —
  `busyIds`/`approveAllBusy`/`actionError` + `clearActionError` in `copyWith`;
  all three in `props` (else bloc suppresses the busy toggles as duplicates).
- `app/lib/features/approvals/presentation/bloc/approvals_bloc.dart` —
  `onData` sorts a copy `createdAt` descending (newest first: dishwasher,
  table, bed) and preserves busy flags; `_onApprove`/`_onNotYet` toggle
  `busyIds ± {id}` around the repo call and set `actionError` on
  `on Object catch`; `_onApproveAll` toggles `approveAllBusy`;
  `_onActionErrorConsumed` clears. Catches use `on Object` per repo
  precedent (auth/paywall/privacy_consent) to satisfy
  `avoid_catches_without_on_clauses`.
- `app/test/features/approvals/approvals_repository_test.dart` (new, 9 tests)
- `app/test/features/approvals/approvals_bloc_test.dart` (new, 9 tests)
- `docs/screens/P11/SHARED_REQUEST.md` (new, non-blocking quote-row request
  from plan §7)
- No DI/route changes needed (`registerApprovals` + `approvalsRoute` already
  correct). No `google_fonts` anywhere.

## Items done (plan §2 + §6.1–6.2)

Entity `createdAtTz`, repo population, bloc events/state/handlers/sort,
repository tests (3 pendings; approve → pending−1 + one `quest_bonus` row
with matching pence + quest note; not-yet → `not_yet`, no ledger row;
approve-all → empty inbox, +3 bonus rows totalling 30p), bloc tests (load →
`[loading, loaded(3 newest-first)]`; approve/not-yet call the repo and
toggle `busyIds`; throws → `actionError` set, busy cleared; approve-all
toggles `approveAllBusy`; consume clears), model round-trip + equality.

## Notes for the UI builder / integrator

- Repository stream order is `createdAt` ASC (oldest first: bed, table,
  dishwasher) — the plan §6.1 parenthetical “(creation order)” lists
  dishwasher-first, but the DB query sorts by instant, so the repo test
  asserts bed/table/dishwasher. The BLOC sorts newest-first (dishwasher,
  table, bed) exactly as the view test (§6.4) expects. No contract impact.
- Drift returns `createdAt` in the local zone in tests — compare instants
  via `.toUtc()`, never `isUtc`.
- `DateTime.utc` is NOT a const constructor: `Approval` fixtures in tests
  must be `final`, never `const` (same for any expected `ApprovalsState`
  containing items — build them non-const; `Equatable` equality still holds).
- `approval_time.dart` (plan §3, lives in `presentation/widgets/`) and all
  view/widget files + view tests are owned by the UI builder — untouched.
- `flutter analyze lib/features/approvals test/features/approvals` → No
  issues found. `flutter test test/features/approvals/` → 18/18 pass.
  Full-app `flutter test` and simulators left to the integrator per stage
  rules.

## ITERATION 2 (2b finding fix)

- `ApprovalsRepositoryImpl.approveAll()` no longer starts with
  `await watchItems().first`: a Drift query stream never delivers its first
  event under `testWidgets` fake async, so driving “Approve all” through the
  bloc hung forever in widget tests. It now runs the same predicate
  (`familyId + done_pending`) as a one-shot `select().get()` — a plain
  future, which completes under fake async exactly like the per-card
  approve path does.
- Deliberately NOT a new repository method: the UI builder hand-writes
  `_StubApprovalsRepository implements ApprovalsRepository`, so any
  interface addition would break their view tests. Public names unchanged —
  CONTRACT CHANGES still none.
- Verified: `flutter analyze lib/features/approvals
  test/features/approvals` → No issues found; `flutter test
  test/features/approvals/` → 45/45 pass (18 logic + 27 UI).

## LEFT FOR NEXT ITERATION

Nothing in the logic layer. UI layer (view, `approvals_loaded_body`,
`approval_card`, `approval_time`, placeholder deletion, view tests) is the
parallel UI builder's scope.

VERDICT: PASS
