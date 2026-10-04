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
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_care_button.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_growth_card.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_nest_slot.dart';
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
    _expectRect(
      pet,
      80,
      title.bottom + 9,
      kPipSlotWidth,
      kPipSlotHeight,
      'pet slot',
    );

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

    // `.k6-care`: three equal columns with 12 px gaps, 90 tall.
    final care = tester.getRect(find.byType(PipCareButton).first);
    expect(care.top, closeTo(grow.bottom + NestSpacing.s4, _tol));
    expect(care.height, closeTo(kPipCareButtonHeight, _tol));
    expect(care.left, closeTo(_side, _tol));
    // (350 - 2 × 12) / 3 = 108.67 at the design width.
    expect(care.width, closeTo((_width - 2 * _side - 2 * 12) / 3, _tol));
    final play = tester.getRect(find.byType(PipCareButton).at(1));
    expect(play.left, closeTo(care.right + 12, _tol));
    final bath = tester.getRect(find.byType(PipCareButton).at(2));
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
}
