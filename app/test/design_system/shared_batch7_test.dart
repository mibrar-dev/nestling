// Shared batch 7 (K06 SHARED_REQUEST §§1,2,3,5,6):
// - wardrobeScarf / wardrobeWellies exact K06 glyphs (new names, old untouched)
// - seed wellies 30 / crown 60 (design mirrors)
// - NestPetStage K06 slot (slotHeight / pipBottom / nestFit / showGlow /
//   showGroundShadow, defaults unchanged)
// - NestKidButton trailing third row (defaults unchanged)
// - NestDashedBorder 3 px dashed ink-2, dash 6 / gap 3, r-l radius

import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

String _readIcon(String file) => File('assets/icons/$file').readAsStringSync();

Future<int?> _wardrobePrice(AppDatabase db, String child, String item) async {
  final row =
      await (db.select(db.pipWardrobe)
            ..where((w) => w.childId.equals(child) & w.item.equals(item)))
          .getSingleOrNull();
  return row?.priceCoins;
}

void main() {
  group('Shared batch 7 wardrobe glyphs (K06 §5)', () {
    test('asset constants point at the new files, old untouched', () {
      expect(NestIcons.wardrobeScarf, 'assets/icons/ic_wardrobe_scarf.svg');
      expect(NestIcons.wardrobeWellies, 'assets/icons/ic_wardrobe_wellies.svg');
      expect(NestlingIcons.wardrobeScarf, 'assets/icons/ic_wardrobe_scarf.svg');
      expect(
        NestlingIcons.wardrobeWellies,
        'assets/icons/ic_wardrobe_wellies.svg',
      );
      // Existing look-alikes other screens use are unchanged.
      expect(NestIcons.scarf, 'assets/icons/ic_scarf.svg');
      expect(NestIcons.wellies, 'assets/icons/ic_wellies.svg');
      expect(NestIcons.sunHat, 'assets/icons/ic_sun_hat.svg');
      expect(NestIcons.crown, 'assets/icons/ic_crown.svg');
    });

    test('ic_wardrobe_scarf.svg is the exact K06 design glyph', () {
      final svg = _readIcon('ic_wardrobe_scarf.svg');
      expect(svg, contains('currentColor'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      // Verbatim from K06-pip.html line 73 `.k6-ward` scarf `<svg>`.
      expect(svg, contains('M5 3h4v18H5z'));
      expect(svg, contains('M11 3h4v5a2 2 0 0 1-4 0z'));
      expect(svg, contains('M7 9v6'));
    });

    test('ic_wardrobe_wellies.svg is the exact K06 design glyph', () {
      final svg = _readIcon('ic_wardrobe_wellies.svg');
      expect(svg, contains('currentColor'));
      expect(svg, contains('stroke-width="2"'));
      expect(svg, contains('viewBox="0 0 24 24"'));
      // Verbatim from K06-pip.html line 75 `.k6-ward` wellies `<svg>`.
      expect(
        svg,
        contains(
          'M8 3v8l-2 4.2A3 3 0 0 0 8.7 20h5.6A2.4 2.4 0 0 0 16.6 15l-2.6-4V3z',
        ),
      );
      expect(svg, contains('M6 3h4M14 3h4'));
    });

    for (final mode in const [ThemeMode.light, ThemeMode.dark]) {
      for (final asset in const [
        NestIcons.wardrobeScarf,
        NestIcons.wardrobeWellies,
      ]) {
        testWidgets('${mode.name}: $asset renders tinted', (tester) async {
          await pumpNest(
            tester,
            Builder(
              builder: (context) => NestIcon(asset, color: context.nest.ink),
            ),
            mode: mode,
          );
          expect(find.byType(NestIcon), findsOneWidget);
          final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
          expect(svg.colorFilter, isNotNull);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('Shared batch 7 wardrobe prices (K06 §6)', () {
    test('seed mirrors the K06 design: wellies 30 / crown 60', () async {
      final db = AppDatabase.memory();
      try {
        await Seed.demo(db);
        expect(await _wardrobePrice(db, 'maya', 'wellies'), 30);
        expect(await _wardrobePrice(db, 'maya', 'crown'), 60);
        expect(await _wardrobePrice(db, 'leo', 'wellies'), 30);
        expect(await _wardrobePrice(db, 'leo', 'crown'), 60);
        // Owned rows stay free; Leo scarf (a different item) is untouched.
        expect(await _wardrobePrice(db, 'maya', 'scarf'), 0);
        expect(await _wardrobePrice(db, 'leo', 'scarf'), 30);
      } finally {
        await db.close();
      }
    });
  });

  group('Shared batch 7 NestPetStage K06 slot (K06 §1)', () {
    test('defaults are unchanged (K03 must not move)', () {
      const stage = NestPetStage(riveEnabled: false);
      expect(stage.slotHeight, isNull);
      expect(stage.pipBottom, isNull);
      expect(stage.nestFit, BoxFit.fill);
      expect(stage.showGlow, isTrue);
      expect(stage.showGroundShadow, isTrue);
      const fallback = PipNestFallback(
        stage: PipStage.fledgling,
        pipH: 152,
        nestW: 236,
        stageW: 350,
      );
      expect(fallback.slotHeight, isNull);
      expect(fallback.pipBottom, isNull);
      expect(fallback.nestFit, BoxFit.fill);
      expect(fallback.showGlow, isTrue);
      expect(fallback.showGroundShadow, isTrue);
    });

    test('explicitGeometry K06 numbers: nest 0, pip -9, stage 206', () {
      final g = PipNestFallback.explicitGeometry(
        nestH: 206,
        pipH: 134,
        contactFrac: PipNestFallback.contactInSvg(PipStage.fledgling),
        slotHeight: 206,
        pipBottom: 81,
      );
      // `.k6-pet { 230 x 206 }` nest at bottom: 0, `.pip { 134, bottom: 81 }`.
      expect(g.nestTop, closeTo(0, 0.01));
      expect(g.pipTop, closeTo(-9, 0.01));
      expect(g.pipTopSvg, closeTo(-9, 0.01));
      expect(g.stageH, closeTo(206, 0.01));
    });

    test('explicitGeometry without overrides is still K03', () {
      final g = PipNestFallback.explicitGeometry(
        nestH: 236,
        pipH: 152,
        contactFrac: PipNestFallback.contactInSvg(PipStage.fledgling),
      );
      // Re-measured shared/ds_cleanup: the 236 × 236 nest sits flush (no
      // bleed), so the nest top is 0 in the 236 slot.
      expect(g.nestTop, closeTo(0, 0.01));
      expect(g.stageH, closeTo(236, 0.01));
    });

    testWidgets('K06 slot lays out 230x206 nest, 134 pip at bottom 81', (
      tester,
    ) async {
      const probe = ValueKey<String>('k06PipProbe');
      await pumpNest(
        tester,
        const Center(
          child: SizedBox(
            width: 350,
            child: NestPetStage(
              riveEnabled: false,
              nestWidth: 230,
              nestHeight: 206,
              fixedPipHeight: 134,
              slotHeight: 206,
              pipBottom: 81,
              nestFit: BoxFit.contain,
              showGlow: false,
              showGroundShadow: false,
              pip: SizedBox(key: probe),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final slot = tester.getRect(find.byType(PipNestFallback));
      expect(slot.height, closeTo(206, 0.5));
      final nest = tester.getRect(
        find
            .descendant(
              of: find.byType(PipNestFallback),
              matching: find.byWidgetPredicate(
                (w) => w is SvgPicture && (w.width ?? 0) > 150,
              ),
            )
            .first,
      );
      expect(nest.width, closeTo(230, 0.5));
      expect(nest.height, closeTo(206, 0.5));
      expect(nest.center.dx, closeTo(slot.center.dx, 1));
      // Nest flush to the slot bottom (bottom: 0).
      expect(nest.bottom, closeTo(slot.bottom, 0.5));
      final pip = tester.getRect(find.byKey(probe));
      expect(pip.height, closeTo(134, 0.5));
      expect(pip.center.dx, closeTo(slot.center.dx, 1));
      // Pip bottom 81 above the slot bottom (the 9 px overhang paints with
      // Clip.none, so no overflow).
      expect(slot.bottom - pip.bottom, closeTo(81, 0.5));
      // No decorative layers in the K06 configuration.
      expect(find.byType(PetStageGlow), findsNothing);
    });

    testWidgets('K06 contain keeps the square art uniform (no stretch)', (
      tester,
    ) async {
      await pumpNest(
        tester,
        const Center(
          child: SizedBox(
            width: 350,
            child: NestPetStage(
              riveEnabled: false,
              nestWidth: 230,
              nestHeight: 206,
              fixedPipHeight: 134,
              slotHeight: 206,
              pipBottom: 81,
              nestFit: BoxFit.contain,
              showGlow: false,
              showGroundShadow: false,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final pictures = tester.widgetList<SvgPicture>(
        find.descendant(
          of: find.byType(PipNestFallback),
          matching: find.byType(SvgPicture),
        ),
      );
      // Nest back + Pip + nest front; both nest halves use contain.
      final nestFits = pictures
          .where((p) => (p.width ?? 0) > 150)
          .map((p) => p.fit)
          .toList();
      expect(nestFits, isNotEmpty);
      for (final fit in nestFits) {
        expect(fit, BoxFit.contain);
      }
    });
  });

  group('Shared batch 7 NestKidButton trailing (K06 §2)', () {
    test('defaults are unchanged (no trailing)', () {
      const button = NestKidButton(label: 'Feed');
      expect(button.trailing, isNull);
      expect(button.gap, 8);
      expect(button.axis, Axis.horizontal);
    });

    testWidgets('vertical trailing sits under the label with the same gap', (
      tester,
    ) async {
      await pumpBothModes(
        tester,
        const SizedBox(
          width: 200,
          child: NestKidButton(
            label: 'Feed',
            axis: Axis.vertical,
            gap: 3,
            minHeight: 88,
            fontSize: 17,
            trailing: Text('5', key: ValueKey('trailing')),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Feed'), findsOneWidget);
      expect(find.byKey(const ValueKey('trailing')), findsOneWidget);
      final label = tester.getRect(find.text('Feed'));
      final trailing = tester.getRect(find.byKey(const ValueKey('trailing')));
      // Column: trailing below the label, separated by the 3 px gap.
      expect(trailing.top - label.bottom, closeTo(3, 1.5));
      expect(trailing.center.dx, closeTo(label.center.dx, 2));
    });

    testWidgets('trailing is visual only: one semantics announcement', (
      tester,
    ) async {
      await pumpNest(
        tester,
        const NestKidButton(
          label: 'Feed',
          semanticLabel: 'Feed Pip, costs 5 coins',
          axis: Axis.vertical,
          gap: 3,
          trailing: Text('5'),
        ),
      );
      final handle = tester.ensureSemantics();
      await tester.pump();
      final node = find.semantics
          .byLabel('Feed Pip, costs 5 coins')
          .evaluate()
          .single
          .getSemanticsData();
      expect(node.hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });

    testWidgets('enabled trailing button keeps the tap action', (tester) async {
      var tapped = 0;
      await pumpNest(
        tester,
        NestKidButton(
          label: 'Feed',
          semanticLabel: 'Feed Pip, costs 5 coins',
          axis: Axis.vertical,
          gap: 3,
          onPressed: () => tapped++,
          trailing: const Text('5'),
        ),
      );
      final handle = tester.ensureSemantics();
      await tester.pump();
      final node = find.semantics
          .byLabel('Feed Pip, costs 5 coins')
          .evaluate()
          .single
          .getSemanticsData();
      expect(node.hasAction(SemanticsAction.tap), isTrue);
      await tester.tap(find.byType(NestKidButton));
      await tester.pump();
      expect(tapped, 1);
      handle.dispose();
    });
  });

  group('Shared batch 7 NestDashedBorder (K06 §3)', () {
    test('defaults match the locked tile: 3 px ink-2, 6/3, r-l', () {
      const border = NestDashedBorder(child: SizedBox());
      expect(border.dashLength, 6);
      expect(border.dashGap, 3);
      expect(border.borderRadius, 24);
      expect(border.color, isNull);
      expect(border.strokeWidth, isNull);
      expect(NestDashedBorder.defaultDashLength, 6);
      expect(NestDashedBorder.defaultDashGap, 3);
    });

    testWidgets('paints a dashed r-l stroke on top of the fill', (
      tester,
    ) async {
      await pumpBothModes(
        tester,
        Builder(
          builder: (context) => NestDashedBorder(
            child: Container(
              width: 120,
              height: 80,
              decoration: BoxDecoration(
                color: context.nest.surface2,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final paints = find.descendant(
        of: find.byType(NestDashedBorder),
        matching: find.byType(CustomPaint),
      );
      expect(paints, findsOneWidget);
      final painter =
          tester.widget<CustomPaint>(paints).foregroundPainter!
              as NestDashedBorderPainter;
      expect(painter.dashLength, 6);
      expect(painter.dashGap, 3);
      expect(painter.borderRadius, 24);
      // Foreground (on the fill, as CSS `border-style: dashed`), never a
      // background painter hidden under the opaque fill.
      expect(tester.widget<CustomPaint>(paints).painter, isNull);
    });

    testWidgets('default colour is ink-2 at the 3 px kid border', (
      tester,
    ) async {
      await pumpNest(
        tester,
        const NestDashedBorder(child: SizedBox(width: 120, height: 80)),
      );
      final tokens = tester.element(find.byType(NestDashedBorder)).nest;
      final kid = tester.element(find.byType(NestDashedBorder)).nestKid;
      final painter =
          tester
                  .widget<CustomPaint>(
                    find.descendant(
                      of: find.byType(NestDashedBorder),
                      matching: find.byType(CustomPaint),
                    ),
                  )
                  .foregroundPainter!
              as NestDashedBorderPainter;
      expect(painter.color, tokens.ink2);
      expect(painter.width, kid.borderWidth);
      expect(painter.width, 3);
    });
  });
}
