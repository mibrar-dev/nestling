// Motion lab — the Rive coin jar.
//
// The `Jar` artboard carries two view model properties: `fill` (0..1) and the
// `drop` trigger. `fill` is declarative and slides live; `drop` is a 1.6 s
// one-shot, fired imperatively through the handle [onController] hands the lab
// (a sibling context cannot use `PipJar.of` — see `PipRive.of`).

import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// The jar, a 0..1 fill slider, and the drop trigger.
class MotionLabJarPanel extends StatelessWidget {
  const MotionLabJarPanel({
    required this.fill,
    required this.motionEnabled,
    required this.riveEnabled,
    required this.onFillChanged,
    required this.onController,
    required this.onJarTap,
    required this.actions,
    super.key,
  });

  /// Coin level, 0..1.
  final double fill;

  /// False under reduced motion, when the widget is already on its SVG path.
  final bool motionEnabled;

  /// Forwarded to [PipJar.riveEnabled].
  final bool riveEnabled;

  final ValueChanged<double> onFillChanged;

  /// Receives the imperative handle once the [PipJar] binds it. The lab keeps
  /// it to fire Drop from its button, the demo and the autoplay.
  final ValueChanged<PipJarController> onController;

  /// Tapping the jar itself. The lab drops coins through its kept handle.
  final VoidCallback onJarTap;

  /// The Drop row, supplied by the lab (it owns the kept handle).
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: PipJar(
              fill: fill,
              size: 200,
              riveEnabled: riveEnabled,
              onReady: onController,
              onTap: onJarTap,
            ),
          ),
          const SizedBox(height: NestSpacing.s2),
          Text(
            'fill = ${fill.toStringAsFixed(2)}',
            style: context.nestText.bodySmallStrong,
            textAlign: TextAlign.center,
          ),
          Text(
            'artboard Jar · machine Jar · svg jar_coins.svg',
            style: context.nestText.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NestSpacing.s2),
          _FillSlider(
            value: fill,
            enabled: motionEnabled,
            onChanged: onFillChanged,
          ),
          const SizedBox(height: NestSpacing.s3),
          actions,
        ],
      ),
    );
  }
}

/// A 0..1 slider, themed from tokens.
///
/// The design system has no slider component, so this is the one place the lab
/// styles a Material control by hand rather than adding to the system: the
/// jar's fill is continuous and nothing else expresses it.
class _FillSlider extends StatelessWidget {
  const _FillSlider({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final double value;
  final bool enabled;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text('Fill 0.00', style: context.nestText.caption),
            const Spacer(),
            Text('1.00 Fill', style: context.nestText.caption),
          ],
        ),
        Opacity(
          opacity: enabled ? 1 : 0.45,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 10,
              activeTrackColor: tokens.coin,
              inactiveTrackColor: tokens.track,
              thumbColor: tokens.knob,
              overlayColor: tokens.leafTint,
              activeTickMarkColor: tokens.coinInk,
              inactiveTickMarkColor: tokens.line,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            ),
            child: Slider(
              value: value,
              divisions: 20,
              label: value.toStringAsFixed(2),
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ),
      ],
    );
  }
}
