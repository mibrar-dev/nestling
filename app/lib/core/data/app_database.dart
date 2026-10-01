// Nestling — local-only database (Drift + SQLite).
//
// One [AppDatabase] owns every table the 30 screens need. Money is integer
// pence; every timestamp is UTC (display via `london_time.dart`).
//
// Conventions shared with screen agents:
// * `family_id` is `'fam1'` in every seed; queries default to it.
// * Completion `status`: `to_do | done_pending | approved | not_yet`.
// * Ledger `type`: `weekly_base | quest_bonus | gift | spend | payout |
//   savings_move`. Amounts are signed pence (`payout`/`spend` negative).
// * `app_state` has exactly one row (`id = 1`).

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
  BoolColumn get needsApproval => boolean().withDefault(const Constant(true))();
  // Null = "Anyone".
  TextColumn get assigneeChildId => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

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
  DateTimeColumn get decidedAt => dateTime().nullable()();
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
  int get schemaVersion => 1;

  // -- Streams shared by repositories -------------------------------------

  Stream<List<ChildrenData>> watchChildren(String familyId) {
    return (select(children)
          ..where((c) => c.familyId.equals(familyId))
          ..orderBy([(c) => OrderingTerm(expression: c.nickname)]))
        .watch();
  }

  Stream<List<Quest>> watchActiveQuests(String familyId) {
    return (select(quests)
          ..where((q) => q.familyId.equals(familyId) & q.active.equals(true))
          ..orderBy([(q) => OrderingTerm(expression: q.title)]))
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
