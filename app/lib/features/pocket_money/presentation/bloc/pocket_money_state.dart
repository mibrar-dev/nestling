import 'package:equatable/equatable.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';

enum PocketMoneyStatus { initial, loading, loaded, failure }

final class PocketMoneyState extends Equatable {
  const new({
    this.status = PocketMoneyStatus.initial,
    this.items = const <PocketMoneyEntry>[],
    this.setup,
    this.errorMessage,
  });

  final PocketMoneyStatus status;
  final List<PocketMoneyEntry> items;

  /// P06 setup (null until the first `watchSetup` emission). Kept alongside
  /// `items` — the same bloc serves `/money` + `/payout`.
  final PocketMoneySetup? setup;
  final String? errorMessage;

  PocketMoneyState copyWith({
    PocketMoneyStatus? status,
    List<PocketMoneyEntry>? items,
    PocketMoneySetup? setup,
    String? errorMessage,
  }) {
    return PocketMoneyState(
      status: status ?? this.status,
      items: items ?? this.items,
      setup: setup ?? this.setup,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, setup, errorMessage];
}
