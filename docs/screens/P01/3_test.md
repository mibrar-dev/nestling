# P01 Welcome — test notes (Stage 3, iteration 3)

Route `/welcome`, feature `onboarding`, parent mode. Tests live in
`app/test/features/onboarding/`, use the in-memory Drift DB through
`setUpTestScope()` (`Seed.demo` default, `Seed.empty`/`Seed.fresh`) and the
shared `disposeApp()` drain.

Iteration 3 closes the test backlog: the last skipped proof was rewritten to
its shipped contract, and the mandatory headline cap is now pinned. The
suite has **zero skips**.

## Tests added / changed this iteration

### `app/test/features/onboarding/p01_bugs_test.dart` (6 proofs, 0 skips)

- **BUG-4 proof rewritten + un-skipped.** Main's `045d190` added
  `AppDatabase.migration.beforeOpen` (insert-if-missing for the `app_state`
  singleton row). The old proof asserted the bug (`row is null` on a fresh
  DB), which the fix correctly invalidates; it now asserts the shipped
  contract: the row exists on a brand-new DB, `session.onboardingComplete`
  starts `false`, and `OnboardingRepository.completeOnboarding()` persists
  (`true` after `refresh`) with no seed. Passes.
- **BUG-2 proof** (rewritten in iteration 2) asserts the new contract —
  CTA block moves up exactly 34dp with a 34dp OS inset, panel ends 34dp
  above the screen edge, `NestHomeIndicator` is 0-height in the app — and is
  enforced. Passes (ORCHESTRATOR_NOTES #5 satisfied).
- BUG-1 / BUG-3 / BUG-3b / BUG-5 proofs stay enforced and pass.

### `app/test/features/onboarding/welcome_view_test.dart` (31 tests)

- **Headline cap pinned (ORCHESTRATOR_NOTES #3):** new test asserts the
  headline paragraph renders at ≤300pt at 390dp (`ConstrainedBox`, no hard
  `\n`), so "like" falls to line 2 as in the design. The 12-case
  width × text-scale matrix still proves 320dp / scale 1.3 wrap without
  overflow.
- Everything else carries over unchanged: light + dark copy, the 320/390/430
  × 1.0/1.3 matrix, `Seed.empty`/`Seed.fresh`, the five bloc states, both
  navigation taps, PipAvatar contract (mochi · sunny · stage 2 · idle, 168×168
  @ 91/120, idle SVG still frame, alt semantics), status-bar height-only
  contract, heading flag, CTA labels + `isButton`, ≥44dp (≥52dp spec) tap
  targets, no icon-only/kid controls.

## Results (run by this stage, `app/`)

- `dart format .` — 342 files, 0 changed (clean).
- `flutter analyze` — `No issues found!`
- `flutter test test/features/onboarding` — **48 passed, 0 skipped,
  0 failed** (`+48: All tests passed!`).
- `flutter test` (full suite) — **355 passed, 0 skipped, 0 failed**
  (`+355: All tests passed!`).

## Bugs found

**None new this iteration.** All six previously-found bugs are fixed and now
pinned by enforced, passing proofs:

| Bug | Owner | Evidence |
|---|---|---|
| BUG-1 scene cropped below 390dp | P01 | Stack lays out 350×388 at 320/360/390/430 with no paint clip (`welcome_view.dart:98-111`); 4 regression tests + BUG-1 proof. |
| BUG-2 bottom inset counted twice | shared | `763192d`; BUG-2 proof asserts the once-counted contract (baseline −34dp with a 34dp inset). |
| BUG-3 / 3b kid-mode gate | shared | `71d2400` + `ded8eb9`; both proofs pass (`/welcome` and `/value-tour` → `/parental-gate` in kid mode). |
| BUG-4 first-install persistence | shared | `045d190` (`beforeOpen` insert-if-missing); rewritten proof passes. |
| BUG-5 coin shadow clipped | P01 | `Stack(clipBehavior: Clip.none)` (`welcome_view.dart:111`); proof passes. |

`SHARED_REQUEST.md` now records every blocking item as closed; the two
remaining entries are non-blocking quality items (first-frame SVG warm-up +
bundled fonts; optional inset-0 CTA floor) and do not block this screen.

## Harness note (carried, not a product bug)

`bloc.close()` on a bloc with a pending `emit.forEach` over a
`StreamController`-backed stream deadlocks under the widget-test fake-async
zone; the loading-state widget test uses an immediately-completing empty
stream and the pending-stream path is covered by `blocTest` in
`onboarding_bloc_test.dart`.

VERDICT: PASS
