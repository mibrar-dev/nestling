// P08b · Today empty (`/today-empty`) — Stage 3 test suite.
//
// Copy of record: `design/html-source/screens/P08b-today-empty.html`
// (byte-exact copy, including the curly quotes and the em/en dashes).
// Geometry of record: `design/screens/{light,dark}/P08b-today-empty.png`
// (1170×2532 @3x; the numbers below are ÷3 and then − 47 for the status bar,
// because `NestStatusBar` only reserves height and the OS draws the real one —
// see the ORCHESTRATOR "STATUS BAR" rule. Widget tests have no top inset, so
// the app's measured y is directly comparable with "design ÷ 3 − 47").
//
// Seeds: `Seed.newFamily` is the P08b UI-check state (Sarah + Maya + Leo, no
// quests — the state the design PNG shows, including the two-name sentence).
// `Seed.empty` (no children at all) drives the 0-child copy variant.
//
// RED TESTS: the `P08b geometry vs design` group pins the design's y
// positions and currently fails — see `docs/screens/P08b/3_test.md`
// (P08b-T01/T02/T03). The screen is NOT patched here by design (Stage 3 rule).

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/today/domain/entities/child_day_summary.dart';
import 'package:nestling/features/today/domain/entities/today_item.dart';
import 'package:nestling/features/today/domain/today_repository.dart';
import 'package:nestling/features/today/presentation/bloc/today_bloc.dart';
import 'package:nestling/features/today/presentation/bloc/today_event.dart';
import 'package:nestling/features/today/presentation/bloc/today_state.dart';
import 'package:nestling/features/today/presentation/views/today_empty_view.dart';
import 'package:nestling/features/today/presentation/widgets/today_loaded_body.dart';

import '../../test_scope.dart';

class _MockTodayRepository extends Mock implements TodayRepository;

/// HTML line 30: the greeting block.
const String _greetingTitle = 'Good morning, Sarah';

/// HTML line 30: `.greet .date`.
const String _emptyDateLine = 'A fresh nest';

/// HTML line 31: `.empty-card h2`.
const String _cardTitle = 'Your nest is quiet';

/// HTML line 31: `.empty-card p` (the two-name variant the design shows).
const String _twoChildMessage =
    'Add your first quest and Pip will start to hatch. '
    'Maya and Leo will see it straight away.';

/// HTML line 31 with no children at all: the second sentence is dropped.
const String _noChildMessage =
    'Add your first quest and Pip will start to hatch.';

/// HTML line 32: `.card.inset .body-s`.
const String _tipTitle = 'Tip for new nests';

/// HTML line 33: `.card.inset .caption` — em dash, curly quotes, en dash.
const String _tipBody =
    'Start with two daily quests each — “Make your bed” and '
    '“Reading – 20 minutes” work beautifully.';

/// HTML line 31: `.empty-card img` alt text.
const String _pipAlt = 'Pip the bird as a speckled egg';

/// Design geometry, logical px, status bar removed (`÷3 − 47`). Each entry is
/// the y of the element's own box; see `3_test.md` for how it was measured.
const double _dH1Top = 0;
const double _dDateTop = 36;
const double _dCardTop = 74;
const double _dCardBottom = 508;
const double _dPipTop = 102;
const double _dH2Top = 250;
const double _dMessageTop = 286;
const double _dButtonTop = 376;
const double _dLinkTop = 436;
const double _dTipTop = 524;
const double _dTipTitleTop = 540;
const double _dTipBodyTop = 562;
const double _dTipBottom = 614;

/// Loads the bundled Inter/Nunito faces so line breaking and box heights match
/// a device run (same pattern as the design-system geometry tests).
Future<void> _loadBundledFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
  await inter.load();
  await nunito.load();
}

/// `Seed.newFamily`: the P08b UI-check state (2 children, nothing to do).
Future<AppDatabase> _seedNewFamily() async {
  final db = await setUpTestScope(seedDemo: false);
  await Seed.newFamily(db);
  await GetIt.instance<AppSession>().refresh();
  return db;
}

/// `Seed.empty`: onboarded parent, no children at all.
Future<AppDatabase> _seedNoChildren() async {
  final db = await setUpTestScope(seedDemo: false);
  await Seed.empty(db);
  await GetIt.instance<AppSession>().refresh();
  return db;
}

Future<void> _resize(WidgetTester tester, double width, double scale) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

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

Future<void> _removeChild(AppDatabase db, String id) async {
  await (db.delete(
    db.questCompletions,
  )..where((c) => c.childId.equals(id))).go();
  await (db.delete(db.quests)..where((q) => q.assigneeChildId.equals(id))).go();
  await (db.delete(db.children)..where((c) => c.id.equals(id))).go();
}

