import 'package:nestling/features/family/data/family_fake_data_source.dart';
import 'package:nestling/features/family/domain/entities/family_member.dart';
import 'package:nestling/features/family/domain/family_repository.dart';

class FamilyRepositoryImpl implements FamilyRepository {
  const new({required this._dataSource});

  final FamilyFakeDataSource _dataSource;

  @override
  Future<List<FamilyMember>> getItems() {
    return Future.value(_dataSource.getItems());
  }
}
