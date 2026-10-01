// Motion lab — the Rive Pip rig.
//
// Everything here is a view model property of `pip.riv` (see
// `docs/animation/RIVE_GUIDE.md` and `core/design_system/motion/pip_rive.dart`):
// `mood` and `stage` are numbers, `evolve` and `tap` are triggers. The panel
// writes the two numbers; [triggers] is handed a context *below* the [PipRive]
// so it can fire the two triggers through `PipRive.of`.

import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// Pip, large, with every stage, mood and trigger the rig exposes.
class MotionLabPipPanel extends StatelessWidget {
  const MotionLabPipPanel({
    required this.stage,
    required this.mood,
    required this.motionEnabled,
    required this.riveEnabled,
    required this.onStageChanged,
    required this.onMoodChanged,
    required this.triggers,
    super.key,
  });

  /// Artboard to show: PipEgg … PipSongbird.
  final PipStage stage;

  /// State machine mood.
  final PipMood mood;

  /// False under reduced motion, when the widget is already on its SVG path.
  final bool motionEnabled;

  /// Forwarded to [PipRive.riveEnabled].
  final bool riveEnabled;

  /// Receives the 1-based stage number.
  final ValueChanged<int> onStageChanged;

  final ValueChanged<PipMood> onMoodChanged;

  /// Built with a [BuildContext] below the [PipRive], so `PipRive.of(context)`
  /// resolves. The lab supplies Evolve and Tap from there.
  final Widget Function(BuildContext pipContext) triggers;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Builder(
            builder: (pipContext) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: PipRive(
                    stage: stage,
                    mood: mood,
                    size: 240,
                    riveEnabled: riveEnabled,
                    onTap: () => PipRive.of(pipContext)?.poke(),
                  ),
                ),
                const SizedBox(height: NestSpacing.s2),
                Text(
                  'Stage ${stage.stage} · ${_pretty(stage.name)} · '
                  'mood ${mood.name} (${mood.value.toInt()})',
                  style: context.nestText.bodySmallStrong,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'artboard ${stage.artboard} · machine Pip · '
                  'svg ${stage.fallbackAsset.split('/').last}',
                  style: context.nestText.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: NestSpacing.s3),
                NestSegmented<int>(
                  semanticLabel: 'Growth stage',
                  value: stage.stage,
                  onChanged: onStageChanged,
                  options: <NestSegmentOption<int>>[
                    for (final value in PipStage.values)
                      NestSegmentOption<int>(
                        value: value.stage,
                        label: '${value.stage}',
                      ),
                  ],
                ),
                const SizedBox(height: NestSpacing.s3),
                Row(
                  children: [
                    for (var i = 0; i < PipMood.values.length; i++) ...[
                      if (i > 0) const SizedBox(width: NestSpacing.s1),
                      Expanded(
                        child: _MoodButton(
                          mood: PipMood.values[i],
                          selected: PipMood.values[i] == mood,
                          onPressed: () => onMoodChanged(PipMood.values[i]),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: NestSpacing.s3),
                triggers(pipContext),
              ],
            ),
          ),
          if (!motionEnabled) ...[
            const SizedBox(height: NestSpacing.s2),
            Text(
              'Reduced motion is on, so Pip is on its static SVG. Evolve and '
              'Tap are the two triggers the rig exposes; both are suppressed '
              'for the same reason.',
              style: context.nestText.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.mood,
    required this.selected,
    required this.onPressed,
  });

  final PipMood mood;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return NestButton(
      label: mood.name,
      variant: selected
          ? NestButtonVariant.primary
          : NestButtonVariant.secondary,
      onPressed: onPressed,
      fullWidth: false,
      minHeight: NestDevice.tapParent,
      fontSize: 15,
      horizontalPadding: NestSpacing.s2,
    );
  }
}

String _pretty(String value) =>
    '${value.substring(0, 1).toUpperCase()}${value.substring(1)}';
