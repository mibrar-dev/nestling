// P02 Value tour — widget contract.
//
// Covers: the static tour copy and preview cards, light + dark themes,
// widths 320/390/430 at text scales 1.0/1.3, pager behaviour (Next taps,
// swipe, reduced-motion jump), navigation to /create-account, every
// OnboardingBloc status (initial/loading/empty/loaded/failure), the
// PipAvatar orchestrator rule and the accessibility contract (semantic
// labels, 44dp parent tap targets, no kid controls).
//
// The tour is static marketing copy (mirroring OnboardingRepositoryImpl._steps
// verbatim), so every bloc status renders the identical screen — the same
// pattern as P01 `welcome_view_test.dart`.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/london_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart' as v2;
import 'package:nestling/features/onboarding/domain/entities/onboarding_step.dart';
import 'package:nestling/features/onboarding/domain/onboarding_repository.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:nestling/features/onboarding/presentation/views/value_tour_view.dart';
import 'package:nestling/features/onboarding/presentation/widgets/value_tour_preview_row.dart';

import '../../test_scope.dart';

const String _step1Title = 'Set quests in seconds';
const String _step1Body =
    "Pick from 40+ ready-made jobs like 'Put the bins out' or make your own.";
const String _step2Title = 'Pip grows as they help';
const String _step3Title = 'Pocket money, sorted';
const String _step3Body =
    'No bank card needed — we keep score, you pay your way.';
const String _pipLabel = 'Pip the fledgling bird';

/// Expected date chip: the next payout Saturday strictly after the pinned
/// story day. Mirrors the view's derivation against `Seed.anchorDay`
/// (Sat 3 Oct 2026 under the test clock → `Sat 10 Oct`); the weekday part is
/// generically guarded by `p02_bugs_test.dart` P02-BUG-5.
String _expectedPayoutChip() {
  final anchor = Seed.anchorDay;
  var ahead = (DateTime.saturday - anchor.weekday) % 7;
  if (ahead == 0) {
    ahead = DateTime.daysPerWeek;
  }
  return formatLondonDay(anchor.add(Duration(days: ahead)));
}

