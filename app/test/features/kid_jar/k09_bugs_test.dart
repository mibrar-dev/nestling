// K09 · My jar — bug proofs (Stage 6, iteration 1).
//
// Adversarial pass over `kid_jar` K09: data edges, rapid double taps, back
// navigation and deep links, restart persistence, mode guards, dark contrast,
// 320 px + 1.3 scale, async gaps, Europe/London + BST, integer money, owner
// rules. The pass found THREE defects (K09-BUG-4..6); the iteration-2 build
// fixed all three, so their proofs below run LIVE — no `skip:` remains — and
// `--run-skipped` is no longer needed:
//
//   cd app && flutter test --timeout 120s test/features/kid_jar/k09_bugs_test.dart
//
// Numbering continues the registry: stages 3–5 already own K09-BUG-1 (retry
// stacks subscriptions; red proofs in `kid_jar_bloc_test.dart`), K09-BUG-2
// (the `coming on Saturday` colour; red proofs in `my_jar_view_test.dart`)
// and K09-BUG-3 (quest-bonus rows show the wrong kid glyph; red proof in
// `my_jar_view_test.dart`). This stage adds:
//
//   K09-BUG-4  major — a reached/exceeded savings goal still asks for money:
//                      "£6.51 to go" after £31.50 was saved against a £24.99
//                      goal (remaining = target − saved is unclamped and
//                      `jarPounds` drops the sign). Reachable through P13's
//                      payout "move to savings" (clamped to the payout, never
//                      to the goal's remainder).
//   K09-BUG-5  minor — a negative owed (a signed ledger correction) renders as
//                      a POSITIVE hero amount ("£0.80 coming on Saturday")
//                      while the list row correctly reads "−£5.00".
//   K09-BUG-6  minor — with a home indicator the scroll tail reserves the
//                      inset twice (SafeArea 34 + homeH 34 + s8 32 = 100 vs
//                      the design's 34 + 32 = 66), so the footer sits 34 px
//                      high when the child scrolls to the end.
//
// The final group pins the probes that came back CLEAN so the "verified
// clean" table in `docs/screens/K09/6_bugs.md` is reproducible: double taps,
// the BST week boundary, integer-pence formatting, dark-mode contrast and
// file-DB restart persistence.
//
// No screen code was changed in this stage. No simulator was used.

import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/app/di.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_jar/data/kid_jar_repository_impl.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_snapshot.dart';
import 'package:nestling/features/kid_jar/presentation/views/my_jar_view.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_amounts.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_goal_card.dart';

import '../../test_scope.dart';

const String _route = '/my-jar';

/// Pumps `/my-jar` (parent-mode deep link, like the view tests) over the demo
/// seed, optionally with a real home-indicator inset.
Future<AppDatabase> _pumpRoute(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  String route = _route,
  double homeInset = 0,
}) async {
  await GetIt.instance.reset();
  final db = AppDatabase.memory();
  await configureDependencies(database: db);
  await Seed.demo(db);
  await GetIt.instance<AppSession>().refresh();
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  if (homeInset > 0) {
    // `SafeArea` reads `MediaQuery.padding`; the screenshot device reports
    // both padding and viewPadding 34.
    tester.view.padding = FakeViewPadding(bottom: homeInset * 3);
    tester.view.viewPadding = FakeViewPadding(bottom: homeInset * 3);
  }
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  return db;
}

/// Reads every rendered text — the proofs below match whole strings, so one
/// list makes the assertion style uniform.
List<String> _texts(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? '')
    .where((t) => t.isNotEmpty)
    .toList();

/// JS-style WCAG relative luminance for a Flutter colour.
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

