// Motion lab — one card per Lottie asset.
//
// The card is deliberately presentational: playback state (the loop flag, the
// controller, the reduced-motion flag) lives in the view, so the scripted demo
// can drive the same four animations the buttons drive.

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/design_system_gallery/presentation/widgets/motion_lab_assets.dart';

/// One asset at its natural size, with Play / Loop / Reset and the frame the
/// app would show when the OS has asked for reduced motion.
class MotionLabLottieCard extends StatelessWidget {
  const MotionLabLottieCard({
    required this.asset,
    required this.composition,
    required this.controller,
    required this.loop,
    required this.playEnabled,
    required this.onPlay,
    required this.onLoopChanged,
    required this.onReset,
    super.key,
  });

  /// The file this card shows.
  final MotionLabAsset asset;

  /// The parsed composition, or null while it is still loading.
  final LottieComposition? composition;

  /// Drives the animation. The view owns it, so the demo can share it.
  final AnimationController controller;

  /// Whether Play loops instead of running once.
  final bool loop;

  /// False under reduced motion, and the Play/Reset buttons go with it.
  final bool playEnabled;

  final VoidCallback onPlay;

  final ValueChanged<bool> onLoopChanged;

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final still = motionLabStillFrame(asset, composition);
    final meta = <String>[
      asset.sizeLabel,
      _durationLabel,
      'still f${still.toInt()}',
      if (asset.playsFullScreen) 'full-screen on play',
    ].join(' · ');

    return NestCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(asset.name, style: context.nestText.h3),
          const SizedBox(height: NestSpacing.gap2),
          Text(meta, style: context.nestText.caption),
          const SizedBox(height: NestSpacing.s3),
          Center(child: _stage(context)),
          const SizedBox(height: NestSpacing.s3),
          Row(
            children: [
              Expanded(
                child: NestButton(
                  label: 'Play',
                  onPressed: playEnabled ? onPlay : null,
                  fullWidth: false,
                  minHeight: NestDevice.tapParent,
                  fontSize: 15,
                  horizontalPadding: NestSpacing.s3,
                ),
              ),
              const SizedBox(width: NestSpacing.s2),
              Expanded(
                child: NestButton(
                  label: 'Loop',
                  leading: loop ? const Icon(Icons.repeat) : null,
                  variant: loop
                      ? NestButtonVariant.primary
                      : NestButtonVariant.secondary,
                  onPressed: playEnabled ? () => onLoopChanged(!loop) : null,
                  fullWidth: false,
                  minHeight: NestDevice.tapParent,
                  fontSize: 15,
                  horizontalPadding: NestSpacing.s3,
                ),
              ),
              const SizedBox(width: NestSpacing.s2),
              Expanded(
                child: NestButton(
                  label: 'Reset',
                  variant: NestButtonVariant.secondary,
                  onPressed: playEnabled ? onReset : null,
                  fullWidth: false,
                  minHeight: NestDevice.tapParent,
                  fontSize: 15,
                  horizontalPadding: NestSpacing.s3,
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpacing.s3),
          _StillPreview(
            asset: asset,
            composition: composition,
            borderColor: tokens.line,
          ),
        ],
      ),
    );
  }

  /// Duration as written, not as parsed: 600 ms, 2.50 s.
  String get _durationLabel {
    final ms = asset.duration.inMilliseconds;
    if (ms % 1000 == 0) return '${(ms / 1000).toStringAsFixed(2)} s';
    return '$ms ms';
  }

  Widget _stage(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final box = asset.displaySize;
        // Natural size, scaled down rather than overflowing on a screen
        // narrower than the 390pt the comps were authored for.
        final available = constraints.maxWidth;
        final scale = available.isFinite && available < box.width
            ? available / box.width
            : 1.0;
        return SizedBox(
          width: box.width * scale,
          height: box.height * scale,
          child: DecoratedBox(
            // The comps are transparent, so the card surface is the only thing
            // behind them; a hairline keeps their edges readable.
            decoration: BoxDecoration(
              color: context.nest.surface2,
              borderRadius: NestRadii.allM,
              border: Border.all(color: context.nest.line),
            ),
            child: Lottie(
              composition: composition,
              controller: controller,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}

/// The reduced-motion rendering, side by side with the live one.
///
/// `RawLottie` is a render object: no [Animation], no ticker, no state, so a
/// still frame costs nothing and cannot be animated by accident. The still
/// frame is deliberately *not* the last frame — coin_burst and confetti both
/// end empty (`LOTTIE.md` §3.2).
class _StillPreview extends StatelessWidget {
  const _StillPreview({
    required this.asset,
    required this.composition,
    required this.borderColor,
  });

  final MotionLabAsset asset;
  final LottieComposition? composition;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final frame = motionLabStillFrame(asset, composition);
    return NestCard(
      variant: NestCardVariant.inset,
      padding: const EdgeInsets.all(NestSpacing.s3),
      child: Row(
        children: [
          SizedBox.square(
            dimension: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: NestRadii.allS,
                border: Border.all(color: borderColor),
              ),
              child: RawLottie(
                composition: composition,
                progress: motionLabStillProgress(asset, composition),
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: NestSpacing.s3),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Reduced motion', style: context.nestText.bodySmallStrong),
                Text(
                  'Still frame ${frame.toInt()} — what the OS flag shows.',
                  style: context.nestText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
