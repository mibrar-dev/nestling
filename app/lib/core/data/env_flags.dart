// Nestling — compile-time environment flags readable from core.
//
// The same `--dart-define` values as `app/launch_flags.dart`, exposed here
// (without importing app-layer code) so design-system widgets can honour
// `DISABLE_ANIMATIONS` at compile time: Rive/Lottie render their still
// frame and implicit animations are skipped.

/// `true` when launched with `--dart-define=DISABLE_ANIMATIONS=1` (or
/// `=true`). `bool.fromEnvironment` only maps the string `'true'`, so the
/// `=1` form `tools/screens/shot.sh` always passes needs the explicit
/// string comparison (P08 §6, K03 #5: without it every Rive screen takes
/// the live path during screenshot runs and the frame never stabilises).
const bool kDisableAnimations =
    bool.fromEnvironment('DISABLE_ANIMATIONS') ||
    String.fromEnvironment('DISABLE_ANIMATIONS') == '1';
