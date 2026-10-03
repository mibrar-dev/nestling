// P13 · Payout — STAGE 3 audit for iteration 2.
//
// Independent adversarial pass over the iteration-2 fixes (ORCHESTRATOR_NOTES
// items 1–3, P13-BUG-01/02/03/04/05, review findings 1–10). This file does
// not trust the builders' reports: it re-derives the behaviour from the
// database and from the rendered widget.
//
// A test here FAILS when it finds a real defect. Such a test is kept with
// `skip: true` and a `P13-I2-*` id so the suite stays green and the finding is
// pinned; run the un-skip recipe in docs/screens/P13/3_test.md to reproduce.
//
// **No simulator was used** (stage rule: only 5_ui may).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
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

import '../../test_scope.dart';

const String kCta = 'Mark as paid & start the celebration';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Past a repository write: the ledger watch stream needs a round trip before
/// the sheet's "did the payout land?" proof fires.
Future<void> _pumpPastWrite(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
  await _settle(tester);
}

/// A repository that serves one hand-made `MoneyLedgerData` so a sheet can be
/// rendered for a family the demo seed does not contain (Leo holding a goal,
/// an unusual goal title). Writes succeed but change nothing observable here.
class _FixtureRepo implements PocketMoneyRepository {
  _FixtureRepo(this.data);

  final MoneyLedgerData data;
  int payoutCalls = 0;

  @override
  Stream<MoneyLedgerData> watchLedgerData() =>
      Stream<MoneyLedgerData>.value(data);

  @override
  Future<void> recordPayout({
    required String childId,
    required int amountPence,
    int savingsMovePence = 0,
    String? goalId,
  }) async {
    payoutCalls++;
  }

