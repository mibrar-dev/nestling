// Motion lab — the screen has to survive both themes, both motion settings,
// and every control the owner is going to press.
//
// The Rive widgets are pumped with `riveEnabled: false` for the same reason
// `pip_rive_test.dart` does: `flutter test` has no `librive_native.dylib`, and
// the runtime reports that through `FlutterError` on every frame. The reduced
// motion test below is the other real path - it leaves `riveEnabled` at its
// default and relies on `MediaQuery.disableAnimations` to keep the widgets on
// their SVG fallback, which is the same short-circuit a user's device takes.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/design_system_gallery/presentation/views/motion_lab_view.dart';

import 'design_system/test_harness.dart';

/// Tall enough that the whole lab is on screen at once, so the tests below can
/// press the Pip and jar buttons directly: the lab is one long scroll view, and
/// a widget below the fold is not hit-testable. One test still uses the real
/// 390 x 844, which is where a real overflow would show up.
const Size _tall = Size(390, 4200);

void main() {
  group('MotionLabView', () {
    testWidgets('builds in light and dark without exceptions', (tester) async {
      await pumpBothModes(
        tester,
        const MotionLabView(riveEnabled: false),
        surface: _tall,
      );

      expect(find.byType(MotionLabView), findsOneWidget);
      expect(find.text('LOTTIE ONE-SHOTS'), findsOneWidget);
      expect(find.text('RIVE · PIP'), findsOneWidget);
      expect(find.text('RIVE · COIN JAR'), findsOneWidget);
      // One card per file in assets/animations/lottie.
      for (final name in const [
        'check_tick',
        'coin_burst',
        'confetti',
        'badge_unlock',
      ]) {
        expect(find.text(name), findsOneWidget, reason: '$name has no card');
      }
    });

    testWidgets('fits the 390 x 844 screen without exceptions', (tester) async {
      await pumpNest(tester, const MotionLabView(riveEnabled: false));

      expect(tester.takeException(), isNull);
      expect(find.text('Motion lab'), findsOneWidget);
      expect(find.text('Play all'), findsOneWidget);
    });

    testWidgets('drives every control without exceptions', (tester) async {
      await pumpNest(
        tester,
        const MotionLabView(riveEnabled: false),
        surface: _tall,
      );
      expect(tester.takeException(), isNull);

      // Play / Loop / Reset, once per card.
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Play').at(i));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Loop').at(i));
        await tester.pump();
        await tester.tap(find.text('Reset').at(i));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);

      // The Rive panels: every stage, every mood, and both Pip triggers.
      for (final stage in const ['1', '2', '3', '4']) {
        await tester.tap(find.text(stage));
        await tester.pump();
      }
      for (final mood in const ['idle', 'happy', 'eating', 'sleepy']) {
        await tester.tap(find.text(mood));
        await tester.pump();
      }
      await tester.tap(find.text('Evolve'));
      await tester.pump();
      await tester.tap(find.text('Tap Pip'));
      await tester.pump();
      expect(tester.takeException(), isNull);

      // The jar: drag the fill slider, then drop.
      await tester.drag(find.byType(Slider), const Offset(120, 0));
      await tester.pump();
      await tester.tap(find.text('Drop coins'));
      await tester.pump();
      expect(tester.takeException(), isNull);

      // The scripted demo, end to end. Each step awaits its animation
      // (Lottie durations + Rive one-shots ≈ 9.3 s) plus a 350 ms scroll and
      // a 400 ms gap, so the full run is ~15 s.
      await tester.tap(find.text('Play all'));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(tester.takeException(), isNull);
      expect(
        find.text('Play all'),
        findsOneWidget,
        reason: 'the demo did not finish and reset its own button',
      );
    });

    testWidgets('plays nothing under reduced motion', (tester) async {
      await pumpNest(
        tester,
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MotionLabView(),
        ),
        surface: _tall,
      );
      expect(tester.takeException(), isNull);

      // The notice is up, every card is parked on its still frame, and the
      // Rive widgets rendered their SVG fallback instead of reaching for the
      // native runtime.
      expect(find.textContaining('Reduced motion is on'), findsWidgets);
      expect(find.text('Reduced motion'), findsNWidgets(4));
      expect(
        find.byType(PipRive),
        findsOneWidget,
        reason: 'the Pip panel is missing',
      );
      expect(
        find.byWidgetPredicate((widget) => widget is SvgPicture),
        findsWidgets,
        reason: 'reduced motion should be on the SVG path',
      );
    });
  });
}
