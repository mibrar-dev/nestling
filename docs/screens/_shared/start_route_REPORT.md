# Start-route report — shared/start_route (real app start screen + splash hatchling size)

## Problem

`buildAppRouter` defaulted `initialLocation` to the design-system gallery, so a
real cold start of an onboarded family landed on an internal developer tool
(visible as the last frames of the old `docs/brand/splash_frames.png`). The
gallery / motion lab / pip lab are developer tools. Separately, the splash
hatchling rendered visibly smaller than the egg, so Pip shrank when it hatched.

## Files changed

- `app/lib/app/router.dart`
  - Default `initialLocation` is now `/`, resolved by the redirect to the
    family's start screen via the new `_startLocation` helper (route
    constants only): not onboarded → `OnboardingRoutePaths.welcome`
    (the existing onboarding rule already sends any location there);
    onboarded parent → `TodayRoutePaths.today`; onboarded kid →
    `KidHomeRoutePaths.home`. The kid-mode gate and expired-trial rules below
    it are byte-for-byte unchanged and run on the redirected location.
  - `INITIAL_ROUTE`, `MOTION_AUTOPLAY`, `PIP_LAB_AUTOPLAY` keep working (the
    autoplay defines still boot straight into their lab).
  - Dev routes are registered only when `devRoutesEnabled`: `kDebugMode ||
    kProfileMode`, or `--dart-define=DEV_ROUTES=1` in release (a lab-autoplay
    define counts as an explicit request). New optional `includeDevRoutes`
    parameter lets tests inject the release configuration. In release a deep
    link to a dev location falls back to the start screen via the redirect
    instead of go_router's error page (verified: top-level redirect runs even
    for unmatched locations, `matchedLocation == uri.path` there).
- `app/lib/app/app.dart` — optional `includeDevRoutes` pass-through to
  `buildAppRouter` (default null = router default; only tests inject `false`).
- `app/lib/app/launch_splash.dart`
  - New `kLaunchSplashHatchlingScale = 1.15`: the hatchling box is
    `256 × 1.15`, same centre. Measured Rive video frames (1170 px wide):
    egg art 968–1538 (h 571, centre 1253), hatchling art 980–1529 (h 550,
    centre 1254.5) → chick/egg = 0.963, centres 1.5 px apart. SVG fallbacks
    (768 px): 627 vs 567 (≈ 1.11×) → 1.15 lands at 1.040 there. Both paths
    satisfy the ±5 % rule with one constant.
  - New `kLaunchSplashHatchlingLift = 4` dp upward nudge so the Rive art
    centres coincide (egg art sits ~13 px above the box centre; chick art is
    box-centred). Timings and the native splash untouched.
- `app/test/app/start_route_test.dart` — new (9 tests, see below).
- `app/test/app/launch_splash_test.dart` — bare cold start now expects
  `TodayRoutePaths.today` (Seed.demo = onboarded parent: this is the bug fix
  demonstrated); new pixel-level hatchling-size test.
- `app/test/widget_test.dart`, `app/test/design_system/theme_shell_test.dart`
  — comment-only updates (gallery is now reached via explicit route; bare boot
  lands on Today).
- `docs/ARCHITECTURE.md` — initial-route line updated (`/` → start screen;
  labs are debug/profile or `DEV_ROUTES=1`).
- `docs/brand/splash_hatch.mp4` — re-recorded on simulator
  604697A9-11DA-462F-9837-396E9CA2493A with SEED=demo (parent, onboarded),
  trimmed to the 5.9 s cold start; ends on Today.
- `docs/brand/splash_frames.png` — rebuilt 5-frame strip (launch, egg,
  hatchling, Today ×2) from the new video. Strip-pixel check: egg h 115,
  chick h 110 (ratio 1.045), centres 250 vs 250.5.

## Test names added

`app/test/app/start_route_test.dart` (cold start at `/`):

- not onboarded boots to welcome
- onboarded parent boots to Today
- onboarded kid boots to Kid Home
- expired trial kid boots to the parental gate
- expired trial parent boots to the paywall
- not onboarded kid boots to the parental gate

`app/test/app/start_route_test.dart` (developer-tool routes):

- release-mode router registers no gallery routes
- debug router keeps the gallery routes
- release deep link to the gallery lands on Today

`app/test/app/launch_splash_test.dart`:

- hatchling visual height matches the egg within ±5 % (renders the real
  `LaunchSplash` on its SVG fallback path, captures stage 1 vs stage 2 pixels
  via `RepaintBoundary.toImage`, asserts the non-background row-span ratio is
  within 0.95–1.05; bounded pumps, cannot hang).

All assertions are router locations (`currentPath`) or route-table paths —
no placeholder view text anywhere.

## Results

- `dart format .` clean; `flutter analyze` → No issues found!
- `flutter test --timeout 120s` in the foreground: All tests passed
  (final counter +5240 passed, ~16 skipped, 0 failed).

## Follow-ups for screen agents

- Nothing required to merge. `shot.sh` / `INITIAL_ROUTE` flows are unchanged;
  the gallery, motion lab and pip lab remain reachable in debug builds via an
  explicit route (e.g. `INITIAL_ROUTE=/design-system`), exactly as before.
- If a widget test pumps bare `NestlingApp()` (no `initialRoute`) and taps
  through the first 1.6 s, boot with an explicit `initialRoute` instead — the
  splash overlay eats taps while up, and the router underneath now lands on
  the start screen rather than the gallery.
- `docs/brand/splash_reduce_motion.mp4` is stale (still shows the small
  hatchling and a gallery landing); left alone — this task scoped the
  re-record to `splash_hatch.mp4` + `splash_frames.png`.
- Observed, not changed: a brief (~0.2–0.4 s) blank-green beat between the
  egg burst and the hatchling on device (Rive Stage1→Stage2 artboard swap;
  longer in the old recording, likely simulator stall). Timings were
  explicitly out of scope; candidate follow-up for the motion owner.
- Release builds needing the labs (QA): `--dart-define=DEV_ROUTES=1`
  (or either lab-autoplay define, which implies it).

VERDICT: PASS
