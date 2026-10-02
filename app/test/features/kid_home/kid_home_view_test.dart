// K03 view tests over the in-memory Drift database: the full width × scale ×
// theme matrix, empty/loading/error states, every tap destination, semantics
// labels on icon buttons and kid tap sizes.
//
// Database-backed tests use `setUpTestScope` + Seed.demo (or Seed.empty);
// loading/error paths, which a healthy database cannot produce, use a
// feature-local fake repository registered over the real one in GetIt.
// Every pumped app ends with `disposeApp` (see test_scope.dart).

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';

import '../../test_scope.dart';

const KidChild _maya = KidChild(
  id: 'maya',
  nickname: 'Maya',
  avatarColour: 'lilac',
  coins: 120,
  pipStyle: 'mochi',
  pipSkin: 'sunny',
  pipAccessory: 'none',
  pipStage: 3,
  happiness: 4,
  pinSet: true,
);

/// Maya's 6 quests in repo (alphabetical) order with demo statuses:
/// 4 done (2 approved + 2 done_pending), 2 to_do (q-reading is first).
List<KidQuest> _mayaItems() => const <KidQuest>[
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
    id: 'q-dishwasher:maya',
    title: 'Empty the dishwasher',
    detail: 'Waiting for Mum\u2019s thumbs-up · +15',
    questId: 'q-dishwasher',
    icon: 'dishwasher',
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
    detail: 'Waiting for Mum\u2019s thumbs-up · +10',
    questId: 'q-table',
    icon: 'plate',
    coins: 10,
    status: 'done_pending',
  ),
  KidQuest(
    id: 'q-reading:maya',
    title: 'Reading – 20 minutes',
    detail: 'To do · +10',
    questId: 'q-reading',
    icon: 'book',
    coins: 10,
    status: 'to_do',
  ),
  KidQuest(
    id: 'q-tidy:maya',
    title: 'Tidy your bedroom',
    detail: 'To do · +15',
    questId: 'q-tidy',
    icon: 'bed',
    coins: 15,
    status: 'to_do',
  ),
];

/// Fake repository for the states a Drift database cannot produce:
/// silent streams (loading), stream errors (load failure) and a failing
/// completion write (actionError). Streams are rebuilt per `watch…()` call,
/// matching the Drift repository; a successful `completeQuest` flips the
/// quest to `done_pending` and re-emits, so the celebration can ride the
/// flip exactly as it does on the real repository.
class _FakeKidHomeRepository implements KidHomeRepository {
  _FakeKidHomeRepository({
    this.failLoad = false,
    this.hang = false,
    this.failComplete = false,
  });

  bool failLoad;
  bool hang;
  bool failComplete;

  final List<List<String>> completed = <List<String>>[];
  final StreamController<List<KidQuest>> _itemsPushed =
      StreamController<List<KidQuest>>.broadcast();

  List<KidQuest> _items = _mayaItems();

  @override
  Future<List<KidQuest>> getItems() async => _items;

  @override
  Stream<List<KidQuest>> watchItems() {
    if (hang) {
      return const Stream<List<KidQuest>>.empty();
    }
    if (failLoad) {
      return Stream<List<KidQuest>>.error(Exception('items down'));
    }
    return _watchItems();
  }

  Stream<List<KidQuest>> _watchItems() async* {
    yield _items;
    yield* _itemsPushed.stream;
  }

  @override
  Stream<List<KidChild>> watchProfiles() =>
      Stream<List<KidChild>>.value(const <KidChild>[_maya]);

  @override
  Stream<KidChild?> watchActiveChild() {
    if (hang) {
      return const Stream<KidChild?>.empty();
    }
    if (failLoad) {
      return Stream<KidChild?>.error(Exception('child down'));
    }
    return Stream<KidChild?>.value(_maya);
  }

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> completeQuest(String childId, String questId) async {
    completed.add(<String>[childId, questId]);
    if (failComplete) {
      throw Exception('save failed');
    }
    _items = <KidQuest>[
      for (final quest in _items)
        if (quest.questId == questId)
          KidQuest(
            id: quest.id,
            title: quest.title,
            detail: quest.detail,
            questId: quest.questId,
            icon: quest.icon,
            coins: quest.coins,
            status: 'done_pending',
          )
        else
          quest,
    ];
    _itemsPushed.add(_items);
  }
}

