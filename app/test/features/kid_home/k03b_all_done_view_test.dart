// K03b widget suite — the all-done state of the shared kid home.
//
// K03b is NOT a separate screen (ORCHESTRATOR_NOTES §1): it is the state of
// `KidHomeView` shown when every quest counts as done for the current period,
// and `/kid-home-done` renders the same view. So this file exercises BOTH
// routes and asserts the two branches never mix.
//
// Data over mocks: every "all done" pump starts from the seeded in-memory
// Drift database (`setUpTestScope` + `Seed.demo`) and finishes the two open
// quests through the real repository, so the counts, the coin pill, the quest
// order and the period scoping are the seeded ones. Only the states a healthy
// database cannot produce (loading, load failure) use a feature-local fake
// repository registered over the real one — the same convention as
// `kid_home_view_test.dart`.
//
// Matrix: light + dark × 320/390/430 × text scale 1.0/1.3, the empty /
// loading / error channels, every tap destination, semantics labels and tap
// targets (ACCESSIBILITY ACTIONS: ≥ 56 kid), the shapes behind the text (UI
// CHECK MEASURES SHAPES, NOT ONLY TEXT), the owner BOTTOM EDGE + ALIGNMENT
// rules, and the shared kid background.
//
// `kid_home_geometry_test.dart` owns the absolute design rows (it loads the
// bundled faces); this file runs on the default test font and pins layout
// CONTRACTS and shapes.

import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/assets/nestling_assets.dart'
    as nest_assets;
import 'package:nestling/core/design_system/design_system.dart' hide PipMood;
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/presentation/widgets/kid_status_chip.dart';

import '../../test_scope.dart';

const KidChild _maya = KidChild(
  id: 'maya',
  nickname: 'Maya',
  ageBand: '7-9',
  avatarColour: 'lilac',
  coins: 120,
  pipStyle: 'mochi',
  pipSkin: 'sunny',
  pipAccessory: 'none',
  pipStage: 3,
  happiness: 4,
  pinSet: true,
  pipTotalCoins: 175,
);

/// Maya's 6 quests in creation order with every status already done — the
/// shape `kid_all_done` produces. Used only where the state itself (not the
/// database) is what is under test.
List<KidQuest> _allDoneItems() => const <KidQuest>[
  KidQuest(
    id: 'q-dishwasher:maya',
    title: 'Empty the dishwasher',
    detail: "Waiting for Mum's thumbs-up · +15",
    questId: 'q-dishwasher',
    icon: 'dishwasher',
    coins: 15,
    status: 'done_pending',
  ),
  KidQuest(
    id: 'q-reading:maya',
    title: 'Reading – 20 minutes',
    detail: "Waiting for Mum's thumbs-up · +10",
    questId: 'q-reading',
    icon: 'book',
    coins: 10,
    status: 'done_pending',
  ),
  KidQuest(
    id: 'q-bins:maya',
    title: 'Put the bins out',
    detail: 'Done · +15',
    questId: 'q-bins',
    icon: 'bins',
    coins: 15,
    status: 'approved',
  ),
  KidQuest(
    id: 'q-tidy:maya',
    title: 'Tidy your bedroom',
    detail: "Waiting for Mum's thumbs-up · +15",
    questId: 'q-tidy',
    icon: 'bed',
    coins: 15,
    status: 'done_pending',
  ),
  KidQuest(
    id: 'q-hoover:maya',
    title: 'Hoover the stairs',
    detail: 'Done · +20',
    questId: 'q-hoover',
    icon: 'hoover',
    coins: 20,
    status: 'approved',
  ),
  KidQuest(
    id: 'q-table:maya',
    title: 'Lay the table',
    detail: "Waiting for Mum's thumbs-up · +10",
    questId: 'q-table',
    icon: 'plate',
    coins: 10,
    status: 'done_pending',
  ),
];

/// Fake repository for the two channels a healthy database cannot produce.
class _FakeRepo extends KidHomeRepository {
  _FakeRepo({this.hang = false, this.failLoad = false});

  /// Watch streams never emit (the loading channel).
  final bool hang;

  /// Watch streams error on listen (the load-failure channel).
  final bool failLoad;

  @override
  Future<List<KidQuest>> getItems() async => _allDoneItems();

  @override
  Stream<List<KidQuest>> watchItems() async* {
    if (failLoad) throw Exception('items down');
    if (hang) return;
    yield _allDoneItems();
  }

  @override
  Stream<KidChild?> watchActiveChild() async* {
    if (failLoad) throw Exception('child down');
    if (hang) return;
    yield _maya;
  }

  @override
  Stream<List<KidChild>> watchProfiles() =>
      Stream<List<KidChild>>.value(const <KidChild>[_maya]);

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> setActiveChild(String childId) async {}

  @override
  Future<void> completeQuest(String childId, String questId) async {}
}

/// Pushable fake for the LIVE branch flip: the only test that changes state
/// while the app is already on screen. It uses plain Dart streams, so the push
/// needs no database round-trip (with an in-memory Drift database the first
/// `runAsync` of a test cannot complete once a frame has been pumped — the
/// constraint `k03b_bugs_test.dart` documents; every other test here seeds
/// BEFORE `_pump`).
class _PushableRepo extends KidHomeRepository {
  _PushableRepo(this._items);

  List<KidQuest> _items;
  final StreamController<List<KidQuest>> _controller =
      StreamController<List<KidQuest>>.broadcast();

  void push(List<KidQuest> items) {
    _items = items;
    _controller.add(items);
  }

  @override
  Future<List<KidQuest>> getItems() async => _items;

  @override
  Stream<List<KidQuest>> watchItems() async* {
    yield _items;
    yield* _controller.stream;
  }

  @override
  Stream<KidChild?> watchActiveChild() => Stream<KidChild?>.value(_maya);

  @override
  Stream<List<KidChild>> watchProfiles() =>
      Stream<List<KidChild>>.value(const <KidChild>[_maya]);

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> setActiveChild(String childId) async {}

