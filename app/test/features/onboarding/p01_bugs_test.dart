// P01 Welcome — adversarial bug proofs (Stage 6, iteration 1; updated through
// iteration 3).
//
// All six proofs are un-skipped and enforced; every underlying fix has landed
// (BUG-2 and BUG-4 now pin the fixed contract, not the old failure):
//
//   flutter test test/features/onboarding/p01_bugs_test.dart
//
// Details and history: docs/screens/P01/6_bugs.md,
// docs/screens/P01/SHARED_REQUEST.md.
//
// BUG-1  scene crops instead of scaling below 390dp        (welcome_view.dart) fixed
// BUG-2  system bottom inset counted twice                 (shared NestBottomCta) fixed
// BUG-3  kid mode opens /welcome + the flow without a gate (shared router.dart) fixed
// BUG-4  fresh install never persists onboarding completion(shared beforeOpen) fixed
// BUG-5  scene Stack clips the coins' --sh-1 shadow        (welcome_view.dart) fixed

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/app/di.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/design_system/design_system.dart';
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
    testWidgets('BUG-1 scene paints in full at 320dp', (tester) async {
      await setUpTestScope();
      await _pumpWelcome(tester, width: 320);

      final sceneStack = tester.renderObject<RenderStack>(_sceneStack);
      // Layout is genuinely fixed (not masked by Clip.none): the Stack
      // always lays out at the full 350x388 design size, even when the
      // frame is narrower (old code laid out 280x310.4 at 320dp).
      expect(sceneStack.size, const Size(350, 388));
      expect(
        sceneStack.describeApproximatePaintClip(sceneStack.firstChild!),
        isNull,
        reason:
            'at 320dp the 350x388 design frame must be scaled down in full; '
            'a non-null clip means the top-right coin (design x=308..342) '
            'and the nest/circle right edges are cropped',
      );

      await disposeApp(tester);
    });

    testWidgets('BUG-2 OS bottom inset is counted exactly once', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpWelcome(tester);
      final baselineTop = tester.getTopLeft(find.byKey(_getStarted)).dy;

      await _pumpWelcome(tester, bottomInset: 34);
      final insetTop = tester.getTopLeft(find.byKey(_getStarted)).dy;

      // Fixed on main (763192d): NestBottomCta's SafeArea consumes the OS
      // bottom inset, NestHomeIndicator no longer reserves a second 34dp
      // band. With a 34dp inset the whole CTA block moves up exactly 34 and
      // its surface panel ends 34dp above the screen edge, as in the design.
      expect(insetTop, closeTo(baselineTop - 34, 1));
      expect(
        tester.getBottomRight(find.text('Made in the UK · No ads, ever')).dy,
        closeTo(844 - 34 - NestSpacing.s4, 1),
      );
      expect(
        tester.getSize(find.byType(NestHomeIndicator)).height,
        0,
        reason: 'the app home indicator is a no-op; the OS draws the real one',
      );

      await disposeApp(tester);
    });

    testWidgets('BUG-3 kid mode opens /welcome without the parental gate', (
      tester,
    ) async {
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
    });

    testWidgets('BUG-3b kid mode cannot open the onboarding step /value-tour', (
      tester,
    ) async {
      await setUpTestScope();
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      final session = GetIt.instance<AppSession>();
      await session.setAppMode('kid');
      await session.refresh();

      // The gate fires when /welcome is requested (see BUG-3), so the old
      // "tap Get started" setup is unreachable — the contract is that the
      // next onboarding step is gated too.
      await pumpAppRoute(tester, '/value-tour');

      expect(
        currentPath(tester),
        '/parental-gate',
        reason:
            'in kid mode every onboarding route (P01–P07) must be gated; '
            'pumping /value-tour must land on the parental gate, not the '
            'tour',
      );

      await disposeApp(tester);
    });

    test('BUG-4 fresh install persists onboarding completion', () async {
      // A release first launch has no SEED flag, but the database now
      // guarantees the app_state singleton row at open (beforeOpen,
      // 045d190), so every repository write (UPDATE WHERE id = 1) lands.
      await GetIt.instance.reset();
      final db = AppDatabase.memory();
      await configureDependencies(database: db);
      final session = GetIt.instance<AppSession>();
      await session.refresh();

      expect(
        await (db.select(
          db.appState,
        )..where((a) => a.id.equals(1))).getSingleOrNull(),
        isNotNull,
        reason: 'the app_state row must exist on a brand-new database',
      );
      expect(session.onboardingComplete, isFalse);

      await GetIt.instance<OnboardingRepository>().completeOnboarding();
      await session.refresh();

      expect(
        session.onboardingComplete,
        isTrue,
        reason:
            'completeOnboarding must persist on a real first install; '
            'before the fix the UPDATE affected 0 rows and every restart '
            'returned the user to /welcome forever',
      );
    });

    testWidgets(
      'BUG-4b fresh install restart lands on Today after onboarding',
      (tester) async {
        // End-to-end proof of the regression the bug caused: complete
        // onboarding through the real repository on an unseeded install, then
        // "restart" (a fresh NestlingApp on the same DB) — the router must not
        // send the user back to /welcome.
        await GetIt.instance.reset();
        final db = AppDatabase.memory();
        await configureDependencies(database: db);
        final session = GetIt.instance<AppSession>();
        await session.refresh();

        await pumpAppRoute(tester, '/today');
        expect(
          currentPath(tester),
          '/welcome',
          reason: 'an un-onboarded install must start at the welcome screen',
        );
        await disposeApp(tester);

        await GetIt.instance<OnboardingRepository>().completeOnboarding();
        await session.refresh();

        await pumpAppRoute(tester, '/today');
        expect(
          currentPath(tester),
          '/today',
          reason:
              'after onboarding completes, a restart must stay on the parent '
              'app instead of looping back to /welcome',
        );
        await disposeApp(tester);
      },
    );

    testWidgets('BUG-5 scene Stack clips the coins --sh-1 shadow', (
      tester,
    ) async {
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
    });
  });
}
