# P01 Welcome — bug hunt (Stage 6, iteration 1)

Adversarial pass over `/welcome` (parent mode, feature `onboarding`).
Branch `screen/P01`; mid-stage the shared commit
`9ad2703 Design system: NestStatusBar reserves space only…` was merged into
the branch (see "Process findings" for the one test it invalidates).

Proofs live in `app/test/features/onboarding/p01_bugs_test.dart`: every test
below fails against the current code and is skipped with its bug id in the
test name, so the suite stays green until the fix lands. Verified by running
the file with the `skip:` markers removed (`+0 -6`), then restored (`+0 ~6`).

Quick rerun of a single proof:

```
cd app
flutter test test/features/onboarding/p01_bugs_test.dart --plain-name 'BUG-2'
```

Baseline gates at the end of this stage: `dart format` 341 files clean,
`flutter analyze` → No issues found, `flutter test` → **324 passed, 6 skipped,
3 failed**. The 3 reds are BUG-1 (×2, pre-existing stage-3 regressions) and one
stale status-bar assertion created by the mid-stage shared merge (finding 0
below) — no other P01 test is red.

---

## BUG-1 — BLOCKER: illustration scene is cropped, not scaled, below 390dp

- **Severity:** blocker — broken artwork on 320/360dp devices and the branch
  cannot go green without it.
- **Where:** `app/lib/features/onboarding/presentation/views/welcome_view.dart:91-104`
  (`_WelcomeScene` `LayoutBuilder`; offending tight `SizedBox` at :94-102,
  `Stack` at :103).
- **Repro:** `flutter test test/features/onboarding/welcome_view_test.dart
  --plain-name 'no crop'` → 320dp and 360dp fail. At 320 the scene `Stack`
  lays out at 280×310.4 **before** the 0.8 paint scale, so the top-right coin
  (design `x=308..342`) is entirely clipped and the nest/circle right edges
  are cut; a dead band is left on the right. 390/430 are pixel-correct.
- **Failing tests:** `P01 welcome — bug regressions … no crop at {320,360}dp`
  (`welcome_view_test.dart`, existing) and
  `BUG-1 scene paints in full at 320dp` (`p01_bugs_test.dart`, new).
- **Suggested fix (P01-owned):** lay the `Stack` out at its full 350×388
  design size and scale only the paint — wrap the inner `SizedBox` in
  `OverflowBox(minWidth: 350, maxWidth: 350, minHeight: 388, maxHeight: 388,
  alignment: Alignment.topLeft)` (or `FittedBox(fit: BoxFit.scaleDown)`)
  before `Transform.scale`. `scale == 1` keeps 390/430 byte-identical.

## BUG-2 — MAJOR: system bottom inset is counted twice (CTA sits 34dp high)

- **Severity:** major — designer-visible on every device with a home
  indicator; matches the Stage-5 screenshot drift (primary top 623.3 vs design
  656.7 = 33.4px).
- **Where (shared):** `NestBottomCta` wraps its content in
  `SafeArea(top: false)` (`app/lib/core/design_system/components/nest_bottom_cta.dart:17-27`)
  while P01 already renders a 34dp `NestHomeIndicator`
  (`welcome_view.dart:55`). The OS inset is consumed once by the SafeArea and
  again by the home-indicator reserve.
- **Repro:** pump `/welcome` with a 34dp system bottom inset
  (`tester.view.padding = FakeViewPadding(bottom: 34*3)`): primary button top
  604.0 vs 638.0 baseline (test-font baseline, +18 vs design); CTA box grows
  189→223 — exactly the 34dp inset. On the Stage-5 simulator this is the
  656.7→623.3 shift.
