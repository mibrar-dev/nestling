# Splash report — shared/splash (Pip hatching launch splash)

## Design decisions

- Native background `#17804F`: exact hex from
  `design/flutter-asset-pack/assets/brand/app_icon_background.svg`
  (`<path fill="#17804F" …/>`). Same green for iOS light + dark (dark uses the
  same green, verified pixel `(23, 128, 79)` in both `background.png` and
  `darkbackground.png`).
- Egg art: `app/assets/brand/splash_egg.png` (1024x1024 transparent) rasterised
  from the approved `PipAvatar` mochi/sunny stage-1 fallback
  (`app/assets/illustrations/pip_v2/mochi/s1_idle_1.svg`) via committed
  `tools/brand/render_splash_egg.py` (cairosvg). Same art, no redraw; sunny is
  the drawn palette so no recolour was applied.
- In-app splash (`app/lib/app/launch_splash.dart`, app shell, not a feature):
  `kLaunchSplashBackground = Color(0xFF17804F)` hard-coded (deliberately NOT
  the theme `leaf` token — dark-mode leaf is lighter and would flash against
  the native splash), egg at 256 dp centred (`kLaunchSplashEggSize`), matching
  the native storyboard (`flutter_native_splash` emits 256/512/768 px per
  scale, so iOS centres the egg at 256 pt; verified seamless, no jump).
- Hatch: `PipAvatar` mochi/sunny, stage 1 egg, existing `evolve` trigger fires
  at 450 ms (lets Rive bind), stage 2 hatchling holds, 200 ms cross-fade into
  the router. Hard timeout at 1600 ms fires regardless (`playEvolve` on a
  detached controller is a silent no-op), so the splash can never hang.
- Reduce Motion (`MediaQuery.disableAnimations` or `DISABLE_ANIMATIONS`):
  hatchling still for 300 ms, no fade, no motion.
- Semantics: single `Semantics(label: 'Nestling', onTap:, excludeSemantics:)`
  node — the blessed pattern from `semantics_actions_test.dart`. No
  FocusNode anywhere, so focus cannot be trapped.
- Wiring: gate in `NestlingApp` overlays `LaunchSplash` above the router's
  first screen (router + redirect guard run normally underneath); decided once
  per process, so resume never replays it. `LaunchFlags.skipSplash` is on when
  `SKIP_SPLASH=1` OR `INITIAL_ROUTE` is set, so `shot.sh` and widget tests
  (which always force a route) boot straight through. No feature code touched.
- `simctl ui` on this Xcode has no reduce-motion switch (only
  appearance/increase_contrast/content_size), so the still video was recorded
  with `DISABLE_ANIMATIONS=1`, which takes the identical code path
  (`kDisableAnimations` ⇒ same still branch as OS Reduce Motion).

## Timings measured

- Widget tests (fake async): `onDone` at exactly 1600 ms (0 at 1599 ms, once
  at 1600 ms, still once after +2 s); still path `onDone` at exactly 300 ms.
- Simulator iPhone 16e (604697A9): cold start → green/egg ≈ 0.5 s native,
  in-app hatch ≈ 1.6 s, gallery landed ≈ 2 s after first frame (see videos).

## Files changed

- `app/pubspec.yaml` (+`lock`): `flutter_native_splash: ^2.4.8` dev_dep + config
  (green both modes, egg image, Android 12 icon-on-green, `web: false`).
- `app/assets/brand/splash_egg.png`: generated egg (committed).
- `tools/brand/render_splash_egg.py`: egg render script (committed, re-runnable).
- `tools/screens/record_splash.sh`: non-interactive cold-start recorder
  (committed; fixed recordVideo stop to verify + escalate INT→TERM→KILL).
- `app/lib/app/launch_flags.dart`: `skipSplashRequested` + `skipSplash`.
- `app/lib/app/launch_splash.dart`: new splash widget + timings + gate helper.
- `app/lib/app/app.dart`: cold-start gate overlaying the router.
- `app/test/app/launch_splash_test.dart`: 13 new tests (see below).
- `app/test/design_system/theme_shell_test.dart`: gallery test now boots with
  explicit `initialRoute: '/design-system'` (same location; splash overlay
  would otherwise intercept its toggle tap).
- Generated native splash: `ios/Runner/{Base.lproj/LaunchScreen.storyboard,
  Info.plist, Assets.xcassets/Launch{Image,Background}.imageset/*}`,
  `android/app/src/main/res/{drawable*,values*,…}` (+`values-v31` Android 12).
- Videos/frames: `docs/brand/splash_hatch.mp4` (5.9 s cold start),
  `docs/brand/splash_reduce_motion.mp4` (2.5 s still path),
  `docs/brand/splash_frames.png` (5-frame strip: launch, egg, hatchling,
  landing x2; hatchling frame is a genuine capture from the same launch).

## Test names added (`app/test/app/launch_splash_test.dart`, 13 tests)

- shouldShowLaunchSplash: plain cold start shows; SKIP_SPLASH hides; forced
  initial route hides (x2); `LaunchFlags.skipSplash` defaults off in tests.
- Animated: finishes by 1.6 s exactly-once; egg→hatchling stills;
  tap-anywhere skips; single labelled node with tap action (semantic tap
  drives the real skip); native-splash green; hard timeout with Rive never
  bound.
- Reduce Motion: hatchling still from first frame, done within 300 ms.
- Wiring: forced route skips splash (`currentPath` asserted, no placeholder
  text); bare cold start shows splash then router at `/design-system`.

## Results

- `dart format .` clean; `flutter analyze` → No issues found!
- `flutter test --timeout 120s` (foreground): All tests passed
  (5061 passed, 16 skipped, 0 failed).

## Follow-ups for screen agents

- None required. If a widget test pumps bare `NestlingApp()` (no
  `initialRoute`) AND taps through the first 1.6 s, boot with an explicit
  `initialRoute` instead (same location) — the splash overlay eats taps while
  up. `pumpAppRoute` and `shot.sh` already force routes, so they are
  unaffected. Never `find.text` on splash art; the only semantic is "Nestling".

VERDICT: PASS
