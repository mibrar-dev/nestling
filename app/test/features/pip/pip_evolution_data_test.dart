// K07 · Pip evolves — the screen is the DATABASE's Pip.
//
// `pip_evolution_view_test.dart` proves the celebration agrees with the demo
// seed. That is one lucky database, and it cannot tell a data-driven screen
// from one that happens to be right about Maya. This file changes the rows and
// watches the screen follow, on three orchestrator rulings:
//
//   * PERIODS — K07's `questsDone` is a LIFETIME milestone, so the ruling that
//     a quest counts only for its current period (daily → the current London
//     day, weekly → the current London week) deliberately does NOT apply here.
//     Every test below first proves its own row would NOT count for its period
//     (`countsForCurrentPeriod`, `core/data/london_time.dart`) and only then
//     asserts the screen counts it, so the assertion cannot pass vacuously.
//   * DATA OVER MOCKS — every number, stage word and Pip is the ACTIVE child's
//     row: Leo (Bolt / sky / stage 2) as well as Maya, including a live switch
//     between children while the screen is open.
//   * ORCHESTRATOR PIP — both stage slots render the child's OWN Pip through
//     `PipAvatar` (style / skin / accessory / stage from the database), never
//     the v1 `pip-stage-*.svg` illustrations.
//
// Plus the one piece of copy only a one-row database can show: the singular
// `Because you helped 1 time`.
//
// Widget tests end with `disposeApp` INSIDE the body (RULES §7.1) and wait for
// the state they assert rather than trusting a fake-clock delay (K06's
// `_pumpUntil` note: the data arrives over real Drift streams, and 400 ms of
// fake time can pass before the query has answered on a loaded machine).
// Nothing here reads the wall clock — `appNowUtc()` is the pinned instant.

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/london_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/pip/data/pip_repository_impl.dart';

import '../../test_scope.dart';

/// Maya's seeded truth (`Seed.demo`): four lifetime helped times, 175 lifetime
/// coins, stage 3. Leo: two, 60, stage 2. Expectations only — the view holds
/// no literals.
const int _mayaQuestsDone = 4;
const int _mayaTotalCoins = 175;
const int _mayaStage = 3;

const int _leoQuestsDone = 2;
const int _leoTotalCoins = 60;
const int _leoStage = 2;

/// A completion old enough to be outside its own period under the PERIODS
/// ruling: a month before the pinned Sat 3 Oct 2026 story day. No clock is
/// read to build it — `Seed.utc` is anchored to `Seed.anchorDay`.
final DateTime _lastMonth = Seed.utc(8, 12, 17, 30);

/// Yesterday (Fri 2 Oct 2026): a different London DAY, the sharpest form of
/// the period question.
final DateTime _yesterday = Seed.utc(10, 2, 16, 40);

/// Fri 25 Sep 2026: the London week before the pinned one (Sat 3 Oct sits in
/// the Mon 29 Sep – Sun 4 Oct week).
final DateTime _lastWeek = Seed.utc(9, 25, 16, 40);

Future<void> _addCompletion(
  AppDatabase db, {
  required String questId,
  required String childId,
  required String status,
  required DateTime createdAt,
}) {
  return db
      .into(db.questCompletions)
      .insert(
        QuestCompletionsCompanion.insert(
          questId: questId,
          childId: childId,
          familyId: Seed.familyId,
          status: Value(status),
          coins: const Value(10),
          createdAt: Value(createdAt),
          createdAtTz: const Value('Europe/London'),
        ),
      );
}

