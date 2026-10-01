import 'package:nestling/features/approvals/data/approvals_fake_data_source.dart';
import 'package:nestling/features/approvals/domain/approvals_repository.dart';
import 'package:nestling/features/approvals/domain/entities/approval.dart';

class ApprovalsRepositoryImpl implements ApprovalsRepository {
  const new({required this._dataSource});

  final ApprovalsFakeDataSource _dataSource;

  @override
  Future<List<Approval>> getItems() {
    return Future.value(_dataSource.getItems());
  }
}
