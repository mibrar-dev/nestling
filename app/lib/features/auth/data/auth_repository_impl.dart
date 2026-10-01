import 'package:nestling/features/auth/data/auth_fake_data_source.dart';
import 'package:nestling/features/auth/domain/auth_repository.dart';
import 'package:nestling/features/auth/domain/entities/auth_account.dart';

class AuthRepositoryImpl implements AuthRepository {
  const new({required this._dataSource});

  final AuthFakeDataSource _dataSource;

  @override
  Future<List<AuthAccount>> getItems() {
    return Future.value(_dataSource.getItems());
  }
}
