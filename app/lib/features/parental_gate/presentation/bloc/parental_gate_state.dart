import 'package:equatable/equatable.dart';
import 'package:nestling/features/parental_gate/domain/entities/parental_gate_challenge.dart';

enum ParentalGateStatus { initial, loading, loaded, failure }

final class ParentalGateState extends Equatable {
  const new({
    this.status = ParentalGateStatus.initial,
    this.items = const <ParentalGateChallenge>[],
    this.errorMessage,
  });

  final ParentalGateStatus status;
  final List<ParentalGateChallenge> items;
  final String? errorMessage;

  ParentalGateState copyWith({
    ParentalGateStatus? status,
    List<ParentalGateChallenge>? items,
    String? errorMessage,
  }) {
    return ParentalGateState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
