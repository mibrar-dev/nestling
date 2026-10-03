// P10 · Quest library — loading, failure and empty-state tests.
//
// The status switch lives in `QuestLibraryView`
// (`quest_library_view.dart:33-73`) and has no widget coverage: the view
// tests can only ever reach `loaded`, because the app's own bloc always
// succeeds against the in-memory Drift DB. These tests drive the switch
// directly with a mocked repository.
//
// Covers `1_plan.md` §d: the loading spinner, the failure block with its
// `Try again` retry, and both empty states (Ideas with no match / Kindness,
// Active with no quests).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/data/quests_repository_impl.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';
import 'package:nestling/features/quests/domain/quests_repository.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_bloc.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_event.dart';
import 'package:nestling/features/quests/presentation/views/quest_library_view.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_category_chips.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_idea_row.dart';
import 'package:nestling/features/quests/quests_routes.dart';

import '../../test_scope.dart';

class _MockQuestsRepository extends Mock implements QuestsRepository {
  /// The bloc owns the idea templates (`QuestsState.ideas`, stage 2a), so
  /// `ideas()` is read on every load: mocktail answers an unstubbed method
  /// with `null`, which threw and left the bloc in `loading` forever.
  /// [setUpTestScope] registers the real repository, so hand the bloc the
  /// very templates the view used to read straight from GetIt.
  _MockQuestsRepository() {
    when(ideas).thenReturn(GetIt.instance<QuestsRepository>().ideas());
  }
}

