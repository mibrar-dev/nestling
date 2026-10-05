TASK — real app start screen + splash hatchling size (shared/start_route)

PROBLEM (release blocker): `buildAppRouter` (app/lib/app/router.dart:72-78) defaults `initialLocation` to the design-system GALLERY. A real cold start of an onboarded family therefore lands on the internal gallery (seen in docs/brand/splash_frames.png). The gallery / motion lab / pip lab are developer tools.

1. Start screen: default `initialLocation` = `/` handled by the redirect (or compute directly):
   - not onboarded → `/welcome` (OnboardingRoutePaths.welcome) — the existing redirect already does this for any location;
   - onboarded + parent mode → `/today` (Today tab);
   - onboarded + kid mode → `/kid-home` (KidHomeRoutePaths.home);
   - keep the existing kid-mode gate and expired-trial rules exactly as they are (they run after this).
   Use route constants, never string literals scattered around. `INITIAL_ROUTE`, `MOTION_AUTOPLAY`, `PIP_LAB_AUTOPLAY` keep working.
2. Developer tools: the design-system gallery, motion lab and pip lab routes are registered ONLY in debug/profile builds (`kDebugMode || kProfileMode`) or when explicitly requested by a dart-define; in a release build they do not exist (a deep link to them goes to the start screen). Tests that use the gallery keep working (tests run in debug).
3. Splash (app/lib/app/launch_splash.dart): in docs/brand/splash_frames.png the hatchling frame is about half the visual height of the egg frame, so Pip visibly shrinks when it hatches. Size the hatchling so its visible art height matches the egg's visible art height (±5 %), same centre. Do not change the timings or the native splash.
4. Tests: router tests for each start case (not onboarded / parent / kid / expired trial kid → gate); a test that a release-mode router config has no gallery routes (inject the mode flag); splash test asserting egg vs hatchling visual height ratio within 0.95–1.05. Update any test that relied on the gallery being the default start (prefer giving such tests an explicit `initialRoute`).
5. `cd app && flutter analyze` (No issues found) and `flutter test --timeout 120s` in the FOREGROUND (all green). Re-record docs/brand/splash_hatch.mp4 + splash_frames.png on simulator 604697A9-11DA-462F-9837-396E9CA2493A ONLY with SEED=demo (parent, onboarded) so the video ends on Today. Commit. Write docs/screens/_shared/start_route_REPORT.md ending with `VERDICT: PASS` or `VERDICT: FAIL`.
