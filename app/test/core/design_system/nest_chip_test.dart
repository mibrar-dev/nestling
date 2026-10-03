// NestChip paints the 14 px side padding INSIDE the pill.
//
// `.chip` is `height: 32px; padding: 0 14px` (`components.css`), so the
// decorated pill must be text width + 28 wide and 32 high. The padding used
// to sit OUTSIDE the `DecoratedBox`, painting the background and the 1.5 px
// border only behind the text (P05 age-band chips rendered as narrow ovals).
// There is deliberately no 44 px minimum on the visible pill itself (CSS sets
// no min-width on `.chip`): narrow pills stay narrow and the 44 px minimum
// tap area comes from the hit-test expander, which never changes layout.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../design_system/test_harness.dart';

/// Loads the bundled Inter faces so text metrics match a device run, as
/// `privacy_consent_geometry_test.dart` does.
Future<void> _loadInter() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  await inter.load();
}

/// Intrinsic single-line width of a chip label at the design style.
double _paragraphWidth(String label) {
  final painter = TextPainter(
    text: TextSpan(text: label, style: NestType.chipLabel()),
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

Finder _pillOf(Finder chip) =>
    find.descendant(of: chip, matching: find.byType(DecoratedBox));

void main() {
  setUpAll(_loadInter);

  group('NestChip pill geometry (real Inter)', () {
    for (final mode in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${mode.name}: pill is text width + 28 and 32 high', (
        tester,
      ) async {
        // Static chip: exactly one DecoratedBox, no InkWell in the tree.
        await pumpNest(
          tester,
          const Center(child: NestChip(label: '4–6')),
          mode: mode,
        );

        final pill = _pillOf(find.byType(NestChip));
        expect(pill, findsOneWidget);
        final size = tester.getSize(pill);
        expect(
          size.width,
          moreOrLessEquals(_paragraphWidth('4–6') + 28, epsilon: 0.5),
          reason: 'padding 14 + 14 lives inside the decoration',
        );
        expect(size.height, moreOrLessEquals(32, epsilon: 0.01));
        expect(tester.takeException(), isNull);
      });

      testWidgets('${mode.name}: selected border spans the pill, '
          'not the text', (tester) async {
        await pumpNest(
          tester,
          const Center(child: NestChip(label: '4–6', selected: true)),
          mode: mode,
        );

        final pill = _pillOf(find.byType(NestChip));
        expect(pill, findsOneWidget);
        final pillRect = tester.getRect(pill);
        final textRect = tester.getRect(find.text('4–6'));

        // The pill is the text plus the 14 px padding on each side; the
        // text rect alone is 28 narrower.
        expect(
          pillRect.width,
          moreOrLessEquals(_paragraphWidth('4–6') + 28, epsilon: 0.5),
        );
        expect(
          pillRect.width - textRect.width,
          moreOrLessEquals(28, epsilon: 0.5),
          reason: 'the 14 + 14 padding is inside the decorated pill',
        );
        expect(pillRect.height, moreOrLessEquals(32, epsilon: 0.01));

        // The leaf border is painted on the pill decoration itself.
        final decoration =
            tester.widget<DecoratedBox>(pill).decoration as BoxDecoration;
        final border = decoration.border! as Border;
        final leaf = mode == ThemeMode.light
            ? NestColors.light.leaf
            : NestColors.dark.leaf;
        expect(border.top.color, leaf);
        expect(border.top.width, 1.5);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('narrow pill stays narrow visually, tap still spans 44', (
      tester,
    ) async {
      final selected = <bool>[];
      await pumpNest(
        tester,
        Center(
          child: NestChip(
            key: const ValueKey('chip-narrow'),
            label: 'A',
            onSelected: selected.add,
          ),
        ),
      );

      // No 44 px minimum on the visible pill: text + 28 can be under 44.
      final rect = tester.getRect(find.byType(NestChip));
      expect(rect.width, lessThan(44));
      expect(
        rect.width,
        moreOrLessEquals(_paragraphWidth('A') + 28, epsilon: 0.5),
      );
      expect(rect.height, moreOrLessEquals(32, epsilon: 0.01));

      // 21 px from the centre is always inside the 44-wide tap box
      // (half-width 22) yet outside this narrow pill: it still selects.
      await tester.tapAt(rect.center + const Offset(-21, 0));
      await tester.pump();
      expect(selected, [true]);

      // 23 px from the centre is outside the 44 box: falls through.
      await tester.tapAt(rect.center + const Offset(23, 0));
      await tester.pump();
      expect(selected, [true]);
      expect(tester.takeException(), isNull);
    });
  });

  group('NestChip tap targets stay ≥ 44×44', () {
    for (final mode in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${mode.name}: 5 px above/below the pill selects', (
        tester,
      ) async {
        final selected = <bool>[];
        await pumpNest(
          tester,
          Center(
            child: NestChip(
              key: const ValueKey('chip-tap'),
              label: '4–6',
              onSelected: selected.add,
            ),
          ),
          mode: mode,
        );

        // Layout is unchanged: the chip itself is still 32 high.
        final rect = tester.getRect(find.byType(NestChip));
        expect(rect.height, moreOrLessEquals(32, epsilon: 0.01));

        // 32-high pill + 6 px slop each side = 44: 5 px outside still hits.
        // (The chip never rebuilds here, so each tap reports `true`.)
        await tester.tapAt(rect.center + const Offset(0, -21));
        await tester.pump();
        expect(selected, [true]);
        await tester.tapAt(rect.center + const Offset(0, 21));
        await tester.pump();
        expect(selected, [true, true]);
        expect(tester.takeException(), isNull);
      });

      testWidgets('${mode.name}: 5 px above/below selects inside '
          'a NestChipWrap', (tester) async {
        final selected = <String>[];
        await pumpNest(
          tester,
          Padding(
            padding: const EdgeInsets.all(NestSpacing.s2),
            child: NestChipWrap(
              spacing: NestSpacing.s2,
              runSpacing: NestSpacing.s2,
              children: [
                for (final label in const <String>['4–6', '7–9', '10–12'])
                  NestChip(
                    key: ValueKey('chip-$label'),
                    label: label,
                    onSelected: (_) => selected.add(label),
                  ),
              ],
            ),
          ),
          mode: mode,
        );

        final first = find.byKey(const ValueKey('chip-4–6'));
        expect(first, findsOneWidget);
        final rect = tester.getRect(first);
        expect(rect.height, moreOrLessEquals(32, epsilon: 0.01));

        await tester.tapAt(rect.center + const Offset(0, -21));
        await tester.pump();
        expect(selected, ['4–6']);
        await tester.tapAt(rect.center + const Offset(0, 21));
        await tester.pump();
        expect(selected, ['4–6', '4–6']);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
