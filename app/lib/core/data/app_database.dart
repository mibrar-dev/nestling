// Nestling — local-only database (Drift + SQLite).
//
// One [AppDatabase] owns every table the 30 screens need. Money is integer
// pence; every event instant is stored as a UTC [DateTime] plus the IANA
// zone id in force when it was written (`…_tz`, e.g. `createdAtTz`).
// Calendar rules (daily/weekly periods, payout weekday, `dueTimeLocal`
// `HH:MM`) are floating local rules evaluated in `families.time_zone`
// (see `family_time.dart`).
//
// Conventions shared with screen agents:
// * `family_id` is `'fam1'` in every seed; queries default to it.
// * Completion `status`: `to_do | done_pending | approved | not_yet`.
// * Ledger `type`: `weekly_base | quest_bonus | gift | spend | payout |
//   savings_move`. Amounts are signed pence (`payout`/`spend` negative).
// * `app_state` has exactly one row (`id = 1`).
// * History renders in its stored `…_tz` zone; "today / this week / payout
//   day / due" use the CURRENT `families.time_zone`.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Families extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withDefault(const Constant('Nestling'))();
  // 1 = Mon … 7 = Sun. 6 = Saturday (spec default).
  IntColumn get payoutDay => integer().withDefault(const Constant(6))();
  // Pence per coin. 1 → "10 coins = 10p".
  IntColumn get coinValuePencePerCoin =>
      integer().withDefault(const Constant(1))();
  // weekly | per_quest | both.
  TextColumn get pocketMoneyMode =>
      text().withDefault(const Constant('both'))();
  // IANA zone id for floating calendar rules (schema v2). Never a fixed
  // offset. London default; see `family_time.dart`.
  TextColumn get timeZone =>
      text().withDefault(const Constant('Europe/London'))();
  // Last family/settings update instant (UTC) + the zone in force then.
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get updatedAtTz =>
      text().withDefault(const Constant('Europe/London'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Members extends Table {
  TextColumn get id => text()();
  TextColumn get familyId => text().references(Families, #id)();
  TextColumn get name => text()();
  // owner | co-parent.
  TextColumn get role => text().withDefault(const Constant('owner'))();
  // active | invited.
  TextColumn get inviteStatus => text().withDefault(const Constant('active'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Children extends Table {
  TextColumn get id => text()();
  TextColumn get familyId => text().references(Families, #id)();
  TextColumn get nickname => text()();
  // 4-6 | 7-9 | 10-12 | 13+.
  TextColumn get ageBand => text().withDefault(const Constant('7-9'))();
  IntColumn get ageYears => integer().withDefault(const Constant(7))();
  // lilac | peach | sky | leaf | coin.
  TextColumn get avatarColour => text().withDefault(const Constant('lilac'))();
  // Salted SHA-256 of the 4-digit PIN; null = no PIN.
  TextColumn get pinHash => text().nullable()();
  // mochi | bolt | storybook.
  TextColumn get pipStyle => text().withDefault(const Constant('mochi'))();
  // sunny | berry | sky | mint.
  TextColumn get pipSkin => text().withDefault(const Constant('sunny'))();
  // none | bow | cap | scarf | glasses.
  TextColumn get pipAccessory => text().withDefault(const Constant('none'))();
  IntColumn get pipStage => integer().withDefault(const Constant(1))();
  // Lifetime coins earned — drives Pip evolution (250 = Songbird).
  IntColumn get pipTotalCoins => integer().withDefault(const Constant(0))();
  // Spendable coin balance.
  IntColumn get coins => integer().withDefault(const Constant(0))();
  // 0..5 hearts, never framed negatively in UI.
  IntColumn get happiness => integer().withDefault(const Constant(4))();
  // 0..7 happy days this week (K11 / P15).
  IntColumn get happyDays => integer().withDefault(const Constant(0))();
  IntColumn get weeklyBasePence => integer().withDefault(const Constant(0))();
  // Creation instant (UTC) + the zone in force then (schema v3). Roster
  // order is creation order everywhere (CHILD ORDER ruling): `watchChildren`
  // sorts by this, then `rowid`.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdAtTz =>
      text().withDefault(const Constant('Europe/London'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Quests extends Table {
  TextColumn get id => text()();
  TextColumn get familyId => text().references(Families, #id)();
  TextColumn get title => text()();
  TextColumn get icon => text().withDefault(const Constant('star'))();
  IntColumn get coins => integer().withDefault(const Constant(10))();
  // once | daily | weekly.
  TextColumn get repeatRule => text().withDefault(const Constant('once'))();
  // CSV of 1..7 (Mon..Sun); empty = no fixed days.
  TextColumn get days => text().withDefault(const Constant(''))();
  TextColumn get dueLabel => text().nullable()();
  // Floating local due time `HH:MM` (e.g. `17:00` = "before tea 5pm"),
  // evaluated in `families.time_zone`. Null = no fixed time.
  TextColumn get dueTimeLocal => text().nullable()();
  BoolColumn get needsApproval => boolean().withDefault(const Constant(true))();
  // Null = "Anyone".
  TextColumn get assigneeChildId => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  // Creation instant (UTC) + the zone in force then (schema v4). The Active
  // list is creation order everywhere (orchestrator ruling for P10 §5):
  // `watchActiveQuests` sorts by this, then `id`.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get createdAtTz =>
      text().withDefault(const Constant('Europe/London'))();

  @override
  Set<Column> get primaryKey => {id};
}

class QuestCompletions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get questId => text().references(Quests, #id)();
  TextColumn get childId => text().references(Children, #id)();
  TextColumn get familyId => text().references(Families, #id)();
  // to_do | done_pending | approved | not_yet.
  TextColumn get status => text().withDefault(const Constant('to_do'))();
  // Coin snapshot at completion time.
  IntColumn get coins => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  // IANA zone id in force when the row was written (schema v2).
  TextColumn get createdAtTz =>
      text().withDefault(const Constant('Europe/London'))();
  DateTimeColumn get decidedAt => dateTime().nullable()();
  TextColumn get decidedAtTz =>
      text().withDefault(const Constant('Europe/London'))();
}

class LedgerEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get familyId => text().references(Families, #id)();
  TextColumn get childId => text().references(Children, #id)();
  // weekly_base | quest_bonus | gift | spend | payout | savings_move.
  TextColumn get type => text()();
  // Signed pence.
  IntColumn get amountPence => integer()();
  TextColumn get note => text().withDefault(const Constant(''))();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  // IANA zone id in force when the row was written (schema v2).
  TextColumn get dateTz =>
      text().withDefault(const Constant('Europe/London'))();
}

class SavingsGoals extends Table {
  TextColumn get id => text()();
  TextColumn get familyId => text().references(Families, #id)();
  TextColumn get childId => text().references(Children, #id)();
  TextColumn get title => text()();
  IntColumn get targetPence => integer()();
  IntColumn get savedPence => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Rewards extends Table {
  TextColumn get id => text()();
  TextColumn get familyId => text().references(Families, #id)();
  TextColumn get title => text()();
  TextColumn get icon => text().withDefault(const Constant('gift'))();
  IntColumn get coinPrice => integer()();
  BoolColumn get needsOk => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

class RewardRedemptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get rewardId => text().references(Rewards, #id)();
  TextColumn get childId => text().references(Children, #id)();
  TextColumn get familyId => text().references(Families, #id)();
  // requested | approved | denied.
  TextColumn get status => text().withDefault(const Constant('requested'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  // IANA zone id in force when the row was written (schema v2).
  TextColumn get createdAtTz =>
      text().withDefault(const Constant('Europe/London'))();
}

class Badges extends Table {
  // Stable key: first-quest | bed-maker-7 | kind-helper | bookworm | …
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get icon => text().withDefault(const Constant('medal'))();
  TextColumn get description => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

class EarnedBadges extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get badgeId => text().references(Badges, #id)();
  TextColumn get childId => text().references(Children, #id)();
  TextColumn get familyId => text().references(Families, #id)();
  DateTimeColumn get earnedAt => dateTime().withDefault(currentDateAndTime)();
  // IANA zone id in force when the row was written (schema v2).
  TextColumn get earnedAtTz =>
      text().withDefault(const Constant('Europe/London'))();

  @override
  List<String> get customConstraints => <String>['UNIQUE(badge_id, child_id)'];
}

class PipWardrobe extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get childId => text().references(Children, #id)();
  // scarf | sunhat | wellies | crown.
  TextColumn get item => text()();
  BoolColumn get owned => boolean().withDefault(const Constant(false))();
  IntColumn get priceCoins => integer().withDefault(const Constant(0))();

  @override
  List<String> get customConstraints => <String>['UNIQUE(child_id, item)'];
}

class Settings extends Table {
  TextColumn get familyId => text().references(Families, #id)();
  TextColumn get pocketMoneyMode =>
      text().withDefault(const Constant('both'))();
  IntColumn get payoutDay => integer().withDefault(const Constant(6))();
  IntColumn get coinValuePencePerCoin =>
      integer().withDefault(const Constant(1))();
  BoolColumn get notifApprovals =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get notifPayout => boolean().withDefault(const Constant(true))();
  BoolColumn get notifSummary => boolean().withDefault(const Constant(true))();
  // OFF by default (P04 / ICO nudge rule).
  BoolColumn get crashReportConsent =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get kidGateEnabled =>
      boolean().withDefault(const Constant(true))();
  // Mirror of `families.time_zone` so rule reads never join (schema v2).
  TextColumn get timeZone =>
      text().withDefault(const Constant('Europe/London'))();
  // Last settings update instant (UTC) + the zone in force then.
  DateTimeColumn get updatedAt => dateTime().nullable()();
  TextColumn get updatedAtTz =>
      text().withDefault(const Constant('Europe/London'))();

  @override
  Set<Column> get primaryKey => {familyId};
}

class AppState extends Table {
  IntColumn get id => integer()();
  BoolColumn get onboardingComplete =>
      boolean().withDefault(const Constant(false))();
  // trial | active | expired.
  TextColumn get subscriptionStatus =>
      text().withDefault(const Constant('trial'))();
  DateTimeColumn get trialStart => dateTime().nullable()();
  // IANA zone id in force when the trial started (schema v2).
  TextColumn get trialStartTz =>
      text().withDefault(const Constant('Europe/London'))();
  TextColumn get activeChildId => text().nullable()();
  // parent | kid.
  TextColumn get appMode => text().withDefault(const Constant('parent'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: <Type>[
    Families,
    Members,
    Children,
    Quests,
    QuestCompletions,
    LedgerEntries,
    SavingsGoals,
    Rewards,
    RewardRedemptions,
    Badges,
    EarnedBadges,
    PipWardrobe,
    Settings,
    AppState,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// In-memory database for tests and previews.
  AppDatabase.memory() : super(NativeDatabase.memory());

  /// File-backed database in the app documents directory.
  static Future<AppDatabase> open() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'nestling.db'));
    return AppDatabase(NativeDatabase(file));
  }

  /// Deletes every row (used for `--dart-define=SEED=…` resets).
  Future<void> clearAll() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }

  @override
  int get schemaVersion => 4;

  /// v1 → v2: every event instant gains a `…_tz` zone column, `families`
  /// (+ `settings` mirror) gains `time_zone`, and `quests` gains the
  /// floating `due_time_local` rule. New `NOT NULL … DEFAULT
  /// 'Europe/London'` columns backfill existing rows to London, so a
  /// family that never moves sees byte-identical behaviour.
  ///
  /// v2 → v3: `children` gains `created_at` (+ `created_at_tz`, London
  /// default). `ADD COLUMN` stamps every existing row with the same
  /// `CURRENT_TIMESTAMP`, so the backfill below staggers them one second
  /// apart in `rowid` order — the insertion order — and roster order is
  /// creation order from then on.
  ///
  /// v3 → v4: `quests` gains `created_at` (+ `created_at_tz`, London
  /// default) with the same rowid-order backfill, so the Active list is
  /// creation order on migrated databases too.
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(families, families.timeZone);
        await m.addColumn(families, families.updatedAt);
        await m.addColumn(families, families.updatedAtTz);
        await m.addColumn(quests, quests.dueTimeLocal);
        await m.addColumn(questCompletions, questCompletions.createdAtTz);
        await m.addColumn(questCompletions, questCompletions.decidedAtTz);
        await m.addColumn(ledgerEntries, ledgerEntries.dateTz);
        await m.addColumn(rewardRedemptions, rewardRedemptions.createdAtTz);
        await m.addColumn(earnedBadges, earnedBadges.earnedAtTz);
        await m.addColumn(settings, settings.timeZone);
        await m.addColumn(settings, settings.updatedAt);
        await m.addColumn(settings, settings.updatedAtTz);
        await m.addColumn(appState, appState.trialStartTz);
      }
      if (from < 3) {
        // `children.created_at` (+ `created_at_tz`, London default).
        // SQLite forbids non-constant defaults in `ADD COLUMN` (drift's
        // `currentDateAndTime` default), so the instant column arrives via
        // raw SQL with a constant 0 placeholder and is immediately
        // backfilled below — one second apart in `rowid` (insertion) order,
        // oldest first. `strftime` is UTC seconds; the `+ rowid` arithmetic
        // coerces the (text) timestamp to the integer drift stores
        // `DateTime` as on native. Empty table ⇒ no-op. Fresh installs take
        // the declared `currentDateAndTime` default from `CREATE TABLE`
        // instead, and every write path sets an explicit instant, so the 0
        // placeholder never survives on a real row.
        await m.database.customStatement(
          'ALTER TABLE children ADD COLUMN created_at INTEGER NOT NULL '
          'DEFAULT 0',
        );
        await m.addColumn(children, children.createdAtTz);
        await m.database.customStatement(
          'UPDATE children SET created_at = '
          "strftime('%s', 'now') + rowid - "
          '(SELECT MIN(rowid) FROM children)',
        );
      }
      if (from < 4) {
        // `quests.created_at` (+ `created_at_tz`, London default) — same
        // `ADD COLUMN` trick as v3: constant 0 placeholder, then one second
        // apart in `rowid` (insertion = seed) order, oldest first. The demo
        // seed inserts quests in display order, so migrated databases keep
        // the Active list in the order the quests were added.
        await m.database.customStatement(
          'ALTER TABLE quests ADD COLUMN created_at INTEGER NOT NULL '
          'DEFAULT 0',
        );
        await m.addColumn(quests, quests.createdAtTz);
        await m.database.customStatement(
          'UPDATE quests SET created_at = '
          "strftime('%s', 'now') + rowid - "
          '(SELECT MIN(rowid) FROM quests)',
        );
      }
    },
    beforeOpen: (details) async {
      // Guarantees the single `app_state` row (id 1) exists. A real first
      // install has no seed, and repositories update `WHERE id = 1`, so
      // without this every onboarding/trial/mode write was silently dropped
      // (P01 BUG-4).
      //
      // Also guarantees the `fam1` family + settings rows (P04 first-run
      // bug): P04 is the first onboarding screen that writes a setting and
      // both repositories issue `UPDATE settings WHERE family_id = 'fam1'`,
      // which matches zero rows on a real first launch and silently drops
      // the parent's choice. `crashReportConsent` keeps its table default
      // (OFF, ICO rule). `'fam1'` mirrors `Seed.familyId` (kept a literal:
      // `seed.dart` imports this file, so importing it back would be a
      // cycle). New rows pick up the London `time_zone` table defaults.
      await into(appState).insert(
        const AppStateCompanion(id: Value(1)),
        mode: InsertMode.insertOrIgnore,
      );
      await into(families).insert(
        FamiliesCompanion.insert(id: 'fam1'),
        mode: InsertMode.insertOrIgnore,
      );
      await into(settings).insert(
        SettingsCompanion.insert(familyId: 'fam1'),
        mode: InsertMode.insertOrIgnore,
      );
    },
  );

  // -- Streams shared by repositories -------------------------------------

  /// Current family zone id (`families.time_zone`, London fallback for
  /// missing/unknown values). Calendar rules ("today", "this week", payout
  /// day) are evaluated in this zone; see `family_time.dart`.
  Future<String> familyZoneId([String familyId = 'fam1']) async {
    final row = await (select(
      families,
    )..where((f) => f.id.equals(familyId))).getSingleOrNull();
    final stored = row?.timeZone;
    if (stored == null || stored.isEmpty) return 'Europe/London';
    return stored;
  }

  /// Live stream of the family zone id (London fallback, as above).
  Stream<String> watchFamilyZoneId([String familyId = 'fam1']) {
    return (select(
      families,
    )..where((f) => f.id.equals(familyId))).watchSingleOrNull().map((row) {
      final stored = row?.timeZone;
      if (stored == null || stored.isEmpty) return 'Europe/London';
      return stored;
    });
  }

  /// Roster order (CHILD ORDER ruling): creation order — Maya before Leo in
  /// the seed — never alphabetical. Ties (same-second inserts) fall back to
  /// `rowid`, which is insertion order on every write path.
  Stream<List<ChildrenData>> watchChildren(String familyId) {
    return (select(children)
          ..where((c) => c.familyId.equals(familyId))
          ..orderBy([
            (c) => OrderingTerm(expression: c.createdAt),
            (c) =>
                OrderingTerm(expression: const CustomExpression<int>('rowid')),
          ]))
        .watch();
  }

  /// Active quests in creation order (orchestrator ruling for P10 §5):
  /// oldest first — the order they were added — never alphabetical. Ties
  /// (same-second inserts) fall back to `id`, which is deterministic.
  Stream<List<Quest>> watchActiveQuests(String familyId) {
    return (select(quests)
          ..where((q) => q.familyId.equals(familyId) & q.active.equals(true))
          ..orderBy([
            (q) => OrderingTerm(expression: q.createdAt),
            (q) => OrderingTerm(expression: q.id),
          ]))
        .watch();
  }

  Stream<List<QuestCompletion>> watchCompletionsForChild(String childId) {
    return (select(questCompletions)
          ..where((c) => c.childId.equals(childId))
          ..orderBy([
            (c) =>
                OrderingTerm(expression: c.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<QuestCompletion>> watchPendingApprovals(String familyId) {
    return (select(questCompletions)
          ..where(
            (c) =>
                c.familyId.equals(familyId) & c.status.equals('done_pending'),
          )
          ..orderBy([(c) => OrderingTerm(expression: c.createdAt)]))
        .watch();
  }

  Stream<List<LedgerEntry>> watchLedger(String childId) {
    return (select(ledgerEntries)
          ..where((l) => l.childId.equals(childId))
          ..orderBy([
            (l) => OrderingTerm(expression: l.date, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<Reward>> watchRewards(String familyId) {
    return (select(rewards)
          ..where((r) => r.familyId.equals(familyId))
          ..orderBy([(r) => OrderingTerm(expression: r.coinPrice)]))
        .watch();
  }

  Stream<List<EarnedBadge>> watchEarnedBadges(String childId) {
    return (select(
      earnedBadges,
    )..where((e) => e.childId.equals(childId))).watch();
  }

  Stream<Setting?> watchSetting(String familyId) {
    return (select(
      settings,
    )..where((s) => s.familyId.equals(familyId))).watchSingleOrNull();
  }

  Stream<AppStateData?> watchAppState() {
    return (select(appState)..where((a) => a.id.equals(1))).watchSingleOrNull();
  }

  Stream<ChildrenData?> watchChild(String childId) {
    return (select(
      children,
    )..where((c) => c.id.equals(childId))).watchSingleOrNull();
  }

  Stream<List<QuestCompletion>> watchAllCompletions(String familyId) {
    return (select(questCompletions)
          ..where((c) => c.familyId.equals(familyId))
          ..orderBy([
            (c) =>
                OrderingTerm(expression: c.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<RewardRedemption>> watchRedemptions(String familyId) {
    return (select(rewardRedemptions)
          ..where((r) => r.familyId.equals(familyId))
          ..orderBy([
            (r) =>
                OrderingTerm(expression: r.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<SavingsGoal>> watchGoals(String familyId) {
    return (select(
      savingsGoals,
    )..where((g) => g.familyId.equals(familyId))).watch();
  }

  Stream<List<PipWardrobeData>> watchWardrobe(String childId) {
    return (select(pipWardrobe)
          ..where((w) => w.childId.equals(childId))
          ..orderBy([(w) => OrderingTerm(expression: w.item)]))
        .watch();
  }
}