  @override
  Future<void> completeQuest(String childId, String questId) async {}
}

/// Six quests in repository order. [doneCount] of them are already finished,
/// so the same list shape renders the K03 branch (4) and, with 6, the K03b
/// celebration branch.
List<KidQuest> _seedItems(int doneCount) {
  const done = <String>[
    'approved',
    'done_pending',
    'approved',
    'done_pending',
    'approved',
    'done_pending',
  ];
  return <KidQuest>[
    for (var i = 0; i < done.length; i++)
      KidQuest(
        id: 'q$i:maya',
        title: 'Quest $i',
        detail: '',
        questId: 'q$i',
        icon: 'book',
        coins: 10,
        status: i < doneCount ? done[i] : 'to_do',
      ),
  ];
}

Future<void> _useRepo(KidHomeRepository repo) async {
  await GetIt.instance.unregister<KidHomeRepository>();
  GetIt.instance.registerSingleton<KidHomeRepository>(repo);
}

/// Finishes every remaining quest for Maya through the real repository, so the
/// seeded database itself reports "6 of 6 done" this period.
Future<void> _finishEveryQuest(WidgetTester tester) async {
  await tester.runAsync(() async {
    final db = GetIt.instance<AppDatabase>();
    final now = appNowUtc();
    // `q-reading` and `q-tidy` are the two seeded to-do quests; the four
    // others already count for the current London period.
    for (final questId in <String>['q-reading', 'q-tidy']) {
      await (db.update(
            db.questCompletions,
          )..where((c) => c.questId.equals(questId) & c.childId.equals('maya')))
          .write(
            QuestCompletionsCompanion(
              status: const Value('done_pending'),
              createdAt: Value(now),
            ),
          );
    }
    await GetIt.instance<AppSession>().refresh();
  });
}

