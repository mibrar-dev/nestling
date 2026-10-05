// Shared/polish_ui — `NestSegmented` narrow-width behaviour (P12-BUG-04).
//
// At 390 dp the control is byte-for-byte the old `Expanded` row (no scroll);
// when the track cannot fit every option at 44 px it switches to a
// horizontally scrollable track where every segment keeps a fixed 44 px
// width and the selected segment is scrolled into view.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../design_system/test_harness.dart';

const _six = <NestSegmentOption<String>>[
  NestSegmentOption(value: 'maya', label: 'Maya'),
  NestSegmentOption(value: 'leo', label: 'Leo'),
  NestSegmentOption(value: 'max', label: 'Maximilian-Alexander'),
  NestSegmentOption(value: 'noah', label: 'Noah'),
  NestSegmentOption(value: 'ava', label: 'Ava'),
  NestSegmentOption(value: 'ethan', label: 'Ethan'),
];

Finder _buttons() => find.descendant(
  of: find.byType(NestSegmented<String>),
  matching: find.byType(InkWell),
);

/// Screens lay the control in a 20 px-gutter column (`.scroll` padding), so
/// at 320 dp the track is 280 wide — the P12-BUG-04 roster. The harness
/// Scaffold stretches full-bleed, so the gutter is reproduced here.
Widget _guttered(Widget child) =>
    Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: child);

void main() {
  group('NestSegmented narrow (shared/polish_ui)', () {
    testWidgets('at 390dp six options fit with no scrollable', (tester) async {
      await pumpNest(
        tester,
        _guttered(
          NestSegmented<String>(
            options: _six,
            value: 'maya',
            onChanged: (_) {},
          ),
        ),
      );
      expect(tester.getSize(find.byType(NestSegmented<String>)).height, 52);
      // Expanded row: no horizontal scroller in the tree.
      expect(
        find.descendant(
          of: find.byType(NestSegmented<String>),
          matching: find.byType(SingleChildScrollView),
        ),
        findsNothing,
      );
      for (var i = 0; i < 6; i++) {
        final size = tester.getSize(_buttons().at(i));
        expect(size.height, 44);
        expect(size.width, greaterThanOrEqualTo(44));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('at 320dp every segment keeps a 44x44 button', (tester) async {
      await pumpNest(
        tester,
        _guttered(
          NestSegmented<String>(
            options: _six,
            value: 'maya',
            onChanged: (_) {},
          ),
        ),
        surface: const Size(320, 844),
      );
      expect(
        find.descendant(
          of: find.byType(NestSegmented<String>),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      expect(_buttons(), findsNWidgets(6));
      for (var i = 0; i < 6; i++) {
        expect(tester.getSize(_buttons().at(i)), const Size(44, 44));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('narrow track scrolls and taps the last option', (
      tester,
    ) async {
      var value = 'maya';
      await pumpNest(
        tester,
        _guttered(
          StatefulBuilder(
            builder: (context, setState) => NestSegmented<String>(
              options: _six,
              value: value,
              onChanged: (next) => setState(() => value = next),
            ),
          ),
        ),
        surface: const Size(320, 844),
      );
      // Last option starts partially off-screen; drag it into view.
      await tester.drag(
        find.byType(NestSegmented<String>),
        const Offset(-60, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ethan'));
      await tester.pump();
      expect(value, 'ethan');
      expect(tester.takeException(), isNull);
    });

    testWidgets('narrow options expose tap semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpNest(
        tester,
        _guttered(
          NestSegmented<String>(
            options: _six,
            value: 'maya',
            onChanged: (_) {},
          ),
        ),
        surface: const Size(320, 844),
      );
      for (final label in ['Maya', 'Leo', 'Noah', 'Ava', 'Ethan']) {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: '$label must stay tappable at 320dp',
        );
      }
      handle.dispose();
    });
  });
}
