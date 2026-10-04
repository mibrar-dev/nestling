import 'dart:async';

import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_child.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_ledger_data.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/domain/entities/savings_goal_data.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';

/// Drift-backed [PocketMoneyRepository].
class PocketMoneyRepositoryImpl implements PocketMoneyRepository {
  new({required this._db});

  final AppDatabase _db;

  @override
  Future<List<PocketMoneyEntry>> getItems() => watchItems().first;

  @override
  Stream<List<PocketMoneyEntry>> watchItems() async* {
    final state = await (_db.select(
      _db.appState,
    )..where((a) => a.id.equals(1))).getSingleOrNull();
    final childId = state?.activeChildId ?? 'maya';
    yield* watchLedger(childId);
  }

  @override
  Stream<List<PocketMoneyEntry>> watchLedger(String childId) {
    // History renders in each row's stored zone (named when the family
    // moved); the stream re-emits when the family zone changes.
    return combineLatest2(
      _db.watchLedger(childId),
      _db.watchFamilyZoneId(),
    ).map((parts) {
      final familyZone = normalizeZoneId(parts[1] as String);
      return (parts[0] as List<LedgerEntry>)
          .map((row) => _toEntity(row, familyZone))
          .toList();
    });
  }

  @override
  Future<OwedSummary> owed(String childId) => watchOwed(childId).first;

  @override
  Stream<OwedSummary> watchOwed(String childId) {
    return _db.watchLedger(childId).map((rows) => summarise(childId, rows));
  }

  /// P12 ledger truth: children (creation order) × the per-child ledger
  /// fan-in × goals × family row, re-emitting when ANY table changes.
  ///
  /// The ledger fan-in rebuilds when the roster changes (children are
  /// near-static; `asyncExpand` re-subscribes the per-child `watchLedger`
  /// streams on every roster emission) and generalises to N children — no
  /// fixed per-child subscription. `payoutDay`/`timeZone` come from the
  /// family row; the setup mirror matches `watchSetup()` exactly so the
  /// bloc serves P06 from this one stream.
  @override
  Stream<MoneyLedgerData> watchLedgerData() {
    return _db.watchChildren(Seed.familyId).asyncExpand((kids) {
      final allLedger = kids.isEmpty
          ? Stream<List<LedgerEntry>>.value(const <LedgerEntry>[])
          : _combineLedgers(<Stream<List<LedgerEntry>>>[
              for (final kid in kids) _db.watchLedger(kid.id),
            ]);
      return combineLatest3(
        allLedger,
        _db.watchGoals(Seed.familyId),
        _watchFamily(),
      ).map((parts) {
        final rows = parts[0] as List<LedgerEntry>;
        final goals = parts[1] as List<SavingsGoal>;
        final family = parts[2] as Family?;
        final zone = normalizeZoneId(family?.timeZone);
        final payoutDay = family?.payoutDay ?? 6;
        final setupChildren = <PocketMoneySetupChild>[
          for (final kid in kids)
            PocketMoneySetupChild(
              id: kid.id,
              nickname: kid.nickname,
              avatarColour: kid.avatarColour,
              weeklyBasePence: kid.weeklyBasePence,
            ),
        ];
        return MoneyLedgerData(
          children: <MoneyChild>[
            for (final kid in kids)
              MoneyChild(id: kid.id, nickname: kid.nickname),
          ],
          entries: rows
              .map((row) => _toEntity(row, zone))
              .toList(growable: false),
          oweds: <OwedSummary>[
            for (final kid in kids)
              summarise(
                kid.id,
                rows.where((row) => row.childId == kid.id).toList(),
              ),
          ],
          goals: <SavingsGoalData>[
            for (final goal in goals)
              SavingsGoalData(
                id: goal.id,
                childId: goal.childId,
                title: goal.title,
                targetPence: goal.targetPence,
                savedPence: goal.savedPence,
              ),
          ],
          payoutDay: payoutDay,
          zoneId: zone,
          setup: PocketMoneySetup(
            mode: family?.pocketMoneyMode ?? 'both',
            payoutDay: payoutDay,
            coinValuePencePerCoin: family?.coinValuePencePerCoin ?? 1,
            children: setupChildren,
          ),
        );
      });
    });
  }

  // -- P06 setup -------------------------------------------------------------

