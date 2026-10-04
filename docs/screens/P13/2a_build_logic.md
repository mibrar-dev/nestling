# 2a — Build, logic chunk (iteration 4) — P13 Payout

Scope: logic layer only (`domain`/`data`/`bloc` + `*bloc*`/`*repository*`
tests). Views/widgets untouched (UI builder's parallel lane).

## CONTRACT CHANGES

None. No signature or event/state shape changed this iteration.

## Files changed

None in `app/lib` or `app/test` — iteration 4 required no logic-layer
edits (disposition below). This file is the stage's only write.

## FIXES_3 disposition (logic-layer items only)

FIXES_3 carries two sections (integrate + test), and **nothing in either is
in this layer**:

- `recordPayout` guards (BUG-02, review #3): the integrate stage reports
  them "already correct" and the test stage re-verified amount 0 /
  negative / clamp / `goalId == null` against the live tree. The guards
  (`amountPence <= 0` no-op, `move = min(move, amount)`) are untouched
  since iteration 2 and still in place (verified by grep).
- Submit guards (BUG-01/04/05): "untouched", still passing — the
  per-child `_payoutInFlight` set with `finally` removal and the
  clear-before-write are intact (verified by grep).
- Saverow copy gate (BUG-06/I2-01): `label()` in
  `presentation/widgets/payout_sheet.dart` — UI builder's file. The
  remaining `childId == 'maya'` smell is an acknowledged product decision
  for the orchestrator, not a logic defect; the data layer exposes only
  neutral `goalFor`/`owedFor` accessors.
- 5_ui deviations from iteration 2: closed by the UI builder's
  `textAlign` flip (view file).
- Whole-repo gate failure (`test/core/family_time_test.dart:319`, Dubai
  day-rollover vs wall clock): shared `core`, outside RULES §1, filed as
  SHARED_REQUEST #2 (`Blocks: yes`). Unchanged and still red; process item
  for the orchestrator, not a finding on this screen.
- Skipped bug tests: none left in P13 — `grep "skip: true"` over the P13
  bug/audit files is empty (only pre-existing P12 skip remains
  tree-wide). Nothing to un-skip in this layer.
- ORCHESTRATOR_NOTES: unchanged since 19:48 (view-side items, all landed
  and pinned in iteration 2; re-verified green by the test stage).

## Verification (post-merge `4f18177`, no logic edits pending)

- `flutter analyze lib/features/pocket_money` + both owned test files →
  No issues found. No `google_fonts` in feature lib/tests.
- Owned tests: `payout_bloc_test.dart` (7) + `payout_repository_test.dart`
  (6) — 13/13 pass.
- Neighbour logic suites (read-only rerun): ledger bloc + ledger
  repository + setup bloc + setup repository + next_payout — all pass
  (101 total with owned files, 0 failures).
- View/widget suites deliberately not run: the UI builder owns them and
  the integrator runs the full feature dir after the merge. No simulator
  used at any point.

## LEFT FOR NEXT ITERATION

- Orchestrator `shared/`: SHARED_REQUEST #2 (the only red gate
  tree-wide); SHARED_REQUEST #1 (`pumpAppRoute` surface size, non-blocking).
- Orchestrator product call: the `childId == 'maya'` copy gate.
- 5_ui: `shot.sh` light + dark + `compare.py` with the ±2 px position
  table.

VERDICT: PASS
