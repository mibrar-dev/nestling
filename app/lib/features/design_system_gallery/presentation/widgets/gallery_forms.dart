import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// Form components: text fields, day picker, keypad + PIN dots.
class GalleryForms extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NestSectionLabel(
          key: ValueKey('ds-section-inputs'),
          label: 'Text fields',
        ),
        SizedBox(height: NestSpacing.s2),
        NestTextField(
          label: 'Email',
          hintText: 'sarah@example.co.uk',
          helperText: 'Children never need an email.',
        ),
        SizedBox(height: NestSpacing.s3),
        NestTextField(
          label: 'Password',
          hintText: 'Choose a password',
          obscureText: true,
        ),
        SizedBox(height: NestSpacing.s3),
        NestTextField(
          label: 'Nickname',
          hintText: 'Maya',
          errorText: 'Nicknames need at least 2 letters.',
        ),
        SizedBox(height: NestSpacing.s4),
        NestSectionLabel(
          key: ValueKey('ds-section-day-picker'),
          label: 'Day picker',
        ),
        SizedBox(height: NestSpacing.s2),
        _DayDemo(),
        SizedBox(height: NestSpacing.s4),
        NestSectionLabel(
          key: ValueKey('ds-section-keypad'),
          label: 'Keypad + PIN',
        ),
        SizedBox(height: NestSpacing.s2),
        _PinDemo(),
      ],
    );
  }
}

class _DayDemo extends StatefulWidget {
  const new();

  @override
  State<_DayDemo> createState() => _DayDemoState();
}

class _DayDemoState extends State<_DayDemo> {
  final selected = <int>{5};

  @override
  Widget build(BuildContext context) {
    return NestDayPicker(
      days: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'],
      selected: selected,
      onChanged: (index) => setState(() {
        if (selected.contains(index)) {
          selected.remove(index);
        } else {
          selected.add(index);
        }
      }),
    );
  }
}

class _PinDemo extends StatefulWidget {
  const new();

  @override
  State<_PinDemo> createState() => _PinDemoState();
}

class _PinDemoState extends State<_PinDemo> {
  String pin = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        NestPinDots(total: 4, filled: pin.length),
        NestKeypad(
          onKey: (digit) {
            if (pin.length >= 4) {
              return;
            }
            setState(() => pin += digit);
          },
          onDelete: () {
            if (pin.isEmpty) {
              return;
            }
            setState(() => pin = pin.substring(0, pin.length - 1));
          },
        ),
      ],
    );
  }
}