/// Any SvgPicture still loading a v1 `pip_stage_*.svg` illustration.
Finder get _v1PipFinder => find.byWidgetPredicate(
  (widget) =>
      widget is SvgPicture &&
      widget.bytesLoader is SvgAssetLoader &&
      (widget.bytesLoader as SvgAssetLoader).assetName.startsWith(
        'assets/illustrations/pip_stage_',
      ),
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

/// Pumps `/value-tour` through the real app (router, DI, themes) at [surface]
/// and [textScale]. Mirrors [pumpAppRoute], which does not take size/scale.
Future<void> _pumpTour(
  WidgetTester tester, {
  required ThemeMode theme,
  required Size surface,
  required double textScale,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await pumpAppRoute(tester, '/value-tour', theme: theme);
  tester.view.physicalSize = surface * 3;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Pumps [ValueTourView] directly (no router) under the real theme with
/// [repository] driving the bloc; returns the bloc for state assertions.
Future<OnboardingBloc> _pumpTourView(
  WidgetTester tester, {
  required OnboardingRepository repository,
  required ThemeMode theme,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final bloc = OnboardingBloc(repository: repository);
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      themeMode: theme,
      home: BlocProvider<OnboardingBloc>.value(
        value: bloc,
        child: const ValueTourView(),
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

Future<void> _tapNext(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('p02_next')));
  await tester.pumpAndSettle();
}

/// The tour card that contains [text] (all three are [NestCard]s).
Finder _cardWith(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(NestCard));

/// The single progress bar inside [card].
NestProgress _progressIn(WidgetTester tester, Finder card) =>
    tester.widget<NestProgress>(
      find.descendant(of: card, matching: find.byType(NestProgress)),
    );

/// Probe boundary for the BOTTOM EDGE owner rule (painted-pixel proof).
const Key _pixelProbe = ValueKey('p02_pixel_probe');

/// Pumps the real app inside a [RepaintBoundary] so painted pixels can be
/// sampled, optionally with an OS bottom inset (home-indicator devices).
Future<void> _pumpTourForPixels(
  WidgetTester tester, {
  required ThemeMode theme,
  required Size surface,
  double bottomInset = 0,
}) async {
  GetIt.instance<ThemeModeController>().selectMode(theme);
  tester.view.physicalSize = surface * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  if (bottomInset > 0) {
    // View padding is physical; the test surface is 3x.
    tester.view.padding = FakeViewPadding(bottom: bottomInset * 3);
    addTearDown(tester.view.resetPadding);
  }
  await tester.pumpWidget(
    const RepaintBoundary(
      key: _pixelProbe,
      child: NestlingApp(initialRoute: '/value-tour'),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Painted RGBA bytes at logical (x, y) of the app surface.
Future<List<int>> _pixelAt(WidgetTester tester, double x, double y) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_pixelProbe),
  );
  late List<int> pixel;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData();
    final offset = (y.round() * image.width + x.round()) * 4;
    pixel = <int>[
      data!.getUint8(offset),
      data.getUint8(offset + 1),
      data.getUint8(offset + 2),
      data.getUint8(offset + 3),
    ];
  });
  return pixel;
}

/// The opaque RGBA bytes of [color] at 8-bit precision.
List<int> _rgba(Color color) => <int>[
  (color.r * 255).round(),
  (color.g * 255).round(),
  (color.b * 255).round(),
  255,
];

void main() {
  group('P02 value tour — copy, theming, width and scale', () {
    testWidgets('light: renders card 1, dots, step copy and CTAs', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // Orchestrator rule: NestStatusBar only reserves height — the OS
      // draws the real status bar, so no mock clock glyphs in the app.
      expect(find.text('9:41'), findsNothing);
      expect(find.byType(NestStatusBar), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text("Today's quests"), findsOneWidget);
      expect(find.text(_expectedPayoutChip()), findsWidgets);
      expect(find.text('Sat 4 Oct'), findsNothing);
      expect(find.text('Empty the dishwasher'), findsOneWidget);
      expect(find.text('Put the bins out'), findsOneWidget);
      expect(find.text('Reading – 20 minutes'), findsOneWidget);
      expect(find.text('Tidy your bedroom'), findsOneWidget);
      expect(find.text('4 of 6 quests done today'), findsOneWidget);
      expect(find.text('New quest'), findsOneWidget);
      expect(find.byType(NestPagerDots), findsOneWidget);
      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text(_step1Body), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.byKey(const ValueKey('p02_continue')), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('dark: renders the same content without overflow', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.dark,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(find.text("Today's quests"), findsOneWidget);
      expect(find.text('Empty the dishwasher'), findsOneWidget);
      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text(_step1Body), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
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
            await _pumpTour(
              tester,
              theme: theme,
              surface: Size(width.toDouble(), 844),
              textScale: scale,
            );

            expect(find.text(_step1Title), findsOneWidget);
            expect(find.text('Next'), findsOneWidget);
            expect(find.text('Skip'), findsOneWidget);
            expect(tester.takeException(), isNull);

            await disposeApp(tester);
          });
        }
      }
    }
  });

  group(
    'P02 value tour — Pip is the v2 avatar (mandatory orchestrator rule)',
    () {
      testWidgets('exactly 4 PipAvatars, all mochi/sunny, stages [3,1,2,3]', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpTour(
          tester,
          theme: ThemeMode.light,
          surface: const Size(390, 844),
          textScale: 1,
        );

        // The v1 onboarding SVGs must never render in a product screen.
        expect(_v1PipFinder, findsNothing);

        // The main Pip lives on step 2: advance the pager so its semantics
        // node is onscreen (offscreen nodes stay out of the semantics tree).
        await _tapNext(tester);

        final avatars = tester
            .widgetList<v2.PipAvatar>(find.byType(v2.PipAvatar))
            .toList();
        expect(avatars.map((a) => a.stage).toList(), const [3, 1, 2, 3]);
        for (final avatar in avatars) {
          expect(avatar.style, v2.PipStyle.mochi);
          expect(avatar.skin, v2.PipSkin.sunny);
        }

        // The main Pip fills its 158x158 slot and carries the design alt text.
        final mainRect = tester.getRect(find.bySemanticsLabel(_pipLabel));
        expect(mainRect.width, moreOrLessEquals(158, epsilon: 0.01));
        expect(mainRect.height, moreOrLessEquals(158, epsilon: 0.01));

        await disposeApp(tester);
      });
    },
  );

  group('P02 value tour — pager behaviour', () {
    testWidgets('Next advances one step at a time, then becomes Continue', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await _tapNext(tester);
      expect(find.text(_step2Title), findsOneWidget);
      expect(tester.widget<NestPagerDots>(find.byType(NestPagerDots)).index, 1);
      expect(find.byKey(const ValueKey('p02_next')), findsOneWidget);

      await _tapNext(tester);
      expect(find.text(_step3Title), findsOneWidget);
      expect(find.text(_step3Body), findsOneWidget);
      expect(tester.widget<NestPagerDots>(find.byType(NestPagerDots)).index, 2);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byKey(const ValueKey('p02_continue')), findsOneWidget);
      expect(find.byKey(const ValueKey('p02_next')), findsNothing);
      expect(find.text("Maya's jar"), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('swipe left advances, swipe right returns', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text(_step2Title), findsOneWidget);

      await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text(_step1Title), findsOneWidget);
      expect(tester.widget<NestPagerDots>(find.byType(NestPagerDots)).index, 0);

      await disposeApp(tester);
    });

    testWidgets('reduced motion still advances via jump', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      final bloc = OnboardingBloc(
        repository: _FakeOnboardingRepository(
          Stream<List<OnboardingStep>>.value(const <OnboardingStep>[]),
        ),
      );
      addTearDown(bloc.close);
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          darkTheme: NestTheme.dark(),
          home: Builder(
            builder: (context) {
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(disableAnimations: true),
                child: BlocProvider<OnboardingBloc>.value(
                  value: bloc,
                  child: const ValueTourView(),
                ),
              );
            },
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('p02_next')));
      await tester.pump();

      expect(find.text(_step2Title), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });
  });

  group('P02 value tour — navigation', () {
    testWidgets('Skip opens /create-account', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(find.byKey(const ValueKey('p02_skip')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/create-account');

      await disposeApp(tester);
    });

    testWidgets('Continue on the last step opens /create-account', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await _tapNext(tester);
      await _tapNext(tester);
      await tester.tap(find.byKey(const ValueKey('p02_continue')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/create-account');

      await disposeApp(tester);
    });

    testWidgets('Next on steps 1-2 stays on /value-tour', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await _tapNext(tester);
      expect(currentPath(tester), '/value-tour');

      await disposeApp(tester);
    });

    testWidgets('tapping a preview row does not navigate', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(find.text('Empty the dishwasher'));
      await tester.pump();

      expect(currentPath(tester), '/value-tour');

      await disposeApp(tester);
    });
  });

  group('P02 value tour — BLoC states render the identical tour', () {
    setUp(() {
      GoogleFonts.config.allowRuntimeFetching = false;
    });

    testWidgets('initial: tour renders before the load event', (tester) async {
      final bloc = await _pumpTourView(
        tester,
        repository: _FakeOnboardingRepository(
          const Stream<List<OnboardingStep>>.empty(),
        ),
        theme: ThemeMode.light,
      );

      expect(bloc.state.status, OnboardingStatus.initial);
      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('loading: tour renders while no items have arrived', (
      tester,
    ) async {
      final bloc = await _pumpTourView(
        tester,
        repository: _FakeOnboardingRepository(
          const Stream<List<OnboardingStep>>.empty(),
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const OnboardingLoadRequested());
      await tester.pump();

      expect(bloc.state.status, OnboardingStatus.loading);
      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text('Empty the dishwasher'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('loaded with no items: still the full tour', (tester) async {
      final bloc = await _pumpTourView(
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
      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('loaded with items: the same static tour', (tester) async {
      final bloc = await _pumpTourView(
        tester,
        repository: _FakeOnboardingRepository(
          Stream<List<OnboardingStep>>.value(const <OnboardingStep>[
            OnboardingStep(
              id: 'quests',
              title: _step1Title,
              detail: _step1Body,
            ),
          ]),
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const OnboardingLoadRequested());
      await tester.pump();

      expect(bloc.state.status, OnboardingStatus.loaded);
      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text(_step1Body), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });

    testWidgets('failure: a repository error never blocks the tour', (
      tester,
    ) async {
      final bloc = await _pumpTourView(
        tester,
        repository: _FakeOnboardingRepository(
          Stream<List<OnboardingStep>>.error(Exception('offline')),
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const OnboardingLoadRequested());
      await tester.pump();

      expect(bloc.state.status, OnboardingStatus.failure);
      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });
  });

  group('P02 value tour — accessibility', () {
    testWidgets('labels, pager group and tap targets meet the contract', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // The step title is the screen's only heading (HTML `<h1>`).
      final titleData = tester
          .getSemantics(find.text(_step1Title))
          .getSemanticsData();
      expect(titleData.flagsCollection.isHeader, isTrue);

      // The pager exposes its group label, updating per step (HTML
      // `role=group` aria-label).
      expect(
        find.bySemanticsLabel('Tour preview, step 1 of 3'),
        findsOneWidget,
      );

      // Skip and Next expose button semantics with their labels, and Skip
      // carries its activation action on the labeled node itself.
      final skipData = tester
          .getSemantics(find.byKey(const ValueKey('p02_skip')))
          .getSemanticsData();
      expect(skipData.label, 'Skip');
      expect(skipData.flagsCollection.isButton, isTrue);
      expect(skipData.hasAction(SemanticsAction.tap), isTrue);
      final nextData = tester
          .getSemantics(find.byKey(const ValueKey('p02_next')))
          .getSemanticsData();
      expect(nextData.label, 'Next');
      expect(nextData.flagsCollection.isButton, isTrue);

      // Decorative chrome carries no semantics; P02 has no icon-only
      // buttons and no kid controls.
      expect(find.bySemanticsLabel('9:41'), findsNothing);
      expect(find.byType(NestIconButton), findsNothing);
      expect(find.byType(NestKidButton), findsNothing);

      // Parent rule: Skip is at least 44x44, Next is a 52dp pill CTA.
      final skipSize = tester.getSize(find.byKey(const ValueKey('p02_skip')));
      final nextSize = tester.getSize(find.byKey(const ValueKey('p02_next')));
      expect(skipSize.height, greaterThanOrEqualTo(NestDevice.tapParent));
      expect(skipSize.width, greaterThanOrEqualTo(NestDevice.tapParent));
      expect(nextSize.height, greaterThanOrEqualTo(52));
      expect(nextSize.width, 390 - 2 * NestSpacing.padSide);

      await disposeApp(tester);
    });

    testWidgets('tap targets hold at 320dp with text scale 1.3', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(320, 844),
        textScale: 1.3,
      );

      final skipSize = tester.getSize(find.byKey(const ValueKey('p02_skip')));
      final nextSize = tester.getSize(find.byKey(const ValueKey('p02_next')));
      expect(skipSize.height, greaterThanOrEqualTo(NestDevice.tapParent));
      expect(nextSize.height, greaterThanOrEqualTo(52));
      expect(nextSize.width, 320 - 2 * NestSpacing.padSide);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P02 value tour — route wiring and Drift seeds', () {
    testWidgets('route provides a working bloc whose load reaches loaded', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // `BlocProvider` is lazy and the static tour never reads the bloc, so
      // the route's `OnboardingLoadRequested` only runs on the first read —
      // after which the state machine loads the three steps (observed
      // behaviour, pinned deliberately; no user impact on P02).
      final bloc = BlocProvider.of<OnboardingBloc>(
        tester.element(find.byType(ValueTourView)),
      );
      await tester.pump();
      await tester.pump();
      expect(bloc.state.status, OnboardingStatus.loaded);
      expect(bloc.state.items.map((step) => step.title), const [
        _step1Title,
        _step2Title,
        _step3Title,
      ]);

      await disposeApp(tester);
    });

    testWidgets('Seed.empty (onboarded, no children): identical tour', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();

      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text('Empty the dishwasher'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('Seed.fresh: /value-tour renders during first-run setup', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.fresh(db);
      await GetIt.instance<AppSession>().refresh();

      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(currentPath(tester), '/value-tour');
      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P02 value tour — pager geometry and card content', () {
    for (final width in const <int>[320, 390, 430]) {
      testWidgets('width $width: card clamps and the next card peeks', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpTour(
          tester,
          theme: ThemeMode.light,
          surface: Size(width.toDouble(), 844),
          textScale: 1,
        );

        final cardW = math.min(310, math.max(240, width - 80)).toDouble();
        final rect = tester.getRect(_cardWith("Today's quests"));
        expect(rect.left, moreOrLessEquals(NestSpacing.padSide, epsilon: 0.01));
        expect(rect.width, moreOrLessEquals(cardW, epsilon: 0.01));

        // The next card starts one pitch later (cardW + the 12px design gap,
        // c2 left 342 = 20 + 310 + 12), clipped by the pager edge exactly
        // like the design's peek.
        final peek = tester.getRect(_cardWith("Pip's nest"));
        expect(
          peek.left,
          moreOrLessEquals(NestSpacing.padSide + cardW + 12, epsilon: 0.01),
        );
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      });
    }

    testWidgets('card 1 previews the seeded quests, coins and progress', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      final card = _cardWith("Today's quests");
      Finder inCard(Finder matching) =>
          find.descendant(of: card, matching: matching);

      expect(inCard(find.text('Maya · daily')), findsNWidgets(3));
      expect(inCard(find.text('Maya · weekly')), findsOneWidget);
      expect(inCard(find.text('4 of 6 quests done today')), findsOneWidget);

      final pills = tester
          .widgetList<NestCoinPill>(inCard(find.byType(NestCoinPill)))
          .map((pill) => pill.amount)
          .toList();
      expect(pills, const ['15', '15', '10', '15']);
      expect(
        _progressIn(tester, card).fraction,
        moreOrLessEquals(4 / 6, epsilon: 1e-9),
      );

      // The dashed add-row is a non-interactive preview whose label stays
      // exposed as plain text (the HTML does not hide it).
      expect(inCard(find.text('New quest')), findsOneWidget);
      expect(inCard(find.bySemanticsLabel('New quest')), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('card 2 shows the Pip stage copy', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );
      await _tapNext(tester);

      final card = _cardWith("Pip's nest");
      Finder inCard(Finder matching) =>
          find.descendant(of: card, matching: matching);

      expect(inCard(find.text('Fledgling')), findsNWidgets(2)); // chip + label
      expect(
        inCard(find.text('175 of 250 coins · Pip evolves at 250')),
        findsOneWidget,
      );
      expect(inCard(find.text('Next stage: Songbird')), findsOneWidget);

      final chip = tester.widget<NestChip>(inCard(find.byType(NestChip)));
      expect(chip.label, 'Fledgling');
      expect(chip.selected, isTrue);
      expect(
        _progressIn(tester, card).fraction,
        moreOrLessEquals(0.7, epsilon: 1e-9),
      );

      await disposeApp(tester);
    });

    testWidgets('card 3 ledger matches the seeded Maya balance', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );
      await _tapNext(tester);
      await _tapNext(tester);

      // DATA OVER MOCKS: the expected strings come from the Drift rows, not
      // from literals shared with the view.
      final maya = (await db.select(db.children).get()).firstWhere(
        (child) => child.id == 'maya',
      );
      final family = (await db.select(db.families).get()).single;
      final basePence = maya.weeklyBasePence;
      final bonusPence = maya.coins * family.coinValuePencePerCoin;

      final card = _cardWith("Maya's jar");
      Finder inCard(Finder matching) =>
          find.descendant(of: card, matching: matching);

      expect(inCard(find.text('coming on Saturday')), findsOneWidget);
      expect(inCard(find.text('Weekly base')), findsOneWidget);
      expect(inCard(find.text(formatPounds(basePence / 100))), findsOneWidget);
      expect(inCard(find.text('Quests (${maya.coins} coins)')), findsOneWidget);
      expect(
        inCard(find.text('+${formatPounds(bonusPence / 100)}')),
        findsOneWidget,
      );
      expect(inCard(find.text('Total')), findsOneWidget);
      expect(
        inCard(find.text(formatPounds((basePence + bonusPence) / 100))),
        findsNWidgets(2),
      );
      expect(inCard(find.text('No bank card needed')), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('steps 2-3 hold at 320dp with text scale 1.3', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.dark,
        surface: const Size(320, 844),
        textScale: 1.3,
      );

      await _tapNext(tester);
      expect(find.text(_step2Title), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _tapNext(tester);
      expect(find.text(_step3Title), findsOneWidget);
      expect(find.byKey(const ValueKey('p02_continue')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('pager height follows the text-scale rule at 1.0', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(
        tester.getSize(find.byType(PageView)).height,
        moreOrLessEquals(400, epsilon: 0.01),
      );

      await disposeApp(tester);
    });

    testWidgets('pager height follows the text-scale rule at 1.3', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1.3,
      );

      expect(
        tester.getSize(find.byType(PageView)).height,
        moreOrLessEquals(400 * 1.3, epsilon: 0.01),
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P02 value tour — pager controls', () {
    testWidgets('dots are non-interactive indicators', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(find.byType(NestPagerDots));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text(_step1Title), findsOneWidget);
      expect(tester.widget<NestPagerDots>(find.byType(NestPagerDots)).index, 0);
      expect(currentPath(tester), '/value-tour');

      await disposeApp(tester);
    });

    testWidgets('swiping to the last step swaps the CTA to Continue', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      await tester.fling(find.byType(PageView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text(_step3Title), findsOneWidget);
      expect(find.byKey(const ValueKey('p02_continue')), findsOneWidget);
      expect(find.byKey(const ValueKey('p02_next')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('p02_continue')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(currentPath(tester), '/create-account');

      await disposeApp(tester);
    });

    testWidgets('swiping back at step 1 stays on step 1', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.fling(find.byType(PageView), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text(_step1Title), findsOneWidget);
      expect(tester.widget<NestPagerDots>(find.byType(NestPagerDots)).index, 0);
      expect(currentPath(tester), '/value-tour');

      await disposeApp(tester);
    });
  });

  group('P02 value tour — accessibility extensions', () {
    testWidgets('pager group and dots labels follow the current step', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(
        find.bySemanticsLabel('Tour preview, step 1 of 3'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Page 1 of 3'), findsOneWidget);

      // Dots are indicators, not controls (the HTML has plain spans).
      expect(find.bySemanticsLabel('Go to page 1'), findsNothing);
      expect(find.bySemanticsLabel('Go to page 2'), findsNothing);
      expect(find.bySemanticsLabel('Go to page 3'), findsNothing);

      await _tapNext(tester);

      expect(
        find.bySemanticsLabel('Tour preview, step 2 of 3'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Page 2 of 3'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('preview add-rows expose plain-text labels', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // Non-interactive, but exposed (the HTML does not hide them).
      expect(find.bySemanticsLabel('New quest'), findsOneWidget);

      await _tapNext(tester);
      expect(find.bySemanticsLabel('Next stage: Songbird'), findsOneWidget);

      await _tapNext(tester);
      expect(find.bySemanticsLabel('No bank card needed'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('status bar reserves height only; no back affordance', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(
        tester.getSize(find.byType(NestStatusBar)).height,
        NestDevice.statusH,
      );
      expect(tester.getSize(find.byType(NestHomeIndicator)).height, 0);
      expect(find.byType(BackButton), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('Continue is a full-width 52dp target with button semantics', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );
      await _tapNext(tester);
      await _tapNext(tester);

      final size = tester.getSize(find.byKey(const ValueKey('p02_continue')));
      expect(size.height, greaterThanOrEqualTo(52));
      expect(size.width, 390 - 2 * NestSpacing.padSide);

      final data = tester
          .getSemantics(find.byKey(const ValueKey('p02_continue')))
          .getSemanticsData();
      expect(data.label, 'Continue');
      expect(data.flagsCollection.isButton, isTrue);

      await disposeApp(tester);
    });

    testWidgets('dark: card surface comes from the dark tokens', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.dark,
        surface: const Size(390, 844),
        textScale: 1,
      );

      final card = _cardWith("Today's quests");
      final container = tester.widget<Container>(
        find.descendant(of: card, matching: find.byType(Container)).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      final darkSurface = tester.element(card).nest.surface;
      final lightSurface = NestTheme.light().extension<NestTokens>()!.surface;

      expect(decoration.color, darkSurface);
      expect(darkSurface, isNot(lightSurface));

      await disposeApp(tester);
    });
  });

  group('P02 value tour — static copy is data-independent', () {
    setUp(() {
      GoogleFonts.config.allowRuntimeFetching = false;
    });

    testWidgets('late repository emissions never change the copy', (
      tester,
    ) async {
      final bloc = await _pumpTourView(
        tester,
        repository: _FakeOnboardingRepository(
          Stream<List<OnboardingStep>>.fromIterable(<List<OnboardingStep>>[
            const <OnboardingStep>[],
            const <OnboardingStep>[
              OnboardingStep(
                id: 'late',
                title: 'DIFFERENT TITLE',
                detail: 'DIFFERENT BODY',
              ),
            ],
          ]),
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const OnboardingLoadRequested());
      await tester.pump();
      await tester.pump();

      expect(bloc.state.status, OnboardingStatus.loaded);
      expect(bloc.state.items.map((step) => step.title), const [
        'DIFFERENT TITLE',
      ]);
      expect(find.text(_step1Title), findsOneWidget);
      expect(find.text('DIFFERENT TITLE'), findsNothing);
      expect(tester.takeException(), isNull);

      await _disposeView(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Owner rule — BOTTOM EDGE: the area below the bottom bar, down to the
  // physical screen edge, must carry the SAME surface colour as the bar
  // itself. A page-tint strip under the CTA panel is a UI failure in light
  // and dark mode alike.
  // -------------------------------------------------------------------------
  group('P02 value tour — owner rule: bottom edge', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final themeName = theme == ThemeMode.light ? 'light' : 'dark';

      testWidgets('$themeName: no page-colour strip under the CTA panel', (
        tester,
      ) async {
        await setUpTestScope();
        // A 34dp OS inset (home-indicator device) is where a strip shows up:
        // the bar content is lifted, the surface must not be.
        await _pumpTourForPixels(
          tester,
          theme: theme,
          surface: const Size(390, 844),
          bottomInset: 34,
        );

        final bar = tester.getRect(find.byType(NestBottomCta));
        expect(
          bar.bottom,
          moreOrLessEquals(844, epsilon: 0.01),
          reason:
              'the CTA panel must run to the physical screen edge; ending it '
              'at ${bar.bottom} exposes page colour below the bar',
        );

        // Painted-pixel proof: the last row of pixels the OS draws over must
        // be the bar surface, not the scaffold paper underneath.
        final tokens = tester.element(find.byType(NestBottomCta)).nest;
        expect(
          tokens.paper,
          isNot(tokens.surface),
          reason:
              'the probe must discriminate: page colour and bar surface are '
              'different colours, so a strip below the bar cannot pass',
        );
        final edgePixel = await _pixelAt(tester, 195, 843);
        expect(
          edgePixel,
          _rgba(tokens.surface),
          reason:
              'the strip below the bar (y=843, inside the 34dp inset) must be '
              'the bar surface ${_rgba(tokens.surface)}; the scaffold paper '
              '${_rgba(tokens.paper)} must not show through there',
        );

        await disposeApp(tester);
      });

      testWidgets('$themeName: bar surface is flush with the edge inset 0', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpTourForPixels(
          tester,
          theme: theme,
          surface: const Size(390, 844),
        );

        final bar = tester.getRect(find.byType(NestBottomCta));
        expect(bar.bottom, moreOrLessEquals(844, epsilon: 0.01));

        final tokens = tester.element(find.byType(NestBottomCta)).nest;
        final edgePixel = await _pixelAt(tester, 195, 843);
        expect(edgePixel, _rgba(tokens.surface));

        await disposeApp(tester);
      });
    }
  });

  // -------------------------------------------------------------------------
  // Owner rule — ALIGNMENT: consistent 20px side gutters, cards and bars on
  // the same edges, nothing a few px off.
  // -------------------------------------------------------------------------
  group('P02 value tour — owner rule: alignment', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in const <int>[320, 390, 430]) {
        final themeName = theme == ThemeMode.light ? 'light' : 'dark';
        testWidgets('$themeName ${width}dp: 20px gutters on every edge', (
          tester,
        ) async {
          await setUpTestScope();
          await _pumpTour(
            tester,
            theme: theme,
            surface: Size(width.toDouble(), 844),
            textScale: 1,
          );

          final cardW = math.min(310, math.max(240, width - 80)).toDouble();
          final card = tester.getRect(_cardWith("Today's quests"));
          final cta = tester.getRect(find.byKey(const ValueKey('p02_next')));
          final skip = tester.getRect(find.byKey(const ValueKey('p02_skip')));
          final bar = tester.getRect(find.byType(NestBottomCta));

          // Step copy and the CTA button both sit on the 20px gutter.
          expect(
            tester.getTopLeft(find.text(_step1Title)).dx,
            moreOrLessEquals(NestSpacing.padSide, epsilon: 0.01),
          );
          expect(
            cta.left,
            moreOrLessEquals(NestSpacing.padSide, epsilon: 0.01),
          );
          expect(
            cta.right,
            moreOrLessEquals(width - NestSpacing.padSide, epsilon: 0.01),
          );

          // The card shares the copy's left edge; its right edge is the
          // design's clipped peek (card 1 spans 20 … 20+cardW at 390).
          expect(
            card.left,
            moreOrLessEquals(NestSpacing.padSide, epsilon: 0.01),
          );
          expect(card.width, moreOrLessEquals(cardW, epsilon: 0.01));

          // The bar is full-bleed (its panel owns the edge rule) and Skip is
          // right-aligned to the same gutter as the button.
          expect(bar.left, 0);
          expect(bar.right, moreOrLessEquals(width.toDouble(), epsilon: 0.01));
          expect(
            skip.right,
            moreOrLessEquals(width - NestSpacing.padSide, epsilon: 0.01),
          );

          expect(tester.takeException(), isNull);

          await disposeApp(tester);
        });
      }
    }

    testWidgets('card content shares one inner left edge', (tester) async {
      await setUpTestScope();
      await _pumpTour(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      final card = _cardWith("Today's quests");
      final cardRect = tester.getRect(card);
      // The card pads its content by s4; every row of that content — head,
      // preview rows, progress bar, dashed add-row — starts on that one edge
      // (the preview-row *titles* sit further in, after their 36dp icon
      // tile, so the row container is the reference).
      final inner = cardRect.left + NestSpacing.s4;
      final rows = find.byType(ValueTourPreviewRow);
      expect(rows, findsNWidgets(4));

      for (final finder in <Finder>[
        find.text("Today's quests"),
        rows.first,
        find.descendant(of: card, matching: find.byType(NestProgress)),
        find.ancestor(
          of: find.text('New quest'),
          matching: find.byType(CustomPaint),
        ),
      ]) {
        expect(
          tester.getTopLeft(finder).dx,
          moreOrLessEquals(inner, epsilon: 0.01),
          reason: 'every card row must start on the same inner edge',
        );
      }

      await disposeApp(tester);
    });
  });
}
