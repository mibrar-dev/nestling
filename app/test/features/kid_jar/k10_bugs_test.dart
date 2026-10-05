// K10 · Payout day — bug proofs (Stage 6, iteration 2).
//
// The adversarial pass over the built K10 screen (`/payout-day`) and its
// logic. Open findings are parked with `skip:` so the suite stays green; run
// them red with:
//
//   cd app && flutter test --timeout 120s --run-skipped \
//     --plain-name 'K10-BUG' test/features/kid_jar/k10_bugs_test.dart
//
// Iteration 2 re-verified the iteration-1 findings against the fixed code:
// K10-BUG-1/1b (same-tick close guard), K10-BUG-2 (clamped percent) and
// K10-BUG-3 (320/1.3 copy fit) are FIXED — their proofs here are live and
// green, and the new probes at the bottom pin the fix behaviour. One new
// latent defect this pass found: K10-BUG-4 (the fund-card h2 still clamps a
// long goal name at 320/1.3), parked below.
//
// Numbering is K10's own registry (K09 keeps its 1..10). The clean probes
// stay green and back the "verified clean" table in
// `docs/screens/K10/6_bugs.md`.
//
// No screen code was changed in this stage. No simulator was booted,
// installed on, screenshot or driven (only stage 5 may). No `google_fonts`,
// no `DateTime.now()`, no wall-clock assertions; the clock is pinned to
// Sat 3 Oct 2026 09:41 Europe/London by `test/flutter_test_config.dart`.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/app/di.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_jar/data/kid_jar_repository_impl.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_entry.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_snapshot.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_summary.dart';
import 'package:nestling/features/kid_jar/domain/entities/payout_celebration.dart';
import 'package:nestling/features/kid_jar/domain/kid_jar_repository.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_bloc.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_event.dart';
import 'package:nestling/features/kid_jar/presentation/views/payout_day_view.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_amounts.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/payout_fund_card.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/payout_note.dart';
import 'package:nestling/features/pocket_money/data/pocket_money_repository_impl.dart';

import '../../test_scope.dart';

const String _route = '/payout-day';

