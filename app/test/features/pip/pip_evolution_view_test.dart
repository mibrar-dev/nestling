// K07 view tests over the in-memory Drift database (`Seed.demo`): the copy,
// the database-driven numbers, both themes, every control's real navigation,
// and the failure / no-child states.
//
// Every test pumps the app at `/pip-evolution` and ends with `disposeApp`
// INSIDE the test body (RULES §7: Drift schedules a deferred stream-close
// timer on bloc disposal, and the pending-timer check runs before
// `addTearDown` callbacks).
//
// The pixel geometry pins live in `pip_evolution_widget_test.dart`.

import 'package:drift/drift.dart' show Value;
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
import 'package:nestling/features/pip/domain/entities/pip_evolution.dart';
import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/pip_repository.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_background.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_sparks.dart';

import '../../test_scope.dart';

/// Both K07 streams error while [fail] is true; the failure card's "Try again"
/// then really reloads (the K06 flaky-repository pattern).
///
/// BOTH streams must fail: the bloc keeps the loaded screen when either the
/// nest or the evolution already has data (K03 review-finding-6), so a failing
/// evolution stream alone would never reach the failure card on `Seed.demo`.
class _FlakyEvolutionRepository extends PipRepositoryImpl {
  _FlakyEvolutionRepository({required super.db});

  bool fail = true;

  @override
  Stream<PipNest?> watchNest() {
    if (fail) return Stream<PipNest?>.error(Exception('down'));
    return super.watchNest();
  }

  @override
  Stream<PipEvolution?> watchEvolution() {
    if (fail) return Stream<PipEvolution?>.error(Exception('down'));
    return super.watchEvolution();
  }
}

/// K07's stream fails while K06's stays healthy — the mirror of
/// [_FlakyEvolutionRepository]. Proves the screen keeps its own failure card
/// when `loaded` arrives from the OTHER stream.
class _FailingEvolutionOnlyRepository extends PipRepositoryImpl {
  _FailingEvolutionOnlyRepository({required super.db});

  @override
  Stream<PipEvolution?> watchEvolution() {
    return Stream<PipEvolution?>.error(Exception('down'));
  }
}

Future<void> _useRepository(PipRepository repo) async {
  await GetIt.instance.unregister<PipRepository>();
  GetIt.instance.registerSingleton<PipRepository>(repo);
}

/// Bounded pumps: `pumpAndSettle` would hang on the loading spinner's endless
/// animation, so every pump here is bounded (K06's `_settle`).
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Performs the real VoiceOver/TalkBack activation of [finder]'s node — not a
/// pointer tap — after checking the node advertises the action.
void performTap(WidgetTester tester, Finder finder) {
  final node = tester.getSemantics(finder);
  expect(
    node.getSemanticsData().hasAction(SemanticsAction.tap),
    isTrue,
    reason: 'the control must expose SemanticsAction.tap',
  );
  node.owner!.performAction(node.id, SemanticsAction.tap);
}

