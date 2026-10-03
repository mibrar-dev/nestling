// P05 · Add children — production-metrics proofs for the view layer.
//
// These run with the BUNDLED Inter/Nunito faces loaded via `FontLoader` (the
// pattern from `test/design_system/nest_balanced_text_test.dart`), so the
// measurements are the ones a device renders, not the wider fallback test
// font that `add_children_test.dart` deliberately uses. They answer
// FIXES_7 item 1 ("4-6 ≈ 54 px, 7-9, 10-12, 13+") and the owner rule that a UI
// check measures the visible BACKGROUND/BORDER rect of a pill, chip, field and
// card — not only where the text lands.
//
// Every expectation is derived from `design/html-source/components.css`:
//   `.chip { height: 32px; padding: 0 14px; gap 8px }` (`.chip-row`)
//   `.scroll { padding: 0 20px }`, `.form-card { padding: 14px }`
// so the widths below are `text + 28` measured in the shipped font.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/family/presentation/widgets/add_child_form_card.dart';
import 'package:nestling/features/family/presentation/widgets/child_display.dart';
import 'package:nestling/features/family/presentation/widgets/kid_card_grid.dart';

import '../../test_scope.dart';

Future<void> _loadBundledFonts() async {
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
  setUpAll(_loadBundledFonts);

  group('P05 age-band pills with the shipped faces', () {
    // `.chip { padding: 0 14px }` around Inter 14/600 text, measured from the
    // bundled faces (the chip label is Inter, not Nunito — `NestType.chipLabel`).
    const widths = <String, double>{
      '4-6': 53.28,
      '7-9': 52.02,
      '10-12': 64.8,
      '13+': 52.25,
    };

    testWidgets('each pill is text + 28 wide and 32 high', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      for (final band in AddChildFormCard.ageBands) {
        final pill = tester.getRect(find.byKey(Key('ageChip-$band')));
        final text = tester.getRect(find.text(displayAgeBand(band)));

        expect(
          pill.width,
          closeTo(widths[band]!, 0.5),
          reason:
              '$band pill width — a collapsed text-width pill is the '
              'FIXES_7 regression this file guards',
        );
        expect(pill.height, NestSpacing.s8, reason: '$band: .chip height');
        expect(
          pill.width - text.width,
          closeTo(NestSpacing.gap14 * 2, 0.5),
          reason: '$band: `.chip { padding: 0 14px }`',
        );
      }

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the painted pill fills the chip box (no narrow fill, no '
        'border outside it)', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      for (final band in AddChildFormCard.ageBands) {
        final pill = tester.getRect(find.byKey(Key('ageChip-$band')));
        final paint = tester.getRect(
          find
              .descendant(
                of: find.byKey(Key('ageChip-$band')),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect(paint, pill, reason: '$band background/border rect');
      }

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('one row, left-aligned on the card content edge, 8 px gaps', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      final pills = <String, Rect>{
        for (final band in AddChildFormCard.ageBands)
          band: tester.getRect(find.byKey(Key('ageChip-$band'))),
      };
      // `.chip-row { display: flex; gap: 8px }` — production fits one run.
      expect(pills.values.map((r) => r.top).toSet(), hasLength(1));
      expect(
        pills.values.first.left,
        NestSpacing.padSide + NestSpacing.gap14,
        reason: 'the row starts on the card content edge',
      );

      final ordered = pills.values.toList()
        ..sort((a, b) => a.left.compareTo(b.left));
      for (var i = 1; i < ordered.length; i++) {
        expect(
          ordered[i].left - ordered[i - 1].right,
          closeTo(NestSpacing.s2, 0.5),
          reason: '8 px gap between chips',
        );
      }
      // The whole row stays inside the card's content width.
      final contentRight =
          tester.getRect(find.byType(NestCard).last).right - NestSpacing.gap14;
      expect(
        ordered.last.right,
        lessThanOrEqualTo(contentRight),
        reason: 'the row does not overflow the card content edge',
      );

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  testWidgets('the h1 is one 34-px line in the shipped Nunito and its band '
      'shares the 20 px gutters', (tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    await setUpTestScope();
    await pumpAppRoute(tester, '/add-children');

    // `.h1 { font-size 28px; line-height 34px; text-wrap: balance }`.
    final text = tester.getRect(find.text('Who\u2019s in your nest?'));
    expect(text.height, 34, reason: 'one balanced line, not a wrapped pair');

    // `NestBalancedText` keeps the screen position: its box still fills the
    // gutters like every other band (owner alignment rule).
    final band = tester.getRect(find.byType(NestBalancedText));
    final grid = tester.getRect(find.byType(KidCardGrid));
    expect(band.left, NestSpacing.padSide);
    expect(band.right, grid.right);
    expect(band.height, text.height);

    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });
}
