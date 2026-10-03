// P15 · Child profile — the status switch the real app cannot reach.
//
// `child_profile_view_test.dart` pumps `/child-profile` against the seeded
// in-memory Drift database, which always succeeds, so it can only ever reach
// `loaded`. This file covers the other three branches of
// `ChildProfileView.build` (`child_profile_view.dart:48-67`):
//
//   initial/loading → centred spinner (`1_plan.md` §d)
//   failure         → reason + `Try again`, which re-adds
//                     `FamilyLoadRequested` (the stream was closed by
//                     `_closeOnError`, so the retry must build a new one)
//   loaded, no child→ `NestEmptyState` + `Add a child` CTA, reached for real
//                     with `Seed.empty()` (RULES §4: onboarded parent, no
//                     children — the P08b story)
//
// The mocks are swapped in through GetIt BEFORE the pump, exactly like
// `approvals_view_states_test.dart:_useRepository`: the route builds its bloc
// with `GetIt.instance<FamilyBloc>()`, so the real router, the real
// `ParentShell` and the real tab bar are all exercised.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
// Not in the barrel: the v2 Pip widget (PIP ruling).
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/family/domain/entities/child_profile.dart';
import 'package:nestling/features/family/domain/entities/family_member.dart';
import 'package:nestling/features/family/domain/family_repository.dart';
import 'package:nestling/features/family/presentation/widgets/child_profile_body.dart';

import '../../test_scope.dart';

class _MockFamilyRepository extends Mock implements FamilyRepository;

const _members = <FamilyMember>[
  FamilyMember(
    id: 'sarah',
    title: 'Sarah',
    detail: 'You',
    name: 'Sarah',
    role: 'owner',
    inviteStatus: 'active',
  ),
];

/// Swaps the family repository for [repository] inside GetIt so the
/// `/child-profile` route builds its bloc over the mock.
Future<void> _useRepository(FamilyRepository repository) async {
  await GetIt.instance.unregister<FamilyRepository>();
  GetIt.instance.registerSingleton<FamilyRepository>(repository);
}

