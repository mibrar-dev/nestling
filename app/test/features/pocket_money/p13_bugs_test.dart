// P13 · Payout (parent) — Stage 6 adversarial bug tests (iteration 1→2).
//
// Iteration 1 found five defects (3 major, 2 minor). Iteration 2 fixed all
// five and the fixers promoted every reproducer below from `skip:` to an
// ACTIVE regression test — a re-break fails the suite.
//
// This iteration re-audited the iteration-2 diff with fresh probes: the five
// fixes, the ORCHESTRATOR_NOTES items 1–3 (full-screen scrim, inline 13 px
// amount, ±1 px row text), the new retry/partial-failure logic, the busy CTA
// and the scrim semantics. Every probe holds except one new minor finding:
// P13-BUG-06 (a goal-bearing Leo still gets the design copy's "her"), kept
// `skip:`-ed with its bug id so the suite stays green until it is fixed.
//
// The "attacks that hold" group is NOT skipped: it documents the adversarial
// probes that passed (same-frame double tap on the real repo, a ticked £0
// child riding along, real 320 dp × 1.3 and 320×568 layouts, six children
// with a long UK name, single child, £0.00, gated single write, goal child
// unticked, back mid-write, deep links, kid-mode guard, restart persistence,
// dark contrast) so a regression is caught here.
//
// The "attacks that hold" group at the bottom is NOT skipped: it documents
// the adversarial probes that passed (real 320 dp × 1.3 and 320×568 layouts,
// six children with a long UK name, single child, £0.00, gated single write,
// goal child unticked, back mid-write, deep links, kid-mode guard, restart
// persistence, dark contrast) so a regression is caught here.
//
// Method: widget/pure probes on the in-memory and file-backed Drift
// databases, plus one gated repository that holds the payout write mid-flight
// so the double-tap race is deterministic instead of timing-dependent.
// **No simulator was used** (stage rule; only stage 5_ui may).
// No screen code was edited (stage rule).

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pocket_money/data/pocket_money_repository_impl.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_child.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_ledger_data.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/domain/entities/savings_goal_data.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_bloc.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_event.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_state.dart';
import 'package:nestling/features/pocket_money/presentation/views/payout_view.dart';

import '../../test_scope.dart';

const String kCta = 'Mark as paid & start the celebration';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Past a repository write: the watch stream needs a round trip.
Future<void> _pumpPastWrite(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
  await _settle(tester);
}

