// NestChipWrap gives chips in a tight row the full 44 px tap target
// without changing the 32 px layout (P05 bug P05-BUG-11).
//
// A plain Wrap/Row of NestChip is exactly 32 px high per run, so taps in
// the 6 px above/below the first/last run never reach the chip. This
// widget lays out identically to Wrap but forwards those points (plus the
// left/right ends and inter-chip gaps) to the nearest chip.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../design_system/test_harness.dart';

List<Widget> _chips(List<String> labels, Map<String, List<bool>> selected) {
  return [
    for (final label in labels)
      NestChip(
        key: ValueKey('wrap-$label'),
        label: label,
        onSelected: (value) => selected[label]!.add(value),
      ),
  ];
}

Widget _rowInColumn({
  required List<String> labels,
  required Map<String, List<bool>> selected,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: NestSpacing.s2),
      Padding(
        padding: const EdgeInsets.all(NestSpacing.s2),
        child: NestChipWrap(
          spacing: NestSpacing.s2,
          runSpacing: NestSpacing.s2,
          children: _chips(labels, selected),
        ),
      ),
      const SizedBox(height: NestSpacing.s2),
    ],
  );
}

void main() {
  group('NestChipWrap', () {
    testWidgets('tap 5 px above the row selects the first chip', (
      tester,
    ) async {
      final selected = {'One': <bool>[], 'Two': <bool>[], 'Three': <bool>[]};
      await pumpNest(
        tester,
        _rowInColumn(labels: const ['One', 'Two', 'Three'], selected: selected),
      );

      final first = find.byKey(const ValueKey('wrap-One'));
      expect(first, findsOneWidget);
      final topLeft = tester.getTopLeft(first);
      final size = tester.getSize(first);
      await tester.tapAt(topLeft + Offset(size.width / 2, -5));
      await tester.pump();

      expect(selected['One'], [true]);
    });

    testWidgets('tap 5 px below the row selects the first chip', (
      tester,
    ) async {
      final selected = {'One': <bool>[], 'Two': <bool>[], 'Three': <bool>[]};
      await pumpNest(
        tester,
        _rowInColumn(labels: const ['One', 'Two', 'Three'], selected: selected),
      );

      final first = find.byKey(const ValueKey('wrap-One'));
      final topLeft = tester.getTopLeft(first);
      final size = tester.getSize(first);
      await tester.tapAt(topLeft + Offset(size.width / 2, size.height + 5));
      await tester.pump();

      expect(selected['One'], [true]);
    });

    testWidgets('tap 2 px left of the first chip selects it', (tester) async {
      final selected = {'One': <bool>[], 'Two': <bool>[], 'Three': <bool>[]};
      await pumpNest(
        tester,
        _rowInColumn(labels: const ['One', 'Two', 'Three'], selected: selected),
      );

      final first = find.byKey(const ValueKey('wrap-One'));
      final topLeft = tester.getTopLeft(first);
      final size = tester.getSize(first);
      await tester.tapAt(topLeft + Offset(-2, size.height / 2));
      await tester.pump();

      expect(selected['One'], [true]);
    });

    testWidgets('laid-out size equals a plain Wrap with same children', (
      tester,
    ) async {
      Widget wrapChildren({required bool useNest}) {
        List<Widget> children() => [
          for (final label in const ['One', 'Two', 'Three'])
            NestChip(label: label, onSelected: (_) {}),
        ];
        if (useNest) {
          return NestChipWrap(
            spacing: NestSpacing.s2,
            runSpacing: NestSpacing.s2,
            children: children(),
          );
        }
        return Wrap(
          spacing: NestSpacing.s2,
          runSpacing: NestSpacing.s2,
          children: children(),
        );
      }

      await pumpNest(tester, wrapChildren(useNest: true));
      final nestSize = tester.getSize(find.byType(NestChipWrap));

      await pumpNest(tester, wrapChildren(useNest: false));
      final wrapSize = tester.getSize(find.byType(Wrap));

      expect(nestSize, wrapSize);
    });

    testWidgets('tap in the 8 px gap selects a neighbouring chip', (
      tester,
    ) async {
      final selected = {'Alpha': <bool>[], 'Beta': <bool>[]};
      await pumpNest(
        tester,
        _rowInColumn(labels: const ['Alpha', 'Beta'], selected: selected),
      );

      final first = find.byKey(const ValueKey('wrap-Alpha'));
      final second = find.byKey(const ValueKey('wrap-Beta'));
      final firstRight =
          tester.getTopLeft(first).dx + tester.getSize(first).width;
      final secondLeft = tester.getTopLeft(second).dx;
      // Spacing is 8: the gap middle sits 4 px past the first chip.
      expect(secondLeft - firstRight, moreOrLessEquals(8, epsilon: 0.5));
      final top = tester.getTopLeft(first).dy;
      final height = tester.getSize(first).height;

      await tester.tapAt(Offset(firstRight + 4, top + height / 2));
      await tester.pump();

      final hits = selected['Alpha']!.length + selected['Beta']!.length;
      expect(hits, 1);
    });

    testWidgets('two runs with runSpacing 8 have no dead spots between runs', (
      tester,
    ) async {
      final selected = {'Long label A': <bool>[], 'Long label B': <bool>[]};
      await pumpNest(
        tester,
        Padding(
          padding: const EdgeInsets.all(NestSpacing.s2),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 160,
              child: NestChipWrap(
                spacing: NestSpacing.s2,
                runSpacing: NestSpacing.s2,
                children: [
                  for (final label in const ['Long label A', 'Long label B'])
                    NestChip(
                      key: ValueKey('wrap-$label'),
                      label: label,
                      onSelected: (value) => selected[label]!.add(value),
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      final wrapTopLeft = tester.getTopLeft(find.byType(NestChipWrap));
      final wrapSize = tester.getSize(find.byType(NestChipWrap));
      final firstTop = tester
          .getTopLeft(find.byKey(const ValueKey('wrap-Long label A')))
          .dy;
      final secondTop = tester
          .getTopLeft(find.byKey(const ValueKey('wrap-Long label B')))
          .dy;
      // Setup check: the narrow width forces exactly two runs.
      expect(secondTop - firstTop, moreOrLessEquals(40, epsilon: 1));

      final gapY = firstTop + 32 + 4;
      var taps = 0;
      // Sweep across the full run width in the middle of the runSpacing gap.
      for (
        var x = wrapTopLeft.dx + 1;
        x < wrapTopLeft.dx + wrapSize.width - 1;
        x += 4
      ) {
        await tester.tapAt(Offset(x, gapY));
        await tester.pump();
        taps++;
      }

      final hits =
          selected['Long label A']!.length + selected['Long label B']!.length;
      expect(hits, taps);
    });
  });
}
