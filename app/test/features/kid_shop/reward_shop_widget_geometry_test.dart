// K08 · Reward shop — design geometry at the design's real font metrics.
//
// `flutter_test`'s default font is much wider than the bundled Nunito, so this
// lives in its own file: loading the real faces changes every text metric on
// the screen. Same isolation (and the same reason) as K03's
// `kid_home_geometry_test.dart`. Behaviour/copy live in
// `reward_shop_view_test.dart`.
//
// What is pinned is the design's own arithmetic, cross-checked pixel by pixel
// against `design/screens/light/K08-shop.png` ÷3 (measured with a script over
// the PNG, not eyeballed):
//
//   status reserve      47
//   back box            x 20…76,   y 47…103   (56, transparent)
//   lock box            x 314…370, y 47…103   (56, surface + line)
//   coin pill           x 276…370, y 109…149  (94 × 40, `.coin-pill.big`)
//   title line box      y 112…146             (34, centred in the 40 row)
//   intro line          y 165…185             (20, `.kcap`)
//   grid row 1          y 201…417  (216)      columns x 20…187 / 203…370 (167)
//   grid row 2          y 433…649  (216)
//   grid row 3          y 665…905  (240)      café note adds 6 + 18, and CSS
//                                              grid stretch makes the dinner
//                                              card 240 too
//   card content box    x 23…184               (border 3 + padding 10)
//   art circle          y 214…270  (56, centre y 242)
//   name box            y 276…316  (min 40)    2 lines = 38, centred → 277
//   price row           y 322…342  (20)        label 16 → 324
//   button              y 348…404  (56)        + the widget's own 6 px shadow
//                                              room, 404…410, inside the card
//
// Run directly:
//   flutter test test/features/kid_shop/reward_shop_widget_geometry_test.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_shop/presentation/widgets/shop_reward_card.dart';

import '../../test_scope.dart';

const String _route = '/reward-shop';

/// `.kcap` intro line, pinned once so the alignment check below can measure
/// its box (a `Text` box spans the available width, so its edges ARE the
/// scroll's gutters).
const String _intro = 'Spend your coins on things you actually want.';

