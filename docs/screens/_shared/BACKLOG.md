# Shared backlog (do after all screens are merged)
- NestSegmented with 6 options at 320 dp shrinks each option below the 44 px tap target (P12-BUG-04, proof skipped in app/test/features/pocket_money/p12_bugs_test.dart; see docs/screens/P12/SHARED_REQUEST.md).
- Parent-tab page title (`.ptitle`) is re-implemented privately in 4+ screens. Extract a shared NestPageTitle and migrate the screens (P12 review finding 6).
- Repositories read the family id from the seed constant `Seed.familyId` (10+ feature repos). OK for local-only (one family per device), but before Supabase, expose the current family from AppSession and replace every `Seed.familyId` in app/lib/features with it.
- P15 family_repository_impl.dart:41 uses `Seed.anchorOverride?.toUtc() ?? DateTime.now()` in app code: replace with `clock.now()`/appNowUtc() (the test clock already pins the day); never read the seed test hook in product code.
- K03 still paints its own in-flow meadow band (kid_home_view.dart ~l.134-137, 550-599). Switch it to the shared kid_meadow when its next polish pass runs (see docs/screens/_shared/kid_meadow_REPORT.md).
