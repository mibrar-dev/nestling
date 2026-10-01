import 'package:nestling/features/approvals/domain/entities/approval.dart';

/// Approvals inbox (P11), backed by Drift.
///
/// Approving writes a `quest_bonus` ledger entry (coins reach the jar via
/// the ledger, the single source of money truth). "Not yet" flips the
/// completion back to `not_yet` with a kind note — no coins move.
abstract class ApprovalsRepository {
  Future<List<Approval>> getItems();
  Stream<List<Approval>> watchItems();

  Future<void> approve(int completionId);
  Future<void> markNotYet(int completionId);
  Future<void> approveAll();
}
