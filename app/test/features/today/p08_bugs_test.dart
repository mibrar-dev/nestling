// P08 · Today (home) — adversarial bug proofs (Stage 6, iteration 1).
//
// Every test below asserts the CORRECT behaviour for a bug found while
// hunting: data edge cases (children with no quests, 3+/6 children, family
// wide pending approvals), parent/kid guard bypass, back navigation, rapid
// retry leaks, and design-system/mandatory-rule violations.
//
// They FAIL against the iteration-1 screen, so each widget test is
// `skip: true` with its bug id in the test name (the suite stays green until
// the fix lands; the fix stage removes the skips). Run the proofs with
// `flutter test --run-skipped test/features/today/p08_bugs_test.dart`.
//
// Full reports with severity, repro and suggested fixes:
// `docs/screens/P08/6_bugs.md`.

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/today/data/today_repository_impl.dart';
import 'package:nestling/features/today/domain/entities/child_day_summary.dart';
import 'package:nestling/features/today/domain/entities/today_item.dart';
import 'package:nestling/features/today/domain/today_repository.dart';
import 'package:nestling/features/today/presentation/bloc/today_bloc.dart';
import 'package:nestling/features/today/presentation/bloc/today_event.dart';
import 'package:nestling/features/today/presentation/views/today_view.dart';

import '../../test_scope.dart';

class _MockTodayRepository extends Mock implements TodayRepository;

Future<void> _insertChild(
  AppDatabase db,
  String id,
  String nickname,
  int age,
) async {
  await db
      .into(db.children)
      .insert(
        ChildrenCompanion.insert(
          id: id,
          familyId: Seed.familyId,
          nickname: nickname,
          ageYears: Value(age),
          avatarColour: const Value('sky'),
        ),
      );
}

Future<void> _insertQuest(
  AppDatabase db,
  String id,
  String title,
  String childId,
) async {
  await db
      .into(db.quests)
      .insert(
        QuestsCompanion.insert(
          id: id,
          familyId: Seed.familyId,
          title: title,
          coins: const Value(5),
          assigneeChildId: Value(childId),
        ),
      );
}

