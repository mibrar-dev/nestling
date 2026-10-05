// K11 · My badges — design geometry at the design's real font metrics.
//
// `flutter_test`'s default font is much wider than the bundled Nunito, so
// this lives in its own file: loading the real faces changes every text
// metric on the screen. Same isolation (and the same reason) as K08's
// `reward_shop_widget_geometry_test.dart`. Behaviour/copy live in
// `badges_view_test.dart`.
//
// What is pinned is the design's own arithmetic, cross-checked pixel by
// pixel against `design/screens/light/K11-badges.png` ÷3 (measured with a
// script over the PNG, not eyeballed):
//
//   status reserve      47
//   back box            x 20…76,   y 47…103   (56, transparent)
//   lock box            x 314…370, y 47…103   (56, surface + line)
//   title line box      y 107…141             (Nunito 28/34)
//   subtitle line       y 157…177             (`.kcap` 15/20)
//   grid row 1          y 193…343  (150)      columns 108.67 / 12 gap
//   grid row 2          y 355…505  (150)
//   grid row 3          y 517…667  (150)
//   week card           y 683…829  (146)      x 20…370, clipped at 810
//   week dots           y 700…738  (38)
//   week letters        y 742…760  (18)
//   why line            y 772…812  (2 × 20, second line clipped at 810)
//   scroll viewport     y 107…810  (`.home-indicator` = 34 below it)
//
// Run directly:
//   flutter test test/features/badges/badges_widget_geometry_test.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/badges/presentation/widgets/badge_grid_cell.dart';
import 'package:nestling/features/badges/presentation/widgets/happy_week_card.dart';

import '../../test_scope.dart';

const String _route = '/badges';

/// Grid geometry at 390 wide (`.k11-grid`: three columns, `--s3` gap, 20 px
/// gutters).
const double _colWidth = 108.67;
const double _colGap = 12;
const double _gutter = 20;

/// Loads the bundled faces so the metrics match a device run.
Future<void> loadBundledFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
  await inter.load();
  await nunito.load();
}

