import 'package:nestling/features/auth/domain/auth_provider.dart';
import 'package:nestling/features/auth/domain/entities/auth_account.dart';

/// Account creation (P03), backed by Drift. Local-only for now: creating an
/// account ensures the owner member row exists.
///
/// The password is never persisted (no email/password columns exist on the
/// members table; schema changes are out of scope) — see `// TODO(P03)` in
/// the impl. Email is used only to derive the owner display name.
///
/// NOTE(P03 isolation): `name` is kept as an optional legacy alias because
/// `app/test/core/data/repositories_test.dart` (shared, out of scope per
/// docs/screens/RULES.md §1) still calls `createAccount(name: ...)`. New
/// callers must pass `email:`. The orchestrator should migrate the shared
/// test to `email:` and restore `required String email` + drop `name`.
abstract class AuthRepository {
  Future<List<AuthAccount>> getItems();
  Stream<List<AuthAccount>> watchItems();

  Future<void> createAccount({String? email, String? name});

  Future<void> createAccountSocial({required AuthProvider provider});
}
