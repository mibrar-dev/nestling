// Shared requests batch 2 — regression tests for every shared change.
//
// 1. NestChip lays out at the design's 32 px while the hit area stays
//    ≥44×44 (P05 chip-row defect).
// 2. NestTextField error state: 2 px danger border + gutter error row
//    announced through a live region (P03-BUG-16 / SHARED_REQUEST §8).
// 3. NestPetStage explicit size mode: nestWidth / fixedPipHeight (K03 slot).
// 4. Child creation order lives in app/test/core/data/children_order_test.dart
//    (schema v2 → v3 migration, Maya-then-Leo, late add last).
//
// See docs/screens/_shared/shared_batch2_REPORT.md.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

void main() {
  group('SHARED BATCH 2 NestChip 32 layout with 44 hit area', () {
    testWidgets('interactive chip lays out 32 tall', (tester) async {
      await pumpBothModes(tester, NestChip(label: '7-9', onSelected: (_) {}));
      final size = tester.getSize(find.byType(NestChip));
      expect(size.height, 32);
      expect(size.width, greaterThanOrEqualTo(44));
    });

    testWidgets('static chip lays out 32 tall', (tester) async {
      await pumpBothModes(tester, const NestChip(label: 'Static'));
      expect(tester.getSize(find.byType(NestChip)).height, 32);
    });

    testWidgets('tap 6 px outside the visual chip still selects', (
      tester,
    ) async {
      final selected = <bool>[];
      await pumpNest(
        tester,
        Center(
          child: NestChip(label: '7-9', onSelected: selected.add),
        ),
      );
      expect(tester.getSize(find.byType(NestChip)).height, 32);

      final topCenter = tester.getTopLeft(find.byType(NestChip));
      final size = tester.getSize(find.byType(NestChip));
      await tester.tapAt(topCenter + Offset(size.width / 2, -6));
      await tester.pump();
      expect(selected, [true]);
    });

    testWidgets('tap 6 px below the visual chip still selects', (tester) async {
      final selected = <bool>[];
      await pumpNest(
        tester,
        Center(
          child: NestChip(label: '7-9', onSelected: selected.add),
        ),
      );
      final topLeft = tester.getTopLeft(find.byType(NestChip));
      final size = tester.getSize(find.byType(NestChip));
      await tester.tapAt(topLeft + Offset(size.width / 2, size.height + 6));
      await tester.pump();
      expect(selected, [true]);
    });

    testWidgets('Wrap of chips at text scale 1.3 still has no overflow', (
      tester,
    ) async {
      // `pumpBothModes` already fails on any overflow exception; the Wrap
      // may use two rows here (flex-wrap is the design's `.chip-row`
      // behaviour) — what must hold is that every chip lays out 32 high
      // with no clipping.
      await pumpBothModes(
        tester,
        Wrap(
          spacing: 8,
          children: [
            for (final band in const ['4-6', '7-9', '10-12', '13+'])
              NestChip(
                key: ValueKey('batch2-ageChip-$band'),
                label: band,
                onSelected: (_) {},
              ),
          ],
        ),
        surface: const Size(320, 568),
        textScale: 1.3,
      );
      for (final band in const ['4-6', '7-9', '10-12', '13+']) {
        final chip = find.byKey(ValueKey('batch2-ageChip-$band'));
        expect(chip, findsOneWidget);
        expect(tester.getSize(chip).height, 32);
      }
    });
  });

  group('SHARED BATCH 2 NestTextField error state', () {
    OutlineInputBorder enabledBorder(WidgetTester tester) {
      final field = tester.widget<TextField>(find.byType(TextField));
      return field.decoration!.enabledBorder! as OutlineInputBorder;
    }

    OutlineInputBorder focusedBorder(WidgetTester tester) {
      final field = tester.widget<TextField>(find.byType(TextField));
      return field.decoration!.focusedBorder! as OutlineInputBorder;
    }

    testWidgets('error border is the 2 px danger token (light)', (
      tester,
    ) async {
      await pumpNest(
        tester,
        const NestTextField(label: 'Nickname', errorText: 'Too short.'),
      );
      expect(enabledBorder(tester).borderSide.color, NestColors.light.danger);
      expect(enabledBorder(tester).borderSide.width, 2);
      expect(focusedBorder(tester).borderSide.color, NestColors.light.danger);
      expect(focusedBorder(tester).borderSide.width, 2);
      expect(find.text('Too short.'), findsOneWidget);
    });

    testWidgets('error border is the 2 px danger token (dark)', (tester) async {
      await pumpNest(
        tester,
        const NestTextField(label: 'Nickname', errorText: 'Too short.'),
        mode: ThemeMode.dark,
      );
      expect(enabledBorder(tester).borderSide.color, NestColors.dark.danger);
      expect(enabledBorder(tester).borderSide.width, 2);
      expect(focusedBorder(tester).borderSide.color, NestColors.dark.danger);
      expect(focusedBorder(tester).borderSide.width, 2);
    });

    testWidgets('error row announces through a live region exactly once', (
      tester,
    ) async {
      await pumpNest(
        tester,
        const NestTextField(label: 'Nickname', errorText: 'Too short.'),
      );
      final liveRegion = find.ancestor(
        of: find.text('Too short.'),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.liveRegion == true,
        ),
      );
      expect(liveRegion, findsOneWidget);
      final node = tester.getSemantics(liveRegion);
      expect(node.label, 'Too short.');
      final labels = <String>[];
      bool visit(SemanticsNode n) {
        if (n.label.isNotEmpty) labels.add(n.label);
        n.visitChildren(visit);
        return true;
      }

      visit(node);
      expect(labels, ['Too short.']);
    });
  });

  group('SHARED BATCH 2 NestPetStage explicit size', () {
    testWidgets('nestWidth 260 yields a 260 nest and a 152 Pip', (
      tester,
    ) async {
      await pumpBothModes(
        tester,
        const NestPetStage(nestWidth: 260, riveEnabled: false),
      );
      final scene = tester.widget<PipNestFallback>(
        find.byType(PipNestFallback),
      );
      expect(scene.nestW, 260);
      expect(scene.pipH, moreOrLessEquals(152, epsilon: 2));
    });

    testWidgets('fixedPipHeight overrides the Pip height', (tester) async {
      await pumpBothModes(
        tester,
        const NestPetStage(fixedPipHeight: 100, riveEnabled: false),
      );
      final scene = tester.widget<PipNestFallback>(
        find.byType(PipNestFallback),
      );
      expect(scene.pipH, 100);
      expect(scene.nestW, moreOrLessEquals(100 / PipNestFallback.split));
    });

    testWidgets('default sizing still caps by pipSize', (tester) async {
      await pumpBothModes(
        tester,
        const NestPetStage(pipSize: 100, riveEnabled: false),
      );
      final scene = tester.widget<PipNestFallback>(
        find.byType(PipNestFallback),
      );
      // A 390-wide parent would derive ~133; the cap holds it at 100.
      expect(scene.pipH, 100);
      expect(scene.nestW, moreOrLessEquals(scene.pipH / 0.55));
    });
  });
}
