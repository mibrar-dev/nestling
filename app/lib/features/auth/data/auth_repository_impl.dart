import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/auth/domain/auth_provider.dart';
import 'package:nestling/features/auth/domain/auth_repository.dart';
import 'package:nestling/features/auth/domain/entities/auth_account.dart';

/// Drift-backed [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  new({required this._db});

  final AppDatabase _db;

  @override
  Future<List<AuthAccount>> getItems() => watchItems().first;

  @override
  Stream<List<AuthAccount>> watchItems() {
    return (_db.select(
      _db.members,
    )..where((m) => m.familyId.equals(Seed.familyId))).watch().map(
      (rows) => rows
          .map(
            (m) => AuthAccount(
              id: m.id,
              title: m.name,
              detail: m.role == 'owner' ? 'Owner' : 'Co-parent',
              name: m.name,
              role: m.role,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> createAccount({String? email, String? name}) async {
    // TODO(P03): real backend auth. The password is never written anywhere:
    // the members table has no email/password columns.
    final String displayName;
    if (email != null) {
      final local = email.trim().split('@').first.trim();
      displayName = local.isEmpty ? 'Parent' : local;
    } else {
      final legacy = (name ?? '').trim();
      displayName = legacy.isEmpty ? 'Parent' : legacy;
    }
    await _ensureOwner(displayName);
  }

  @override
  Future<void> createAccountSocial({required AuthProvider provider}) async {
    // TODO(P03): real backend auth.
    switch (provider) {
      case AuthProvider.apple:
      case AuthProvider.google:
        await _ensureOwner('Parent');
    }
  }

  Future<void> _ensureOwner(String displayName) async {
    final existing =
        await (_db.select(_db.members)..where(
              (m) => m.familyId.equals(Seed.familyId) & m.role.equals('owner'),
            ))
            .get();
    if (existing.isNotEmpty) return;
    await _db
        .into(_db.members)
        .insert(
          MembersCompanion.insert(
            id: 'owner',
            familyId: Seed.familyId,
            name: displayName,
          ),
        );
  }
}
