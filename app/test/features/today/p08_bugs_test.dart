// P08 · Today (home) — adversarial bug proofs (Stage 6, iteration 1 + 2 + 3).
//
// Iteration 1 found 11 bugs (P08-B01…B10); iteration 2 fixed all of them and
// un-skipped the proofs. Iteration 2's findings (P08-B11 periods, P08-B12
// double-tap push) and iteration 3's findings (P08-B13 banner scoping,
// P08-B14 push-guard latch) were fixed in the following iterations — every
// proof below runs unskipped and green.
//
// Iteration 4 re-hunted the tree and found no new bugs; no skips remain.
//
// Full reports with severity, repro and suggested fixes:
// `docs/screens/P08/6_bugs.md`.

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/quests/presentation/views/quest_editor_view.dart';
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
    });
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
    });

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
    });
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
    });

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

      // Half of the 350px content width minus the 10px gap.
      final samCard = find
          .ancestor(of: find.text('Sam'), matching: find.byType(NestCard))
          .first;
      expect(tester.getSize(samCard).width, closeTo(170, 1));

      await disposeApp(tester);
    });

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
    });

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
    });
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
      // The pushed page observes the new location (the shell branch still
      // reports `/today` via `currentConfiguration`), so read the URI from
      // the top-most rendered route via the shared `pushedPath` helper —
      // `GoRouter.state` is built from the full match list, so this asserts
      // both where we are AND what the Navigator renders. Never assert a
      // pushed screen's title text: screen agents replace placeholder views
      // (P11's `AppBar('P11 Approvals')` → `Waiting for you (N)`), paths are
      // the stable contract. See `_shared/router_push_test_fix_REPORT.md`.
      expect(pushedPath(tester), '/approvals');

      final popped = await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(popped, isTrue, reason: 'the OS must not exit the app');
      expect(currentPath(tester), '/today');

      await disposeApp(tester);
    });
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
      when(repo.watchPendingCount).thenAnswer((_) => Stream.value(0));
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
    });
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
    });

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
    );
  });

  group('P08 period scoping (mandatory orchestrator ruling)', () {
    test(
      '[P08-B11] a daily completion from the previous London day is to do',
      () async {
        final db = await setUpTestScope();
        final now = DateTime.now().toUtc();
        final stale = dayStartUtc(
          'Europe/London',
          now,
        ).subtract(const Duration(minutes: 1));
        await (db.delete(
          db.questCompletions,
        )..where((c) => c.questId.equals('q-reading'))).go();
        await db
            .into(db.questCompletions)
            .insert(
              QuestCompletionsCompanion.insert(
                questId: 'q-reading',
                childId: 'maya',
                familyId: Seed.familyId,
                status: const Value('approved'),
                coins: const Value(10),
                createdAt: Value(stale),
              ),
            );

        final impl = TodayRepositoryImpl(db: db);
        final items = await impl.getItems();

        expect(
          items.firstWhere((i) => i.questId == 'q-reading').status,
          'to_do',
          reason:
              "yesterday's daily completion is outside today's London day — "
              'the ruling says the quest is to do again',
        );
      },
    );

    test(
      '[P08-B11] a weekly completion from last week is to do again',
      () async {
        final db = await setUpTestScope();
        final now = DateTime.now().toUtc();
        final stale = weekStartUtc(
          'Europe/London',
          now,
        ).subtract(const Duration(minutes: 1));
        await (db.delete(
          db.questCompletions,
        )..where((c) => c.questId.equals('q-bins'))).go();
        await db
            .into(db.questCompletions)
            .insert(
              QuestCompletionsCompanion.insert(
                questId: 'q-bins',
                childId: 'maya',
                familyId: Seed.familyId,
                status: const Value('approved'),
                coins: const Value(15),
                createdAt: Value(stale),
              ),
            );

        final impl = TodayRepositoryImpl(db: db);
        final items = await impl.getItems();

        expect(
          items.firstWhere((i) => i.questId == 'q-bins').status,
          'to_do',
          reason: "last week's weekly completion is outside this London week",
        );
      },
    );

    testWidgets('[P08-B11] the kid card count excludes stale completions', (
      tester,
    ) async {
      final db = await setUpTestScope();
      final now = DateTime.now().toUtc();
      final stale = dayStartUtc(
        'Europe/London',
        now,
      ).subtract(const Duration(minutes: 1));
      await (db.delete(
        db.questCompletions,
      )..where((c) => c.questId.equals('q-reading'))).go();
      await db
          .into(db.questCompletions)
          .insert(
            QuestCompletionsCompanion.insert(
              questId: 'q-reading',
              childId: 'maya',
              familyId: Seed.familyId,
              status: const Value('approved'),
              coins: const Value(10),
              createdAt: Value(stale),
            ),
          );

      await pumpAppRoute(tester, '/today');

      // Maya's "done" count must not include yesterday's daily quest.
      expect(find.text('4 of 6 quests'), findsOneWidget);
      expect(find.text('5 of 6 quests'), findsNothing);

      await disposeApp(tester);
    });

    test('[P08-B11] a "once" completion from years ago still counts', () async {
      final db = await setUpTestScope();
      await db
          .into(db.quests)
          .insert(
            QuestsCompanion.insert(
              id: 'q-once',
              familyId: Seed.familyId,
              title: 'Return the library book',
              coins: const Value(5),
              repeatRule: const Value('once'),
              assigneeChildId: const Value('maya'),
            ),
          );
      await db
          .into(db.questCompletions)
          .insert(
            QuestCompletionsCompanion.insert(
              questId: 'q-once',
              childId: 'maya',
              familyId: Seed.familyId,
              status: const Value('approved'),
              coins: const Value(5),
              createdAt: Value(DateTime.utc(2020)),
            ),
          );

      final impl = TodayRepositoryImpl(db: db);
      final items = await impl.getItems();

      // `once` → forever: the ruling must not reset this one (pin).
      expect(items.firstWhere((i) => i.questId == 'q-once').status, 'approved');
    });
  });

  group('P08 rapid taps', () {
    testWidgets('[P08-B12] a rapid double-tap opens one quest editor', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      // Two taps before the first frame rebuilds: without a guard each tap
      // runs `push('/quest-editor?questId=…')`.
      await tester.tap(find.text('Empty the dishwasher'));
      await tester.tap(find.text('Empty the dishwasher'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Assert the route (durable contract) via the shared `pushedPath`
      // helper — same as the /approvals assertion — plus the view type.
      // Never assert a pushed screen's placeholder title text.
      expect(pushedPath(tester), '/quest-editor');
      expect(
        find.byType(QuestEditorView, skipOffstage: false),
        findsOneWidget,
        reason: 'a double-tap must not stack two editor pages',
      );

      final popped = await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(popped, isTrue);
      expect(find.text("Today's quests", skipOffstage: false), findsOneWidget);

      await disposeApp(tester);
    });
  });

  group('P08 Pip under Reduce Motion (regression pin, shared art)', () {
    // M1 (4_review iteration 2): Bolt/Storybook fallbacks were dashed
    // placeholders, so Reduce Motion showed an outline for Leo. Fixed on main
    // (`f6b02d8`, approved art per style) — this pins the screen outcome.
    testWidgets("Leo's Pip renders real art, not the placeholder", (
      tester,
    ) async {
      await setUpTestScope();
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpAppRoute(tester, '/today');

      String? pipAssetFor(String nickname) {
        final card = find
            .ancestor(of: find.text(nickname), matching: find.byType(NestCard))
            .first;
        final svgs = tester.widgetList<SvgPicture>(
          find.descendant(of: card, matching: find.byType(SvgPicture)),
        );
        for (final svg in svgs) {
          final loader = svg.bytesLoader;
          if (loader is SvgAssetLoader && loader.assetName.contains('pip_v2')) {
            return loader.assetName;
          }
        }
        return null;
      }

      expect(pipAssetFor('Maya'), isNotNull);
      expect(pipAssetFor('Maya'), isNot(contains('placeholder')));
      expect(pipAssetFor('Leo'), isNotNull);
      expect(
        pipAssetFor('Leo'),
        isNot(contains('placeholder')),
        reason: 'Reduce Motion must not draw the dashed placeholder outline',
      );

      await disposeApp(tester);
    });
  });

  group('P08 approvals banner vs the periods ruling', () {
    test(
      '[P08-B13] a stale pending completion does not count in the banner total',
      () async {
        final db = await setUpTestScope();
        // Derive the stale instant from the pinned story clock (repo default
        // clock is `Seed.anchorOverride`) instead of duplicating a literal.
        final pin = Seed.anchorOverride ?? DateTime.now().toUtc();
        final stale = dayStartUtc(
          'Europe/London',
          pin,
        ).subtract(const Duration(minutes: 30));
        await (db.delete(
          db.questCompletions,
        )..where((c) => c.questId.equals('q-reading'))).go();
        await db
            .into(db.questCompletions)
            .insert(
              QuestCompletionsCompanion.insert(
                questId: 'q-reading',
                childId: 'maya',
                familyId: Seed.familyId,
                status: const Value('done_pending'),
                coins: const Value(10),
                createdAt: Value(stale),
              ),
            );

        final impl = TodayRepositoryImpl(db: db);

        // The row correctly resets to "to do" (period expired)…
        expect(
          (await impl.getItems())
              .firstWhere((i) => i.questId == 'q-reading')
              .status,
          'to_do',
        );
        // …so the banner total must not keep counting it: the 3 seeded
        // current-period pendings remain.
        expect(
          await impl.watchPendingCount().first,
          3,
          reason:
              'counting the stale pending makes the banner say 4 above a '
              'list with 3 "Needs a look" rows',
        );
      },
    );

    testWidgets('[P08-B13] the banner count matches the current-period rows', (
      tester,
    ) async {
      final db = await setUpTestScope();
      final pin = Seed.anchorOverride ?? DateTime.now().toUtc();
      final stale = dayStartUtc(
        'Europe/London',
        pin,
      ).subtract(const Duration(minutes: 30));
      await (db.delete(
        db.questCompletions,
      )..where((c) => c.questId.equals('q-reading'))).go();
      await db
          .into(db.questCompletions)
          .insert(
            QuestCompletionsCompanion.insert(
              questId: 'q-reading',
              childId: 'maya',
              familyId: Seed.familyId,
              status: const Value('done_pending'),
              coins: const Value(10),
              createdAt: Value(stale),
            ),
          );

      await pumpAppRoute(tester, '/today');

      expect(find.text('3 quests waiting for your thumbs-up'), findsOneWidget);
      expect(find.text('4 quests waiting for your thumbs-up'), findsNothing);

      await disposeApp(tester);
    });
  });

  group('P08 push guard robustness', () {
    testWidgets('[P08-B14] a pushed page navigating with go() unlatches it', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      await tester.tap(find.bySemanticsLabel('New quest'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(pushedPath(tester), '/quest-editor');

      // The pushed page navigates home with `go` (P09/P11 may; §4 asks them
      // to pop, but the guard must not depend on another screen's contract).
      // Use the same Navigator lookup as the shared `pushedPath` helper.
      GoRouter.of(
        tester.element(find.byType(Navigator).first),
      ).go('/today');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));

      // The guard must have released: New quest works again.
      await tester.tap(find.bySemanticsLabel('New quest'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(pushedPath(tester), '/quest-editor');
      expect(
        find.byType(QuestEditorView, skipOffstage: false),
        findsOneWidget,
        reason: 'the pushed page is gone, so the button must not stay latched',
      );

      await disposeApp(tester);
    });
  });
}
