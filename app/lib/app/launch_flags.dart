// Nestling — compile-time launch flags (debug + profile only).
//
// Passed with `--dart-define=KEY=value`. Used by developers, the screenshot
// harness (`tools/screens/shot.sh`) and the 30 screen agents to open any
// screen in a deterministic state:
//
//   SEED=demo|empty|fresh|onboarding_kids   reseed the database on launch when given
//   INITIAL_ROUTE=/today    jump straight to a route (see route constants)
//   APP_MODE=parent|kid     app mode at launch
//   THEME=light|dark|system theme at launch
//   CHILD=maya|leo          active child at launch
//   DISABLE_ANIMATIONS=1    still frames (Rive/Lottie/SVG), no motion

abstract final class LaunchFlags {
  static const String seed = String.fromEnvironment('SEED');
  static const String initialRoute = String.fromEnvironment('INITIAL_ROUTE');
  static const String appMode = String.fromEnvironment('APP_MODE');
  static const String theme = String.fromEnvironment('THEME');
  static const String child = String.fromEnvironment('CHILD');

  static const bool disableAnimations =
      bool.fromEnvironment('DISABLE_ANIMATIONS') ||
      String.fromEnvironment('DISABLE_ANIMATIONS') == '1';

  static bool get hasSeed => isSupportedSeed(seed);

  /// All `SEED=` values `applyLaunchFlags` understands (see `launch.dart`).
  /// Split out for tests: `seed` itself is compile-time, so widget/unit
  /// tests cannot set it per-case.
  static bool isSupportedSeed(String value) =>
      value == 'demo' ||
      value == 'empty' ||
      value == 'fresh' ||
      value == 'onboarding_kids';
}
