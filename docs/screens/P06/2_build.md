# P06 Pocket money setup — integration build (Stage 2 INTEGRATE, iteration 2)

Two parallel builders produced this state; integration only. Route `/pocket-money-setup` · feature `pocket_money` · parent mode.

## 2a — logic builder (`2a_build_logic.md`)

- **Contract changes: none.** Public names unchanged per `1_plan.md` §2: `PocketMoneySetup` (+ `childById`), `PocketMoneyRepository.watchSetup/setMode/setPayoutDay/setWeeklyBasePence`, `PocketMoneyState.setup`, events `PocketMoneyModeChanged` / `PocketMoneyPayoutDayChanged` / `PocketMoneyWeeklyBaseStepped(childId, deltaPence)`, 50p step, 0..2000 clamp.
- **Files changed: none** — existing repository impl, bloc, state/event and DI/routes already satisfied the plan. Verified: `watchSetup` = `families` truth + `settings` mirror + children by SQLite `rowid` (Maya then Leo); setters write both tables in one transaction with `updatedAt` UTC; bloc keeps ONE `emit.forEach` over `combineLatest2` with `_closeOnError`, guarded day re-tap, base read from `state.setup`.
- Checks: analyze clean on the logic files; bloc + repository tests 20/20.

## 2b — UI builder (`2b_build_ui.md`)

- **Files changed:** `app/test/features/pocket_money/pocket_money_setup_view_test.dart` — deleted the `package:google_fonts/google_fonts.dart` import and the `GoogleFonts.config.allowRuntimeFetching = false;` call (package removed from `pubspec.yaml`; the orchestrator FONTS rule forbids both).
- No view/widget source edits: the committed `pocket_money_setup_view.dart` already matched plan + design (status-bar reserve → compact nav → 20px-gutter scroll → dense `NestBottomCta` → home indicator; token-only option cards, settings card with full-bleed dividers, 44-tall day cells, Maya-then-Leo base rows with `<300px` reflow, coin-value row; CTA surface runs to the physical edge in both themes; HTML-verbatim copy).
- Checks: analyze clean; view suite 26/26.

## Integration actions (this stage)

- No integration breakage: 2a's contract was unchanged, so 2b compiled against it with zero edits; the only uncommitted diff in the worktree was 2b's google_fonts removal, already merged onto the committed code cleanly.
- Ran the stage checks only — `dart format .`, full-app `flutter analyze`, full-app `flutter test`.
- No source changes made by the integrator.

## FIXES_1 items

| Item | Owner | Status |
|---|---|---|
| Weekly-base row overflow at 320dp × 1.3 (+26px) | 2b | DONE — `LayoutBuilder` reflow below 300px row width; 12-way light/dark × width × scale matrix green |
| Selected-flag / day-tap failures | 2b | DONE — test-only (`Tristate.isTrue/isFalse`) |
| Stepper-tap failures | 2b | DONE — test-only (`RegExp` semantics labels, `ensureVisible` for the below-fold Leo row) |
| Retry test stall / teardown hang | 2a (logic half already carried `_closeOnError`) | DONE — fake-repo fresh streams per `watch…()`; direct-pump helper documents why it does not close the bloc under FakeAsync |
| Skipped bug tests to un-skip | 2a | N/A — no `*bug*` files, no `skip:` in `app/test/features/pocket_money/` |
| google_fonts removal (FONTS rule) | 2b | DONE — feature + tests contain no `google_fonts`/`GoogleFonts` |

## Analyze / test tails

- `dart format .` → `Formatted 369 files (0 changed) in 0.87 seconds.`
- `flutter analyze` (full app) → `No issues found! (ran in 3.4s)`
- `flutter test` (full suite) → `All tests passed!` (+696, EXIT 0, ~14s; previous stall gone)

## Scope compliance

No files modified by the integrator; only 2b's one test file differs from HEAD, inside `app/test/features/pocket_money/**`. No shared-code edits.

VERDICT: PASS