void main() {
  setUpAll(loadBundledFonts);

  setUp(() async {
    await setUpTestScope();
  });

  Future<void> pumpBadges(
    WidgetTester tester, {
    double width = 390,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
    await tester.pumpWidget(const NestlingApp(initialRoute: _route));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  Finder cell(int index) => find.byType(BadgeGridCell).at(index);

  /// The dots are 38 circles inside the week card; the card's own surface is
  /// the only other decorated box, so the circle shape isolates the seven.
  Finder weekDots() => find.descendant(
    of: find.byType(HappyWeekCard),
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration! as BoxDecoration).shape == BoxShape.circle,
    ),
  );

  /// The ALIGNMENT owner rule: every edge on the screen resolves to the same
  /// 20 px gutter, whatever the device width.
  Future<void> expectAlignedEdges(WidgetTester tester, double width) async {
    final edges = <(String, double)>[
      ('back left', tester.getRect(find.byType(NestIconButton)).left),
      ('lock right', tester.getRect(find.byType(NestLockButton)).right),
      ('cell 0 left', tester.getRect(cell(0)).left),
      ('cell 2 right', tester.getRect(cell(2)).right),
      ('week left', tester.getRect(find.byType(HappyWeekCard)).left),
      ('week right', tester.getRect(find.byType(HappyWeekCard)).right),
      ('title left', tester.getRect(find.text('My badges')).left),
    ];
    for (final (what, value) in edges) {
      final expected = what.contains('right') ? width - _gutter : _gutter;
      expect(value, closeTo(expected, 0.5), reason: '$what at $width px');
    }
  }

  group('K11 chrome geometry', () {
    testWidgets('back and lock boxes sit in the 47…103 top row', (
      tester,
    ) async {
      await pumpBadges(tester);
      expect(tester.takeException(), isNull);
      // `.krow-top` starts straight under the status reserve and is 56 + 4
      // tall.
      expect(
        tester.getRect(find.byType(NestIconButton)),
        const Rect.fromLTRB(_gutter, 47, _gutter + 56, 103),
      );
      expect(
        tester.getRect(find.byType(NestLockButton)),
        const Rect.fromLTRB(390 - _gutter - 56, 47, 390 - _gutter, 103),
      );
      await disposeApp(tester);
    });

    testWidgets('the title and the subtitle keep their design rows', (
      tester,
    ) async {
      await pumpBadges(tester);
      expect(tester.takeException(), isNull);
      // 28/34 heading, straight under the 107 top row.
      final title = tester.getRect(find.text('My badges'));
      expect(title.top, closeTo(107, 2));
      expect(title.height, closeTo(34, 2));
      // `.kcap` 15/20: 141 + 16 = 157, one line.
      final subtitle = tester.getRect(
        find.text('Four shiny ones already. Pip is very impressed.'),
      );
      expect(subtitle.top, closeTo(157, 2));
      expect(subtitle.height, closeTo(20, 2));
      await disposeApp(tester);
    });

    testWidgets('the scroll stops 34 px above the physical edge', (
      tester,
    ) async {
      await pumpBadges(tester);
      expect(tester.takeException(), isNull);
      // `.home-indicator { height: var(--home-h) }` (`K11-badges.html:138`):
      // the HTML's flex column gives the scroll 107…810 and clips the week
      // card there — measured on the design PNG, the card's white face ends at
      // y 809 and the meadow fills 810…844.
      expect(
        tester.getRect(find.byType(ListView)),
        const Rect.fromLTRB(0, 107, 390, 810),
      );
      expect(
        tester.getRect(find.byType(HappyWeekCard)).bottom,
        greaterThan(810),
        reason: 'the card runs under the clip, exactly as the design shows it',
      );
      // BOTTOM EDGE owner rule: nothing paints in the reserve — the Scaffold is
      // transparent over the shared `KidScope`, so the meadow runs to the
      // physical edge and the OS home pill sits on it.
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        Colors.transparent,
      );
      await disposeApp(tester);
    });
  });

  group('K11 grid geometry', () {
    testWidgets('three 108.67 columns with a 12 gap and 20 gutters', (
      tester,
    ) async {
      await pumpBadges(tester);
      expect(tester.takeException(), isNull);
      final count = find.byType(BadgeGridCell).evaluate().length;
      for (var index = 0; index + 2 < count; index += 3) {
        expect(
          tester.getRect(cell(index)).left,
          closeTo(_gutter, 0.5),
          reason: 'cell $index left gutter',
        );
        expect(
          tester.getRect(cell(index)).width,
          closeTo(_colWidth, 1),
          reason: 'cell $index width',
        );
        expect(
          tester.getRect(cell(index + 1)).left -
              tester.getRect(cell(index)).right,
          closeTo(_colGap, 0.5),
          reason: 'cell $index gap',
        );
        expect(
          tester.getRect(cell(index + 2)).right,
          closeTo(390 - _gutter, 0.5),
          reason: 'cell $index right gutter',
        );
      }
      // The trailing row of the demo shelf (8 rows, not the design's nine)
      // keeps the same column width and 12 px gap: the inert filler slot holds
      // the third column open so the card below stays on the 20 px gutter.
      if (count % 3 != 0) {
        final last = count - 1;
        expect(
          tester.getRect(cell(count % 3)).width,
          closeTo(_colWidth, 1),
          reason: 'short row keeps the column width',
        );
        expect(
          tester.getRect(cell(last)).width,
          closeTo(_colWidth, 1),
          reason: 'cell $last width',
        );
        expect(
          tester.getRect(cell(last)).left -
              tester.getRect(cell(last - 1)).right,
          closeTo(_colGap, 0.5),
          reason: 'short row gap',
        );
      }
      await disposeApp(tester);
    });

    testWidgets('grid rows land at 193, 355 and 517 — week card at 683', (
      tester,
    ) async {
      await pumpBadges(tester);
      expect(tester.takeException(), isNull);
      for (final (index, top) in <(int, double)>[
        (0, 193),
        (3, 355),
        (6, 517),
      ]) {
        expect(
          tester.getRect(cell(index)).top,
          closeTo(top, 2),
          reason: 'row at $top',
        );
        expect(
          tester.getRect(cell(index)).height,
          closeTo(150, 2),
          reason:
              'cell $index height (border 6 + padding 20 + 60 + 4 + 38 + 4 + 18)',
        );
      }
      // Row 3's last cell is a two-cell row stretched to the same 150 by
      // `IntrinsicHeight`; the week card follows 16 below the grid.
      expect(tester.getRect(cell(7)).top, closeTo(517, 2));
      final week = tester.getRect(find.byType(HappyWeekCard));
      expect(week.top, closeTo(683, 2));
      expect(week.height, closeTo(146, 2));
      expect(week.bottom, closeTo(829, 2));
      await disposeApp(tester);
    });

    testWidgets('the medal, name box and sub keep the cell rhythm', (
      tester,
    ) async {
      await pumpBadges(tester);
      expect(tester.takeException(), isNull);
      // Column: border 3 + padding 10 → medal at 206…266, name box
      // 270…308 (min 38), sub 312…330, padding 10 + border 3 → 343.
      final medal = tester.getRect(
        find.descendant(of: cell(0), matching: find.byType(SvgPicture)),
      );
      // Per-axis, not `== Size.square(60)`: the 108.67 column width arrives
      // with a float tail, so the medal renders 60.00000000000001 wide.
      expect(medal.width, closeTo(60, 0.01), reason: 'medal width');
      expect(medal.height, closeTo(60, 0.01), reason: 'medal height');
      expect(medal.top, closeTo(206, 2));
      final name = tester.getRect(find.text('First quest'));
      expect(name.height, closeTo(19, 2));
      expect(name.center.dy, closeTo(289, 2));
      final sub = tester.getRect(find.text('Got it!').first);
      expect(sub.height, closeTo(18, 2));
      expect(sub.top, closeTo(312, 2));
      // Two-line names share the same 38 box ("Bed maker ×7" wraps in the
      // design).
      final two = tester.getRect(find.text('Bed maker ×7'));
      expect(two.height, closeTo(38, 2));
      expect(two.center.dy, closeTo(289, 2));
      await disposeApp(tester);
    });
  });

  group('K11 week card geometry', () {
    testWidgets('the seven dots are 38 px with 18 px letters under them', (
      tester,
    ) async {
      await pumpBadges(tester);
      expect(tester.takeException(), isNull);
      final dots = weekDots();
      expect(dots, findsNWidgets(7));
      for (var i = 0; i < 7; i++) {
        final rect = tester.getRect(dots.at(i));
        expect(rect.width, closeTo(38, 0.01), reason: 'dot $i width');
        expect(rect.height, closeTo(38, 0.01), reason: 'dot $i height');
        expect(rect.top, closeTo(700, 2), reason: 'dot $i top');
      }
      // Slots are equal: (350 − 6 border − 24 padding − 24 gap) / 7 = 42.29,
      // dot centred → first centre at 35 + 21.14 = 56.14, last at 333.86.
      final first = tester.getRect(dots.first);
      final last = tester.getRect(dots.last);
      expect(first.center.dx, closeTo(56.14, 1));
      expect(last.center.dx, closeTo(333.86, 1));
      final letter = tester.getRect(find.text('M'));
      expect(letter.top, closeTo(742, 2));
      expect(letter.height, closeTo(18, 2));
      await disposeApp(tester);
    });

    testWidgets('the why line is centred under the dots', (tester) async {
      await pumpBadges(tester);
      expect(tester.takeException(), isNull);
      final why = tester.getRect(
        find.text('4 happy days this week — Pip hasn’t stopped singing.'),
      );
      expect(why.top, closeTo(772, 2));
      expect(why.height, closeTo(40, 2));
      expect(
        why.center.dx,
        closeTo(195, 1),
        reason: 'the why line is centred on the card',
      );
      await disposeApp(tester);
    });
  });

  group('K11 alignment across widths (OWNER rule)', () {
    for (final width in <double>[320, 390, 430]) {
      testWidgets('every edge lands on the 20 px gutter at ${width.toInt()}', (
        tester,
      ) async {
        await pumpBadges(tester, width: width);
        expect(tester.takeException(), isNull);
        await expectAlignedEdges(tester, width);
        await disposeApp(tester);
      });

      testWidgets('the columns follow the width at ${width.toInt()}', (
        tester,
      ) async {
        await pumpBadges(tester, width: width);
        expect(tester.takeException(), isNull);
        final column = (width - 2 * _gutter - 2 * _colGap) / 3;
        for (final index in <int>[0, 3, 6]) {
          expect(
            tester.getRect(cell(index)).width,
            closeTo(column, 1),
            reason: 'cell $index at ${width.toInt()}',
          );
          expect(
            tester.getRect(cell(index + 1)).left -
                tester.getRect(cell(index)).right,
            closeTo(_colGap, 0.5),
          );
        }
        await disposeApp(tester);
      });

      testWidgets(
        'the dots shrink instead of overflowing at ${width.toInt()}',
        (tester) async {
          await pumpBadges(tester, width: width);
          expect(tester.takeException(), isNull);
          // min(38, (content − 24) / 7): 38 at 390/430, ~32.3 at 320.
          final dot = tester.getRect(weekDots().first);
          final content = width - 2 * _gutter - 2 * 3 - 2 * 12;
          expect(dot.width, closeTo(mathMin(38, (content - 24) / 7), 0.5));
          expect(find.byType(HappyWeekCard), findsOneWidget);
          await disposeApp(tester);
        },
      );
    }

    testWidgets('320 px at 1.3 text scale still lays out without overflow', (
      tester,
    ) async {
      await pumpBadges(tester, width: 320, textScale: 1.3);
      expect(tester.takeException(), isNull);
      expect(find.text('My badges'), findsOneWidget);
      expect(find.byType(BadgeGridCell), findsNWidgets(8));
      // The last column still ends on the 20 px gutter; the names are
      // clamped to two lines so the cell can never push past its slot.
      expect(tester.getRect(cell(2)).right, closeTo(320 - _gutter, 0.5));
      await disposeApp(tester);
    });
  });
}

/// `dart:math`'s `min` without the import (a one-line helper keeps the
/// analysis surface small).
double mathMin(double a, double b) => a < b ? a : b;
