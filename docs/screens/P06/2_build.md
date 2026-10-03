# P06 Pocket money setup — integration build (Stage 2 INTEGRATE, iteration 5)

Two parallel builders worked on P06; this stage only integrated them and fixed any
merge breakage. Route `/pocket-money-setup` · feature `pocket_money` · parent mode.

## 2a — logic builder (`2a_build_logic.md`, iteration 5)

- **Contract: none changed** (no event/state shapes, no repository interface — all three
  feature fakes compile untouched).
- **Files changed:** `pocket_money_repository_impl.dart`, `pocket_money_bloc.dart`.
  - Review #9 — `watchSetup` dropped the `watchSetting` subscription
    (`combineLatest3` → `combineLatest2`); the mirror is written in the same transaction
    as `families`, so the extra subscription only re-emitted identical setups.
  - Review #12 — `setMode`/`setPayoutDay` now throw `ArgumentError` past the `assert`,
    so the invariant holds in release/profile while debug asserts still fire first
    (validation tests pin `AssertionError`, unchanged and green).
  - Review #10 — `if (emit.isDone) return;` guards before the failure emits in
    `_onModeChanged` / `_onPayoutDayChanged` (day-guard rollback still runs first).

## 2b — UI builder (`2b_build_ui.md`, iteration 5)

- **Files changed:** `pocket_money_setup_view.dart`, `pocket_money_setup_view_test.dart`,
  `p06_bugs_test.dart`, `SHARED_REQUEST.md`.
  - Review #3 / P06-BUG-10 — `_SetupTitle` renders `NestBalancedText` (with
    `textAlign: left`, keeping the owner ALIGNMENT rule) inside the existing
    `Semantics(header: true)`; `NestBalancedText` is now present in the worktree after the
    main merge, so the earlier merge-order dependency is gone.
  - Review #1 (MAJOR) — the payout-day row is back at the design's **32 px** band: the
    tight `Padding`/`SizedBox` ancestors that swallowed the out-of-bounds tap point are
    gone (the card `Column` is the `NestChipWrap`'s direct parent), the inset is done in the
    cell-width math, the pills paint flush at the design y, and the settings card returns
    to its design height (270) so it no longer slides under the CTA panel.
  - Review #2 — the analyzer `info` in the view test is gone (`borderRadius` compared to
    `NestRadii.allM`).
  - Review #4 — all six hand-rolled teardowns replaced with `disposeApp(tester)`.
  - Review #5/#6 — nickname + coin-value rows use `.amount-name` (w600, 16/22); the loading
    spinner is token-coloured (`tokens.leaf`).
  - Review #7/#8/#14 — SHARED_REQUEST updated; `BlocBuilder.buildWhen` filters ledger-only
    emissions.
  - Review #13 — the stale `P06-BUG-04` (≥44 × ≥44 cell) proof was **deleted**, since its
    width demand is superseded by ORCHESTRATOR_NOTES item 2. This removes the last skip in
    the feature.

## Integration actions (this stage)

None required. 2a declared no contract change and 2b compiled against it; the combined
worktree analyzed clean and the full suite passed on the first run, so no source edits
were made by the integrator (only the stage gates were run).

## FIXES_4 items (all from `3_test.md` / `4_review.md`)

| Item | Owner | Status |
|---|---|---|
| #1 day row 44 instead of design 32 (MAJOR) | 2b | DONE — 32 px band, pills at the design y, card back to 270, card flush above the CTA |
| #2 `flutter analyze` not clean (MAJOR) | 2b | DONE — `No issues found!` |
| #3 H1 must be `NestBalancedText` (MAJOR) | 2b | DONE (component present after the main merge) |
| #4 real-DB widget test lacked `disposeApp` (MAJOR) | 2b | DONE — all six teardowns now drain Drift |
| #5 `.amount-name` w600 16/22 | 2b | DONE (nickname + coin value) |
| #6 spinner token colour | 2b | DONE |
| #7 un-tokened literals | 2b | PARTIAL by design — `SHARED_REQUEST.md` extended (13/22/200/60/300); blocked on shared tokens |
| #8 `_DayPill` re-implements `NestChip` | 2b | PARKED — `SHARED_REQUEST.md` item 1 (shared day variant); `TODO(P06)` retained |
| #9 unused `watchSetting` subscription | 2a | DONE |
| #10 `emit` after `await` without `isDone` | 2a | DONE |
| #11 invented empty-state copy | 2b | FLAGGED — `Add children to set weekly amounts.` is screen-authored (renders only under `Seed.empty`/`Seed.fresh`); needs orchestrator ratification |
| #12 assert-only validation | 2a | DONE (asserts kept for debug + `ArgumentError` for release) |
| #13 stale `P06-BUG-04` skip | 2b | DONE — test deleted |
| #14 whole form rebuilds on ledger emissions | 2b | DONE — `buildWhen` |
| P06-BUG-10 unbalanced H1 (from `3_test`) | 2b | DONE — same fix as #3 |

Remaining known-open items are all blocked on shared work, not screen work: the
`NestChip` day variant (review #8 / SHARED_REQUEST item 1), the missing spacing tokens
(#7 / item 2), and the orchestrator's call on the empty-state copy (#11).

## Analyze / test tails

- `dart format .` → `Formatted 390 files (0 changed) in 0.95 seconds.`
- `flutter analyze` (full app) → `No issues found! (ran in 3.5s)`
- `flutter test` (full app) → `All tests passed!` (`+1153`, EXIT 0, ~18s). **No skips at
  all** — the feature's last skipped proof (P06-BUG-04) was deleted, and no test in
  `app/test/features/pocket_money/` contains a `skip:`.

## Scope compliance

No integrator edits. Worktree changes are the two builders' files, all under
`app/lib/features/pocket_money/**`, `app/test/features/pocket_money/**` and
`docs/screens/P06/**` (RULES §1). No shared code, no `analysis_options` change, no
`google_fonts`/`GoogleFonts` in the feature, no simulator used.

VERDICT: PASS