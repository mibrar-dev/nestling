# P01 Welcome — bug hunt (Stage 6, iteration 2)

Adversarial re-test of `/welcome` (parent mode, feature `onboarding`) on
`screen/P01`, HEAD `773de5e` (main merged through `ded8eb9`; shared fixes
`763192d` and `71d2400` are ancestors of `main`). The iteration-2 build's
uncommitted work is in the tree (`welcome_view.dart` + the onboarding tests).

Method this iteration: re-ran every iteration-1 proof against the new code,
rewrote the BUG-2 proof to the shipped contract and un-skipped it (mandatory
`ORCHESTRATOR_NOTES.md` item 5 / Stage-4 finding 1), re-ran the adversarial
probes on the new `PipAvatar`/`OverflowBox` code, and audited the freshly
merged router gate. Proofs live in
`app/test/features/onboarding/p01_bugs_test.dart` (5 enforced + 1 skipped).

Gates after this stage: `dart format` 342 files clean · `flutter analyze`
No issues found · `flutter test test/features/onboarding` **46 passed,
1 skipped, 0 failed** · full suite **352 passed, 1 skipped, 0 failed**. The
single skip is the still-reproducing BUG-4 proof (verified failing when
un-skipped, temporary copy removed).

---

## Resolved and now enforced (verified this iteration)

### BUG-1 — scene cropped below 390dp → **fixed** (P01-owned)

`welcome_view.dart:98-111`: the outer box reserves `_frameW * scale`, the
`OverflowBox` lays the `Stack` out at full 350×388 and only paint scales.
Proofs pass at 320dp (`sceneStack.size == Size(350, 388)`,
`describeApproximatePaintClip == null`) and the four width regressions
(320/360/390/430) are green with the stronger size pin.

### BUG-2 — OS bottom inset counted twice → **fixed** (shared `763192d`)

`NestHomeIndicator` is a no-op in the app (`nest_chrome.dart:222-225`) and
`NestBottomCta`'s `SafeArea` owns the inset exactly once. The proof was
rewritten to the shipped contract and **un-skipped**
(`BUG-2 OS bottom inset is counted exactly once`):
`insetTop == baselineTop − 34`, caption bottom at `844 − 34 − s4`, and
`NestHomeIndicator` measures 0×0. Measured: baseline primary top 672.0,
with a 34dp inset 638.0 (delta −34). The Stage-5 simulator drift
(623.3 → design 656.7) is closed. Do not touch `nest_bottom_cta.dart`.

### BUG-3 / BUG-3b — kid-mode gate bypass → **fixed** (shared `71d2400`)

Onboarding locations are now parent-only; both proofs pass (`/welcome` and
`/value-tour` land on `/parental-gate`). The follow-up merge `ded8eb9` (P08)
completed the gate for `/today-empty` and `/quest-editor`, and the shared
`router_redirect_test.dart` now parameterizes all 17 parent routes — audited:
every product parent route is gated; only the dev-only `/design-system`
gallery is open, which is intentional (default boot route for dev).

### BUG-5 — coin `--sh-1` shadow clipped → **fixed** (P01-owned)

`welcome_view.dart:111` is `Stack(clipBehavior: Clip.none)`, matching the
HTML `.scene`; the proof is un-skipped and passes.

---

## Open

### BUG-4 — MAJOR (shared): fresh install never creates the `app_state` row

- **Severity:** major — on a release first launch (no `SEED` flag) onboarding
  completion is never persisted, so every restart returns the user to
  `/welcome`: the screen loops forever. This is the "state after app restart
  (Drift persistence)" case.
- **Where (shared):** `AppSession._write` upserts now (`763192d`), but the
  feature repositories still write directly:
  `app/lib/features/onboarding/data/onboarding_repository_impl.dart:24-28`
  (`completeOnboarding`) and the paywall repo (`startTrial`/`activate`) do
  `UPDATE … WHERE id = 1`; nothing bootstraps row 1 at DB open.
- **Repro:** `configureDependencies(database: AppDatabase.memory())` with no
  seed → `app_state` select is empty → `OnboardingRepository.completeOnboarding()`
  → `session.refresh()` → `onboardingComplete` is still `false`.
- **Failing test:** `BUG-4 fresh install never persists onboarding completion`
  (skipped with its bug id; verified `Expected: true / Actual: <false>` when
  un-skipped this iteration).
