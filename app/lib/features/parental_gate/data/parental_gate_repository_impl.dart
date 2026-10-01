import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/parental_gate/domain/entities/parental_gate_challenge.dart';
import 'package:nestling/features/parental_gate/domain/parental_gate_repository.dart';

/// Drift-backed [ParentalGateRepository].
class ParentalGateRepositoryImpl implements ParentalGateRepository {
  new({required this._db});

  final AppDatabase _db;

  @override
  Future<List<ParentalGateChallenge>> getItems() => watchItems().first;

  @override
  Stream<List<ParentalGateChallenge>> watchItems() {
    return _db.watchSetting(Seed.familyId).map((setting) {
      if (setting != null && !setting.kidGateEnabled) {
        return const <ParentalGateChallenge>[];
      }
      return <ParentalGateChallenge>[challengeFor(DateTime.now().toUtc())];
    });
  }

  @override
  Stream<bool> watchGateEnabled() {
    return _db
        .watchSetting(Seed.familyId)
        .map((setting) => setting?.kidGateEnabled ?? true);
  }

  @override
  Future<void> setGateEnabled({required bool enabled}) {
    return (_db.update(_db.settings)
          ..where((s) => s.familyId.equals(Seed.familyId)))
        .write(SettingsCompanion(kidGateEnabled: Value(enabled)));
  }

  @override
  ParentalGateChallenge challengeFor(DateTime utc) {
    final day = utc.day + utc.month * 31;
    final a = 2 + (day % 8);
    final b = 2 + ((day ~/ 8) % 8);
    return ParentalGateChallenge(
      id: '${utc.year}-${utc.month}-${utc.day}',
      title: 'Grown-ups only',
      detail: 'This keeps settings and purchases safe.',
      a: a,
      b: b,
    );
  }
}
