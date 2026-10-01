import 'package:nestling/features/kid_home/data/kid_home_fake_data_source.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';

class KidHomeRepositoryImpl implements KidHomeRepository {
  const new({required this._dataSource});

  final KidHomeFakeDataSource _dataSource;

  @override
  Future<List<KidQuest>> getItems() {
    return Future.value(_dataSource.getItems());
  }
}
