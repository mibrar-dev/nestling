import 'package:equatable/equatable.dart';

sealed class PocketMoneyEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class PocketMoneyLoadRequested extends PocketMoneyEvent {
  const new();
}
