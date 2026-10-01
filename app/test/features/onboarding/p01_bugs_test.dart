// P01 Welcome — adversarial bug proofs (Stage 6, iteration 1).
//
// Each test below fails against the current code and is skipped (`skip: true`)
// with its bug id in the test name so the suite stays green until the bug is
// fixed. Remove the skip together with the fix, then re-run:
//
//   flutter test test/features/onboarding/p01_bugs_test.dart
//
// Details, severity and suggested fixes: docs/screens/P01/6_bugs.md.
//
// BUG-1  scene crops instead of scaling below 390dp        (welcome_view.dart)
// BUG-2  system bottom inset counted twice                 (shared NestBottomCta)
// BUG-3  kid mode opens /welcome + the flow without a gate (shared router.dart)
// BUG-4  fresh install never persists onboarding completion(shared AppSession)
// BUG-5  scene Stack clips the coins' --sh-1 shadow        (welcome_view.dart)

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/app/di.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/features/onboarding/domain/onboarding_repository.dart';

import '../../test_scope.dart';

const ValueKey<String> _getStarted = ValueKey<String>('p01_get_started');

/// Pumps `/welcome` at 390x844 (or [width]) with [textScale] and an optional
/// system bottom inset [bottomInset] in logical px.
Future<void> _pumpWelcome(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  double bottomInset = 0,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  if (bottomInset > 0) {
    // View padding is physical; the test surface is 3x.
    tester.view.padding = FakeViewPadding(bottom: bottomInset * 3);
    addTearDown(tester.view.resetPadding);
  }
  await pumpAppRoute(tester, '/welcome');
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Finder get _sceneStack => find.descendant(
  of: find.byType(SingleChildScrollView),
  matching: find.byType(Stack),
);

void main() {
  group('P01 welcome — bug proofs (Stage 6)', () {
    testWidgets(
      'BUG-1 scene paints in full at 320dp',
      (tester) async {
        await setUpTestScope();
        await _pumpWelcome(tester, width: 320);

        final sceneStack = tester.renderObject<RenderStack>(_sceneStack);
        expect(
          sceneStack.describeApproximatePaintClip(sceneStack.firstChild!),
          isNull,
          reason:
              'at 320dp the 350x388 design frame must be scaled down in full; '
              'a non-null clip means the top-right coin (design x=308..342) '
              'and the nest/circle right edges are cropped',
        );

        await disposeApp(tester);
      },
      skip: true, // BUG-1: scene crops at 320dp instead of scaling.
    );

    testWidgets(
      'BUG-2 system bottom inset is added twice',
      (tester) async {
        await setUpTestScope();
        await _pumpWelcome(tester);
        final baselineTop = tester.getTopLeft(find.byKey(_getStarted)).dy;

        await _pumpWelcome(tester, bottomInset: 34);
        final insetTop = tester.getTopLeft(find.byKey(_getStarted)).dy;

        expect(
          insetTop,
          closeTo(baselineTop, 1),
          reason:
              'NestHomeIndicator already draws the 34dp home reserve; the '
              'SafeArea inside NestBottomCta adds the OS inset a second time, '
              'moving the CTAs 34dp up on every device with a home indicator',
        );

        await disposeApp(tester);
      },
      // BUG-2: bottom safe inset + NestHomeIndicator double-counted
      // (core/design_system/components/nest_bottom_cta.dart).
      skip: true,
    );

    testWidgets(
      'BUG-3 kid mode opens /welcome without the parental gate',
      (tester) async {
        await setUpTestScope();
        GetIt.instance<AppModeController>().selectMode(AppMode.kid);
        final session = GetIt.instance<AppSession>();
        await session.setAppMode('kid');
        await session.refresh();

        await _pumpWelcome(tester);

        expect(
          currentPath(tester),
          '/parental-gate',
          reason:
              'P01 is a parent-mode screen; kid mode must be redirected to '
              'the gate (app/lib/app/router.dart parentOnly list)',
        );

        await disposeApp(tester);
      },
      // BUG-3: /welcome (and the onboarding flow) is not on the kid-mode
      // parentOnly list (app/lib/app/router.dart).
      skip: true,
    );

    testWidgets(
      'BUG-3b kid mode can tap Get started into /value-tour',
      (tester) async {
        await setUpTestScope();
        GetIt.instance<AppModeController>().selectMode(AppMode.kid);
        final session = GetIt.instance<AppSession>();
        await session.setAppMode('kid');
        await session.refresh();

        await _pumpWelcome(tester);
        await tester.tap(find.byKey(_getStarted));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          currentPath(tester),
          '/parental-gate',
          reason:
              'in kid mode a parent onboarding step must not be reachable; '
              'the redirect guard only gates /today, /money, /settings, …',
        );

        await disposeApp(tester);
      },
      // BUG-3: /value-tour is not on the kid-mode parentOnly list
      // (app/lib/app/router.dart).
      skip: true,
    );

    test(
      'BUG-4 fresh install never persists onboarding completion',
      () async {
        // A release first launch has no SEED flag: no row is ever inserted
        // into `app_state`.
        await GetIt.instance.reset();
        final db = AppDatabase.memory();
        await configureDependencies(database: db);
        final session = GetIt.instance<AppSession>();
        await session.refresh();
        expect(session.onboardingComplete, isFalse);
        expect(
          await (db.select(
            db.appState,
          )..where((a) => a.id.equals(1))).getSingleOrNull(),
          isNull,
        );

        await GetIt.instance<OnboardingRepository>().completeOnboarding();
        await session.refresh();

        expect(
          session.onboardingComplete,
          isTrue,
          reason:
              'AppSession._write and completeOnboarding only UPDATE row 1; '
              'with no seeded row the update affects 0 rows, so after a '
              'restart the user is sent back to /welcome forever',
        );
      },
      // BUG-4: fresh install has no app_state singleton row; all session
      // writes are silent no-ops (core/data/app_session.dart).
      skip: true,
    );

    testWidgets(
      'BUG-5 scene Stack clips the coins --sh-1 shadow',
      (tester) async {
        await setUpTestScope();
        await _pumpWelcome(tester);

        final sceneStack = tester.renderObject<RenderStack>(_sceneStack);
        expect(
          sceneStack.clipBehavior,
          Clip.none,
          reason:
              'the HTML .scene has no overflow:hidden, so the 8px-blur shadow '
              'of c3 (left 7, rotated 22deg) and c2 (left 308) paints outside '
              'the 350x388 frame; Clip.hardEdge cuts 1-4px, most visible in '
              'dark mode (black@40%)',
        );

        await disposeApp(tester);
      },
      // BUG-5: scene Stack uses Clip.hardEdge, cutting the coin shadows
      // (welcome_view.dart).
      skip: true,
    );
  });
}
