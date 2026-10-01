import 'package:equatable/equatable.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';

enum PocketMoneyStatus { initial, loading, loaded, failure }

final class PocketMoneyState extends Equatable {
  const new({
    this.status = PocketMoneyStatus.initial,
    this.items = const <PocketMoneyEntry>[],
    this.errorMessage,
  });

  final PocketMoneyStatus status;
  final List<PocketMoneyEntry> items;
  final String? errorMessage;

  PocketMoneyState copyWith({
    PocketMoneyStatus? status,
    List<PocketMoneyEntry>? items,
    String? errorMessage,
  }) {
    return PocketMoneyState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