/// Pumps [TodayView] directly (no router) over [bloc] — for state-proofs that
/// need a repository whose stream errors while staying open.
Future<void> _pumpTodayView(WidgetTester tester, TodayBloc bloc) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      home: BlocProvider<TodayBloc>.value(
        value: bloc,
        child: const TodayView(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('P08 guard bypass', () {
    testWidgets('[P08-B01] kid mode cannot deep-link into /today-empty', (
      tester,
    ) async {
      await setUpTestScope();
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      final session = GetIt.instance<AppSession>();
      await session.setAppMode('kid');
      await session.refresh();

      await pumpAppRoute(tester, '/today-empty');

      expect(currentPath(tester), '/parental-gate');
      await disposeApp(tester);
    }, skip: true);
  });

  group('P08 Pip artwork (mandatory orchestrator rule)', () {
    testWidgets("[P08-B02] kid cards render each child's own PipAvatar", (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      final pips = tester
          .widgetList<PipAvatar>(find.byType(PipAvatar))
          .toList();
      expect(pips, hasLength(2), reason: 'one Pip per kid card');
      // Maya = Mochi · sunny · stage 3 (seed `maya`).
      expect(pips.first.style, PipStyle.mochi);
      expect(pips.first.skin, PipSkin.sunny);
      expect(pips.first.stage, 3);
      expect(pips.first.accessory, PipAccessory.none);
      // Leo = Bolt · sky · stage 2 (seed `leo`).
      expect(pips.last.style, PipStyle.bolt);
      expect(pips.last.skin, PipSkin.sky);
      expect(pips.last.stage, 2);

      await disposeApp(tester);
    }, skip: true);

    testWidgets('[P08-B03] P08b empty state uses PipAvatar (mochi/sunny/1)', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/today-empty');

      final pips = tester
          .widgetList<PipAvatar>(find.byType(PipAvatar))
          .toList();
      expect(pips, hasLength(1));
      expect(pips.single.style, PipStyle.mochi);
      expect(pips.single.skin, PipSkin.sunny);
      expect(pips.single.stage, 1);

      await disposeApp(tester);
    }, skip: true);
  });

  group('P08 data edge cases', () {
    testWidgets('[P08-B04] a child with no assigned quests still gets a card', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await _insertChild(db, 'sam', 'Sam', 5);

      await pumpAppRoute(tester, '/today');

      // P05 adds children before any quest is assigned; the home screen must
      // still show the child (design: a card per child).
      expect(find.text('Sam'), findsOneWidget);
      await disposeApp(tester);
    }, skip: true);

    testWidgets('[P08-B05] three children keep the 2-up kids grid', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await _insertChild(db, 'sam', 'Sam', 5);
      await _insertQuest(db, 'q-sam', 'Feed the hamster', 'sam');

      await pumpAppRoute(tester, '/today');

      expect(find.text('Sam'), findsOneWidget);
      final rows = <double>{
        tester.getTopLeft(find.text('Maya')).dy,
        tester.getTopLeft(find.text('Leo')).dy,
        tester.getTopLeft(find.text('Sam')).dy,
      };
      // `.kids` is a 2-up grid (170 + 170, gap 10): the third card wraps to a
      // second row instead of squeezing three cards into one row.
      expect(rows, hasLength(2));

      await disposeApp(tester);
    }, skip: true);

    testWidgets('[P08-B05] six children keep the 2-up grid with no overflow', (
      tester,
    ) async {
      final db = await setUpTestScope();
      final extras = <String>['Sam', 'Ada', 'Ines', 'Nia'];
      for (var i = 0; i < extras.length; i++) {
        final id = 'kid$i';
        await _insertChild(db, id, extras[i], 5 + i);
        await _insertQuest(db, 'q-$id', 'Quest $i', id);
      }

      await pumpAppRoute(tester, '/today');

      final rows = <double>{
        for (final name in <String>['Maya', 'Leo', ...extras])
          tester.getTopLeft(find.text(name)).dy,
      };
      expect(rows, hasLength(3), reason: '6 children = 3 rows of 2');
      expect(tester.takeException(), isNull, reason: 'no RenderFlex overflow');

      await disposeApp(tester);
    }, skip: true);

    testWidgets('[P08-B06] banner counts family-wide pending approvals', (
      tester,
    ) async {
      final db = await setUpTestScope();
      // A pending completion on an "Anyone" quest (q-living) is waiting in
      // P11 but is not assigned to a child, so today's items exclude it.
      await db
          .into(db.questCompletions)
          .insert(
            QuestCompletionsCompanion.insert(
              questId: 'q-living',
              childId: 'leo',
              familyId: Seed.familyId,
              status: const Value('done_pending'),
              coins: const Value(10),
              createdAt: Value(Seed.utc(10, 3, 9)),
            ),
          );

      await pumpAppRoute(tester, '/today');

      // Review opens /approvals, which lists 3 seeded + this one.
      expect(find.text('4 quests waiting for your thumbs-up'), findsOneWidget);
      await disposeApp(tester);
    }, skip: true);
  });

  group('P08 navigation', () {
    testWidgets('[P08-B07] system back from approvals returns to Today', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(currentPath(tester), '/approvals');

      final popped = await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(popped, isTrue, reason: 'the OS must not exit the app');
      expect(currentPath(tester), '/today');

      await disposeApp(tester);
    }, skip: true);
  });

  group('P08 resilience', () {
    testWidgets("[P08-B08] retry releases the failed load's watchers", (
      tester,
    ) async {
      final repo = _MockTodayRepository();
      var calls = 0;
      var cancels = 0;
      final first = StreamController<List<TodayItem>>(
        onCancel: () => cancels++,
      );
      final second = StreamController<List<TodayItem>>();
      addTearDown(first.close);
      addTearDown(second.close);
      when(repo.watchItems)
          .thenAnswer((_) => calls++ == 0 ? first.stream : second.stream);
      when(repo.watchSummaries)
          .thenAnswer((_) => Stream.value(const <ChildDaySummary>[]));
      when(repo.watchParentName).thenAnswer((_) => Stream.value('Sarah'));
      when(repo.watchPayoutDay).thenAnswer((_) => Stream.value(6));
      final bloc = TodayBloc(repository: repo)..add(const TodayLoadRequested());

      await _pumpTodayView(tester, bloc);
      await tester.pump();

      // The first load's stream errors but stays open (a real combined Drift
      // stream does not close on a single source error).
      first.addError(Exception('offline'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Try again'), findsOneWidget);

      // Rapid retry: the failed load must have released its watcher before
      // the new load starts, or every retry leaks a full set of watchers.
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();

      expect(calls, 2, reason: 'a retry starts a fresh subscription');
      expect(cancels, 1, reason: 'the failed load was cancelled on error');

      await disposeApp(tester);
    }, skip: true);
  });

  group('P08 layout fidelity', () {
    testWidgets('[P08-B09] a single child keeps the 2-up grid card width', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await (db.delete(
        db.questCompletions,
      )..where((c) => c.childId.equals('leo'))).go();
      await (db.delete(
        db.quests,
      )..where((q) => q.assigneeChildId.equals('leo'))).go();
      await (db.delete(db.children)..where((c) => c.id.equals('leo'))).go();

      await pumpAppRoute(tester, '/today');

      final card = find
          .ancestor(
            of: find.text('4 of 6 quests'),
            matching: find.byType(NestCard),
          )
          .first;
      // `.kids { grid-template-columns:170px 170px }`: one child occupies one
      // 170px column, not the full 350px content width.
      expect(tester.getSize(card).width, lessThanOrEqualTo(175));

      await disposeApp(tester);
    }, skip: true);

    test(
      '[P08-B10] quest rows are ordered pending-first like the design',
      () async {
        final db = await setUpTestScope();
        final impl = TodayRepositoryImpl(db: db);

        final items = await impl.getItems();
        final maya = items
            .where((i) => i.childId == 'maya')
            .map((i) => i.title)
            .toList();

        // Design order: done_pending → to_do → approved, title within each
        // rank (Maya's rows on P08: dishwasher, reading, bins …).
        expect(
          maya,
          orderedEquals(<String>[
            'Empty the dishwasher',
            'Lay the table',
            'Reading – 20 minutes',
            'Tidy your bedroom',
            'Hoover the stairs',
            'Put the bins out',
          ]),
        );
      },
      skip: 'P08-B10: rows() sorts alphabetically, scattering "Needs a look"',
    );
  });
}
