// K09 · My jar — the states a healthy demo database cannot produce on
// demand: loading, failure, retry recovery and a genuinely EMPTY jar.
//
// Stage 3 (test). `my_jar_view_test.dart` owns the happy path (copy,
// navigation, loaded matrix); this file owns everything the seed is healthy
// enough to hide:
//
//   * loading — a stalled `watchJar` keeps the chrome and the shared kid sky
//     (K08's pattern: a fake repository swapped into GetIt, because a Drift
//     watch stream that never emits cannot be staged from the database);
//   * failure + retry — `Try again` really re-requests the load and the jar
//     comes back;
//   * the empty jar — driven by the REAL `Seed.empty` database (an onboarded
//     parent with no children), not a fake, so the `£0.00`, the hidden goal
//     card and `Nothing here yet` are all produced by the repository;
//   * tap targets — every control is at least the kid minimum (56) and is
//     operable by VoiceOver/TalkBack.
//
// Every pumped app ends with `disposeApp` (test_scope.dart). No
// `DateTime.now`, no `google_fonts`, no simulator. `pumpAndSettle` is never
// used while the spinner is on screen — it animates forever.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/app/di.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_entry.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_snapshot.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_summary.dart';
import 'package:nestling/features/kid_jar/domain/entities/payout_celebration.dart';
import 'package:nestling/features/kid_jar/domain/kid_jar_repository.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_goal_card.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_history_card.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_illustration.dart';

import '../../test_scope.dart';

const String _route = '/my-jar';

/// Maya's demo jar as one atomic snapshot (the same figures
/// `my_jar_view_test.dart` reads out of the real database). Dates are pinned
/// to the test clock's day (Sat 3 Oct 2026) — never wall-clock.
final JarSnapshot _mayaSnapshot = JarSnapshot(
  childId: 'maya',
  items: <JarEntry>[
    JarEntry(
      id: '1',
      title: 'Pocket money',
      detail: 'This Saturday',
      type: 'weekly_base',
      amountPence: 300,
      date: DateTime.utc(2026, 10, 3, 8),
    ),
  ],
  summary: const JarSummary(
    childId: 'maya',
    owedPence: 420,
    nextPayoutDay: 'Saturday',
    goalTitle: 'Lego Friends set',
    goalSavedPence: 1550,
    goalTargetPence: 2499,
  ),
);

/// A repository that can stall, fail, fail only the first watch or serve
/// Maya's jar — the states the healthy seed cannot produce on demand
/// (`reward_shop_view_test.dart` precedent, same DI swap).
class _FakeKidJarRepository implements KidJarRepository {
  _FakeKidJarRepository({
    this.hang = false,
    this.failLoad = false,
    this.failFirstWatch = false,
  });

  final bool hang;
  final bool failLoad;

  /// Fail only the first subscription, so `Try again` has a recovery to find.
  final bool failFirstWatch;

  int _watches = 0;

  int get watches => _watches;

  @override
  Stream<JarSnapshot> watchJar() {
    _watches++;
    if (hang) return const Stream<JarSnapshot>.empty();
    if (failLoad || (failFirstWatch && _watches == 1)) {
      return Stream<JarSnapshot>.error(Exception('jar is down'));
    }
    return Stream<JarSnapshot>.value(_mayaSnapshot);
  }

  @override
  Future<List<JarEntry>> getItems() async => _mayaSnapshot.items;

  @override
  Stream<List<JarEntry>> watchItems() =>
      Stream<List<JarEntry>>.value(_mayaSnapshot.items);

  @override
  Stream<JarSummary> watchSummary(String childId) =>
      Stream<JarSummary>.value(_mayaSnapshot.summary);

  @override
  Future<void> moveToSavings({
    required String childId,
    required String goalId,
    required int amountPence,
  }) async {}

  /// K10 hook: the empty celebration stream — the K09 jar views this test
  /// drives never request a payout load.
  @override
  Stream<PayoutCelebration?> watchLatestPayout() =>
      const Stream<PayoutCelebration?>.empty();
}

/// Swaps the Drift repository for [repo]. `KidJarRepository` is a lazy
/// singleton and `KidJarBloc` a factory, so the route's
/// `GetIt.instance<KidJarBloc>()` picks this up on the next build.
Future<void> _useFakeRepository(KidJarRepository repo) async {
  await GetIt.instance.unregister<KidJarRepository>();
  GetIt.instance.registerSingleton<KidJarRepository>(repo);
}