/// Bounded pumps: `pumpAndSettle` would hang on the loading spinner's endless
/// animation.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Pumps until [ready] matches (bounded to ~3 s of real time), then settles.
Future<void> _pumpUntil(WidgetTester tester, Finder ready) async {
  for (var i = 0; i < 60 && ready.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  await _settle(tester);
}

List<PipAvatar> pipsOf(WidgetTester tester) => tester
    .widgetList<PipAvatar>(find.byType(PipAvatar))
    .toList(growable: false);

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await setUpTestScope();
  });

  /// Writes to the shared in-memory DB from a widget test (real event loop).
  Future<void> write(WidgetTester tester, Future<void> Function() body) =>
      tester.runAsync(body);

  /// Sets `app_state.active_child_id` and re-reads the session, so both the
  /// K07 streams (`_db.watchAppState()`) and the app shell see the switch.
  Future<void> useChild(WidgetTester tester, String? childId) =>
      tester.runAsync(() async {
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          AppStateCompanion(activeChildId: Value(childId)),
        );
        await GetIt.instance<AppSession>().refresh();
      });

  /// Pumps `/pip-evolution` and waits for the loaded celebration.
  Future<void> pumpEvolution(WidgetTester tester) async {
    await pumpAppRoute(tester, '/pip-evolution');
    await _pumpUntil(tester, find.byKey(const Key('k07-cta')));
  }

  /// The value inside one stat card, by the card's own key (never by a bare
  /// `find.text`, because a child can legitimately show the same number in
  /// two cards — Leo is "2 helped / 60 coins / stage 2").
  Finder statValue(String cardKey, String value) =>
      find.descendant(of: find.byKey(Key(cardKey)), matching: find.text(value));

  group('the lifetime milestone ignores the PERIODS ruling', () {
    // `watchEvolution` counts every `done_pending` / `approved` completion, all
    // time (1_plan.md §(b)). These tests are what stop a future "fix" from
    // quietly applying `countsForCurrentPeriod` here: each row is outside its
    // period, and each still counts.
    //
    // Every row below belongs to a quest the child has NEVER completed, so the
    // count is the same whether a milestone counts completion ROWS (today) or
    // DISTINCT quests (`k07_bugs_test.dart`'s open K07-BUG-3). These tests
    // answer the period question only and must not pin either side of that.
    test('a daily quest approved YESTERDAY still counts', () async {
      final repo = PipRepositoryImpl(db: db);
      expect(
        countsForCurrentPeriod('daily', _yesterday, appNowUtc()),
        isFalse,
        reason:
            'yesterday is a different London day, so the PERIODS ruling would '
            'not count this row — the assertion below is not vacuous',
      );

      // q-reading is one of Maya's seeded `to_do` quests: nothing completed it
      // yet, so this row adds exactly one quest.
      await _addCompletion(
        db,
        questId: 'q-reading',
        childId: 'maya',
        status: 'approved',
        createdAt: _yesterday,
      );

      expect(
        (await repo.watchEvolution().first)!.questsDone,
        _mayaQuestsDone + 1,
      );
    });

    test('a weekly quest approved LAST WEEK still counts', () async {
      final repo = PipRepositoryImpl(db: db);
      expect(
        countsForCurrentPeriod('weekly', _lastWeek, appNowUtc()),
        isFalse,
        reason:
            'last week is a different London week, so the PERIODS ruling would '
            'not count this row — the assertion below is not vacuous',
      );

      // Maya's two seeded weekly quests (q-bins, q-hoover) are already done,
      // so the weekly case gets a quest of its own — again one with no
      // completion yet, so rows and distinct quests agree.
      await db
          .into(db.quests)
          .insert(
            QuestsCompanion.insert(
              id: 'q-veggies',
              familyId: Seed.familyId,
              title: 'Pick the veg patch',
              icon: const Value('leaf'),
              coins: const Value(10),
              repeatRule: const Value('weekly'),
              assigneeChildId: const Value('maya'),
              createdAt: Value(Seed.utc(9, 19, 8)),
            ),
          );
      await _addCompletion(
        db,
        questId: 'q-veggies',
        childId: 'maya',
        status: 'approved',
        createdAt: _lastWeek,
      );

      expect(
        (await repo.watchEvolution().first)!.questsDone,
        _mayaQuestsDone + 1,
      );
    });

    test('a daily quest approved LAST MONTH still counts', () async {
      final repo = PipRepositoryImpl(db: db);
      expect(countsForCurrentPeriod('daily', _lastMonth, appNowUtc()), isFalse);

      await _addCompletion(
        db,
        questId: 'q-tidy',
        childId: 'maya',
        status: 'approved',
        createdAt: _lastMonth,
      );

      expect(
        (await repo.watchEvolution().first)!.questsDone,
        _mayaQuestsDone + 1,
      );
    });

    test('a `done_pending` row from last month counts too', () async {
      final repo = PipRepositoryImpl(db: db);
      await _addCompletion(
        db,
        questId: 'q-washing',
        childId: 'maya',
        status: 'done_pending',
        createdAt: _lastMonth,
      );

      expect(
        (await repo.watchEvolution().first)!.questsDone,
        _mayaQuestsDone + 1,
        reason:
            'awaiting a grown-up still counts — the milestone is helped '
            'times, not paid ones',
      );
    });

    testWidgets('the screen counts a month-old completion and shows the '
        'singular sub for it', (tester) async {
      // Only ONE counting row, and it is a month old: the sub's singular form
      // is reachable from the database alone (no helper-only assertion), and
      // the count can only come from a lifetime read.
      await write(tester, () async {
        await (db.delete(
          db.questCompletions,
        )..where((c) => c.childId.equals('maya'))).go();
        await _addCompletion(
          db,
          questId: 'q-dishwasher',
          childId: 'maya',
          status: 'approved',
          createdAt: _lastMonth,
        );
      });

      await pumpEvolution(tester);

      expect(find.text('Because you helped 1 time'), findsOneWidget);
      expect(find.textContaining('times'), findsNothing);
      expect(statValue('k07-card-quests', '1'), findsOneWidget);
      // The rest of the celebration is untouched by the count.
      expect(find.text('Pip grew into a Fledgling!'), findsOneWidget);
      expect(statValue('k07-card-coins', '$_mayaTotalCoins'), findsOneWidget);
      expect(statValue('k07-card-stage', '$_mayaStage'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('the active child’s own Pip (ORCHESTRATOR PIP + DATA OVER MOCKS)', () {
    testWidgets('Leo renders Bolt/sky at stage 2 with his own numbers', (
      tester,
    ) async {
      await useChild(tester, 'leo');
      await pumpEvolution(tester);

      expect(find.text('Pip grew into a Hatchling!'), findsOneWidget);
      expect(
        find.text('Because you helped $_leoQuestsDone times'),
        findsOneWidget,
      );
      expect(find.text('Hello! Pip is out of the egg!'), findsOneWidget);
      expect(find.text('Meet Hatchling Pip'), findsOneWidget);
      // Maya's stage words are nowhere on Leo's screen.
      expect(find.textContaining('Fledgling'), findsNothing);

      expect(statValue('k07-card-quests', '$_leoQuestsDone'), findsOneWidget);
      expect(statValue('k07-card-coins', '$_leoTotalCoins'), findsOneWidget);
      expect(statValue('k07-card-stage', '$_leoStage'), findsOneWidget);

      // ORCHESTRATOR PIP RULE: the DB's look for THIS child in BOTH slots, one
      // stage apart — never a v1 `pip-stage-*.svg`.
      final avatars = pipsOf(tester);
      expect(avatars.length, 2);
      for (final avatar in avatars) {
        expect(avatar.style, PipStyle.bolt);
        expect(avatar.skin, PipSkin.sky);
      }
      final stages = avatars.map((a) => a.stage).toList()..sort();
      expect(stages, <int>[_leoStage - 1, _leoStage]);

      expect(
        tester
            .getSemantics(find.byKey(const Key('k07-new-pip')))
            .getSemanticsData()
            .label,
        "Leo's Pip, a hatchling",
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('switching the active child while the screen is open '
        're-renders Pip, without navigating', (tester) async {
      await pumpEvolution(tester);
      expect(find.text('Pip grew into a Fledgling!'), findsOneWidget);
      expect(pipsOf(tester).every((a) => a.style == PipStyle.mochi), isTrue);

      await useChild(tester, 'leo');
      await _pumpUntil(tester, find.text('Meet Hatchling Pip'));

      expect(find.text('Pip grew into a Hatchling!'), findsOneWidget);
      expect(find.text('Pip grew into a Fledgling!'), findsNothing);
      expect(statValue('k07-card-coins', '$_leoTotalCoins'), findsOneWidget);
      expect(
        pipsOf(tester)
            .every((a) => a.style == PipStyle.bolt && a.skin == PipSkin.sky),
        isTrue,
      );
      // The screen never left: a live data change is not a navigation.
      expect(currentPath(tester), '/pip-evolution');
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('an equipped accessory reaches both slots and never the '
        'counts', (tester) async {
      // The K06 wardrobe writes `pip_accessory` on the child row, so this
      // screen must render THAT row — not a constant `PipAccessory.none` — in
      // both slots, and must leave the milestone numbers alone.
      //
      // The write happens BEFORE the pump: a Drift write to `children`
      // from inside a live `tester.runAsync` (i.e. after the app is
      // pumping) wedges on this project's AppSession watch — see
      // `docs/screens/K07/3_test.md` §Observations 1. So this one is a
      // setup step, and the live-update proof in this file is the child
      // switch above, which writes `app_state` and completes normally.
      await write(tester, () async {
        await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
          const ChildrenCompanion(pipAccessory: Value('scarf')),
        );
        await GetIt.instance<AppSession>().refresh();
      });
      await pumpEvolution(tester);

      final avatars = pipsOf(tester);
      expect(avatars.length, 2);
      expect(
        avatars.every((a) => a.accessory == PipAccessory.scarf),
        isTrue,
        reason: 'both slots render the child’s own look',
      );
      // The look is the only thing that changed.
      expect(statValue('k07-card-quests', '$_mayaQuestsDone'), findsOneWidget);
      expect(statValue('k07-card-coins', '$_mayaTotalCoins'), findsOneWidget);
      expect(statValue('k07-card-stage', '$_mayaStage'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });
}
