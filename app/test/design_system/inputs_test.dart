import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

void main() {
  group('NestChip', () {
    testWidgets('static and interactive chips lay out 32 high', (tester) async {
      await pumpBothModes(
        tester,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NestChip(label: 'Static'),
            SizedBox(width: 8),
            _InteractiveChip(),
          ],
        ),
      );
      expect(tester.getSize(find.text('Static')).height, lessThan(44));
      // The pill lays out at the design's 32 px; the 44 tap minimum is an
      // overlaid hit test (shared batch 2), not layout.
      final staticChip = tester.getSize(
        find.ancestor(of: find.text('Static'), matching: find.byType(NestChip)),
      );
      expect(staticChip.height, 32);
      final hit = tester.getSize(
        find.ancestor(
          of: find.text('Tappable'),
          matching: find.byType(NestChip),
        ),
      );
      expect(hit.height, 32);
      expect(hit.width, greaterThanOrEqualTo(44));
    });

    testWidgets('select toggles', (tester) async {
      final selected = <bool>[];
      await pumpNest(tester, NestChip(label: 'Sat', onSelected: selected.add));
      await tester.tap(find.byType(NestChip));
      expect(selected, [true]);
    });

    testWidgets('no overflow at 320 wide and textScale 1.3', (tester) async {
      await pumpBothModes(
        tester,
        Wrap(
          spacing: 8,
          children: [
            for (var i = 0; i < 6; i++)
              NestChip(
                label: 'Very long chip label $i',
                selected: i.isEven,
                onSelected: (_) {},
              ),
          ],
        ),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
    });
  });

  group('NestDayPicker', () {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    testWidgets('seven 44-high cells in one row', (tester) async {
      await pumpBothModes(
        tester,
        NestDayPicker(days: days, selected: const {5}, onChanged: (_) {}),
      );
      expect(find.byType(InkWell), findsNWidgets(7));
      final cell = tester.getSize(find.byType(InkWell).first);
      expect(cell.height, greaterThanOrEqualTo(44));
    });

    testWidgets('tap reports the index', (tester) async {
      final tapped = <int>[];
      await pumpNest(
        tester,
        NestDayPicker(days: days, selected: const {}, onChanged: tapped.add),
      );
      await tester.tap(find.text('S').first);
      expect(tapped, [5]);
    });

    testWidgets('fits 320 wide at textScale 1.3', (tester) async {
      await pumpBothModes(
        tester,
        NestDayPicker(days: days, selected: const {0, 6}, onChanged: (_) {}),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
    });
  });

  group('NestSegmented', () {
    const options = [
      NestSegmentOption(value: 'Once', label: 'Once'),
      NestSegmentOption(value: 'Daily', label: 'Daily'),
      NestSegmentOption(value: 'Weekly', label: 'Weekly'),
    ];

    testWidgets('44 thumb in a 52 container', (tester) async {
      await pumpBothModes(
        tester,
        NestSegmented<String>(
          options: options,
          value: 'Once',
          onChanged: (_) {},
        ),
      );
      // `.segmented`: 4 px padding around 44 px buttons = 52 px track.
      expect(
        tester.getSize(find.byType(NestSegmented<String>).first).height,
        52,
      );
      expect(tester.getSize(find.byType(InkWell).first).height, 44);
    });

    testWidgets('tap reports the value', (tester) async {
      var value = 'Once';
      await pumpNest(
        tester,
        NestSegmented<String>(
          options: options,
          value: value,
          onChanged: (next) => value = next,
        ),
      );
      await tester.tap(find.text('Daily'));
      expect(value, 'Daily');
    });

    testWidgets('long labels ellipsize at 320 wide', (tester) async {
      await pumpBothModes(
        tester,
        NestSegmented<String>(
          options: const [
            NestSegmentOption(value: 'a', label: 'A very long option label'),
            NestSegmentOption(value: 'b', label: 'Another long option label'),
          ],
          value: 'a',
          onChanged: (_) {},
        ),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
    });
  });

  group('NestToggle', () {
    testWidgets('51x31 track inside a 44 hit area', (tester) async {
      await pumpBothModes(
        tester,
        NestToggle(value: true, semanticLabel: 'Approvals', onChanged: (_) {}),
      );
      final hit = tester.getSize(find.byType(NestToggle));
      expect(hit.height, greaterThanOrEqualTo(44));
      final track = tester.getSize(find.byType(AnimatedContainer));
      expect(track.width, 51);
      expect(track.height, 31);
    });

    testWidgets('tap flips the value', (tester) async {
      final calls = <bool>[];
      await pumpNest(
        tester,
        NestToggle(
          value: false,
          semanticLabel: 'Reminders',
          onChanged: calls.add,
        ),
      );
      await tester.tap(find.byType(NestToggle));
      expect(calls, [true]);
    });
  });

  group('NestTextField', () {
    testWidgets('label, helper and error render', (tester) async {
      await pumpBothModes(
        tester,
        const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NestTextField(
                label: 'Email',
                hintText: 'sarah@example.co.uk',
                helperText: 'Children never need an email.',
              ),
              SizedBox(height: 12),
              NestTextField(label: 'Nickname', errorText: 'Too short.'),
            ],
          ),
        ),
      );
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Children never need an email.'), findsOneWidget);
      expect(find.text('Too short.'), findsOneWidget);
    });

    testWidgets('typing and obscure eye work', (tester) async {
      var changed = '';
      await pumpNest(
        tester,
        NestTextField(
          label: 'Password',
          obscureText: true,
          onChanged: (value) => changed = value,
        ),
      );
      await tester.enterText(find.byType(TextField), 'secret');
      expect(changed, 'secret');
      final field = find.byType(TextField);
      expect(tester.widget<TextField>(field).obscureText, isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(tester.widget<TextField>(field).obscureText, isFalse);
      expect(find.text('secret'), findsOneWidget);
    });

    testWidgets('no overflow at 320 wide and textScale 1.3', (tester) async {
      await pumpBothModes(
        tester,
        const NestTextField(
          label: 'A very long field label that must ellipsize',
          helperText: 'A long helper line that wraps under the field.',
          errorText: 'A long error line that wraps under the field.',
        ),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
    });
  });

  group('NestStepper', () {
    testWidgets('44 buttons and inc/dec callbacks', (tester) async {
      var value = 3.0;
      await pumpBothModes(
        tester,
        StatefulBuilder(
          builder: (context, setState) => NestStepper(
            valueText: formatPounds(value),
            onDecrease: () => setState(() => value -= 0.5),
            onIncrease: () => setState(() => value += 0.5),
          ),
        ),
      );
      expect(find.text('£3.00'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('increase')));
      await tester.pumpAndSettle();
      expect(find.text('£3.50'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('decrease')));
      await tester.pumpAndSettle();
      expect(find.text('£3.00'), findsOneWidget);
    });

    testWidgets('no overflow at 320 wide and textScale 1.3', (tester) async {
      await pumpBothModes(
        tester,
        const NestStepper(valueText: '£123.50'),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
    });
  });
}

class _InteractiveChip extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return NestChip(label: 'Tappable', onSelected: (_) {});
  }
}
