// Motion lab — what the lab knows about the Lottie set before it parses it.
//
// One entry per file in `assets/animations/lottie/`. The numbers are the build
// outputs of `tools/lottie/build.js`, tabulated in `docs/animation/LOTTIE.md`
// §1 and §3.2, and they exist so a card can be laid out and labelled on the
// first frame. They are never the authority for the still frame: at runtime
// [motionLabStillProgress] reads the `still` marker the generator writes into
// every file, and only falls back to [MotionLabAsset.stillFrame] if a file ever
// loses it.

import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';

/// One Lottie one-shot, as the motion lab presents it.
@immutable
class MotionLabAsset {
  const MotionLabAsset({
    required this.name,
    required this.duration,
    required this.stillFrame,
    required this.compSize,
    this.previewSize,
    this.playsFullScreen = false,
  });

  /// File name without the extension, e.g. `check_tick`.
  final String name;

  /// Wall-clock length of the composition.
  final Duration duration;

  /// The `still` marker frame declared in the JSON. A fallback only.
  final int stillFrame;

  /// The composition's own box, in its authored units.
  final Size compSize;

  /// Box the lab paints it in. Defaults to [compSize]; overridden only where
  /// the natural box cannot fit a 390pt screen (confetti is 390 × 844).
  final Size? previewSize;

  /// Whether playing this asset also throws a full-screen overlay.
  final bool playsFullScreen;

  /// Asset path, relative to the app root.
  String get path => 'assets/animations/lottie/$name.json';

  /// The box the lab paints: the natural size unless it was capped.
  Size get displaySize => previewSize ?? compSize;

  /// `w × h` of the authored composition, for the meta line.
  String get sizeLabel =>
      '${compSize.width.toInt()} × ${compSize.height.toInt()}';

  /// Whether the lab had to shrink it to fit, so the card can say so.
  bool get isCapped => displaySize != compSize;
}

/// The four one-shots, in `LOTTIE.md` §1 order.
abstract final class MotionLabAssets {
  const new _();

  /// Duration of the gap between two steps of the scripted demo.
  static const Duration demoGap = Duration(milliseconds: 400);

  /// `confetti`, which is the only one that goes full-screen.
  static final MotionLabAsset confetti = byName('confetti');

  static const List<MotionLabAsset> all = <MotionLabAsset>[
    MotionLabAsset(
      name: 'check_tick',
      duration: Duration(milliseconds: 600),
      stillFrame: 32,
      compSize: Size(64, 64),
    ),
    MotionLabAsset(
      name: 'coin_burst',
      duration: Duration(milliseconds: 1000),
      stillFrame: 30,
      compSize: Size(260, 260),
    ),
    MotionLabAsset(
      name: 'confetti',
      duration: Duration(milliseconds: 2500),
      stillFrame: 75,
      compSize: Size(390, 844),
      // Full-bleed art in a 390pt card: contained to the height that fits.
      previewSize: Size(120, 240),
      playsFullScreen: true,
    ),
    MotionLabAsset(
      name: 'badge_unlock',
      duration: Duration(milliseconds: 900),
      stillFrame: 50,
      compSize: Size(260, 260),
    ),
  ];

  /// Looks an asset up by [name]. Falls back to the first entry so a typo in
  /// the demo script shows something rather than throwing inside a timer.
  static MotionLabAsset byName(String name) =>
      all.firstWhere((asset) => asset.name == name, orElse: () => all.first);
}

/// Progress 0..1 of the frame the reduced-motion still should hold.
///
/// Reads the `still` marker at runtime (`LOTTIE.md` §3.1) rather than trusting
/// [MotionLabAsset.stillFrame], then converts it the same way the runtime
/// converts a frame everywhere else:
///
/// ```dart
/// progress = (frame - composition.startFrame) / composition.durationFrames
/// ```
///
/// That matters — `RenderLottie` asserts progress is within 0..1, so handing it
/// a frame *number* (32) is an assert, not a still.
double motionLabStillProgress(
  MotionLabAsset asset,
  LottieComposition? composition,
) {
  final comp = composition;
  if (comp == null) return 0;
  final frames = comp.durationFrames;
  if (frames <= 0) return 0;
  final frame = comp.getMarker('still')?.startFrame ?? asset.stillFrame;
  return ((frame - comp.startFrame) / frames).clamp(0.0, 1.0);
}

/// The still frame number, for the label. Prefers the marker, falls back to the
/// documented literal.
double motionLabStillFrame(
  MotionLabAsset asset,
  LottieComposition? composition,
) => composition?.getMarker('still')?.startFrame ?? asset.stillFrame.toDouble();
