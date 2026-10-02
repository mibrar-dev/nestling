# P01 Welcome — test notes (Stage 3, iteration 2)

Route `/welcome`, feature `onboarding`, parent mode. Tests live in
`app/test/features/onboarding/`, use the in-memory Drift DB through
`setUpTestScope()` (`Seed.demo` default, `Seed.empty`/`Seed.fresh`) and the
shared `disposeApp()` drain.

This iteration re-verified the iteration-1 work after the build stage's
iteration-2 fixes and updated the suite to the new shared contracts
(`NestStatusBar` height-only, `PipAvatar` orchestrator rule, kid-mode
onboarding gate).

## Tests added / changed this iteration

### `app/test/features/onboarding/welcome_view_test.dart` (30 tests)

- **Status bar (new contract):** light test now asserts the mock `9:41`
  clock is **absent** and that `NestStatusBar` reserves exactly
  `NestDevice.statusH` (47dp) — the OS draws the real bar. The old
  `find.text('9:41')` assertion was removed.
- **PipAvatar group (new, mandatory ORCHESTRATOR_NOTES #1):**
  - renders `PipAvatar` with `style: mochi` · `skin: sunny` (default) ·
    `stage: 2` · `mood: idle`;
  - fills the design slot — 168×168 at (91,120) inside the 350×388 scene;
  - the v1 `pip_stage_2.svg` illustration is absent;
  - in `flutter test` the Rive runtime is absent, so the approved idle
    still-frame SVG `pip_v2/mochi/s2_idle_1.svg` is what paints;
  - the HTML alt text is still exposed (`Semantics(image, label)`).
- **Accessibility:** added the heading flag assertion
  (`flagsCollection.isHeader` on the headline), alongside the existing CTA
  labels + `isButton`, Pip alt text, excluded chrome, ≥44dp (and ≥52dp spec)
  tap targets, and no icon-only/kid controls.
- **BUG-1 regressions strengthened:** the four `no crop` tests now also pin
  `sceneStack.size == Size(350, 388)` at 320/360/390/430dp — the layout is
  genuinely fixed, not merely masked by `Clip.none`.

### `app/test/features/onboarding/p01_bugs_test.dart` (6 proofs)

- **Un-skipped and now enforced:** BUG-1 (scene scale), BUG-3 + BUG-3b
  (kid-mode gate), BUG-5 (coin shadow clip) — all pass.
- **BUG-3b rewritten:** the old "kid taps Get started" setup is impossible
  once `/welcome` itself redirects to the gate, so the proof now asserts the
  real contract — in kid mode, pumping `/value-tour` lands on
  `/parental-gate` (the whole onboarding flow is gated).
- **Still skipped (shared code, not P01-editable):** BUG-2 and BUG-4. Both
  were verified to still fail when un-skipped (temporary copy, removed
  afterwards: `+4 -2`), so the skips are honest.

## Results (run by this stage, `app/`)

- `dart format .` — 341 files, 0 changed (clean).
- `flutter analyze` — `No issues found!`
- `flutter test test/features/onboarding` — **45 passed, 2 skipped,
  0 failed** (`+45 ~2: All tests passed!`).
- `flutter test` (full suite) — **333 passed, 2 skipped, 0 failed**
  (`+333 ~2: All tests passed!`). The 2 skips are the shared BUG-2/BUG-4
  proofs.

## Bugs found

**None in the screen this iteration.** All P01-owned bugs from iteration 1
are fixed and now pinned by passing tests (independently re-verified here):

| Bug | Evidence it is fixed |
|---|---|
| BUG-1 scene cropped below 390dp | `welcome_view.dart:98-111` — outer box reserves the scaled frame, `OverflowBox` lays the Stack out at full 350×388, only paint scales. At 320dp the Stack is 350×388 and `describeApproximatePaintClip` is `null` (was 280×310.4 / non-null). 390/430 unchanged. |
| BUG-5 coin `--sh-1` shadow clipped | `welcome_view.dart:111` — `Stack(clipBehavior: Clip.none)`, matching the HTML `.scene`; proof asserts it. |
| v1 `pipStage2` SVG in a product screen | `welcome_view.dart:138-150` — `PipAvatar(style: mochi, stage: 2)` (idle, sunny) in the same slot, v1 asset absent, alt text kept. |

### Remaining — shared-code bugs (tracked, not in P01's edit scope)

Both are outside `app/lib/features/onboarding/**` and were verified to still
reproduce when their proofs are un-skipped. `docs/screens/P01/SHARED_REQUEST.md`
lists them (the fixed kid-mode item was removed; the gate is now provided by
main's `71d2400`, merged here via `8ac81ec`):

1. **BUG-2 — bottom system inset counted twice.**
   `app/lib/core/design_system/components/nest_bottom_cta.dart:17` wraps the
   CTA in `SafeArea` while `NestHomeIndicator` already reserves 34dp, so P01's
   CTAs sit 34dp high on home-indicator devices. Repro:
   `flutter test test/features/onboarding/p01_bugs_test.dart --plain-name 'BUG-2'`
   (after removing its `skip:`); on the simulator this is the stage-5
   623.3 vs 656.7 drift.
2. **BUG-4 — fresh install never creates the `app_state` row.**
   `app/lib/core/data/app_session.dart` (`_write` UPDATE-only) plus
   `OnboardingRepositoryImpl.completeOnboarding`; nothing inserts row 1 at
   startup (no `beforeOpen`/bootstrap insert in `app/lib/app/di.dart`), so a
   release first launch never persists onboarding completion. Repro:
   the `BUG-4` proof.

Shared request item 3 (warm the first-frame SVGs / bundle Inter+Nunito,
review findings 4+8) is unchanged and also non-blocking here.

## Harness note (unchanged, not a product bug)

`bloc.close()` on a bloc with a pending `emit.forEach` over a
`StreamController`-backed stream deadlocks under the widget-test fake-async
zone; the loading-state widget test uses an immediately-completing empty
stream and the pending-stream path is covered by `blocTest` in
`onboarding_bloc_test.dart`.

## Correction (Stage 6, iteration 2)

- **BUG-2 is fixed on main** (`763192d`). `NestHomeIndicator` is a no-op in
  the app and `NestBottomCta`'s `SafeArea` owns the OS inset exactly once; the
  proof is now un-skipped in `p01_bugs_test.dart` and asserts the shipped
  contract (`insetTop == baselineTop − 34`, caption bottom at
  `844 − 34 − s4`). The "still skipped" claim above is superseded — do not
  touch `core/design_system/components/nest_bottom_cta.dart`.
- **BUG-4's remaining root cause is narrower** than stated above:
  `AppSession._write` upserts now; only the onboarding/paywall repositories
  (direct `UPDATE … WHERE id = 1`) and the missing startup bootstrap remain.
  See `SHARED_REQUEST.md` (item BUG-4).

VERDICT: PASS
