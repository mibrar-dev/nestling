import 'dart:async';

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
///
/// [result] is the write's result channel (review finding 1): it completes
/// after the write lands and completes with the error when the write fails,
/// so the editor sheet can stay open with an inline error (plan §4) instead
/// of watching the list state. It is optional — legacy fire-and-forget adds
/// pass nothing and compile unchanged — and is excluded from [props]: it is
/// an identity channel, not value. (A `const` constructor may still declare
/// a `Completer?` parameter; only `const` invocations are restricted.)
final class RewardsNeedsOkChanged extends RewardsEvent {
  const new({required this.id, required this.needsOk, this.result});

  final String id;
  final bool needsOk;
  final Completer<void>? result;

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
    this.result,
  });

  final String title;
  final int coinPrice;
  final bool needsOk;
  final String icon;

  /// Write-result channel; see [RewardsNeedsOkChanged] for the contract.
  final Completer<void>? result;

  @override
  List<Object?> get props => <Object?>[title, coinPrice, needsOk, icon];
}

/// The editor sheet's Save for an existing reward (prefilled).
final class RewardsUpdateRequested extends RewardsEvent {
  const new({required this.reward, this.result});

  final Reward reward;

  /// Write-result channel; see [RewardsNeedsOkChanged] for the contract.
  final Completer<void>? result;

  @override
  List<Object?> get props => <Object?>[reward];
}

/// The editor sheet's Delete (second tap confirms in the sheet itself).
final class RewardsDeleteRequested extends RewardsEvent {
  const new({required this.id, this.result});

  final String id;

  /// Write-result channel; see [RewardsNeedsOkChanged] for the contract.
  final Completer<void>? result;

  @override
  List<Object?> get props => <Object?>[id];
}
