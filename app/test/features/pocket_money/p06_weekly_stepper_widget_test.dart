// P06 weekly-base stepper — widget tests (iteration 6).
//
// The design HTML (`design/html-source/screens/P06-pocket-money.html:73,82`)
// prints `&minus;` — U+2212 — beside a U+002B `+` inside every
// `.stepper button`, so the two signs share weight and width. The shared
// `NestStepper` hard-codes an ASCII hyphen (U+002D) for decrease and offers
// no glyph override, which is why P06 renders this feature-local widget
// (`presentation/widgets/p06_weekly_stepper.dart`) until the shared component
// grows the override requested in `docs/screens/P06/SHARED_REQUEST.md`.
//
// ORCHESTRATOR_NOTES "UPDATE (07:22)" / "(07:58)": *"Use "−" (U+2212), or
// the same icon set as "+" … Add a test that the minus button's glyph is not
// U+002D."*

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/features/pocket_money/presentation/widgets/p06_weekly_stepper.dart';

import '../../design_system/test_harness.dart';

/// Pumps the stepper inside the app's real themes so `context.nest` resolves.
Future<void> _pump(WidgetTester tester, P06WeeklyStepper child) =>
    pumpNest(tester, Center(child: child));

/// The glyph [Text] inside a stepper button, found by its button key (the
/// shared semantics labels are asserted in the screen's own a11y test).
Finder _glyphIn(String buttonKey) => find.descendant(
  of: find.byKey(ValueKey<String>(buttonKey)),
  matching: find.byType(Text),
);

void main() {
  group('P06WeeklyStepper', () {
    testWidgets("the minus glyph is the design's U+2212, never U+002D", (
      tester,
    ) async {
      await _pump(
        tester,
        const P06WeeklyStepper(
          valueText: '£3.00',
          decreaseSemanticLabel: 'Less weekly pocket money for Maya',
          increaseSemanticLabel: 'More weekly pocket money for Maya',
        ),
      );

      final minus = tester.widget<Text>(_glyphIn('decrease').first);
      expect(minus.data, '−');
      expect(minus.data, kP06StepperMinusGlyph);
      expect(
        minus.data!.codeUnits,
        isNot([0x2D]),
        reason: 'a short hyphen reads lighter and narrower than the +',
      );

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('the plus glyph is U+002B, so − and + are one family', (
      tester,
    ) async {
      await _pump(
        tester,
        const P06WeeklyStepper(
          valueText: '£3.00',
          decreaseSemanticLabel: 'Less weekly pocket money for Maya',
          increaseSemanticLabel: 'More weekly pocket money for Maya',
        ),
      );

      final plus = tester.widget<Text>(_glyphIn('increase').first);
      expect(plus.data, '+');
      // Both glyphs come out of the same style, so they share weight/size and
      // read as one family — that is the point of the U+2212 pairing.
      expect(plus.style?.fontSize, 20);
      expect(plus.style?.fontWeight, FontWeight.w700);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('the value renders tabular, at least 64 wide, 1 line', (
      tester,
    ) async {
      await _pump(tester, const P06WeeklyStepper(valueText: '£1.50'));

      final value = find.text('£1.50');
      expect(value, findsOneWidget);
      final style = tester.widget<Text>(value).style!;
      expect(style.fontSize, 18);
      expect(style.height, moreOrLessEquals(24 / 18, epsilon: 0.0001));
      expect(tester.getSize(value).height, moreOrLessEquals(24, epsilon: 1));
      final text = tester.widget<Text>(value);
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('both buttons are 44 dp circles and fire their callbacks', (
      tester,
    ) async {
      var down = 0;
      var up = 0;
      await _pump(
        tester,
        P06WeeklyStepper(
          valueText: '£3.00',
          onDecrease: () => down++,
          onIncrease: () => up++,
        ),
      );

      final decrease = find.byKey(const ValueKey('decrease'));
      final increase = find.byKey(const ValueKey('increase'));
      final semantics = tester.ensureSemantics();
      for (final finder in <Finder>[decrease, increase]) {
        expect(tester.getSize(finder), const Size(44, 44));
        // Announced as a button, so the screen's a11y contract holds here too.
        expect(
          tester
              .getSemantics(finder)
              .getSemanticsData()
              .flagsCollection
              .isButton,
          isTrue,
        );
      }
      semantics.dispose();

      await tester.tap(decrease);
      await tester.tap(increase);
      expect(down, 1);
      expect(up, 1);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('a null callback disables its button (0.45 opacity)', (
      tester,
    ) async {
      await _pump(tester, const P06WeeklyStepper(valueText: '£3.00'));

      // Disabled: the tap is inert (there is no callback) and the button is
      // dimmed to 0.45 rather than disappearing.
      final opacity = tester.widget<Opacity>(
        find
            .descendant(
              of: find.byKey(const ValueKey('decrease')),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(opacity.opacity, 0.45);
      // Tapping a disabled stepper must not throw or move the value.
      await tester.tap(find.byKey(const ValueKey('decrease')));
      expect(find.text('£3.00'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