/// Pumps `/payout-day` over the demo seed on a controllable surface.
Future<AppDatabase> _pumpRoute(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  await GetIt.instance.reset();
  final db = AppDatabase.memory();
  await configureDependencies(database: db);
  await Seed.demo(db);
  await GetIt.instance<AppSession>().refresh();
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(const NestlingApp(initialRoute: _route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  return db;
}

/// Every rendered string — the proofs below match whole lines.
List<String> _texts(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .where((t) => t.isNotEmpty)
    .toList();

/// JS-style WCAG relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

const PayoutCelebration _mayaCelebration = PayoutCelebration(
  childId: 'maya',
  nickname: 'Maya',
  paidPence: 380,
  movedPence: 550,
  goalTitle: 'Lego Friends set',
  goalSavedPence: 1550,
  goalTargetPence: 2499,
  pipStyle: 'mochi',
  pipSkin: 'sunny',
  pipAccessory: 'none',
  pipStage: 3,
);

/// A repository whose `watchLatestPayout()` hands out a fresh broadcast
/// stream per call and reports how many of them still have a listener — the
/// only way to answer "was the previous subscription released?" for a stream
/// that never completes (K09-BUG-7's instrument, now aimed at K10).
class _CountingPayoutRepository implements KidJarRepository {
  final List<StreamController<PayoutCelebration?>> controllers =
      <StreamController<PayoutCelebration?>>[];

  int get watches => controllers.length;
  int get liveSubscriptions => controllers.where((c) => c.hasListener).length;

  @override
  Stream<PayoutCelebration?> watchLatestPayout() {
    final controller = StreamController<PayoutCelebration?>.broadcast();
    controllers.add(controller);
    return controller.stream;
  }

  @override
  Future<List<JarEntry>> getItems() async => const <JarEntry>[];

  @override
  Stream<List<JarEntry>> watchItems() => const Stream<List<JarEntry>>.empty();

  @override
  Stream<JarSnapshot> watchJar() => const Stream<JarSnapshot>.empty();

  @override
  Stream<JarSummary> watchSummary(String childId) =>
      const Stream<JarSummary>.empty();

  @override
  Future<void> moveToSavings({
    required String childId,
    required String goalId,
    required int amountPence,
  }) async {}

  Future<void> shutDown() async {
    for (final controller in controllers) {
      await controller.close();
    }
  }
}

/// The real bundled faces, so the layout probes below measure the design's
/// Nunito metrics (the geometry test's loader).
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

void main() {
  setUpAll(_loadBundledFonts);

  // -------------------------------------------------------------------------
  // K10-BUG-1 — minor (latent) — FIXED in iteration 2 (same-tick close guard).
  // This proof is LIVE and green: it fails on the iteration-1 build.
  // -------------------------------------------------------------------------
  //
  // `_onPayoutRequested` (kid_jar_bloc.dart:88-105) opens with
  // `await previous?.cancel()`. Even with `previous == null` that await
  // suspends the handler for a microtask, so a `close()` landing in the
  // window finds `_payoutSub` still null, cancels nothing, and the handler
  // then subscribes to `watchLatestPayout()` AFTER the bloc is closed. The
  // subscription is never cancelled and the first emission calls
  // `add(KidJarPayoutReceived(…))` on the closed bloc, which throws
  // `Bad state: Cannot add new events after calling close` from inside the
  // stream callback (an unhandled async error).
  //
  // This is the K09-BUG-7 defect's exact twin — the payout half of
  // `KidJarBloc` never received the guard the jar half got. Latent: no
  // gesture can close the route inside the microtask window (the first frame
  // must render before any control exists), so only programmatic teardown
  // (a future caller, or a test harness) reaches it.
  test('K10-BUG-1: a payout request then close releases the subscription', () async {
    final repo = _CountingPayoutRepository();
    final bloc = KidJarBloc(repository: repo)
      ..add(const KidJarPayoutRequested());
    await bloc.close();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(
      repo.liveSubscriptions,
      0,
      reason:
          'K10-BUG-1: the payout handler suspended at `await previous?.cancel()` '
          'let close() run first; it then subscribed after close (live=1) and '
          'that subscription is never cancelled',
    );
    await repo.shutDown();
  });

  test(
    'K10-BUG-1b: the leaked payout subscription cannot emit after close',
    () async {
      final repo = _CountingPayoutRepository();
      final bloc = KidJarBloc(repository: repo)
        ..add(const KidJarPayoutRequested());
      await bloc.close();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // The first emission on the leaked subscription reaches
      // `add(KidJarPayoutReceived(…))` on the closed bloc; pre-fix this is an
      // unhandled `Bad state: Cannot add new events after calling close` and
      // fails the test. Post-fix there is no leaked subscription to emit into.
      for (final controller in repo.controllers.where((c) => c.hasListener)) {
        controller.add(_mayaCelebration);
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await repo.shutDown();
    },
  );

  // -------------------------------------------------------------------------
  // K10-BUG-2 — minor — FIXED in iteration 2 (percent follows the clamped
  // fraction). This proof is LIVE and green: it fails on the iteration-1
  // build, where a goal saved past its target reads "142% there!" beside a
  // full bar and "£0.00 to go".
  // -------------------------------------------------------------------------
  //
  // `PayoutCelebration.goalFraction` is clamped to 0…1 (the bar is honest),
  // and `goalRemainingPence` is clamped at 0 (`£0.00 to go`), but
  // `goalPercent` (payout_celebration.dart:61-64) divides the RAW saved
  // amount: `((goalSavedPence * 100) / goalTargetPence).round()`. Saved past
  // the target therefore renders a percent over 100 — "142% there!" under a
  // 100%-full progress bar, next to "£0.00 to go" — and the same figure is
  // announced in the progress semantics ("142% of the … saved").
  //
  // K09's own card clamps first (`JarGoalCard.percent` is
  // `(fraction * 100).round()` with `fraction` clamped), so the sibling
  // screen reads "100% there!" for the same data. Reachable through the real
  // product API: `PocketMoneyRepositoryImpl.recordPayout` caps the move at
  // the payout but never at the goal's remainder (recordPayout writes
  // `savedPence: goal.savedPence + movePence` unbounded — the same hole
  // K09-BUG-4 fixed in `moveToSavings`), so a payout whose move overshoots
  // the goal's remainder (here 2000p into a 949p remainder) lands saved at
  // 3550 of 2499.
  testWidgets(
    'K10-BUG-2: a goal saved past its target never reads over 100% there',
    (tester) async {
      final db = await _pumpRoute(tester);
      final money = PocketMoneyRepositoryImpl(db: db);
      await money.recordPayout(
        childId: 'maya',
        amountPence: 2000,
        savingsMovePence: 2000,
        goalId: 'goal-lego',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Sanity: the overshoot really is on screen (3550 of 2499 = 142%).
      expect(find.text('£35.50'), findsOneWidget);
      // K10-BUG-2 (shared/kid_bugs): the design has no reached-state copy,
      // so `£0.00 to go` is replaced by `Goal reached!` beside `100% there!`.
      expect(find.text('Goal reached!'), findsOneWidget);
      expect(find.text('£0.00 to go'), findsNothing);

      final percents = _texts(tester)
          .where((t) => t.endsWith('% there!'))
          .toList();
      expect(
        percents.where((t) => t != '100% there!'),
        isEmpty,
        reason:
            'K10-BUG-2: saved 3550 of target 2499 renders "${percents.join(" / ")}" '
            'under a full progress bar with "Goal reached!"; the percent must be '
            'clamped like the K09 `JarGoalCard.percent` (fraction * 100, where '
            'fraction is clamped to 0…1) so the caption and the bar agree',
      );
      await disposeApp(tester);
    },
  );

  // -------------------------------------------------------------------------
  // K10-BUG-4 — minor (latent) — the fund-card h2 still clamps a long goal
  // name at 320 px / 1.3×
  // -------------------------------------------------------------------------
  //
  // The iteration-2 K10-BUG-3 fix freed the NOTE title (`payout_note.dart`
  // dropped `maxLines: 2`) but the fund card's h2 kept its cap
  // (`payout_fund_card.dart:49-54` — `maxLines: 2, overflow: ellipsis`).
  // `K10-payout-day.html` sets no max-lines/line-clamp anywhere on the
  // screen (the K10-BUG-3 rationale), and the design's `.k10-fund h2` grows
  // with content like every other card. A plausible UK wishlist name —
  // `Maximilian-Alexander's Nintendo Switch 2 game`, the same fixture K09's
  // clean probe uses — needs THREE lines in the 242 px card at 320/1.3, so
  // the goal name loses its tail.
  //
  // Latent: savings goals have no writer in `lib/` today (only `Seed.demo`
  // inserts them; `recordPayout` and `moveToSavings` update `savedPence`
  // only; P15 deletes them with a child), so this needs a future goal
  // editor or imported data. It is the one string on the screen still
  // clamped against the design's own "no clamp" rule, and the fix is the
  // same one the note title already got.
  testWidgets('K10-BUG-4: a long goal name is never clamped in the fund card', (
    tester,
  ) async {
    final db = await _pumpRoute(tester, width: 320, textScale: 1.3);
    await (db.update(
      db.savingsGoals,
    )..where((g) => g.id.equals('goal-lego'))).write(
      const SavingsGoalsCompanion(
        title: Value('Maximilian-Alexander’s Nintendo Switch 2 game'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final h2 = tester.renderObject<RenderParagraph>(
      find.text('Maximilian-Alexander’s Nintendo Switch 2 game'),
    );
    expect(
      h2.didExceedMaxLines,
      isFalse,
      reason:
          'K10-BUG-4: the fund-card h2 keeps maxLines: 2, so a long goal '
          'name is ellipsized at 320 px / 1.3× while the sibling note title '
          'wraps freely (K10-BUG-3 fix) and the design clamps nothing. Drop '
          'the cap (or raise it) so the card grows with content',
    );
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // CLEAN probes — kept green so the 6_bugs.md "verified clean" list is
  // reproducible.
  // -------------------------------------------------------------------------
  group('K10 clean probes (stay green)', () {
    testWidgets('worst-case names and amounts render without overflow', (
      tester,
    ) async {
      final db = await _pumpRoute(tester, width: 320, textScale: 1.3);
      // The longest plausible UK name and a seven-figure goal, on the
      // narrowest supported screen with the largest supported text scale.
      // NOTE: this probe asserts "no overflow / no crash", not copy fit —
      // the seeded copy truncation at this cell is K10-BUG-3, owned and
      // proven by the stage-3 matrix file.
      await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(nickname: Value('Maximilian-Alexander')),
      );
      await (db.update(
        db.savingsGoals,
      )..where((g) => g.id.equals('goal-lego'))).write(
        const SavingsGoalsCompanion(
          title: Value('Maximilian-Alexander’s Nintendo Switch 2 game'),
          savedPence: Value(999999999),
          targetPence: Value(1999999999),
        ),
      );
      await (db.update(db.ledgerEntries)..where((l) => l.type.equals('payout')))
          .write(const LedgerEntriesCompanion(amountPence: Value(-999999999)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final scroll = find.byType(Scrollable).first;
      for (var i = 0; i < 10; i++) {
        await tester.drag(scroll, const Offset(0, -200));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      expect(find.byType(PayoutNote), findsNWidgets(2));
      expect(find.byType(PayoutFundCard), findsOneWidget);
      expect(find.text('Thanks Mum!'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('a double-tap on Thanks Mum! ends up home exactly once', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final thanks = find.text('Thanks Mum!');
      await tester.tap(thanks);
      await tester.tap(thanks, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/kid-home');
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a double-tap on the lock opens exactly one gate', (
      tester,
    ) async {
      await _pumpRoute(tester);
      final lock = find.byType(NestLockButton);
      await tester.tap(lock);
      await tester.tap(lock, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/parental-gate');

      // One pop returns to the payout day: a second gate would keep us there.
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      expect(pushedPath(tester), _route);
      await disposeApp(tester);
    });

    testWidgets('an active-child switch swaps the whole celebration', (
      tester,
    ) async {
      final db = await _pumpRoute(tester);
      await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
        const AppStateCompanion(activeChildId: Value('leo')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Leo: paid 190, no move (note 2 hidden), no goal.
      expect(find.text('Mum marked £1.90 as paid'), findsOneWidget);
      expect(find.text('Just like you asked'), findsNothing);
      expect(find.byType(PayoutNote), findsOneWidget);
      expect(find.text('Pip says well done, Leo!'), findsOneWidget);
      expect(find.textContaining('Maya'), findsNothing);
      await disposeApp(tester);
    });

    test(
      'the companion move counts from the payout instant, never before',
      () async {
        final db = AppDatabase.memory();
        addTearDown(db.close);
        await Seed.demo(db);

        Future<void> payout(DateTime at, int pence) => db
            .into(db.ledgerEntries)
            .insert(
              LedgerEntriesCompanion.insert(
                familyId: Seed.familyId,
                childId: 'maya',
                type: 'payout',
                amountPence: -pence,
                note: const Value('Paid · probe'),
                date: Value(at),
                dateTz: const Value('Europe/London'),
              ),
            );
        Future<void> move(DateTime at, int pence) => db
            .into(db.ledgerEntries)
            .insert(
              LedgerEntriesCompanion.insert(
                familyId: Seed.familyId,
                childId: 'maya',
                type: 'savings_move',
                amountPence: pence,
                note: const Value('Jar → probe goal'),
                date: Value(at),
                dateTz: const Value('Europe/London'),
              ),
            );

        // The seed's 26 Sep payout is no longer the latest one.
        final at = DateTime.utc(2026, 10, 3, 8, 41);
        await payout(at, 500);
        await move(at.subtract(const Duration(seconds: 1)), 300);
        final repo = KidJarRepositoryImpl(db: db);
        var celebration = await repo.watchLatestPayout().first;
        expect(celebration!.paidPence, 500);
        expect(
          celebration.movedPence,
          isNull,
          reason: 'a move one second BEFORE the payout is not its companion',
        );

        // At the exact instant it is (P13 writes both rows with one `now`).
        await move(at, 300);
        celebration = await repo.watchLatestPayout().first;
        expect(celebration!.movedPence, 300);
      },
    );

    test('a restart keeps the celebration (file database reopened)', () async {
      final dir = Directory.systemTemp.createTempSync('k10_bugs');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/nestling.db');

      final first = AppDatabase(NativeDatabase(file));
      await Seed.demo(first);
      await PocketMoneyRepositoryImpl(db: first).recordPayout(
        childId: 'maya',
        amountPence: 420,
        savingsMovePence: 100,
        goalId: 'goal-lego',
      );
      await first.close();

      final second = AppDatabase(NativeDatabase(file));
      addTearDown(second.close);
      final celebration = await KidJarRepositoryImpl(db: second)
          .watchLatestPayout()
          .first;
      expect(celebration!.paidPence, 420);
      expect(celebration.movedPence, 100);
      expect(celebration.goalSavedPence, 1650);
      expect(celebration.nickname, 'Maya');
    });

    test('the K10 text pairs meet WCAG AA in both themes', () {
      const light = NestColors.light;
      const dark = NestColors.dark;
      for (final scheme in <(String, NestSchemeColors)>[
        ('light', light),
        ('dark', dark),
      ]) {
        final (name, c) = scheme;
        final pairs = <(String, Color, Color)>[
          ('title ink/skyTop', c.ink, c.kidSkyTop),
          ('note title ink/surface', c.ink, c.surface),
          ('note sub ink2/surface', c.ink2, c.surface),
          ('fund title/amounts ink/coinTint', c.ink, c.coinTint),
          ('fund captions ink2/coinTint', c.ink2, c.coinTint),
          ('check glyph leafInk/leafTint', c.leafInk, c.leafTint),
          ('moved glyph ink/lilacTint', c.ink, c.lilacTint),
          ('bar label onLeaf/leaf', c.onLeaf, c.leaf),
          ('empty body ink2/skyBottom', c.ink2, c.kidSkyBottom),
          ('empty heading ink/skyBottom', c.ink, c.kidSkyBottom),
        ];
        for (final (label, fg, bg) in pairs) {
          expect(
            _contrast(fg, bg),
            greaterThanOrEqualTo(4.5),
            reason: '$name $label',
          );
        }
      }
    });

    test('integer pence format exactly (no float drift)', () {
      String pounds(int pence) =>
          '£${pence ~/ 100}.${(pence % 100).toString().padLeft(2, '0')}';
      for (var pence = 0; pence <= 300000; pence++) {
        expect(jarPounds(pence), pounds(pence), reason: 'jarPounds($pence)');
      }
      for (final pence in <int>[
        0,
        1,
        99,
        100,
        420,
        949,
        1000,
        2499,
        99999999,
      ]) {
        expect(jarPounds(pence), pounds(pence), reason: '($pence)');
      }
    });

    testWidgets('closing the screen mid-load emits nothing after close', (
      tester,
    ) async {
      final db = await _pumpRoute(tester);
      await disposeApp(tester); // the payout watch stream is still live
      await (db.update(db.savingsGoals)..where((g) => g.id.equals('goal-lego')))
          .write(const SavingsGoalsCompanion(savedPence: Value(1600)));
      await db
          .into(db.ledgerEntries)
          .insert(
            LedgerEntriesCompanion.insert(
              familyId: Seed.familyId,
              childId: 'maya',
              type: 'payout',
              amountPence: -100,
              note: const Value('Paid · probe'),
              date: Value(DateTime.utc(2026, 10, 3, 8, 41)),
              dateTz: const Value('Europe/London'),
            ),
          );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('an out-of-range Pip stage is clamped, never a crash', (
      tester,
    ) async {
      final db = await _pumpRoute(tester);
      await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(
          pipStage: Value(9),
          pipStyle: Value('not-a-style'),
          pipSkin: Value('not-a-skin'),
          pipAccessory: Value('not-an-accessory'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final pip = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(pip.stage, 4, reason: 'clamp(1, 4)');
      expect(pip.style, PipStyle.mochi, reason: 'unknown style falls back');
      expect(pip.skin, PipSkin.sunny, reason: 'unknown skin falls back');
      expect(pip.accessory, PipAccessory.none, reason: 'unknown accessory');
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a parent-mode deep link renders without a mode crash', (
      tester,
    ) async {
      // Kid routes are deliberately not mode-guarded (K02 convention: a
      // parent may preview a kid screen); the guard that matters is the
      // parent-only redirect in kid mode, which the router owns.
      await GetIt.instance.reset();
      final db = AppDatabase.memory();
      await configureDependencies(database: db);
      await Seed.demo(db);
      await GetIt.instance<AppSession>().refresh();
      GetIt.instance<AppModeController>().selectMode(AppMode.parent);
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const NestlingApp(initialRoute: _route));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(PayoutDayView), findsOneWidget);
      expect(find.text('Mum marked £3.80 as paid'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // ITERATION-2 probes — the fix behaviour, pinned (all stay green).
  // -------------------------------------------------------------------------
  group('K10 iteration-2 close races (stay green)', () {
    test('an emission racing close leaves no leak and no error', () async {
      final repo = _CountingPayoutRepository();
      final bloc = KidJarBloc(repository: repo)
        ..add(const KidJarPayoutRequested());
      await Future<void>.delayed(Duration.zero);
      expect(repo.liveSubscriptions, 1);

      // The event is in flight when close() starts; the guard and the
      // cancel must leave nothing live and throw nothing.
      repo.controllers.last.add(_mayaCelebration);
      await bloc.close();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repo.liveSubscriptions, 0);
      await repo.shutDown();
    });

    test('a stream error racing close leaves no leak and no error', () async {
      final repo = _CountingPayoutRepository();
      final bloc = KidJarBloc(repository: repo)
        ..add(const KidJarPayoutRequested());
      await Future<void>.delayed(Duration.zero);
      repo.controllers.last.addError(StateError('racing error'));
      await bloc.close();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repo.liveSubscriptions, 0);
      await repo.shutDown();
    });

    test('a reload racing close leaves no leak and no second watch', () async {
      final repo = _CountingPayoutRepository();
      final bloc = KidJarBloc(repository: repo)
        ..add(const KidJarPayoutRequested());
      await Future<void>.delayed(Duration.zero);

      // The second load is paused in `await previous.cancel()` when close
      // lands; the old sub is cancelled by the handler, the new one is
      // never created (the `_closing` re-check).
      bloc.add(const KidJarPayoutRequested());
      repo.controllers.first.add(_mayaCelebration);
      await bloc.close();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repo.liveSubscriptions, 0);
      await repo.shutDown();
    });

    test('six same-tick requests then close never subscribe', () async {
      final repo = _CountingPayoutRepository();
      final bloc = KidJarBloc(repository: repo);
      for (var i = 0; i < 6; i++) {
        bloc.add(const KidJarPayoutRequested());
      }
      await bloc.close();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Every queued handler saw `_closing` before it emitted or subscribed.
      expect(repo.watches, 0);
      expect(repo.liveSubscriptions, 0);
      await repo.shutDown();
    });

    test('close is idempotent after an emission', () async {
      final repo = _CountingPayoutRepository();
      final bloc = KidJarBloc(repository: repo)
        ..add(const KidJarPayoutRequested());
      await Future<void>.delayed(Duration.zero);
      repo.controllers.last.add(_mayaCelebration);
      await bloc.close();
      await bloc.close();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repo.liveSubscriptions, 0);
      await repo.shutDown();
    });
  });

  group('K10 iteration-2 layout fixes (stay green)', () {
    testWidgets('the seeded note title and money render whole at 320 x 1.3', (
      tester,
    ) async {
      // K10-BUG-3 regression: the note title wraps unclamped and the amount
      // is shrunk to fit by its FittedBox, instead of being ellipsized.
      await _pumpRoute(tester, width: 320, textScale: 1.3);
      bool exceeded(String line) => tester
          .renderObject<RenderParagraph>(find.text(line, skipOffstage: false))
          .didExceedMaxLines;
      expect(exceeded('£5.50 went into your Lego Friends set'), isFalse);
      expect(exceeded('£9.49 to go'), isFalse);
      await disposeApp(tester);
    });

    testWidgets('the amount slot is identity at 390 and scales at 320 x 1.3', (
      tester,
    ) async {
      // 390/1.0 (the design cell): the amount fits its slot, so the
      // FittedBox renders at scale 1 — pixel-identical to the pre-fix build.
      await _pumpRoute(tester);
      final fitted390 = find.ancestor(
        of: find.text('£9.49 to go'),
        matching: find.byType(FittedBox),
      );
      final child390 = tester.getSize(find.text('£9.49 to go')).width;
      final box390 = tester.getSize(fitted390).width;
      expect(box390, closeTo(child390, 0.1), reason: 'scale 1.0 at 390');
      await disposeApp(tester);

      // 320/1.3: the slot is narrower than the text, so the money string is
      // scaled to fit (never cut) — and only barely.
      await _pumpRoute(tester, width: 320, textScale: 1.3);
      final fitted320 = find.ancestor(
        of: find.text('£9.49 to go'),
        matching: find.byType(FittedBox),
      );
      final child320 = tester.getSize(find.text('£9.49 to go')).width;
      final box320 = tester.getSize(fitted320).width;
      expect(box320, lessThan(child320), reason: 'scaled at 320/1.3');
      expect(box320 / child320, greaterThan(0.9), reason: 'barely shrunk');
      await disposeApp(tester);
    });

    testWidgets(
      'an unbroken goal word wraps by character, never past the card',
      (tester) async {
        // The K10-BUG-3 fix removed the note-title ellipsis; this proves that
        // did not trade truncation for a paint overflow on unbreakable words.
        final db = await _pumpRoute(tester, width: 320, textScale: 1.3);
        const word = 'Supercalifragilisticexpialidocious';
        await (db.update(db.savingsGoals)
              ..where((g) => g.id.equals('goal-lego')))
            .write(const SavingsGoalsCompanion(title: Value(word)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final h2 = tester.renderObject<RenderParagraph>(find.text(word));
        final boxes = h2.getBoxesForSelection(
          const TextSelection(baseOffset: 0, extentOffset: word.length),
        );
        final maxRight = boxes.fold<double>(
          0,
          (m, b) => b.right > m ? b.right : m,
        );
        expect(maxRight, lessThanOrEqualTo(h2.size.width + 0.5));
        await disposeApp(tester);
      },
    );
  });
}