void main() {
  // -------------------------------------------------------------------------
  // K09-BUG-4 — major — a reached goal still reads "£6.51 to go"
  // -------------------------------------------------------------------------
  //
  // `JarGoalCard.remainingPence` is `target − saved` with no lower clamp and
  // `jarPounds` prints the absolute value, so once savings pass the target the
  // card claims a growing amount is STILL MISSING: here £31.50 is saved of
  // £24.99 and the card says "£6.51 to go" while the same card says
  // "100% there!". `JarIllustration`/`NestProgress` both clamp, so only the
  // "to go" line lies.
  //
  // Reachable in the product: P13's "move to savings" credits up to the whole
  // payout to the child's goal (`payout_view.dart` `_submit` clamps `move` to
  // `entry.value`, never to the goal's remainder; `recordPayout` in
  // `pocket_money_repository_impl.dart` then writes
  // `savedPence: goal.savedPence + movePence` unbounded). The same is true of
  // this feature's own `moveToSavings`, which also never looks at the target.
  testWidgets('K09-BUG-4: a reached goal never asks for more money', (
    tester,
  ) async {
    final db = await _pumpRoute(tester);

    // A payer credits Maya's £24.99 goal past the target (1550 + 1600).
    await (db.update(db.savingsGoals)..where((g) => g.id.equals('goal-lego')))
        .write(const SavingsGoalsCompanion(savedPence: Value(3150)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // The contradiction, on one card: fully saved, and a "to go" figure.
    expect(find.text('£31.50'), findsOneWidget);
    expect(find.text('100% there!'), findsOneWidget);
    final toGo = _texts(tester).where((t) => t.endsWith(' to go')).toList();
    expect(
      toGo.where((t) => t != '£0.00 to go'),
      isEmpty,
      reason:
          'K09-BUG-4: saved 3150 of target 2499 is OVER the goal, so no '
          'positive "to go" figure may be shown — the card renders '
          '"£6.51 to go" because remaining (2499 − 3150) is unclamped and '
          '`jarPounds` prints its absolute value',
    );
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // K09-BUG-5 — minor (latent) — a negative owed is announced as positive
  // -------------------------------------------------------------------------
  //
  // The ledger is signed (`LedgerEntries.amountPence` — "Signed pence"), and
  // the K09 list renders a negative row correctly as "−£5.00" (U+2212), but
  // the hero amount goes through `jarPounds`, which drops the sign. With a
  // −500p correction in the current period, Maya is owed −80p and the screen
  // says "£0.80 coming on Saturday".
  //
  // Latent: no current screen writes a negative quest_bonus, so this is a
  // robustness defect, not a flow the demo seed reaches.
  testWidgets('K09-BUG-5: a negative owed is never shown as money coming', (
    tester,
  ) async {
    final db = await _pumpRoute(tester);

    // Maya is owed 420; a −500p correction makes the period total −80.
    await db
        .into(db.ledgerEntries)
        .insert(
          LedgerEntriesCompanion.insert(
            familyId: Seed.familyId,
            childId: 'maya',
            type: 'quest_bonus',
            amountPence: -500,
            note: const Value('Correction'),
            date: Value(DateTime.utc(2026, 10, 3, 9, 30)),
            dateTz: const Value('Europe/London'),
          ),
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // The list row keeps its sign…
    expect(find.text('−£5.00'), findsOneWidget);
    // …while the hero must not claim £0.80 is coming.
    expect(
      find.text('£0.80'),
      findsNothing,
      reason:
          'K09-BUG-5: owed is −80p, so "£0.80 coming on Saturday" is a '
          'positive rendering of a negative balance (`jarPounds` abs). '
          'Clamp owed at 0 in `_summarize` (→ "£0.00") or render the minus',
    );
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // K09-BUG-6 — minor — the scroll tail reserves the home inset twice
  // -------------------------------------------------------------------------
  //
  // The design keeps the 34 px home indicator as a flex sibling AFTER the
  // scroll (`.home-indicator`, components.css:51) and the scroll's own tail is
  // `--s8` = 32 (`.scroll`, components.css:65). The view instead wraps the
  // Column in `SafeArea(bottom: true)` AND pads the scroll tail with
  // `NestDevice.homeH + NestSpacing.s8` (34 + 32), so the last content sits
  // 34 px higher than the design when scrolled to the end (K08 solves this
  // with the tail alone — no bottom SafeArea).
  //
  // Initial-frame geometry is unaffected, which is why the stage-5 checks did
  // not see it; it is measured at maxScrollExtent.
  testWidgets('K09-BUG-6: the footer keeps the design row at max scroll', (
    tester,
  ) async {
    await _pumpRoute(tester, homeInset: 34);

    final scroll = find.byType(Scrollable).first;
    await tester.drag(scroll, const Offset(0, -4000));
    await tester.pumpAndSettle();

    // Design: scroll viewport ends at 844 − 34 (home indicator); its tail is
    // the 32 px `--s8`, so the footer's bottom = 810 − 32 = 778.
    final footer = tester.getRect(find.text(MyJarCopy.footer));
    expect(
      footer.bottom,
      closeTo(778, 2),
      reason:
          'K09-BUG-6: with the 34 px home inset the footer bottom measures '
          '744.0 (SafeArea 34 + homeH 34 + s8 32 = 100 above the edge) '
          "instead of the design's 778 (34 + 32 = 66)",
    );
    await disposeApp(tester);
  });

  // -------------------------------------------------------------------------
  // CLEAN probes — kept green so the 6_bugs.md "verified clean" list is
  // reproducible.
  // -------------------------------------------------------------------------
  group('K09 clean probes (stay green)', () {
    testWidgets('a double-tap back pops exactly one route', (tester) async {
      await _pumpRoute(tester, route: '/kid-home');
      await tester.tap(find.text('My jar'));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), _route);

      final back = find.byType(NestIconButton);
      await tester.tap(back);
      await tester.tap(back, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    testWidgets('a double-tap lock opens exactly one gate', (tester) async {
      await _pumpRoute(tester);
      final lock = find.byType(NestLockButton);
      await tester.tap(lock);
      await tester.tap(lock, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/parental-gate');

      // One pop returns to the jar: a second gate would keep us on the gate.
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      expect(pushedPath(tester), _route);
      await disposeApp(tester);
    });

    testWidgets('long goal + huge amounts fit at 320 x 1.3', (tester) async {
      final db = await _pumpRoute(tester, width: 320, textScale: 1.3);
      await (db.update(
        db.savingsGoals,
      )..where((g) => g.id.equals('goal-lego'))).write(
        const SavingsGoalsCompanion(
          title: Value('Maximilian-Alexander’s Nintendo Switch 2 game'),
          savedPence: Value(999999999),
          targetPence: Value(1999999999),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final scroll = find.byType(Scrollable).first;
      for (var i = 0; i < 8; i++) {
        await tester.drag(scroll, const Offset(0, -200));
        await tester.pump();
      }
      expect(tester.takeException(), isNull);
      expect(find.text('My jar'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('an active-child switch swaps the whole jar atomically', (
      tester,
    ) async {
      final db = await _pumpRoute(tester);
      await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
        const AppStateCompanion(activeChildId: Value('leo')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      // One frame holds Leo's figures only — never Maya's summary with
      // Leo's rows (the snapshot comes from one atomic emission).
      expect(find.text('£2.10'), findsOneWidget);
      expect(find.text('£4.20'), findsNothing);
      expect(find.byType(JarGoalCard), findsNothing); // Leo has no goal
      await disposeApp(tester);
    });

    testWidgets('closing the screen mid-load emits nothing after close', (
      tester,
    ) async {
      final db = await _pumpRoute(tester);
      await disposeApp(tester); // bloc disposed with the watch stream live
      await (db.update(db.savingsGoals)..where((g) => g.id.equals('goal-lego')))
          .write(const SavingsGoalsCompanion(savedPence: Value(1600)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    test('BST week boundaries map This/Last correctly', () async {
      // The pinned anchor is restored no matter what.
      Seed.anchorOverride = DateTime.utc(2026, 10, 3);
      addTearDown(() => Seed.anchorOverride = DateTime.utc(2026, 10, 3));

      final db = AppDatabase.memory();
      addTearDown(db.close);
      await Seed.demo(db);
      final repo = KidJarRepositoryImpl(db: db);

      Future<void> base(DateTime utc) => db
          .into(db.ledgerEntries)
          .insert(
            LedgerEntriesCompanion.insert(
              familyId: Seed.familyId,
              childId: 'maya',
              type: 'weekly_base',
              amountPence: 1,
              note: const Value('boundary probe'),
              date: Value(utc),
              dateTz: const Value('Europe/London'),
            ),
          );

      // London is BST. Week starts Mon 19 Oct 00:00 BST = Sun 18 Oct 23:00Z.
      Seed.anchorOverride = DateTime.utc(2026, 10, 21);
      await base(DateTime.utc(2026, 10, 18, 23, 30)); // Mon 00:30 BST
      await base(DateTime.utc(2026, 10, 18, 22, 30)); // Sun 23:30 BST
      var details = (await repo.watchJar().first).items
          .take(2)
          .map((e) => e.detail)
          .toList();
      expect(details, <String>['This Monday', 'Last Sunday']);

      // London is GMT. Week starts Mon 26 Oct 00:00 GMT = 26 Oct 00:00Z.
      Seed.anchorOverride = DateTime.utc(2026, 10, 27);
      await base(DateTime.utc(2026, 10, 25, 23, 30)); // Sun 23:30 GMT
      await base(DateTime.utc(2026, 10, 26, 0, 30)); // Mon 00:30 GMT
      details = (await repo.watchJar().first).items
          .take(2)
          .map((e) => e.detail)
          .toList();
      expect(details, <String>['This Monday', 'Last Sunday']);
    });

    test('integer pence format exactly (no float drift)', () {
      String pounds(int pence) =>
          '£${pence ~/ 100}.${(pence % 100).toString().padLeft(2, '0')}';
      for (var pence = 0; pence <= 300000; pence++) {
        expect(jarPounds(pence), pounds(pence), reason: 'jarPounds($pence)');
      }
      for (final pence in <int>[999, 1000, 999999, 420, 100, 99, 0]) {
        final expected = pence >= 100 ? '+${pounds(pence)}' : '+${pence}p';
        expect(formatJarAmount(pence), expected, reason: '($pence)');
      }
      expect(jarPounds(999999999), '£9999999.99');
    });

    test('the K09 text pairs meet WCAG AA in both themes', () {
      const light = NestColors.light;
      const dark = NestColors.dark;
      for (final scheme in <(String, NestSchemeColors)>[
        ('light', light),
        ('dark', dark),
      ]) {
        final (name, c) = scheme;
        final pairs = <(String, Color, Color)>[
          ('title ink/skyTop', c.ink, c.kidSkyTop),
          ('footer ink2/skyBottom', c.ink2, c.kidSkyBottom),
          ('footer ink2/meadow', c.ink2, c.kidMeadow),
          ('row title ink/surface', c.ink, c.surface),
          ('row sub ink2/surface', c.ink2, c.surface),
          ('row value leafInk/surface', c.leafInk, c.surface),
          ('goal ink/coinTint', c.ink, c.coinTint),
          ('goal captions ink2/coinTint', c.ink2, c.coinTint),
          ('empty glyph leafInk/leafTint', c.leafInk, c.leafTint),
          ('row glyph ink/lilacTint', c.ink, c.lilacTint),
          ('row glyph ink/peachTint', c.ink, c.peachTint),
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

    test('a restart keeps the jar (file database reopened)', () async {
      final dir = Directory.systemTemp.createTempSync('k09_bugs');
      addTearDown(() => dir.deleteSync(recursive: true));
      final file = File('${dir.path}/nestling.db');

      final first = AppDatabase(NativeDatabase(file));
      await Seed.demo(first);
      await KidJarRepositoryImpl(
        db: first,
      ).moveToSavings(childId: 'maya', goalId: 'goal-lego', amountPence: 100);
      await first.close();

      final second = AppDatabase(NativeDatabase(file));
      addTearDown(second.close);
      final snapshot = await KidJarRepositoryImpl(db: second).watchJar().first;
      expect(snapshot.summary.owedPence, 420);
      expect(snapshot.summary.goalSavedPence, 1650);
      expect(snapshot.items, hasLength(9));
    });
  });
}
