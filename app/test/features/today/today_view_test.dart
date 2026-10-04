import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/today/domain/entities/child_day_summary.dart';
import 'package:nestling/features/today/domain/entities/today_item.dart';
import 'package:nestling/features/today/domain/today_repository.dart';
import 'package:nestling/features/today/presentation/bloc/today_bloc.dart';
import 'package:nestling/features/today/presentation/bloc/today_event.dart';
import 'package:nestling/features/today/presentation/views/today_view.dart';
import 'package:nestling/features/today/presentation/widgets/today_loaded_body.dart';

import '../../test_scope.dart';

class _MockTodayRepository extends Mock implements TodayRepository;

/// One pending quest / one child: drives the loading + failure state tests
/// (a healthy Drift database can never produce those states).
const _mockItems = <TodayItem>[
  TodayItem(
    id: 'q-dishwasher:maya',
    title: 'Empty the dishwasher',
    questId: 'q-dishwasher',
    childId: 'maya',
    childName: 'Maya',
    status: 'done_pending',
    coins: 15,
    repeatRule: 'weekly',
    iconKey: 'dishwasher',
  ),
];

const _mockSummaries = <ChildDaySummary>[
  ChildDaySummary(
    childId: 'maya',
    nickname: 'Maya',
    avatarColour: 'lilac',
    pipStage: 3,
    done: 1,
    total: 1,
    coins: 120,
    ageYears: 9,
    happyDays: 4,
  ),
];

String _expectedGreeting() {
  final london = toFamilyZone(appNowUtc(), 'Europe/London');
  return '${dayPartForHour(london.hour)}, Sarah';
}

String _expectedDateLine(int happyDays) {
  final day = happyDays == 1 ? 'day' : 'days';
  return '${formatDay(appNowUtc(), 'Europe/London')} · Happy week: $happyDays $day';
}

/// Pumps [TodayView] directly (no router, no shell) over [bloc].
Future<void> _pumpTodayView(
  WidgetTester tester,
  TodayBloc bloc, {
  ThemeMode theme = ThemeMode.light,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      themeMode: theme,
      home: BlocProvider<TodayBloc>.value(
        value: bloc,
        child: const TodayView(),
      ),
    ),
  );
  await tester.pump();
}

/// Current go_router location for a widget already on screen after a tap.
Uri _currentUri(WidgetTester tester, Finder anchor) =>
    GoRouter.of(tester.element(anchor)).state.uri;

/// Resizes the test surface and applies a text scale, then settles a frame.
Future<void> _resize(WidgetTester tester, double width, double scale) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Extra child row for the 3+ and 1-child copy cases.
Future<void> _insertChild(
  AppDatabase db,
  String id,
  String nickname,
  int age, {
  String pipStyle = 'mochi',
  String pipSkin = 'sunny',
  String pipAccessory = 'none',
  int pipStage = 1,
}) async {
  await db
      .into(db.children)
      .insert(
        ChildrenCompanion.insert(
          id: id,
          familyId: Seed.familyId,
          nickname: nickname,
          ageYears: Value(age),
          avatarColour: const Value('sky'),
          pipStyle: Value(pipStyle),
          pipSkin: Value(pipSkin),
          pipAccessory: Value(pipAccessory),
          pipStage: Value(pipStage),
        ),
      );
}

/// Removes a seeded child with its quests and completions.
Future<void> _removeChild(AppDatabase db, String id) async {
  await (db.delete(
    db.questCompletions,
  )..where((c) => c.childId.equals(id))).go();
  await (db.delete(db.quests)..where((q) => q.assigneeChildId.equals(id))).go();
  await (db.delete(db.children)..where((c) => c.id.equals(id))).go();
}

/// Any [SvgPicture] drawing an asset whose path contains [needle].
Finder _svgAssetContaining(String needle) => find.byWidgetPredicate((w) {
  if (w is! SvgPicture) return false;
  final loader = w.bytesLoader;
  return loader is SvgAssetLoader && loader.assetName.contains(needle);
});

/// Minimal summary for the pure copy-helper tests.
ChildDaySummary _kidNamed(String name) => ChildDaySummary(
  childId: name.toLowerCase(),
  nickname: name,
  avatarColour: 'lilac',
  pipStage: 2,
  done: 0,
  total: 1,
  coins: 10,
);

