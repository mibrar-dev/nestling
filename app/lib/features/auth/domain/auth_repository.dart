import 'package:nestling/features/auth/domain/entities/auth_account.dart';

abstract class AuthRepository {
  Future<List<AuthAccount>> getItems();
}
