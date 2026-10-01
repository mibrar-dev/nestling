import 'package:nestling/features/approvals/domain/entities/approval.dart';

abstract class ApprovalsRepository {
  Future<List<Approval>> getItems();
}
