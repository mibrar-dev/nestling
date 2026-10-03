import 'dart:async';

import 'package:nestling/features/pocket_money/domain/entities/money_child.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_ledger_data.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/domain/entities/savings_goal_data.dart';

/// Money ledger + payout (P06 setup, P12 ledger, P13 payout), backed by
/// Drift. The ledger is the single source of money truth; `owed()` derives
/// the payout figure from it (never stored).
abstract class PocketMoneyRepository {
  Future<List<PocketMoneyEntry>> getItems();
  Stream<List<PocketMoneyEntry>> watchItems();

  /// Ledger for one child, newest first.
  Stream<List<PocketMoneyEntry>> watchLedger(String childId);

  /// Everything the P12 ledger renders in one emission (children, all
  /// entries, oweds, goals, payout day, zone, plus the P06 setup carried
  /// alongside so one bloc serves every pocket-money route from one stream).
  Stream<MoneyLedgerData> watchLedgerData();

  /// Base + quest bonuses since the last payout.
  Future<OwedSummary> owed(String childId);
  Stream<OwedSummary> watchOwed(String childId);

  Future<void> addMoney({
    required String childId,
    required int amountPence,
    required String note,
  });
  Future<void> recordSpending({
    required String childId,
    required int amountPence,
    required String note,
  });

  /// P13 "Mark as paid": writes a negative `payout` entry (and an optional
  /// `savings_move` + goal bump) so the next `owed()` starts from zero.
  Future<void> recordPayout({
    required String childId,
    required int amountPence,
    int savingsMovePence = 0,
    String? goalId,
  });

  // -- P06 setup (onboarding) ------------------------------------------------

  /// Family money style + payout day + coin value + per-child weekly base.
  /// Children arrive in insertion order (Maya, then Leo).
  Stream<PocketMoneySetup> watchSetup();

  /// One of `weekly | per_quest | both`. Writes `families` AND the
  /// `settings` mirror in one transaction.
  Future<void> setMode(String mode);

  /// 1 = Mon … 7 = Sun. Writes `families` AND the `settings` mirror.
  Future<void> setPayoutDay(int day);

  /// Weekly base for one child, clamped to 0..2000 pence. Writes the
  /// `children` row (the single copy — no mirror table carries it).
  Future<void> setWeeklyBasePence(String childId, int pence);
}

/// Fallback `watchLedgerData` for fakes/tests: derived from [setupStream] ×
/// [itemsStream] — each subscribed exactly once, so shared
/// single-subscription stub streams keep working — with no goals (fakes own
/// no savings table). The Drift implementation overrides the interface
/// method with the full per-child ledger fan-in, goals and family row.
///
/// Same `combineLatest` semantics the P06 bloc always used (re-emit when
/// either side emits), so existing P06 fake-driven tests observe identical
/// behaviour through the new single-stream bloc.
Stream<MoneyLedgerData> ledgerDataFallback(
  Stream<PocketMoneySetup> setupStream,
  Stream<List<PocketMoneyEntry>> itemsStream,
) {
  return _combineLatest2(setupStream, itemsStream).map((parts) {
    final setup = parts[0] as PocketMoneySetup;
    final rows = List<PocketMoneyEntry>.of(parts[1] as List<PocketMoneyEntry>)
      ..sort((a, b) => b.date.compareTo(a.date));
    return MoneyLedgerData(
      children: <MoneyChild>[
        for (final child in setup.children)
          MoneyChild(id: child.id, nickname: child.nickname),
      ],
      entries: rows,
      oweds: <OwedSummary>[
        for (final child in setup.children) _owedFromEntries(child.id, rows),
      ],
      goals: const <SavingsGoalData>[],
      payoutDay: setup.payoutDay,
      zoneId: rows.isEmpty ? 'Europe/London' : rows.first.dateTz,
      setup: setup,
    );
  });
}

/// Same payout-boundary rule as `summarise` (impl), over entities:
/// newest-first [rows] for every child; only `weekly_base` + `quest_bonus`
/// rows after the latest `payout` count for [childId].
OwedSummary _owedFromEntries(String childId, List<PocketMoneyEntry> rows) {
  var base = 0;
  var quests = 0;
  for (final row in rows) {
    if (row.childId != childId) continue;
    if (row.type == 'payout') break;
    if (row.type == 'weekly_base') base += row.amountPence;
    if (row.type == 'quest_bonus') quests += row.amountPence;
  }
  return OwedSummary(
    childId: childId,
    totalPence: base + quests,
    basePence: base,
    questsPence: quests,
  );
}

/// Minimal two-stream `combineLatest` (same semantics as
/// `core/data/stream_combine.dart`, kept local so the domain interface stays
/// dependency-free): re-emits `[a, b]` whenever either source emits, after
/// both have emitted at least once.
Stream<List<dynamic>> _combineLatest2(Stream<dynamic> a, Stream<dynamic> b) {
  late final StreamController<List<dynamic>> controller;
  controller = StreamController<List<dynamic>>(
    onListen: () {
      dynamic latestA;
      dynamic latestB;
      var seenA = false;
      var seenB = false;
      void emitIfReady() {
        if (seenA && seenB) {
          controller.add(<dynamic>[latestA, latestB]);
        }
      }

      final subA = a.listen((value) {
        latestA = value;
        seenA = true;
        emitIfReady();
      }, onError: controller.addError);
      final subB = b.listen((value) {
        latestB = value;
        seenB = true;
        emitIfReady();
      }, onError: controller.addError);
      controller.onCancel = () async {
        await subA.cancel();
        await subB.cancel();
      };
    },
  );
  return controller.stream;
}
