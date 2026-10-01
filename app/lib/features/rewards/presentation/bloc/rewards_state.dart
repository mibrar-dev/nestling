import 'package:equatable/equatable.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart';

enum RewardsStatus { initial, loading, loaded, failure }

final class RewardsState extends Equatable {
  const new({
    this.status = RewardsStatus.initial,
    this.items = const <Reward>[],
    this.errorMessage,
  });

  final RewardsStatus status;
  final List<Reward> items;
  final String? errorMessage;

  RewardsState copyWith({
    RewardsStatus? status,
    List<Reward>? items,
    String? errorMessage,
  }) {
    return RewardsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
