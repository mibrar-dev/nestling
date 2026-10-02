import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/london_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/today/domain/entities/child_day_summary.dart';
import 'package:nestling/features/today/domain/entities/today_item.dart';
import 'package:nestling/features/today/domain/today_repository.dart';
import 'package:nestling/features/today/presentation/bloc/today_bloc.dart';
import 'package:nestling/features/today/presentation/bloc/today_event.dart';
import 'package:nestling/features/today/presentation/views/today_view.dart';

import '../../test_scope.dart';

class _MockTodayRepository extends Mock implements TodayRepository;

/// One pending quest / one child: drives the loading + failure state tests
/// (a healthy Drift database can never produce those states).
const _mockItems = <TodayItem>[
  TodayItem(
    id: 'q-dishwasher:maya',
    title: 'Empty the dishwasher',
    detail: 'Maya · waiting for thumbs-up',
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
  final london = toLondon(DateTime.now().toUtc());
  return '${dayPartForHour(london.hour)}, Sarah';
}

String _expectedDateLine(int happyDays) {
  return '${formatLondonDay(DateTime.now().toUtc())} · Happy week: $happyDays days';
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

      // Maya's six quests are α-ordered; scroll through them in order.
      final list = find.byType(Scrollable).first;
      for (final title in <String>[
        'Empty the dishwasher',
        'Put the bins out',
        'Reading – 20 minutes',
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
      expect(find.text('P11 Approvals'), findsOneWidget);
      expect(
        _currentUri(tester, find.text('P11 Approvals')).path,
        '/approvals',
      );

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
      expect(find.text('P10 Quest library'), findsOneWidget);
      expect(
        _currentUri(tester, find.text('P10 Quest library')).path,
        '/quests',
      );

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
      expect(find.text('P10 Quest library'), findsOneWidget);

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

      // Scroll through every row so each lays out under the constraints.
      final list = find.byType(Scrollable).first;
      for (final title in <String>[
        'Put the bins out',
        'Reading – 20 minutes',
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
      final bloc = TodayBloc(repository: repo)..add(const TodayLoadRequested());

      await _pumpTodayView(tester, bloc);
      await tester.pump();

      expect(find.textContaining('offline'), findsOneWidget);
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
      final bloc = TodayBloc(repository: repo)..add(const TodayLoadRequested());

      await _pumpTodayView(tester, bloc, theme: ThemeMode.dark);
      await tester.pump();

      expect(find.textContaining('offline'), findsOneWidget);
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

      expect(find.text('P16 Settings'), findsOneWidget);
      expect(_currentUri(tester, find.text('P16 Settings')).path, '/settings');

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

      expect(find.text('P15 Child profile'), findsOneWidget);
      final uri = _currentUri(tester, find.text('P15 Child profile'));
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
