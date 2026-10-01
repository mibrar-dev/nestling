// P01 Welcome — widget contract.
//
// Covers: the brand copy and artwork, light + dark themes, widths 320/390/430
// at text scales 1.0/1.3, every OnboardingBloc status (initial/loading/
// empty/loaded/failure), both navigation taps, and the accessibility
// contract (semantic labels, 44dp parent tap targets, no kid controls).
//
// Layout regression found here (recorded in docs/screens/P01/3_test.md,
// NOT patched in stage 3): at 320/360dp the scene's 350x388 frame is laid
// out inside the already-shrunk box, so the Stack crops its content (the
// top-right coin disappears) instead of scaling it.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/onboarding/domain/entities/onboarding_step.dart';
import 'package:nestling/features/onboarding/domain/onboarding_repository.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:nestling/features/onboarding/presentation/views/welcome_view.dart';

import '../../test_scope.dart';

const String _headline = 'Chores that feel like a game.';
const String _body =
    'Nestling turns family jobs into quests your children actually '
    'want to finish — and keeps pocket money fair and tidy.';
const String _caption = 'Made in the UK · No ads, ever';
const String _pipLabel = 'Pip the hatchling bird sitting in a twig nest';

const OnboardingStep _firstStep = OnboardingStep(
  id: 'quests',
  title: 'Set quests in seconds',
  detail: 'Pick from 40+ ready-made jobs.',
);

const OnboardingStep _secondStep = OnboardingStep(
  id: 'pip',
  title: 'Pip grows as they help',
  detail: 'Every finished quest feeds Pip the bird.',
);

/// In-memory repository with a caller-controlled item stream, used to reach
/// the states the Drift repository cannot (pending load, empty, stream error).
class _FakeOnboardingRepository implements OnboardingRepository {
  _FakeOnboardingRepository(this._items);

  final Stream<List<OnboardingStep>> _items;

  @override
  Future<List<OnboardingStep>> getItems() => _items.first;

  @override
  Stream<List<OnboardingStep>> watchItems() => _items;

  @override
  Stream<bool> watchComplete() => Stream<bool>.value(true);

  @override
  Future<void> completeOnboarding() async {}
}

