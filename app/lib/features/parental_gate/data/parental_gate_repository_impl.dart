import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/current_family.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/features/parental_gate/domain/entities/parental_gate_challenge.dart';
import 'package:nestling/features/parental_gate/domain/parental_gate_repository.dart';

/// Drift-backed [ParentalGateRepository].
class ParentalGateRepositoryImpl implements ParentalGateRepository {
  new({required AppDatabase db, CurrentFamily? currentFamily})
    : _db = db,
      _currentFamily = currentFamily ?? CurrentFamily.fallback(db);

  final AppDatabase _db;
  final CurrentFamily _currentFamily;

  String get _familyId => _currentFamily.familyId;

  @override
  Future<List<ParentalGateChallenge>> getItems() => watchItems().first;

  @override
  Stream<List<ParentalGateChallenge>> watchItems() {
    return _db.watchSetting(_familyId).map((setting) {
      if (setting != null && !setting.kidGateEnabled) {
        return const <ParentalGateChallenge>[];
      }
      return <ParentalGateChallenge>[challengeFor(appNowUtc())];
    });
  }

  @override
  Stream<bool> watchGateEnabled() {
    return _db
        .watchSetting(_familyId)
        .map((setting) => setting?.kidGateEnabled ?? true);
  }

  @override
  Future<void> setGateEnabled({required bool enabled}) {
    return (_db.update(_db.settings)
          ..where((s) => s.familyId.equals(_familyId)))
        .write(SettingsCompanion(kidGateEnabled: Value(enabled)));
  }

  @override
  ParentalGateChallenge challengeFor(DateTime utc) {
    // P17-BUG-2: the gate's day is the Europe/London calendar day, like
    // every other period in the app (PERIODS ruling) — never the UTC date,
    // which would flip the question at 01:00 London during BST.
    final london = toFamilyZone(utc, defaultFamilyZoneId);
    final day = london.day + london.month * 31;
    final a = 2 + (day % 8);
    final b = 2 + ((day ~/ 8) % 8);
    return ParentalGateChallenge(
      id: '${london.year}-${london.month}-${london.day}',
      title: 'Grown-ups only',
      detail: 'This keeps settings and purchases safe.',
      a: a,
      b: b,
    );
  }
}
