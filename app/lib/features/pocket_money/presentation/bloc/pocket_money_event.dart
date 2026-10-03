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

/// P12: the parent switched the child segment (Maya | Leo). Synchronous —
/// no stream work, no reload; the bloc re-filters `items` for that child.
final class PocketMoneyChildSelected extends PocketMoneyEvent {
  const new(this.childId);

  final String childId;

  @override
  List<Object?> get props => <Object?>[childId];
}

/// P12: the "Add money" sheet saved. Pounds→pence parsing and inline
/// validation live in the sheet; the bloc writes a `gift` row and the
/// watch stream re-emits.
final class PocketMoneyAddMoneySubmitted extends PocketMoneyEvent {
  const new(this.childId, this.amountPence, this.note);

  final String childId;
  final int amountPence;
  final String note;

  @override
  List<Object?> get props => <Object?>[childId, amountPence, note];
}

/// P12: the "Record spending" sheet saved (a `spend` row, stored negative).
final class PocketMoneySpendingSubmitted extends PocketMoneyEvent {
  const new(this.childId, this.amountPence, this.note);

  final String childId;
  final int amountPence;
  final String note;

  @override
  List<Object?> get props => <Object?>[childId, amountPence, note];
}