/// Pumps `/welcome` through the real app (router, DI, themes) at [surface]
/// and [textScale]. Mirrors [pumpAppRoute], which does not take size/scale.
Future<void> _pumpWelcome(
  WidgetTester tester, {
  required ThemeMode theme,
  required Size surface,
  required double textScale,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await pumpAppRoute(tester, '/welcome', theme: theme);
  tester.view.physicalSize = surface * 3;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Pumps [WelcomeView] directly (no router) under the real theme with
/// [repository] driving the bloc; returns the bloc for state assertions.
Future<OnboardingBloc> _pumpWelcomeView(
  WidgetTester tester, {
  required OnboardingRepository repository,
  required ThemeMode theme,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  final bloc = OnboardingBloc(repository: repository);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      themeMode: theme,
      home: BlocProvider<OnboardingBloc>.value(
        value: bloc,
        child: const WelcomeView(),
      ),
    ),
  );
  await tester.pump();
  return bloc;
}

Future<void> _disposeView(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

void main() {
  group('P01 welcome — copy, theming, width and scale', () {
    testWidgets('light: renders brand copy, both CTAs, caption and Pip', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpWelcome(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(find.text('9:41'), findsOneWidget);
      expect(find.text(_headline), findsOneWidget);
      expect(find.text(_body), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('I already have an account'), findsOneWidget);
      expect(find.text(_caption), findsOneWidget);
      expect(find.bySemanticsLabel(_pipLabel), findsOneWidget);
      expect(find.byType(NestIconButton), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('dark: renders the same content without overflow', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpWelcome(
        tester,
        theme: ThemeMode.dark,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(find.text(_headline), findsOneWidget);
      expect(find.text(_body), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text('I already have an account'), findsOneWidget);
      expect(find.text(_caption), findsOneWidget);
      expect(find.bySemanticsLabel(_pipLabel), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in const <int>[320, 390, 430]) {
        for (final scale in const <double>[1, 1.3]) {
          final themeName = theme == ThemeMode.light ? 'light' : 'dark';
          testWidgets('$themeName ${width}dp at text scale $scale', (
            tester,
          ) async {
            await setUpTestScope();
            await _pumpWelcome(
              tester,
              theme: theme,
              surface: Size(width.toDouble(), 844),
              textScale: scale,
            );

            expect(find.text(_headline), findsOneWidget);
            expect(find.text('Get started'), findsOneWidget);
            expect(find.text('I already have an account'), findsOneWidget);
            expect(find.text(_caption), findsOneWidget);
            expect(tester.takeException(), isNull);

            await disposeApp(tester);
          });
        }
      }
    }

    testWidgets('Seed.empty (onboarded, no children) still renders P01', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();

      await _pumpWelcome(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(find.text(_headline), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('Seed.fresh: /today redirects to the real welcome screen', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.fresh(db);
      await GetIt.instance<AppSession>().refresh();

      await pumpAppRoute(tester, '/today');

      expect(find.text(_headline), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P01 welcome — BLoC states render the static brand screen', () {
    setUp(() {
      GoogleFonts.config.allowRuntimeFetching = false;
    });

    testWidgets('initial: content renders before the load event', (
      tester,
    ) async {
      final bloc = await _pumpWelcomeView(
        tester,
        repository: _FakeOnboardingRepository(
          const Stream<List<OnboardingStep>>.empty(),
        ),
        theme: ThemeMode.light,
      );

      expect(bloc.state.status, OnboardingStatus.initial);
      expect(find.text(_headline), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('loading: content renders while no items have arrived', (
      tester,
    ) async {
      // An empty stream leaves the bloc in `loading` (the load event emits
      // loading before subscribing and no data ever arrives). Note: a
      // never-ending StreamController cannot be used under the widget-test
      // fake-async zone — closing the bloc then deadlocks the test harness
      // (a harness artifact, not an app bug). The pending-stream path is
      // covered by `blocTest` in onboarding_bloc_test.dart.
      final bloc = await _pumpWelcomeView(
        tester,
        repository: _FakeOnboardingRepository(
          const Stream<List<OnboardingStep>>.empty(),
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const OnboardingLoadRequested());
      await tester.pump();

      expect(bloc.state.status, OnboardingStatus.loading);
      expect(find.text(_headline), findsOneWidget);
      expect(find.text(_caption), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('loaded with no items: still the full brand screen', (
      tester,
    ) async {
      final bloc = await _pumpWelcomeView(
        tester,
        repository: _FakeOnboardingRepository(
          Stream<List<OnboardingStep>>.value(const <OnboardingStep>[]),
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const OnboardingLoadRequested());
      await tester.pump();

      expect(bloc.state.status, OnboardingStatus.loaded);
      expect(bloc.state.items, isEmpty);
      expect(find.text(_headline), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('loaded with items: the tour cards do not change P01', (
      tester,
    ) async {
      final bloc = await _pumpWelcomeView(
        tester,
        repository: _FakeOnboardingRepository(
          Stream<List<OnboardingStep>>.value(const <OnboardingStep>[
            _firstStep,
            _secondStep,
          ]),
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const OnboardingLoadRequested());
      await tester.pump();

      expect(bloc.state.status, OnboardingStatus.loaded);
      expect(bloc.state.items, const <OnboardingStep>[_firstStep, _secondStep]);
      expect(find.text(_headline), findsOneWidget);
      expect(find.text(_body), findsOneWidget);
      expect(find.text('Set quests in seconds'), findsNothing);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('failure: a repository error never blocks the brand screen', (
      tester,
    ) async {
      final bloc = await _pumpWelcomeView(
        tester,
        repository: _FakeOnboardingRepository(
          Stream<List<OnboardingStep>>.error(Exception('offline')),
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const OnboardingLoadRequested());
      await tester.pump();

      expect(bloc.state.status, OnboardingStatus.failure);
      expect(bloc.state.errorMessage, contains('offline'));
      expect(find.text(_headline), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      expect(find.text(_caption), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });
  });

  group('P01 welcome — navigation', () {
    testWidgets('Get started opens /value-tour', (tester) async {
      await setUpTestScope();
      await _pumpWelcome(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );
      final router = GoRouter.of(tester.element(find.byType(WelcomeView)));

      await tester.tap(find.byKey(const ValueKey('p01_get_started')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/value-tour',
      );

      await disposeApp(tester);
    });

    testWidgets('I already have an account opens /create-account', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpWelcome(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );
      final router = GoRouter.of(tester.element(find.byType(WelcomeView)));

      await tester.tap(find.byKey(const ValueKey('p01_have_account')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/create-account',
      );

      await disposeApp(tester);
    });
  });

  group('P01 welcome — accessibility', () {
    testWidgets('labels, excluded chrome and tap targets meet the contract', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpWelcome(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // Both CTAs expose their label; the artwork carries the HTML alt text.
      // (The label finder matches the Semantics wrapper and the inner Text.)
      expect(find.bySemanticsLabel('Get started'), findsWidgets);
      expect(find.bySemanticsLabel('I already have an account'), findsWidgets);
      expect(find.bySemanticsLabel(_pipLabel), findsOneWidget);

      final getStartedData = tester
          .getSemantics(find.byKey(const ValueKey('p01_get_started')))
          .getSemanticsData();
      expect(getStartedData.label, 'Get started');
      expect(getStartedData.flagsCollection.isButton, isTrue);
      final haveAccountData = tester
          .getSemantics(find.byKey(const ValueKey('p01_have_account')))
          .getSemanticsData();
      expect(haveAccountData.label, 'I already have an account');
      expect(haveAccountData.flagsCollection.isButton, isTrue);

      // Decorative chrome carries no semantics (status bar excluded).
      expect(find.bySemanticsLabel('9:41'), findsNothing);

      // P01 is parent mode and has no icon-only buttons / kid controls, so
      // the 56dp kid tap-target rule does not apply here.
      expect(find.byType(NestIconButton), findsNothing);
      expect(find.byType(NestKidButton), findsNothing);

      // Parent rule: every tap target is at least 44x44, and the two CTAs
      // are full-width 52dp pill buttons per SPACING_SPEC §2.
      final getStarted = tester.getSize(
        find.byKey(const ValueKey('p01_get_started')),
      );
      final haveAccount = tester.getSize(
        find.byKey(const ValueKey('p01_have_account')),
      );
      expect(getStarted.height, greaterThanOrEqualTo(NestDevice.tapParent));
      expect(haveAccount.height, greaterThanOrEqualTo(NestDevice.tapParent));
      expect(getStarted.height, greaterThanOrEqualTo(52));
      expect(haveAccount.height, greaterThanOrEqualTo(52));
      expect(getStarted.width, 390 - 2 * NestSpacing.padSide);
      expect(haveAccount.width, getStarted.width);

      await disposeApp(tester);
    });

    testWidgets('tap targets hold at 320dp with text scale 1.3', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpWelcome(
        tester,
        theme: ThemeMode.light,
        surface: const Size(320, 844),
        textScale: 1.3,
      );

      for (final key in const <ValueKey<String>>[
        ValueKey('p01_get_started'),
        ValueKey('p01_have_account'),
      ]) {
        final size = tester.getSize(find.byKey(key));
        expect(size.height, greaterThanOrEqualTo(NestDevice.tapParent));
        expect(size.width, 320 - 2 * NestSpacing.padSide);
      }
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P01 welcome — bug regressions', () {
    for (final width in const <int>[320, 360, 390, 430]) {
      testWidgets('scene frame is painted in full (no crop) at ${width}dp', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpWelcome(
          tester,
          theme: ThemeMode.light,
          surface: Size(width.toDouble(), 844),
          textScale: 1,
        );

        final sceneStack = tester.renderObject<RenderStack>(
          find.descendant(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(Stack),
          ),
        );
        expect(
          sceneStack.describeApproximatePaintClip(sceneStack.firstChild!),
          isNull,
          reason:
              'at ${width}dp the 350x388 scene frame must be scaled down in '
              'full; a non-null clip rect means content is cropped (at 320dp '
              'the top-right coin sits at design x=308..342 and is entirely '
              'cut off; the nest and circle right edges are cut too). '
              'See docs/screens/P01/3_test.md.',
        );

        await disposeApp(tester);
      });
    }
  });
}