  @override
  Future<List<PocketMoneyEntry>> getItems() async => const <PocketMoneyEntry>[];
  @override
  Stream<List<PocketMoneyEntry>> watchItems() =>
      Stream<List<PocketMoneyEntry>>.value(const <PocketMoneyEntry>[]);
  @override
  Stream<List<PocketMoneyEntry>> watchLedger(String childId) => watchItems();
  @override
  Stream<OwedSummary> watchOwed(String childId) => Stream<OwedSummary>.value(
    data.owedFor(childId) ??
        OwedSummary(
          childId: childId,
          totalPence: 0,
          basePence: 0,
          questsPence: 0,
        ),
  );
  @override
  Future<OwedSummary> owed(String childId) async => OwedSummary(
    childId: childId,
    totalPence: 0,
    basePence: 0,
    questsPence: 0,
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
    PocketMoneySetup(
      mode: 'weekly',
      payoutDay: data.payoutDay,
      coinValuePencePerCoin: 1,
      children: <PocketMoneySetupChild>[
        for (final child in data.children)
          PocketMoneySetupChild(
            id: child.id,
            nickname: child.nickname,
            avatarColour: 'lilac',
            weeklyBasePence: 0,
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

/// Holds `recordPayout` open on a [Completer] so the widget test can observe
/// the `busy` window deterministically. On an in-memory Drift database the
/// write lands inside the first frame, so pumping real time can never catch
/// `PayoutSheet.busy` without a gate (same device as `p13_bugs_test.dart`).
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
  Stream<MoneyLedgerData> watchLedgerData() => _inner.watchLedgerData();
  @override
  Future<List<PocketMoneyEntry>> getItems() => _inner.getItems();
  @override
  Stream<List<PocketMoneyEntry>> watchItems() => _inner.watchItems();
  @override
  Stream<List<PocketMoneyEntry>> watchLedger(String childId) =>
      _inner.watchLedger(childId);
  @override
  Stream<OwedSummary> watchOwed(String childId) => _inner.watchOwed(childId);
  @override
  Future<OwedSummary> owed(String childId) => _inner.owed(childId);
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

/// Maya + Leo, with [goals] attached to whichever child the test needs.
MoneyLedgerData _ledger(List<SavingsGoalData> goals) => MoneyLedgerData(
  children: const <MoneyChild>[
    MoneyChild(id: 'maya', nickname: 'Maya'),
    MoneyChild(id: 'leo', nickname: 'Leo'),
  ],
  entries: const <PocketMoneyEntry>[],
  oweds: const <OwedSummary>[
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
  goals: goals,
  payoutDay: 6,
  zoneId: 'Europe/London',
);

Future<void> _pumpWith(WidgetTester tester, MoneyLedgerData data) async {
  await setUpTestScope();
  final repository = _FixtureRepo(data);
  await GetIt.instance.unregister<PocketMoneyRepository>();
  GetIt.instance.registerSingleton<PocketMoneyRepository>(repository);
  await pumpAppRoute(tester, '/payout');
  await _settle(tester);
}

void main() {
  // ==========================================================================
  // A. The `.saverow` copy helper (iteration-2 review finding 7 fix)
  // ==========================================================================
  group('P13 iteration 2 — the .saverow copy is data-driven', () {
    testWidgets('the seeded Lego goal still renders the design string', (
      tester,
    ) async {
      await _pumpWith(
        tester,
        _ledger(<SavingsGoalData>[
          const SavingsGoalData(
            id: 'goal-lego',
            childId: 'maya',
            title: 'Lego Friends set',
            targetPence: 2499,
            savedPence: 1550,
          ),
        ]),
      );

      expect(
        find.text("Move £1.00 of Maya's to her Lego fund"),
        findsOneWidget,
        reason:
            'P13-payout.html:29 verbatim, ASCII 0x27 apostrophe, '
            '£ from the DB',
      );
      await disposeApp(tester);
    });

    testWidgets('a NON-lego goal never borrows a gender pronoun', (
      tester,
    ) async {
      await _pumpWith(
        tester,
        _ledger(<SavingsGoalData>[
          const SavingsGoalData(
            id: 'goal-bike',
            childId: 'maya',
            title: 'New bike',
            targetPence: 9000,
            savedPence: 500,
          ),
        ]),
      );

      // DATA OVER MOCKS: the goal title decides the wording, and the design
      // string ("...to her Lego fund") is specific to the seeded Lego goal.
      expect(find.textContaining("Move £1.00 of Maya's"), findsOneWidget);
      expect(find.textContaining('New bike'), findsOneWidget);
      expect(
        find.textContaining(' her '),
        findsNothing,
        reason:
            "a non-Lego goal must not be described with the design's "
            'feminine pronoun for an arbitrary child',
      );
      await disposeApp(tester);
    });

    // P13-I2-01 — the "Lego" special case keys the pronoun off the GOAL TITLE,
    // not off the child, so a Lego goal belonging to a boy renders "...to HER
    // Lego fund". The database has no gender/pronoun column at all
    // (`Children` in app_database.dart:65-85), so the app can never get this
    // right — it is unresolvable from the data the screen is given.
    testWidgets(
      'P13-I2-01: a Lego goal for Leo renders the feminine "her Lego fund"',
      (tester) async {
        await _pumpWith(
          tester,
          _ledger(<SavingsGoalData>[
            const SavingsGoalData(
              id: 'goal-lego-leo',
              childId: 'leo',
              title: 'Lego City',
              targetPence: 2499,
              savedPence: 300,
            ),
          ]),
        );

        final row = tester.widget<Text>(
          find.textContaining("Move £1.00 of Leo's"),
        );
        // The rendered copy is echoed so the finding is readable from a test
        // log without opening the widget tree.
        debugPrint('P13-I2-01 rendered copy: ${row.data}');

        expect(
          row.data,
          isNot(contains(' her ')),
          reason:
              'P13-I2-01: Leo is a boy in the demo seed, but the copy says '
              '"her" because PayoutSaveRow.label() only checks that the goal '
              'TITLE contains "lego". No gender column exists to do better.',
        );
        await disposeApp(tester);
      },
      skip: true, // P13-I2-01 — OPEN (minor): goal-title-keyed pronoun
    );
  });

  // ==========================================================================
  // B. The repository guards (review #3, P13-BUG-02)
  // ==========================================================================
  group('P13 iteration 2 — recordPayout guards', () {
    late AppDatabase db;
    late PocketMoneyRepositoryImpl repository;

    setUp(() async {
      db = AppDatabase.memory();
      await Seed.demo(db);
      repository = PocketMoneyRepositoryImpl(db: db);
    });

    tearDown(() => db.close());

    Future<List<LedgerEntry>> newRows(String childId, Set<int> seeded) async {
      final rows = await (db.select(
        db.ledgerEntries,
      )..where((l) => l.childId.equals(childId))).get();
      return rows.where((r) => !seeded.contains(r.id)).toList();
    }

    test('amountPence 0 writes nothing at all', () async {
      final before = await db.select(db.ledgerEntries).get();
      await repository.recordPayout(childId: 'maya', amountPence: 0);
      final after = await db.select(db.ledgerEntries).get();

      expect(
        after.length,
        before.length,
        reason: 'review #3: no "Paid · £0.00" row for money never handed over',
      );
    });

    test('amountPence 0 with a savings move still moves nothing', () async {
      final goalBefore = (await (db.select(
        db.savingsGoals,
      )..where((g) => g.id.equals('goal-lego'))).getSingle()).savedPence;

      await repository.recordPayout(
        childId: 'maya',
        amountPence: 0,
        savingsMovePence: 100,
        goalId: 'goal-lego',
      );

      final goalAfter = (await (db.select(
        db.savingsGoals,
      )..where((g) => g.id.equals('goal-lego'))).getSingle()).savedPence;
      expect(
        goalAfter,
        goalBefore,
        reason: 'P13-BUG-02: the move can never conjure money on a £0 payout',
      );
    });

    test('the clamp backstop holds for a caller that does NOT clamp', () async {
      // The view clamps with min(100, owed); this pins the repository backstop
      // on its own, for a small week (owed 50p, move 100p).
      final seeded = (await db.select(db.ledgerEntries).get())
          .map((r) => r.id)
          .toSet();

      await repository.recordPayout(
        childId: 'maya',
        amountPence: 50,
        savingsMovePence: 100,
        goalId: 'goal-lego',
      );

      final rows = await newRows('maya', seeded);
      final payout = rows.firstWhere((r) => r.type == 'payout');
      final move = rows.firstWhere((r) => r.type == 'savings_move');
      expect(payout.amountPence, -50, reason: 'the amount paid is untouched');
      expect(
        move.amountPence,
        50,
        reason: 'P13-BUG-02: the move is clamped to the £0.50 actually paid',
      );
      expect(
        (await (db.select(
          db.savingsGoals,
        )..where((g) => g.id.equals('goal-lego'))).getSingle()).savedPence,
        1550 + 50,
        reason: 'the goal is credited with the CLAMPED value, not the request',
      );
    });

    test('a negative amount is a no-op, not a credit', () async {
      final seeded = (await db.select(db.ledgerEntries).get())
          .map((r) => r.id)
          .toSet();
      await repository.recordPayout(childId: 'maya', amountPence: -500);

      final rows = await newRows('maya', seeded);
      expect(
        rows.where((r) => r.type == 'payout'),
        isEmpty,
        reason:
            'amountPence <= 0 returns before the insert — no money is minted',
      );
    });

    test('a savings move without a goal id moves no money', () async {
      final seeded = (await db.select(db.ledgerEntries).get())
          .map((r) => r.id)
          .toSet();
      await repository.recordPayout(
        childId: 'maya',
        amountPence: 420,
        savingsMovePence: 100,
      );

      final rows = await newRows('maya', seeded);
      expect(
        rows.where((r) => r.type == 'savings_move'),
        isEmpty,
        reason: 'goalId == null is honoured even with a positive move',
      );
      expect(rows.where((r) => r.type == 'payout'), hasLength(1));
    });
  });

  // ==========================================================================
  // C. PayoutSheet.busy and the CTA (P13-BUG-01 fix)
  // ==========================================================================
  group('P13 iteration 2 — the busy CTA', () {
    /// The painted pill, found by its own shape rather than by the label text:
    /// `loading: true` swaps in a spinner prefix, so a text-anchored finder
    /// would measure the wrong thing.
    Rect ctaPillRect(WidgetTester tester) =>
        tester.getRect(find.byType(AnimatedContainer).first);

    testWidgets('the CTA pill keeps its rect while the write is in flight', (
      tester,
    ) async {
      final db = await setUpTestScope();
      final gated = _GatedRepo(GetIt.instance<PocketMoneyRepository>());
      await GetIt.instance.unregister<PocketMoneyRepository>();
      GetIt.instance.registerSingleton<PocketMoneyRepository>(gated);
      expect(db, isNotNull);

      await pumpAppRoute(tester, '/payout');
      await _settle(tester);
      final idle = ctaPillRect(tester);

      await tester.tap(find.text(kCta));
      // The gate holds the write open, so `busy` stays true.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(
        tester.widget<NestButton>(find.byType(NestButton)).loading,
        isTrue,
        reason: 'the sheet is in its in-flight state',
      );
      expect(
        ctaPillRect(tester),
        idle,
        reason:
            'the 2b note claims `loading` does not change the pill geometry — '
            'a pill that resizes mid-write is a visible jump',
      );

      gated.releaseAll();
      await _pumpPastWrite(tester);
      await disposeApp(tester);
    });

    testWidgets('a busy CTA exposes no tap action for a second tap', (
      tester,
    ) async {
      final db = await setUpTestScope();
      final gated = _GatedRepo(GetIt.instance<PocketMoneyRepository>());
      await GetIt.instance.unregister<PocketMoneyRepository>();
      GetIt.instance.registerSingleton<PocketMoneyRepository>(gated);
      expect(db, isNotNull);

      await pumpAppRoute(tester, '/payout');
      await _settle(tester);

      await tester.tap(find.text(kCta));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      final button = tester.widget<NestButton>(find.byType(NestButton));
      expect(
        button.onPressed,
        isNull,
        reason: 'canSubmit = !busy && … — the disabled CTA cannot re-enter',
      );
      await disposeApp(tester);
    });
  });

  // ==========================================================================
  // D. The two `BlocListener`s (priming, failure, landing) and _lastFailure
  // ==========================================================================
  group('P13 iteration 2 — submit guards', () {
    testWidgets('unticking everyone still disables the CTA (no regression)', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/payout');
      await _settle(tester);

      expect(
        tester
            .widget<NestButton>(find.widgetWithText(NestButton, kCta))
            .onPressed,
        isNotNull,
        reason: 'Maya is primed ticked, so the CTA starts enabled',
      );

      await tester.tap(find.bySemanticsLabel('Maya paid in cash'));
      await _settle(tester);

      expect(
        tester
            .widget<NestButton>(find.widgetWithText(NestButton, kCta))
            .onPressed,
        isNull,
        reason: 'canSubmit needs at least one ticked child',
      );
      await disposeApp(tester);
    });

    testWidgets('ticking a second child pays BOTH (the guard is per child)', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await pumpAppRoute(tester, '/payout');
      await _settle(tester);

      // The demo seed already carries a historical payout row per child, so
      // only rows written by THIS tap may be counted.
      final seeded = (await db.select(db.ledgerEntries).get())
          .map((r) => r.id)
          .toSet();

      // Maya is primed; add Leo. Both must be written in ONE tap — a naive
      // "any payout in flight" guard would silently drop the second child.
      await tester.tap(find.bySemanticsLabel('Leo paid in cash'));
      await _settle(tester);

      await tester.tap(find.text(kCta));
      await _pumpPastWrite(tester);

      // Read the ledger directly off the captured database (a repository read
      // through GetIt from inside the fake-async test zone can hang).
      final payouts =
          (await (db.select(
                db.ledgerEntries,
              )..where((l) => l.type.equals('payout'))).get())
              .where((r) => !seeded.contains(r.id))
              .toList();
      final byChild = <String, int>{};
      for (final row in payouts) {
        byChild[row.childId] = (byChild[row.childId] ?? 0) + row.amountPence;
      }

      expect(
        byChild['maya'],
        -420,
        reason: 'the primed child was paid exactly what she owed',
      );
      expect(
        byChild['leo'],
        -210,
        reason:
            'the sibling ticked in the same tap must ALSO be paid — '
            "P13-BUG-01's fix must not swallow a second, different child",
      );
      expect(
        payouts,
        hasLength(2),
        reason: 'one payout row per ticked child, no duplicates',
      );
      await disposeApp(tester);
    });
  });
}
