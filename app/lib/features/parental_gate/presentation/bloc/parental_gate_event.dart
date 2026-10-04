import 'package:equatable/equatable.dart';

sealed class ParentalGateEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class ParentalGateLoadRequested extends ParentalGateEvent {
  const new();
}

/// One keypad digit (`'0'`–`'9'`). Appends when the gate is loaded, a
/// challenge exists, and a box is still empty; a full entry auto-verifies
/// (correct → unlocked, wrong → cleared + attempts + 1).
final class ParentalGateDigitEntered extends ParentalGateEvent {
  const new(this.digit);

  final String digit;

  @override
  List<Object?> get props => <Object?>[digit];
}

/// The keypad delete key. Drops the last typed digit; no-op when empty.
final class ParentalGateDeletePressed extends ParentalGateEvent {
  const new();
}

/// Resets the unlocked flag after the view navigates (one-shot).
final class ParentalGateUnlockAcknowledged extends ParentalGateEvent {
  const new();
}
