// K06 · Pip's nest — the non-loaded states (1_plan.md §4): loading,
// load-failure + "Try again", and no-active-child. The happy path lives in
// `pip_nest_view_test.dart`; the pixel geometry in
// `pip_nest_widget_test.dart`.
//
// Paths that a healthy Seed.demo database cannot produce are driven with
// two feature-local repository subclasses swapped into GetIt before the app
// is pumped (the K03 `kid_home_view_test.dart` pattern):
//   * `_ControlledNestRepository` — a nest stream the test feeds by hand, so
//     the loading state can be observed (the spinner never settles) and then
//     released into a real nest.
//   * `_FlakyNestRepository` — the stream errors until the test flips it, so
//     the failure card's "Try again" can be exercised for real.
//
// `Seed.empty()` gives the third state: an onboarded family with no children,
// so `app_state.active_child_id` is null and the bloc loads a null nest.
//
// Every test ends with `disposeApp` INSIDE the test body (RULES §7.1).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipStage;
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/pip/data/pip_repository_impl.dart';
import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/entities/pip_profile.dart';
import 'package:nestling/features/pip/domain/entities/pip_stage.dart'
    show PipStage;
import 'package:nestling/features/pip/domain/pip_repository.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_wardrobe_tile.dart';

import '../../test_scope.dart';

/// Nest stream the test drives by hand: [gate] emits nothing until the test
/// adds a nest or flips [fail] to make it error.
class _ControlledNestRepository extends PipRepositoryImpl {
  _ControlledNestRepository({required super.db});

  final StreamController<PipNest?> gate = StreamController<PipNest?>();
  bool fail = false;

  @override
  Stream<PipNest?> watchNest() {
    if (fail) return Stream<PipNest?>.error(Exception('nest down'));
    return gate.stream;
  }
}

/// The stream errors while [failNest] is true; the failure card's
/// "Try again" then really reloads.
class _FlakyNestRepository extends PipRepositoryImpl {
  _FlakyNestRepository({required super.db});

  bool failNest = true;

  @override
  Stream<PipNest?> watchNest() {
    if (failNest) return Stream<PipNest?>.error(Exception('nest down'));
    return super.watchNest();
  }
}

Future<void> _useRepository(PipRepository repo) async {
  await GetIt.instance.unregister<PipRepository>();
  GetIt.instance.registerSingleton<PipRepository>(repo);
}

