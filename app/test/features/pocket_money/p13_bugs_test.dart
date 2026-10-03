// P13 · Payout (parent) — Stage 6 adversarial bug tests (iteration 1).
//
// Five findings this iteration — three major (P13-BUG-01/02/03) and two
// minor (P13-BUG-04/05). Every failing reproducer is a `skip:` test carrying
// its bug id so the suite stays green; each one was run unskipped during the
// hunt and fails on the current build exactly as the reason lines say.
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
    // P13-BUG-01 — major, open: the view has no re-entrancy guard; a second
    // tap before the ledger stream proves the first write dispatches the
    // same PocketMoneyPayoutSubmitted again. Repro measured: 2 payout rows
    // (−420 each), 2 savings_move rows (100 each), goal 1750 instead of
    // 1650.
    skip: true, // P13-BUG-01 — open (major)
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
    // P13-BUG-02 — major, open: `PayoutSheet.savingsMovePence` is the
    // design-fixed 100 p and `_submit` never clamps it to the child's owed
    // amount. At 50p owed: payout −50, savings_move +100, goal 1550 → 1650
    // (+£1.00 conjured). Same root when a £0.00 child is ticked next to a
    // paying sibling: a −0 payout row plus a £1.00 move.
    skip: true, // P13-BUG-02 — open (major)
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
    // P13-BUG-03 — major, open: `_DimmedLedger` puts the scrim inside the
    // `Expanded` below the summary card (measured Rect 0,169,390,844)
    // instead of `Positioned.fill`/inset 0, so the top 169 px (status bar
    // reserve + title + card) is undimmed and not tappable. The design PNGs
    // dim the whole backdrop; 1_plan.md §a spells out Positioned.fill.
    skip: true, // P13-BUG-03 — open (major)
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
    // P13-BUG-04 — minor, open: the error path emits the same
    // `errorMessage`, which `copyWith` makes an equal state, so Bloc skips
    // the emission; the view only toasts on a changed message and
    // `_submitted` stays armed. Fix: give the view a direct retry path
    // (toast on tap / clear the message before re-requesting) or include a
    // monotonically increasing attempt in the state.
    skip: true, // P13-BUG-04 — open (minor)
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
    // P13-BUG-05 — minor, open: `_DimmedLedger`'s doc comment says
    // `ExcludeSemantics` (and 1_plan.md §e requires it) but the build
    // method never wraps the column, so the background is announced behind
    // the modal. Fix: wrap the non-sheet subtree in `ExcludeSemantics`
    // (keep the scrim's dismiss outside it).
    skip: true, // P13-BUG-05 — open (minor)
  );

  // -- attacks that hold --------------------------------------------------

  group('P13 attacks that hold', () {
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
