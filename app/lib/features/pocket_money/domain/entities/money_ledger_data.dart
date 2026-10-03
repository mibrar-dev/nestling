import 'package:equatable/equatable.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_child.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/domain/entities/savings_goal_data.dart';

// Everything the P12 ledger (`/money`) renders, in one emission. Re-emitted
// whenever ANY underlying table changes (children, ledger, goals, family).
class MoneyLedgerData extends Equatable {
  const new({
    required this.children,
    required this.entries,
    required this.oweds,
    required this.goals,
    required this.payoutDay,
    required this.zoneId,
    this.setup,
  });

  /// Children in creation order (Maya, then Leo) — never alphabetical.
  final List<MoneyChild> children;

  /// Ledger rows for ALL children, newest first (the view filters by the
  /// selected child id).
  final List<PocketMoneyEntry> entries;

  /// One owed summary per child (weekly base + quest bonuses accrued since
  /// the latest payout; gift/spend/savings moves never count).
  final List<OwedSummary> oweds;

  /// Savings goals (the demo seed has one: Maya's Lego fund).
  final List<SavingsGoalData> goals;

  /// 1 = Mon … 7 = Sun. 6 = Saturday (spec default).
  final int payoutDay;

  /// Current `families.time_zone` (floating payout labels render in this).
  final String zoneId;

  /// Full P06 setup (mode/coin/weekly base) carried alongside so the single
  /// `PocketMoneyBloc` serves `/money` + `/pocket-money-setup` + `/payout`
  /// from one stream. Null only in hand-built fixtures; both repository
  /// implementations always provide it.
  final PocketMoneySetup? setup;

  /// First child id, or null when there are no children (Seed.empty/fresh).
  /// The view/bloc default `selectedChildId` to this on the first load.
  String? get firstChildId => children.isEmpty ? null : children.first.id;

  MoneyChild? childById(String id) {
    for (final child in children) {
      if (child.id == id) return child;
    }
    return null;
  }

  /// Entries for one child, newest first. Empty when [childId] is null or
  /// unknown.
  List<PocketMoneyEntry> entriesFor(String? childId) {
    if (childId == null) return const <PocketMoneyEntry>[];
    return entries.where((entry) => entry.childId == childId).toList();
  }

  OwedSummary? owedFor(String childId) {
    for (final owed in oweds) {
      if (owed.childId == childId) return owed;
    }
    return null;
  }

  /// First goal for one child (the P12 card shows at most one), or null.
  SavingsGoalData? goalFor(String childId) {
    for (final goal in goals) {
      if (goal.childId == childId) return goal;
    }
    return null;
  }

  @override
  List<Object?> get props => <Object?>[
    children,
    entries,
    oweds,
    goals,
    payoutDay,
    zoneId,
    setup,
  ];
}