/// The empty-state card (the `.empty-card` ancestor of its own title).
Finder _emptyCard() => find
    .ancestor(of: find.text(_cardTitle), matching: find.byType(NestCard))
    .first;

/// The `.card.inset` tip.
Finder _tipCard() => find
    .ancestor(of: find.text(_tipTitle), matching: find.byType(NestCard))
    .first;

/// The `Add a quest` primary button's own widget (the visible pill).
Finder _addQuestButton() => find
    .ancestor(of: find.text('Add a quest'), matching: find.byType(NestButton))
    .first;

/// The `Browse ideas` link's hit area (`InkWell`).
Finder _browseIdeasLink() => find
    .ancestor(of: find.text('Browse ideas'), matching: find.byType(InkWell))
    .first;

void main() {
  setUpAll(_loadBundledFonts);

  group('P08b copy · light · new_family (the design state)', () {
    testWidgets('renders every line of copy, byte-exact', (tester) async {
      await _seedNewFamily();
      await pumpAppRoute(tester, '/today-empty');

      expect(find.text(_greetingTitle), findsOneWidget);
      // The day part of the date line comes from the pinned clock; its suffix
      // is pinned by "the date line uses the design day part" below (P08b-T05).
      expect(find.textContaining('Sat 3 Oct · '), findsOneWidget);
      expect(find.text(_cardTitle), findsOneWidget);
      expect(find.text(_twoChildMessage), findsOneWidget);
      expect(find.text(_tipTitle), findsOneWidget);
      expect(find.text(_tipBody), findsOneWidget);
      expect(find.text('Add a quest'), findsOneWidget);
      expect(find.text('Browse ideas'), findsOneWidget);

      // The typographic characters are part of the contract: em dash (—),
      // en dash (–), curly quotes (“ ”), never a hyphen or straight quotes.
      final tip = tester.widget<Text>(find.text(_tipBody)).data!;
      expect(tip, contains('—'));
      expect(tip, contains('“Make your bed”'));
      expect(tip, contains('Reading – 20 minutes'));
      expect(tip, isNot(contains(' - ')));
      expect(tip, isNot(contains('"')));

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the date line uses the design day part (P08b-T05)', (
      tester,
    ) async {
      await _seedNewFamily();
      await pumpAppRoute(tester, '/today-empty');

      // Pinned clock (test/flutter_test_config.dart): Sat 3 Oct 2026 09:41
      // Europe/London. The design PNG says "Sat 4 Oct" (the design's own day);
      // the day name/month come from the clock, the suffix from the screen.
      expect(
        tester.widget<Text>(find.textContaining('Sat 3 Oct · ')).data,
        'Sat 3 Oct · $_emptyDateLine',
      );

      await disposeApp(tester);
    });

    testWidgets('no plus button, no avatar, no banner or quest sections', (
      tester,
    ) async {
      await _seedNewFamily();
      await pumpAppRoute(tester, '/today-empty');

      // The P08b greeting is text only (HTML line 30 has no .greet-actions).
      expect(find.bySemanticsLabel('New quest'), findsNothing);
      expect(find.bySemanticsLabel("Sarah's profile"), findsNothing);
      expect(find.byType(NestIconButton), findsNothing);

      // The populated P08 furniture is absent: no approvals banner, no kids
      // grid, no "Today's quests", no hand-off button.
      expect(find.text('Review'), findsNothing);
      expect(find.textContaining('waiting for your thumbs-up'), findsNothing);
      expect(find.text('4 of 6 quests'), findsNothing);
      expect(find.text('2 of 4 quests'), findsNothing);
      expect(find.text("Today's quests"), findsNothing);
      expect(find.textContaining('Hand to'), findsNothing);
      expect(find.text('MAYA · 9'), findsNothing);

      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('dark theme renders the same copy', (tester) async {
      await _seedNewFamily();
      await pumpAppRoute(tester, '/today-empty', theme: ThemeMode.dark);

      expect(find.text(_greetingTitle), findsOneWidget);
      expect(find.text(_cardTitle), findsOneWidget);
      expect(find.text(_twoChildMessage), findsOneWidget);
      expect(find.text(_tipTitle), findsOneWidget);
      expect(find.text(_tipBody), findsOneWidget);
      expect(find.text('Add a quest'), findsOneWidget);
      expect(find.text('Browse ideas'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P08b message copy · family size', () {
    test('the second sentence names 0 / 1 / 2 / 3+ children', () {
      expect(emptyMessageSuffix(const <String>[]), '');
      expect(
        emptyMessageSuffix(const <String>['Maya']),
        ' Maya will see it straight away.',
      );
      expect(
        emptyMessageSuffix(const <String>['Maya', 'Leo']),
        ' Maya and Leo will see it straight away.',
      );
      // UK style: no Oxford comma.
      expect(
        emptyMessageSuffix(const <String>['Maya', 'Leo', 'Ava']),
        ' Maya, Leo and Ava will see it straight away.',
      );
    });

    testWidgets('no children: the names sentence is dropped', (tester) async {
      await _seedNoChildren();
      await pumpAppRoute(tester, '/today-empty');

      expect(find.text(_noChildMessage), findsOneWidget);
      expect(find.textContaining('will see it straight away'), findsNothing);
      expect(find.text(_cardTitle), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('one child: only that child is named', (tester) async {
      final db = await _seedNewFamily();
      await _removeChild(db, 'leo');
      await pumpAppRoute(tester, '/today-empty');

      expect(
        find.text(
          'Add your first quest and Pip will start to hatch. '
          'Maya will see it straight away.',
        ),
        findsOneWidget,
      );

      await disposeApp(tester);
    });

    testWidgets('three children: all are named, eldest first', (tester) async {
      final db = await _seedNewFamily();
      await _insertChild(db, 'ava', 'Ava', 4);
      await pumpAppRoute(tester, '/today-empty');

      expect(
        find.text(
          'Add your first quest and Pip will start to hatch. '
          'Maya, Leo and Ava will see it straight away.',
        ),
        findsOneWidget,
      );

      await disposeApp(tester);
    });

    testWidgets('a later child who is OLDER still comes last (P08b-T06)', (
      tester,
    ) async {
      final db = await _seedNewFamily();
      // Zara (12) is added after Maya and Leo but is the oldest. The CHILD
      // ORDER ruling (creation order, never age or alphabetical) applies to
      // every screen and repository.
      await _insertChild(db, 'zara', 'Zara', 12);
      await pumpAppRoute(tester, '/today-empty');

      expect(
        find.text(
          'Add your first quest and Pip will start to hatch. '
          'Maya, Leo and Zara will see it straight away.',
        ),
        findsOneWidget,
        reason:
            'BUG P08b-T06: TodayRepositoryImpl.watchSummaries re-sorts the '
            'roster by ageYears desc then nickname, so this renders '
            '"Zara, Maya and Leo"',
      );

      await disposeApp(tester);
    });
  });

  group('P08b navigation · every control', () {
    testWidgets('Add a quest pushes the editor with no questId', (
      tester,
    ) async {
      await _seedNewFamily();
      await pumpAppRoute(tester, '/today-empty');

      await tester.tap(find.text('Add a quest'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(pushedPath(tester), '/quest-editor');
      final uri = GoRouter.of(tester.element(find.byType(Navigator).first))
          .state
          .uri;
      expect(uri.path, '/quest-editor');
      expect(uri.queryParameters.containsKey('questId'), isFalse);

      // System back returns to the empty screen, not out of the app.
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text(_cardTitle), findsOneWidget);
      expect(find.text(_greetingTitle), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('Browse ideas goes to the quest library', (tester) async {
      await _seedNewFamily();
      await pumpAppRoute(tester, '/today-empty');

      await tester.tap(find.text('Browse ideas'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(pushedPath(tester), '/quests');

      await disposeApp(tester);
    });

    testWidgets('the tab bar still navigates between the shell branches', (
      tester,
    ) async {
      await _seedNewFamily();
      await pumpAppRoute(tester, '/today-empty');

      // Scope the tab finders to the bar: the other shell branches stay alive
      // in the indexed stack, so P10's own "Quests" heading is in the tree.
      Finder tab(String label) => find
          .descendant(
            of: find.byType(NestTabBar),
            matching: find.bySemanticsLabel(label),
          )
          .first;

      await tester.tap(tab('Quests'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(pushedPath(tester), '/quests');

      await tester.tap(tab('Today'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // The Today branch is already active, so `goBranch` keeps its current
      // location: the empty screen comes back, not `/today`.
      expect(pushedPath(tester), '/today-empty');
      expect(find.text(_cardTitle), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('a non-empty database falls back to the populated P08 body', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today-empty');

      expect(find.text("Today's quests"), findsOneWidget);
      expect(find.text('4 of 6 quests'), findsOneWidget);
      expect(find.text(_cardTitle), findsNothing);
      expect(find.text(_tipTitle), findsNothing);

      await disposeApp(tester);
    });
  });

  group('P08b states · loading and failure', () {
    testWidgets('loading shows the spinner, never the empty card', (
      tester,
    ) async {
      final repo = _MockTodayRepository();
      when(repo.watchItems)
          .thenAnswer((_) => const Stream<List<TodayItem>>.empty());
      when(repo.watchSummaries)
          .thenAnswer((_) => const Stream<List<ChildDaySummary>>.empty());
      when(repo.watchParentName)
          .thenAnswer((_) => const Stream<String>.empty());
      when(repo.watchPayoutDay).thenAnswer((_) => const Stream<int>.empty());
      when(repo.watchPendingCount).thenAnswer((_) => const Stream<int>.empty());
      final bloc = TodayBloc(repository: repo)..add(const TodayLoadRequested());

      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          darkTheme: NestTheme.dark(),
          home: BlocProvider<TodayBloc>.value(
            value: bloc,
            child: const TodayEmptyView(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(_cardTitle), findsNothing);
      expect(find.text(_tipTitle), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('failure shows the retry copy and recovers into the card', (
      tester,
    ) async {
      final repo = _MockTodayRepository();
      var attempts = 0;
      when(repo.watchItems).thenAnswer((_) {
        attempts++;
        return attempts == 1
            ? Stream<List<TodayItem>>.error(Exception('offline'))
            : Stream<List<TodayItem>>.value(const <TodayItem>[]);
      });
      when(repo.watchSummaries).thenAnswer(
        (_) => Stream<List<ChildDaySummary>>.value(const <ChildDaySummary>[
          ChildDaySummary(
            childId: 'maya',
            nickname: 'Maya',
            avatarColour: 'lilac',
            pipStage: 3,
            done: 0,
            total: 0,
            coins: 0,
          ),
        ]),
      );
      when(repo.watchParentName).thenAnswer((_) => Stream.value('Sarah'));
      when(repo.watchPayoutDay).thenAnswer((_) => Stream.value(6));
      when(repo.watchPendingCount).thenAnswer((_) => Stream.value(0));
      final bloc = TodayBloc(repository: repo)..add(const TodayLoadRequested());

      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          darkTheme: NestTheme.dark(),
          home: BlocProvider<TodayBloc>.value(
            value: bloc,
            child: const TodayEmptyView(),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text(
          "We couldn't load today's quests. Your data is safe — "
          'please try again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text(_cardTitle), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('P08b semantics', () {
    testWidgets('the greeting is a header node', (tester) async {
      await _seedNewFamily();
      await pumpAppRoute(tester, '/today-empty');
      final handle = tester.ensureSemantics();
      await tester.pump();

      final header = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.header == true,
      );
      expect(header, findsOneWidget);
      final data = tester.getSemantics(header).getSemanticsData();
      expect(data.label, contains(_greetingTitle));
      expect(data.hasAction(SemanticsAction.tap), isFalse);

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('the Pip art is an image node with the design alt text', (
      tester,
    ) async {
      await _seedNewFamily();
      await pumpAppRoute(tester, '/today-empty');
      final handle = tester.ensureSemantics();
      await tester.pump();

      final art = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == _pipAlt,
      );
      expect(art, findsOneWidget);
      final data = tester.getSemantics(art).getSemanticsData();
      expect(data.flagsCollection.isImage, isTrue);
      expect(
        data.hasAction(SemanticsAction.tap),
        isFalse,
        reason: 'the artwork is decorative, not a control',
      );

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('Add a quest: tap action present, performAction navigates', (
      tester,
    ) async {
      await _seedNewFamily();
      await pumpAppRoute(tester, '/today-empty');
      final handle = tester.ensureSemantics();
      await tester.pump();

      final data = tester
          .getSemantics(find.bySemanticsLabel('Add a quest'))
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      tester.semantics.performAction(
        find.semantics.byLabel('Add a quest'),
        SemanticsAction.tap,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(pushedPath(tester), '/quest-editor');

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('Browse ideas: tap action present, performAction navigates', (
      tester,
    ) async {
      await _seedNewFamily();
      await pumpAppRoute(tester, '/today-empty');
      final handle = tester.ensureSemantics();
      await tester.pump();

      // The link wraps `InkWell(onTap)` inside
      // `Semantics(excludeSemantics: true)`; without `onTap:` on the Semantics
      // node VoiceOver would see a label with no action (ORCHESTRATOR
      // "ACCESSIBILITY ACTIONS" rule).
      final data = tester
          .getSemantics(find.bySemanticsLabel('Browse ideas'))
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      tester.semantics.performAction(
        find.semantics.byLabel('Browse ideas'),
        SemanticsAction.tap,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(pushedPath(tester), '/quests');

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('no Semantics(excludeSemantics) node hides content', (
      tester,
    ) async {
      await _seedNewFamily();
      await pumpAppRoute(tester, '/today-empty');

      // A control may hide its subtree (`excludeSemantics`) only if it declares its
      // own label; otherwise VoiceOver/TalkBack read an unlabelled button.
      final offenders = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where(
            (s) =>
                s.excludeSemantics &&
                (s.properties.button ?? false) &&
                (s.properties.label ?? '').isEmpty,
          );
      expect(offenders, isEmpty);

      await disposeApp(tester);
    });
  });

  group('P08b tap targets (parent floor 44)', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: button >= 52, link >= 44', (tester) async {
        await _seedNewFamily();
        await pumpAppRoute(tester, '/today-empty', theme: theme);

        final button = tester.getRect(_addQuestButton());
        expect(button.height, greaterThanOrEqualTo(NestDevice.tapParent));
        expect(button.height, closeTo(52, 1));
        expect(button.width, closeTo(310, 1));

        final link = tester.getRect(_browseIdeasLink());
        expect(link.height, greaterThanOrEqualTo(NestDevice.tapParent));

        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });
    }

    testWidgets('a tap 5 px above and below the link still fires', (
      tester,
    ) async {
      await _seedNewFamily();
      await pumpAppRoute(tester, '/today-empty');

      final link = tester.getRect(_browseIdeasLink());
      expect(link.height, greaterThanOrEqualTo(44));

      // Taps just outside the 15/22 glyph box must still hit the control.
      for (final dy in const <double>[-12, 12]) {
        await tester.tapAt(Offset(link.center.dx, link.center.dy + dy));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(
          pushedPath(tester),
          '/quests',
          reason: 'a tap $dy px off the glyph centre must still activate',
        );
        await tester.pumpWidget(Container());
        await tester.pump();
        await pumpAppRoute(tester, '/today-empty');
      }

      await disposeApp(tester);
    });
  });

  group('P08b size matrix · no overflow at 320/390/430 and 1.0x/1.3x', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in const <double>[320, 390, 430]) {
        for (final scale in const <double>[1, 1.3]) {
          final themeName = theme == ThemeMode.light ? 'light' : 'dark';
          testWidgets(
            '$themeName ${width.toInt()}px @${scale}x renders the whole '
            'empty state',
            (tester) async {
              await _seedNewFamily();
              await pumpAppRoute(tester, '/today-empty', theme: theme);
              await _resize(tester, width, scale);

              expect(find.text(_cardTitle), findsOneWidget);
              expect(find.text('Add a quest'), findsOneWidget);
              expect(find.text('Browse ideas'), findsOneWidget);
              expect(tester.takeException(), isNull);

              await tester.scrollUntilVisible(
                find.text(_tipTitle),
                300,
                scrollable: find.byType(Scrollable).first,
              );
              await tester.pump();

              expect(find.text(_tipTitle), findsOneWidget);
              expect(find.text(_tipBody), findsOneWidget);
              // The tip caption has `maxLines: 4`; at 320 px @1.3x it needs
              // exactly four lines, so it must not be ellipsised away.
              expect(
                tester.getRect(find.text(_tipBody)).height,
                lessThanOrEqualTo(4 * 18 * scale + 1),
              );
              expect(tester.takeException(), isNull);

              await disposeApp(tester);
            },
          );
        }
      }
    }
  });

  group('P08b alignment (owner rule)', () {
    for (final width in const <double>[320, 390, 430]) {
      testWidgets('${width.toInt()}px: one gutter, everything centred', (
        tester,
      ) async {
        await _seedNewFamily();
        await pumpAppRoute(tester, '/today-empty');
        await _resize(tester, width, 1);

        const gutter = 20.0;
        final right = width - gutter;

        expect(tester.getTopLeft(find.text(_greetingTitle)).dx, gutter);
        expect(tester.getTopLeft(_emptyCard()).dx, gutter);
        expect(tester.getTopRight(_emptyCard()).dx, right);
        expect(tester.getTopLeft(_tipCard()).dx, gutter);
        expect(tester.getTopRight(_tipCard()).dx, right);

        // The primary button spans the card's inner width (20 px inset).
        final button = tester.getRect(_addQuestButton());
        expect(button.left, gutter + 20);
        expect(button.right, right - 20);

        // The Pip, the button and the link are centred on the card.
        final centre = tester.getRect(_emptyCard()).center.dx;
        expect(
          tester.getRect(find.byType(PipAvatar)).center.dx,
          closeTo(centre, 0.5),
        );
        expect(button.center.dx, closeTo(centre, 0.5));
        expect(
          tester.getRect(_browseIdeasLink()).center.dx,
          closeTo(centre, 0.5),
        );

        // The message keeps the design's 260 px measure.
        expect(
          tester.getSize(find.text(_twoChildMessage)).width,
          lessThanOrEqualTo(260),
        );

        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });
    }
  });

  group('P08b geometry vs design (÷3, status bar removed)', () {
    testWidgets('the greeting starts at the top of the scroll (P08b-T01)', (
      tester,
    ) async {
      await _seedNewFamily();
      await pumpAppRoute(tester, '/today-empty');

      // P08b's CSS has NO `.greet { padding-top }` — only P08's own
      // screen-local rule does (`P08-today.html:3`). Cross-check: P08's
      // banner starts at 123 px = 47 + 8 + 28 + 2 + 22 + 16, P08b's card at
      // 121 px = 47 + 34 + 2 + 22 + 16.
      expect(
        tester.getTopLeft(find.text(_greetingTitle)).dy,
        closeTo(_dH1Top, 1),
        reason:
            'BUG P08b-T01: _EmptyGreeting adds an 8 px top padding the '
            'design does not have, so the whole body sits 8 px low',
      );
      expect(
        tester.getTopLeft(find.textContaining(_emptyDateLine)).dy,
        closeTo(_dDateTop, 1),
      );
      expect(
        tester.getTopLeft(_emptyCard()).dy,
        closeTo(_dCardTop, 1),
        reason: 'BUG P08b-T01: design card top 121 px − 47 status bar = 74',
      );

      await disposeApp(tester);
    });

    testWidgets(
      'the empty card is 434 tall and the link row is 44 (P08b-T02)',
      (tester) async {
        await _seedNewFamily();
        await pumpAppRoute(tester, '/today-empty');

        // `.linkrow a { min-height: 44px }` — the design's row is exactly 44,
        // so the card is 434: 28 + 140 + 28 + 66 + 8 + 52 + 44 + 28 + 5×8 gaps.
        expect(
          tester.getSize(_browseIdeasLink()).height,
          closeTo(44, 1),
          reason:
              'BUG P08b-T02: the link row pads 12 px above and below the '
              '15/22 glyph (46 tall), 2 px over the design',
        );
        expect(
          tester.getTopLeft(_browseIdeasLink()).dy,
          closeTo(_dLinkTop, 1),
          reason: 'design link row 483 px − 47 = 436',
        );
        expect(
          tester.getBottomLeft(_emptyCard()).dy,
          closeTo(_dCardBottom, 1),
          reason:
              'BUG P08b-T02 (+ P08b-T01): design card bottom 555 − 47 = 508',
        );

        await disposeApp(tester);
      },
    );

    testWidgets(
      'the tip card stacks title and caption with no gap (P08b-T03)',
      (tester) async {
        await _seedNewFamily();
        await pumpAppRoute(tester, '/today-empty');

        // `.card.inset` is a plain block card (`* { margin: 0 }`), so the
        // `.body-s` and `.caption` divs touch: 16 + 22 + 36 + 16 = 90 tall.
        // Offsets are measured from the card's own top so this isolates the
        // missing gap from the whole-screen shift of P08b-T01.
        final cardTop = tester.getTopLeft(_tipCard()).dy;
        expect(
          tester.getTopLeft(find.text(_tipTitle)).dy - cardTop,
          closeTo(_dTipTitleTop - _dTipTop, 1),
          reason: 'design: 16 px card padding before the title box',
        );
        expect(
          tester.getTopLeft(find.text(_tipBody)).dy - cardTop,
          closeTo(_dTipBodyTop - _dTipTop, 1),
          reason:
              'BUG P08b-T03: _TipCard adds spacing: s1 (4 px) between the '
              'title and the caption, which the design does not have — design '
              'puts the caption box 38 px below the card top, the app 42',
        );
        expect(
          tester.getSize(_tipCard()).height,
          closeTo(_dTipBottom - _dTipTop, 1),
          reason: 'BUG P08b-T03: design tip 571–661 px − 47 = 90 tall',
        );
        expect(
          cardTop,
          closeTo(_dTipTop, 1),
          reason: 'design tip card top 571 px − 47 = 524',
        );

        await disposeApp(tester);
      },
    );

    testWidgets('the artwork, title, message and button match the design', (
      tester,
    ) async {
      await _seedNewFamily();
      await pumpAppRoute(tester, '/today-empty');

      // Everything INSIDE the card is already exact; only the card's own top
      // (T01) and bottom (T02) drift.
      expect(tester.getRect(find.byType(PipAvatar)).height, 140);
      expect(
        tester.getTopLeft(find.byType(PipAvatar)).dy -
            tester.getTopLeft(_emptyCard()).dy,
        closeTo(_dPipTop - _dCardTop, 1),
      );
      expect(
        tester.getTopLeft(find.text(_cardTitle)).dy -
            tester.getTopLeft(_emptyCard()).dy,
        closeTo(_dH2Top - _dCardTop, 1),
      );
      expect(
        tester.getTopLeft(find.text(_twoChildMessage)).dy -
            tester.getTopLeft(_emptyCard()).dy,
        closeTo(_dMessageTop - _dCardTop, 1),
      );
      // Three lines of 15/22, in the design's 260 px measure.
      expect(
        tester.getSize(find.text(_twoChildMessage)).height,
        closeTo(66, 1),
      );
      expect(
        tester.getTopLeft(_addQuestButton()).dy -
            tester.getTopLeft(_emptyCard()).dy,
        closeTo(_dButtonTop - _dCardTop, 1),
      );
      expect(tester.getSize(_addQuestButton()).height, closeTo(52, 1));

      await disposeApp(tester);
    });

    testWidgets('the greeting is never ellipsised (P08b-T04)', (tester) async {
      await _seedNewFamily();
      await pumpAppRoute(tester, '/today-empty');
      await _resize(tester, 320, 1.3);

      // P08b's `.greet h1` has no `white-space: nowrap` (P08's does), so the
      // design wraps the greeting instead of clipping the parent's name.
      // (A single-line intrinsic-width assertion could never hold here:
      // the copy needs two lines at 320 px @1.3x by design — what matters
      // is that nothing is cut off.)
      final greeting = tester.renderObject<RenderParagraph>(
        find.text(_greetingTitle),
      );
      expect(
        greeting.didExceedMaxLines,
        isFalse,
        reason:
            'BUG P08b-T04: maxLines: 1 clips the greeting to '
            '"Good morning, Sa…" at 320 px and at 1.3x on 390 px',
      );

      await disposeApp(tester);
    });
  });

  group('P08b bottom edge (owner rule)', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('${theme.name}: the tab bar surface runs to the edge', (
        tester,
      ) async {
        await _seedNewFamily();
        await pumpAppRoute(tester, '/today-empty', theme: theme);

        final screenBottom =
            tester.view.physicalSize.height / tester.view.devicePixelRatio;
        final screenRight =
            tester.view.physicalSize.width / tester.view.devicePixelRatio;

        final bar = find.byType(NestTabBar);
        expect(bar, findsOneWidget);
        final rect = tester.getRect(bar);
        expect(rect.bottom, screenBottom);
        expect(rect.left, 0);
        expect(rect.right, screenRight);

        final container = tester.widget<Container>(
          find.descendant(of: bar, matching: find.byType(Container)).first,
        );
        final decoration = container.decoration! as BoxDecoration;
        final expected = theme == ThemeMode.light
            ? NestColors.light.surface
            : NestColors.dark.surface;
        expect(decoration.color, expected);

        // Today is the active tab on /today-empty.
        expect(tester.widget<NestTabBar>(bar).currentIndex, 0);

        await disposeApp(tester);
      });
    }
  });

  group('P08b TodayBloc · the empty-state paths', () {
    blocTest<TodayBloc, TodayState>(
      'no children: loaded with the fresh-nest date line (P08b-T05)',
      build: () {
        final repo = _MockTodayRepository();
        when(repo.watchItems)
            .thenAnswer((_) => Stream.value(const <TodayItem>[]));
        when(repo.watchSummaries)
            .thenAnswer((_) => Stream.value(const <ChildDaySummary>[]));
        when(repo.watchParentName).thenAnswer((_) => Stream.value('Sarah'));
        when(repo.watchPayoutDay).thenAnswer((_) => Stream.value(6));
        when(repo.watchPendingCount).thenAnswer((_) => Stream.value(0));
        return TodayBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const TodayLoadRequested()),
      expect: () => [
        const TodayState(status: TodayStatus.loading),
        predicate<TodayState>(
          (s) =>
              s.status == TodayStatus.loaded &&
              s.items.isEmpty &&
              s.summaries.isEmpty &&
              s.parentName == 'Sarah' &&
              s.dateLine.endsWith(' · A fresh nest'),
        ),
      ],
    );

    blocTest<TodayBloc, TodayState>(
      'children but nothing to do: the date line is still A fresh nest '
      '(P08b-T05)',
      build: () {
        final repo = _MockTodayRepository();
        // The `Seed.newFamily` shape: two children, no quests. The view's
        // empty branch is `items.isEmpty || summaries.isEmpty`
        // (today_loaded_body.dart:264), so the date line must agree.
        when(repo.watchItems)
            .thenAnswer((_) => Stream.value(const <TodayItem>[]));
        when(repo.watchSummaries).thenAnswer(
          (_) => Stream.value(const <ChildDaySummary>[
            ChildDaySummary(
              childId: 'maya',
              nickname: 'Maya',
              avatarColour: 'lilac',
              pipStage: 3,
              done: 0,
              total: 0,
              coins: 120,
              ageYears: 9,
              happyDays: 4,
            ),
            ChildDaySummary(
              childId: 'leo',
              nickname: 'Leo',
              avatarColour: 'peach',
              pipStage: 2,
              done: 0,
              total: 0,
              coins: 45,
              ageYears: 6,
              happyDays: 3,
            ),
          ]),
        );
        when(repo.watchParentName).thenAnswer((_) => Stream.value('Sarah'));
        when(repo.watchPayoutDay).thenAnswer((_) => Stream.value(6));
        when(repo.watchPendingCount).thenAnswer((_) => Stream.value(0));
        return TodayBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const TodayLoadRequested()),
      expect: () => [
        const TodayState(status: TodayStatus.loading),
        predicate<TodayState>(
          (s) =>
              s.status == TodayStatus.loaded &&
              s.items.isEmpty &&
              s.summaries.length == 2 &&
              // The design shows "A fresh nest" on exactly this state; the
              // bloc instead counts the children's seeded happyDays.
              s.dateLine.endsWith(' · A fresh nest'),
        ),
      ],
    );

    blocTest<TodayBloc, TodayState>(
      'something to do: the happy-week label returns',
      build: () {
        final repo = _MockTodayRepository();
        when(repo.watchItems).thenAnswer(
          (_) => Stream.value(const <TodayItem>[
            TodayItem(
              id: 'q-bed:maya',
              title: 'Make your bed',
              questId: 'q-bed',
              childId: 'maya',
              childName: 'Maya',
              status: 'to_do',
              coins: 5,
              repeatRule: 'daily',
              iconKey: 'bed',
            ),
          ]),
        );
        when(repo.watchSummaries).thenAnswer(
          (_) => Stream.value(const <ChildDaySummary>[
            ChildDaySummary(
              childId: 'maya',
              nickname: 'Maya',
              avatarColour: 'lilac',
              pipStage: 3,
              done: 1,
              total: 2,
              coins: 120,
              ageYears: 9,
              happyDays: 4,
            ),
          ]),
        );
        when(repo.watchParentName).thenAnswer((_) => Stream.value('Sarah'));
        when(repo.watchPayoutDay).thenAnswer((_) => Stream.value(6));
        when(repo.watchPendingCount).thenAnswer((_) => Stream.value(0));
        return TodayBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const TodayLoadRequested()),
      expect: () => [
        const TodayState(status: TodayStatus.loading),
        predicate<TodayState>(
          (s) =>
              s.status == TodayStatus.loaded &&
              s.items.length == 1 &&
              s.dateLine.endsWith(' · Happy week: 4 days'),
        ),
      ],
    );

    blocTest<TodayBloc, TodayState>(
      'a stream error after load switches to failure (P08b-T06)',
      build: () {
        final repo = _MockTodayRepository();
        when(repo.watchItems)
            .thenAnswer((_) => Stream.error(Exception('boom')));
        when(repo.watchSummaries)
            .thenAnswer((_) => Stream.value(const <ChildDaySummary>[]));
        when(repo.watchParentName).thenAnswer((_) => Stream.value('Sarah'));
        when(repo.watchPayoutDay).thenAnswer((_) => Stream.value(6));
        when(repo.watchPendingCount).thenAnswer((_) => Stream.value(0));
        return TodayBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const TodayLoadRequested()),
      expect: () => [
        const TodayState(status: TodayStatus.loading),
        predicate<TodayState>(
          (s) =>
              s.status == TodayStatus.failure &&
              (s.errorMessage ?? '').contains('boom'),
        ),
      ],
    );

    test('initial state is initial and empty', () {
      final bloc = TodayBloc(repository: _MockTodayRepository());
      addTearDown(bloc.close);
      expect(bloc.state.status, TodayStatus.initial);
      expect(bloc.state.items, isEmpty);
      expect(bloc.state.summaries, isEmpty);
      expect(bloc.state.errorMessage, isNull);
    });

    blocTest<TodayBloc, TodayState>(
      'retry after a failure reloads',
      build: () {
        final repo = _MockTodayRepository();
        var attempts = 0;
        when(repo.watchItems).thenAnswer((_) {
          attempts++;
          return attempts == 1
              ? Stream<List<TodayItem>>.error(Exception('offline'))
              : Stream<List<TodayItem>>.value(const <TodayItem>[]);
        });
        when(repo.watchSummaries)
            .thenAnswer((_) => Stream.value(const <ChildDaySummary>[]));
        when(repo.watchParentName).thenAnswer((_) => Stream.value('Sarah'));
        when(repo.watchPayoutDay).thenAnswer((_) => Stream.value(6));
        when(repo.watchPendingCount).thenAnswer((_) => Stream.value(0));
        return TodayBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const TodayLoadRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const TodayLoadRequested());
      },
      expect: () => [
        const TodayState(status: TodayStatus.loading),
        predicate<TodayState>((s) => s.status == TodayStatus.failure),
        // The retry keeps the stale error in the state (copyWith), but the
        // view only shows `TodayStatus.failure`, so it never reaches the user.
        predicate<TodayState>(
          (s) => s.status == TodayStatus.loading && s.errorMessage != null,
        ),
        predicate<TodayState>(
          (s) => s.status == TodayStatus.loaded && s.items.isEmpty,
        ),
      ],
    );
  });
}
