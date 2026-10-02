import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// P05 "Add a child" form card (HTML `.form-card`, padding 14).
///
/// The nickname [TextEditingController]/[FocusNode] are owned by the caller
/// (the screen's state) so the bottom CTA can read the field and restore
/// focus after a save; the bloc stays the source of truth for validation.
class AddChildFormCard extends StatelessWidget {
  const AddChildFormCard({
    required this.nicknameController,
    required this.nicknameFocus,
    required this.draftAgeBand,
    required this.draftAvatarColour,
    required this.nicknameError,
    required this.onNicknameChanged,
    required this.onAgeBandSelected,
    required this.onAvatarColourSelected,
    super.key,
  });

  final TextEditingController nicknameController;
  final FocusNode nicknameFocus;
  final String draftAgeBand;
  final String draftAvatarColour;
  final String? nicknameError;
  final ValueChanged<String> onNicknameChanged;
  final ValueChanged<String> onAgeBandSelected;
  final ValueChanged<String> onAvatarColourSelected;

  static const List<String> ageBands = <String>['4-6', '7-9', '10-12', '13+'];

  static const List<String> swatchColours = <String>[
    'lilac',
    'peach',
    'sky',
    'leaf',
    'coin',
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return NestCard(
      padding: const EdgeInsets.all(NestSpacing.gap14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add a child', style: NestType.h3(color: tokens.ink)),
          const SizedBox(height: NestSpacing.gap10),
          NestTextField(
            key: const Key('nicknameField'),
            label: 'Nickname',
            hintText: 'e.g. Ollie',
            controller: nicknameController,
            focusNode: nicknameFocus,
            textInputAction: TextInputAction.done,
            errorText: nicknameError,
            onChanged: onNicknameChanged,
          ),
          const SizedBox(height: NestSpacing.s2),
          Text(
            'Age band',
            style: NestType.fieldLabel(color: tokens.ink2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: NestSpacing.s1),
          Wrap(
            spacing: NestSpacing.s2,
            runSpacing: NestSpacing.s2,
            children: [
              for (final band in ageBands)
                NestChip(
                  key: Key('ageChip-$band'),
                  label: _displayBand(band),
                  selected: draftAgeBand == band,
                  onSelected: (_) => onAgeBandSelected(band),
                ),
            ],
          ),
          const SizedBox(height: NestSpacing.s2),
          Text(
            'Avatar colour',
            style: NestType.fieldLabel(color: tokens.ink2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: NestSpacing.s1),
          Semantics(
            label: 'Avatar colour',
            container: true,
            child: Wrap(
              spacing: NestSpacing.s2,
              runSpacing: NestSpacing.s2,
              children: [
                for (final colour in swatchColours)
                  _Swatch(
                    colour: colour,
                    selected: draftAvatarColour == colour,
                    onTap: () => onAvatarColourSelected(colour),
                  ),
              ],
            ),
          ),
          const SizedBox(height: NestSpacing.gap6),
          Text(
            'We only ask for an age range so quests suit them.',
            style: NestType.caption(color: tokens.ink2),
          ),
        ],
      ),
    );
  }

  static String _displayBand(String band) => band.replaceAll('-', '\u2013');
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.colour,
    required this.selected,
    required this.onTap,
  });

  final String colour;
  final bool selected;
  final VoidCallback onTap;

  Color _fill(NestTokens tokens) => switch (colour) {
    'lilac' => tokens.lilac,
    'peach' => tokens.peach,
    'sky' => tokens.sky,
    'leaf' => tokens.leaf,
    'coin' => tokens.coin,
    _ => tokens.surface2,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Semantics(
      key: Key('swatch-$colour'),
      label: 'Avatar colour $colour',
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: NestDevice.tapParent,
          height: NestDevice.tapParent,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _fill(tokens),
            boxShadow: selected
                ? <BoxShadow>[
                    BoxShadow(
                      color: tokens.ink,
                      spreadRadius: NestSpacing.gap3,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}