  @override
  Stream<PocketMoneySetup> watchSetup() {
    // `families` is the source of truth. The `settings` row is its
    // write-mirror (kept equal by the setters below so P16 never diverges),
    // written in the same transaction — so it is deliberately NOT subscribed:
    // a second subscription would re-emit an identical setup on every
    // mirror write (review #9).
    // Roster order is the canonical CHILD ORDER query (creation order,
    // Maya before Leo — never alphabetical), not a local raw query
    // (review #4).
    return combineLatest2(_watchFamily(), _db.watchChildren(Seed.familyId)).map(
      (parts) {
        final family = parts[0] as Family?;
        final children = parts[1] as List<ChildrenData>;
        return PocketMoneySetup(
          mode: family?.pocketMoneyMode ?? 'both',
          payoutDay: family?.payoutDay ?? 6,
          coinValuePencePerCoin: family?.coinValuePencePerCoin ?? 1,
          children: children
              .map(
                (row) => PocketMoneySetupChild(
                  id: row.id,
                  nickname: row.nickname,
                  avatarColour: row.avatarColour,
                  weeklyBasePence: row.weeklyBasePence,
                ),
              )
              .toList(),
        );
      },
    );
  }

  /// The `families` row for the demo family (null until the first launch
  /// bootstrap in `beforeOpen` inserts it).
  Stream<Family?> _watchFamily() {
    return (_db.select(
      _db.families,
    )..where((f) => f.id.equals(Seed.familyId))).watchSingleOrNull();
  }

  @override
  Future<void> setMode(String mode) async {
    assert(
      mode == 'weekly' || mode == 'per_quest' || mode == 'both',
      'P06 mode must be weekly | per_quest | both, got $mode',
    );
    // The assert above is stripped in release/profile builds, so enforce
    // the invariant there too (review #12). In debug the assert still fires
    // first, which the validation tests pin.
    if (mode != 'weekly' && mode != 'per_quest' && mode != 'both') {
      throw ArgumentError.value(
        mode,
        'mode',
        'P06 mode must be weekly | per_quest | both',
      );
    }
    final now = appNowUtc();
    final zone = await _db.familyZoneId();
    await _db.transaction(() async {
      await (_db.update(
        _db.families,
      )..where((f) => f.id.equals(Seed.familyId))).write(
        FamiliesCompanion(
          pocketMoneyMode: Value(mode),
          updatedAt: Value(now),
          updatedAtTz: Value(zone),
        ),
      );
      await (_db.update(
        _db.settings,
      )..where((s) => s.familyId.equals(Seed.familyId))).write(
        SettingsCompanion(
          pocketMoneyMode: Value(mode),
          updatedAt: Value(now),
          updatedAtTz: Value(zone),
        ),
      );
    });
  }

  @override
  Future<void> setPayoutDay(int day) async {
    assert(day >= 1 && day <= 7, 'P06 payout day must be 1..7, got $day');
    // See setMode: the assert is debug-only, so enforce in release too.
    if (day < 1 || day > 7) {
      throw ArgumentError.value(day, 'day', 'P06 payout day must be 1..7');
    }
    final now = appNowUtc();
    final zone = await _db.familyZoneId();
    await _db.transaction(() async {
      await (_db.update(
        _db.families,
      )..where((f) => f.id.equals(Seed.familyId))).write(
        FamiliesCompanion(
          payoutDay: Value(day),
          updatedAt: Value(now),
          updatedAtTz: Value(zone),
        ),
      );
      await (_db.update(
        _db.settings,
      )..where((s) => s.familyId.equals(Seed.familyId))).write(
        SettingsCompanion(
          payoutDay: Value(day),
          updatedAt: Value(now),
          updatedAtTz: Value(zone),
        ),
      );
    });
  }

  @override
  Future<void> setWeeklyBasePence(String childId, int pence) async {
    await (_db.update(_db.children)..where((c) => c.id.equals(childId))).write(
      ChildrenCompanion(weeklyBasePence: Value(pence.clamp(0, 2000))),
    );
  }

  /// Pure owed math, shared with tests: [rows] is one child's ledger (any
  /// order). Only `weekly_base` + `quest_bonus` rows at or after the latest
  /// `payout` instant count. Order-independent (review finding 4): the latest payout date is found first, then rows
  /// with `date >= payout` are summed — so a `quest_bonus` sharing the
  /// payout's clock second can never be dropped by a tie in the
  /// `date desc`-only ledger order. Rows on the payout instant itself count
  /// (they settled nothing yet); anything strictly before it is settled.
  OwedSummary summarise(String childId, List<LedgerEntry> rows) {
    DateTime? latestPayout;
    for (final row in rows) {
      if (row.type == 'payout' &&
          (latestPayout == null || row.date.isAfter(latestPayout))) {
        latestPayout = row.date;
      }
    }
    var base = 0;
    var quests = 0;
    for (final row in rows) {
      if (row.type != 'weekly_base' && row.type != 'quest_bonus') continue;
      if (latestPayout != null && row.date.isBefore(latestPayout)) continue;
      if (row.type == 'weekly_base') {
        base += row.amountPence;
      } else {
        quests += row.amountPence;
      }
    }
    return OwedSummary(
      childId: childId,
      totalPence: base + quests,
      basePence: base,
      questsPence: quests,
    );
  }

