import 'package:nestling/features/today/data/today_fake_data_source.dart';
import 'package:nestling/features/today/domain/entities/today_item.dart';
import 'package:nestling/features/today/domain/today_repository.dart';

class TodayRepositoryImpl implements TodayRepository {
  const new({required this._dataSource});

  final TodayFakeDataSource _dataSource;

  @override
  Future<List<TodayItem>> getItems() {
    return Future.value(_dataSource.getItems());
  }
}
