import 'package:nestling/features/auth/domain/entities/auth_account.dart';

/// Account creation (P03), backed by Drift. Local-only for now: creating an
/// account ensures the owner member row exists.
abstract class AuthRepository {
  Future<List<AuthAccount>> getItems();
  Stream<List<AuthAccount>> watchItems();

  Future<void> createAccount({required String name});
}
