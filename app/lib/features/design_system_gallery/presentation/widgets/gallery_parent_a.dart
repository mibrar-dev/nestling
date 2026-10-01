import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// Parent components, part 1: buttons, cards, lists, chips, segmented,
/// toggles, steppers. Every state from `components.css` §2–3.
class GalleryParentA extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const NestSectionLabel(
          key: ValueKey('ds-section-buttons'),
          label: 'Buttons',
        ),
        const SizedBox(height: NestSpacing.s2),
        NestButton(label: 'Get started', onPressed: () {}),
        const SizedBox(height: NestSpacing.s3),
        NestButton(
          label: 'I already have an account',
          variant: NestButtonVariant.secondary,
          onPressed: () {},
        ),
        const SizedBox(height: NestSpacing.s3),
        Row(
          children: [
            Expanded(
              child: NestButton(
                label: 'Cancel',
                variant: NestButtonVariant.ghost,
                fullWidth: false,
                onPressed: () {},
              ),
            ),
            Expanded(
              child: NestButton(
                label: 'Remove Maya',
                variant: NestButtonVariant.dangerGhost,
                fullWidth: false,
                onPressed: () {},
              ),
            ),
          ],
        ),
        const SizedBox(height: NestSpacing.s3),
        NestButton(label: 'Saving', loading: true, onPressed: () {}),
        const SizedBox(height: NestSpacing.s3),
        const NestButton(label: 'Disabled'),
        const SizedBox(height: NestSpacing.s3),
        NestButton(
          label: 'With leading icon',
          leading: NestIcon(NestIcons.check, color: tokens.onLeaf),
          onPressed: () {},
        ),
        const SizedBox(height: NestSpacing.s3),
        NestAppleButton(label: 'Continue with Apple', onPressed: () {}),
        const SizedBox(height: NestSpacing.s3),
        NestGoogleButton(label: 'Continue with Google', onPressed: () {}),
        const SizedBox(height: NestSpacing.s4),
        const NestSectionLabel(
          key: ValueKey('ds-section-cards'),
          label: 'Cards',
        ),
        const SizedBox(height: NestSpacing.s2),
        NestCard(
          child: Text(
            'Card · surface · sh-1 · padding 16',
            style: NestType.body(color: tokens.ink),
          ),
        ),
        const SizedBox(height: NestSpacing.s3),
        NestCard(
          variant: NestCardVariant.inset,
          child: Text(
            'Inset card · surface-2 · no shadow',
            style: NestType.body(color: tokens.ink),
          ),
        ),
        const SizedBox(height: NestSpacing.s3),
        NestCard(
          variant: NestCardVariant.hero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Weekly pocket money',
                style: NestType.bodySmallStrong(color: tokens.onHero2),
              ),
              Text('£3.00', style: NestType.kidHero(color: tokens.onHero)),
              Text(
                'Paid every Saturday',
                style: NestType.bodySmall(color: tokens.onHero2),
              ),
              const SizedBox(height: 14),
              NestButton(label: 'Set up', onPressed: () {}),
            ],
          ),
        ),
        const SizedBox(height: NestSpacing.s4),
        const NestSectionLabel(
          key: ValueKey('ds-section-lists'),
          label: 'Lists',
        ),
        const SizedBox(height: NestSpacing.s2),
        NestList(
          children: [
            NestListRow(
              title: 'Put the bins out — a very long title truncates',
              subtitle: 'Suggested 15 coins · Age 8+',
              leadingAsset: NestIcons.bin,
              tint: NestTileTint.leaf,
              trailing: Text(
                '+ Add',
                style: NestType.chipSmall(color: tokens.ink3),
              ),
              onTap: () {},
            ),
            NestListRow(
              title: 'Pocket money',
              subtitle: '£3.00/week',
              leadingAsset: NestIcons.poundCoin,
              tint: NestTileTint.coin,
              trailing: Text('›', style: NestType.h3(color: tokens.ink3)),
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: NestSpacing.s4),
        const NestSectionLabel(
          key: ValueKey('ds-section-chips'),
          label: 'Chips',
        ),
        const SizedBox(height: NestSpacing.s2),
        const _ChipsDemo(),
        const SizedBox(height: NestSpacing.s4),
        const NestSectionLabel(
          key: ValueKey('ds-section-segmented'),
          label: 'Segmented',
        ),
        const SizedBox(height: NestSpacing.s2),
        const _SegmentedDemo(),
        const SizedBox(height: NestSpacing.s4),
        const NestSectionLabel(
          key: ValueKey('ds-section-toggles'),
          label: 'Toggles',
        ),
        const SizedBox(height: NestSpacing.s2),
        const _ToggleDemo(),
        const SizedBox(height: NestSpacing.s4),
        const NestSectionLabel(
          key: ValueKey('ds-section-stepper'),
          label: 'Stepper',
        ),
        const SizedBox(height: NestSpacing.s2),
        const _StepperDemo(),
      ],
    );
  }
}

class _ChipsDemo extends StatefulWidget {
  const new();

  @override
  State<_ChipsDemo> createState() => _ChipsDemoState();
}

class _ChipsDemoState extends State<_ChipsDemo> {
  final selected = <String>{'Sat'};

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: NestSpacing.s2,
      runSpacing: NestSpacing.s2,
      children: [
        for (final label in const ['Kitchen', 'Sat', 'Outdoors'])
          NestChip(
            label: label,
            selected: selected.contains(label),
            onSelected: (value) => setState(() {
              if (value) {
                selected.add(label);
              } else {
                selected.remove(label);
              }
            }),
          ),
      ],
    );
  }
}

class _SegmentedDemo extends StatefulWidget {
  const new();

  @override
  State<_SegmentedDemo> createState() => _SegmentedDemoState();
}

class _SegmentedDemoState extends State<_SegmentedDemo> {
  String value = 'Once';

  @override
  Widget build(BuildContext context) {
    return NestSegmented<String>(
      options: const [
        NestSegmentOption(value: 'Once', label: 'Once'),
        NestSegmentOption(value: 'Daily', label: 'Daily'),
        NestSegmentOption(value: 'Weekly', label: 'Weekly'),
      ],
      value: value,
      onChanged: (next) => setState(() => value = next),
    );
  }
}

class _ToggleDemo extends StatefulWidget {
  const new();

  @override
  State<_ToggleDemo> createState() => _ToggleDemoState();
}

class _ToggleDemoState extends State<_ToggleDemo> {
  bool approvals = true;
  bool reminders = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Approvals waiting',
                style: NestType.body(color: tokens.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            NestToggle(
              value: approvals,
              semanticLabel: 'Approvals waiting',
              onChanged: (next) => setState(() => approvals = next),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                'Reminders',
                style: NestType.body(color: tokens.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            NestToggle(
              value: reminders,
              semanticLabel: 'Reminders',
              onChanged: (next) => setState(() => reminders = next),
            ),
          ],
        ),
      ],
    );
  }
}

class _StepperDemo extends StatefulWidget {
  const new();

  @override
  State<_StepperDemo> createState() => _StepperDemoState();
}

class _StepperDemoState extends State<_StepperDemo> {
  double amount = 3;

  @override
  Widget build(BuildContext context) {
    return NestStepper(
      valueText: formatPounds(amount),
      onDecrease: amount <= 0 ? null : () => setState(() => amount -= 0.5),
      onIncrease: () => setState(() => amount += 0.5),
    );
  }
}
