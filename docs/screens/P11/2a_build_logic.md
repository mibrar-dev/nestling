# P11 · Approvals — Stage 2a build logic (iteration 2 — FIXES_1, logic layer)

Non-UI layer only. Views/widgets untouched (UI builder owns them).

## CONTRACT CHANGES (additive only — no event removed/renamed, no field removed)

1. `Approval` / `ApprovalModel` gain optional `String? kidNote` (default
   null): the child's note from `quest_completions.kid_note` (schema v6,
   orchestrator item 1). Existing constructions compile unchanged; `fromJson`
   treats a missing key as null; `kidNote` is in `props`.
2. New `enum ApprovalsDecision { approve, notYet }` + state field
   `busyActions: Map<int, ApprovalsDecision>` (default const {}): which
   button was tapped per busy card (BUG-P11-4 — plan §1 “loading only if THIS
   button was tapped”). `busyIds` is kept in sync and retained, so existing
   readers keep compiling while the card migrates to per-button loading.
3. Behaviour, same shapes: `_onApprove`/`_onNotYet` absorb a repeat for a
   busy id AND for an already-decided id (private `_decided` set, pruned when
   rows leave the inbox; failures never enter it so retry still works);
   `_onApproveAll` absorbs while `approveAllBusy`. Repository decisions are
   compare-and-set (see below), so the absorb is a fast path, not the
   guarantee.

## Files changed (this iteration)

- `data/approvals_repository_impl.dart` — BUG-P11-1: `approve()` is now one
  transaction whose UPDATE claims the row
  (`WHERE id = ? AND status = 'done_pending'`); 0 rows changed → return
  before touching the ledger (K03-BUG-1 precedent). BUG-P11-2:
  `markNotYet()` only matches `done_pending` rows (single atomic UPDATE),
  so a stale/racing “Not yet” can never overwrite an approval.
  `approveAll()` inherits both through `approve()`. Also populates the new
  `kidNote` from `QuestCompletion.kidNote`.
- `domain/entities/approval.dart`, `data/models/approval_model.dart` —
  `kidNote` (above).
- `presentation/bloc/approvals_state.dart` — `ApprovalsDecision` +
  `busyActions` (above, in `props` + `copyWith`).
- `presentation/bloc/approvals_bloc.dart` — absorb guards + `_decided`
  pruning in `onData` (above).
- `test/.../approvals_repository_test.dart` — kidNote asserts (dishwasher
  note / table NULL / bed note), model round-trip + null-default tests.
- `test/.../approvals_bloc_test.dart` — busyActions expectations, 3 new
  absorb tests (busy-window approve, busy-window approve-all, decided-set
  repeat after completion).
- `test/.../approvals_bloc_paths_test.dart` — ONE expectation updated for
  the additive `busyActions` (not-yet failure). NOTE: that file also carries
  the parallel UI builder's uncommitted `_busy()` helper (BUG-P11-4 widget
  prep, currently unused → `unused_element` warning is theirs, resolves when
  they consume it).
- `test/.../p11_bugs_test.dart` — un-skipped the 6 BUG-P11-1/BUG-P11-2
  proofs (2 repo + 2 widget for BUG-1, 1 repo + 1 widget for BUG-2). BUG-3
  (×2) and BUG-4 (×1) stay skipped — widget-layer fixes owned by the UI
  builder.
- `docs/screens/P11/SHARED_REQUEST.md` — quote-row request marked RESOLVED
  (schema v6); CTA §3 unchanged (shared component, still pending).
- No DI/route changes. No `google_fonts` anywhere.

## Items done (FIXES_1, logic layer only)

- BUG-P11-1 major: DB CAS (concurrent approve/approveAll credit once) +
  bloc absorb (same-frame double-tap dispatches one write, even with an
  instant repo). Proofs: `concurrent approve()`, `concurrent approveAll()`,
  `same-frame double-tap on "Approve all"`, `same-frame double-tap on
  Approve` — all 4 PASS un-skipped.
- BUG-P11-2 major: guarded `markNotYet` + CAS `approve`. Proofs:
  `markNotYet() after approve()` (status stays `approved`) and `same-frame
  Approve then Not yet` (consistent pair) — both PASS un-skipped.
- BUG-P11-4 state support: `busyActions` recorded per decision; unit-tested
  (`{1: approve}`, `{3: notYet}`). The card widget change + its proof stay
  with the UI builder.
- Orchestrator item 1 (data part): `kidNote` flows DB → entity (repo test
  pins all three seed values incl. table NULL). Quote RENDER + geometry pins
  (items 1/4) are UI-builder work — their `approvals_quote_test.dart` WIP
  fails until the card renders the line, as expected mid-iteration.
- Orchestrator item 2 (pending set from DB): confirmed, no change. Items 3
  (CTA position): shared component, SHARED_REQUEST §3 stands.

## Verification

- `flutter analyze` on all 9 logic-layer files I own/touched →
  No issues found.
- `flutter test` approvals: repository 11 + bloc 13 + bloc_paths (incl. my
  fix) + `p11_bugs_test.dart` → `+6 ~3` (6 proofs pass, 3 UI-layer skips
  remain). Full-dir run still shows the UI builder's in-flight WIP failing
  (`approvals_quote_test` ×3 — quote not rendered yet; their untracked
  `zz_scratch_probe_test` lint) — NOT logic-layer regressions.
- No simulator booted (UI-check stage only).

## LEFT FOR NEXT ITERATION

- UI builder: BUG-P11-3 (`approval_time.dart` UTC date-only diff), BUG-P11-4
  card per-button loading via `busyActions` + un-skip its proof, quote-line
  render (17/24 w700, margin-top 10, curly quotes, NULL = no line/gap) +
  172/138 geometry pins, remove/split `zz_scratch_probe_test.dart`, consume
  `_busy()` (clears the `unused_element` warning).
- Logic layer: nothing outstanding.

---

# Appendix — iteration 1 record (superseded, kept for history)

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
