// Launch splash tests (shared/splash): timing, skip, Reduce Motion,
// hard timeout and cold-start wiring. Never asserts placeholder view text:
// routing is asserted through `currentPath`, per RULES §7.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/launch_flags.dart';
import 'package:nestling/app/launch_splash.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';

import '../test_scope.dart';

Future<void> _pumpSplash(
  WidgetTester tester, {
  required VoidCallback onDone,
  bool disableAnimations = false,
  bool riveEnabled = true,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData().copyWith(
        disableAnimations: disableAnimations,
      ),
      child: MaterialApp(
        home: Scaffold(
          body: LaunchSplash(onDone: onDone, riveEnabled: riveEnabled),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Asset names of every SVG currently rendered (the Pip stills).
List<String> _svgAssets(WidgetTester tester) => tester
    .widgetList<SvgPicture>(find.byType(SvgPicture))
    .map((w) => (w.bytesLoader as SvgAssetLoader).assetName)
    .toList();

void main() {
  group('shouldShowLaunchSplash', () {
    test('shows on a plain cold start', () {
      expect(
        shouldShowLaunchSplash(skipSplash: false, hasInitialRoute: false),
        isTrue,
      );
    });

    test('hides when SKIP_SPLASH is requested', () {
      expect(
        shouldShowLaunchSplash(skipSplash: true, hasInitialRoute: false),
        isFalse,
      );
    });

    test('hides whenever an initial route is forced', () {
      expect(
        shouldShowLaunchSplash(skipSplash: false, hasInitialRoute: true),
        isFalse,
      );
      expect(
        shouldShowLaunchSplash(skipSplash: true, hasInitialRoute: true),
        isFalse,
      );
    });

    test('LaunchFlags.skipSplash defaults off without dart-defines', () {
      // Widget tests never launch with SKIP_SPLASH/INITIAL_ROUTE defines.
      expect(LaunchFlags.skipSplashRequested, isFalse);
      expect(LaunchFlags.skipSplash, isFalse);
    });
  });

  group('LaunchSplash animated path', () {
    testWidgets('finishes by 1.6 s and calls onDone exactly once', (
      tester,
    ) async {
      var doneCount = 0;
      await _pumpSplash(tester, onDone: () => doneCount++);
      expect(find.byType(LaunchSplash), findsOneWidget);

      // Still up just before the hard timeout.
      await tester.pump(
        LaunchSplashTimings.total - const Duration(milliseconds: 1),
      );
      expect(doneCount, 0);

      await tester.pump(const Duration(milliseconds: 1));
      expect(doneCount, 1);

      // Never fires twice, even with extra frames.
      await tester.pump(const Duration(seconds: 2));
      expect(doneCount, 1);
    });

    testWidgets('starts on the egg and advances to the hatchling', (
      tester,
    ) async {
      var doneCount = 0;
      await _pumpSplash(tester, onDone: () => doneCount++);
      expect(
        _svgAssets(tester),
        contains(PipAvatar.fallbackAsset(PipStyle.mochi, 1)),
      );

      await tester.pump(LaunchSplashTimings.evolveDelay);
      expect(
        _svgAssets(tester),
        contains(PipAvatar.fallbackAsset(PipStyle.mochi, 2)),
      );
      expect(doneCount, 0);
    });

    testWidgets('tap anywhere skips immediately', (tester) async {
      var doneCount = 0;
      await _pumpSplash(tester, onDone: () => doneCount++);
      await tester.tap(find.byType(LaunchSplash));
      await tester.pump();
      expect(doneCount, 1);
    });

    testWidgets('exposes a single labelled node with a tap action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var doneCount = 0;
      await _pumpSplash(tester, onDone: () => doneCount++);
      await tester.pump();
      final node = tester.getSemantics(find.bySemanticsLabel('Nestling'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      // The semantic tap drives the real skip.
      tester.semantics.performAction(
        find.semantics.byLabel('Nestling'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(doneCount, 1);
      handle.dispose();
    });

    testWidgets('uses the native splash green', (tester) async {
      await _pumpSplash(tester, onDone: () {});
      expect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == kLaunchSplashBackground,
        ),
        findsOneWidget,
      );
    });

    testWidgets('hard timeout fires even though Rive never binds', (
      tester,
    ) async {
      // riveEnabled: false keeps the widget on its SVG path forever, so the
      // `evolve` trigger lands on a detached controller and is dropped — the
      // splash must still leave by the hard timeout.
      var doneCount = 0;
      await _pumpSplash(tester, onDone: () => doneCount++, riveEnabled: false);
      await tester.pump(LaunchSplashTimings.total);
      expect(doneCount, 1);
    });
  });

  group('LaunchSplash Reduce Motion path', () {
    testWidgets('shows the hatchling still and finishes within 300 ms', (
      tester,
    ) async {
      var doneCount = 0;
      await _pumpSplash(
        tester,
        onDone: () => doneCount++,
        disableAnimations: true,
      );

      // No hatch: the hatchling still from the first frame, never the egg.
      expect(
        _svgAssets(tester),
        contains(PipAvatar.fallbackAsset(PipStyle.mochi, 2)),
      );
      expect(
        _svgAssets(tester),
        isNot(contains(PipAvatar.fallbackAsset(PipStyle.mochi, 1))),
      );

      await tester.pump(
        LaunchSplashTimings.stillHold - const Duration(milliseconds: 1),
      );
      expect(doneCount, 0);

      await tester.pump(const Duration(milliseconds: 1));
      expect(doneCount, 1);
    });
  });

  group('NestlingApp splash wiring', () {
    testWidgets('forced initial route skips the splash', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/design-system');
      expect(find.byType(LaunchSplash), findsNothing);
      expect(currentPath(tester), '/design-system');
      await disposeApp(tester);
    });

    testWidgets('cold start shows the splash, then the router', (tester) async {
      await setUpTestScope();
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const NestlingApp());
      await tester.pump();
      expect(find.byType(LaunchSplash), findsOneWidget);

      await tester.pump(LaunchSplashTimings.total);
      await tester.pump();
      expect(find.byType(LaunchSplash), findsNothing);
      // The router underneath kept its default first location.
      expect(currentPath(tester), '/design-system');
      await disposeApp(tester);
    });
  });
}
