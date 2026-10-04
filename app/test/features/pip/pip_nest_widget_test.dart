// K06 geometry: every painted rect against the design PNG.
//
// Numbers were measured off `design/screens/light/K06-pip.png` (1170x2532,
// divided by 3) and cross-checked against the CSS box model of
// `design/html-source/screens/K06-pip.html` — the two agree to the pixel, so
// these are the design's own positions, not guesses:
//
//   status bar      0 – 47                      (--status-h)
//   .k6-top         y 47, 56 tall, +4 padding   -> scroll starts at 107
//   .k6-name        y 107 – 141                 (kid-title 28/34)
//   .k6-pet         y 150 – 356                 (margin-top 9, 230x206)
//   .k6-grow        y 372 – 486                 (s4 gap, 114 tall)
//   .k6-care        y 502 – 593                 (s4 gap, 91 tall)
//   .k6-sec         y 609 – 635                 (s4 gap, 20/26)
//   .k6-ward        y 651 – 767                 (s4 gap, 116 tall)
//   caption         y 783 – 803                 (s4 gap, 15/20)
//
// The bundled faces are loaded first: `flutter test`'s default placeholder
// glyphs are one em wide, which would change every measured text box (the
// same reason `k01_copy_fit_test.dart` loads them).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_growth_card.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_wardrobe_tile.dart';

import '../../test_scope.dart';

/// The design's 20 px side gutters and 390 px width.
const double _side = NestSpacing.padSide;
const double _width = NestDevice.width;

/// Tolerance for one measurement (a design-pixel round trip).
const double _tol = 1.5;

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

void _expectRect(
  Rect actual,
  double l,
  double t,
  double w,
  double h,
  String what,
) {
  expect(actual.left, closeTo(l, _tol), reason: '$what left');
  expect(actual.top, closeTo(t, _tol), reason: '$what top');
  expect(actual.width, closeTo(w, _tol), reason: '$what width');
  expect(actual.height, closeTo(h, _tol), reason: '$what height');
}