/// Swaps the DI-registered repository for [repo] before pumping the app.
Future<void> _useFakeRepository(KidHomeRepository repo) async {
  await GetIt.instance.unregister<KidHomeRepository>();
  GetIt.instance.registerSingleton<KidHomeRepository>(repo);
}

/// Pumps the full app at [route] on a [width]×844 surface with [textScale].
Future<void> _pumpRoute(
  WidgetTester tester, {
  String route = '/kid-home',
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
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

/// Scrolls the quest list until the (lazy) card column is built. At larger
/// text scales the cards start below the viewport + cache extent, so the
/// widget tree contains none of them until the list moves.
Future<void> _revealCards(WidgetTester tester) async {
  final list = find.byType(Scrollable).first;
  for (var i = 0; i < 10; i++) {
    if (find.byType(NestKidQuestCard).evaluate().isNotEmpty) {
      return;
    }
    await tester.drag(list, const Offset(0, -200));
    await tester.pump();
  }
}

/// Bounded route-transition pumps. `pumpAndSettle` is avoided on purpose:
/// the loading spinner is an endless animation, so a screen that is still
/// loading would spin it forever.
Future<void> _settleRoute(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Asset names of every [SvgPicture] currently in the tree.
List<String> _svgAssets(WidgetTester tester) => find
    .byType(SvgPicture)
    .evaluate()
    .map((element) => (element.widget as SvgPicture).bytesLoader)
    .whereType<SvgAssetLoader>()
    .map((loader) => loader.assetName)
    .toList();

/// v1 Pip illustrations — the orchestrator forbids them in product screens.
List<String> _v1PipAssets(WidgetTester tester) =>
    _svgAssets(tester).where((name) => name.contains('pip_stage')).toList();

/// Adds a quest-less child and makes them the active child.
Future<void> _addQuestlessChild(
  WidgetTester tester, {
  required String id,
  required String nickname,
}) async {
  final db = GetIt.instance<AppDatabase>();
  await tester.runAsync(() async {
    await db
        .into(db.children)
        .insert(
          ChildrenCompanion.insert(
            id: id,
            familyId: Seed.familyId,
            nickname: nickname,
          ),
        );
    await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
      AppStateCompanion(activeChildId: Value<String?>(id)),
    );
    await GetIt.instance<AppSession>().refresh();
  });
}

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  group('K03 layout matrix', () {
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
              await _pumpRoute(
                tester,
                width: width,
                textScale: scale,
                theme: theme,
              );
              expect(find.text('Hi Maya!'), findsOneWidget);
              expect(find.text('120'), findsOneWidget);
              expect(find.text('4 of 6 done'), findsOneWidget);
              await _revealCards(tester);
              expect(find.byType(NestKidQuestCard), findsNWidgets(6));
              expect(find.text('Pip'), findsOneWidget);
              expect(find.text('Shop'), findsOneWidget);
              expect(find.text('My jar'), findsOneWidget);
              expect(find.textContaining('£'), findsNothing);
              expect(tester.takeException(), isNull);
              await disposeApp(tester);
            },
          );
        }
      }
    }
  });

  group('K03 states', () {
    testWidgets('light: no active child offers the picker', (tester) async {
      await tester.runAsync(() => Seed.empty(GetIt.instance<AppDatabase>()));
      await tester.runAsync(() => GetIt.instance<AppSession>().refresh());
      await _pumpRoute(tester);
      expect(find.text('Who\u2019s playing?'), findsOneWidget);
      expect(find.byType(NestKidQuestCard), findsNothing);
      expect(find.byType(NestLockButton), findsNothing);
      await tester.tap(find.text('Choose'));
      await _settleRoute(tester);
      expect(find.text('K01 Who is playing'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('dark: no active child offers the picker', (tester) async {
      await tester.runAsync(() => Seed.empty(GetIt.instance<AppDatabase>()));
      await tester.runAsync(() => GetIt.instance<AppSession>().refresh());
      await _pumpRoute(tester, theme: ThemeMode.dark);
      expect(find.text('Who\u2019s playing?'), findsOneWidget);
      expect(find.byType(NestKidQuestCard), findsNothing);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a child with no quests shows the gentle empty state', (
      tester,
    ) async {
      await _addQuestlessChild(tester, id: 'nina', nickname: 'Nina');
      await _pumpRoute(tester);
      expect(find.text('Hi Nina!'), findsOneWidget);
      expect(find.text('0 done today'), findsOneWidget);
      expect(find.text('No quests today'), findsOneWidget);
      expect(find.text('Enjoy playing with Pip!'), findsOneWidget);
      expect(find.byType(NestKidQuestCard), findsNothing);
      // The dock stays usable when there is nothing to do.
      expect(find.text('Pip'), findsOneWidget);
      expect(find.text('My jar'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    const themes = <(String, ThemeMode)>[
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ];

    for (final (String themeName, ThemeMode theme) in themes) {
      testWidgets('$themeName: silent streams keep the loading state', (
        tester,
      ) async {
        await _useFakeRepository(_FakeKidHomeRepository(hang: true));
        final semantics = tester.ensureSemantics();
        await _pumpRoute(tester, theme: theme);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.bySemanticsLabel('Loading your quests'), findsOneWidget);
        expect(find.byType(NestKidQuestCard), findsNothing);
        expect(tester.takeException(), isNull);
        semantics.dispose();
        await disposeApp(tester);
      });

      testWidgets('$themeName: load failure retries into the loaded home', (
        tester,
      ) async {
        final repo = _FakeKidHomeRepository(failLoad: true);
        await _useFakeRepository(repo);
        await _pumpRoute(tester, theme: theme);
        expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
        expect(find.text('Let\u2019s try again.'), findsOneWidget);
        expect(find.byType(NestKidQuestCard), findsNothing);
        repo.failLoad = false;
        await tester.tap(find.text('Try again'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('Hi Maya!'), findsOneWidget);
        expect(find.byType(NestKidQuestCard), findsNWidgets(6));
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });
    }

    testWidgets('a failed completion keeps the list and shows the snack bar', (
      tester,
    ) async {
      final repo = _FakeKidHomeRepository(failComplete: true);
      await _useFakeRepository(repo);
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      final check = find.bySemanticsLabel('Mark done').first;
      await tester.ensureVisible(check);
      await tester.pump();
      await tester.tap(check);
      await _settleRoute(tester);
      expect(find.text('Hmm, that did not work. Try again.'), findsOneWidget);
      // A failed write never celebrates (K03-BUG-2).
      expect(find.text('K05 Quest complete'), findsNothing);
      expect(repo.completed, <List<String>>[
        <String>['maya', 'q-reading'],
      ]);
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('K03 Pip (orchestrator mandate)', () {
    testWidgets("the pet slot renders the child's own PipAvatar", (
      tester,
    ) async {
      await _pumpRoute(tester);
      final avatar = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(avatar.style, PipStyle.mochi);
      expect(avatar.skin, PipSkin.sunny);
      expect(avatar.accessory, PipAccessory.none);
      expect(avatar.stage, 3);
      expect(avatar.size, 152);
      expect(_v1PipAssets(tester), isEmpty);
      await disposeApp(tester);
    });

    testWidgets("the active child's database look drives PipAvatar (Leo)", (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value<String?>('leo')),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _pumpRoute(tester);
      expect(find.text('Hi Leo!'), findsOneWidget);
      final avatar = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(avatar.style, PipStyle.bolt);
      expect(avatar.skin, PipSkin.sky);
      expect(avatar.accessory, PipAccessory.none);
      expect(avatar.stage, 2);
      expect(_v1PipAssets(tester), isEmpty);
      await disposeApp(tester);
    });

    testWidgets("the empty-quests state shows the child's own Pip", (
      tester,
    ) async {
      await _addQuestlessChild(tester, id: 'nina', nickname: 'Nina');
      await _pumpRoute(tester);
      expect(find.text('No quests today'), findsOneWidget);
      expect(find.byType(PipAvatar), findsOneWidget);
      final avatar = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(avatar.style, PipStyle.mochi);
      expect(avatar.skin, PipSkin.sunny);
      expect(avatar.stage, 1);
      expect(_v1PipAssets(tester), isEmpty);
      await disposeApp(tester);
    });

    testWidgets('no product state renders the v1 pip_stage_*.svg art', (
      tester,
    ) async {
      final repo = _FakeKidHomeRepository(failLoad: true);
      await _useFakeRepository(repo);
      await _pumpRoute(tester);
      expect(find.text('Oh no! Pip got lost.'), findsOneWidget);
      expect(_v1PipAssets(tester), isEmpty);
      await disposeApp(tester);
    });
  });

  group('K03 navigation', () {
    testWidgets('card tap opens quest detail with questId + childId', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final card = find.text('Reading – 20 minutes');
      await tester.ensureVisible(card);
      await tester.pump();
      await tester.tap(card);
      await _settleRoute(tester);
      expect(find.text('K04 Quest detail'), findsOneWidget);
      final state = GoRouter.of(tester.element(find.text('K04 Quest detail')))
          .state;
      expect(state.uri.path, '/quest-detail');
      final extra = state.extra! as Map<String, Object?>;
      expect(extra['questId'], 'q-reading');
      expect(extra['childId'], 'maya');
      await disposeApp(tester);
    });

    testWidgets('check tap completes, persists and opens the celebration', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      final check = find.bySemanticsLabel('Mark done').first;
      await tester.ensureVisible(check);
      await tester.pump();
      await tester.tap(check);
      await _settleRoute(tester);
      expect(find.text('K05 Quest complete'), findsOneWidget);
      final state = GoRouter.of(tester.element(find.text('K05 Quest complete')))
          .state;
      expect(state.uri.path, '/quest-complete');
      final extra = state.extra! as Map<String, Object?>;
      expect(extra['questId'], 'q-reading');
      expect(extra['childId'], 'maya');
      expect(extra['coins'], 10);
      // The tap persisted a done_pending completion in the database.
      final items = await tester.runAsync(
        () => GetIt.instance<KidHomeRepository>().getItems(),
      );
      expect(
        items!.singleWhere((quest) => quest.questId == 'q-reading').status,
        'done_pending',
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('done check falls through to detail and never re-completes', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      final card = find.ancestor(
        of: find.text('Empty the dishwasher'),
        matching: find.byType(NestKidQuestCard),
      );
      final doneCheck = find.descendant(
        of: card,
        matching: find.bySemanticsLabel('Done'),
      );
      expect(doneCheck, findsOneWidget);
      await tester.ensureVisible(doneCheck);
      await tester.pump();
      await tester.tap(doneCheck);
      await _settleRoute(tester);
      // No completion action on the check; the card beneath opens detail
      // and the pending-approval count is untouched.
      expect(find.text('K04 Quest detail'), findsOneWidget);
      final pending = await tester.runAsync(
        () => GetIt.instance<AppDatabase>()
            .watchPendingApprovals(Seed.familyId)
            .first,
      );
      expect(pending, hasLength(3));
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('double-tapping the check completes once', (tester) async {
      final repo = _FakeKidHomeRepository();
      await _useFakeRepository(repo);
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      await _revealCards(tester);
      final check = find.bySemanticsLabel('Mark done').first;
      await tester.ensureVisible(check);
      await tester.pump();
      // Two taps inside one frame: the tap guard must swallow the second.
      await tester.tap(check);
      await tester.tap(check);
      await _settleRoute(tester);
      expect(repo.completed, hasLength(1));
      expect(find.text('K05 Quest complete'), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a failed check tap can be retried and then celebrates', (
      tester,
    ) async {
      final repo = _FakeKidHomeRepository(failComplete: true);
      await _useFakeRepository(repo);
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      await _revealCards(tester);
      final check = find.bySemanticsLabel('Mark done').first;
      await tester.ensureVisible(check);
      await tester.pump();
      await tester.tap(check);
      await _settleRoute(tester);
      expect(find.text('Hmm, that did not work. Try again.'), findsOneWidget);
      expect(find.text('K05 Quest complete'), findsNothing);
      // Let the SnackBar go, then retry the same check: the failure reset
      // must release the tap guard.
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 400));
      repo.failComplete = false;
      await tester.ensureVisible(check);
      await tester.pump();
      await tester.tap(check);
      await _settleRoute(tester);
      expect(find.text('K05 Quest complete'), findsOneWidget);
      expect(repo.completed, hasLength(2));
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('lock opens the parental gate', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      await tester.tap(find.bySemanticsLabel('Grown-ups'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('P17 Parental gate'), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('dock Pip opens /pip', (tester) async {
      await _pumpRoute(tester);
      await tester.tap(find.text('Pip'));
      await _settleRoute(tester);
      expect(find.text('K06 Pip nest'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('dock Shop opens /reward-shop', (tester) async {
      await _pumpRoute(tester);
      await tester.tap(find.text('Shop'));
      await _settleRoute(tester);
      expect(find.text('K08 Reward shop'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('dock My jar opens /my-jar', (tester) async {
      await _pumpRoute(tester);
      await tester.tap(find.text('My jar'));
      await _settleRoute(tester);
      expect(find.text('K09 My jar'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('K03 accessibility', () {
    testWidgets('icon buttons and key labels expose kid semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      expect(find.bySemanticsLabel('Grown-ups'), findsOneWidget);
      expect(find.bySemanticsLabel('120 coins'), findsOneWidget);
      expect(find.bySemanticsLabel('Hi Maya, 4 done today'), findsOneWidget);
      expect(
        find.bySemanticsLabel('4 of 6 of today\u2019s quests done'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Pip is happy today, 4 of 5 hearts'),
        findsOneWidget,
      );
      await _revealCards(tester);
      // Four cards are done (2 approved + 2 done_pending), so all four
      // checks read 'Done'; only the two to-do checks read 'Mark done'.
      expect(find.bySemanticsLabel('Mark done'), findsNWidgets(2));
      expect(find.bySemanticsLabel('Done'), findsNWidgets(4));
      // Card nodes merge title + status into one label (read via the merged
      // node, since `bySemanticsLabel` cannot see merged nodes). Descendant
      // texts append after the button label, so match the prefix.
      expect(
        tester.getSemantics(find.text('Empty the dishwasher')).label,
        startsWith('Empty the dishwasher, Waiting for Mum\u2019s thumbs-up'),
      );
      expect(
        tester.getSemantics(find.text('Put the bins out')).label,
        startsWith('Put the bins out, Done'),
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('kid tap targets meet the 56 minimum', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      _expectAtLeast(
        tester,
        find.byType(NestLockButton),
        NestDevice.tapKid,
        'lock button',
      );
      await _revealCards(tester);
      _expectAtLeast(
        tester,
        find.bySemanticsLabel('Mark done').first,
        NestDevice.tapKid,
        'to-do check',
      );
      final dockButtons = find.byType(NestKidButton).evaluate().length;
      expect(dockButtons, 3);
      for (var i = 0; i < dockButtons; i++) {
        _expectAtLeast(
          tester,
          find.byType(NestKidButton).at(i),
          NestDevice.tapKid,
          'dock button $i',
        );
      }
      final cards = find.byType(NestKidQuestCard).evaluate().length;
      expect(cards, 6);
      for (var i = 0; i < cards; i++) {
        _expectAtLeast(
          tester,
          find.byType(NestKidQuestCard).at(i),
          NestDevice.tapKid,
          'quest card row $i',
        );
      }
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('320px at 1.3 scale keeps lock and progress semantics', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester, width: 320, textScale: 1.3);
      expect(find.text('Hi Maya!'), findsOneWidget);
      expect(find.text('Pip'), findsOneWidget);
      expect(find.bySemanticsLabel('Grown-ups'), findsOneWidget);
      expect(
        find.bySemanticsLabel('4 of 6 of today\u2019s quests done'),
        findsOneWidget,
      );
      await _revealCards(tester);
      expect(find.byType(NestKidQuestCard), findsNWidgets(6));
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await disposeApp(tester);
    });
  });
}