  @override
  Future<void> addMoney({
    required String childId,
    required int amountPence,
    required String note,
  }) async {
    final zone = await _db.familyZoneId();
    await _db
        .into(_db.ledgerEntries)
        .insert(
          LedgerEntriesCompanion.insert(
            familyId: Seed.familyId,
            childId: childId,
            type: 'gift',
            amountPence: amountPence,
            note: Value(note),
            date: Value(appNowUtc()),
            dateTz: Value(zone),
          ),
        );
  }

  @override
  Future<void> recordSpending({
    required String childId,
    required int amountPence,
    required String note,
  }) async {
    final zone = await _db.familyZoneId();
    await _db
        .into(_db.ledgerEntries)
        .insert(
          LedgerEntriesCompanion.insert(
            familyId: Seed.familyId,
            childId: childId,
            type: 'spend',
            amountPence: -amountPence.abs(),
            note: Value(note),
            date: Value(appNowUtc()),
            dateTz: Value(zone),
          ),
        );
  }

  @override
  Future<void> recordPayout({
    required String childId,
    required int amountPence,
    int savingsMovePence = 0,
    String? goalId,
  }) async {
    final now = appNowUtc();
    final zone = await _db.familyZoneId();
    await _db.transaction(() async {
      await _db
          .into(_db.ledgerEntries)
          .insert(
            LedgerEntriesCompanion.insert(
              familyId: Seed.familyId,
              childId: childId,
              type: 'payout',
              amountPence: -amountPence.abs(),
              note: Value('Paid · ${formatDay(now, zone)}'),
              date: Value(now),
              dateTz: Value(zone),
            ),
          );
      if (savingsMovePence > 0 && goalId != null) {
        await _db
            .into(_db.ledgerEntries)
            .insert(
              LedgerEntriesCompanion.insert(
                familyId: Seed.familyId,
                childId: childId,
                type: 'savings_move',
                amountPence: savingsMovePence.abs(),
                note: const Value('Jar → savings goal'),
                date: Value(now),
                dateTz: Value(zone),
              ),
            );
        final goal = await (_db.select(
          _db.savingsGoals,
        )..where((g) => g.id.equals(goalId))).getSingleOrNull();
        if (goal != null) {
          await (_db.update(
            _db.savingsGoals,
          )..where((g) => g.id.equals(goalId))).write(
            SavingsGoalsCompanion(
              savedPence: Value(goal.savedPence + savingsMovePence.abs()),
            ),
          );
        }
      }
    });
  }

  PocketMoneyEntry _toEntity(LedgerEntry row, String familyZone) {
    return PocketMoneyEntry(
      id: row.id,
      title: row.note.isEmpty ? _typeLabel(row.type) : row.note,
      detail:
          '${_typeLabel(row.type)} · ${formatDay(row.date, row.dateTz, familyZoneId: familyZone)} '
          '${formatTime(row.date, row.dateTz, familyZoneId: familyZone)}',
      childId: row.childId,
      type: row.type,
      amountPence: row.amountPence,
      note: row.note,
      date: row.date,
      dateTz: row.dateTz,
    );
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'weekly_base':
        return 'Weekly pocket money';
      case 'quest_bonus':
        return 'Quest bonus';
      case 'gift':
        return 'Added money';
      case 'spend':
        return 'Spent';
      case 'payout':
        return 'Paid';
      case 'savings_move':
        return 'To savings';
      default:
        return type;
    }
  }
}

/// Fan-in for N per-child ledger streams (newest-first each): emits the
/// merged list, newest first, whenever any child ledger emits (after every
/// child has emitted at least once). Generalises `combineLatest2/3/4` (max
/// arity 4 in `stream_combine.dart`) to a near-static roster of any size.
Stream<List<LedgerEntry>> _combineLedgers(
  List<Stream<List<LedgerEntry>>> sources,
) {
  late final StreamController<List<LedgerEntry>> controller;
  controller = StreamController<List<LedgerEntry>>(
    onListen: () {
      final latest = List<List<LedgerEntry>?>.filled(sources.length, null);
      var seen = 0;
      final subs = <StreamSubscription<List<LedgerEntry>>>[];
      for (var i = 0; i < sources.length; i++) {
        subs.add(
          sources[i].listen((rows) {
            if (latest[i] == null) seen++;
            latest[i] = rows;
            if (seen == sources.length) {
              final all = latest.expand((list) => list!).toList()
                ..sort((a, b) => b.date.compareTo(a.date));
              controller.add(List<LedgerEntry>.unmodifiable(all));
            }
          }, onError: controller.addError),
        );
      }
      controller.onCancel = () async {
        for (final sub in subs) {
          await sub.cancel();
        }
      };
    },
  );
  return controller.stream;
}
