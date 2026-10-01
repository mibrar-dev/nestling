import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';

/// Money ledger + payout (P06 setup, P12 ledger, P13 payout), backed by
/// Drift. The ledger is the single source of money truth; `owed()` derives
/// the payout figure from it (never stored).
abstract class PocketMoneyRepository {
  Future<List<PocketMoneyEntry>> getItems();
  Stream<List<PocketMoneyEntry>> watchItems();

  /// Ledger for one child, newest first.
  Stream<List<PocketMoneyEntry>> watchLedger(String childId);

  /// Base + quest bonuses since the last payout.
  Future<OwedSummary> owed(String childId);
  Stream<OwedSummary> watchOwed(String childId);

  Future<void> addMoney({
    required String childId,
    required int amountPence,
    required String note,
  });
  Future<void> recordSpending({
    required String childId,
    required int amountPence,
    required String note,
  });

  /// P13 "Mark as paid": writes a negative `payout` entry (and an optional
  /// `savings_move` + goal bump) so the next `owed()` starts from zero.
  Future<void> recordPayout({
    required String childId,
    required int amountPence,
    int savingsMovePence = 0,
    String? goalId,
  });
}
