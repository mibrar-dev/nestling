// Pip lab — the screen has to survive both themes, both motion settings,
// and every control the owner is going to press.
//
// The avatar is pumped with `riveEnabled: false` for the same reason
// `pip_avatar_test.dart` does: `flutter test` has no `librive_native.dylib`,
// and the runtime reports that through `FlutterError` on every frame. The
// reduced motion test below is the other real path — it leaves `riveEnabled`
// at its default and relies on `MediaQuery.disableAnimations` to keep the
// avatar on its SVG fallback, which is the same short-circuit a user's
// device takes.

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/design_system_gallery/presentation/views/pip_lab_view.dart';

import 'design_system/test_harness.dart';

/// Tall enough that the whole lab is on screen at once, so the tests below
/// can press every chip directly: the lab is one long scroll view, and a
/// widget below the fold is not hit-testable. One test still uses the real
/// 390 x 844, which is where a real overflow would show up.
const Size _tall = Size(390, 2600);

void main() {
  group('PipLabView', () {
    testWidgets('builds in light and dark without exceptions', (tester) async {
      await pumpBothModes(
        tester,
        const PipLabView(riveEnabled: false),
        surface: _tall,
      );

      expect(find.byType(PipLabView), findsOneWidget);
      expect(find.text('Pip lab'), findsOneWidget);
      expect(find.text('BODY STYLE'), findsOneWidget);
      expect(find.text('GROWTH STAGE'), findsOneWidget);
      expect(find.text('MOOD'), findsOneWidget);
      expect(find.text('SKIN'), findsOneWidget);
      expect(find.text('ACCESSORY'), findsOneWidget);
      expect(find.text('PICKER PREVIEW'), findsOneWidget);
      expect(find.text('Play all moods'), findsOneWidget);
      // One large avatar plus three picker previews.
      expect(find.byType(PipAvatar), findsNWidgets(4));
    });

    testWidgets('fits the 390 x 844 screen without exceptions', (tester) async {
      await pumpNest(tester, const PipLabView(riveEnabled: false));

      expect(tester.takeException(), isNull);
      expect(find.text('Pip lab'), findsOneWidget);
      expect(find.text('Play all moods'), findsOneWidget);
    });

    testWidgets('drives every control without exceptions', (tester) async {
      await pumpNest(
        tester,
        const PipLabView(riveEnabled: false),
        surface: _tall,
      );
      expect(tester.takeException(), isNull);

      // Body styles.
      for (final style in const ['Mochi', 'Bolt', 'Storybook']) {
        await tester.tap(find.text(style));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);

      // Stages.
      for (final stage in const ['1', '2', '3', '4']) {
        await tester.tap(find.text(stage));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);

      // Moods (by key: the status caption names moods too).
      for (final mood in const [
        'idle',
        'happy',
        'eating',
        'sleepy',
        'surprised',
        'proud',
      ]) {
        await tester.tap(find.byKey(ValueKey('piplab-mood-$mood')));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);

      // Skins and accessories (by key for the same reason).
      for (final skin in const ['sunny', 'berry', 'sky', 'mint']) {
        await tester.tap(find.byKey(ValueKey('piplab-skin-$skin')));
        await tester.pump();
      }
      for (final acc in const ['none', 'bow', 'cap', 'scarf', 'glasses']) {
        await tester.tap(find.byKey(ValueKey('piplab-acc-$acc')));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);

      // Evolve advances a stage; Tap pokes (both dropped silently without
      // Rive, but neither may throw).
      await tester.tap(find.text('Evolve'));
      await tester.pump();
      await tester.tap(find.text('Tap'));
      await tester.pump();
      expect(tester.takeException(), isNull);

      // In-nest toggle flips the artboard caption.
      expect(find.textContaining('artboard Stage'), findsOneWidget);
      await tester.tap(find.byType(NestToggle));
      await tester.pump();
      expect(find.textContaining('artboard PipStage'), findsOneWidget);
      await tester.tap(find.byType(NestToggle));
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Picker preview selects the style.
      await tester.tap(find.byKey(const ValueKey('piplab-preview-bolt')));
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Play-all end to end: six moods (≈ 10.7 s of holds + gaps) plus the
      // 1.5 s evolve, so ~20 one-second pumps cover it with margin.
      await tester.tap(find.text('Play all moods'));
      for (var i = 0; i < 22; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(tester.takeException(), isNull);
      expect(
        find.text('Play all moods'),
        findsOneWidget,
        reason: 'play-all did not finish and reset its own button',
      );
    });

    testWidgets('shows nothing animated under reduced motion', (tester) async {
      await pumpNest(
        tester,
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: PipLabView(),
        ),
        surface: _tall,
      );
      expect(tester.takeException(), isNull);

      // The notice is up, the one-shot buttons are off, and the avatar
      // rendered its SVG fallback instead of reaching for the native
      // runtime.
      expect(find.textContaining('Reduced motion is on'), findsOneWidget);
      expect(find.byType(PipAvatar), findsNWidgets(4));
      expect(
        find.byWidgetPredicate((widget) => widget is SvgPicture),
        findsWidgets,
        reason: 'reduced motion should be on the SVG path',
      );
    });
  });
}
