// K11 · My badges — view tests over the in-memory Drift database.
//
// Scope (stage 2b, UI builder): the design copy character-by-character, the
// three-column grid in DB order, the happy-week dots, every navigation
// destination, VoiceOver/TalkBack activation driving the REAL route change,
// the empty/loading/failure surfaces, and the width × text-scale matrix.
// Design geometry against the real bundled Nunito metrics lives in the
// sibling `badges_widget_geometry_test.dart` (isolated on purpose — loading
// the real faces moves every text metric on the screen).
//
// Every pumped app ends with `disposeApp` (test_scope.dart). No
// `DateTime.now`, no `google_fonts`, no simulator.
//
// The demo seed carries the design's nine shelf rows in DB insertion order
// (`shared/k11_badges_seed` on main); every count below is read from the
// database, never hard-coded from the design.

import 'dart:async';

import 'package:drift/drift.dart' show Value;
// Material's `Badge` widget collides with the Drift row class for the
// `badges` table, which these tests read straight from the database.
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/badges/domain/badges_repository.dart';
import 'package:nestling/features/badges/domain/entities/badge.dart' as domain;
import 'package:nestling/features/badges/domain/entities/badges_data.dart';
import 'package:nestling/features/badges/presentation/widgets/badge_grid_cell.dart';
import 'package:nestling/features/badges/presentation/widgets/happy_week_card.dart';

import '../../test_scope.dart';

const String _route = '/badges';

/// A repository that can stall, fail, or serve a controlled shelf — the
/// states a healthy demo database cannot produce on demand (K08 precedent).
class _FakeBadgesRepository implements BadgesRepository {
  _FakeBadgesRepository({
    this.hang = false,
    this.failFirstWatch = false,
    this.shelf = const <domain.Badge>[],
    this.happyDays = 0,
  });

  final bool hang;

  /// Fail only the first subscription, so "Try again" has a recovery to find.
  final bool failFirstWatch;

  final List<domain.Badge> shelf;
  final int happyDays;

  /// The shelf belongs to the active child; the fake always answers for Maya
  /// (the child-switch path is covered against the real database).
  final String childId = 'maya';

  int _watches = 0;

  BadgesData get _data =>
      BadgesData(childId: childId, items: shelf, happyDays: happyDays);

  @override
  Stream<BadgesData> watchActiveBadges() {
    _watches++;
    if (hang) return const Stream<BadgesData>.empty();
    if (failFirstWatch && _watches == 1) {
      return Stream<BadgesData>.error(Exception('badges down'));
    }
    return Stream<BadgesData>.value(_data);
  }

  @override
  Stream<List<domain.Badge>> watchShelf(String childId) =>
      Stream<List<domain.Badge>>.value(shelf);

  @override
  Stream<int> watchHappyDays(String childId) => Stream<int>.value(happyDays);

  @override
  Future<List<domain.Badge>> getItems() async => shelf;

  @override
  Stream<List<domain.Badge>> watchItems() => watchShelf(childId);
}

Future<void> _useFakeRepository(BadgesRepository repo) async {
  await GetIt.instance.unregister<BadgesRepository>();
  GetIt.instance.registerSingleton<BadgesRepository>(repo);
}

