// Shared batch 8 (K08 SHARED_REQUEST §1):
// - NestKidButtonColor.muted: K08 `.k8-get.off` (surface-2 / ink-2 at full
//   opacity, same 3 px ink border + sh-kid shadow, disabled semantics).

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import 'test_harness.dart';

void main() {
  group('Shared batch 8 muted kid button (K08 .k8-get.off)', () {
    testWidgets('muted paints surface-2 / ink-2 with the kid border+shadow', (
      tester,
    ) async {
      await pumpNest(
        tester,
        const NestKidButton(
          label: 'Save up!',
          color: NestKidButtonColor.muted,
          minHeight: 56,
          borderRadius: 16,
          fontSize: 17,
        ),
      );
      final tokens = tester.element(find.byType(NestKidButton)).nest;
      final kid = tester.element(find.byType(NestKidButton)).nestKid;

      final box =
          tester
                  .widget<AnimatedContainer>(
                    find.descendant(
                      of: find.byType(NestKidButton),
                      matching: find.byType(AnimatedContainer),
                    ),
                  )
                  .decoration!
              as BoxDecoration;
      expect(box.color, tokens.surface2, reason: '.k8-get.off background');
      final border = box.border! as Border;
      expect(border.top.width, kid.borderWidth);
      expect(border.top.width, 3);
      expect(border.top.color, tokens.ink);
      expect(box.boxShadow, hasLength(1));
      expect(box.boxShadow!.single.color, tokens.kidShadow.single.color);
      expect(box.boxShadow!.single.offset, const Offset(0, 6));

      final label = tester.widget<Text>(find.text('Save up!'));
      expect(label.style!.color, tokens.ink2, reason: '.k8-get.off color');
      expect(label.style!.fontSize, 17);
      expect(label.style!.fontWeight, FontWeight.w900);
    });

    testWidgets('muted renders at full opacity when disabled', (tester) async {
      await pumpNest(
        tester,
        const NestKidButton(label: 'Save up!', color: NestKidButtonColor.muted),
      );
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(NestKidButton),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 1.0);
    });

    testWidgets('muted keeps disabled semantics when onPressed is null', (
      tester,
    ) async {
      await pumpNest(
        tester,
        const NestKidButton(label: 'Save up!', color: NestKidButtonColor.muted),
      );
      final handle = tester.ensureSemantics();
      await tester.pump();
      final data = tester
          .getSemantics(find.byType(NestKidButton))
          .getSemanticsData();
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });

    testWidgets('muted stays enabled when onPressed is set', (tester) async {
      var tapped = 0;
      await pumpNest(
        tester,
        NestKidButton(
          label: 'Get',
          color: NestKidButtonColor.muted,
          onPressed: () => tapped++,
        ),
      );
      final handle = tester.ensureSemantics();
      await tester.pump();
      final data = tester
          .getSemantics(find.byType(NestKidButton))
          .getSemanticsData();
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      await tester.tap(find.byType(NestKidButton));
      expect(tapped, 1);
      handle.dispose();
    });
  });
}