/// `/payout` the way a parent reaches it — pushed on top of `/money` — so
/// the scrim pop and the post-write pop have something to pop.
Future<void> _openPayoutFromLedger(WidgetTester tester) async {
  await pumpAppRoute(tester, '/money');
  await _settle(tester);
  await tester.tap(find.text('Payout time'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Set<int> _rowIds(List<LedgerEntry> rows) => rows.map((r) => r.id).toSet();

List<LedgerEntry> _newRows(List<LedgerEntry> rows, Set<int> seeded) =>
    rows.where((r) => !seeded.contains(r.id)).toList();

/// Delegates every read to the real Drift repository but holds
/// `recordPayout` on a [Completer] so the widget test can tap again *while
/// the write is in flight* — the race the happy path cannot produce on an
/// in-memory database.
class _GatedRepo implements PocketMoneyRepository {
  _GatedRepo(this._inner);

  final PocketMoneyRepository _inner;
  final List<Completer<void>> gates = <Completer<void>>[];
  int payoutCalls = 0;

  void releaseAll() {
    for (final gate in List<Completer<void>>.of(gates)) {
      if (!gate.isCompleted) gate.complete();
    }
  }

  @override
  Future<void> recordPayout({
    required String childId,
    required int amountPence,
    int savingsMovePence = 0,
    String? goalId,
  }) {
    payoutCalls++;
    final gate = Completer<void>();
    gates.add(gate);
    return gate.future.then(
      (_) => _inner.recordPayout(
        childId: childId,
        amountPence: amountPence,
        savingsMovePence: savingsMovePence,
        goalId: goalId,
      ),
    );
  }

  @override
  Future<List<PocketMoneyEntry>> getItems() => _inner.getItems();
  @override
  Stream<List<PocketMoneyEntry>> watchItems() => _inner.watchItems();
  @override
  Stream<List<PocketMoneyEntry>> watchLedger(String childId) =>
      _inner.watchLedger(childId);
  @override
  Stream<MoneyLedgerData> watchLedgerData() => _inner.watchLedgerData();
  @override
  Future<OwedSummary> owed(String childId) => _inner.owed(childId);
  @override
  Stream<OwedSummary> watchOwed(String childId) => _inner.watchOwed(childId);
  @override
  Future<void> addMoney({
    required String childId,
    required int amountPence,
    required String note,
  }) => _inner.addMoney(childId: childId, amountPence: amountPence, note: note);
  @override
  Future<void> recordSpending({
    required String childId,
    required int amountPence,
    required String note,
  }) => _inner.recordSpending(
    childId: childId,
    amountPence: amountPence,
    note: note,
  );
  @override
  Stream<PocketMoneySetup> watchSetup() => _inner.watchSetup();
  @override
  Future<void> setMode(String mode) => _inner.setMode(mode);
  @override
  Future<void> setPayoutDay(int day) => _inner.setPayoutDay(day);
  @override
  Future<void> setWeeklyBasePence(String childId, int pence) =>
      _inner.setWeeklyBasePence(childId, pence);
}

/// Every payout write throws the same error — the "the parent retries and it
/// fails again" path (P13-BUG-04). The data is the seeded shape so the sheet
/// renders without a database.
class _AlwaysFailingRepo implements PocketMoneyRepository {
  static const MoneyLedgerData _data = MoneyLedgerData(
    children: <MoneyChild>[
      MoneyChild(id: 'maya', nickname: 'Maya'),
      MoneyChild(id: 'leo', nickname: 'Leo'),
    ],
    entries: <PocketMoneyEntry>[],
    oweds: <OwedSummary>[
      OwedSummary(
        childId: 'maya',
        totalPence: 420,
        basePence: 300,
        questsPence: 120,
      ),
      OwedSummary(
        childId: 'leo',
        totalPence: 210,
        basePence: 150,
        questsPence: 60,
      ),
    ],
    goals: <SavingsGoalData>[
      SavingsGoalData(
        id: 'goal-lego',
        childId: 'maya',
        title: 'Lego Friends set',
        targetPence: 2499,
        savedPence: 1550,
      ),
    ],
    payoutDay: 6,
    zoneId: 'Europe/London',
  );

  @override
  Stream<MoneyLedgerData> watchLedgerData() =>
      Stream<MoneyLedgerData>.value(_data);

  @override
  Future<void> recordPayout({
    required String childId,
    required int amountPence,
    int savingsMovePence = 0,
    String? goalId,
  }) async {
    throw Exception('ledger unavailable');
  }

  @override
  Future<List<PocketMoneyEntry>> getItems() async => const <PocketMoneyEntry>[];
  @override
  Stream<List<PocketMoneyEntry>> watchItems() =>
      Stream<List<PocketMoneyEntry>>.value(const <PocketMoneyEntry>[]);
  @override
  Stream<List<PocketMoneyEntry>> watchLedger(String childId) => watchItems();
  @override
  Future<OwedSummary> owed(String childId) async => OwedSummary(
    childId: childId,
    totalPence: 0,
    basePence: 0,
    questsPence: 0,
  );
  @override
  Stream<OwedSummary> watchOwed(String childId) => Stream<OwedSummary>.value(
    OwedSummary(childId: childId, totalPence: 0, basePence: 0, questsPence: 0),
  );
  @override
  Future<void> addMoney({
    required String childId,
    required int amountPence,
    required String note,
  }) async {}
  @override
  Future<void> recordSpending({
    required String childId,
    required int amountPence,
    required String note,
  }) async {}
  @override
  Stream<PocketMoneySetup> watchSetup() => Stream<PocketMoneySetup>.value(
    const PocketMoneySetup(
      mode: 'both',
      payoutDay: 6,
      coinValuePencePerCoin: 1,
      children: <PocketMoneySetupChild>[
        PocketMoneySetupChild(
          id: 'maya',
          nickname: 'Maya',
          avatarColour: 'lilac',
          weeklyBasePence: 300,
        ),
        PocketMoneySetupChild(
          id: 'leo',
          nickname: 'Leo',
          avatarColour: 'peach',
          weeklyBasePence: 150,
        ),
      ],
    ),
  );
  @override
  Future<void> setMode(String mode) async {}
  @override
  Future<void> setPayoutDay(int day) async {}
  @override
  Future<void> setWeeklyBasePence(String childId, int pence) async {}
}

/// WCAG 2.x relative luminance.
double _luminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  // -- P13-BUG-01 ---------------------------------------------------------

  testWidgets(
    'P13-BUG-01: a second tap while the payout write is in flight '
    'double-writes the payout, the savings move and the goal bump',
    (tester) async {
      final db = await setUpTestScope();
      final gated = _GatedRepo(GetIt.instance<PocketMoneyRepository>());
      await GetIt.instance.unregister<PocketMoneyRepository>();
      GetIt.instance.registerSingleton<PocketMoneyRepository>(gated);

      await _openPayoutFromLedger(tester);
      final seeded = _rowIds(await db.select(db.ledgerEntries).get());

      final cta = find.widgetWithText(NestButton, kCta);
      await tester.tap(cta);
      // The write is being held by the gate: the sheet has no in-flight
      // state — the CTA stays enabled and looks untouched.
      await tester.pump(const Duration(milliseconds: 80));
      expect(cta, findsOneWidget);

      // A parent who sees no response taps again (80 ms later, well inside a
      // real device's Drift round trip).
      await tester.tap(cta);
      await tester.pump(const Duration(milliseconds: 20));
      final attempted = gated.payoutCalls;

      gated.releaseAll();
      await _pumpPastWrite(tester);

      final written = _newRows(await db.select(db.ledgerEntries).get(), seeded);
      final goal = await (db.select(
        db.savingsGoals,
      )..where((g) => g.id.equals('goal-lego'))).getSingle();

      expect(
        attempted,
        1,
        reason:
            'P13-BUG-01: the second tap was accepted while the first '
            'write was still in flight ($attempted writes dispatched)',
      );
      expect(
        written.where((r) => r.type == 'payout').length,
        1,
        reason: 'P13-BUG-01: one ticked child must produce one payout row',
      );
      expect(
        written.where((r) => r.type == 'savings_move').length,
        1,
        reason: 'P13-BUG-01: the £1.00 move must be written once',
      );
      expect(
        goal.savedPence,
        1650,
        reason: 'P13-BUG-01: the goal was credited twice (1550 → 1750)',
      );

      gated.releaseAll();
      await disposeApp(tester);
    },
    // P13-BUG-01 — FIXED (iteration 2): `_submit` is non-reentrant and the
    // sheet's CTA is `loading` while a write is in flight, so the second tap
    // is dropped. The guard re-arms only after a failure the parent actually
    // saw, so retrying stays possible. Same-frame regression assertion also
    // lives in `payout_view_test.dart`.
    skip: false, // P13-BUG-01 — fixed (major)
  );

  // -- P13-BUG-02 ---------------------------------------------------------

  testWidgets(
    'P13-BUG-02: the £1.00 savings move is not clamped to the amount paid',
    (tester) async {
      final db = await setUpTestScope();
      // A small week: Maya is owed exactly £0.50 (one 50p weekly base).
      await db.transaction(() async {
        await db.delete(db.ledgerEntries).go();
        await db
            .into(db.ledgerEntries)
            .insert(
              LedgerEntriesCompanion.insert(
                familyId: Seed.familyId,
                childId: 'maya',
                type: 'weekly_base',
                amountPence: 50,
                date: Value(DateTime.utc(2026, 10, 3, 8)),
                dateTz: const Value('Europe/London'),
              ),
            );
      });
      await GetIt.instance<AppSession>().refresh();

      await _openPayoutFromLedger(tester);
      expect(find.text('Weekly + quests · £0.50'), findsOneWidget);

      // Maya (£0.50) is ticked and the saverow is ON by default: no extra
      // action needed. "Mark as paid" pays 50p — and moves £1.00.
      await tester.tap(find.widgetWithText(NestButton, kCta));
      await _pumpPastWrite(tester);

      final written = await db.select(db.ledgerEntries).get();
      final paid = written
          .firstWhere((r) => r.type == 'payout')
          .amountPence
          .abs();
      final moved = written
          .where((r) => r.type == 'savings_move')
          .fold<int>(0, (sum, r) => sum + r.amountPence);
      final goal = await (db.select(
        db.savingsGoals,
      )..where((g) => g.id.equals('goal-lego'))).getSingle();

      expect(
        moved,
        lessThanOrEqualTo(paid),
        reason:
            'P13-BUG-02: £${(moved / 100).toStringAsFixed(2)} moved to '
            'savings on a £${(paid / 100).toStringAsFixed(2)} payout — the '
            'goal becomes money that was never paid',
      );
      expect(
        goal.savedPence - 1550,
        moved,
        reason: 'the goal must move exactly what the ledger moved',
      );

      await disposeApp(tester);
    },
    // P13-BUG-02 — FIXED (iteration 2): `_submit` clamps the move to the
    // money actually paid (`min(100 p, owed)`) and skips a ticked child who
    // owes nothing, so neither a £0.50 payout nor a £0.00 sibling can conjure
    // money in the jar. The goal is credited exactly what the ledger moved.
    skip: false, // P13-BUG-02 — fixed (major)
  );

  // -- P13-BUG-03 ---------------------------------------------------------

  testWidgets(
    'P13-BUG-03: the scrim is not inset 0 — the P12 backdrop stays lit and '
    'the top of the screen does not dismiss the sheet',
    (tester) async {
      await setUpTestScope();
      await _openPayoutFromLedger(tester);

      final scrim = NestTheme.light().extension<NestTokens>()!.scrim;
      final scrimFinder = find.byWidgetPredicate((widget) {
        if (widget is ColoredBox) return widget.color == scrim;
        if (widget is DecoratedBox) {
          final decoration = widget.decoration;
          return decoration is BoxDecoration && decoration.color == scrim;
        }
        return false;
      });
      expect(scrimFinder, findsOneWidget);
      final rect = tester.getRect(scrimFinder);
      expect(
        rect.top,
        0,
        reason:
            'P13-BUG-03: .scrim is inset:0 (SPACING_SPEC §5) — the '
            'measured scrim starts at y=${rect.top}, so the "Pocket money" '
            'title and summary card are never dimmed',
      );
      expect(rect.bottom, 844, reason: 'the scrim must reach the bottom');

      // The design/plan dismiss on any scrim tap; the title area is dead.
      await tester.tapAt(const Offset(195, 60));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        currentPath(tester),
        '/money',
        reason:
            'P13-BUG-03: a tap over the (undimmed) title does not '
            'dismiss the sheet',
      );

      await disposeApp(tester);
    },
    // P13-BUG-03 — FIXED (iteration 2): the scrim is its own `Positioned.fill`
    // layer between the dimmed ledger and the sheet (design `inset: 0`,
    // `components.css:164`), so the status-bar reserve, title and summary card
    // are dimmed and a tap over the title dismisses the sheet.
    skip: false, // P13-BUG-03 — fixed (major)
  );

  // -- P13-BUG-04 ---------------------------------------------------------

  testWidgets(
    'P13-BUG-04: a repeated identical write failure gives the parent no '
    'feedback at all',
    (tester) async {
      final bloc = PocketMoneyBloc(repository: _AlwaysFailingRepo())
        ..add(const PocketMoneyLoadRequested());
      await bloc.stream.firstWhere(
        (state) => state.status == PocketMoneyStatus.loaded,
      );
      addTearDown(bloc.close);

      await tester.pumpWidget(
        MaterialApp(
          theme: NestTheme.light(),
          home: BlocProvider<PocketMoneyBloc>.value(
            value: bloc,
            child: const PayoutView(),
          ),
        ),
      );
      await _settle(tester);

      final cta = find.widgetWithText(NestButton, kCta);
      await tester.tap(cta);
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget, reason: 'first failure');

      // Let the toast expire, then retry.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);

      await tester.tap(cta);
      await tester.pumpAndSettle();
      expect(
        find.byType(SnackBar),
        findsOneWidget,
        reason:
            'P13-BUG-04: the retry failed with the same message and the '
            'equal state is suppressed by the bloc, so the listener never '
            'fires — the button looks dead',
      );

      await tester.pumpWidget(Container());
    },
    // P13-BUG-04 — FIXED (iteration 2): the view records the message it
    // surfaced (`_lastFailure`) and re-arms the submit for a retry after a
    // failure the parent actually saw, so the button is never left dead. The
    // retry's identical failure is a state change again in this rig, so the
    // toast fires (measured 1 SnackBar, stable over repeated runs).
    skip: false, // P13-BUG-04 — fixed (minor)
  );

  // -- P13-BUG-05 ---------------------------------------------------------

  testWidgets(
    'P13-BUG-05: the ledger behind the modal stays in the semantics tree',
    (tester) async {
      await setUpTestScope();
      await _openPayoutFromLedger(tester);
      final handle = tester.ensureSemantics();

      expect(
        find.bySemanticsLabel('Saturday payout'),
        findsWidgets,
        reason: 'the sheet itself must stay reachable',
      );
      expect(
        find.bySemanticsLabel('Pocket money'),
        findsNothing,
        reason:
            'P13-BUG-05: the dimmed title behind the modal is a '
            'semantics node — VoiceOver can focus it behind the sheet',
      );
      expect(
        find.bySemanticsLabel('Maya is owed £4.20 · Leo is owed £2.10'),
        findsNothing,
        reason:
            'P13-BUG-05: the summary card behind the modal is a '
            'semantics node',
      );

      handle.dispose();
      await disposeApp(tester);
    },
    // P13-BUG-05 — FIXED (iteration 2): the dimmed chrome is wrapped in
    // `ExcludeSemantics` (the doc comment is now true), and the scrim keeps
    // its own labelled dismiss node outside it — `'Close payout'`, with a
    // real tap action.
    skip: false, // P13-BUG-05 — fixed (minor)
  );

  // -- P13-BUG-06 ---------------------------------------------------------

  testWidgets(
    'P13-BUG-06: a goal-bearing Leo still gets the design copy with "her"',
    (tester) async {
      final db = await setUpTestScope();
      // Move the only goal to Leo: he becomes the `.saverow` child, so the
      // design string's fixed "her Lego fund" describes him.
      await (db.update(db.savingsGoals)..where((g) => g.id.equals('goal-lego')))
          .write(const SavingsGoalsCompanion(childId: Value('leo')));
      await GetIt.instance<AppSession>().refresh();

      await _openPayoutFromLedger(tester);
      final copy = tester
          .widgetList<Text>(find.byType(Text))
          .map((widget) => widget.data)
          .whereType<String>()
          .firstWhere((s) => s.startsWith('Move £1.00 of Leo'));

      // Measured today: "Move £1.00 of Leo's to her Lego fund" — the fix for
      // review finding 7 keys the design string on the goal TITLE containing
      // "lego" (`PayoutSaveRow.label`), so a male goal child with a Lego goal
      // still gets the design's feminine pronoun. There is no gender column,
      // so the only data-safe phrasing is the neutral fallback.
      expect(
        copy.contains('to her'),
        isFalse,
        reason:
            'P13-BUG-06: "$copy" — the design string is Maya-specific; a '
            'goal-bearing Leo must not be told the money goes to "her fund"',
      );

      await disposeApp(tester);
    },
    // P13-BUG-06 — FIXED (iteration 3): `PayoutSaveRow.label` renders the
    // design string only for the exact seeded shape (goal child Maya AND goal
    // title "Lego Friends set"); every other shape — a goal-bearing Leo with
    // a Lego goal included — gets the neutral data-driven sentence, never the
    // design's gendered "her Lego fund".
    skip: false, // P13-BUG-06 — fixed (minor)
  );

  // -- attacks that hold --------------------------------------------------

  group('P13 attacks that hold', () {
    testWidgets('a same-frame double tap on the real repository writes once', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await _openPayoutFromLedger(tester);
      final seeded = _rowIds(await db.select(db.ledgerEntries).get());

      final cta = find.widgetWithText(NestButton, kCta);
      await tester.tap(cta);
      await tester.tap(cta);
      await _pumpPastWrite(tester);

      final written = _newRows(await db.select(db.ledgerEntries).get(), seeded);
      final goal = await (db.select(
        db.savingsGoals,
      )..where((g) => g.id.equals('goal-lego'))).getSingle();
      expect(written.where((r) => r.type == 'payout').length, 1);
      expect(written.where((r) => r.type == 'savings_move').length, 1);
      expect(goal.savedPence, 1650);
      expect(pushedPath(tester), '/money');
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('a ticked £0 child riding along writes no row and no move', (
      tester,
    ) async {
      final db = await setUpTestScope();

      // Visit 1: pay Maya only (default tick; Leo stays unticked).
      await _openPayoutFromLedger(tester);
      await tester.tap(find.widgetWithText(NestButton, kCta));
      await _pumpPastWrite(tester);
      expect(pushedPath(tester), '/money');

      // Visit 2: Maya £0 (unticked by the prime), Leo £2.10 (ticked).
      await tester.tap(find.text('Payout time'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.bySemanticsLabel('Maya paid in cash'));
      await tester.pump(const Duration(milliseconds: 50));

      final before = _rowIds(await db.select(db.ledgerEntries).get());
      await tester.tap(find.widgetWithText(NestButton, kCta));
      await _pumpPastWrite(tester);

      final written = _newRows(await db.select(db.ledgerEntries).get(), before);
      final goal = await (db.select(
        db.savingsGoals,
      )..where((g) => g.id.equals('goal-lego'))).getSingle();
      final payouts = written.where((r) => r.type == 'payout').toList();
      expect(payouts, hasLength(1));
      expect(payouts.single.childId, 'leo');
      expect(payouts.single.amountPence, -210);
      expect(written.where((r) => r.type == 'savings_move'), isEmpty);
      expect(goal.savedPence, 1650, reason: 'visit 1 moved £1.00 once');
      expect(pushedPath(tester), '/money');
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('a single gated write lands once and pops with the toast', (
      tester,
    ) async {
      final db = await setUpTestScope();
      final gated = _GatedRepo(GetIt.instance<PocketMoneyRepository>());
      await GetIt.instance.unregister<PocketMoneyRepository>();
      GetIt.instance.registerSingleton<PocketMoneyRepository>(gated);

      await _openPayoutFromLedger(tester);
      final seeded = _rowIds(await db.select(db.ledgerEntries).get());

      await tester.tap(find.widgetWithText(NestButton, kCta));
      await tester.pump(const Duration(milliseconds: 80));
      expect(gated.payoutCalls, 1);
      gated.releaseAll();
      await _pumpPastWrite(tester);

      final written = _newRows(await db.select(db.ledgerEntries).get(), seeded);
      final goal = await (db.select(
        db.savingsGoals,
      )..where((g) => g.id.equals('goal-lego'))).getSingle();
      expect(written.where((r) => r.type == 'payout').length, 1);
      expect(written.where((r) => r.type == 'savings_move').length, 1);
      expect(written.firstWhere((r) => r.type == 'payout').amountPence, -420);
      expect(goal.savedPence, 1650);
      expect(pushedPath(tester), '/money');
      expect(
        find.text('Payout recorded — enjoy the celebration'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('six children including a long UK name at a real 320 dp × 1.3: '
        'creation order, no overflow, CTA operable', (tester) async {
      final db = await setUpTestScope();
      for (final row in <({String id, String name})>[
        (id: 'mia', name: 'Maximilian-Alexander'),
        (id: 'noah', name: 'Noah'),
        (id: 'ava', name: 'Ava'),
        (id: 'ethan', name: 'Ethan'),
      ]) {
        await db
            .into(db.children)
            .insert(
              ChildrenCompanion.insert(
                id: row.id,
                familyId: Seed.familyId,
                nickname: row.name,
              ),
            );
      }
      await GetIt.instance<AppSession>().refresh();
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      // NOTE: `pumpAppRoute` forces 390×844, so the narrow size is set
      // *after* the first pump (the pre-pump override is silently reset).
      await pumpAppRoute(tester, '/payout');
      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await _settle(tester);

      const order = <String>[
        'Maya',
        'Leo',
        'Maximilian-Alexander',
        'Noah',
        'Ava',
        'Ethan',
      ];
      for (var i = 1; i < order.length; i++) {
        expect(
          tester.getTopLeft(find.text(order[i])).dy,
          greaterThan(tester.getTopLeft(find.text(order[i - 1])).dy),
          reason: '${order[i - 1]} must sit above ${order[i]}',
        );
      }

      final seeded = _rowIds(await db.select(db.ledgerEntries).get());
      final cta = find.widgetWithText(NestButton, kCta);
      await tester.scrollUntilVisible(cta, 120);
      await _settle(tester);
      await tester.tap(cta);
      await _pumpPastWrite(tester);

      final written = _newRows(await db.select(db.ledgerEntries).get(), seeded);
      expect(written.where((r) => r.type == 'payout').length, 1);
      expect(written.firstWhere((r) => r.type == 'payout').amountPence, -420);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('a real 320×568 surface scrolls the sheet to the CTA', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/payout');
      tester.view.physicalSize = const Size(320 * 3, 568 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await _settle(tester);

      final cta = find.widgetWithText(NestButton, kCta);
      await tester.scrollUntilVisible(cta, 120);
      await _settle(tester);
      await tester.tap(cta);
      await _pumpPastWrite(tester);

      expect(currentPath(tester), '/money');
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('unticking the goal child moves no money to savings', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await _openPayoutFromLedger(tester);
      final seeded = _rowIds(await db.select(db.ledgerEntries).get());

      // Untick Maya (the goal child), tick Leo, pay.
      await tester.tap(find.bySemanticsLabel('Maya paid in cash'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.bySemanticsLabel('Leo paid in cash'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.widgetWithText(NestButton, kCta));
      await _pumpPastWrite(tester);

      final written = _newRows(await db.select(db.ledgerEntries).get(), seeded);
      final goal = await (db.select(
        db.savingsGoals,
      )..where((g) => g.id.equals('goal-lego'))).getSingle();
      expect(written.where((r) => r.type == 'savings_move'), isEmpty);
      expect(goal.savedPence, 1550);
      final payouts = written.where((r) => r.type == 'payout').toList();
      expect(payouts, hasLength(1));
      expect(payouts.single.childId, 'leo');
      expect(payouts.single.amountPence, -210);

      await disposeApp(tester);
    });

    testWidgets('everyone at £0.00: two rows and a disabled CTA', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await db.delete(db.ledgerEntries).go();
      await GetIt.instance<AppSession>().refresh();

      await pumpAppRoute(tester, '/payout');
      await _settle(tester);

      expect(find.text('Weekly + quests · £0.00'), findsNWidgets(2));
      final handle = tester.ensureSemantics();
      final node = tester.getSemantics(find.bySemanticsLabel(kCta));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('a one-child family renders one payout row', (tester) async {
      final db = await setUpTestScope();
      await (db.delete(db.children)..where((c) => c.id.equals('leo'))).go();
      await GetIt.instance<AppSession>().refresh();

      await pumpAppRoute(tester, '/payout');
      await _settle(tester);

      expect(find.text('Maya'), findsOneWidget);
      expect(find.textContaining('Leo'), findsNothing);
      expect(find.text('Weekly + quests · £4.20'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('kid-mode deep link to /payout stops at the parental gate', (
      tester,
    ) async {
      await setUpTestScope();
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/payout');
      expect(currentPath(tester), '/parental-gate');
      expect(find.text('Saturday payout'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('a fresh (never onboarded) deep link lands on /welcome', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.fresh(db);
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/payout');
      expect(currentPath(tester), '/welcome');
      await disposeApp(tester);
    });

    testWidgets('launched at /payout with nothing to pop, the scrim goes '
        'to /money', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/payout');
      await _settle(tester);

      await tester.tapAt(const Offset(195, 200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(currentPath(tester), '/money');

      await disposeApp(tester);
    });

    testWidgets('system back mid-write: one payout row, no exception', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await _openPayoutFromLedger(tester);
      final seeded = _rowIds(await db.select(db.ledgerEntries).get());

      await tester.tap(find.widgetWithText(NestButton, kCta));
      await tester.binding.handlePopRoute();
      await _pumpPastWrite(tester);

      final written = _newRows(await db.select(db.ledgerEntries).get(), seeded);
      expect(written.where((r) => r.type == 'payout').length, 1);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    test(
      'a payout, savings move and goal bump survive a database restart',
      () async {
        final dir = Directory.systemTemp.createTempSync('p13_bugs_restart');
        final file = File('${dir.path}/nestling.db');
        try {
          var db = AppDatabase(NativeDatabase(file));
          await Seed.demo(db);
          var repository = PocketMoneyRepositoryImpl(db: db);
          final before = await repository.watchLedgerData().first;
          final payoutsBefore = before
              .entriesFor('maya')
              .where((entry) => entry.type == 'payout')
              .length;
          final movesBefore = before
              .entriesFor('maya')
              .where((entry) => entry.type == 'savings_move')
              .length;

          await repository.recordPayout(
            childId: 'maya',
            amountPence: 420,
            savingsMovePence: 100,
            goalId: 'goal-lego',
          );
          await db.close();

          db = AppDatabase(NativeDatabase(file));
          repository = PocketMoneyRepositoryImpl(db: db);
          final after = await repository.watchLedgerData().first;
          expect(after.owedFor('maya')?.totalPence, 0);
          expect(after.goalFor('maya')?.savedPence, 1650);
          expect(
            after
                .entriesFor('maya')
                .where((entry) => entry.type == 'payout')
                .length,
            payoutsBefore + 1,
          );
          expect(
            after
                .entriesFor('maya')
                .where((entry) => entry.type == 'savings_move')
                .length,
            movesBefore + 1,
          );
          await db.close();
        } finally {
          dir.deleteSync(recursive: true);
        }
      },
    );

    test('P13 text pairs pass 4.5:1 in both themes', () {
      for (final theme in <ThemeData>[NestTheme.light(), NestTheme.dark()]) {
        final tokens = theme.extension<NestTokens>()!;
        for (final pair in <(String, Color, Color)>[
          ('ink/surface', tokens.ink, tokens.surface),
          ('ink2/surface', tokens.ink2, tokens.surface),
          ('ink/paper', tokens.ink, tokens.paper),
          ('ink2/paper', tokens.ink2, tokens.paper),
          ('onLeaf/leaf', tokens.onLeaf, tokens.leaf),
        ]) {
          expect(
            _contrast(pair.$2, pair.$3),
            greaterThanOrEqualTo(4.5),
            reason: '${pair.$1} fails contrast on ${theme.brightness}',
          );
        }
      }
    });
  });
}
