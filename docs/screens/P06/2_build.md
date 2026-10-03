# P06 Pocket money setup — integration build (Stage 2 INTEGRATE, iteration 3)

Two parallel builders produced this state; integration only. Route `/pocket-money-setup` · feature `pocket_money` · parent mode.

## 2a — logic builder (`2a_build_logic.md`)

- **Contract: additive only** — no event/state shape changes. New: `PocketMoneySetup.withChildBase(id, pence)` (pure, insertion order kept), `PocketMoneyState.copyWith(..., {clearErrorMessage = false})`, private bloc fields `_pendingDay` / `_requestedBase`.
- **Files changed:** `pocket_money_bloc.dart`, `domain/entities/pocket_money_setup.dart`, `presentation/bloc/pocket_money_state.dart`, plus tests (`pocket_money_setup_bloc_test.dart`, `p06_bugs_test.dart`).
- Fixes: `_onWeeklyBaseStepped` early-returns on an unknown child id (BUG-07), accumulates each request on the previous *request* via `_requestedBase` recorded synchronously before the first await so overlapping rapid taps add up (BUG-01, instrumented probe: writes 350 then 400), and confirms the write in state via `withChildBase`; `_onPayoutDayChanged` guards on the last *requested* day so a fast Sun→Sat correction is not dropped (BUG-02); load emissions clear the stale `errorMessage` (BUG-06). Three regression tests added.
- Review #4 (`assert` → `ArgumentError`) deliberately NOT changed: `1_plan.md` §2 mandates asserts and two test groups pin `AssertionError`.

## 2b — UI builder (`2b_build_ui.md`)

- **Files changed:** `pocket_money_setup_view.dart`, `pocket_money_setup_view_test.dart` (alignment group), `p06_bugs_test.dart`, new `docs/screens/P06/SHARED_REQUEST.md`.
- Fixes: failed writes keep the loaded form and show an inline danger caption, `_FailureBody`/`Retry` only for load failures (BUG-05); day cells are `max(44, (available − 6·gap6)/7)` with a breakout inset so cells reach ≥44dp at 390/430 and the row scrolls horizontally at 320 (BUG-04); `NestChip`+`FittedBox` replaced by a token-built `_DayPill` painting the design's 32dp height with the 13/18 w600 label (BUG-03 visual cause; `TODO(P06)`); coin tile → `NestSpacing.s10`, radio dot → `NestSpacing.gap10` (review #6).
- Uncommitted at integration time: two cosmetic lines in the view — a redundant `clipBehavior: Clip.hardEdge` removed (it was the default and was the last analyzer `info`) and one re-wrapped expression from `dart format`. Both verified part of the committed-plus-worktree state below.

## FIXES_2 items

| Item | Owner | Status |
|---|---|---|
| P06-BUG-01 (MAJOR) lost rapid `+` taps | 2a | DONE — request-tracking accumulation; proof un-skipped, green (real repo £3.00 → £4.00) |
| P06-BUG-02 fast Sun→Sat dropped | 2a | DONE — guard on last requested day; proof un-skipped, green |
| P06-BUG-03 day pills paint ~19dp | 2b | VISUAL cause DONE (`_DayPill`, 32dp); the widget proof stays **skipped** — its finder expects the shared `NestChip`, so closing it rides on the new `SHARED_REQUEST.md` (compact/`labelStyle` day variant) |
| P06-BUG-04 day cells 40.3dp wide | 2b | DONE — ≥44dp clamp + breakout inset + scroll at 320; proof un-skipped, green |
| P06-BUG-05 failed write blanks form | 2b | DONE — inline error, form retained; proof un-skipped, green |
| P06-BUG-06 stale `errorMessage` | 2a | DONE — `clearErrorMessage` on load emissions; proof un-skipped, green |
| P06-BUG-07 unknown-child write | 2a | DONE — early return before any repository call; proof un-skipped, green |
| Review #3 stale message | 2a | DONE (same fix as BUG-06) |
| Review #4 `assert` → `ArgumentError` | 2a | LEFT BY DESIGN — asserts mandated by `1_plan.md` §2 and pinned by tests |
| Review #6 hard-coded sizes | 2b | PARTIAL — `s10`/`gap10` applied; 13 / 22 / 200 parked in `SHARED_REQUEST.md` |
| Review #5 unknown-child step | 2a | DONE (same fix as BUG-07) |
| Review #7 day-cell width | 2b | DONE (same fix as BUG-04) |

Remaining skip: exactly one, `P06-BUG-03`'s widget-level pill-height proof, intentionally pending the shared `NestChip` change.

## Integration actions (this stage)

No integration breakage: 2a declared an additive-only contract and 2b compiled against it unchanged. No code edits were needed — the worktree diff was already consistent and analyzed clean. The integrator only ran the stage gates.

## Analyze / test tails

- `dart format .` → `Formatted 372 files (0 changed) in 1.17 seconds.`
- `flutter analyze` (full app) → `No issues found! (ran in 5.3s)`
- `flutter test` (full suite) → `All tests passed!` (`+764 ~1`, EXIT 0, ~17s). The single `~1` is the intentionally skipped P06-BUG-03 proof; no unexpected skips or failures.

## Scope compliance

No files modified by the integrator. Worktree diff is the feature view + the two builders' own docs, all inside RULES §1.

VERDICT: PASS