/// Pumps [QuestLibraryView] over a bloc backed by [repository].
///
/// The view reads the idea templates from GetIt, so the scope is set up the
/// same way `pumpAppRoute` does; only the bloc is swapped.
Future<void> _pumpView(
  WidgetTester tester,
  QuestsRepository repository, {
  ThemeMode theme = ThemeMode.light,
  double width = 390,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  // Tear-downs run last-registered-first: this drain must run AFTER
  // `bloc.close()`, because closing the bloc cancels the Drift
  // `QueryStream`, which then schedules a deferred close timer. Without the
  // pump the test framework hangs on "A Timer is still pending".
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  });
  final bloc = QuestsBloc(repository: repository)
    ..add(const QuestsLoadRequested());
  addTearDown(bloc.close);
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      themeMode: theme,
      home: BlocProvider<QuestsBloc>.value(
        value: bloc,
        child: const QuestLibraryView(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// The pushed route's full URI (path **and** query).
///
/// [pushedPath] strips the query, which is exactly what the `?idea=` check
/// needs to see.
Uri _pushedUri(WidgetTester tester) {
  final context = tester.element(find.byType(Navigator).first);
  final goRouter = GoRouter.of(context);
  return goRouter.state.uri;
}

void main() {
  group('P10 loading state', () {
    testWidgets('a pending stream shows a leaf spinner and no content', (
      tester,
    ) async {
      await setUpTestScope();
      final repository = _MockQuestsRepository();
      // Never emits: the view stays in `loading` for the whole test.
      when(repository.watchItems)
          .thenAnswer((_) => const Stream<List<Quest>>.empty());

      await _pumpView(tester, repository);

      final spinner = find.byType(CircularProgressIndicator);
      expect(spinner, findsOneWidget);
      final tokens = tester.element(spinner).nest;
      expect(
        tester.widget<CircularProgressIndicator>(spinner).color,
        tokens.leaf,
      );

      // Nothing from the loaded tree leaks in behind it.
      expect(find.text('Quests'), findsNothing);
      expect(find.byType(QuestIdeaRow), findsNothing);
      expect(find.byType(TextField), findsNothing);

      // The spinner is centred, not pinned to the top-left.
      final rect = tester.getRect(spinner);
      expect(rect.center.dx, closeTo(195, 1));
    });

    testWidgets('the first emission replaces the spinner with the body', (
      tester,
    ) async {
      await setUpTestScope();
      final repository = _MockQuestsRepository();
      // Emits on the next microtask, so the view really goes
      // loading → loaded inside the test (the previous pump sees the
      // spinner, this one the body).
      when(repository.watchItems)
          .thenAnswer((_) => Stream<List<Quest>>.value(const <Quest>[]));

      await _pumpView(tester, repository);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Quests'), findsOneWidget);
      expect(find.byType(QuestIdeaRow), findsWidgets);
    });
  });

  group('P10 failure state', () {
    testWidgets('a stream error shows the message and a Try again button', (
      tester,
    ) async {
      await setUpTestScope();
      final repository = _MockQuestsRepository();
      when(repository.watchItems).thenAnswer(
        (_) => Stream<List<Quest>>.error(Exception('Database is offline')),
      );

      await _pumpView(tester, repository);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      // The message is the whole `error.toString()`, so it carries the
      // exception type as well as the message.
      expect(find.text('Exception: Database is offline'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      // The message is body copy in ink, centred, with no list behind it.
      final message = tester.widget<Text>(
        find.text('Exception: Database is offline'),
      );
      final tokens = tester
          .element(find.text('Exception: Database is offline'))
          .nest;
      expect(message.style!.color, tokens.ink);
      expect(message.textAlign, TextAlign.center);
      expect(find.byType(QuestIdeaRow), findsNothing);
    });

    testWidgets('the error message is centred in the viewport', (tester) async {
      await setUpTestScope();
      final repository = _MockQuestsRepository();
      when(repository.watchItems)
          .thenAnswer((_) => Stream<List<Quest>>.error(Exception('boom')));

      await _pumpView(tester, repository);

      final rect = tester.getRect(find.text('Exception: boom'));
      expect(rect.center.dx, closeTo(195, 1));
    });

    testWidgets('a failure with no message still offers the retry', (
      tester,
    ) async {
      await setUpTestScope();
      final repository = _MockQuestsRepository();
      when(repository.watchItems)
          .thenAnswer((_) => Stream<List<Quest>>.error(Exception('')));

      await _pumpView(tester, repository);

      // `errorMessage` is never null for a failure, so the fallback copy is
      // unreachable through the bloc — pin whatever it renders instead.
      expect(find.text('Try again'), findsOneWidget);
      expect(find.byType(NestButton), findsOneWidget);
    });

    testWidgets('`Try again` re-requests and a healthy retry loads', (
      tester,
    ) async {
      await setUpTestScope();
      final repository = _MockQuestsRepository();
      var attempts = 0;
      when(repository.watchItems).thenAnswer((_) {
        attempts++;
        return attempts == 1
            ? Stream<List<Quest>>.error(Exception('offline'))
            : Stream<List<Quest>>.value(const <Quest>[]);
      });

      await _pumpView(tester, repository);
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(attempts, 2);
      expect(find.text('Try again'), findsNothing);
      expect(find.text('Quests'), findsOneWidget);
      expect(find.byType(QuestIdeaRow), findsWidgets);
    });

    testWidgets('the failure state renders in dark mode too', (tester) async {
      await setUpTestScope();
      final repository = _MockQuestsRepository();
      when(repository.watchItems)
          .thenAnswer((_) => Stream<List<Quest>>.error(Exception('offline')));

      await _pumpView(tester, repository, theme: ThemeMode.dark);

      // The message is the whole exception string (`error.toString()`).
      expect(find.textContaining('offline'), findsOneWidget);
      final tokens = tester.element(find.textContaining('offline')).nest;
      expect(tokens.isDark, isTrue);
    });
  });

  group('P10 empty states', () {
    testWidgets('a query with no match shows `No ideas found`', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump();

      expect(find.text('No ideas found'), findsOneWidget);
      expect(find.text('Try a different search or category.'), findsOneWidget);
      expect(find.byType(QuestIdeaRow), findsNothing);
      // The empty state offers no CTA (plan §d).
      expect(find.byType(NestButton), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('the Kindness chip shows the same empty state', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      // `Kindness` is the last chip, off-screen in the scrolling row.
      await tester.dragUntilVisible(
        find.byKey(const ValueKey<String>('quest-filter-chip-Kindness')),
        find.byType(QuestCategoryChips),
        const Offset(-120, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('quest-filter-chip-Kindness')),
      );
      await tester.pump();

      expect(find.text('No ideas found'), findsOneWidget);
      expect(find.text('Try a different search or category.'), findsOneWidget);
      expect(find.byType(QuestIdeaRow), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('the empty state is centred like the design block', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump();

      final title = tester.getRect(find.text('No ideas found'));
      expect(title.center.dx, closeTo(195, 1));

      await disposeApp(tester);
    });

    testWidgets('Active with no quests shows `No active quests`', (
      tester,
    ) async {
      // `Seed.empty()` is the P08b path (onboarded parent, no quests); the
      // repository-level proof that it yields 0 actives lives in
      // `quests_repository_test.dart`, so here an empty stream is enough.
      await setUpTestScope();
      final repository = _MockQuestsRepository();
      when(repository.watchItems)
          .thenAnswer((_) => Stream<List<Quest>>.value(const <Quest>[]));

      await _pumpView(tester, repository);

      expect(find.text('Active (0)'), findsOneWidget);
      await tester.tap(find.text('Active (0)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('No active quests'), findsOneWidget);
      expect(find.text('Add one from Ideas.'), findsOneWidget);
      expect(find.byType(QuestIdeaRow), findsNothing);
    });

    testWidgets('a cleared query restores the full idea list', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump();
      expect(find.text('No ideas found'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(find.text('No ideas found'), findsNothing);
      expect(find.byType(QuestIdeaRow), findsWidgets);

      await disposeApp(tester);
    });

    testWidgets('switching back from an empty category restores All', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      await tester.dragUntilVisible(
        find.byKey(const ValueKey<String>('quest-filter-chip-Kindness')),
        find.byType(QuestCategoryChips),
        const Offset(-120, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('quest-filter-chip-Kindness')),
      );
      await tester.pump();
      expect(find.text('No ideas found'), findsOneWidget);

      // `All` is the first chip: scroll the row back before tapping it.
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('quest-filter-chip-All')),
        120,
        scrollable: find.descendant(
          of: find.byType(QuestCategoryChips),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('quest-filter-chip-All')),
      );
      await tester.pump();

      expect(find.text('No ideas found'), findsNothing);
      expect(find.byType(QuestIdeaRow), findsWidgets);

      await disposeApp(tester);
    });
  });

  group('P10 tab switching', () {
    testWidgets('Ideas is selected first, Active on tap, and back again', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      // The route is `/quests`; the parent tab bar is the shell's.
      expect(currentPath(tester), QuestsRoutePaths.library);

      await tester.tap(find.text('Active (12)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(QuestAddButton), findsNothing);

      await tester.tap(find.text('Ideas'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(QuestAddButton), findsWidgets);

      // Switching tabs never changes the route.
      expect(currentPath(tester), QuestsRoutePaths.library);

      await disposeApp(tester);
    });

    testWidgets('the Active count label tracks the database, not a literal', (
      tester,
    ) async {
      final db = await setUpTestScope();
      final repository = QuestsRepositoryImpl(db: db);
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      expect(find.text('Active (12)'), findsOneWidget);

      // Live insert: DATA OVER MOCKS means the label follows the stream.
      await repository.createQuest(
        const Quest(
          id: 'q-live',
          title: 'A brand new quest',
          detail: 'Daily · 5 coins',
          icon: 'leaf',
          coins: 5,
          repeatRule: 'daily',
          days: '',
          dueLabel: null,
          needsApproval: false,
          assigneeChildId: null,
          active: true,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Active (13)'), findsOneWidget);

      await disposeApp(tester);
    });
  });

  group('P10 navigation', () {
    testWidgets('`+ Add` pushes the editor with the idea id as a query', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      await tester.tap(find.byType(QuestAddButton).first);
      await tester.pumpAndSettle();

      // `pushedPath` strips the query, so read the full URI here.
      final uri = _pushedUri(tester);
      expect(uri.path, QuestsRoutePaths.editor);
      expect(uri.queryParameters['idea'], 'idea-bed');

      await disposeApp(tester);
    });

    testWidgets('each `+ Add` carries its own template id', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      for (final row in <List<String>>[
        <String>['quest-idea-idea-bed', 'idea-bed'],
        <String>['quest-idea-idea-table', 'idea-table'],
        <String>['quest-idea-idea-bins', 'idea-bins'],
      ]) {
        await tester.tap(
          find.descendant(
            of: find.byKey(ValueKey<String>(row[0])),
            matching: find.byType(QuestAddButton),
          ),
        );
        await tester.pumpAndSettle();

        final uri = _pushedUri(tester);
        expect(uri.path, QuestsRoutePaths.editor);
        expect(uri.queryParameters['idea'], row[1], reason: row[0]);

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(currentPath(tester), QuestsRoutePaths.library);
      }

      await disposeApp(tester);
    });

    testWidgets('an Active row opens the editor with no query', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      await tester.tap(find.text('Active (12)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byType(QuestIdeaRow).first);
      await tester.pumpAndSettle();

      final uri = _pushedUri(tester);
      expect(uri.path, QuestsRoutePaths.editor);
      expect(uri.query, isEmpty, reason: 'P09 reads ?idea, not ?id');

      await disposeApp(tester);
    });

    testWidgets('back from the editor returns to `/quests` intact', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, QuestsRoutePaths.library);

      await tester.tap(find.byType(QuestAddButton).first);
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(currentPath(tester), QuestsRoutePaths.library);
      // The list is still filtered to Ideas + All, not reset by the push.
      expect(find.byType(QuestAddButton), findsWidgets);

      await disposeApp(tester);
    });
  });
}
