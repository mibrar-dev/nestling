import 'package:nestling/features/pocket_money/data/pocket_money_fake_data_source.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';

class PocketMoneyRepositoryImpl implements PocketMoneyRepository {
  const new({required this._dataSource});

  final PocketMoneyFakeDataSource _dataSource;

  @override
  Future<List<PocketMoneyEntry>> getItems() {
    return Future.value(_dataSource.getItems());
  }
}
