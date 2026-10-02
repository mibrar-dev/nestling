// K03 (kid home) adversarial test suite — Stage 6 bug hunt.
//
// Every bug proof is written to FAIL while the corresponding bug exists and
// is marked `skip: true` (this Flutter test API takes a bool, so the
// `K03-BUG-n` id lives in the test name) to keep the suite green. The full
// write-up lives in docs/screens/K03/6_bugs.md; run the proofs with
// `flutter test --run-skipped --plain-name "K03-BUG"`.
//
// Probes that pass are kept as evidence for the "checked, clean" categories
// (contrast, overflow, persistence, money rounding, deep links).

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/london_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_home/data/kid_home_repository_impl.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_bloc.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_event.dart';

import '../../test_scope.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Pumps the full app at [route] with optional kid mode / width / scale.
Future<void> _pump(
  WidgetTester tester, {
  String route = '/kid-home',
  bool kidMode = true,
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  if (kidMode) {
    GetIt.instance<AppModeController>().selectMode(AppMode.kid);
  }
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Scrolls the quest list until the (lazy) card column is built.
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

double _linear(double channel) => channel <= 0.03928
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b);

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  // -------------------------------------------------------------------------
  // K03-BUG-1 — rapid double tap inserts a duplicate pending completion
  // -------------------------------------------------------------------------

  test('K03-BUG-1 repo: second completeQuest after done_pending creates a '
      'duplicate row', () async {
    final db = GetIt.instance<AppDatabase>();
    final repo = KidHomeRepositoryImpl(db: db);
    await repo.completeQuest('maya', 'q-reading');
    await repo.completeQuest('maya', 'q-reading');
    final rows = await db.select(db.questCompletions).get();
    final mine = rows
        .where((r) => r.questId == 'q-reading' && r.childId == 'maya')
        .toList();
    expect(
      mine.where((r) => r.status == 'done_pending'),
      hasLength(1),
      reason: 'a quest must have at most one pending completion',
    );
  }, skip: true);

  testWidgets(
    'K03-BUG-1 widget: double-tapping the check creates two pending rows',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);
      await _revealCards(tester);
      final check = find.bySemanticsLabel('Mark done').first;
      await tester.ensureVisible(check);
      await tester.pump();
      // Two taps inside one frame: the route push has not been laid out yet,
      // so both hit the same check.
      await tester.tap(check);
      await tester.tap(check);
      await _settle(tester);
      final rows = await tester.runAsync(
        () => (GetIt.instance<AppDatabase>().select(
          GetIt.instance<AppDatabase>().questCompletions,
        )..where((c) => c.questId.equals('q-reading'))).get(),
      );
      semantics.dispose();
      await disposeApp(tester);
      expect(
        rows!.where((r) => r.status == 'done_pending'),
        hasLength(1),
        reason: 'rapid double tap must be idempotent',
      );
    },
    skip: true,
  );

  // -------------------------------------------------------------------------
  // K03-BUG-2 — the celebration opens even when the save fails
  // -------------------------------------------------------------------------

  testWidgets('K03-BUG-2: a failed completion still opens the celebration', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _useFakeRepository(_FailSaveRepository());
    await _pump(tester);
    await _revealCards(tester);
    final check = find.bySemanticsLabel('Mark done').first;
    await tester.ensureVisible(check);
    await tester.pump();
    await tester.tap(check);
    await _settle(tester);
    expect(
      find.text('K05 Quest complete'),
      findsNothing,
      reason: 'do not celebrate a quest the database never recorded',
    );
    semantics.dispose();
    await disposeApp(tester);
  }, skip: true);

  // -------------------------------------------------------------------------
  // K03-BUG-3 — identical failures after the first are never surfaced
  // -------------------------------------------------------------------------

  test('K03-BUG-3: state keeps the first actionError forever so a second '
      'identical failure is not announced', () async {
    final repo = _FailSaveRepository();
    final bloc = KidHomeBloc(repository: repo);
    final errors = <String?>[];
    final sub = bloc.stream.listen((s) => errors.add(s.actionError));
    bloc.add(const KidHomeLoadRequested());
    await Future<void>.delayed(const Duration(milliseconds: 30));
    bloc.add(
      const KidHomeQuestCompleted(
        childId: 'maya',
        questId: 'q-reading',
        coins: 10,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    bloc.add(
      const KidHomeQuestCompleted(
        childId: 'maya',
        questId: 'q-tidy',
        coins: 15,
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await sub.cancel();
    await bloc.close();
    expect(
      errors.where((e) => e != null),
      hasLength(2),
      reason: 'the second failed tap must also surface feedback',
    );
  }, skip: true);

  // -------------------------------------------------------------------------
  // K03-BUG-4 — "done today" counts completions from previous London days
  // -------------------------------------------------------------------------

  testWidgets(
    'K03-BUG-4: a completion from a previous London day still reads as '
    'done today',
    (tester) async {
      final db = GetIt.instance<AppDatabase>();
      final thirtyHoursAgo = DateTime.now().toUtc().subtract(
        const Duration(hours: 30),
      );
      expect(
        toLondon(thirtyHoursAgo).day == toLondon(DateTime.now().toUtc()).day,
        isFalse,
        reason: '30h always crosses a London calendar day',
      );
      await tester.runAsync(() async {
        await db.delete(db.questCompletions).go();
        await db
            .into(db.questCompletions)
            .insert(
              QuestCompletionsCompanion.insert(
                questId: 'q-reading',
                childId: 'maya',
                familyId: Seed.familyId,
                status: const Value('approved'),
                coins: const Value(10),
                createdAt: Value(thirtyHoursAgo),
                decidedAt: Value(thirtyHoursAgo),
              ),
            );
      });
      await _pump(tester);
      expect(
        find.text('0 done today'),
        findsOneWidget,
        reason: 'yesterday\u2019s approval is not done today',
      );
      await disposeApp(tester);
    },
    skip: true,
  );

  // -------------------------------------------------------------------------
  // K03-BUG-5 — kid-mode guard misses parent routes added after the list
  // -------------------------------------------------------------------------

  testWidgets(
    'K03-BUG-5: kid mode can deep-link to /today-empty without the gate',
    (tester) async {
      await _pump(tester, route: '/today-empty');
      expect(currentPath(tester), '/parental-gate');
      await disposeApp(tester);
    },
    skip: true,
  );

  testWidgets(
    'K03-BUG-5: kid mode can deep-link to /quest-editor without the gate',
    (tester) async {
      await _pump(tester, route: '/quest-editor');
      expect(currentPath(tester), '/parental-gate');
      await disposeApp(tester);
    },
    skip: true,
  );

  // -------------------------------------------------------------------------
  // Edge-case probes: passing checks + further skipped bug proofs
  // -------------------------------------------------------------------------

  group('edge-case probes', () {
    testWidgets('guard still blocks /today in kid mode', (tester) async {
      await _pump(tester, route: '/today');
      expect(currentPath(tester), '/parental-gate');
      await disposeApp(tester);
    });

    testWidgets('deep link to /kid-home in kid mode renders the home', (
      tester,
    ) async {
      await _pump(tester);
      expect(find.text('Hi Maya!'), findsOneWidget);
      expect(find.text('4 of 6 done'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('deep link to /kid-home with no active child offers picker', (
      tester,
    ) async {
      await tester.runAsync(() => Seed.empty(GetIt.instance<AppDatabase>()));
      await tester.runAsync(() => GetIt.instance<AppSession>().refresh());
      await _pump(tester);
      expect(find.text('Who\u2019s playing?'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('zero children, long nickname and 9999 coins at 320/1.3 '
        'do not overflow', (tester) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await db
            .into(db.children)
            .insert(
              ChildrenCompanion.insert(
                id: 'max',
                familyId: Seed.familyId,
                nickname: 'Maximilian-Alexander',
                avatarColour: const Value('sky'),
                coins: const Value(9999),
                happiness: const Value(0),
              ),
            );
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value<String?>('max')),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await _pump(tester, width: 320, textScale: 1.3);
      expect(find.text('Hi Maximilian-Alexander!'), findsOneWidget);
      expect(find.text('9999'), findsOneWidget);
      expect(find.text('0 done today'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a family with a single child renders the home', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.delete(
          db.questCompletions,
        )..where((c) => c.childId.equals('leo'))).go();
        await (db.delete(db.children)..where((c) => c.id.equals('leo'))).go();
      });
      await _pump(tester);
      expect(find.text('Hi Maya!'), findsOneWidget);
      expect(find.text('4 of 6 done'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('six children in the family do not change the home', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        for (var i = 0; i < 4; i++) {
          await db
              .into(db.children)
              .insert(
                ChildrenCompanion.insert(
                  id: 'extra$i',
                  familyId: Seed.familyId,
                  nickname: 'Extra Child $i',
                ),
              );
        }
      });
      await _pump(tester);
      expect(find.text('Hi Maya!'), findsOneWidget);
      expect(find.text('4 of 6 done'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('zero-cost and long quests render with integer coins only', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await db
            .into(db.quests)
            .insert(
              QuestsCompanion.insert(
                id: 'q-free',
                familyId: Seed.familyId,
                title:
                    'A very long quest title that should wrap to two lines '
                    'without losing its coin reward',
                coins: const Value(0),
                assigneeChildId: const Value('maya'),
              ),
            );
      });
      await _pump(tester);
      await _revealCards(tester);
      expect(find.textContaining('\u00a3'), findsNothing);
      expect(find.text('+0'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('back from the celebration returns to the home with the '
        'card flipped', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);
      await _revealCards(tester);
      final check = find.bySemanticsLabel('Mark done').first;
      await tester.ensureVisible(check);
      await tester.pump();
      await tester.tap(check);
      await _settle(tester);
      expect(find.text('K05 Quest complete'), findsOneWidget);
      await tester.pageBack();
      await _settle(tester);
      expect(find.text('Hi Maya!'), findsOneWidget);
      await _revealCards(tester);
      expect(find.text('Waiting for Mum'), findsNWidgets(3));
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('K03-BUG-6: double-tapping a quest card stacks two detail '
        'routes', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);
      await _revealCards(tester);
      final card = find.text('Reading \u2013 20 minutes');
      await tester.ensureVisible(card);
      await tester.pump();
      await tester.tap(card);
      await tester.tap(card);
      await _settle(tester);
      expect(find.text('K04 Quest detail'), findsOneWidget);
      await tester.pageBack();
      await _settle(tester);
      expect(
        find.text('Hi Maya!'),
        findsOneWidget,
        reason: 'one back press must leave the detail',
      );
      semantics.dispose();
      await disposeApp(tester);
    }, skip: true);

    testWidgets('K03-BUG-6: double-tapping the check stacks two celebration '
        'routes', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pump(tester);
      await _revealCards(tester);
      final check = find.bySemanticsLabel('Mark done').first;
      await tester.ensureVisible(check);
      await tester.pump();
      await tester.tap(check);
      await tester.tap(check);
      await _settle(tester);
      expect(find.text('K05 Quest complete'), findsOneWidget);
      await tester.pageBack();
      await _settle(tester);
      expect(
        find.text('Hi Maya!'),
        findsOneWidget,
        reason: 'one back press must leave the celebration',
      );
      semantics.dispose();
      await disposeApp(tester);
    }, skip: true);

    test('verified clean: a late failure emitted after bloc close does not '
        'throw', () async {
      final repo = _SlowFailRepository();
      final bloc = KidHomeBloc(repository: repo);
      _load(bloc);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      _complete(bloc, 'q-reading', 10);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      await bloc.close();
      // The write fails only after the bloc is closed.
      repo.fail();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });

    test('Drift file persistence survives a database reopen', () async {
      final dir = Directory.systemTemp.createTempSync('k03_restart_');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/nestling.db');
      final db1 = AppDatabase(NativeDatabase(file));
      await Seed.demo(db1);
      await KidHomeRepositoryImpl(db: db1).completeQuest('maya', 'q-reading');
      await db1.close();
      final db2 = AppDatabase(NativeDatabase(file));
      final items = await KidHomeRepositoryImpl(db: db2).getItems();
      await db2.close();
      expect(
        items.singleWhere((q) => q.questId == 'q-reading').status,
        'done_pending',
      );
    });

    test('K03 token pairs meet WCAG contrast in light and dark', () {
      const light = NestColors.light;
      const dark = NestColors.dark;
      final pairs = <String, (Color, Color)>{
        'light ink on skyTop': (light.ink, light.kidSkyTop),
        'light ink on skyBottom': (light.ink, light.kidSkyBottom),
        'light ink2 on skyTop': (light.ink2, light.kidSkyTop),
        'light coinInk on coinTint': (light.coinInk, light.coinTint),
        'light leafInk on leafTint': (light.leafInk, light.leafTint),
        'light onLeaf on leaf': (light.onLeaf, light.leaf),
        'light onAccent on lilacStrong': (light.onAccent, light.lilacStrong),
        'light onWarm on coin': (light.onWarm, light.coin),
        'dark ink on skyTop': (dark.ink, dark.kidSkyTop),
        'dark ink2 on skyTop': (dark.ink2, dark.kidSkyTop),
        'dark coinInk on coinTint': (dark.coinInk, dark.coinTint),
        'dark leafInk on leafTint': (dark.leafInk, dark.leafTint),
        'dark onLeaf on leaf': (dark.onLeaf, dark.leaf),
        'dark onAccent on lilacStrong': (dark.onAccent, dark.lilacStrong),
        'dark onWarm on coin': (dark.onWarm, dark.coin),
        'dark ink on surface': (dark.ink, dark.surface),
      };
      for (final MapEntry(key: name, value: (a, b)) in pairs.entries) {
        expect(
          _contrast(a, b),
          greaterThanOrEqualTo(4.5),
          reason: '$name contrast',
        );
      }
    });
  });
}

// ---------------------------------------------------------------------------
// Fake repository: streams are healthy, `completeQuest` always fails.
// ---------------------------------------------------------------------------

class _SlowFailRepository implements KidHomeRepository {
  final Completer<void> _gate = Completer<void>();

  void fail() {
    if (!_gate.isCompleted) {
      _gate.completeError(Exception('save failed after dispose'));
    }
  }

  @override
  Future<List<KidQuest>> getItems() async => _items;

  @override
  Stream<List<KidQuest>> watchItems() => Stream<List<KidQuest>>.value(_items);

  @override
  Stream<List<KidChild>> watchProfiles() =>
      Stream<List<KidChild>>.value(const <KidChild>[]);

  @override
  Stream<KidChild?> watchActiveChild() => Stream<KidChild?>.value(_maya);

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> completeQuest(String childId, String questId) => _gate.future;
}

class _FailSaveRepository implements KidHomeRepository {
  @override
  Future<List<KidQuest>> getItems() async => _items;

  @override
  Stream<List<KidQuest>> watchItems() => Stream<List<KidQuest>>.value(_items);

  @override
  Stream<List<KidChild>> watchProfiles() =>
      Stream<List<KidChild>>.value(const <KidChild>[]);

  @override
  Stream<KidChild?> watchActiveChild() => Stream<KidChild?>.value(_maya);

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> completeQuest(String childId, String questId) async {
    throw Exception('save failed');
  }
}

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

const List<KidQuest> _items = <KidQuest>[
  KidQuest(
    id: 'q-reading:maya',
    title: 'Reading \u2013 20 minutes',
    detail: 'To do \u00b7 +10',
    questId: 'q-reading',
    icon: 'book',
    coins: 10,
    status: 'to_do',
  ),
  KidQuest(
    id: 'q-tidy:maya',
    title: 'Tidy your bedroom',
    detail: 'To do \u00b7 +15',
    questId: 'q-tidy',
    icon: 'bed',
    coins: 15,
    status: 'to_do',
  ),
];

/// Swaps the DI-registered repository for [repo] before pumping the app.
Future<void> _useFakeRepository(KidHomeRepository repo) async {
  await GetIt.instance.unregister<KidHomeRepository>();
  GetIt.instance.registerSingleton<KidHomeRepository>(repo);
}

void _load(KidHomeBloc bloc) => bloc.add(const KidHomeLoadRequested());

void _complete(KidHomeBloc bloc, String questId, int coins) => bloc.add(
  KidHomeQuestCompleted(childId: 'maya', questId: questId, coins: coins),
);