Future<void> _pumpAt(
  WidgetTester tester,
  String route, {
  double width = 390,
  double textScale = 1.0,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  group('P15 loading state', () {
    testWidgets('streams that never emit keep the spinner up', (tester) async {
      await setUpTestScope();
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer((_) => const Stream.empty());
      when(repo.watchChildren).thenAnswer((_) => const Stream.empty());
      when(repo.watchProfile).thenAnswer((_) => const Stream.empty());
      await _useRepository(repo);

      await _pumpAt(tester, '/child-profile');

      final spinner = find.byType(CircularProgressIndicator);
      expect(spinner, findsOneWidget);
      expect(tester.element(spinner).nest.isDark, isFalse);
      expect(find.byType(ChildProfileBody), findsNothing);
      expect(find.text('Maya'), findsNothing);
      expect(find.text('Try again'), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the spinner is token-coloured in dark mode too', (
      tester,
    ) async {
      await setUpTestScope();
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer((_) => const Stream.empty());
      when(repo.watchChildren).thenAnswer((_) => const Stream.empty());
      when(repo.watchProfile).thenAnswer((_) => const Stream.empty());
      await _useRepository(repo);

      await _pumpAt(tester, '/child-profile', theme: ThemeMode.dark);

      final spinner = find.byType(CircularProgressIndicator);
      expect(spinner, findsOneWidget);
      expect(tester.element(spinner).nest.isDark, isTrue);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the first profile emission replaces the spinner', (
      tester,
    ) async {
      await setUpTestScope();
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
      when(repo.watchChildren).thenAnswer((_) => Stream.value(const []));
      final gate = StreamController<ChildProfile?>();
      when(repo.watchProfile).thenAnswer((_) => gate.stream);
      await _useRepository(repo);

      await _pumpAt(tester, '/child-profile');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gate.add(null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No children yet'), findsOneWidget);

      await gate.close();
      await disposeApp(tester);
    });
  });

  group('P15 failure state', () {
    testWidgets('the stream error shows the reason and Try again', (
      tester,
    ) async {
      await setUpTestScope();
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
      when(repo.watchChildren).thenAnswer((_) => Stream.value(const []));
      when(repo.watchProfile)
          .thenAnswer((_) => Stream<ChildProfile?>.error(Exception('offline')));
      await _useRepository(repo);

      await _pumpAt(tester, '/child-profile');

      // `findsWidgets`, not `findsOneWidget`: the failure block prints the
      // reason AND the `BlocListener` toast repeats it — see the
      // "BUG P15-BUG-2" test below, which is the one that fails.
      expect(find.text('Exception: offline'), findsWidgets);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.byType(ChildProfileBody), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('Try again re-loads and recovers', (tester) async {
      await setUpTestScope();
      final repo = _MockFamilyRepository();
      var attempts = 0;
      when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
      when(repo.watchChildren).thenAnswer((_) => Stream.value(const []));
      when(repo.watchProfile).thenAnswer((_) {
        attempts++;
        return attempts == 1
            ? Stream<ChildProfile?>.error(Exception('offline'))
            : Stream<ChildProfile?>.value(null);
      });
      await _useRepository(repo);

      await _pumpAt(tester, '/child-profile');
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(attempts, 2, reason: 'the retry built a fresh subscription');
      expect(find.text('Try again'), findsNothing);
      expect(find.text('No children yet'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the failure block renders in dark theme too', (tester) async {
      await setUpTestScope();
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
      when(repo.watchChildren).thenAnswer((_) => Stream.value(const []));
      when(repo.watchProfile)
          .thenAnswer((_) => Stream<ChildProfile?>.error(Exception('offline')));
      await _useRepository(repo);

      await _pumpAt(tester, '/child-profile', theme: ThemeMode.dark);

      expect(find.text('Exception: offline'), findsWidgets);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.byType(ChildProfileBody), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    // ── BUG P15-BUG-2 (failing repro — do not "fix" the test) ──────────────
    // `ChildProfileView`'s `BlocListener` (child_profile_view.dart:41-45)
    // toasts ANY new `errorMessage`, including the one the load failure
    // itself sets — and `_FailureBody` prints the same string at the same
    // moment. The parent therefore reads the failure twice: a toast on top
    // of the failure block. P12 sets the precedent this deviates from
    // (`money_ledger_view.dart:64-67`): its toast is armed only for
    // `status == loaded`, i.e. for ACTION errors, never for the load
    // failure the body already shows.
    testWidgets('BUG P15-BUG-2: a load failure is reported once, not twice', (
      tester,
    ) async {
      await setUpTestScope();
      final repo = _MockFamilyRepository();
      when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
      when(repo.watchChildren).thenAnswer((_) => Stream.value(const []));
      when(repo.watchProfile)
          .thenAnswer((_) => Stream<ChildProfile?>.error(Exception('offline')));
      await _useRepository(repo);

      await _pumpAt(tester, '/child-profile');

      expect(
        find.text('Exception: offline'),
        findsOneWidget,
        reason:
            'the failure block owns this string; the toast repeats it '
            '(child_profile_view.dart:41-45 needs the P12 '
            '`status == loaded` guard)',
      );

      await disposeApp(tester);
    });

    testWidgets('Try again is a real tap target in both themes', (
      tester,
    ) async {
      for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
        await setUpTestScope();
        final repo = _MockFamilyRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
        when(repo.watchChildren).thenAnswer((_) => Stream.value(const []));
        when(
          repo.watchProfile,
        ).thenAnswer((_) => Stream<ChildProfile?>.error(Exception('offline')));
        await _useRepository(repo);

        await _pumpAt(tester, '/child-profile', theme: theme);

        final button = find.widgetWithText(NestButton, 'Try again');
        expect(button, findsOneWidget);
        expect(
          tester.getRect(button).height,
          greaterThanOrEqualTo(NestDevice.tapParent),
        );
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      }
    });
  });

  group('P15 with Seed.empty() (no children)', () {
    testWidgets('the route survives and the empty state offers the funnel', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);

      await _pumpAt(tester, '/child-profile');

      expect(currentPath(tester), '/child-profile');
      expect(find.text('No children yet'), findsOneWidget);
      expect(
        find.text('Add your first child and their Pip will start to hatch.'),
        findsOneWidget,
      );
      expect(find.byType(ChildProfileBody), findsNothing);
      // No child yet → the onboarding Pip (mochi · sunny, stage 1), never the
      // v1 `pip_stage_*.svg` illustrations (PIP ruling).
      final pip = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(pip.style, PipStyle.mochi);
      expect(pip.skin, PipSkin.sunny);
      expect(pip.stage, 1);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the empty state CTA is a >= 44 px control that navigates', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);

      await _pumpAt(tester, '/child-profile');

      final button = find.widgetWithText(NestButton, 'Add a child');
      expect(
        tester.getRect(button).height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(pushedPath(tester), '/add-children');
      await disposeApp(tester);
    });

    testWidgets('the empty state holds up in dark mode', (tester) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);

      await _pumpAt(tester, '/child-profile', theme: ThemeMode.dark);

      expect(find.text('No children yet'), findsOneWidget);
      expect(tester.element(find.text('No children yet')).nest.isDark, isTrue);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });
}
