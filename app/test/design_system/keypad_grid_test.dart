import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

// CSS `.keypad` grid (components.css:193): `repeat(3, 1fr)`, 10px gaps,
// padding 8px 24px 0, 72px keys centred in their cells.
//
// P17 gate card: block-level grid in the 302px card content box
// (342px modal - 2x20px card padding) -> 78px columns, 88px column pitch.
// K02 PIN: `.k2-body{align-items:center}` shrink-wraps the grid to its
// 284px max-content width inside the 350px scroll content box -> 72px
// columns, 82px column pitch. Both verified against the design PNGs
// (P17 key columns 71-143/159-231/247-319; K02 77-149/159-231/241-313).
// Tests pump with the real bundled Inter/Nunito fonts (no mocks).
void main() {
  group('NestKeypad CSS grid', () {
    test('contentWidth is the CSS max-content width', () {
      expect(NestKeypad.contentWidth, 284);
      expect(
        NestKeypad(onKey: (_) {}, onDelete: () {}).fit,
        NestKeypadFit.stretch,
      );
    });

    testWidgets('P17 stretch grid at 302px card content width', (tester) async {
      await pumpBothModes(
        tester,
        SizedBox(
          width: 302,
          child: NestKeypad(onKey: (_) {}, onDelete: () {}),
        ),
      );
      final origin = tester.getTopLeft(find.byType(NestKeypad));
      Offset centerOf(String label) =>
          tester.getCenter(find.text(label)) - origin;

      // Column centres: 24px padding + 78px columns -> 63/151/239.
      expect(centerOf('1'), const Offset(63, 44));
      expect(centerOf('2'), const Offset(151, 44));
      expect(centerOf('3'), const Offset(239, 44));
      expect(centerOf('4').dx, moreOrLessEquals(63));
      expect(centerOf('0'), const Offset(151, 290));

      // Pitches: 78 + 10 = 88 across, 72 + 10 = 82 down.
      expect(centerOf('2').dx - centerOf('1').dx, moreOrLessEquals(88));
      expect(centerOf('4').dy - centerOf('1').dy, moreOrLessEquals(82));

      // Keys are 72x72 (well above the 44px minimum tap target).
      final firstKey = find
          .descendant(of: find.byType(NestKeypad), matching: find.byType(Ink))
          .first;
      expect(tester.getSize(firstKey), const Size(72, 72));

      // Padding: 8px top, 0 bottom. Total height 8 + 4x72 + 3x10 = 326.
      final padTop = tester.getTopLeft(firstKey).dy - origin.dy;
      expect(padTop, moreOrLessEquals(8));
      expect(tester.getSize(find.byType(NestKeypad)), const Size(302, 326));
    });

    testWidgets('K02 shrinkWrap grid at 350px scroll content width', (
      tester,
    ) async {
      await pumpBothModes(
        tester,
        SizedBox(
          width: 350,
          height: 326,
          child: NestKeypad(
            kid: true,
            fit: NestKeypadFit.shrinkWrap,
            onKey: (_) {},
            onDelete: () {},
          ),
        ),
      );
      final origin = tester.getTopLeft(find.byType(NestKeypad));
      Offset centerOf(String label) =>
          tester.getCenter(find.text(label)) - origin;

      // 284px grid centred in 350px -> 33px each side; 72px columns.
      expect(centerOf('1'), const Offset(93, 44));
      expect(centerOf('2'), const Offset(175, 44));
      expect(centerOf('3'), const Offset(257, 44));
      expect(centerOf('0'), const Offset(175, 290));

      // Pitches: 72 + 10 = 82 both ways.
      expect(centerOf('2').dx - centerOf('1').dx, moreOrLessEquals(82));
      expect(centerOf('4').dy - centerOf('1').dy, moreOrLessEquals(82));

      final keys = find.descendant(
        of: find.byType(NestKeypad),
        matching: find.byType(Ink),
      );
      expect(keys, findsNWidgets(11));
      expect(tester.getSize(keys.first), const Size(72, 72));
      final keypadRight = origin.dx + 350;
      expect(
        tester.getTopLeft(keys.first).dx,
        moreOrLessEquals(origin.dx + 57),
      );
      expect(
        tester.getBottomRight(keys.first).dx,
        moreOrLessEquals(origin.dx + 129),
      );
      expect(
        tester.getBottomRight(keys.at(2)).dx,
        moreOrLessEquals(keypadRight - 57),
      );
    });

    testWidgets('shrinkWrap caps at contentWidth on narrow screens', (
      tester,
    ) async {
      await pumpBothModes(
        tester,
        SizedBox(
          width: 280,
          child: NestKeypad(
            kid: true,
            fit: NestKeypadFit.shrinkWrap,
            onKey: (_) {},
            onDelete: () {},
          ),
        ),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
      expect(
        tester.getSize(find.byType(NestKeypad)).width,
        moreOrLessEquals(280),
      );
    });

    testWidgets('digit and delete taps fire in both fits', (tester) async {
      for (final fit in NestKeypadFit.values) {
        final keys = <String>[];
        var deleted = 0;
        await pumpNest(
          tester,
          SizedBox(
            width: 350,
            child: NestKeypad(
              fit: fit,
              onKey: keys.add,
              onDelete: () => deleted++,
            ),
          ),
        );
        await tester.tap(find.text('5'));
        await tester.tap(find.bySemanticsLabel('Delete'));
        expect(keys, ['5']);
        expect(deleted, 1);
      }
    });
  });
}
