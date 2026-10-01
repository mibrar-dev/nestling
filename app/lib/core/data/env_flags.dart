// Nestling — compile-time environment flags readable from core.
//
// The same `--dart-define` values as `app/launch_flags.dart`, exposed here
// (without importing app-layer code) so design-system widgets can honour
// `DISABLE_ANIMATIONS` at compile time: Rive/Lottie render their still
// frame and implicit animations are skipped.

/// `1` when launched with `--dart-define=DISABLE_ANIMATIONS=1`.
const bool kDisableAnimations = bool.fromEnvironment('DISABLE_ANIMATIONS');