void main() {
  group('P08 Today (light, demo seed)', () {
    testWidgets('shows greeting, banner, kids, groups and hand-off', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      expect(find.text(_expectedGreeting()), findsOneWidget);
      expect(find.text(_expectedDateLine(4)), findsOneWidget);
      expect(find.text('3 quests waiting for your thumbs-up'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);

      expect(find.text('Maya'), findsWidgets);
      expect(find.text('Leo'), findsWidgets);
      expect(find.text('4 of 6 quests'), findsOneWidget);
      expect(find.text('2 of 4 quests'), findsOneWidget);
      expect(find.text('120'), findsWidgets);
      expect(find.text('45'), findsWidgets);

      expect(find.text("Today's quests"), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);
      expect(find.text('MAYA · 9'), findsOneWidget);

      // Maya's rows are pending-first, then α; scroll through them in order.
      final list = find.byType(Scrollable).first;
      for (final title in <String>[
        'Empty the dishwasher',
        'Lay the table',
        'Reading – 20 minutes',
        'Tidy your bedroom',
        'Hoover the stairs',
        'Put the bins out',
        'LEO · 6',
        'Make your bed',
        'Feed Biscuit the cat',
        'Hand to Maya or Leo',
      ]) {
        await tester.scrollUntilVisible(
          find.text(title),
          300,
          scrollable: list,
        );
        await tester.pump();
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text('Needs a look'), findsWidgets);
      expect(find.text('Approved ✓'), findsWidgets);

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('Review opens approvals', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // Assert the location, not a placeholder view title: P11 replaced its
      // foundation `AppBar('P11 Approvals')` with the real screen
      // (`Waiting for you (N)`). `pushedPath` reads `GoRouter.state`, which is
      // built from the full match list and therefore reflects exactly what the
      // Navigator renders. See `_shared/router_push_test_fix_REPORT.md`.
      expect(pushedPath(tester), '/approvals');

      await disposeApp(tester);
    });

    testWidgets('plus opens the quest editor without a questId', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      await tester.tap(find.bySemanticsLabel('New quest'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('P09 Quest editor'), findsOneWidget);
      final uri = _currentUri(tester, find.text('P09 Quest editor'));
      expect(uri.path, '/quest-editor');
      expect(uri.queryParameters.containsKey('questId'), isFalse);

      await disposeApp(tester);
    });

    testWidgets('quest row opens the editor with its questId', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      await tester.tap(find.text('Empty the dishwasher'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('P09 Quest editor'), findsOneWidget);
      final uri = _currentUri(tester, find.text('P09 Quest editor'));
      expect(uri.path, '/quest-editor');
      expect(uri.queryParameters['questId'], 'q-dishwasher');

      await disposeApp(tester);
    });

    testWidgets('hand-off button opens who-is-playing', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      final list = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Hand to Maya or Leo'),
        300,
        scrollable: list,
      );
      await tester.pump();
      await tester.tap(find.text('Hand to Maya or Leo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('K01 Who is playing'), findsOneWidget);
      expect(
        _currentUri(tester, find.text('K01 Who is playing')).path,
        '/who-is-playing',
      );

      await disposeApp(tester);
    });

    testWidgets('See all opens the quest library', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      await tester.tap(find.text('See all'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // Route-path assertion only: P10 owns the library view and its copy.
      expect(pushedPath(tester), '/quests');

      await disposeApp(tester);
    });
  });

  group('P08 Today (dark)', () {
    testWidgets('same content renders in dark mode', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today', theme: ThemeMode.dark);

      expect(find.text(_expectedGreeting()), findsOneWidget);
      expect(find.text('3 quests waiting for your thumbs-up'), findsOneWidget);
      expect(find.text('Maya'), findsWidgets);
      expect(find.text('Empty the dishwasher'), findsOneWidget);

      final list = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Hand to Maya or Leo'),
        300,
        scrollable: list,
      );
      await tester.pump();
      expect(find.text('Hand to Maya or Leo'), findsOneWidget);

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('P08b Today empty', () {
    testWidgets('quiet nest card with two actions', (tester) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/today');

      expect(find.text('Your nest is quiet'), findsOneWidget);
      expect(find.text('Add a quest'), findsOneWidget);
      expect(find.text('Browse ideas'), findsOneWidget);
      expect(find.text('Review'), findsNothing);

      await tester.tap(find.text('Browse ideas'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // Route-path assertion only: P10 owns the library view and its copy.
      expect(pushedPath(tester), '/quests');

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('/today-empty route shows the quiet-nest card', (tester) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/today-empty');

      expect(find.text('Your nest is quiet'), findsOneWidget);
      expect(
        find.text('Add your first quest and Pip will start to hatch.'),
        findsOneWidget,
      );
      expect(find.text('Add a quest'), findsOneWidget);
      expect(find.text('Hand to Maya or Leo'), findsNothing);
      expect(find.text('Review'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Add a quest'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('P09 Quest editor'), findsOneWidget);
      expect(
        _currentUri(tester, find.text('P09 Quest editor')).path,
        '/quest-editor',
      );

      await disposeApp(tester);
    });
  });

  group('P08 sizes', () {
    testWidgets('no overflow at 320 wide + text scale 1.3; taps >= 44', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      Size ancestorSize(Finder inner, Type ancestor) {
        final found = find
            .ancestor(of: inner, matching: find.byType(ancestor))
            .first;
        return tester.getSize(found);
      }

      expect(
        ancestorSize(find.bySemanticsLabel('New quest'), SizedBox).height,
        greaterThanOrEqualTo(44),
      );
      expect(
        ancestorSize(find.text('Review'), GestureDetector).height,
        greaterThanOrEqualTo(44),
      );
      expect(
        ancestorSize(find.text('See all'), InkWell).height,
        greaterThanOrEqualTo(44),
      );

      // Scroll through every row (in render order) so each lays out under
      // the constraints.
      final list = find.byType(Scrollable).first;
      for (final title in <String>[
        'Reading – 20 minutes',
        'Put the bins out',
        'LEO · 6',
        'Feed Biscuit the cat',
        'Hand to Maya or Leo',
      ]) {
        await tester.scrollUntilVisible(
          find.text(title),
          300,
          scrollable: list,
        );
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      expect(
        ancestorSize(find.text('Hand to Maya or Leo'), GestureDetector).height,
        greaterThanOrEqualTo(44),
      );

      await disposeApp(tester);
    });
  });

  group('P08 Today states', () {
    testWidgets('loading shows the spinner', (tester) async {
      final repo = _MockTodayRepository();
      when(repo.watchItems)
          .thenAnswer((_) => const Stream<List<TodayItem>>.empty());
      when(repo.watchSummaries)
          .thenAnswer((_) => const Stream<List<ChildDaySummary>>.empty());
      when(repo.watchParentName)
          .thenAnswer((_) => const Stream<String>.empty());
      when(repo.watchPayoutDay).thenAnswer((_) => const Stream<int>.empty());
      when(repo.watchPendingCount).thenAnswer((_) => Stream.value(0));
      // No `bloc.close()` here (nor below): TodayBloc's `emit.forEach` holds
      // the long-lived repository streams open — as in the app — so the close
      // future only resolves when a source ends. The unreferenced bloc is
      // collected with the test.
      final bloc = TodayBloc(repository: repo)..add(const TodayLoadRequested());

      await _pumpTodayView(tester, bloc);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text("Today's quests"), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failure shows the reason and Try again recovers', (
      tester,
    ) async {
      final repo = _MockTodayRepository();
      var attempts = 0;
      when(repo.watchItems).thenAnswer((_) {
        attempts++;
        return attempts == 1
            ? Stream<List<TodayItem>>.error(Exception('offline'))
            : Stream.value(_mockItems);
      });
      when(repo.watchSummaries).thenAnswer((_) => Stream.value(_mockSummaries));
      when(repo.watchParentName).thenAnswer((_) => Stream.value('Sarah'));
      when(repo.watchPayoutDay).thenAnswer((_) => Stream.value(6));
      when(repo.watchPendingCount).thenAnswer((_) => Stream.value(0));
      final bloc = TodayBloc(repository: repo)..add(const TodayLoadRequested());

      await _pumpTodayView(tester, bloc);
      await tester.pump();

      expect(
        find.text(
          "We couldn't load today's quests. Your data is safe — please try again.",
        ),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();

      expect(find.text("Today's quests"), findsOneWidget);
      expect(find.text('Empty the dishwasher'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failure renders in dark theme too', (tester) async {
      final repo = _MockTodayRepository();
      when(
        repo.watchItems,
      ).thenAnswer((_) => Stream<List<TodayItem>>.error(Exception('offline')));
      when(repo.watchSummaries).thenAnswer((_) => Stream.value(_mockSummaries));
      when(repo.watchParentName).thenAnswer((_) => Stream.value('Sarah'));
      when(repo.watchPayoutDay).thenAnswer((_) => Stream.value(6));
      when(repo.watchPendingCount).thenAnswer((_) => Stream.value(0));
      final bloc = TodayBloc(repository: repo)..add(const TodayLoadRequested());

      await _pumpTodayView(tester, bloc, theme: ThemeMode.dark);
      await tester.pump();

      expect(
        find.text(
          "We couldn't load today's quests. Your data is safe — please try again.",
        ),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('P08 Today navigation', () {
    testWidgets('avatar opens settings', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      await tester.tap(find.bySemanticsLabel("Sarah's profile"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Assert the location, not a placeholder view title: P16 replaced its
      // foundation `AppBar('P16 Settings')` with the real screen
      // (`Family & settings`). `pushedPath` reads `GoRouter.state`, which is
      // built from the full match list and therefore reflects exactly what the
      // Navigator renders. See `_shared/router_push_test_fix_REPORT.md`.
      expect(pushedPath(tester), '/settings');

      await disposeApp(tester);
    });

    testWidgets('kid card opens the child profile with its childId', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      await tester.tap(find.text('4 of 6 quests'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // P15 is a real screen now, so anchor on its hero card instead of the
      // old placeholder title (same anchor add_children_test.dart uses).
      expect(find.byKey(const Key('p15-hero')), findsOneWidget);
      final uri = _currentUri(tester, find.byKey(const Key('p15-hero')));
      expect(uri.path, '/child-profile');
      expect(uri.queryParameters['childId'], 'maya');

      await disposeApp(tester);
    });
  });

  group('P08 Today live data', () {
    testWidgets('approving every pending quest hides the banner', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await pumpAppRoute(tester, '/today');
      expect(find.text('Review'), findsOneWidget);

      await (db.update(db.questCompletions)
            ..where((c) => c.status.equals('done_pending')))
          .write(const QuestCompletionsCompanion(status: Value('approved')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Review'), findsNothing);
      expect(find.text('3 quests waiting for your thumbs-up'), findsNothing);
      expect(find.text("Today's quests"), findsOneWidget);
      expect(find.text('Empty the dishwasher'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P08 Today accessibility', () {
    testWidgets('icon buttons, cards and rows expose semantics labels', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      // Interactive labels surface on their own semantics nodes.
      expect(find.bySemanticsLabel('New quest'), findsOneWidget);
      expect(find.bySemanticsLabel("Sarah's profile"), findsOneWidget);

      // The rest merge with sibling text (a Row / card merges its children),
      // so match the declared label inside the combined node label.
      expect(find.bySemanticsLabel(RegExp('See all quests')), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp('Maya, 4 of 6 quests, 120 coins')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          RegExp('Empty the dishwasher, 15 coins, Needs a look'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('3 quests waiting for your thumbs-up')),
        findsWidgets,
      );

      // Pip art and progress bars declare their labels (they merge into the
      // kid card's node, so assert the declarations).
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics && w.properties.label == "Maya's Pip, a fledgling",
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics && w.properties.label == "Maya's quest progress",
        ),
        findsOneWidget,
      );

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('parent tap targets are at least 44 high', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      expect(
        tester.getSize(find.byType(NestIconButton)).height,
        greaterThanOrEqualTo(44),
      );

      final avatar = find
          .ancestor(
            of: find.bySemanticsLabel("Sarah's profile"),
            matching: find.byType(InkWell),
          )
          .first;
      expect(tester.getSize(avatar).height, greaterThanOrEqualTo(44));

      final review = find
          .ancestor(of: find.text('Review'), matching: find.byType(NestButton))
          .first;
      expect(tester.getSize(review).height, greaterThanOrEqualTo(44));

      final seeAll = find
          .ancestor(of: find.text('See all'), matching: find.byType(InkWell))
          .first;
      expect(tester.getSize(seeAll).height, greaterThanOrEqualTo(44));

      final row = find
          .ancestor(
            of: find.text('Empty the dishwasher'),
            matching: find.byType(NestQuestCard),
          )
          .first;
      expect(tester.getSize(row).height, greaterThanOrEqualTo(56));

      await tester.scrollUntilVisible(
        find.text('Hand to Maya or Leo'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      final hand = find
          .ancestor(
            of: find.text('Hand to Maya or Leo'),
            matching: find.byType(NestButton),
          )
          .first;
      expect(tester.getSize(hand).height, greaterThanOrEqualTo(44));

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('P08 Today copy', () {
    testWidgets('one pending approval reads "1 quest" (singular)', (
      tester,
    ) async {
      final db = await setUpTestScope();
      final pending = await (db.select(
        db.questCompletions,
      )..where((c) => c.status.equals('done_pending'))).get();
      expect(pending, hasLength(3));
      for (final row in pending.skip(1)) {
        await (db.update(db.questCompletions)
              ..where((c) => c.id.equals(row.id)))
            .write(const QuestCompletionsCompanion(status: Value('approved')));
      }

      await pumpAppRoute(tester, '/today');

      final banner = find.textContaining('waiting for your thumbs-up');
      expect(banner, findsOneWidget);
      expect(
        tester.widget<Text>(banner).data,
        '1 quest waiting for your thumbs-up',
      );

      await disposeApp(tester);
    });

    testWidgets('banner subtitle names the children', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      // Design: "Maya and Leo did brilliantly yesterday".
      final subtitle = find.textContaining('did brilliantly');
      expect(subtitle, findsOneWidget);
      expect(
        tester.widget<Text>(subtitle).data,
        'Maya and Leo did brilliantly yesterday',
      );

      await disposeApp(tester);
    });
  });

  group('P08 Today copy helpers', () {
    test('pending label pluralises', () {
      expect(todayPendingLabel(0), '0 quests waiting for your thumbs-up');
      expect(todayPendingLabel(1), '1 quest waiting for your thumbs-up');
      expect(todayPendingLabel(3), '3 quests waiting for your thumbs-up');
    });

    test('banner subtitle names 0 / 1 / 2 / 3+ children', () {
      expect(
        todayBannerSubtitle(const <ChildDaySummary>[]),
        'Your nestlings did brilliantly yesterday',
      );
      expect(
        todayBannerSubtitle([_kidNamed('Maya')]),
        'Maya did brilliantly yesterday',
      );
      expect(
        todayBannerSubtitle([_kidNamed('Maya'), _kidNamed('Leo')]),
        'Maya and Leo did brilliantly yesterday',
      );
      expect(
        todayBannerSubtitle([
          _kidNamed('Maya'),
          _kidNamed('Leo'),
          _kidNamed('Sam'),
        ]),
        'Maya, Leo and Sam did brilliantly yesterday',
      );
    });

    test('Pip mappers cover every DB token and fall back safely', () {
      expect(pipStyleFor('mochi'), PipStyle.mochi);
      expect(pipStyleFor('bolt'), PipStyle.bolt);
      expect(pipStyleFor('storybook'), PipStyle.storybook);
      expect(pipStyleFor('v1-legacy'), PipStyle.mochi);

      expect(pipSkinFor('sunny'), PipSkin.sunny);
      expect(pipSkinFor('berry'), PipSkin.berry);
      expect(pipSkinFor('sky'), PipSkin.sky);
      expect(pipSkinFor('mint'), PipSkin.mint);
      expect(pipSkinFor('plum'), PipSkin.sunny);

      expect(pipAccessoryFor('none'), PipAccessory.none);
      expect(pipAccessoryFor('bow'), PipAccessory.bow);
      expect(pipAccessoryFor('cap'), PipAccessory.cap);
      expect(pipAccessoryFor('scarf'), PipAccessory.scarf);
      expect(pipAccessoryFor('glasses'), PipAccessory.glasses);
      expect(pipAccessoryFor('hat'), PipAccessory.none);
    });
  });

  group('P08 Today Pip artwork (orchestrator rule)', () {
    testWidgets("kid cards use each child's PipAvatar, never a v1 SVG", (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      final pips = tester
          .widgetList<PipAvatar>(find.byType(PipAvatar))
          .toList();
      expect(pips, hasLength(2));
      expect(pips.first.style, PipStyle.mochi);
      expect(pips.first.skin, PipSkin.sunny);
      expect(pips.first.stage, 3);
      expect(pips.last.style, PipStyle.bolt);
      expect(pips.last.skin, PipSkin.sky);
      expect(pips.last.stage, 2);

      // The rule forbids the v1 `pip_stage_*.svg` illustrations; whatever
      // art does load (Rive, or PipAvatar's own SVG fallback) is v2.
      expect(_svgAssetContaining('pip_stage'), findsNothing);
      final assets = tester
          .widgetList<SvgPicture>(find.byType(SvgPicture))
          .where((w) => w.bytesLoader is SvgAssetLoader)
          .map((w) => (w.bytesLoader as SvgAssetLoader).assetName)
          .toList();
      for (final asset in assets) {
        if (asset.contains('pip')) {
          expect(asset, contains('pip_v2'));
        }
      }

      // Both slots keep the design's 72px size.
      expect(tester.getSize(find.byType(PipAvatar).first), const Size(72, 72));
      expect(tester.getSize(find.byType(PipAvatar).last), const Size(72, 72));

      await disposeApp(tester);
    });

    testWidgets('P08b empty card uses PipAvatar(mochi, stage 1) at 140', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/today-empty');

      expect(_svgAssetContaining('pip_stage'), findsNothing);
      final pips = tester
          .widgetList<PipAvatar>(find.byType(PipAvatar))
          .toList();
      expect(pips, hasLength(1));
      expect(pips.single.style, PipStyle.mochi);
      expect(pips.single.stage, 1);
      expect(tester.getSize(find.byType(PipAvatar)), const Size(140, 140));

      await disposeApp(tester);
    });

    testWidgets('non-default Pip fields travel from the DB to the card', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await _insertChild(
        db,
        'ava',
        'Ava',
        4,
        pipStyle: 'storybook',
        pipSkin: 'mint',
        pipAccessory: 'scarf',
        pipStage: 4,
      );
      await pumpAppRoute(tester, '/today');

      final pips = tester
          .widgetList<PipAvatar>(find.byType(PipAvatar))
          .toList();
      expect(pips, hasLength(3));
      // Eldest first: Maya, Leo, then Ava.
      final ava = pips.last;
      expect(ava.style, PipStyle.storybook);
      expect(ava.skin, PipSkin.mint);
      expect(ava.accessory, PipAccessory.scarf);
      expect(ava.stage, 4);

      await disposeApp(tester);
    });
  });

  group('P08 Today family-size copy', () {
    testWidgets('three children: banner and hand-off name all of them', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await _insertChild(db, 'sam', 'Sam', 5);
      await pumpAppRoute(tester, '/today');

      expect(
        find.text('Maya, Leo and Sam did brilliantly yesterday'),
        findsOneWidget,
      );

      // The 2-up grid survives a third child: Sam's card keeps the 170 px
      // column instead of squeezing three cards into one row. (Measured
      // before scrolling past it to the hand-off button.)
      await tester.scrollUntilVisible(
        find.text('Sam'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(
        tester.getSize(find.byType(NestCard).at(2)).width,
        closeTo(170, 5),
      );

      await tester.scrollUntilVisible(
        find.textContaining('Hand to'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(find.text('Hand to Maya and 2 others'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('one child: banner and hand-off use the one name', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await _removeChild(db, 'leo');
      await pumpAppRoute(tester, '/today');

      expect(find.text('Maya did brilliantly yesterday'), findsOneWidget);
      expect(find.text('2 quests waiting for your thumbs-up'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Hand to Maya'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(find.text('Hand to Maya'), findsOneWidget);

      await disposeApp(tester);
    });
  });

  group('P08 Today a11y regressions', () {
    testWidgets('the banner announces its copy exactly once', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      final banner = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      );
      expect(banner, findsOneWidget);
      final label = tester.getSemantics(banner).getSemanticsData().label;
      expect('waiting for your thumbs-up'.allMatches(label), hasLength(1));
      expect(label, contains('3 quests waiting for your thumbs-up'));
      expect(label, contains('Maya and Leo did brilliantly yesterday'));

      await disposeApp(tester);
    });
  });

  group('P08 Today navigation (push)', () {
    testWidgets('system back from the quest editor returns to Today', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      await tester.tap(find.text('Empty the dishwasher'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('P09 Quest editor'), findsOneWidget);
      expect(
        _currentUri(
          tester,
          find.text('P09 Quest editor'),
        ).queryParameters['questId'],
        'q-dishwasher',
      );

      final popped = await tester.binding.handlePopRoute();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(popped, isTrue, reason: 'the OS must not exit the app');
      expect(find.text("Today's quests"), findsOneWidget);

      await disposeApp(tester);
    });
  });

  group('P08 Today stress', () {
    testWidgets('six children at 320 px + 1.3x, long names, no overflow', (
      tester,
    ) async {
      final db = await setUpTestScope();
      final extras = <String>['Sam', 'Ada', 'Maximilian-Alexander', 'Nia'];
      for (var i = 0; i < extras.length; i++) {
        final id = 'kid$i';
        await _insertChild(db, id, extras[i], 5 + i, pipStage: 2);
        await db
            .into(db.quests)
            .insert(
              QuestsCompanion.insert(
                id: 'q-$id',
                familyId: Seed.familyId,
                title: 'Maximilian-Alexander tidies the whole bedroom $i',
                coins: const Value(9999),
                assigneeChildId: Value(id),
              ),
            );
      }
      await pumpAppRoute(tester, '/today');
      await _resize(tester, 320, 1.3);

      await tester.scrollUntilVisible(
        find.text('Hand to Maya and 5 others'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(find.text('Hand to Maya and 5 others'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P08 Today alignment (owner rule)', () {
    testWidgets('content shares the 20 px gutters at 390 px', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      const left = 20.0;
      const right = 370.0;

      // Greeting text is inset by the page gutter; the avatar is flush with
      // the right gutter and the + button sits 8 px + 44 px to its left.
      expect(tester.getTopLeft(find.text(_expectedGreeting())).dx, left);
      final avatar = find
          .ancestor(
            of: find.bySemanticsLabel("Sarah's profile"),
            matching: find.byType(InkWell),
          )
          .first;
      expect(tester.getTopRight(avatar).dx, right);
      expect(tester.getTopRight(find.byType(NestIconButton)).dx, right - 52);

      // Banner (live-region wrapper = banner bounds) spans the column.
      final banner = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.liveRegion == true,
      );
      expect(tester.getTopLeft(banner).dx, left);
      expect(tester.getTopRight(banner).dx, right);

      // Kid cards: 2-up grid flush to both gutters.
      final mayaCard = find
          .ancestor(of: find.text('Maya'), matching: find.byType(NestCard))
          .first;
      final leoCard = find
          .ancestor(of: find.text('Leo'), matching: find.byType(NestCard))
          .first;
      expect(tester.getTopLeft(mayaCard).dx, left);
      expect(tester.getTopRight(leoCard).dx, right);

      // Section header and its link.
      expect(tester.getTopLeft(find.text("Today's quests")).dx, left);
      final seeAll = find
          .ancestor(of: find.text('See all'), matching: find.byType(InkWell))
          .first;
      expect(tester.getTopRight(seeAll).dx, right);

      // Quest row and hand-off button.
      final row = find
          .ancestor(
            of: find.text('Empty the dishwasher'),
            matching: find.byType(NestQuestCard),
          )
          .first;
      expect(tester.getTopLeft(row).dx, left);
      expect(tester.getTopRight(row).dx, right);

      await tester.scrollUntilVisible(
        find.text('Hand to Maya or Leo'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      final hand = find
          .ancestor(
            of: find.text('Hand to Maya or Leo'),
            matching: find.byType(NestButton),
          )
          .first;
      expect(tester.getTopLeft(hand).dx, left);
      expect(tester.getTopRight(hand).dx, right);

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the empty-state card shares the same gutters', (tester) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/today-empty');

      final card = find
          .ancestor(
            of: find.text('Your nest is quiet'),
            matching: find.byType(NestCard),
          )
          .first;
      expect(tester.getTopLeft(card).dx, 20);
      expect(tester.getTopRight(card).dx, 370);
      expect(
        tester.getTopLeft(find.text(_expectedGreeting())).dx,
        20,
        reason: 'the empty screen keeps the same 20 px gutter',
      );

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('P08 Today bottom edge (owner rule)', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: the tab bar surface reaches the edge', (
        tester,
      ) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/today', theme: theme);

        final screenBottom =
            tester.view.physicalSize.height / tester.view.devicePixelRatio;
        final screenRight =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;

        final bar = find.byType(NestTabBar);
        expect(bar, findsOneWidget);
        final rect = tester.getRect(bar);
        expect(
          rect.bottom,
          screenBottom,
          reason: 'no strip below the bar down to the physical edge',
        );
        expect(rect.left, 0);
        expect(rect.right, screenRight);
        expect(rect.height, NestDevice.tabH);

        final container = tester.widget<Container>(
          find.descendant(of: bar, matching: find.byType(Container)).first,
        );
        final decoration = container.decoration! as BoxDecoration;
        final expected = theme == ThemeMode.light
            ? NestColors.light.surface
            : NestColors.dark.surface;
        expect(
          decoration.color,
          expected,
          reason: 'the home-indicator area keeps the tab bar surface colour',
        );

        await disposeApp(tester);
      });
    }
  });

  group('P08 Today period scoping in the view', () {
    testWidgets('a stale daily completion renders as To do', (tester) async {
      final db = await setUpTestScope();
      // Story day is pinned to Sat 3 Oct 2026; 2 Oct 22:30 UTC is
      // 23:30 London — yesterday's London day, so the quest is to do again.
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
              createdAt: Value(DateTime.utc(2026, 10, 2, 22, 30)),
            ),
          );

      await pumpAppRoute(tester, '/today');
      await tester.scrollUntilVisible(
        find.text('Reading – 20 minutes'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      final row = find
          .ancestor(
            of: find.text('Reading – 20 minutes'),
            matching: find.byType(NestQuestCard),
          )
          .first;
      expect(
        find.descendant(of: row, matching: find.text('To do')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.text('Approved ✓')),
        findsNothing,
        reason: "yesterday's approval is not today's status",
      );

      await disposeApp(tester);
    });

    testWidgets('every pending stale: banner gone and the counts agree', (
      tester,
    ) async {
      final db = await setUpTestScope();
      // Move all three seeded approvals to yesterday's London day
      // (2 Oct 22:30 UTC = 23:30 London; the story day is pinned to 3 Oct).
      await (db.update(
        db.questCompletions,
      )..where((c) => c.status.equals('done_pending'))).write(
        QuestCompletionsCompanion(
          createdAt: Value(DateTime.utc(2026, 10, 2, 22, 30)),
        ),
      );

      await pumpAppRoute(tester, '/today');

      expect(find.textContaining('waiting for your thumbs-up'), findsNothing);
      expect(find.text('Review'), findsNothing);
      expect(find.text('Needs a look'), findsNothing);
      // Only this week's approvals remain, on both cards.
      expect(find.text('2 of 6 quests'), findsOneWidget); // bins + hoover
      expect(find.text('1 of 4 quests'), findsOneWidget); // bag, story day

      await tester.scrollUntilVisible(
        find.text('Put the bins out'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(find.text('Approved ✓'), findsWidgets);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('P08 Today push guard (per frame)', () {
    testWidgets('a later tap cannot stack a second editor', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      await tester.tap(find.text('Empty the dishwasher'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // The pushed page covers the list, so a tap in a later frame cannot
      // reach the row — that is what makes the per-frame guard safe. (Match
      // the row itself: P09's placeholder repeats the quest title.)
      final behind = find.byWidgetPredicate(
        (w) => w is NestQuestCard && w.title == 'Empty the dishwasher',
        skipOffstage: false,
      );
      expect(behind, findsOneWidget, reason: 'the row is still in the tree');
      await tester.tap(behind, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('P09 Quest editor', skipOffstage: false),
        findsOneWidget,
      );

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text("Today's quests", skipOffstage: false), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('the guard does not latch after a normal pop', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');

      await tester.tap(find.text('Empty the dishwasher'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('P09 Quest editor'), findsOneWidget);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text("Today's quests"), findsOneWidget);

      // The same row must still work: the guard released.
      await tester.tap(find.text('Empty the dishwasher'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('P09 Quest editor'), findsOneWidget);

      await disposeApp(tester);
    });
  });

  group('P08 Today size matrix', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in const <double>[320, 390, 430]) {
        for (final scale in const <double>[1, 1.3]) {
          final themeName = theme == ThemeMode.light ? 'light' : 'dark';
          testWidgets(
            '$themeName ${width.toInt()}px @${scale}x renders with no overflow',
            (tester) async {
              await setUpTestScope();
              await pumpAppRoute(tester, '/today', theme: theme);
              await _resize(tester, width, scale);

              expect(find.text(_expectedGreeting()), findsOneWidget);
              expect(
                find.text('3 quests waiting for your thumbs-up'),
                findsOneWidget,
              );
              expect(find.text('4 of 6 quests'), findsOneWidget);
              expect(find.text("Today's quests"), findsOneWidget);
              expect(find.text('MAYA · 9'), findsOneWidget);

              await tester.scrollUntilVisible(
                find.text('Hand to Maya or Leo'),
                300,
                scrollable: find.byType(Scrollable).first,
              );
              await tester.pump();

              expect(find.text('Hand to Maya or Leo'), findsOneWidget);
              expect(tester.takeException(), isNull);

              await disposeApp(tester);
            },
          );
        }
      }
    }
  });
}
