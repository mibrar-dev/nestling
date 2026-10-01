import 'package:nestling/features/badges/data/badges_fake_data_source.dart';
import 'package:nestling/features/badges/domain/badges_repository.dart';
import 'package:nestling/features/badges/domain/entities/badge.dart';

class BadgesRepositoryImpl implements BadgesRepository {
  const new({required this._dataSource});

  final BadgesFakeDataSource _dataSource;

  @override
  Future<List<Badge>> getItems() {
    return Future.value(_dataSource.getItems());
  }
}
