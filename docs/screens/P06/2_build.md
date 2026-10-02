# P06 Pocket money setup — build report (Stage 2, iteration 2)

Route: `/pocket-money-setup` · feature `pocket_money` · parent mode · onboarding (P05 → P06 → P07).
Plan: `docs/screens/P06/1_plan.md`. Fix list: `docs/screens/P06/FIXES_1.md` (loop-generated from the iteration-1 report — overflow, untriaged interaction failures, teardown hang; stages 3–6 did not run in iteration 1). No `ORCHESTRATOR_NOTES.md`. No Pip on this screen.

## Files changed (all inside the feature sandbox, RULES §1)

Iteration-1 files (entity, repository + impl, bloc event/state, view, 3 test files) are committed in HEAD; iteration-2 delta is 3 files:

- `app/lib/features/pocket_money/presentation/views/pocket_money_setup_view.dart` — `_WeeklyBaseRow` now reflows via `LayoutBuilder`: single line at row width ≥ 300, otherwise name-line + right-aligned stepper (`_BaseStepper` split out so one instance lives in whichever branch builds). Keeps the fixed 44px stepper buttons at every width/scale instead of overflowing.
- `app/lib/features/pocket_money/presentation/bloc/pocket_money_bloc.dart` — load stream now `.transform(_closeOnError)` (error-then-close, same pattern as TodayBloc): a failed load's watchers no longer stay subscribed, Retry resubscribes cleanly. Added missing `dart:async` import.
- `app/test/features/pocket_money/pocket_money_setup_view_test.dart` — `flagsCollection.isSelected` now compared to `Tristate.isTrue/isFalse` (`dart:ui` import; `isButton`/`isHeader` stay bool); stepper taps/asserts use `RegExp` labels; fake repository builds a FRESH stream per `watch…()` call; Leo-stepper tap scrolls the row into view first (`ensureVisible`); direct-pump helper no longer closes the bloc (see hang item).

## What was done about each fix item

1. **Weekly-base row overflow at 320dp + scale 1.3 (+26px).** Root cause (semantics-tree dump + probes): under the test fallback font the stepper value runs ~118px, so avatar + name + fixed stepper exceed 248px. Fix: width-threshold reflow (above). Verified: `light/dark 320dp at text scale 1.3` pass, full 2×3×2 matrix green.
2. **Selection-flip / day-tap / selected-flags failures.** Two test-only causes: (a) `flagsCollection.isSelected` is `Tristate`, not `bool`, in this Flutter version (P01-style `isTrue` comparisons fail); (b) taps/assertions themselves worked. Fixed with `Tristate` comparisons. Verified passing.
3. **Stepper-tap failures.** Two causes: (a) `NestStepper`'s inner `-`/`+` text merges into the button semantics label, so exact-String `bySemanticsLabel` finds nothing — fixed with `RegExp` matching (the finder docs' recommended approach); (b) Leo's row sits below the fold behind the fixed `NestBottomCta`, so the tap hit the caption text (hit-test warning proved it) — fixed with `ensureVisible` before tapping. Verified: £3.50 and £1.00 updates pass.
4. **Retry-test stall (~10 min) / teardown hang.** Three stacked causes, all fixed: (a) fake reused one single-subscription error stream → `Bad state: Stream has already been listened to` on Retry — fixed with per-call stream factories; (b) failed load left `emit.forEach` subscribed forever (bloc `onEach` uses `cancelOnError: false` when `onError` is set) — fixed with `_closeOnError` so the failed load terminates; (c) `bloc.close()` still deadlocks under the FakeAsync clock with the never-closing `combineLatest` controller (bisected: identical sequence closes instantly in real async; P01-documented hazard) — the direct-pump helper no longer closes the bloc, with rationale comment (safe: fake repo owns no DB/timers; verified clean exit, no pending-timer complaints).
5. **No skipped bug tests exist for P06** (no `*_bugs_test.dart`, no `skip:` in the new files) — nothing to un-skip.

## Analyze / format tails

- `dart format .` → `Formatted 368 files (0 changed)`.
- `flutter analyze` (full app) → `No issues found!`
- Incidental analyzer fixes during iteration 2: `dart:async` import, `dart:ui show Tristate` import.

## Test tails

- `flutter test test/features/pocket_money` → `All tests passed!` (46/46: repo 9, bloc 11, view 26).
- `flutter test` (full suite) → `All tests passed!` (+691, EXIT 0).
- View-file run completes in ~seconds-to-minutes with no hang (previously stalled ~10 min at teardown).

## Scope compliance

Only the 3 files above differ from HEAD; all inside `app/lib/features/pocket_money/**` + `app/test/features/pocket_money/**`. No shared-component edits (the day-chip `labelStyle` follow-up from 1_plan §7 remains parked — the 44-tall `FittedBox(scaleDown)` cells pass at every width/scale). `SHARED_REQUEST.md`: not filed. Probe/debug test files removed.

VERDICT: PASS