/// Pumps the app at [route] on a [width]×844 surface at [textScale].
Future<void> _pump(
  WidgetTester tester, {
  String route = '/kid-home',
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  bool bottomInset = false,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  if (bottomInset) {
    tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
  }
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Bounded route-transition pumps. `pumpAndSettle` is avoided on purpose:
/// the loading spinner is an endless animation.
Future<void> _settleRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Scrolls until the (lazy) quest-card column is built.
Future<void> _revealCards(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    if (find.byType(NestKidQuestCard).evaluate().isNotEmpty) return;
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
    await tester.pump();
  }
}

void _expectAtLeast(
  WidgetTester tester,
  Finder finder,
  double min,
  String what,
) {
  final size = tester.getSize(finder);
  expect(size.width, greaterThanOrEqualTo(min), reason: '$what width');
  expect(size.height, greaterThanOrEqualTo(min), reason: '$what height');
}

/// The K03b bottom bar's surface container: a top-only 3 px ink border (the
/// same shape as K03's dock, so it is identified the same way).
Finder _barSurface() => find.byWidgetPredicate((widget) {
  if (widget is! Container) return false;
  final decoration = widget.decoration;
  if (decoration is! BoxDecoration) return false;
  final border = decoration.border;
  return border is Border && border.top.width == 3 && border.left.width == 0;
});

/// The PAINTED quest-card surface (the all-side-ink-bordered [Container]
/// inside the shared card's 6 px shadow reserve), so a rect comparison reads
/// the design's `.quest-card` and not the reserve.
Finder _paintedCard(int index) => find
    .descendant(
      of: find.byType(NestKidQuestCard).at(index),
      matching: find.byWidgetPredicate((widget) {
        if (widget is! Container) return false;
        final box = widget.decoration;
        if (box is! BoxDecoration) return false;
        final border = box.border;
        return border is Border &&
            border.top.width > 0 &&
            border.left.width == border.top.width;
      }),
    )
    .first;

/// Every [SvgPicture] asset currently in the tree.
List<String> _svgAssets(WidgetTester tester) => find
    .byType(SvgPicture)
    .evaluate()
    .map((element) => (element.widget as SvgPicture).bytesLoader)
    .whereType<SvgAssetLoader>()
    .map((loader) => loader.assetName)
    .toList();

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  // -------------------------------------------------------------------------
  // The all-done branch itself (seeded database, both routes)
  // -------------------------------------------------------------------------

  group('K03b all-done branch (seeded data)', () {
    testWidgets('light: every quest done renders the K03b screen', (
      tester,
    ) async {
      await _finishEveryQuest(tester);
      await _pump(tester);
      // Header: the design's "All done!" replaces "$done done today".
      expect(find.text('Hi Maya!'), findsOneWidget);
      expect(find.text('All done!'), findsOneWidget);
      expect(find.text('4 done today'), findsNothing);
      // Celebration copy, character-for-character with the HTML (l.49).
      expect(
        find.text('You did everything today! Pip is so proud.'),
        findsOneWidget,
      );
      // Counts are the seeded ones (6 quests, all done this period).
      expect(find.text('6 of 6 done'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
      // The CTA replaces the 3-button dock.
      expect(find.text('Visit Pip'), findsOneWidget);
      expect(find.text('My jar'), findsNothing);
      expect(find.text('Shop'), findsNothing);
      expect(find.byType(NestKidButton), findsOneWidget);
      // K03-only blocks are gone: no hearts row, no K03 speech bubble.
      expect(find.text('Pip is happy today'), findsNothing);
      expect(find.byType(NestHeart), findsNothing);
      expect(find.text("Let's do some quests!"), findsNothing);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('dark: the same branch with the dark kid tokens', (
      tester,
    ) async {
      await _finishEveryQuest(tester);
      await _pump(tester, theme: ThemeMode.dark);
      expect(find.text('All done!'), findsOneWidget);
      expect(
        find.text('You did everything today! Pip is so proud.'),
        findsOneWidget,
      );
      expect(find.text('6 of 6 done'), findsOneWidget);
      expect(find.text('Visit Pip'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('/kid-home-done renders the same view, not a placeholder', (
      tester,
    ) async {
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      expect(find.text('K03b Kid home done'), findsNothing);
      expect(find.text('All done!'), findsOneWidget);
      expect(find.text('Visit Pip'), findsOneWidget);
      // Same route path, same bloc: `pushedPath`/`currentPath` stay honest.
      expect(currentPath(tester), '/kid-home-done');
      await disposeApp(tester);
    });

    testWidgets('/kid-home shows the same all-done screen (ONE kid home)', (
      tester,
    ) async {
      await _finishEveryQuest(tester);
      await _pump(tester);
      expect(find.text('All done!'), findsOneWidget);
      expect(find.text('Visit Pip'), findsOneWidget);
      expect(find.text('My jar'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('demo seed (4 of 6) keeps the K03 branch untouched', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('4 done today'), findsOneWidget);
      expect(find.text('4 of 6 done'), findsOneWidget);
      expect(find.text('Pip is happy today'), findsOneWidget);
      expect(find.text("Let's do some quests!"), findsOneWidget);
      expect(find.text('All done!'), findsNothing);
      expect(find.text('Visit Pip'), findsNothing);
      expect(find.text('My jar'), findsOneWidget);
      expect(find.text('Shop'), findsOneWidget);
      expect(find.byType(NestKidButton), findsNWidgets(3));
      await disposeApp(tester);
    });

    testWidgets('finishing the last quests flips the screen in place', (
      tester,
    ) async {
      // The live transition a child performs, on ONE route: four of six done
      // (the K03 branch), then the open quests land and the same view swaps to
      // the K03b branch. Pushed through a stream fake rather than a database
      // write because an in-memory Drift database cannot be written from a
      // `runAsync` once a frame has been pumped (`k03b_bugs_test.dart`
      // documents the same constraint); the seeded-database proofs above and
      // in `k03b_bugs_test.dart` cover the data-driven equivalent.
      final repo = _PushableRepo(_seedItems(4));
      await _useRepo(repo);
      await _pump(tester);
      expect(find.text('All done!'), findsNothing);
      expect(find.text('4 done today'), findsOneWidget);
      expect(find.text('Visit Pip'), findsNothing);
      expect(find.text('My jar'), findsOneWidget);

      repo.push(_seedItems(6));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('All done!'), findsOneWidget, reason: 'same route');
      expect(find.text('6 of 6 done'), findsOneWidget);
      expect(find.text('Visit Pip'), findsOneWidget);
      expect(find.text('My jar'), findsNothing);
      expect(find.text('Pip is happy today'), findsNothing);
      await _revealCards(tester);
      expect(find.byType(NestKidQuestCard), findsNWidgets(6));
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets(
      'PERIODS: a completion outside the period never reaches all-done',
      (tester) async {
        // Every write happens BEFORE the first pump: with an in-memory Drift
        // database a `runAsync` cannot complete once a frame has been pumped
        // (the constraint `k03b_bugs_test.dart` documents).
        await _finishEveryQuest(tester);
        // `q-hoover` is weekly; move its completion out of the current London
        // week and it reads "to do" again, so five of six count and the
        // celebration must not appear.
        await tester.runAsync(() async {
          final db = GetIt.instance<AppDatabase>();
          await (db.update(
            db.questCompletions,
          )..where((c) => c.questId.equals('q-hoover'))).write(
            QuestCompletionsCompanion(
              createdAt: Value(
                Seed.anchorDay.subtract(const Duration(days: 9)),
              ),
            ),
          );
          await GetIt.instance<AppSession>().refresh();
        });
        await _pump(tester);
        expect(find.text('All done!'), findsNothing);
        expect(find.text('5 done today'), findsOneWidget);
        expect(find.text('5 of 6 done'), findsOneWidget);
        expect(find.text('Visit Pip'), findsNothing);
        expect(find.text('My jar'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Layout matrix — light/dark × 320/390/430 × scale 1.0/1.3
  // -------------------------------------------------------------------------

  group('K03b layout matrix', () {
    const themes = <(String, ThemeMode)>[
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ];
    const widths = <double>[320, 390, 430];
    const scales = <double>[1, 1.3];

    for (final (String themeName, ThemeMode theme) in themes) {
      for (final width in widths) {
        for (final scale in scales) {
          testWidgets(
            '$themeName ${width.toInt()}px scale $scale renders without overflow',
            (tester) async {
              await _finishEveryQuest(tester);
              await _pump(
                tester,
                route: '/kid-home-done',
                width: width,
                textScale: scale,
                theme: theme,
              );
              expect(find.text('All done!'), findsOneWidget);
              expect(find.text('6 of 6 done'), findsOneWidget);
              expect(find.text('Visit Pip'), findsOneWidget);
              expect(
                find.text('You did everything today! Pip is so proud.'),
                findsOneWidget,
              );
              await _revealCards(tester);
              expect(find.byType(NestKidQuestCard), findsNWidgets(6));
              // The coin pill never becomes a money amount on a kid screen.
              expect(find.textContaining('£'), findsNothing);
              expect(tester.takeException(), isNull);
              await disposeApp(tester);
            },
          );
        }
      }
    }

    testWidgets('320px at 1.3 scale keeps lock, chip and progress semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done', width: 320, textScale: 1.3);
      expect(find.bySemanticsLabel('Grown-ups'), findsOneWidget);
      expect(
        find.bySemanticsLabel("6 of 6 of today's quests done"),
        findsOneWidget,
      );
      expect(find.text('Visit Pip'), findsOneWidget);
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Non-all-done channels (empty / loading / error / no child)
  // -------------------------------------------------------------------------

  group('K03b non-all-done channels', () {
    testWidgets('loading: a spinner, the gate lock and no celebration', (
      tester,
    ) async {
      await _useRepo(_FakeRepo(hang: true));
      await _pump(tester, route: '/kid-home-done');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(NestLockButton), findsOneWidget);
      expect(find.text('All done!'), findsNothing);
      expect(find.text('Visit Pip'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('error: the shared failure card with a working retry', (
      tester,
    ) async {
      await _useRepo(_FakeRepo(failLoad: true));
      await _pump(tester, route: '/kid-home-done');
      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
      expect(find.text('All done!'), findsNothing);
      expect(find.text('Visit Pip'), findsNothing);
      // The retry exposes a tap action (ACCESSIBILITY ACTIONS).
      final retry = find.text('Try again');
      expect(
        tester
            .getSemantics(retry)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      await disposeApp(tester);
    });

    testWidgets('a child with no quests shows the gentle empty state', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final db = GetIt.instance<AppDatabase>();
        await (db.delete(
          db.quests,
        )..where((q) => q.assigneeChildId.equals('maya'))).go();
        await GetIt.instance<AppSession>().refresh();
      });
      await _pump(tester, route: '/kid-home-done');
      expect(find.text('No quests today'), findsOneWidget);
      // No quests is NOT "all done" — never the celebration.
      expect(find.text('All done!'), findsNothing);
      expect(find.text('Visit Pip'), findsNothing);
      expect(find.text('My jar'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    for (final (String themeName, ThemeMode theme) in <(String, ThemeMode)>[
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ]) {
      testWidgets('$themeName: no active child offers the picker', (
        tester,
      ) async {
        // `Seed.empty` is the parent-only state: no children, so kid mode has
        // nobody to celebrate and must offer K01 instead of K03b.
        await tester.runAsync(() async {
          await Seed.empty(GetIt.instance<AppDatabase>());
          await GetIt.instance<AppSession>().refresh();
        });
        await _pump(tester, route: '/kid-home-done', theme: theme);
        expect(find.text("Who's playing?"), findsOneWidget);
        expect(find.text('All done!'), findsNothing);
        expect(find.text('Visit Pip'), findsNothing);
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });
    }
  });

  // -------------------------------------------------------------------------
  // Shapes — the visible background/border rect, not only where text lands
  // -------------------------------------------------------------------------

  group('K03b shapes', () {
    testWidgets('the section chip is a 32 px leaf-tint pill on the gutter', (
      tester,
    ) async {
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      final chip = find.ancestor(
        of: find.text('6 of 6 done'),
        matching: find.byType(KidStatusChip),
      );
      expect(tester.getRect(chip).height, closeTo(32, 0.5), reason: '.kchip');
      final container = tester.widget<Container>(
        find.descendant(of: chip, matching: find.byType(Container)).first,
      );
      final decoration = container.decoration! as BoxDecoration;
      final tokens = Theme.of(tester.element(find.byType(NestProgress)))
          .extension<NestTokens>()!;
      expect(decoration.color, tokens.leafTint, reason: '.kchip background');
      expect(decoration.borderRadius, NestRadii.allPill);
      // The 12 px horizontal padding keeps the label off the pill edge, and
      // the pill's outer edges sit on the 20 px gutters.
      final rect = tester.getRect(chip);
      expect(
        tester.getRect(find.text('6 of 6 done')).left,
        closeTo(rect.left + NestSpacing.s3, 0.5),
      );
      expect(rect.right, closeTo(NestDevice.width - NestSpacing.padSide, 0.5));
      await disposeApp(tester);
    });

    testWidgets('the speech bubble matches .speech and is centred', (
      tester,
    ) async {
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      final tokens = Theme.of(tester.element(find.byType(NestProgress)))
          .extension<NestTokens>()!;
      final body = find.descendant(
        of: find.byType(NestSpeechBubble),
        matching: find.byWidgetPredicate((widget) {
          if (widget is! Container) return false;
          final box = widget.decoration;
          return box is BoxDecoration &&
              box.borderRadius == BorderRadius.circular(18);
        }),
      );
      expect(body, findsOneWidget);
      final container = tester.widget<Container>(body);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, tokens.surface, reason: '.speech background');
      expect(decoration.borderRadius, BorderRadius.circular(18));
      final border = decoration.border! as Border;
      expect(border.top.width, 3, reason: '.speech border is 3 px ink');
      expect(border.top.color, tokens.ink);
      expect(
        container.padding,
        const EdgeInsets.symmetric(
          horizontal: NestSpacing.gap14,
          vertical: NestSpacing.s2,
        ),
        reason: '.speech padding is 8 px / 14 px',
      );
      final rect = tester.getRect(body);
      expect(rect.width, lessThanOrEqualTo(260), reason: '.speech max-width');
      expect(
        rect.center.dx,
        closeTo(NestDevice.width / 2, 0.5),
        reason: '.k3-bubble centres the bubble',
      );
      // The label is Nunito 800 at 16 px with no tracking.
      final label = tester.widget<Text>(
        find.descendant(
          of: body,
          matching: find.text('You did everything today! Pip is so proud.'),
        ),
      );
      expect(label.style!.fontSize, 16);
      expect(label.style!.fontWeight, FontWeight.w800);
      expect(label.style!.letterSpacing ?? 0, 0);
      // The tail hangs 9 px below the body, centred (CSS `::after` overflow).
      final tail = find.descendant(
        of: find.byType(NestSpeechBubble),
        matching: find.byType(CustomPaint),
      );
      expect(tail, findsOneWidget);
      final tailRect = tester.getRect(tail);
      expect(tailRect.width, closeTo(18, 0.5));
      expect(tailRect.height, closeTo(9, 0.5));
      expect(tailRect.top, closeTo(rect.bottom, 0.5));
      expect(tailRect.center.dx, closeTo(rect.center.dx, 0.5));
      await disposeApp(tester);
    });

    testWidgets('the CTA is a full-width 64 px lilac kid button', (
      tester,
    ) async {
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      final button = find.byType(NestKidButton);
      expect(button, findsOneWidget, reason: 'the dock is replaced, not added');
      final widget = tester.widget<NestKidButton>(button);
      expect(widget.label, 'Visit Pip');
      expect(widget.color, NestKidButtonColor.lilac, reason: '.btn-kid.lilac');
      expect(widget.minHeight, 64, reason: '.btn-kid min-height is 64 px');
      expect(widget.fullWidth, isTrue);
      expect(widget.icon, isA<NestIcon>(), reason: 'the design shows a check');
      expect((widget.icon! as NestIcon).assetName, NestIcons.check);
      final rect = tester.getRect(button);
      expect(rect.left, closeTo(NestSpacing.padSide, 0.5));
      expect(rect.right, closeTo(NestDevice.width - NestSpacing.padSide, 0.5));
      _expectAtLeast(tester, button, NestDevice.tapKid, 'Visit Pip');
      // The painted button surface: radius 24 (`.btn-kid { --r-l }`), a 3 px
      // ink border and the lilac fill (UI CHECK MEASURES SHAPES).
      final painted = find.descendant(
        of: button,
        matching: find.byWidgetPredicate((widget) {
          if (widget is! AnimatedContainer) return false;
          final box = widget.decoration;
          return box is BoxDecoration && box.color == _lilacCta(tester);
        }),
      );
      expect(painted, findsOneWidget);
      final decoration =
          tester.widget<AnimatedContainer>(painted).decoration!
              as BoxDecoration;
      expect(
        decoration.borderRadius,
        BorderRadius.circular(NestRadii.l),
        reason: '.btn-kid uses --r-l',
      );
      final paintedBorder = decoration.border! as Border;
      expect(paintedBorder.top.width, 3, reason: '.btn-kid border is 3 px ink');
      expect(paintedBorder.top.color, _tokens(tester).ink);
      await disposeApp(tester);
    });

    testWidgets('quest cards keep the K03 rects, tints and 12 px gap', (
      tester,
    ) async {
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      await _revealCards(tester);
      final tokens = _tokens(tester);
      // Per-quest icon tints are unchanged from K03 (DATA OVER MOCKS: the
      // tint follows the seeded icon, not the design's sample order).
      final expected = <String, Color>{
        'Empty the dishwasher': tokens.skyTint,
        'Reading – 20 minutes': tokens.lilacTint,
        'Tidy your bedroom': tokens.peachTint,
      };
      for (final MapEntry(key: title, value: tint) in expected.entries) {
        final tile = find.descendant(
          of: find.ancestor(
            of: find.text(title),
            matching: find.byType(NestKidQuestCard),
          ),
          matching: find.byWidgetPredicate((widget) {
            if (widget is! Container) return false;
            final box = widget.decoration;
            return box is BoxDecoration &&
                box.borderRadius == BorderRadius.circular(16);
          }),
        );
        expect(tile, findsOneWidget, reason: 'tile for "$title"');
        expect(tester.getSize(tile), const Size(48, 48), reason: '.kid-icon');
        final decoration = tester.widget<Container>(tile).decoration!;
        expect((decoration as BoxDecoration).color, tint);
      }
      // `.k3-quests { gap: 12px }` between the PAINTED card rects (the shared
      // card reserves 6 px of shadow room under itself).
      final first = tester.getRect(_paintedCard(0));
      final second = tester.getRect(_paintedCard(1));
      expect(
        second.top - first.bottom,
        closeTo(NestSpacing.s3, 1),
        reason: '12 px between painted cards',
      );
      expect(first.left, closeTo(NestSpacing.padSide, 0.5));
      expect(first.right, closeTo(NestDevice.width - NestSpacing.padSide, 0.5));
      _expectAtLeast(
        tester,
        find.byType(NestKidQuestCard).first,
        NestDevice.tapKid,
        'quest card row',
      );
      await disposeApp(tester);
    });

    testWidgets('the progress bar is the full kid bar at fraction 1', (
      tester,
    ) async {
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      final progress = find.byType(NestProgress);
      expect(progress, findsOneWidget);
      final widget = tester.widget<NestProgress>(progress);
      expect(widget.kid, isTrue, reason: '.progress.kid');
      expect(widget.fraction, 1, reason: 'every quest is done');
      final rect = tester.getRect(progress);
      expect(rect.left, closeTo(NestSpacing.padSide, 0.5));
      expect(rect.right, closeTo(NestDevice.width - NestSpacing.padSide, 0.5));
      expect(rect.height, closeTo(NestSpacing.s4, 0.5));
      // Section → progress keeps the design's 16 px scroll gap (the SECTION
      // chip, not every chip: the cards carry meta chips too).
      final sectionChip = find.ancestor(
        of: find.text('6 of 6 done'),
        matching: find.byType(KidStatusChip),
      );
      expect(
        rect.top - tester.getRect(sectionChip).bottom,
        greaterThanOrEqualTo(NestSpacing.s4 - 0.5),
      );
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Owner rules — BOTTOM EDGE + ALIGNMENT
  // -------------------------------------------------------------------------

  group('K03b owner rules (bottom edge, alignment)', () {
    const themes = <(String, ThemeMode)>[
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ];

    for (final (String themeName, ThemeMode theme) in themes) {
      testWidgets('$themeName: the bar surface runs to the physical edge', (
        tester,
      ) async {
        await _finishEveryQuest(tester);
        await _pump(
          tester,
          route: '/kid-home-done',
          theme: theme,
          bottomInset: true,
        );
        final bar = _barSurface();
        expect(bar, findsOneWidget);
        final rect = tester.getRect(bar);
        expect(rect.left, 0);
        expect(rect.right, NestDevice.width);
        expect(
          rect.bottom,
          closeTo(NestDevice.height, 0.5),
          reason:
              'the bar surface must cover the OS inset to the edge — no '
              'meadow/sky strip under it or around the home indicator',
        );
        // The surface colour is the bar's own, in both themes.
        final decoration =
            tester.widget<Container>(bar).decoration! as BoxDecoration;
        expect(decoration.color, _tokens(tester).surface);
        // The button stays above the inset; the OS draws the home pill.
        expect(
          tester.getRect(find.byType(NestKidButton)).bottom,
          lessThanOrEqualTo(NestDevice.height - 34),
        );
        expect(tester.getSize(find.byType(NestHomeIndicator)), Size.zero);
        final safeArea = find
            .ancestor(
              of: find.text('Visit Pip'),
              matching: find.byType(SafeArea),
            )
            .first;
        expect(tester.widget<SafeArea>(safeArea).top, isFalse);
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });

      testWidgets('$themeName: every row shares the 20 px gutters', (
        tester,
      ) async {
        await _finishEveryQuest(tester);
        await _pump(tester, route: '/kid-home-done', theme: theme);
        await _revealCards(tester);
        const gutter = NestSpacing.padSide;
        expect(
          tester.getRect(find.byType(NestAvatar)).left,
          closeTo(gutter, 0.5),
        );
        expect(
          tester.getRect(find.byType(NestLockButton)).right,
          closeTo(NestDevice.width - gutter, 0.5),
        );
        expect(
          tester.getRect(find.byType(NestKidButton)).left,
          closeTo(gutter, 0.5),
        );
        expect(
          tester.getRect(find.byType(NestKidButton)).right,
          closeTo(NestDevice.width - gutter, 0.5),
        );
        expect(
          tester.getRect(find.byType(NestProgress)).left,
          closeTo(gutter, 0.5),
        );
        expect(
          tester.getRect(find.byType(NestBalancedText)).left,
          closeTo(gutter, 0.5),
        );
        final card = tester.getRect(_paintedCard(0));
        expect(card.left, closeTo(gutter, 0.5));
        expect(card.right, closeTo(NestDevice.width - gutter, 0.5));
        // The quest list ends where the fixed bar starts.
        expect(
          tester.getRect(find.byType(ListView)).bottom,
          closeTo(tester.getRect(_barSurface()).top, 0.5),
        );
        await disposeApp(tester);
      });
    }

    testWidgets('430px: the bar still runs to the edge with the inset', (
      tester,
    ) async {
      await _finishEveryQuest(tester);
      await _pump(
        tester,
        route: '/kid-home-done',
        width: 430,
        bottomInset: true,
      );
      final rect = tester.getRect(_barSurface());
      expect(rect.left, 0);
      expect(rect.right, 430);
      expect(rect.bottom, closeTo(844, 0.5));
      await disposeApp(tester);
    });

    testWidgets(
      'a top inset reserves the status bar and leaves the bar intact',
      (tester) async {
        await _finishEveryQuest(tester);
        tester.view.viewPadding = const FakeViewPadding(
          top: 59 * 3,
          bottom: 34 * 3,
        );
        tester.view.padding = const FakeViewPadding(
          top: 59 * 3,
          bottom: 34 * 3,
        );
        await _pump(tester, route: '/kid-home-done');
        // STATUS BAR rule: the widget only reserves height.
        expect(
          tester.getRect(find.byType(NestAvatar)).top,
          greaterThanOrEqualTo(59),
        );
        expect(tester.getRect(_barSurface()).bottom, closeTo(844, 0.5));
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      },
    );
  });

  // -------------------------------------------------------------------------
  // Shared design-system usage (KID BACKGROUND, PIP, BALANCED HEADINGS)
  // -------------------------------------------------------------------------

  group('K03b shared design system', () {
    testWidgets('the screen background is the shared kid gradient + hills', (
      tester,
    ) async {
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      await _revealCards(tester);
      final tokens = _tokens(tester);
      final gradient = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(KidScope),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .map((box) => box.gradient)
          .whereType<LinearGradient>()
          .first;
      expect(gradient.colors, <Color>[
        tokens.kidSkyTop,
        tokens.kidSkyBottom,
        tokens.kidHorizon,
        tokens.kidMeadow,
      ]);
      expect(gradient.stops, <double>[0, 0.62, 0.62, 1]);
      // The shared hills sit at the physical bottom, 390×136, behind the bar.
      final hills = tester.getRect(find.byType(NestMeadow));
      expect(hills.left, 0);
      expect(hills.width, closeTo(NestDevice.width, 0.5));
      expect(hills.height, closeTo(136, 0.5));
      expect(hills.bottom, closeTo(NestDevice.height, 0.5));
      // No feature-local meadow painter survives.
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint &&
              widget.painter.runtimeType.toString() == '_MeadowPainter',
        ),
        findsNothing,
      );
      await disposeApp(tester);
    });

    testWidgets("Pip is the child's own PipAvatar, celebrating", (
      tester,
    ) async {
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      final avatar = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(avatar.style, PipStyle.mochi, reason: "Maya's seeded look");
      expect(avatar.skin, PipSkin.sunny);
      expect(avatar.accessory, PipAccessory.none);
      expect(avatar.stage, 3, reason: "Maya's seeded stage");
      expect(avatar.mood, PipMood.happy, reason: 'the celebration mood');
      // The design tilts Pip -7° (`.k3-pet .pip { rotate(-7deg) }`).
      final rotate = find.ancestor(
        of: find.byType(PipAvatar),
        matching: find.byType(Transform),
      );
      expect(rotate, findsWidgets);
      // sin(-7°) ≈ -0.122: a visible rotation, not the identity matrix.
      expect(
        tester.widget<Transform>(rotate.first).transform,
        predicate<Object>((m) => m is Matrix4 && m.entry(0, 1).abs() > 0.1),
      );
      // PIP rule: never the v1 `pip_stage_*.svg` illustrations.
      expect(
        _svgAssets(tester).where((name) => name.contains('pip_stage')),
        isEmpty,
      );
      await disposeApp(tester);
    });

    testWidgets('Leo deep-link uses bolt/sky/stage 2 from the database', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final db = GetIt.instance<AppDatabase>();
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value('leo')),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _pump(tester, route: '/kid-home-done');
      final avatar = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(avatar.style, PipStyle.bolt);
      expect(avatar.skin, PipSkin.sky);
      expect(avatar.stage, 2);
      await disposeApp(tester);
    });

    testWidgets('the pet slot announces the stage and the celebration', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      expect(
        find.bySemanticsLabel('Pip the Fledgling, stage 3 of 4, celebrating'),
        findsOneWidget,
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the confetti plate is the shared decorative SVG', (
      tester,
    ) async {
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      final confetti = find.byWidgetPredicate(
        (widget) =>
            widget is SvgPicture &&
            widget.bytesLoader is SvgAssetLoader &&
            (widget.bytesLoader as SvgAssetLoader).assetName ==
                nest_assets.NestlingIllustrations.confetti,
      );
      expect(confetti, findsOneWidget, reason: 'the design plate, once');
      // Decorative: no semantics node, no hit target.
      expect(
        find.ancestor(of: confetti, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
      expect(
        find.ancestor(of: confetti, matching: find.byType(IgnorePointer)),
        findsWidgets,
      );
      // The design's 320×250 plate, scaled down rather than overflowing.
      final rect = tester.getRect(confetti);
      expect(rect.width, lessThanOrEqualTo(320));
      expect(rect.height, lessThanOrEqualTo(250));
      expect(rect.center.dx, closeTo(NestDevice.width / 2, 1));
      await disposeApp(tester);
    });

    testWidgets('the .kid-title heading renders through NestBalancedText', (
      tester,
    ) async {
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      final balanced = tester.widget<NestBalancedText>(
        find.byType(NestBalancedText),
      );
      expect(balanced.text, "Today's quests");
      expect(balanced.style.fontSize, 28, reason: '.kid-title is 28 px');
      expect(balanced.style.fontWeight, FontWeight.w900);
      expect(balanced.maxLines, 2);
      expect(balanced.textAlign, TextAlign.start);
      expect(balanced.style.letterSpacing ?? 0, 0);
      // Exactly one balanced heading: no body/caption copy was switched over.
      expect(find.byType(NestBalancedText), findsOneWidget);
      expect(find.text("Today's quests"), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('every K03b string uses the shared kid styles, tracking 0', (
      tester,
    ) async {
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      // .k3-name 22/26 w900, .k3-sub 15/20 w700, .kchip 15/15 w800,
      // .kid-title 28/34 w900, .speech 16 w800, .coin-pill 16/16 w800,
      // .btn-kid 20/26 w900.
      final expected = <String, (double, double?, FontWeight)>{
        'Hi Maya!': (22, 26 / 22, FontWeight.w900),
        'All done!': (15, 20 / 15, FontWeight.w700),
        "Today's quests": (28, 34 / 28, FontWeight.w900),
        '6 of 6 done': (15, 15 / 15, FontWeight.w800),
        'You did everything today! Pip is so proud.': (
          16,
          null,
          FontWeight.w800,
        ),
        '120': (16, 16 / 16, FontWeight.w800),
        'Visit Pip': (20, 26 / 20, FontWeight.w900),
      };
      for (final MapEntry(key: text, value: spec) in expected.entries) {
        final finder = find.text(text);
        expect(finder, findsOneWidget, reason: 'copy: $text');
        final style = tester.widget<Text>(finder).style!;
        final (size, height, weight) = spec;
        expect(style.fontSize, size, reason: 'font size: $text');
        expect(
          style.height,
          height == null ? isNull : closeTo(height, 0.001),
          reason: 'line box: $text',
        );
        expect(style.fontWeight, weight, reason: 'weight: $text');
        expect(
          style.letterSpacing ?? 0,
          0,
          reason: '$text must carry no tracking (the CSS sets none)',
        );
      }
      // "All done!" is `.k3-sub`, which the CSS paints in leaf-ink.
      final sub = tester.widget<Text>(find.text('All done!')).style!;
      expect(sub.color, _tokens(tester).leafInk);
      await disposeApp(tester);
    });

    testWidgets('copy matches the K03b HTML character-for-character', (
      tester,
    ) async {
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      await _revealCards(tester);
      // l.40 avatar initial, l.42/43 greeting, l.45 coin pill, l.49 bubble,
      // l.76 heading (ASCII apostrophe, as authored), l.77 chip, l.108 CTA.
      expect(find.text('Hi Maya!'), findsOneWidget);
      expect(find.text('All done!'), findsOneWidget);
      expect(
        find.text('You did everything today! Pip is so proud.'),
        findsOneWidget,
      );
      expect(find.text("Today's quests"), findsOneWidget);
      expect(find.text('6 of 6 done'), findsOneWidget);
      expect(find.text('Visit Pip'), findsOneWidget);
      expect(
        tester.widget<NestAvatar>(find.byType(NestAvatar)).initial,
        'M',
        reason: 'nestAvatarInitial, never name[0]',
      );
      // The seed title's en dash is preserved (HTML `&ndash;`).
      expect(find.text('Reading – 20 minutes'), findsOneWidget);
      // DB-driven meta (ROW META, orchestrator 04:52): approved + needs
      // approval → `Mum said yes!`, waiting → `Waiting for Mum`.
      // `Seed.demo` approves two of Maya's quests (bins, hoover) and leaves
      // the dishwasher + table pending; `_finishEveryQuest` adds reading +
      // tidy as pending. So: 2 "Mum said yes!", 4 "Waiting for Mum".
      expect(find.text('Mum said yes!'), findsNWidgets(2));
      expect(find.text('Waiting for Mum'), findsNWidgets(4));
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Navigation — every tap reaches the right route
  // -------------------------------------------------------------------------

  group('K03b navigation', () {
    testWidgets('Visit Pip opens /pip', (tester) async {
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      await tester.tap(find.text('Visit Pip'));
      await _settleRoute(tester);
      // A `go` route, so the declarative location changes too.
      expect(currentPath(tester), '/pip');
      expect(pushedPath(tester), '/pip');
      await disposeApp(tester);
    });

    testWidgets('the lock opens the parental gate', (tester) async {
      final semantics = tester.ensureSemantics();
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      await tester.tap(find.bySemanticsLabel('Grown-ups'));
      await _settleRoute(tester);
      expect(pushedPath(tester), '/parental-gate');
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a quest card opens the detail with questId + childId', (
      tester,
    ) async {
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      await _revealCards(tester);
      await tester.ensureVisible(find.text('Reading – 20 minutes'));
      await tester.pump();
      await tester.tap(find.text('Reading – 20 minutes'));
      await _settleRoute(tester);
      expect(pushedPath(tester), '/quest-detail');
      final state = GoRouter.of(tester.element(find.byType(Navigator).first))
          .state;
      final extra = state.extra! as Map<String, Object?>;
      expect(extra['questId'], 'q-reading');
      expect(extra['childId'], 'maya');
      await disposeApp(tester);
    });

    testWidgets('the quest order is the database order, never re-sorted', (
      tester,
    ) async {
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -200));
        await tester.pump();
      }
      // ROW ORDER (owner rule, orchestrator 04:52): creation order —
      // `watchActiveQuests` sorts by `created_at` then `id`, and the view
      // renders `state.items` in order (no re-sort). The seed stamps one
      // second per quest: dishwasher, reading, bins, tidy, hoover, table —
      // exactly the K03/K03b HTML row order. NOT re-sorted by status, and
      // NOT hard-coded to the design PNG's sample rows (DATA OVER MOCKS).
      expect(
        <String>[
          for (final card in tester.widgetList<NestKidQuestCard>(
            find.byType(NestKidQuestCard),
          ))
            card.title,
        ],
        <String>[
          'Empty the dishwasher',
          'Reading – 20 minutes',
          'Put the bins out',
          'Tidy your bedroom',
          'Hoover the stairs',
          'Lay the table',
        ],
      );
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Accessibility — ACCESSIBILITY ACTIONS + tap targets
  // -------------------------------------------------------------------------

  group('K03b accessibility', () {
    /// Performs the real VoiceOver/TalkBack activation of [finder]'s node.
    void performTap(WidgetTester tester, Finder finder) {
      final node = tester.getSemantics(finder);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'the control must expose SemanticsAction.tap',
      );
      node.owner!.performAction(node.id, SemanticsAction.tap);
    }

    // One test per control, not a loop: a second iteration would have to
    // re-seed the database AFTER frames were pumped, and the first
    // `runAsync` of a test cannot complete then (see the `_PushableRepo`
    // comment).
    for (final (label, path) in <(String, String)>[
      ('Visit Pip', '/pip'),
      ('Grown-ups', '/parental-gate'),
    ]) {
      testWidgets('$label exposes a tap action that reaches $path', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        await _finishEveryQuest(tester);
        await _pump(tester, route: '/kid-home-done');
        final node = find.bySemanticsLabel(label);
        expect(node, findsOneWidget, reason: label);
        performTap(tester, node);
        await _settleRoute(tester);
        expect(pushedPath(tester), path, reason: label);
        semantics.dispose();
        await disposeApp(tester);
      });
    }

    testWidgets('a quest card exposes a tap action that opens the detail', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      await _revealCards(tester);
      final card = find.byType(NestKidQuestCard).first;
      expect(
        tester
            .getSemantics(card)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );
      performTap(tester, card);
      await _settleRoute(tester);
      expect(pushedPath(tester), '/quest-detail');
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('icon buttons and key labels expose kid semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      expect(find.bySemanticsLabel('Grown-ups'), findsOneWidget);
      expect(find.bySemanticsLabel('120 coins'), findsOneWidget);
      // The header merges the two texts behind `excludeSemantics` and reads
      // as one announcement — display-only, never a button.
      expect(find.bySemanticsLabel('Hi Maya, all done!'), findsOneWidget);
      expect(
        find.bySemanticsLabel("6 of 6 of today's quests done"),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Pip the Fledgling, stage 3 of 4, celebrating'),
        findsOneWidget,
      );
      await _revealCards(tester);
      // Every quest is done, so no check is actionable ('Mark done' is the
      // to-do check's label) and the status is announced on the card instead.
      expect(find.bySemanticsLabel('Mark done'), findsNothing);
      expect(
        tester.getSemantics(find.text('Empty the dishwasher')).label,
        startsWith("Empty the dishwasher, Waiting for Mum's thumbs-up"),
      );
      expect(
        tester.getSemantics(find.text('Put the bins out')).label,
        startsWith('Put the bins out, Mum said yes!'),
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('non-controls advertise no tap action', (tester) async {
      final semantics = tester.ensureSemantics();
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      await _revealCards(tester);
      bool hasTap(Finder finder) => tester
          .getSemantics(finder)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap);
      expect(hasTap(find.bySemanticsLabel('Hi Maya, all done!')), isFalse);
      expect(
        hasTap(find.bySemanticsLabel("6 of 6 of today's quests done")),
        isFalse,
      );
      expect(
        hasTap(
          find.bySemanticsLabel('Pip the Fledgling, stage 3 of 4, celebrating'),
        ),
        isFalse,
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('kid tap targets meet the 56 minimum', (tester) async {
      final semantics = tester.ensureSemantics();
      await _finishEveryQuest(tester);
      await _pump(tester, route: '/kid-home-done');
      _expectAtLeast(
        tester,
        find.byType(NestLockButton),
        NestDevice.tapKid,
        'lock button',
      );
      _expectAtLeast(
        tester,
        find.byType(NestKidButton),
        NestDevice.tapKid,
        'Visit Pip',
      );
      _expectAtLeast(
        tester,
        find.byType(NestKidQuestCard).first,
        NestDevice.tapKid,
        'quest card row',
      );
      // The card's check is display-only here, but the 56 px circle is still
      // what a child aims at (K03's `.quest-check`).
      await _revealCards(tester);
      final painted = tester.getRect(_paintedCard(0));
      expect(painted.height, greaterThanOrEqualTo(NestSpacing.s8));
      semantics.dispose();
      await disposeApp(tester);
    });
  });
}

/// The ambient token set at the nearest `Theme`.
NestTokens _tokens(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(NestProgress).first))
      .extension<NestTokens>()!;
}

/// The lilac CTA fill, read from the tokens so the finder cannot drift.
Color _lilacCta(WidgetTester tester) => _tokens(tester).lilacStrong;
