# P12 · 2a BUILD (logic chunk, iteration 2)

## CONTRACT CHANGES

UI builder — two additive changes since iteration 1 (nothing renamed or
removed; every `1_plan.md` name still exists):

1. `errorMessage` on the P12 paths now reads `We couldn’t load your
   ledger: <raw>` (load failure) or `We couldn’t save that: <raw>` (sheet
   submit failure) — curly ’ U+2019. The raw cause is retained after the
   colon, so all pinned `contains(...)` expectations still match. The
   failure body and the error toast render this string; no view change is
   required. P06 setup-write messages are byte-identical (out of scope).
2. `ledgerDataFallback` moved from
   `domain/pocket_money_repository.dart` to the shared test helper
   `app/test/features/pocket_money/ledger_data_fallback.dart` (same
   function, same semantics). Production fakes are unaffected; do not
   import it from view code. The domain interface is abstract-only again.

No state/event shape changed otherwise. `MoneyLedgerData.setup`,
`selectedChildId`, `items`, and all three P12 events keep their iteration-1
shapes. The success toast flow is unchanged (write-through, row appears on
stream re-emit — the view-side `await`-before-toast half of review finding
6 is yours; the bloc deliberately still emits nothing optimistically, which
your `money_ledger_states_test` and the bloc suite both pin).

## FIXES_1.md triage (logic layer only)

- Review 7 (raw errors) — FIXED in bloc: friendly lead + raw cause (see
  above). All `contains(...)` pins still match; new `startsWith` assertions
  lock the friendly copy in `pocket_money_ledger_bloc_test.dart`.
- Review 9 (test helper in domain) — FIXED: fallback + two private helpers
  moved to `test/.../ledger_data_fallback.dart`; the six P06 fake call
  sites only gained an import each. `domain/` is abstract + entities +
  `next_payout.dart` again.
- Review 8 (`next_payout.dart` location) — KEPT in `domain/`: `1_plan.md`
  §b mandates that path and your view + view test import it; moving it
  mid-iteration would break your imports. Revisit only with a plan update.
- Review 10 (`MoneyLedgerData.setup` coupling) — DECLINED (optional per
  the review): serving setup from a second stream would reintroduce double
  subscriptions on the P06 fakes' shared single-subscription stub streams
  (`Bad state: Stream has already been listened to`). Single-stream is
  load-bearing for P06 compat.
- Review 13 (`items` semantics / P13 hand-off) — NOTE FOR P13: `state.items`
  is the **selected** child's ledger (`data.entriesFor(selectedChildId)`),
  defaulting to Maya (first in creation order); previously it was
  `watchItems()` = the **active** child's ledger. `payout_view.dart` reads
  `state.items`, so P13 must either set its own selection explicitly or
  keep an `activeChildItems` alongside `items`.
- Review 1–4, 11 (spacer, goal/card heights, tile radius, `buildWhen`) —
  YOURS (views/widgets). Geometry guards fail exactly as pinned in
  iteration 1 (55/71, 105/121, 173/189, 400/419, 504/525); my layer moves
  no pixels.
- Review 5, 6 (sheet live region, toast-before-write) — YOURS
  (widgets/views). Bloc half noted under CONTRACT CHANGES.
- Review 12 + BUG-04 — filed as `docs/screens/P12/SHARED_REQUEST.md`
  (tile radius, `NestPageTitle`, segmented overflow). Already on disk; do
  not file a duplicate.
- BUG-01/02/03 (amount parser) — YOURS (sheet widget). BUG-05 (spacer) —
  YOURS (view). Skipped reproducers live in `p12_bugs_test.dart` /
  `money_ledger_geometry_test.dart`, which are outside my test scope, so
  un-skipping is left to you/the test stage.

## Files changed

- `app/lib/features/pocket_money/domain/pocket_money_repository.dart`:
  abstract-only again (fallback removed).
- `app/lib/features/pocket_money/presentation/bloc/pocket_money_bloc.dart`:
  `_loadErrorMessage` / `_submitErrorMessage` on the P12 load + submit
  paths (P06 paths untouched).
- `app/test/features/pocket_money/ledger_data_fallback.dart` (new): the
  moved fallback + `_owedFromEntries` + `_combineLatest2`, verbatim.
- `app/test/features/pocket_money/{p06_bugs_test,pocket_money_setup_bloc_test,pocket_money_setup_view_test,pocket_money_ledger_bloc_test}.dart`:
  one import each for the moved helper (+3 friendly-copy assertions in the
  ledger bloc test).
- `docs/screens/P12/SHARED_REQUEST.md` (new): three non-blocking shared
  items (tile radius, page title, segmented overflow).
- `docs/screens/P12/2a_build_logic.md` (this file).

NOT touched: `presentation/views/**`, `presentation/widgets/**`,
`app/lib/core/**`, `app/lib/app/**`, any other feature. No `google_fonts`.
No simulator. DI/routes unchanged (already wired).

## Verification

- `dart format` clean; `flutter analyze lib/features/pocket_money
  test/features/pocket_money` → No issues found.
- My suites: repository 17/17, next_payout 7/7, ledger bloc 15/15 pass.
- P06 regression (shared bloc/interface): setup bloc + repository,
  p06_bugs 76/76 pass.
- UI-owned suites observing my layer: states + ledger view 27/27 pass.
- Remaining failures in the feature dir are exactly the 6 pre-existing
  geometry guards (views spacer, iteration-1-pinned, UI builder's fix);
  everything else in the batch passes (151 up).

## LEFT FOR NEXT ITERATION

- Nothing in the logic layer is unfinished. UI builder owns the views-side
  findings (1–6, 11, BUG-01/02/03/05) and un-skipping their reproducers.

VERDICT: PASS
