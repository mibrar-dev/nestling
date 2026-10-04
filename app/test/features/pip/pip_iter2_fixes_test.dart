// K06 · Pip's nest — the iteration-2 UI fixes (K06-BUG-3…6, `4_review.md`
// #11) at the layer `pip_nest_widget_test.dart` and `pip_copy_parity_test.dart`
// do not work at, plus the one behaviour the fixes leave open.
//
// Each group names what it pins:
//   * BUG-4 — the nest art's BOX is pinned by 2b; its FIT is not. A box-only
//     proof still passes with `BoxFit.fill`, which is exactly what the bug was.
//   * BUG-5 — 2b pins equal heights at 390/1.3×. The risk the fix introduces is
//     the design's own metric: `IntrinsicHeight` must not move the 91 px row
//     at scale 1.0, and all three buttons must stay equal at EVERY width and
//     both scales, not just one.
//   * #11 — the progress bar now announces the design's own aria wording, so
//     the copy oracle can compare it with the HTML instead of documenting the
//     difference.
//   * OPEN — a purchase refused by the DATABASE (not the bloc's cached
//     pre-check) answers a tap with silence. Parked, repro in the group.
//
// Real fonts are loaded first: the placeholder glyphs are one em wide and would
// wrap the care labels, which is what made the heights differ in the first
// place.

import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipStage;
import 'package:nestling/features/pip/presentation/bloc/pip_bloc.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_care_button.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_nest_slot.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_wardrobe_tile.dart';

import '../../test_scope.dart';

const double _tol = 1.5;

/// The design's `.k6-care .btn-kid` painted height (PNG ÷3: y 502 – 593).
const double _designCareHeight = 91;

/// Repaint boundary the pixel probe samples (an `SvgPicture` is not one).
const Key _pixelProbe = ValueKey<String>('k06_iter2_pixel_probe');

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