/// Bounded route pumps. `pumpAndSettle` is avoided on purpose: the loading
/// spinner is an endless animation, so a screen that is still loading would
/// spin it forever (same reasoning as K03's `_settleRoute`).
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Pumps `/pip` on a [width]×844 surface with [textScale].
Future<void> _pumpNest(
  WidgetTester tester, {
  double width = NestDevice.width,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await pumpAppRoute(tester, '/pip', theme: theme);
  // `pumpAppRoute` pins 390x844 ITSELF, so a surface set before the pump is
  // silently overwritten and the width matrix runs at 390 (stage 6's
  // test-infrastructure note). Apply it after, re-lay out, and assert the
  // size so this cannot rot again.
  tester.view.physicalSize = Size(width * 3, NestDevice.height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pump();
  expect(
    tester.view.physicalSize.width / tester.view.devicePixelRatio,
    width,
    reason: 'this test must really run at $width logical px',
  );
}

/// The real VoiceOver/TalkBack activation, after checking the node
/// advertises the action.
void performTap(WidgetTester tester, Finder finder) {
  final node = tester.getSemantics(finder);
  expect(
    node.getSemanticsData().hasAction(SemanticsAction.tap),
    isTrue,
    reason: 'the control must expose SemanticsAction.tap',
  );
  node.owner!.performAction(node.id, SemanticsAction.tap);
}

bool hasTap(WidgetTester tester, Finder finder) {
  return tester
      .getSemantics(finder)
      .getSemanticsData()
      .hasAction(SemanticsAction.tap);
}

/// The chrome every state shares: the 56 px back tile and the 56 px
/// grown-ups lock at the design's 20 px gutters, under the 47 px status
/// reserve.
void _expectChrome(WidgetTester tester) {
  final back = tester.getRect(find.byKey(const Key('k06-back')));
  final lock = tester.getRect(find.byKey(const Key('k06-lock')));
  expect(back.left, closeTo(NestSpacing.padSide, 1.5));
  expect(back.top, closeTo(NestDevice.statusH, 1.5));
  expect(back.width, closeTo(NestDevice.tapKid, 1.5));
  expect(back.height, closeTo(NestDevice.tapKid, 1.5));
  expect(lock.right, closeTo(NestDevice.width - NestSpacing.padSide, 1.5));
  expect(lock.top, closeTo(NestDevice.statusH, 1.5));
  expect(lock.width, closeTo(NestDevice.tapKid, 1.5));
  expect(lock.height, closeTo(NestDevice.tapKid, 1.5));
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await setUpTestScope();
  });

  group('loading', () {
    testWidgets('the spinner is announced and the nest is not on screen yet', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final repo = _ControlledNestRepository(db: db);
      await _useRepository(repo);
      addTearDown(() async {
        if (!repo.gate.isClosed) await repo.gate.close();
      });

      await _pumpNest(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Loading Pip'), findsOneWidget);
      // Nothing from the loaded body leaks into the loading state.
      expect(find.byKey(const Key('k06-title')), findsNothing);
      expect(find.byKey(const Key('k06-pet')), findsNothing);
      expect(find.byKey(const Key('k06-grow')), findsNothing);
      expect(find.text('Pip $_middot Fledgling'), findsNothing);
      // The shared kid meadow is there from the first frame (owner KID
      // BACKGROUND rule), not only once the nest loads.
      expect(find.byType(NestMeadow), findsOneWidget);
      _expectChrome(tester);
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the first nest emission replaces the spinner', (tester) async {
      final repo = _ControlledNestRepository(db: db);
      await _useRepository(repo);
      addTearDown(() async {
        if (!repo.gate.isClosed) await repo.gate.close();
      });
      await _pumpNest(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // A literal Maya nest (same numbers as Seed.demo), so the loading state
      // can be released WITHOUT awaiting a Drift stream inside the fake-async
      // zone — that await never completes there and wedges the whole file.
      repo.gate.add(_mayaNest);
      await _settle(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const Key('k06-title')), findsOneWidget);
      expect(find.text('Pip $_middot Fledgling'), findsOneWidget);
      expect(currentPath(tester), '/pip');
      await disposeApp(tester);
    });
  });

  group('load failure', () {
    testWidgets('the failure card explains itself and offers Try again', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _useRepository(_FlakyNestRepository(db: db));
      await _pumpNest(tester);

      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
      expect(find.text("Let's try again."), findsOneWidget);
      expect(find.byKey(const Key('k06-title')), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // No child is known on this path, so the neutral look stands in
      // (orchestrator PIP rule) — never a v1 stage illustration.
      final avatar = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(avatar.style, PipStyle.mochi);
      expect(avatar.skin, PipSkin.sunny);
      // The retry is a real control: kid-sized and operable.
      final retry = tester.getRect(find.byType(NestKidButton));
      expect(retry.height, greaterThanOrEqualTo(NestDevice.tapKid));
      expect(hasTap(tester, find.byType(NestKidButton)), isTrue);
      _expectChrome(tester);
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('Try again really reloads the nest', (tester) async {
      final repo = _FlakyNestRepository(db: db);
      await _useRepository(repo);
      await _pumpNest(tester);
      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);

      repo.failNest = false;
      await tester.tap(find.byType(NestKidButton));
      await _settle(tester);

      expect(find.text('Oh no! Pip got lost.'), findsNothing);
      expect(find.text('Pip $_middot Fledgling'), findsOneWidget);
      expect(find.byType(PipWardrobeTile), findsNWidgets(4));
      expect(currentPath(tester), '/pip');
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the accessibility path reloads the nest too', (tester) async {
      final semantics = tester.ensureSemantics();
      final repo = _FlakyNestRepository(db: db);
      await _useRepository(repo);
      await _pumpNest(tester);
      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
      // Healthy again BEFORE the retry, so the tap really reloads.
      repo.failNest = false;

      performTap(tester, find.bySemanticsLabel('Try again'));
      await _settle(tester);

      expect(find.text('Pip $_middot Fledgling'), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets(
      'the back tile still leaves to kid home from the failure card',
      (tester) async {
        await _useRepository(_FlakyNestRepository(db: db));
        await _pumpNest(tester);

        await tester.tap(find.bySemanticsLabel('Back'));
        await _settle(tester);
        expect(currentPath(tester), '/kid-home');
        await disposeApp(tester);
      },
    );

    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in const <double>[320, 430]) {
        testWidgets(
          '${theme.name} @${width.toInt()}px: the failure card fits',
          (tester) async {
            await _useRepository(_FlakyNestRepository(db: db));
            await _pumpNest(tester, theme: theme, width: width, textScale: 1.3);

            expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
            expect(find.byType(NestKidButton), findsOneWidget);
            expect(tester.takeException(), isNull);
            await disposeApp(tester);
          },
        );
      }
    }
  });

  group('no active child (Seed.empty)', () {
    Future<void> emptySeed(WidgetTester tester) async {
      await tester.runAsync(() async {
        await Seed.empty(db);
        await GetIt.instance<AppSession>().refresh();
      });
    }

    testWidgets("the screen asks who's playing and routes to the picker", (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await emptySeed(tester);
      await _pumpNest(tester);

      expect(find.text("Who's playing?"), findsOneWidget);
      expect(find.byKey(const Key('k06-title')), findsNothing);
      expect(find.byKey(const Key('k06-pet')), findsNothing);
      expect(find.byKey(const Key('k06-grow')), findsNothing);
      expect(find.text('Feed'), findsNothing);
      expect(find.text('Pip’s wardrobe'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(NestMeadow), findsOneWidget);
      _expectChrome(tester);

      performTap(tester, find.bySemanticsLabel('Choose'));
      await _settle(tester);
      expect(pushedPath(tester), '/who-is-playing');
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the pointer path lands on the picker too', (tester) async {
      await emptySeed(tester);
      await _pumpNest(tester);

      await tester.tap(find.text('Choose'));
      await _settle(tester);
      expect(pushedPath(tester), '/who-is-playing');
      await disposeApp(tester);
    });

    testWidgets('back goes to kid home (nothing to pop)', (tester) async {
      await emptySeed(tester);
      await _pumpNest(tester);

      await tester.tap(find.bySemanticsLabel('Back'));
      await _settle(tester);
      expect(currentPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: the no-child card fits', (tester) async {
        await emptySeed(tester);
        await _pumpNest(tester, theme: theme, textScale: 1.3);

        expect(find.text("Who's playing?"), findsOneWidget);
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });
    }
  });

  group('non-controls advertise no tap action', () {
    testWidgets('nothing on the loaded screen reads as a phantom button', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpNest(tester);

      // Every control on K06, and nothing else.
      for (final label in const <String>[
        'Back',
        'Grown-ups',
        'Feed Pip, costs 5 coins',
        'Play with Pip, free',
        'Bathe Pip, costs 3 coins',
        'Scarf, Owned',
        'Sun hat, Owned',
        'Wellies, 40 coins',
        'Crown, 120 coins',
      ]) {
        expect(
          hasTap(tester, find.bySemanticsLabel(label)),
          isTrue,
          reason: label,
        );
      }
      // Informative text: the title, the growth copy, the caption and the
      // progress bar are not controls.
      expect(
        hasTap(tester, find.bySemanticsLabel(RegExp('Pip is 70 percent'))),
        isFalse,
      );
      expect(hasTap(tester, find.byKey(const Key('k06-caption'))), isFalse);
      expect(hasTap(tester, find.byKey(const Key('k06-title'))), isFalse);
      expect(hasTap(tester, find.byKey(const Key('k06-grow'))), isFalse);
      expect(
        hasTap(
          tester,
          find.bySemanticsLabel('Pip the Fledgling, stage 3 of 4'),
        ),
        isFalse,
        reason: 'the pet is an image, not a control',
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the failure and no-child headings are not buttons', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _useRepository(_FlakyNestRepository(db: db));
      await _pumpNest(tester);
      expect(
        hasTap(tester, find.bySemanticsLabel('Oh no! Pip got lost.')),
        isFalse,
      );
      expect(hasTap(tester, find.bySemanticsLabel('Try again')), isTrue);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the no-child heading is not a button but Choose is', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.runAsync(() async {
        await Seed.empty(db);
        await GetIt.instance<AppSession>().refresh();
      });
      await _pumpNest(tester);
      expect(hasTap(tester, find.bySemanticsLabel("Who's playing?")), isFalse);
      expect(hasTap(tester, find.bySemanticsLabel('Choose')), isTrue);
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  test('the controlled repository hands out a real Maya nest', () async {
    // Guards the fixtures above against a silently-empty Seed.demo.
    final repo = PipRepositoryImpl(db: db);
    final nest = await repo.watchNest().first;
    expect(nest, isNotNull);
    expect(nest!.profile.childId, 'maya');
    expect(nest.items, hasLength(4));
  });
}

/// · — HTML `&middot;` (U+00B7).
const String _middot = '·';

/// Maya's nest exactly as `Seed.demo` writes it, so the loading state can be
/// released by hand. Constructed as data (never read from Drift inside a
/// `testWidgets` body — that await never completes in the fake-async zone).
const PipNest _mayaNest = PipNest(
  profile: PipProfile(
    childId: 'maya',
    nickname: 'Maya',
    style: 'mochi',
    skin: 'sunny',
    accessory: 'none',
    stage: 3,
    totalCoins: 175,
    coins: 120,
    happiness: 4,
  ),
  items: <PipStage>[
    PipStage(
      id: 'scarf',
      title: 'Scarf',
      detail: 'Owned',
      owned: true,
      priceCoins: 0,
    ),
    PipStage(
      id: 'sunhat',
      title: 'Sun hat',
      detail: 'Owned',
      owned: true,
      priceCoins: 0,
    ),
    PipStage(
      id: 'wellies',
      title: 'Wellies',
      detail: '40 coins',
      owned: false,
      priceCoins: 40,
    ),
    PipStage(
      id: 'crown',
      title: 'Crown',
      detail: '120 coins',
      owned: false,
      priceCoins: 120,
    ),
  ],
);
