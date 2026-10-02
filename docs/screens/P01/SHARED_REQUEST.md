# Shared request — P01 Welcome (Stage 6, iteration 2)

Supersedes the stale request about `router_redirect_test.dart` (that test
passes — route-location based since `2f723db`).

**Closed on main, verified here** (proofs un-skipped and passing in
`app/test/features/onboarding/p01_bugs_test.dart`):

- BUG-2 bottom inset counted twice — fixed by `763192d`
  (`NestHomeIndicator` is a no-op in the app; `NestBottomCta`'s `SafeArea`
  owns the OS inset exactly once). The proof now asserts the shipped contract
  (`insetTop == baselineTop − 34`), not the pre-fix inverse.
- BUG-3 kid-mode gate skipped the onboarding flow — fixed by `71d2400`
  (onboarding locations are parent-only).
- BUG-1 / BUG-5 (P01-owned scene scale + coin shadow clip) — fixed in
  `welcome_view.dart`.

**Need (one remaining shared defect, BUG-4):**

**Fresh install never creates the `app_state` row.** `AppSession._write`
upserts now (`763192d`), but the feature repositories still write directly:
`features/onboarding/data/onboarding_repository_impl.dart:24-28`
(`completeOnboarding`) and `features/paywall/data/paywall_repository_impl.dart`
(`startTrial` / `activate`) do `UPDATE … WHERE id = 1` with no
insert-if-missing, and nothing bootstraps row 1 when the DB opens. On a
release first launch (no `SEED` flag) the update affects 0 rows, so onboarding
completion is never persisted and every restart returns the user to
`/welcome` — the screen loops forever.

Fix (either): insert-if-missing in `MigrationStrategy.beforeOpen` (preferred —
covers every writer at once), or an upsert in each repository. Whoever lands it
must un-skip and pass the `BUG-4` proof in
`app/test/features/onboarding/p01_bugs_test.dart`.

**Files:** `app/lib/core/data/app_database.dart` (beforeOpen) ·
`app/lib/features/onboarding/data/onboarding_repository_impl.dart` ·
`app/lib/features/paywall/data/paywall_repository_impl.dart`.

**Blocks:** **no** for P01's visual landing (the P01-owned bugs BUG-1/BUG-5
are fixed). **Yes** for the product's first-launch onboarding persistence.

**Also open (non-blocking, from the review):** warm P01's five first-frame
SVGs at startup with `precachePicture` (nothing calls `NestlingImages.precache`,
and it lists the webp rasters) and bundle Inter + Nunito with
`GoogleFonts.config.allowRuntimeFetching = false` in `lib/main.dart` — fonts
currently come from the Google-Fonts CDN on first paint.
