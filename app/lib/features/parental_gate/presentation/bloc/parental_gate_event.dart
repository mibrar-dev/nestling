import 'package:equatable/equatable.dart';

sealed class ParentalGateEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class ParentalGateLoadRequested extends ParentalGateEvent {
  const new();
}
