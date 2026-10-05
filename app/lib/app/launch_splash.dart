// Nestling — in-app launch splash: Pip hatching from the egg.
//
// Cold start shows the native splash first (leaf green + centred egg), then
// this widget continues on the same green with the egg at the same apparent
// size (256 dp, centred) so the hand-off does not jump. The hatch plays with
// the existing v2 Rive Pip (mochi/sunny): stage 1 egg, then the existing
// `evolve` trigger advances to the stage 2 hatchling, a brief hold, and a
// ≤ 200 ms cross-fade into the router. A hard timeout guarantees the splash
// can never hang, even if Rive never binds.
//
// Owner rules: total animated part ≤ 1.6 s, tap anywhere skips, Reduce Motion
// (`MediaQuery.disableAnimations` or `DISABLE_ANIMATIONS`) shows the
// hatchling still for ≤ 300 ms with no motion, and the splash appears only on
// a real cold start (see [shouldShowLaunchSplash] and the gate in `app.dart`).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nestling/core/data/env_flags.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';

/// Background green, identical to the native splash (the app icon background,
/// `design/flutter-asset-pack/assets/brand/app_icon_background.svg`).
///
/// Deliberately NOT the theme `leaf` token: dark-mode leaf is a lighter green
/// and would flash against the native splash. Both native modes use this same
/// green, so this widget does too.
const Color kLaunchSplashBackground = Color(0xFF17804F);

/// Apparent size of the native splash egg: `flutter_native_splash` emits the
/// 1024 px art at 256/512/768 px per scale, so iOS centres it at 256 pt on
/// every display. Same size and centre here means no jump at hand-off.
const double kLaunchSplashEggSize = 256;

/// Visible-art scale for the stage-2 hatchling: the Rive Stage2 artboard draws
/// Pip smaller than the Stage1 egg (measured release-playback video frames at
/// 1170 px wide: egg art 571 px tall, hatchling art 478 px tall ≈ 1.19×),
/// while the SVG fallbacks are closer (627 px vs 567 px at 768 px ≈ 1.11×).
/// 1.15 keeps both paths within ±5 % of the egg's visible art height, so Pip
/// no longer shrinks when it hatches.
const double kLaunchSplashHatchlingScale = 1.15;

/// Upward nudge (dp) applied to the hatchling so its art centre coincides with
/// the egg's: the egg art sits ~13 px above the box centre on a 1170-wide
/// capture (≈ 4 dp) while the hatchling art is box-centred.
const double kLaunchSplashHatchlingLift = 4;

/// Splash timings. [total] is the hard ceiling: the splash always calls
/// [LaunchSplash.onDone] by then, whether Rive bound or not.
abstract final class LaunchSplashTimings {
  /// Delay after the first frame before firing `evolve` (lets Rive bind).
  static const Duration evolveDelay = Duration(milliseconds: 450);

  /// Cross-fade into the router at the end of the animated path.
  static const Duration fade = Duration(milliseconds: 200);

  /// Hard ceiling from the first frame to [LaunchSplash.onDone].
  static const Duration total = Duration(milliseconds: 1600);

  /// Still hold on the Reduce Motion path (hatchling, no motion).
  static const Duration stillHold = Duration(milliseconds: 300);
}

/// Whether a real cold start should show the splash.
///
/// Compile-time `LaunchFlags` cannot vary per test, so the matrix lives here
/// as a pure function: the splash shows only when it was not skipped AND no
/// initial route was forced. Callers pass `LaunchFlags.skipSplash` and
/// `initialRoute != null`.
bool shouldShowLaunchSplash({
  required bool skipSplash,
  required bool hasInitialRoute,
}) => !skipSplash && !hasInitialRoute;

/// In-app launch splash. Calls [onDone] exactly once: after the hatch, on
/// tap-anywhere skip, on the Reduce Motion still hold, or on the hard
/// timeout — whichever comes first.
class LaunchSplash extends StatefulWidget {
  const LaunchSplash({
    required this.onDone,
    super.key,
    this.riveEnabled = true,
  });

  /// Called exactly once when the splash should leave the screen.
  final VoidCallback onDone;

  /// Set false to force the static SVG even when the `.riv` is present.
  /// Passed through to [PipAvatar]; tests use it for a deterministic still.
  final bool riveEnabled;

  @override
  State<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<LaunchSplash> {
  late final PipAvatarController _pip = PipAvatarController.detached();

  Timer? _evolveTimer;
  Timer? _fadeTimer;
  Timer? _doneTimer;
  bool _scheduled = false;
  bool _reduce = false;
  bool _done = false;
  bool _fading = false;
  int _stage = 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_scheduled) return;
    _scheduled = true;
    _reduce =
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        kDisableAnimations;
    if (_reduce) {
      // No hatch, no motion: the hatchling still, then straight on.
      _stage = 2;
      _doneTimer = Timer(LaunchSplashTimings.stillHold, _finish);
    } else {
      _evolveTimer = Timer(LaunchSplashTimings.evolveDelay, _evolve);
      _fadeTimer = Timer(
        LaunchSplashTimings.total - LaunchSplashTimings.fade,
        () {
          if (mounted && !_done) setState(() => _fading = true);
        },
      );
      // Hard timeout: fires even if Rive never bound and `evolve` landed
      // nowhere (`playEvolve` on a detached controller is a silent no-op).
      _doneTimer = Timer(LaunchSplashTimings.total, _finish);
    }
  }

  void _evolve() {
    if (!mounted || _done) return;
    _pip.playEvolve();
    setState(() => _stage = 2);
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _evolveTimer?.cancel();
    _fadeTimer?.cancel();
    _doneTimer?.cancel();
    widget.onDone();
  }

  @override
  void dispose() {
    _evolveTimer?.cancel();
    _fadeTimer?.cancel();
    _doneTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // mochi/sunny: sunny is PipAvatar's default skin (the drawn palette).
    // The hatchling box is scaled so its visible art height matches the
    // egg's (±5 %); the box stays centred and the lift aligns the art
    // centres (see [kLaunchSplashHatchlingScale]).
    final isEgg = _stage == 1;
    final pip = PipAvatar(
      style: PipStyle.mochi,
      stage: _stage,
      size: isEgg
          ? kLaunchSplashEggSize
          : kLaunchSplashEggSize * kLaunchSplashHatchlingScale,
      controller: _pip,
      riveEnabled: widget.riveEnabled,
    );
    final art = isEgg
        ? pip
        : Transform.translate(
            offset: const Offset(0, -kLaunchSplashHatchlingLift),
            child: pip,
          );
    // One labelled node for the whole splash: `excludeSemantics` collapses
    // the visual tree (the egg is decorative here) and `onTap` exposes the
    // skip as SemanticsAction.tap. No FocusNode anywhere, so focus can never
    // be trapped on this screen.
    return Semantics(
      label: 'Nestling',
      onTap: _finish,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _finish,
        behavior: HitTestBehavior.opaque,
        child: ColoredBox(
          color: kLaunchSplashBackground,
          child: SizedBox.expand(
            child: Center(
              child: AnimatedOpacity(
                opacity: _fading && !_reduce ? 0 : 1,
                duration: LaunchSplashTimings.fade,
                child: art,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
