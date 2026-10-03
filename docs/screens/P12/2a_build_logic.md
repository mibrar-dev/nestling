# P12 · 2a BUILD (logic chunk, iteration 3)

## CONTRACT CHANGES

None this iteration — no state/event/entity shape changed. `errorMessage`
copy (iteration 2), `MoneyLedgerData` fields, all three P12 events and
`watchLedgerData` keep their shapes; only the owed-math rule behind
`oweds`/`watchOwed` changed (same values on untied data — Maya 420, Leo
210 — plus a same-second tie now resolves deterministically).

## FIXES_2.md triage (logic layer only)

- Finding 4 (`summarise` tie) — FIXED. `summarise()` in
  `data/pocket_money_repository_impl.dart` is order-independent: it finds
  the latest `payout` instant first, then sums `weekly_base` +
  `quest_bonus` rows with `date >= payout` (ties count — they settled
  nothing yet). Same rule applied to `_owedFromEntries` in the shared test
  fallback. New regression test pins both input orders
  (`pocket_money_repository_test.dart`: payout-first and bonus-first give
  quests 25 / base 0 / total 25). Belt-and-braces `rowid desc` tie-break in
  `app_database.dart watchLedger` filed as `SHARED_REQUEST.md` §4 (core —
  non-blocking, P12 is correct without it).
- Finding 7 (raw after friendly lead) — RETAINED deliberately. Stripping
  the raw cause breaks ~12 pinned `contains(...)` expectations across P06,
  P12 and states suites (several in files outside my scope), and the test
  stage has since pinned that P06 setup writes keep their raw copy. The
  friendly lead (`We couldn’t…`, U+2019) is the parent-facing part; the
  suffix is diagnostics. No change.
- Finding 5 (`next_payout.dart` location) — KEPT in `domain/`: `1_plan.md`
  §b mandates the path and the view + `next_payout_test.dart` import it;
  moving it mid-loop breaks the UI builder's imports. Revisit only with a
  plan update (and P13 will import the same path).
- Finding 8 (P13 hand-off) — carried: `state.items` is the **selected**
  child's ledger, defaulting to Maya. I cannot edit P13 docs (RULES §1:
  `docs/screens/P12/**` only); the note stands here for the P13 loop.
- Finding 9 (setup coupling) — accepted trade-off, confirmed by the
  review; no change.
- Findings 1–3, 6 (status-bar pinning, sheet `errorText`, toast tuple,
  `.ptitle`) — UI BUILDER's (views/widgets). Untouched.
- Skipped reproducers (`p12_bugs_test.dart` BUG-01/02/03/04/05,
  geometry guards) live outside my test scope (no `bloc`/`cubit`/
  `repository`/`data` in name) and their fixes are views/widgets/shared —
  nothing for this layer to un-skip. No skipped test exists in my files.

## Files changed

- `app/lib/features/pocket_money/data/pocket_money_repository_impl.dart`:
  order-independent `summarise` (+ precondition doc: one child's rows).
- `app/test/features/pocket_money/ledger_data_fallback.dart`: same rule
  in `_owedFromEntries`.
- `app/test/features/pocket_money/pocket_money_repository_test.dart`:
  same-second tie regression test (both orders).
- `docs/screens/P12/SHARED_REQUEST.md`: appended §4 (core `watchLedger`
  tie-break, non-blocking).
- `docs/screens/P12/2a_build_logic.md` (this file).

NOT touched: `presentation/views/**`, `presentation/widgets/**`,
`app/lib/core/**`, `app/lib/app/**`, any other feature, DI/routes (already
wired). No `google_fonts`. No simulator.

## Verification

- `dart format` clean; `flutter analyze lib/features/pocket_money
  test/features/pocket_money` → No issues found.
- My suites: repository 18/18 (incl. new tie test), next_payout 7/7,
  ledger bloc 18/18 pass.
- Regression: P06 setup bloc + repository + p06_bugs, P12 states —
  93/93 pass.

## LEFT FOR NEXT ITERATION

- Nothing in the logic layer is unfinished.

VERDICT: PASS