/// Maya's seeded values (lifetime, `Seed.demo`): stage 3, 175 lifetime coins,
/// and four completed quests (dishwasher + table pending, bins + hoover
/// approved). Expectations only — the view hard-codes no number.
const int _mayaStage = 3;
const int _mayaTotalCoins = 175;
const int _mayaQuestsDone = 4;

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await setUpTestScope();
  });

  Future<void> pumpEvolution(
    WidgetTester tester, {
    ThemeMode theme = ThemeMode.light,
  }) async {
    GetIt.instance<ThemeModeController>().selectMode(theme);
    await pumpAppRoute(tester, '/pip-evolution', theme: theme);
  }

  group('the loaded screen', () {
    testWidgets('shows the seeded child’s stage copy and DB numbers', (
      tester,
    ) async {
      await pumpEvolution(tester);

      // Title/sub/CTA are stage-driven, so the DB's stage 3 picks the words.
      expect(find.text('Pip grew into a Fledgling!'), findsOneWidget);
      expect(
        find.text('Because you helped $_mayaQuestsDone times'),
        findsOneWidget,
      );
      expect(find.text('Meet Fledgling Pip'), findsOneWidget);

      // The three stat cards carry DB numbers, never the design's literals
      // (the design says 25 / 250 / 4 — a later stage and a richer child).
      final stats = find.byKey(const Key('k07-stats'));
      expect(stats, findsOneWidget);
      expect(
        find.descendant(of: stats, matching: find.text('$_mayaQuestsDone')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: stats, matching: find.text('$_mayaTotalCoins')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: stats, matching: find.text('$_mayaStage')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: stats, matching: find.text('quests done')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: stats, matching: find.text('coins grown')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: stats, matching: find.text('of 4 stages')),
        findsOneWidget,
      );

      expect(find.text('Pip still loves a chin scratch.'), findsOneWidget);
      expect(find.text("Flap, flap! Look at Pip's wings!"), findsOneWidget);

      // The speech is the shared component, not a look-alike.
      expect(find.byType(NestSpeechBubble), findsOneWidget);
      // The design's own numbers must NOT appear.
      expect(find.text('Because you helped 25 times'), findsNothing);
      expect(find.text('Meet Songbird Pip'), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('renders the design’s stage slots (old Pip, arrow, new Pip)', (
      tester,
    ) async {
      await pumpEvolution(tester);

      expect(find.byKey(const Key('k07-stage')), findsOneWidget);
      expect(find.byKey(const Key('k07-old-pip')), findsOneWidget);
      expect(find.byKey(const Key('k07-arrow')), findsOneWidget);
      expect(find.byKey(const Key('k07-new-pip')), findsOneWidget);
      expect(find.byType(PipEvolutionSparks), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('both slots render the child’s own Pip, one stage apart', (
      tester,
    ) async {
      await pumpEvolution(tester);

      final avatars = tester
          .widgetList<PipAvatar>(find.byType(PipAvatar))
          .toList(growable: false);
      expect(avatars.length, 2);
      // ORCHESTRATOR PIP RULE: the DB's look (Maya = Mochi / sunny), never a
      // v1 `pip-stage-*.svg`.
      for (final avatar in avatars) {
        expect(avatar.style, PipStyle.mochi);
        expect(avatar.skin, PipSkin.sunny);
      }
      final stages = avatars.map((a) => a.stage).toList()..sort();
      expect(stages, <int>[_mayaStage - 1, _mayaStage]);

      await disposeApp(tester);
    });

    testWidgets('the new Pip is announced as an image of this child', (
      tester,
    ) async {
      await pumpEvolution(tester);

      final data = tester
          .getSemantics(find.byKey(const Key('k07-new-pip')))
          .getSemanticsData();
      expect(data.flagsCollection.isImage, isTrue);
      expect(data.label, "Maya's Pip, a fledgling");

      await disposeApp(tester);
    });

    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: renders on the lilac glow, stars in dark', (
        tester,
      ) async {
        await pumpEvolution(tester, theme: theme);

        expect(find.text('Pip grew into a Fledgling!'), findsOneWidget);
        expect(find.byType(PipEvolutionGlow), findsOneWidget);
        // `--kid-stars` is `none` in light, so the shared stars painter is
        // dark-only.
        expect(
          find.byType(PipEvolutionStars),
          theme == ThemeMode.dark ? findsOneWidget : findsNothing,
        );
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      });
    }

    testWidgets('the CTA goes to Pip’s nest (/pip)', (tester) async {
      await pumpEvolution(tester);
      expect(currentPath(tester), '/pip-evolution');

      await tester.tap(find.byKey(const Key('k07-cta')));
      await _settle(tester);

      expect(currentPath(tester), '/pip');
      await disposeApp(tester);
    });

    testWidgets('the lock pushes the parental gate (/parental-gate)', (
      tester,
    ) async {
      await pumpEvolution(tester);

      await tester.tap(find.byKey(const Key('k07-lock')));
      await _settle(tester);

      expect(pushedPath(tester), '/parental-gate');
      await disposeApp(tester);
    });
  });

  group('accessibility', () {
    testWidgets('the CTA’s real VoiceOver action navigates to /pip', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpEvolution(tester);

      performTap(tester, find.byKey(const Key('k07-cta')));
      await _settle(tester);

      expect(currentPath(tester), '/pip');
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the lock’s real VoiceOver action opens the gate', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpEvolution(tester);

      // The design's `aria-label` is `Grown-ups`, not the widget default.
      final node = tester.getSemantics(find.byKey(const Key('k07-lock')));
      expect(node.getSemanticsData().label, 'Grown-ups');
      performTap(tester, find.byKey(const Key('k07-lock')));
      await _settle(tester);

      expect(pushedPath(tester), '/parental-gate');
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the stats row announces one merged sentence', (tester) async {
      await pumpEvolution(tester);

      final label = tester
          .getSemantics(find.byKey(const Key('k07-stats')))
          .getSemanticsData()
          .label;
      expect(
        label,
        '$_mayaQuestsDone quests done, $_mayaTotalCoins coins grown, '
        'stage $_mayaStage of 4',
      );

      await disposeApp(tester);
    });
  });

  group('load failure', () {
    testWidgets('the failure card explains itself and offers Try again', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _useRepository(_FlakyEvolutionRepository(db: db));
      await pumpEvolution(tester);
      await _settle(tester);

      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
      expect(find.text("Let's try again."), findsOneWidget);
      expect(find.byKey(const Key('k07-title')), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // No child is known on this path, so the neutral look stands in.
      final avatar = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(avatar.style, PipStyle.mochi);
      expect(avatar.skin, PipSkin.sunny);
      // No celebration CTA on this card; the retry is the only button.
      expect(find.byKey(const Key('k07-cta')), findsNothing);
      performTap(tester, find.byKey(const Key('k07-retry')));
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('Try again really reloads the evolution', (tester) async {
      final repo = _FlakyEvolutionRepository(db: db);
      await _useRepository(repo);
      await pumpEvolution(tester);
      await _settle(tester);
      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);

      repo.fail = false;
      await tester.tap(find.byKey(const Key('k07-retry')));
      await _settle(tester);

      expect(find.text('Oh no! Pip got lost.'), findsNothing);
      expect(find.text('Pip grew into a Fledgling!'), findsOneWidget);
      expect(currentPath(tester), '/pip-evolution');
      await disposeApp(tester);
    });
  });

  group('no active child (Seed.empty)', () {
    /// Drift's writes run on the real event loop, so they need `runAsync` —
    /// a bare `await` inside a widget test deadlocks the fake-async zone.
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
      await pumpEvolution(tester);

      expect(find.text("Who's playing?"), findsOneWidget);
      expect(find.byKey(const Key('k07-title')), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      performTap(tester, find.byKey(const Key('k07-choose')));
      await _settle(tester);

      expect(pushedPath(tester), '/who-is-playing');
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the pointer path lands on the picker too', (tester) async {
      await emptySeed(tester);
      await pumpEvolution(tester);

      await tester.tap(find.text('Choose'));
      await _settle(tester);

      expect(pushedPath(tester), '/who-is-playing');
      await disposeApp(tester);
    });
  });

  testWidgets('the nest stream healthy and this one failing: the failure card, '
      'not the who-is-playing card', (tester) async {
    // K06 shares this bloc, so a healthy NEST emission reports `loaded` with an
    // evolution of null — a child is known, so the screen must offer the retry
    // rather than send a real child to the picker.
    await _useRepository(_FailingEvolutionOnlyRepository(db: db));
    await pumpEvolution(tester);
    await _settle(tester);

    expect(find.text("Who's playing?"), findsNothing);
    expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
    // The nest's last-known Pip stands in, with the seeded look and stage.
    final avatar = tester.widget<PipAvatar>(find.byType(PipAvatar));
    expect(avatar.style, PipStyle.mochi);
    expect(avatar.skin, PipSkin.sunny);
    expect(avatar.stage, _mayaStage);
    expect(find.byKey(const Key('k07-title')), findsNothing);
    expect(find.byKey(const Key('k07-cta')), findsNothing);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('a stage-1 child shows one Pip, with no arrow or old slot', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(pipStage: Value(1)),
      );
      await GetIt.instance<AppSession>().refresh();
    });
    await pumpEvolution(tester);
    await _settle(tester);

    expect(find.byKey(const Key('k07-new-pip')), findsOneWidget);
    expect(find.byKey(const Key('k07-old-pip')), findsNothing);
    expect(find.byKey(const Key('k07-arrow')), findsNothing);
    // The stage-1 wording is still the shared table's, with `an` before Egg.
    expect(find.text('Pip grew into an Egg!'), findsOneWidget);
    expect(find.text('Meet Egg Pip'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await disposeApp(tester);
  });
}