- **Failing test:** `BUG-2 system bottom inset is added twice`.
- **Suggested fix (shared, SHARED_REQUEST):** count the inset exactly once.
  Precedent: the new `NestStatusBar` reserves
  `max(viewPadding.top, 47)`. Do the same at the bottom — let
  `NestHomeIndicator` reserve `max(viewPadding.bottom, 34)` (and keep drawing
  the pill only when no real inset), and drop the `SafeArea` from
  `NestBottomCta` (or gate it behind a `safeBottom: false` flag used when a
  home indicator follows). With inset 0 the 390dp layout must stay unchanged.

## BUG-3 — MAJOR: kid mode can open /welcome and walk the parent flow

- **Severity:** major — parental-gate bypass. P01 is parent mode
  (screen brief) and the gate is the only guard against kid-mode entry to
  parent surfaces.
- **Where (shared):** `app/lib/app/router.dart:96-112` — the `parentOnly` list
  does not contain `/welcome`, `/value-tour`, `/create-account`, `/privacy`,
  `/add-children` or `/pocket-money-setup`, so the kid-mode redirect never
  fires for them.
- **Repro:** with `AppModeController.mode = kid` + `app_state.appMode='kid'`,
  pump `/welcome` → stays on `/welcome` (expected `/parental-gate`); tapping
  **Get started** → `/value-tour` (expected the gate). The walk continues
  until `/paywall`.
- **Failing tests:** `BUG-3 kid mode opens /welcome without the parental
  gate`, `BUG-3b kid mode can tap Get started into /value-tour`.
- **Suggested fix (shared, SHARED_REQUEST):** include the onboarding/auth/
  setup routes in the guarded set (or invert the rule: in kid mode only kid
  routes are allowed). A fresh install starts in parent mode, so gating
  `/welcome` cannot strand a legitimate kid session.

## BUG-4 — MAJOR: fresh install never persists onboarding completion (restart loop)

- **Severity:** major / product-blocking — on a release first launch the user
  can never leave onboarding; after every restart the router sends them back
  to `/welcome`. This is the "state after app restart (Drift persistence)"
  case.
- **Where (shared):** `AppState` row 1 is inserted **only** by `Seed.demo/
  empty/fresh` (`app/lib/core/data/seed.dart`). In release there is no
  `SEED` flag (`app/lib/app/launch_flags.dart`), so the table is empty;
  `AppSession._write` (`app/lib/core/data/app_session.dart:61-65`),
  `OnboardingRepositoryImpl.completeOnboarding`
  (`onboarding_repository_impl.dart:24-28`) and `PaywallRepositoryImpl`
  all only `UPDATE … WHERE id = 1` → 0 rows affected, silently.
- **Repro:** `configureDependencies(database: AppDatabase.memory())` with no
  seed, `session.refresh()` → `onboardingComplete == false` and the `app_state`
  select is empty; `completeOnboarding()` then `refresh()` → still `false`.
- **Failing test:** `BUG-4 fresh install never persists onboarding
  completion`.
- **Suggested fix (shared, SHARED_REQUEST):** guarantee the singleton row at
  open time (Drift `MigrationStrategy.beforeOpen` insert-if-missing, or an
  insert-if-missing bootstrap in `configureDependencies`). Upserting in
  `AppSession._write` alone is not enough because
  `OnboardingRepositoryImpl`/`PaywallRepositoryImpl` write directly.

## BUG-5 — MINOR: scene `Stack` clips the floating coins' `--sh-1` shadow

- **Severity:** minor (cosmetic; most visible in dark mode where `sh-1` is
  `black@40%`).
- **Where:** `welcome_view.dart:103` — `Stack` uses the default
  `Clip.hardEdge`; the HTML `.scene` has no `overflow: hidden`
  (`design/html-source/screens/P01-welcome.html:15`), so the shadow paints
  outside the frame. Rotated coins: `c3` (36px @22°) reaches x≈1.6 and its
  8px-blur shadow x≈−2.4; `c2` (34px @16°) reaches x≈347/351 — 1–4px cut.
- **Repro:** `expect(sceneStack.clipBehavior, Clip.none)` fails
  (actual `Clip.hardEdge`).