- **Suggested fix (shared):** insert-if-missing in
  `MigrationStrategy.beforeOpen` (preferred — covers every writer) or an
  upsert in each repository. Do **not** patch only the onboarding repo: the
  paywall has the same defect and the two paths must not diverge. The
  `SHARED_REQUEST.md` item is narrowed to exactly this.

### OPEN MANDATORY ITEM — headline line break (`ORCHESTRATOR_NOTES` #3, Stage-5 dev 1)

Design wraps `Chores that feel` / `like a game.`; the app wraps
`Chores that feel like` / `a game.` (band 4 ≈5.75%). The orchestrator's
mandatory note prescribes constraining the headline width (≈300,
`ConstrainedBox`; never a hard `\n`, must still wrap at 320dp / scale 1.3).
Not applied in the current tree — it belongs to the next build pass. No
widget-test proof is possible here: `flutter test` falls back to the test
font, so the wrap cannot be measured without bundled Inter/Nunito
(cf. shared request item 3); the Stage-5 pixel comparison is the check.

### INFO — inset-0 devices have no 34dp bottom band (review finding 4)

With `NestHomeIndicator` a no-op and no OS inset (tests, some Android nav
modes), the CTA panel sits flush with the screen edge — 34dp lower than the
design's band. Not a defect under the orchestrator's OS-chrome rule; the
optional shared floor (`max(viewPadding.bottom, 34)` in `NestBottomCta`) is
recorded in the review, not here.

### INFO — `PipAvatar` defaults instead of explicit args (review finding 5)

`welcome_view.dart:148` is `PipAvatar(style: mochi, stage: 2)`; `sunny`/`idle`
are defaults and pinned by the widget test. Behaviour is correct today; pass
`skin: PipSkin.sunny, mood: PipMood.idle` explicitly for robustness (next
build pass).

---

## Verified sound (probes run this iteration)

| Area | Probe | Result |
|---|---|---|
| Rapid double tap | two taps on Get started, no pump between | single `/value-tour`, `takeException()` null |
| Data edge cases (0/2/6 children, "Maximilian-Alexander", 9999 coins, £999.99 goal) | seeded 4 extra children with extremes on top of `Seed.demo`, pumped P01; `Seed.empty` (0 children) covered by the suite | no exception, extreme strings/numbers absent — P01 still reads no child/money data |
| Back navigation / deep links | `/welcome` is a root route; parent-mode deep link still renders P01 (unchanged); kid-mode deep link now gated (BUG-3) | no regression; `go` to `/value-tour` matches the P02 design (no back affordance) |
| Pip semantics | `Semantics(image, label)` wrapper + `PipAvatar` | exactly one labelled node, HTML alt text intact, no duplicate |
| Home-indicator layout | `NestHomeIndicator` size | 0×0 in app (OS draws it), CTA bottom flush at inset 0 (see INFO) |
| Text scale 1.3 × width 320 (+390/430, light/dark) | existing 12-case matrix | all green, no overflow/ellipsis |
| Dark/light contrast | token pairs (unchanged) | headline 16.30/15.45:1, body 10.84/8.31:1, caption 9.82/8.87:1, primary 8.43/4.96:1 — all ≥4.5 |
| Async gap / emit after close | bloc closed mid-load | subscription cancelled cleanly (carried from iteration 1) |
| Timezone / money rounding | P01 renders no dates or money | N/A by construction |

## Summary

| # | Severity | Owner | Status |
|---|---|---|---|
| BUG-1 | blocker | P01 | **fixed**, proof enforced |
| BUG-2 | major | shared | **fixed** (`763192d`), proof rewritten + enforced |
| BUG-3/3b | major | shared | **fixed** (`71d2400`), proofs enforced |
| BUG-4 | major | shared repos + bootstrap | **open**, proof skipped, filed |
| BUG-5 | minor | P01 | **fixed**, proof enforced |
| — | mandatory | P01 | headline break pending (next build) |
| — | minor/info | P01/shared | PipAvatar explicit args; inset-0 band |

P01's own code has no known major defects left. The stage cannot pass while
BUG-4 still reproduces: it is a major, product-blocking persistence bug in the
flow this screen starts, even though its fix is shared and already filed with
a repro (`SHARED_REQUEST.md`).

VERDICT: FAIL
