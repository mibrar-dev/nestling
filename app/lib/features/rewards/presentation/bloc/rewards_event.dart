import 'package:equatable/equatable.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart';

sealed class RewardsEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class RewardsLoadRequested extends RewardsEvent {
  const new();
}

/// A per-row "Needs my OK" toggle flip (P14 `.okrow`).
final class RewardsNeedsOkChanged extends RewardsEvent {
  const new({required this.id, required this.needsOk});

  final String id;
  final bool needsOk;

  @override
  List<Object?> get props => <Object?>[id, needsOk];
}

/// The editor sheet's Save for a brand-new reward. The repository generates
/// the id (`reward-{ms}`) when the entity id is empty.
final class RewardsCreateRequested extends RewardsEvent {
  const new({
    required this.title,
    required this.coinPrice,
    required this.needsOk,
    required this.icon,
  });

  final String title;
  final int coinPrice;
  final bool needsOk;
  final String icon;

  @override
  List<Object?> get props => <Object?>[title, coinPrice, needsOk, icon];
}

/// The editor sheet's Save for an existing reward (prefilled).
final class RewardsUpdateRequested extends RewardsEvent {
  const new({required this.reward});

  final Reward reward;

  @override
  List<Object?> get props => <Object?>[reward];
}

/// The editor sheet's Delete (second tap confirms in the sheet itself).
final class RewardsDeleteRequested extends RewardsEvent {
  const new({required this.id});

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}