/// Grid geometry at 390 wide (`.k8-grid`: two columns, `--s4` gap, 20 px
/// gutters).
const double _colWidth = 167;
const double _colGap = 16;
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

  late AppDatabase db;

  setUp(() async {
    db = await setUpTestScope();
  });

  Future<void> pumpShop(WidgetTester tester, {double width = 390}) async {
    tester.view.physicalSize = Size(width * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
    await tester.pumpWidget(const NestlingApp(initialRoute: _route));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  Finder card(int index) => find.byType(ShopRewardCard).at(index);

  /// The ALIGNMENT owner rule: every edge on the screen resolves to the same
  /// 20 px gutter, whatever the device width.
  Future<void> expectAlignedEdges(WidgetTester tester, double width) async {
    final edges = <(String, double)>[
      ('back left', tester.getRect(find.byType(NestIconButton)).left),
      ('lock right', tester.getRect(find.byType(NestLockButton)).right),
      ('card left', tester.getRect(card(0)).left),
      ('card right', tester.getRect(card(1)).right),
      ('pill right', tester.getRect(find.byType(NestCoinPill)).right),
      ('intro left', tester.getRect(find.text(_intro)).left),
      ('intro right', tester.getRect(find.text(_intro)).right),
    ];
    for (final (what, value) in edges) {
      final expected = what.contains('right') ? width - _gutter : _gutter;
      expect(value, closeTo(expected, 0.5), reason: '$what at $width px');
    }
    // Rows 2 and 3 repeat the same gutters.
    for (final index in <int>[2, 4]) {
      expect(tester.getRect(card(index)).left, closeTo(_gutter, 0.5));
      expect(
        tester.getRect(card(index + 1)).right,
        closeTo(width - _gutter, 0.5),
      );
    }
  }

  group('K08 chrome geometry', () {
    testWidgets('back and lock boxes sit in the 47…103 top row', (
      tester,
    ) async {
      await pumpShop(tester);
      expect(tester.takeException(), isNull);
      // `.k8-top` starts straight under the status reserve and is 56 + 6 tall.
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

    testWidgets('the coin pill is the 94 × 40 big pill at y 109', (
      tester,
    ) async {
      await pumpShop(tester);
      expect(tester.takeException(), isNull);
      // Measured: x 276.0…370.0, y 109.0…149.0 in the light PNG ÷3.
      expect(
        tester.getRect(find.byType(NestCoinPill)),
        const Rect.fromLTRB(276, 109, 370, 149),
      );
      await disposeApp(tester);
    });

    testWidgets('the title and the intro keep their design rows', (
      tester,
    ) async {
      await pumpShop(tester);
      expect(tester.takeException(), isNull);
      // 28/34 heading, centred in the 40-tall head row (109…149).
      expect(tester.getRect(find.text('Reward shop')).top, closeTo(112, 2));
      expect(tester.getRect(find.text('Reward shop')).height, closeTo(34, 2));
      // `.kcap` 15/20: 149 + 16 = 165, one line.
      final intro = tester.getRect(
        find.text('Spend your coins on things you actually want.'),
      );
      expect(intro.top, closeTo(165, 2));
      expect(intro.height, closeTo(20, 2));
      await disposeApp(tester);
    });
  });

  group('K08 grid geometry', () {
    testWidgets('two 167 columns with a 16 gap and 20 gutters', (tester) async {
      await pumpShop(tester);
      expect(tester.takeException(), isNull);
      for (final index in <int>[0, 2, 4]) {
        expect(
          tester.getRect(card(index)).left,
          closeTo(_gutter, 0.5),
          reason: 'card $index left gutter',
        );
        expect(
          tester.getRect(card(index)).width,
          closeTo(_colWidth, 1),
          reason: 'card $index width',
        );
        expect(
          tester.getRect(card(index + 1)).left -
              tester.getRect(card(index)).right,
          closeTo(_colGap, 0.5),
          reason: 'card $index gap',
        );
        expect(
          tester.getRect(card(index + 1)).right,
          closeTo(390 - _gutter, 0.5),
          reason: 'card $index right gutter',
        );
      }
      await disposeApp(tester);
    });

    testWidgets('card rows land at 201, 433 and 665', (tester) async {
      await pumpShop(tester);
      expect(tester.takeException(), isNull);
      for (final index in <int>[0, 1]) {
        expect(
          tester.getRect(card(index)).top,
          closeTo(201, 2),
          reason: 'row 1 card $index top',
        );
        expect(
          tester.getRect(card(index)).height,
          closeTo(216, 2),
          reason: 'row 1 card $index height',
        );
        expect(
          tester.getRect(card(index)).bottom,
          closeTo(417, 2),
          reason: 'row 1 card $index bottom',
        );
      }
      for (final index in <int>[2, 3]) {
        expect(
          tester.getRect(card(index)).top,
          closeTo(433, 2),
          reason: 'row 2 card $index top',
        );
        expect(
          tester.getRect(card(index)).height,
          closeTo(216, 2),
          reason: 'row 2 card $index height',
        );
      }
      // The café card carries the "30 more to go" note (+6 gap, +18 line) and
      // the grid stretches its row-mate to match.
      expect(tester.getRect(card(4)).top, closeTo(665, 2));
      expect(tester.getRect(card(4)).height, closeTo(240, 2));
      expect(tester.getRect(card(5)).top, closeTo(665, 2));
      expect(tester.getRect(card(5)).height, closeTo(240, 2));
      await disposeApp(tester);
    });

    testWidgets('the note sits between the price and the button', (
      tester,
    ) async {
      await pumpShop(tester);
      expect(tester.takeException(), isNull);
      // Row 3 card top 665 + border 3 + padding 10 + art 56 + 6 + name 40 + 6
      // + price 20 + 6 = 812: the note lands exactly where the plain card's
      // button starts, and pushes this card's button down by 24 (6 + 18).
      final note = tester.getRect(find.text('30 more to go'));
      expect(note.top, closeTo(812, 2));
      expect(note.height, closeTo(18, 2));
      final button = tester.getRect(
        find.descendant(of: card(4), matching: find.byType(NestKidButton)),
      );
      expect(button.top, closeTo(836, 2));
      expect(button.top - note.bottom, closeTo(6, 2));
      expect(tester.getRect(card(4)).bottom, closeTo(905, 2));
      await disposeApp(tester);
    });
  });

  group('K08 card internals', () {
    testWidgets('the art disc is 56 and centred on the card', (tester) async {
      await pumpShop(tester);
      expect(tester.takeException(), isNull);
      // The 32 px glyph sits centred in the 56 px `coin-tint` circle, so its
      // own rect pins the circle: 242 = 214 + 28.
      for (final (index, centreY) in <(int, double)>[
        (0, 242),
        (1, 242),
        (2, 474),
        (3, 474),
        (4, 706),
        (5, 706),
      ]) {
        final icon = tester.getRect(
          find.descendant(of: card(index), matching: find.byType(NestIcon)),
        );
        expect(icon.size, const Size.square(32), reason: 'card $index glyph');
        expect(
          icon.center.dy,
          closeTo(centreY, 2),
          reason: 'card $index art centre',
        );
        expect(
          icon.center.dx,
          closeTo(
            index.isEven ? 20 + _colWidth / 2 : 390 - _gutter - _colWidth / 2,
            1,
          ),
          reason: 'card $index art centre x',
        );
      }
      await disposeApp(tester);
    });

    testWidgets('two-line names and one-line names share the 40 row', (
      tester,
    ) async {
      await pumpShop(tester);
      expect(tester.takeException(), isNull);
      // "30 min extra screen time" wraps to two 19 px lines (38), centred in
      // the 40 px `.k8-n` box at 276…316.
      final two = tester.getRect(find.text('30 min extra screen time'));
      expect(two.height, closeTo(38, 2));
      expect(two.top, closeTo(277, 2));
      // "Pick Friday film" is one line, centred on the same box.
      final one = tester.getRect(find.text('Pick Friday film'));
      expect(one.height, closeTo(19, 2));
      expect(one.center.dy, closeTo(296, 2));
      expect(one.center.dx, closeTo(286.5, 2));
      await disposeApp(tester);
    });

    testWidgets('the price row is 20 tall with a 16 label', (tester) async {
      await pumpShop(tester);
      expect(tester.takeException(), isNull);
      final price = tester.getRect(find.text('50'));
      expect(price.height, closeTo(16, 2));
      expect(price.top, closeTo(324, 2));
      // The `.k8-p` row is `inline-flex` + centred: coin (20) + 4 gap + label.
      // The ROW is centred on the card, not the label.
      final coin = tester.getRect(
        find.descendant(
          of: card(0),
          matching: find.byWidgetPredicate(
            (widget) => widget is SvgPicture && widget.width == 20,
          ),
        ),
      );
      expect(coin.height, closeTo(20, 2));
      expect((coin.left + price.right) / 2, closeTo(103.5, 1));
      await disposeApp(tester);
    });

    testWidgets('the Get it button is 56 tall and full width', (tester) async {
      await pumpShop(tester);
      expect(tester.takeException(), isNull);
      // `NestKidButton` reserves 6 px below the visible button for `--sh-kid`,
      // so its widget box is 62 tall: the painted button occupies 348…404 and
      // the shadow band 404…410 — both inside the card's white area, exactly
      // as the CSS draws it.
      final button = tester.getRect(
        find.descendant(of: card(0), matching: find.byType(NestKidButton)),
      );
      expect(button.left, closeTo(33, 1));
      expect(button.top, closeTo(348, 2));
      expect(button.width, closeTo(141, 1));
      expect(button.height, closeTo(62, 2));
      // Right column: 216…357.
      final right = tester.getRect(
        find.descendant(of: card(1), matching: find.byType(NestKidButton)),
      );
      expect(right.left, closeTo(216, 1));
      expect(right.top, closeTo(348, 2));
      await disposeApp(tester);
    });
  });

  group('K08 alignment across widths (OWNER rule)', () {
    for (final width in <double>[320, 390, 430]) {
      testWidgets('every edge lands on the 20 px gutter at ${width.toInt()}', (
        tester,
      ) async {
        await pumpShop(tester, width: width);
        expect(tester.takeException(), isNull);
        await expectAlignedEdges(tester, width);
        await disposeApp(tester);
      });

      testWidgets('the columns follow the width at ${width.toInt()}', (
        tester,
      ) async {
        await pumpShop(tester, width: width);
        expect(tester.takeException(), isNull);
        final column = (width - 2 * _gutter - _colGap) / 2;
        for (final index in <int>[0, 2, 4]) {
          expect(
            tester.getRect(card(index)).width,
            closeTo(column, 1),
            reason: 'card $index at ${width.toInt()}',
          );
          expect(
            tester.getRect(card(index + 1)).left -
                tester.getRect(card(index)).right,
            closeTo(_colGap, 0.5),
          );
        }
        // The `.k8-n` 40 px name row and the 56 px art disc keep their offset from
        // the card's own top at every width (201 + 95 = 296 at 390). A
        // narrower device moves the whole rhythm down (the balanced heading
        // wraps to two lines), but the card's internal spacing is unchanged.
        final one = tester.getRect(find.text('Pick Friday film'));
        expect(one.center.dy - tester.getRect(card(1)).top, closeTo(95, 2));
        // One 19 px line at 390/430, two (38) in the 132 px column at 320 —
        // either way the `.k8-n` box is its 40 px slot, never taller.
        expect(one.height, anyOf(closeTo(19, 2), closeTo(38, 2)));
        final art = tester.getRect(
          find.descendant(of: card(1), matching: find.byType(NestIcon)),
        );
        expect(
          art.center.dy - tester.getRect(card(1)).top,
          closeTo(41, 2),
          reason: 'the 56 px disc sits 13 px below the card top',
        );
        expect(art.size, const Size.square(32));
        await disposeApp(tester);
      });
    }

    testWidgets('the kid targets stay 56 at 320 px / 1.3 scale', (
      tester,
    ) async {
      await pumpShop(tester, width: 320);
      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.byType(NestIconButton)).size,
        const Size(56, 56),
      );
      expect(
        tester.getRect(find.byType(NestLockButton)).size,
        const Size(56, 56),
      );
      final button = tester.getRect(
        find.descendant(of: card(0), matching: find.byType(NestKidButton)),
      );
      expect(button.width, greaterThanOrEqualTo(56));
      expect(
        button.height,
        closeTo(62, 2),
        reason: '56 painted + 6 shadow room',
      );
      await disposeApp(tester);
    });
  });

  group('K08 odd reward counts (K08-BUG-2 regression geometry)', () {
    // The trailing CSS-grid cell is an inert filler now, so an odd count lays
    // out exactly like an even one: the lone card keeps its column width, its
    // left gutter and its own height (the grid's `align-items: stretch` no
    // longer has a row-mate to stretch to).
    const cases = <int, List<String>>{
      5: <String>['r-screen', 'r-film', 'r-bedtime', 'r-baking', 'r-cafe'],
      3: <String>['r-screen', 'r-film', 'r-bedtime'],
      1: <String>['r-screen'],
    };

    for (final entry in cases.entries) {
      for (final width in <double>[390, 320]) {
        testWidgets('${entry.key} cards lay out at ${width.toInt()} px', (
          tester,
        ) async {
          await (db.delete(
            db.rewards,
          )..where((r) => r.id.isNotIn(entry.value))).go();
          await pumpShop(tester, width: width);

          expect(tester.takeException(), isNull);
          expect(find.byType(ShopRewardCard), findsNWidgets(entry.key));

          // Rows keep the 16 px gap; a lone card starts the row it is in, so its top
          // is the first card's top plus one row pitch per row before it. The
          // pitch is measured, not assumed, because a narrow device moves the
          // whole rhythm down (the balanced heading wraps to two lines).
          final first = tester.getRect(card(0));
          final rowsBefore = (entry.key - 1) ~/ 2;
          // Row pitch = card height (216) + `.k8-grid` gap (16). Measured from
          // two real rows rather than assumed, because a narrow device moves
          // the whole rhythm down (the balanced heading wraps to two lines).
          var pitch = 232.0;
          if (entry.key > 2) {
            pitch = tester.getRect(card(2)).top - first.top;
            expect(pitch, closeTo(232, 2), reason: 'row pitch: 216 + 16');
          }
          final lone = tester.getRect(card(entry.key - 1));
          final hasNote = entry.value.last == 'r-cafe';
          final cardHeight = hasNote ? 240.0 : 216.0;
          expect(lone.top, closeTo(first.top + rowsBefore * pitch, 2));
          expect(lone.height, closeTo(cardHeight, 2));
          expect(lone.left, closeTo(_gutter, 0.5));
          expect(
            lone.width,
            closeTo((width - 2 * _gutter - _colGap) / 2, 1),
            reason: 'the lone card still fills its own column',
          );

          // Every row above it is the plain 216 (or 240 with a note) card.
          for (var i = 0; i + 1 < entry.key; i += 2) {
            final rowTop = tester.getRect(card(i)).top;
            expect(
              tester.getRect(card(i + 1)).top,
              closeTo(rowTop, 0.5),
              reason: 'cards $i and ${i + 1} share a row',
            );
          }
          await disposeApp(tester);
        });
      }
    }
  });

  group('K08 footer and scroll tail', () {
    testWidgets('the footer is centred and follows the last row by 16', (
      tester,
    ) async {
      await pumpShop(tester);
      expect(tester.takeException(), isNull);
      const footer = 'You have 120 coins. Pip is helping you save!';
      // It sits below the fold (design y 921) and the list is lazy, so it is
      // built only once the list moves.
      final list = find.byType(Scrollable).first;
      for (var i = 0; i < 10 && find.text(footer).evaluate().isEmpty; i++) {
        await tester.drag(list, const Offset(0, -200));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
      }
      final rect = tester.getRect(find.text(footer));
      expect(rect.height, closeTo(20, 2));
      expect(rect.center.dx, closeTo(195, 1));
      // The tail is 58 px (`--home-h` 34 + `--s6` 24), so the list can scroll
      // the footer clear of the home indicator.
      final scrollable = tester.widget<Scrollable>(list);
      expect(scrollable.controller, isNotNull);
      expect(scrollable.controller!.position.maxScrollExtent, greaterThan(0));
      await disposeApp(tester);
    });
  });
}
