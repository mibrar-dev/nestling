# Shared backlog (do after all screens are merged)
- NestSegmented with 6 options at 320 dp shrinks each option below the 44 px tap target (P12-BUG-04, proof skipped in app/test/features/pocket_money/p12_bugs_test.dart; see docs/screens/P12/SHARED_REQUEST.md).
- Parent-tab page title (`.ptitle`) is re-implemented privately in 4+ screens. Extract a shared NestPageTitle and migrate the screens (P12 review finding 6).
