// Pip lab — small control rows shared by [PipLabView].
//
// Design-system components only (NestChip, NestCard), light/dark aware
// through tokens. The view owns all state; these are pure views.

import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipMood;
import 'package:nestling/core/design_system/motion/pip_avatar.dart';

/// One chip per mood. Keys are `piplab-mood-<name>` so widget tests can tap
/// them without colliding with the status caption, which also names moods.
class PipLabMoodChips extends StatelessWidget {
  const PipLabMoodChips({
    required this.mood,
    required this.onChanged,
    super.key,
  });

  final PipMood mood;
  final ValueChanged<PipMood> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in PipMood.values)
          NestChip(
            key: ValueKey('piplab-mood-${value.name}'),
            label: value.name,
            selected: value == mood,
            onSelected: (_) => onChanged(value),
          ),
      ],
    );
  }
}

/// One swatch chip per skin, with a colour dot leading the label.
class PipLabSkinSwatches extends StatelessWidget {
  const PipLabSkinSwatches({
    required this.skin,
    required this.onChanged,
    super.key,
  });

  final PipSkin skin;
  final ValueChanged<PipSkin> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in PipSkin.values)
          NestChip(
            key: ValueKey('piplab-skin-${value.name}'),
            label: value.name,
            selected: value == skin,
            leading: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value.body,
                border: Border.all(color: const Color(0xFF1E1B3A), width: 1.5),
              ),
            ),
            onSelected: (_) => onChanged(value),
          ),
      ],
    );
  }
}

/// One chip per accessory, including `none`.
class PipLabAccessoryChips extends StatelessWidget {
  const PipLabAccessoryChips({
    required this.accessory,
    required this.onChanged,
    super.key,
  });

  final PipAccessory accessory;
  final ValueChanged<PipAccessory> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in PipAccessory.values)
          NestChip(
            key: ValueKey('piplab-acc-${value.name}'),
            label: value.name,
            selected: value == accessory,
            onSelected: (_) => onChanged(value),
          ),
      ],
    );
  }
}

/// Picker preview: the three body styles side by side at 64 px, the way the
/// kid sees them when choosing their Pip. Tapping one selects the style.
/// The current style gets a leaf ring; everything else is the shared
/// [PipAvatar], so this row also proves one widget drives all three files.
class PipLabPickerPreview extends StatelessWidget {
  const PipLabPickerPreview({
    required this.style,
    required this.stage,
    required this.skin,
    required this.riveEnabled,
    required this.onSelected,
    super.key,
  });

  final PipStyle style;
  final int stage;
  final PipSkin skin;
  final bool riveEnabled;
  final ValueChanged<PipStyle> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return NestCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final value in PipStyle.values)
            Semantics(
              button: true,
              selected: value == style,
              label: 'Choose ${value.name}',
              child: GestureDetector(
                key: ValueKey('piplab-preview-${value.name}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(value),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: value == style ? tokens.leaf : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: PipAvatar(
                    style: value,
                    stage: stage,
                    skin: skin,
                    size: 64,
                    riveEnabled: riveEnabled,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
