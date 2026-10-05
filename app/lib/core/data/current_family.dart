// Nestling — current family single source of truth (pre-backend groundwork).
//
// Product code must not depend on the seed constant `Seed.familyId`.
// `Seed.familyId` remains for seeding only; every repository reads the
// current family id from here instead.
//
// One family per device still (no behaviour change): the id is resolved from
// the database at startup — the one `families` row on this device — and
// exposed through get_it (see `app/di.dart`). Repositories take it as an
// optional constructor parameter so existing direct constructions
// (`Repo(db: db)`) keep working in tests; the DI setup always passes the
// shared singleton.
//
// After account deletion (P16 delete → fresh install) there is no `families`
// row until onboarding writes again. [refresh] keeps the previous id when
// the table is empty, so onboarding's `ensureFamily` recreates the same id
// and the holder resolves again without a restart.

import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';

class CurrentFamily {
  CurrentFamily(this._db, String familyId) : _familyId = familyId;

  /// In-memory holder for tests that never touch the database.
  factory CurrentFamily.fallback(AppDatabase db) =>
      CurrentFamily(db, fallbackId);

  /// Fallback when no `families` row exists yet (fresh install, or right
  /// after account deletion before onboarding recreates the row). Mirrors
  /// `Seed.familyId` (`'fam1'`) as a literal: importing the seed from
  /// product code would reintroduce the dependency this class removes.
  static const String fallbackId = 'fam1';

  final AppDatabase _db;
  String _familyId;

  /// The current family id. Stable for the life of the device (one family).
  String get familyId => _familyId;

  /// Alias for call sites that read `.id`.
  String get id => _familyId;

  /// Resolves the current family from the database: the one `families` row
  /// on this device, or [fallbackId] when the table is empty.
  static Future<CurrentFamily> resolve(AppDatabase db) async {
    final rows = await db.select(db.families).get();
    if (rows.isEmpty) return CurrentFamily(db, fallbackId);
    return CurrentFamily(db, rows.first.id);
  }

  /// Re-reads the `families` table. When rows exist the first row wins
  /// (insertion order — one family per device); when empty the previous id
  /// is kept so onboarding can recreate it via [ensureFamily].
  Future<void> refresh() async {
    final rows = await _db.select(_db.families).get();
    if (rows.isNotEmpty) {
      _familyId = rows.first.id;
    }
  }

  /// Ensures the current family's `families` + `settings` rows exist
  /// (insert-or-ignore). Called by onboarding write paths so a fresh install
  /// after account deletion recreates the family without a restart. Existing
  /// rows are never overwritten: notification preferences stay OFF for new
  /// families (nudge rule) and the London `time_zone` table defaults apply.
  Future<String> ensureFamily() async {
    await _db
        .into(_db.families)
        .insert(
          FamiliesCompanion.insert(id: _familyId),
          mode: InsertMode.insertOrIgnore,
        );
    await _db
        .into(_db.settings)
        .insert(
          SettingsCompanion.insert(
            familyId: _familyId,
            notifApprovals: const Value(false),
            notifPayout: const Value(false),
            notifSummary: const Value(false),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    return _familyId;
  }
}