- **Failing test:** `BUG-5 scene Stack clips the coins --sh-1 shadow`.
- **Suggested fix (P01-owned):** `Stack(clipBehavior: Clip.none, …)` (after
  BUG-1; the crop comes from layout, not the clip). Fix BUG-1 first so this
  does not mask it.

---

## Verified sound (probed, no bug)

| Area | Probe | Result |
|---|---|---|
| Rapid double tap | two `tap`s on Get started, no pump between | single `/value-tour`, no exception |
| Async gap / emit after close | `OnboardingBloc` closed while `watchItems` load pending | subscription cancelled cleanly, no unhandled error |
| Dark-mode contrast | token pairs, WCAG 2.x formula | headline 16.30:1 · body 10.84:1 · caption 9.82:1 · primary 8.43:1 · ghost 14.76:1 — all ≥4.5 |
| Light-mode contrast | same | headline 15.45:1 · body 8.31:1 · caption 8.87:1 · primary 4.96:1 |
| Text scale 1.3 + 320dp | caption/ghost `didExceedMaxLines`, overflow exceptions | no ellipsis, no RenderFlex overflow (clamp 1.0–1.3 in `app.dart` works) |
| Data edge cases (0/1/6 children, "Maximilian-Alexander", 9999 coins, £999.99 goal, empty list) | seeded 6 children/extremes, pumped P01 | screen byte-identical; P01 reads no child/money data (only the static 3-item tour list); empty/`failure` states covered by stage-3 tests |
| Timezone / money rounding | P01 renders no dates or money | N/A by construction |
| Back navigation | `go` to `/value-tour` replaces the root stack; no back affordance | matches P02 design (Skip only, no back chevron) — noted, not filed |
| Onboarded deep link to `/welcome` | `Seed.demo` + pump `/welcome` | stays on `/welcome`; the redirect contract only forces *incomplete* installs to it, and "I already have an account" implies returning users may see it — INFO only, not filed |

## Process findings (not product bugs, but iteration 2 must handle)

0. **Stale test after the mid-stage shared merge** — `9ad2703` makes
   `NestStatusBar` reserve height without drawing the mock clock; the OS draws
   the real one (orchestrator note: "status-bar differences are harness
   artefacts — ignore"). `welcome_view_test.dart:133` still asserts
   `find.text('9:41')`, so that test is now red for a reason unrelated to
   P01's code. Update it to the new contract (the a11y assertion at :433
   already matches). This is the third red test above.
1. **Mandatory orchestrator change not yet applied** —
   `docs/screens/P01/ORCHESTRATOR_NOTES.md` requires P01 to render
   `PipAvatar(style: mochi, skin: sunny, stage: 2)` (idle, still frame under
   `DISABLE_ANIMATIONS`/reduced motion) in the same 168×168 @ (91,120) slot.
   `welcome_view.dart` still draws `SvgPicture.asset(pipStage2)`; the
   iteration-2 build must swap it. (The stage-3 test asserting the SVG alt
   text must move with it.)
2. **Stale `SHARED_REQUEST.md` replaced** — the old file asked the
   orchestrator to change `router_redirect_test.dart` for a failure that does
   not exist (stage 4 already flagged this). It now lists the three real
   shared requests (BUG-2, BUG-3, BUG-4).

## Summary

| # | Severity | Owner | Status |
|---|---|---|---|
| BUG-1 | blocker | P01 (`welcome_view.dart`) | open, 2 existing tests red |
| BUG-2 | major | shared (`NestBottomCta`) | open, proof skipped |
| BUG-3 | major | shared (`router.dart`) | open, 2 proofs skipped |
| BUG-4 | major | shared (`AppSession`/bootstrap) | open, proof skipped |
| BUG-5 | minor | P01 (`welcome_view.dart`) | open, proof skipped |
| — | info | P01 test file | stale `9:41` assertion from shared merge |

Major bugs remain open → this stage cannot pass.

VERDICT: FAIL