/// The REAL `Seed.empty` family (onboarded parent, no children): nothing
/// goes in, nothing is owed and there is no savings goal, so `watchJar`
/// falls back to `'maya'` and emits an empty list with a zero summary.
///
/// Seeding BEFORE `configureDependencies` is the whole trick — `Seed.empty`
/// calls `db.clearAll()`, which never completes on a database `AppSession`
/// is already watching (`reward_shop_view_test.dart`).
Future<AppDatabase> _useEmptySeed() async {
  await GetIt.instance.reset();
  final db = AppDatabase.memory();
  await Seed.empty(db);
  await configureDependencies(database: db);
  await GetIt.instance<AppSession>().refresh();
  return db;
}

Future<void> _pumpRoute(
  WidgetTester tester, {
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
  await tester.pumpWidget(const NestlingApp(initialRoute: _route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Two settles long enough for a Drift emission, but never `pumpAndSettle`:
/// the loading spinner animates forever and would spin until its timeout.
Future<void> _settleStreams(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

bool _hasTap(WidgetTester tester, Finder finder) => tester
    .getSemantics(finder)
    .getSemanticsData()
    .hasAction(SemanticsAction.tap);

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  group('K09 loading', () {
    testWidgets('a stalled jar shows the spinner with its own label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _useFakeRepository(_FakeKidJarRepository(hang: true));
      await _pumpRoute(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(CircularProgressIndicator)).label,
        'Loading your jar',
      );
      // A live region so a screen reader announces a slow stream instead of
      // the frame swapping in silently (review finding 6).
      expect(
        tester
            .getSemantics(find.byType(CircularProgressIndicator))
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
        reason: 'the loading label must be a live region',
      );
      // Nothing from the loaded body may leak into the first frame.
      expect(find.text('My jar'), findsNothing);
      expect(find.byType(JarGoalCard), findsNothing);
      expect(find.byType(JarHistoryCard), findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the kid sky and meadow survive the stall', (tester) async {
      await _useFakeRepository(_FakeKidJarRepository(hang: true));
      await _pumpRoute(tester);

      // The shared kid scope paints behind the spinner, so a slow database
      // never flashes a bare scaffold (KID BACKGROUND owner rule).
      expect(find.byType(KidScope), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('exactly one shared meadow, mounted by KidScope', (
      tester,
    ) async {
      await _pumpRoute(tester);

      // KID BACKGROUND: the hills come from the shared scope only. A COUNT,
      // not an absence — the meadow legitimately lives inside `KidScope`
      // (K01 harness note), so "MyJarView mounts no hill of its own" can only
      // be expressed as exactly one, and it must be the scope's.
      expect(find.byType(KidScope), findsOneWidget);
      expect(find.byType(NestMeadow), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(KidScope),
          matching: find.byType(NestMeadow),
        ),
        findsOneWidget,
      );
      // And the hills sit where the HTML pins them: full width, 136 tall, at
      // the bottom of the screen — with no bar of its own, K09's meadow runs
      // to the physical edge (BOTTOM EDGE owner rule).
      final meadow = tester.getRect(find.byType(NestMeadow));
      expect(meadow.left, 0);
      expect(meadow.right, closeTo(390, 2));
      expect(meadow.height, closeTo(NestMeadowGeometry.defaultHeight, 2));
      expect(meadow.bottom, closeTo(844, 2));
      await disposeApp(tester);
    });

    testWidgets('a stalled jar can still go back', (tester) async {
      await _useFakeRepository(_FakeKidJarRepository(hang: true));
      await _pumpRoute(tester);

      // Deliberately not `pumpAndSettle`: the spinner never stops animating.
      await tester.tap(find.byType(NestIconButton));
      await _settleStreams(tester);

      expect(currentPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    testWidgets('a stalled jar can still reach a grown-up', (tester) async {
      await _useFakeRepository(_FakeKidJarRepository(hang: true));
      await _pumpRoute(tester);

      await tester.tap(find.byType(NestLockButton));
      await _settleStreams(tester);

      expect(pushedPath(tester), '/parental-gate');
      await disposeApp(tester);
    });
  });

  group('K09 failure and retry', () {
    testWidgets('a failed jar offers a kid-voice retry', (tester) async {
      await _useFakeRepository(_FakeKidJarRepository(failLoad: true));
      await _pumpRoute(tester);

      expect(find.text('Oh no! Something went wrong.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.byType(NestKidButton), findsOneWidget);
      // No stale numbers and no spinner left behind.
      expect(find.text('£4.20'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(JarIllustration), findsNothing);
      expect(find.byType(JarGoalCard), findsNothing);
      // The chrome survives: a child is never trapped on a dead screen.
      expect(find.byType(NestIconButton), findsOneWidget);
      expect(find.byType(NestLockButton), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the failure state reads the same in dark mode', (
      tester,
    ) async {
      await _useFakeRepository(_FakeKidJarRepository(failLoad: true));
      await _pumpRoute(tester, theme: ThemeMode.dark);

      expect(find.text('Oh no! Something went wrong.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.byType(KidScope), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('Try again really reloads and the jar comes back', (
      tester,
    ) async {
      final repo = _FakeKidJarRepository(failFirstWatch: true);
      await _useFakeRepository(repo);
      await _pumpRoute(tester);
      expect(find.text('Oh no! Something went wrong.'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await _settleStreams(tester);

      expect(repo.watches, 2, reason: 'the retry re-requests the load');
      expect(find.text('Oh no! Something went wrong.'), findsNothing);
      expect(find.text('My jar'), findsOneWidget);
      expect(find.text('£4.20'), findsOneWidget);
      expect(find.text('Lego Friends set'), findsOneWidget);
      expect(find.byType(JarHistoryCard), findsOneWidget);
      expect(find.text('+£3.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('VoiceOver/TalkBack can press the retry too', (tester) async {
      final semantics = tester.ensureSemantics();
      final repo = _FakeKidJarRepository(failFirstWatch: true);
      await _useFakeRepository(repo);
      await _pumpRoute(tester);

      final retry = find.bySemanticsLabel('Try again');
      expect(retry, findsOneWidget);
      expect(_hasTap(tester, retry), isTrue);

      final node = tester.getSemantics(retry);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await _settleStreams(tester);

      expect(repo.watches, 2);
      expect(find.text('My jar'), findsOneWidget);
      expect(find.text('Oh no! Something went wrong.'), findsNothing);
      semantics.dispose();
      await disposeApp(tester);
    });

    for (final width in <double>[320, 390, 430]) {
      for (final textScale in <double>[1, 1.3]) {
        for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
          testWidgets(
            'the failure state fits ${width.toInt()} px at $textScale in '
            '${theme.name}',
            (tester) async {
              await _useFakeRepository(_FakeKidJarRepository(failLoad: true));
              await _pumpRoute(
                tester,
                width: width,
                textScale: textScale,
                theme: theme,
              );

              expect(tester.takeException(), isNull);
              expect(find.text('Try again'), findsOneWidget);
              // The retry must stay a real control at every size, not a
              // squeezed sliver.
              final retry = tester.getSize(find.byType(NestKidButton));
              expect(
                retry.height,
                greaterThanOrEqualTo(NestDevice.tapKid),
                reason: 'kid tap target minimum',
              );
              expect(retry.width, greaterThanOrEqualTo(NestDevice.tapKid));
              expect(retry.width, lessThanOrEqualTo(width));
              // 20 px gutters, exactly like the loaded screen.
              final retryRect = tester.getRect(find.byType(NestKidButton));
              expect(retryRect.left, greaterThanOrEqualTo(0));
              expect(retryRect.right, lessThanOrEqualTo(width));
              await disposeApp(tester);
            },
          );
        }
      }
    }
  });

  group('K09 empty jar (real Seed.empty family)', () {
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets(
        'nothing owed, no goal and the one empty row in ${theme.name}',
        (tester) async {
          await _useEmptySeed();
          await _pumpRoute(tester, theme: theme);

          expect(tester.takeException(), isNull);
          expect(find.text('My jar'), findsOneWidget);
          expect(find.text('£0.00'), findsOneWidget);
          expect(find.text('coming on Saturday'), findsOneWidget);

          // No savings goal: no card, no bar, no "£0.00 to go".
          expect(find.byType(JarGoalCard), findsNothing);
          expect(find.byType(NestProgress), findsNothing);
          expect(find.textContaining('to go'), findsNothing);

          // The design's own empty row (`1_plan.md` §d).
          expect(find.byType(JarHistoryCard), findsOneWidget);
          expect(find.text('Nothing here yet'), findsOneWidget);
          expect(find.text('Finish a quest to fill your jar'), findsOneWidget);
          // Nothing has gone in, so nothing is added.
          expect(find.textContaining('+£'), findsNothing);
          expect(find.textContaining('+'), findsNothing);

          // The empty row still carries the design's pocket-money glyph
          // (shared `NestIcons.jarPocketMoney`), not a placeholder.
          final emptyGlyph = find.descendant(
            of: find.byType(JarHistoryCard),
            matching: find.byType(NestIcon),
          );
          expect(emptyGlyph, findsOneWidget);
          expect(
            tester.widget<NestIcon>(emptyGlyph).assetName,
            NestIcons.jarPocketMoney,
          );

          // The jar is genuinely empty and says so.
          expect(
            tester
                .widget<JarIllustration>(find.byType(JarIllustration))
                .percentLabel,
            0,
          );
          await disposeApp(tester);
        },
      );
    }

    testWidgets('the empty jar announces itself at 0%', (tester) async {
      final semantics = tester.ensureSemantics();
      await _useEmptySeed();
      await _pumpRoute(tester);

      expect(
        find.bySemanticsLabel('A glass money jar about 0% full of coins'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('£0.00 coming on Saturday'), findsOneWidget);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('the empty jar still goes back and still reaches a grown-up', (
      tester,
    ) async {
      await _useEmptySeed();
      await _pumpRoute(tester);

      await tester.tap(find.byType(NestIconButton));
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/kid-home');

      await _pumpRoute(tester);
      await tester.tap(find.byType(NestLockButton));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/parental-gate');
      await disposeApp(tester);
    });

    testWidgets('no overflow at 320 px / 1.3x', (tester) async {
      await _useEmptySeed();
      await _pumpRoute(tester, width: 320, textScale: 1.3);

      expect(tester.takeException(), isNull);
      expect(find.text('Nothing here yet'), findsOneWidget);
      // 20 px gutters hold when the content is the short empty column.
      final card = tester.getRect(find.byType(JarHistoryCard));
      expect(card.left, closeTo(NestSpacing.padSide, 2));
      expect(card.right, closeTo(320 - NestSpacing.padSide, 2));
      await disposeApp(tester);
    });
  });

  group('K09 tap targets and semantics', () {
    testWidgets('every control is at least the kid minimum of 56 px', (
      tester,
    ) async {
      await _pumpRoute(tester);

      for (final finder in <Finder>[
        find.byType(NestIconButton),
        find.byType(NestLockButton),
      ]) {
        final size = tester.getSize(finder);
        expect(
          size.width,
          greaterThanOrEqualTo(NestDevice.tapKid),
          reason: '$finder width',
        );
        expect(
          size.height,
          greaterThanOrEqualTo(NestDevice.tapKid),
          reason: '$finder height',
        );
      }
      await disposeApp(tester);
    });

    testWidgets('a tap well away from the glyph still works', (tester) async {
      await _pumpRoute(tester);

      // 5 px in from the left edge of the 56 px back box, level with its
      // centre: far outside the 26 px chevron, so only the box can catch it.
      // (`NestIconButton`'s `InkWell` is bounded by a `CircleBorder`, so the
      // box's corners are outside the circle by design — Material behaviour,
      // same as every other screen's icon button.)
      final back = tester.getRect(find.byType(NestIconButton));
      await tester.tapAt(Offset(back.left + 5, back.center.dy));
      await tester.pumpAndSettle();
      expect(currentPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    testWidgets('both icon buttons carry the design aria-labels', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _pumpRoute(tester);

      // `K09-jar.html:45` — `aria-label="Back"` / `aria-label="Grown-ups"`.
      for (final label in <String>['Back', 'Grown-ups']) {
        final finder = find.bySemanticsLabel(label);
        expect(finder, findsOneWidget, reason: label);
        final data = tester.getSemantics(finder).getSemanticsData();
        expect(data.label, label);
        expect(
          data.hasAction(SemanticsAction.tap),
          isTrue,
          reason: '$label must expose SemanticsAction.tap',
        );
        expect(data.flagsCollection.isButton, isTrue, reason: label);
      }
      // `NestIconButton` states `enabled: true` explicitly (RULES §8);
      // `NestLockButton` (a shared component in `core/design_system`, not K09
      // code) leaves the flag unset, which every platform reads as enabled.
      // The lock's contract that matters is the tap action, asserted above.
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Back'))
            .getSemanticsData()
            .flagsCollection
            .isEnabled
            .toBoolOrNull(),
        isTrue,
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('tapping a history row changes nothing', (tester) async {
      await _pumpRoute(tester);

      // A ledger row is display-only: tapping it must not navigate, throw or
      // change the state (`1_plan.md` §e).
      await tester.tap(find.text('Pocket money').first);
      await _settleStreams(tester);

      expect(currentPath(tester), _route);
      expect(tester.takeException(), isNull);
      expect(find.text('My jar'), findsOneWidget);
      await disposeApp(tester);
    });
  });
}
