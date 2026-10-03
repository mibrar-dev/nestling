// P13 Payout — Drift `recordPayout` contract on `Seed.demo()`.
//
// Pins the plan §f item 2: `recordPayout(maya, 420, savings 100, goal-lego)`
// writes a negative `payout` row (−420) plus a `savings_move` (+100), bumps
// the Lego goal 1550 → 1650, zeroes Maya's owed, and leaves Leo's £2.10
// untouched. A zero-save payout writes only the `payout` row.

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/pocket_money/data/pocket_money_repository_impl.dart';

void main() {
  late AppDatabase db;
  late PocketMoneyRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase.memory();
    await Seed.demo(db);
    repository = PocketMoneyRepositoryImpl(db: db);
  });

  tearDown(() => db.close());

  Future<List<LedgerEntry>> rowsFor(String childId) async {
    final rows = await (db.select(
      db.ledgerEntries,
    )..where((l) => l.childId.equals(childId))).get();
    rows.sort((a, b) => b.date.compareTo(a.date));
    return rows;
  }

  Future<int> goalSaved(String goalId) async {
    final goal = await (db.select(
      db.savingsGoals,
    )..where((g) => g.id.equals(goalId))).getSingle();
    return goal.savedPence;
  }

  group('recordPayout', () {
    test('maya (420, savings 100, goal-lego): payout + savings rows', () async {
      await repository.recordPayout(
        childId: 'maya',
        amountPence: 420,
        savingsMovePence: 100,
        goalId: 'goal-lego',
      );

      final maya = await rowsFor('maya');
      final payouts = maya.where((row) => row.type == 'payout').toList();
      // The seed holds the settled 26 Sep payout; the new one lands on top.
      expect(payouts, hasLength(2));
      expect(payouts.first.amountPence, -420);

      final moves = maya.where((row) => row.type == 'savings_move').toList();
      // The seed already holds savings moves; the new one lands on top.
      expect(moves.map((row) => row.amountPence), contains(100));
      expect(moves.first.amountPence, 100);
    });

    test('maya payout bumps the Lego goal 1550 → 1650', () async {
      expect(await goalSaved('goal-lego'), 1550);

      await repository.recordPayout(
        childId: 'maya',
        amountPence: 420,
        savingsMovePence: 100,
        goalId: 'goal-lego',
      );

      expect(await goalSaved('goal-lego'), 1650);
    });

    test('maya payout zeroes her owed and leaves Leo at 210', () async {
      await repository.recordPayout(
        childId: 'maya',
        amountPence: 420,
        savingsMovePence: 100,
        goalId: 'goal-lego',
      );

      expect((await repository.owed('maya')).totalPence, 0);
      final leo = await repository.owed('leo');
      expect(leo.totalPence, 210);
      expect(leo.basePence, 150);
      expect(leo.questsPence, 60);
    });

    test('zero-save payout writes only the payout row', () async {
      await repository.recordPayout(childId: 'leo', amountPence: 210);

      final leo = await rowsFor('leo');
      final payouts = leo.where((row) => row.type == 'payout').toList();
      // The seed holds the settled 26 Sep payout; the new one lands on top.
      expect(payouts, hasLength(2));
      expect(payouts.first.amountPence, -210);
      expect(leo.where((row) => row.type == 'savings_move'), isEmpty);
      expect(await goalSaved('goal-lego'), 1550);
      expect((await repository.owed('leo')).totalPence, 0);
      // Maya is untouched by Leo's payout.
      expect((await repository.owed('maya')).totalPence, 420);
    });
  });
}