void main() {
  setUpAll(loadBundledFonts);

  setUp(() async {
    await setUpTestScope();
  });

  testWidgets('every painted rect sits on its design position', (tester) async {
    await pumpAppRoute(tester, '/pip');

    // `.k6-top`: 56 px back tile at the left gutter, lock at the right.
    _expectRect(
      tester.getRect(find.byKey(const Key('k06-back'))),
      _side,
      NestDevice.statusH,
      NestDevice.tapKid,
      NestDevice.tapKid,
      'back button',
    );
    _expectRect(
      tester.getRect(find.byKey(const Key('k06-lock'))),
      _width - _side - NestDevice.tapKid,
      NestDevice.statusH,
      NestDevice.tapKid,
      NestDevice.tapKid,
      'grown-ups lock',
    );

    // `.k6-name`: kid-title 28/34 directly under the 4 px top-row padding.
    final title = tester.getRect(find.byKey(const Key('k06-title')));
    _expectRect(title, _side, 107, _width - 2 * _side, 34, 'title');

    // `.k6-pet`: its own `margin: 9px auto 0` (not the s4 sibling margin).
    final pet = tester.getRect(find.byKey(const Key('k06-pet')));
    _expectRect(pet, 80, title.bottom + 9, 230, 206, 'pet slot');

    // `.k6-grow`: 3 px border, 12x14 padding, 30/10/16/8/20 of content.
    final grow = tester.getRect(find.byType(PipGrowthCard));
    _expectRect(
      grow,
      _side,
      pet.bottom + NestSpacing.s4,
      _width - 2 * _side,
      114,
      'growth card',
    );

    // `.k6-care`: three equal columns with 12 px gaps.
    //
    // The visible painted care button (the 91 px design band) is the
    // AnimatedContainer inside the shared NestKidButton's key; the outer
    // NestKidButton rectangle additionally carries the shared 6 px bottom
    // gap to make space for the pressed / shadowed state.
    final care = tester.getRect(
      find
          .descendant(
            of: find.byType(NestKidButton).first,
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect(care.top, closeTo(grow.bottom + NestSpacing.s4, _tol));
    expect(care.height, closeTo(91, _tol));
    expect(care.left, closeTo(_side, _tol));
    // (350 - 2 × 12) / 3 = 108.67 at the design width.
    expect(care.width, closeTo((_width - 2 * _side - 2 * 12) / 3, _tol));
    final play = tester.getRect(
      find
          .descendant(
            of: find.byType(NestKidButton).at(1),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect(play.left, closeTo(care.right + 12, _tol));
    final bath = tester.getRect(
      find
          .descendant(
            of: find.byType(NestKidButton).at(2),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    expect(bath.left, closeTo(play.right + 12, _tol));
    expect(bath.right, closeTo(_width - _side, _tol));

    // `.k6-sec`: 20/26 heading, `s4` below the care row.
    final section = tester.getRect(find.byKey(const Key('k06-section')));
    _expectRect(
      section,
      _side,
      care.bottom + NestSpacing.s4,
      _width - 2 * _side,
      26,
      "Pip's wardrobe heading",
    );

    // `.k6-ward`: four equal tiles, 12 px gaps, 116 tall.
    final tile = tester.getRect(find.byKey(const Key('k06-ward-scarf')));
    _expectRect(
      tile,
      _side,
      section.bottom + NestSpacing.s4,
      78.5,
      kPipWardrobeTileHeight,
      'wardrobe tile',
    );
    final sunhat = tester.getRect(find.byKey(const Key('k06-ward-sunhat')));
    expect(sunhat.left, closeTo(tile.right + 12, _tol));
    final wellies = tester.getRect(find.byKey(const Key('k06-ward-wellies')));
    expect(wellies.left, closeTo(sunhat.right + 12, _tol));
    final crown = tester.getRect(find.byKey(const Key('k06-ward-crown')));
    expect(crown.left, closeTo(wellies.right + 12, _tol));
    expect(crown.right, closeTo(_width - _side, _tol));

    // Centred caption on the design's 15/20 line.
    final caption = tester.getRect(find.byKey(const Key('k06-caption')));
    _expectRect(
      caption,
      _side,
      tile.bottom + NestSpacing.s4,
      _width - 2 * _side,
      20,
      'caption',
    );
    await disposeApp(tester);
  });

  testWidgets('the design gutters are identical for every row', (tester) async {
    // Owner ALIGNMENT rule: cards and bars align to the same edges.
    await pumpAppRoute(tester, '/pip');

    // Full-width rows share both 20 px gutters; the care row's first and
    // last columns own them (each button is a third of the content width).
    final rect = tester.getRect(find.byType(PipGrowthCard));
    expect(rect.left, closeTo(_side, _tol));
    expect(rect.right, closeTo(_width - _side, _tol));
    expect(
      tester.getRect(find.byKey(const Key('k06-feed'))).left,
      closeTo(_side, _tol),
    );
    expect(
      tester.getRect(find.byKey(const Key('k06-bath'))).right,
      closeTo(_width - _side, _tol),
    );
    // Every wardrobe tile shares the same top and bottom edge.
    final tops = <double>[];
    for (final id in const <String>['scarf', 'sunhat', 'wellies', 'crown']) {
      final rect = tester.getRect(find.byKey(Key('k06-ward-$id')));
      tops.add(rect.top);
      expect(rect.height, closeTo(kPipWardrobeTileHeight, _tol));
    }
    for (final top in tops) {
      expect(top, closeTo(tops.first, _tol));
    }
    await disposeApp(tester);
  });

  testWidgets(
    'the nest art box is the design 230 x 206 slot box, letterboxed not '
    'stretched',
    (tester) async {
      // `.k6-pet .nest { width:230px; height:206px }` (K06-pip.html). The
      // design PNG confirms the UNIFORM 206/240 scale: its widest painted row
      // is logical y 277.7 and spans 163 px (`202 units x 206/240`), where a
      // 230-stretched box would draw 194 px. Painting it square (K06-BUG-4)
      // moved the rim ~12 px off the design.
      await pumpAppRoute(tester, '/pip');

      final nest = find
          .descendant(
            of: find.byKey(const Key('k06-pet')),
            matching: find.byType(SvgPicture),
          )
          .first;
      expect(tester.getSize(nest), const Size(230, 206));
      // The art box is the slot box, sharing its bottom edge — the design's
      // `bottom: 0`.
      final slot = tester.getRect(find.byKey(const Key('k06-pet')));
      expect(tester.getRect(nest).bottom, closeTo(slot.bottom, _tol));
      expect(
        tester.getRect(nest).left,
        closeTo(slot.center.dx - 230 / 2, _tol),
      );
      await disposeApp(tester);
    },
  );

  testWidgets('the three care buttons share one height at text scale 1.3', (
    tester,
  ) async {
    // `.k6-care` is a flex row with the default `align-items: stretch`, so
    // all three `.btn-kid` columns take the tallest one's height (K06-BUG-5).
    // `IntrinsicHeight` + `CrossAxisAlignment.stretch` is what supplies it
    // inside the unbounded `ListView`.
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpAppRoute(tester, '/pip');

    final heights = <double>[
      for (final id in const <String>['k06-feed', 'k06-play', 'k06-bath'])
        tester.getRect(find.byKey(Key(id))).height,
    ];
    expect(heights.toSet(), hasLength(1), reason: 'measured $heights');
    // They still share a top and a bottom, i.e. they stay aligned with each
    // other (owner ALIGNMENT rule).
    final tops = <double>[
      for (final id in const <String>['k06-feed', 'k06-play', 'k06-bath'])
        tester.getRect(find.byKey(Key(id))).top,
    ];
    expect(tops.toSet(), hasLength(1), reason: 'measured $tops');
    await disposeApp(tester);
  });

  testWidgets(
    'the locked tiles dash their border IN FRONT of the fill, and every art '
    'circle still lands on the same inset',
    (tester) async {
      // K06-BUG-6: the screen-local dashed stroke used to be a background
      // `CustomPaint.painter`, so the tile's own opaque `surface-2` fill
      // covered it completely and the locked slot read as a borderless card
      // (the UI stage's D1, in both themes). It is a `foregroundPainter` now,
      // which is also what the pixel proof in `k06_bugs_test.dart` reads.
      await pumpAppRoute(tester, '/pip');

      for (final id in const <String>['wellies', 'crown']) {
        final paint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byKey(Key('k06-ward-$id')),
            matching: find.byType(CustomPaint),
          ),
        );
        expect(
          paint.foregroundPainter,
          isNotNull,
          reason: '$id must stroke its border above the fill',
        );
        expect(paint.painter, isNull, reason: '$id has no background painter');
      }

      // `.k6-item-art`: 52 px circle, and the owned tile's solid border and
      // the locked tile's reserved dashed band occupy the same 3 px, so the
      // circles must still share one left inset and one width.
      Rect artOf(String id) => tester.getRect(
        find.descendant(
          of: find.byKey(Key('k06-ward-$id')),
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.constraints?.maxHeight == kPipWardrobeArtSize &&
                w.decoration is BoxDecoration,
          ),
        ),
      );

      final ownedArt = artOf('scarf');
      final ownedTile = tester.getRect(find.byKey(const Key('k06-ward-scarf')));
      for (final id in const <String>['sunhat', 'wellies', 'crown']) {
        final art = artOf(id);
        expect(
          art.width,
          closeTo(kPipWardrobeArtSize, _tol),
          reason: '$id art',
        );
        expect(
          art.left - tester.getRect(find.byKey(Key('k06-ward-$id'))).left,
          closeTo(ownedArt.left - ownedTile.left, _tol),
          reason: '$id art circle must sit on the same inset as Scarf',
        );
      }
      await disposeApp(tester);
    },
  );
}
