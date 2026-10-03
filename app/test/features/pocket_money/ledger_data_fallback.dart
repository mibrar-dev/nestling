// Shared fake plumbing for pocket-money tests (P06 + P12).
//
// Moved out of `domain/pocket_money_repository.dart` (review finding 9):
// the domain interface stays abstract-only, and fakes compose this fallback
// with a one-line `watchLedgerData` override.

import 'dart:async';

import 'package:nestling/features/pocket_money/domain/entities/money_child.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_ledger_data.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/domain/entities/savings_goal_data.dart';

/// Fallback `watchLedgerData` for fakes: derived from [setupStream] ×
/// [itemsStream] — each subscribed exactly once, so shared
/// single-subscription stub streams keep working — with no goals (fakes own
/// no savings table). Same `combineLatest` semantics the P06 bloc always
/// used (re-emit when either side emits).
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

/// Same payout-boundary rule as the impl's `summarise`, over entities:
/// the latest `payout` instant is found first, then `weekly_base` +
/// `quest_bonus` rows at or after it are summed (order-independent, so a
/// same-second tie in the `date desc`-only order can never drop a bonus).
OwedSummary _owedFromEntries(String childId, List<PocketMoneyEntry> rows) {
  DateTime? latestPayout;
  for (final row in rows) {
    if (row.childId == childId &&
        row.type == 'payout' &&
        (latestPayout == null || row.date.isAfter(latestPayout))) {
      latestPayout = row.date;
    }
  }
  var base = 0;
  var quests = 0;
  for (final row in rows) {
    if (row.childId != childId) continue;
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

/// Minimal two-stream `combineLatest` (same semantics as
/// `core/data/stream_combine.dart`, kept local so the helper stays
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
