import 'package:equatable/equatable.dart';

sealed class PocketMoneyEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class PocketMoneyLoadRequested extends PocketMoneyEvent {
  const new();
}

/// P06: the parent picked a money style (`weekly | per_quest | both`).
/// Write-through — the `watchSetup` stream re-emits.
final class PocketMoneyModeChanged extends PocketMoneyEvent {
  const new(this.mode);

  final String mode;

  @override
  List<Object?> get props => <Object?>[mode];
}

/// P06: the parent picked a payout day (1 = Mon … 7 = Sun).
final class PocketMoneyPayoutDayChanged extends PocketMoneyEvent {
  const new(this.day);

  final int day;

  @override
  List<Object?> get props => <Object?>[day];
}

/// P06: stepper tap for one child's weekly base. The bloc reads the current
/// base from its setup state and writes current + delta (the
/// repository clamps to 0..2000 p).
final class PocketMoneyWeeklyBaseStepped extends PocketMoneyEvent {
  const new(this.childId, this.deltaPence);

  final String childId;
  final int deltaPence;

  @override
  List<Object?> get props => <Object?>[childId, deltaPence];
}
