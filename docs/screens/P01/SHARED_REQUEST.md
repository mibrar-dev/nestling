# Shared request — P01 Welcome (Stage 6)

Supersedes the stale request about `router_redirect_test.dart` (that test
passes — routed to the route-location check in `2f723db`). Three real shared
defects surfaced by the P01 bug hunt; each has a skipped proof in
`app/test/features/onboarding/p01_bugs_test.dart`. Details and repro steps:
`docs/screens/P01/6_bugs.md` (BUG-2, BUG-3, BUG-4).

**Need:**

1. **Kid-mode gate skips the onboarding/auth routes.** The `parentOnly` list
   in `app/lib/app/router.dart:96-106` excludes `/welcome`, `/value-tour`,
   `/create-account`, `/privacy`, `/add-children` and `/pocket-money-setup`,
   so a kid-mode session can open P01 and walk the parent flow to `/paywall`
   without the gate. Add the onboarding/auth/setup paths (or invert to an
   allow-list of kid routes).
2. **Bottom inset counted twice.** `NestBottomCta` wraps its content in
   `SafeArea` while P01 also renders the 34dp `NestHomeIndicator`, so CTAs
   sit 34dp higher than the design on every home-indicator device
   (simulator: 623.3 vs 656.7). Let the home indicator reserve
   `max(viewPadding.bottom, 34)` (mirroring the new `NestStatusBar`) and stop
   the CTA from adding the inset again; keep 390dp parity when inset = 0.
3. **Fresh install never creates the `app_state` row.** Only `Seed` inserts
   row id = 1; `AppSession._write`, `OnboardingRepositoryImpl.completeOnboarding`
   and `PaywallRepositoryImpl` only UPDATE it. On a release first launch the
   update affects 0 rows, so onboarding completion is never persisted and
   every restart returns the user to `/welcome`. Insert-if-missing at DB open
   (`MigrationStrategy.beforeOpen` or the `configureDependencies` bootstrap).

**Files:** `app/lib/app/router.dart` (1) ·
`app/lib/core/design_system/components/nest_bottom_cta.dart` (2) ·
`app/lib/core/data/app_session.dart` + `app/lib/app/di.dart` (3).

**Blocks:** **no** for P01's visual landing (BUG-1/BUG-5 are P01-owned).
**Yes** for the product's onboarding persistence (3) and the parental-gate
contract (1); (2) is a cross-screen visual defect but P01's screenshots stay
acceptable until fixed.