Future<void> _pumpRoute(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  String route = _route,
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

/// The demo shelf's rows in DB insertion order (the grid order). The Drift row
/// type for the `badges` table is `Badge` (the domain entity is imported as
/// `domain.Badge`).
Future<List<Badge>> _shelfRows(AppDatabase db) => db.select(db.badges).get();

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await setUpTestScope();
  });

  group('K11 copy and grid', () {
    testWidgets('the title carries the design copy', (tester) async {
      await _pumpRoute(tester);
      expect(find.text('My badges'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('every badge shows the database title, in creation order', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final rows = await _shelfRows(db);
      final cells = find.byType(BadgeGridCell);
      expect(cells, findsNWidgets(rows.length));
      expect(
        tester
            .widgetList<BadgeGridCell>(cells)
            .map((cell) => cell.badge.id)
            .toList(),
        rows.map((row) => row.id).toList(),
      );
      for (final row in rows) {
        expect(find.text(row.title), findsOneWidget, reason: row.title);
      }
      await disposeApp(tester);
    });

    testWidgets('the earned/id copy is character-exact', (tester) async {
      await _pumpRoute(tester);
      final rows = await _shelfRows(db);
      final earned = (await db.select(db.earnedBadges).get())
          .where((e) => e.childId == 'maya')
          .length;
      // The design's typographic characters: × U+00D7 (seed title) and the
      // `!` on both subs. Detail copy is the repository's (design copy).
      expect(find.text('Bed maker ×7'), findsOneWidget);
      expect(find.text('Got it!'), findsNWidgets(earned));
      expect(find.text('Keep going!'), findsNWidgets(rows.length - earned));
      await disposeApp(tester);
    });

    testWidgets('the subtitle states the earned count in kid voice', (
      tester,
    ) async {
      await _pumpRoute(tester);
      expect(
        find.text('Four shiny ones already. Pip is very impressed.'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('the week line carries the em dash and curly apostrophe', (
      tester,
    ) async {
      await _pumpRoute(tester);
      expect(
        find.text('4 happy days this week — Pip hasn’t stopped singing.'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('the week dots fill 4 of 7 and keep the design letters', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final checks = find.descendant(
        of: find.byType(HappyWeekCard),
        matching: find.byWidgetPredicate(
          (widget) => widget is NestIcon && widget.assetName == NestIcons.check,
        ),
      );
      final rings = find.descendant(
        of: find.byType(HappyWeekCard),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is NestIcon && widget.assetName == NestIcons.circle,
        ),
      );
      expect(checks, findsNWidgets(4));
      expect(rings, findsNWidgets(3));
      for (final letter in <String>['M', 'W', 'F']) {
        expect(find.text(letter), findsOneWidget, reason: letter);
      }
      expect(find.text('T'), findsNWidgets(2));
      expect(find.text('S'), findsNWidgets(2));
      await disposeApp(tester);
    });

    testWidgets('a badge tile is static: one merged label, no tap action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      final rows = await _shelfRows(db);
      final earned = <String>{
        for (final e in await db.select(db.earnedBadges).get()) e.badgeId,
      };
      for (final row in rows) {
        final expected =
            '${row.title}, ${earned.contains(row.id) ? 'Got it!' : 'Keep going!'}';
        final node = find.bySemanticsLabel(expected);
        expect(node, findsOneWidget, reason: expected);
        expect(
          tester
              .getSemantics(node)
              .getSemanticsData()
              .hasAction(SemanticsAction.tap),
          isFalse,
          reason: 'a badge tile has no destination — it must not offer a tap',
        );
      }
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('K11 navigation', () {
    testWidgets('back leaves the badges for the kid home', (tester) async {
      await _pumpRoute(tester);
      await tester.tap(find.byType(NestIconButton));
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    testWidgets('the lock opens the parental gate', (tester) async {
      await _pumpRoute(tester);
      await tester.tap(find.byType(NestLockButton));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/parental-gate');
      await disposeApp(tester);
    });

    testWidgets('back POPS when the badges were pushed onto the stack', (
      tester,
    ) async {
      // Reached imperatively: no dock entry pushes /badges yet, so the test
      // pushes it the way a future entry will, then the back button must pop
      // rather than re-route (`canPop` branch in `_BadgesTopRow`).
      await _pumpRoute(tester, route: '/kid-home');
      expect(currentPath(tester), '/kid-home');
      final context = tester.element(find.byType(Navigator).first);
      unawaited(GoRouter.of(context).push('/badges'));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/badges');
      expect(find.byType(BadgeGridCell), findsWidgets);

      await tester.tap(find.byType(NestIconButton));
      await tester.pumpAndSettle();

      expect(currentPath(tester), '/kid-home');
      expect(pushedPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    testWidgets('a fast double tap on the lock opens one gate only', (
      tester,
    ) async {
      await _pumpRoute(tester);
      await tester.tap(find.byType(NestLockButton));
      await tester.tap(find.byType(NestLockButton));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/parental-gate');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/badges');
      expect(find.byType(NestLockButton), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('K11 accessibility actions (VoiceOver/TalkBack)', () {
    bool hasTap(WidgetTester tester, Finder finder) => tester
        .getSemantics(finder)
        .getSemanticsData()
        .hasAction(SemanticsAction.tap);

    void performTap(WidgetTester tester, Finder finder) {
      final node = tester.getSemantics(finder);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'the control must expose SemanticsAction.tap',
      );
      node.owner!.performAction(node.id, SemanticsAction.tap);
    }

    testWidgets('back and the lock both advertise a tap', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      expect(hasTap(tester, find.bySemanticsLabel('Back').first), isTrue);
      expect(hasTap(tester, find.bySemanticsLabel('Grown-ups').first), isTrue);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a screen-reader tap on Back really navigates', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      performTap(tester, find.bySemanticsLabel('Back').first);
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/kid-home');
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('a screen-reader tap on the lock really opens the gate', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);
      performTap(tester, find.bySemanticsLabel('Grown-ups').first);
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/parental-gate');
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('K11 database-driven states', () {
    testWidgets("Leo's shelf shows his own one badge and three happy days", (
      tester,
    ) async {
      await _pumpRoute(tester);
      expect(
        find.text('Four shiny ones already. Pip is very impressed.'),
        findsOneWidget,
      );

      await tester.runAsync(() async {
        await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
          const AppStateCompanion(activeChildId: Value('leo')),
        );
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(
        find.text('One shiny one already. Pip is very impressed.'),
        findsOneWidget,
      );
      expect(
        find.text('3 happy days this week — Pip hasn’t stopped singing.'),
        findsOneWidget,
      );
      expect(find.text('Got it!'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('earning a badge re-reads the grid and the subtitle', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final family = await db.select(db.families).getSingle();
      await tester.runAsync(() async {
        await db
            .into(db.earnedBadges)
            .insert(
              EarnedBadgesCompanion.insert(
                badgeId: 'early-bird',
                childId: 'maya',
                familyId: family.id,
                earnedAt: Value(DateTime.utc(2026, 9, 30, 10)),
              ),
            );
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('Got it!'), findsNWidgets(5));
      // 5 earned: the design's word list is not used past nine and 5 is
      // "Five".
      expect(
        find.text('Five shiny ones already. Pip is very impressed.'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('a happy-day write moves the dots and the week line', (
      tester,
    ) async {
      await _pumpRoute(tester);
      await tester.runAsync(() async {
        await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
          const ChildrenCompanion(happyDays: Value(6)),
        );
        await Future<void>.delayed(Duration.zero);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      final checks = find.descendant(
        of: find.byType(HappyWeekCard),
        matching: find.byWidgetPredicate(
          (widget) => widget is NestIcon && widget.assetName == NestIcons.check,
        ),
      );
      expect(checks, findsNWidgets(6));
      expect(
        find.text('6 happy days this week — Pip hasn’t stopped singing.'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });

    testWidgets('wiping the shelf shows the kid empty state, no week card', (
      tester,
    ) async {
      await db.delete(db.earnedBadges).go();
      await db.delete(db.badges).go();
      await _pumpRoute(tester);
      expect(find.text('No badges yet'), findsOneWidget);
      expect(
        find.text('Finish a quest and your first badge will shine here.'),
        findsOneWidget,
      );
      expect(find.byType(BadgeGridCell), findsNothing);
      expect(find.byType(HappyWeekCard), findsNothing);
      // The chrome survives so a child can always get back.
      expect(find.byType(NestIconButton), findsOneWidget);
      expect(find.byType(NestLockButton), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('K11 happy-day clamp (K11-BUG-1 regression)', () {
    testWidgets('a stored count above 7 fills seven dots, never eight days', (
      tester,
    ) async {
      // The schema documents 0..7 but enforces no upper bound; the card must
      // clamp to the seven days it draws. Mirrors the skipped `k11_bugs_test`
      // probe — un-skipped here because the widget now owns the clamp.
      await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(happyDays: Value(8)),
      );
      await _pumpRoute(tester);
      expect(tester.takeException(), isNull);

      final checks = find.descendant(
        of: find.byType(HappyWeekCard),
        matching: find.byWidgetPredicate(
          (widget) => widget is NestIcon && widget.assetName == NestIcons.check,
        ),
      );
      expect(checks, findsNWidgets(7), reason: 'only seven days exist');
      expect(
        find.text('8 happy days this week — Pip hasn’t stopped singing.'),
        findsNothing,
        reason: 'the card must not claim a day it cannot draw',
      );
      expect(
        find.text('7 happy days this week — Pip hasn’t stopped singing.'),
        findsOneWidget,
        reason: 'the line clamps to the seven drawn days',
      );
      await disposeApp(tester);
    });

    testWidgets('a negative stored count renders the zero line, no dots', (
      tester,
    ) async {
      await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(happyDays: Value(-3)),
      );
      await _pumpRoute(tester);
      expect(tester.takeException(), isNull);

      final checks = find.descendant(
        of: find.byType(HappyWeekCard),
        matching: find.byWidgetPredicate(
          (widget) => widget is NestIcon && widget.assetName == NestIcons.check,
        ),
      );
      expect(checks, findsNothing);
      expect(find.text('Let’s make today a happy day!'), findsOneWidget);
      await disposeApp(tester);
    });

    test('HappyWeekCopy.why clamps outside 0..7', () {
      expect(
        HappyWeekCopy.why(8),
        '7 happy days this week — Pip hasn’t stopped singing.',
      );
      expect(
        HappyWeekCopy.why(99),
        '7 happy days this week — Pip hasn’t stopped singing.',
      );
      expect(HappyWeekCopy.why(-3), 'Let’s make today a happy day!');
      expect(
        HappyWeekCopy.why(1),
        '1 happy day this week — Pip hasn’t stopped singing.',
      );
    });
  });

  group('K11 states', () {
    testWidgets('a stalled stream shows the kid spinner with a label', (
      tester,
    ) async {
      await _useFakeRepository(_FakeBadgesRepository(hang: true));
      await _pumpRoute(tester);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(CircularProgressIndicator)).label,
        'Loading badges',
      );
      // The chrome stays usable while the shelf loads.
      expect(find.byType(NestIconButton), findsOneWidget);
      expect(find.byType(NestLockButton), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('a failed stream offers a retry that reloads', (tester) async {
      await _useFakeRepository(
        _FakeBadgesRepository(
          failFirstWatch: true,
          shelf: const <domain.Badge>[
            domain.Badge(
              id: 'first-quest',
              title: 'First quest',
              detail: 'Got it!',
              icon: 'medal',
              description: '',
              earned: true,
              earnedAt: null,
            ),
          ],
          happyDays: 2,
        ),
      );
      await _pumpRoute(tester);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('My badges'), findsOneWidget);
      expect(find.byType(BadgeGridCell), findsOneWidget);
      expect(
        find.text('One shiny one already. Pip is very impressed.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the empty surface still lets the child go back', (
      tester,
    ) async {
      await _useFakeRepository(_FakeBadgesRepository());
      await _pumpRoute(tester);
      expect(find.text('No badges yet'), findsOneWidget);
      await tester.tap(find.byType(NestIconButton));
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    testWidgets('the failure surface still lets the child go back', (
      tester,
    ) async {
      // `hang` wins over `failFirstWatch` in the fake, so only the failing
      // flag is set here: the screen must sit on the retry surface.
      await _useFakeRepository(_FakeBadgesRepository(failFirstWatch: true));
      await _pumpRoute(tester);
      expect(find.text('Something went wrong'), findsOneWidget);
      await tester.tap(find.byType(NestIconButton));
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    testWidgets('the failure surface still reaches the parental gate', (
      tester,
    ) async {
      await _useFakeRepository(_FakeBadgesRepository(failFirstWatch: true));
      await _pumpRoute(tester);
      expect(find.text('Something went wrong'), findsOneWidget);
      await tester.tap(find.byType(NestLockButton));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/parental-gate');
      await disposeApp(tester);
    });

    testWidgets('a screen-reader tap on Try again reloads the real shelf', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _useFakeRepository(
        _FakeBadgesRepository(
          failFirstWatch: true,
          shelf: const <domain.Badge>[
            domain.Badge(
              id: 'first-quest',
              title: 'First quest',
              detail: 'Got it!',
              icon: 'medal',
              description: '',
              earned: true,
              earnedAt: null,
            ),
          ],
          happyDays: 2,
        ),
      );
      await _pumpRoute(tester);
      expect(find.text('Something went wrong'), findsOneWidget);

      // The retry is a real control: a tap action that drives the real bloc
      // event and repaints the shelf.
      final node = tester.getSemantics(find.bySemanticsLabel('Try again'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('My badges'), findsOneWidget);
      expect(find.byType(BadgeGridCell), findsOneWidget);
      expect(
        find.text('2 happy days this week — Pip hasn’t stopped singing.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await disposeApp(tester);
    });
  });

  group('K11 theme and layout matrix', () {
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('renders without overflow in ${theme.name}', (tester) async {
        await _pumpRoute(tester, theme: theme);
        expect(tester.takeException(), isNull);
        expect(find.text('My badges'), findsOneWidget);
        expect(find.byType(BadgeGridCell), findsWidgets);
        expect(find.byType(HappyWeekCard), findsOneWidget);
        await disposeApp(tester);
      });
    }

    for (final (width, scale) in <(double, double)>[(320, 1.3), (390, 1)]) {
      testWidgets('fits ${width.toInt()} px at text scale $scale', (
        tester,
      ) async {
        await _pumpRoute(tester, width: width, textScale: scale);
        expect(tester.takeException(), isNull);
        final first = tester.getRect(find.byType(BadgeGridCell).first);
        final third = tester.getRect(find.byType(BadgeGridCell).at(2));
        expect(first.left, closeTo(20, 0.5));
        expect(third.right, closeTo(width - 20, 0.5));
        // The columns follow the width, never a fixed 108.67
        // (SPACING_SPEC §10.2): (W − 40 − 24) / 3.
        expect(first.width, closeTo((width - 40 - 24) / 3, 1));
        // The week card can sit below the fold at the narrow / large-type
        // corner (the list builds lazily), so scroll it into view and check it
        // lays out there too — no overflow, card still 20 px in from both
        // edges.
        await tester.scrollUntilVisible(find.byType(HappyWeekCard), 120);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final week = tester.getRect(find.byType(HappyWeekCard));
        expect(week.left, closeTo(20, 0.5));
        expect(week.right, closeTo(width - 20, 0.5));
        await disposeApp(tester);
      });
    }

    testWidgets('a 2.0 system text scale is clamped to 1.3 by the shell', (
      tester,
    ) async {
      await _pumpRoute(tester, textScale: 1.3);
      final atClamp = tester.getRect(find.text('My badges'));

      await _pumpRoute(tester, textScale: 2);

      expect(tester.takeException(), isNull);
      expect(
        tester.getRect(find.text('My badges')),
        atClamp,
        reason: 'app.dart clamps textScaler to 1.0…1.3',
      );
      await disposeApp(tester);
    });
  });
}
