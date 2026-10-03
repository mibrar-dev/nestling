import 'package:equatable/equatable.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_ledger_data.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';

enum PocketMoneyStatus { initial, loading, loaded, failure }

final class PocketMoneyState extends Equatable {
  const new({
    this.status = PocketMoneyStatus.initial,
    this.items = const <PocketMoneyEntry>[],
    this.setup,
    this.errorMessage,
    this.data,
    this.selectedChildId,
  });

  final PocketMoneyStatus status;
  final List<PocketMoneyEntry> items;

  /// P06 setup (null until the first emission). Kept alongside `items` —
  /// the same bloc serves `/money` + `/payout` + `/pocket-money-setup`.
  /// Since the P12 iteration this arrives inside [data] (the repository
  /// carries it in every `MoneyLedgerData`); the field stays for compat.
  final PocketMoneySetup? setup;
  final String? errorMessage;

  /// P12 ledger truth (null until the first `watchLedgerData` emission).
  final MoneyLedgerData? data;

  /// Selected child segment (Maya | Leo). Null until the first load, when
  /// the bloc defaults it to the first child in creation order.
  final String? selectedChildId;

  PocketMoneyState copyWith({
    PocketMoneyStatus? status,
    List<PocketMoneyEntry>? items,
    PocketMoneySetup? setup,
    String? errorMessage,

    /// Set to drop a stale message (copyWith cannot express null otherwise).
    /// The load path passes this on every emission (P06-BUG-06).
    bool clearErrorMessage = false,
    MoneyLedgerData? data,
    String? selectedChildId,

    /// Set alongside a null [selectedChildId] to clear the selection (no
    /// children — Seed.empty/fresh). Without it copyWith cannot express
    /// null, mirroring `clearErrorMessage` above.
    bool clearSelectedChildId = false,
  }) {
    return PocketMoneyState(
      status: status ?? this.status,
      items: items ?? this.items,
      setup: setup ?? this.setup,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      data: data ?? this.data,
      selectedChildId: clearSelectedChildId
          ? null
          : (selectedChildId ?? this.selectedChildId),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    items,
    setup,
    errorMessage,
    data,
    selectedChildId,
  ];
}
