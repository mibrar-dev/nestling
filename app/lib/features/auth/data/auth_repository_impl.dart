import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
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
  Future<void> createAccount({required String name}) async {
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
            name: name,
          ),
        );
  }
}