/// Bounded pumps: the loading spinner never settles.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _pumpNest(
  WidgetTester tester, {
  double width = NestDevice.width,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await pumpAppRoute(tester, '/pip', theme: theme);
  // `pumpAppRoute` pins 390x844 itself, so the surface is applied after.
  tester.view.physicalSize = Size(width * 3, NestDevice.height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pump();
  expect(
    tester.view.physicalSize.width / tester.view.devicePixelRatio,
    width,
    reason: 'this test must really run at $width logical px',
  );
}

/// The three care buttons' heights, in design order.
List<double> _careHeights(WidgetTester tester) => <double>[
  for (final id in const <String>['k06-feed', 'k06-play', 'k06-bath'])
    tester.getRect(find.byKey(Key(id))).height,
];

void main() {
  late AppDatabase db;

  setUpAll(loadBundledFonts);

  setUp(() async {
    db = await setUpTestScope();
  });

  group('K06-BUG-4 — the nest art box AND its fit', () {
    testWidgets('the art is contained, not stretched into the box', (
      tester,
    ) async {
      // `nest.svg` is a square `viewBox="0 0 240 240"`. The design's `<img>`
      // box is 230 x 206, so a browser fits the art UNIFORMLY (206 wide,
      // letterboxed 12 px each side). `BoxFit.fill` in that box is what made
      // the bowl 12 % too wide and 24 px too tall — and a box-only assertion
      // cannot tell the two apart.
      await _pumpNest(tester);

      final art = find
          .descendant(
            of: find.byKey(const Key('k06-pet')),
            matching: find.byType(SvgPicture),
          )
          .first;
      final picture = tester.widget<SvgPicture>(art);
      expect(picture.fit, BoxFit.contain);
      expect(
        tester.getSize(art),
        const Size(kPipNestArtWidth, kPipNestArtHeight),
      );

      // The visible art is the square inscribed in the box, centred: 206 wide
      // in a 230 box is 12 px of letterbox on each side.
      final slot = tester.getRect(find.byKey(const Key('k06-pet')));
      expect(
        slot.width - kPipNestArtHeight,
        closeTo(24, _tol),
        reason: 'a uniform 206/240 scale leaves 12 px each side',
      );
      await disposeApp(tester);
    });

    testWidgets('the painted nest is ~173 px wide and centred (paint level)', (
      tester,
    ) async {
      // The box and the fit can both be right while the art sits off-centre
      // inside the box, so this reads the pixels. `SvgPicture` is not itself a
      // repaint boundary, so the screen is pumped inside one (the
      // `k06_bugs_test.dart` idiom) and the slot's global rect is mapped into
      // that image.
      //
      // The design PNG's widest painted row is 173.3 px
      // (`202 units x 206/240`), centred on the slot's axis; a stretched
      // 230-wide draw would be ~194 px.
      tester.view.physicalSize = const Size(
        NestDevice.width * 3,
        NestDevice.height * 3,
      );
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const RepaintBoundary(
          key: _pixelProbe,
          child: NestlingApp(initialRoute: '/pip'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      const slotKey = Key('k06-pet');
      final slot = tester.getRect(find.byKey(slotKey));
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(_pixelProbe),
      );
      var minX = slot.width;
      var maxX = -1.0;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = (await image.toByteData())!;
        final left = slot.left.round();
        final top = slot.top.round();
        final w = slot.width.round();
        final h = slot.height.round();

        List<int> pixel(int x, int y) {
          final o = ((top + y) * image.width + (left + x)) * 4;
          return <int>[
            data.getUint8(o),
            data.getUint8(o + 1),
            data.getUint8(o + 2),
          ];
        }

        // `.k6-pet .nest` is 230 wide with the square art letterboxed 12 px
        // each side, so x = 2 of the slot is bare sky in both themes. "Painted"
        // then means "differs from the sky", which works in light and dark
        // without guessing at a colour.
        //
        // Scanned BELOW the Pip: the Pip overhangs the slot to y 125, and the
        // nest's widest row is at y ~128 (design PNG), so rows 126…206 are
        // bowl only.
        for (var y = 126; y < h; y++) {
          final sky = pixel(2, y);
          for (var x = 12; x < w - 12; x++) {
            final c = pixel(x, y);
            final delta =
                (c[0] - sky[0]).abs() +
                (c[1] - sky[1]).abs() +
                (c[2] - sky[2]).abs();
            if (delta > 40) {
              if (x < minX) minX = x.toDouble();
              if (x > maxX) maxX = x.toDouble();
            }
          }
        }
        image.dispose();
      });

      expect(maxX, greaterThan(minX), reason: 'the bowl was painted');
      expect(
        maxX - minX + 1,
        closeTo(173.4, 8),
        reason: "202 of the SVG's 240 units at the 206/240 scale",
      );
      expect(
        (minX + maxX) / 2,
        closeTo(slot.width / 2, 8),
        reason: 'the art stays centred in the box',
      );
      await disposeApp(tester);
    });
  });

  group('K06-BUG-5 — equal heights without moving the design', () {
    for (final textScale in const <double>[1, 1.3]) {
      testWidgets('@${textScale}x: all three buttons share one height', (
        tester,
      ) async {
        await _pumpNest(tester, textScale: textScale);

        final heights = _careHeights(tester);
        expect(heights.toSet(), hasLength(1), reason: 'measured $heights');
        // Owner ALIGNMENT rule: one top and one bottom edge for the row.
        final tops = <double>[
          for (final id in const <String>['k06-feed', 'k06-play', 'k06-bath'])
            tester.getRect(find.byKey(Key(id))).top,
        ];
        expect(tops.toSet(), hasLength(1), reason: 'measured $tops');
        await disposeApp(tester);
      });
    }

    testWidgets('at the design scale the row is still exactly 91 px', (
      tester,
    ) async {
      // The risk `IntrinsicHeight` introduces: the row takes its height from
      // the tallest child instead of the 91 px floor. At 390/1.0× the design
      // says 91 (PNG y 502 – 593), so that must not drift.
      await _pumpNest(tester);

      final heights = _careHeights(tester);
      expect(
        heights.first,
        closeTo(_designCareHeight, _tol),
        reason: '$heights',
      );
      expect(
        heights.first,
        closeTo(kPipCareButtonHeight, _tol),
        reason: 'and the token the widget floors at stays the same number',
      );
      await disposeApp(tester);
    });

    for (final width in const <double>[320, 430]) {
      for (final textScale in const <double>[1, 1.3]) {
        testWidgets(
          '${width.toInt()}px @${textScale}x: still one height, still >= 56',
          (tester) async {
            await _pumpNest(tester, width: width, textScale: textScale);

            final heights = _careHeights(tester);
            expect(heights.toSet(), hasLength(1), reason: 'measured $heights');
            for (final height in heights) {
              expect(height, greaterThanOrEqualTo(NestDevice.tapKid));
            }
            await disposeApp(tester);
          },
        );
      }
    }

    testWidgets('a held press does not change the row height', (tester) async {
      // `PipCareButton` presses by translating 4 px inside an
      // `AnimatedContainer`. Inside `IntrinsicHeight` + stretch, a press must
      // stay a pure transform: if the animation ever fed back into layout, the
      // held button would resize and the row would lose its one height.
      await _pumpNest(tester, textScale: 1.3);
      final before = _careHeights(tester);
      expect(before.toSet(), hasLength(1), reason: 'resting: $before');

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const Key('k06-play'))),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(
        _careHeights(tester).toSet(),
        hasLength(1),
        reason: 'held press: ${_careHeights(tester)}',
      );
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 200));
      expect(_careHeights(tester).toSet(), hasLength(1), reason: 'released');
      await disposeApp(tester);
    });
  });

  group('4_review.md #11 — the progress bar announces the design wording', () {
    String designAria() {
      var dir = Directory.current.absolute;
      for (var depth = 0; depth < 5; depth++) {
        final candidate = File(
          '${dir.path}/design/html-source/screens/K06-pip.html',
        );
        if (candidate.existsSync()) {
          final match = RegExp(
            'class="progress kid" role="img" aria-label="([^"]*)"',
          ).firstMatch(candidate.readAsStringSync());
          if (match != null) return match.group(1)!;
        }
        final parent = dir.parent;
        if (parent.path == dir.path) break;
        dir = parent;
      }
      throw StateError('K06 design source not found');
    }

    testWidgets('the label is the design aria-label with the row percentage', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpNest(tester);

      // `.progress kid` aria-label: "Pip is 70% of the way to Songbird".
      final aria = designAria();
      expect(aria, 'Pip is 70% of the way to Songbird');
      // Same words, the design's 70 replaced by Maya's 175/250 = 70 %. The
      // oracle is the HTML's own aria string with only the number generalised,
      // so a future edit to the screen's wording cannot pass.
      //
      // Matched unanchored and by pattern on purpose: the shared
      // `NestProgress` sits inside the growth card's merged semantics node and
      // carries a `value` as well, so neither an exact label nor a `^`-anchored
      // one can hit it.
      expect(
        find.bySemanticsLabel(
          RegExp(RegExp.escape(aria).replaceAll('70%', r'\d+%')),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Pip is 70% of the way to Songbird')),
        findsOneWidget,
        reason: 'and the number really is the row percentage (175/250)',
      );
      // The article and the spelled-out "percent" that #11 removed must not
      // creep back into the LABEL ("…a Songbird"). The shared component's own
      // `value` still says "<n> percent" — that is core's, not K06's copy.
      expect(find.bySemanticsLabel(RegExp('way to a Songbird')), findsNothing);
      expect(
        find.bySemanticsLabel(RegExp('way to an Egg|way to a Hatchling')),
        findsNothing,
      );
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('OPEN — a purchase the DATABASE refuses answers nothing', () {
    testWidgets(
      'K06-BUG-7: the tile that lost the race must still say why',
      (tester) async {
        // Two locked tiles tapped in one burst, both inside the balance the
        // bloc has cached: Wellies (40) and Crown (120) against 120 coins.
        // The database can only honour one (K06-BUG-2's fix is exactly that).
        // The refused tile is the same "not enough coins yet" condition the
        // screen already has copy for (`kPipNotEnoughCoins`), but the refusal
        // happens BELOW the bloc's cached pre-check, so no error is ever
        // raised and the tap is answered with silence.
        await _pumpNest(tester);

        // Both taps land in the same frame, so both handlers run against the
        // same cached balance of 120.
        await tester.tap(find.byKey(const Key('k06-ward-wellies')));
        await tester.tap(find.byKey(const Key('k06-ward-crown')));
        await _settle(tester);

        // Exactly one purchase, and the money agrees (the fix works).
        final owned = <bool>[
          for (final item in const <String>['wellies', 'crown'])
            (await (db.select(db.pipWardrobe)..where(
                      (w) => w.childId.equals('maya') & w.item.equals(item),
                    ))
                    .getSingle())
                .owned,
        ];
        expect(owned.where((o) => o).length, 1, reason: 'one purchase only');
        final row = await (db.select(
          db.children,
        )..where((c) => c.id.equals('maya'))).getSingle();
        expect(row.coins, greaterThanOrEqualTo(0));

        // …but the child who tapped the other tile was told nothing at all.
        expect(
          find.text(kPipNotEnoughCoins),
          findsOneWidget,
          reason:
              'the refused tile owes the same explanation as any other '
              'unaffordable buy',
        );
        await disposeApp(tester);
      },
      skip: true, // K06-BUG-7 — parked; see docs/screens/K06/3_test.md §4.
    );
  });

  group('the fixes did not disturb the rest of the screen', () {
    testWidgets('the wardrobe strip is still four tiles in design order', (
      tester,
    ) async {
      await _pumpNest(tester);
      final tiles = find.byType(PipWardrobeTile);
      expect(tiles, findsNWidgets(4));
      expect(
        tester
            .widgetList<PipWardrobeTile>(tiles)
            .map((tile) => tile.item.id)
            .toList(),
        <String>['scarf', 'sunhat', 'wellies', 'crown'],
      );
      await disposeApp(tester);
    });

    testWidgets('the care buttons keep their own semantics', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpNest(tester);
      for (final label in const <String>[
        'Feed Pip, costs 5 coins',
        'Play with Pip, free',
        'Bathe Pip, costs 3 coins',
      ]) {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: label,
        );
      }
      expect(find.byType(PipCareButton), findsNWidgets(3));
      semantics.dispose();
      await disposeApp(tester);
    });
  });
}
