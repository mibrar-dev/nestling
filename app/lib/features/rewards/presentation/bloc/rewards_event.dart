import 'package:equatable/equatable.dart';

sealed class RewardsEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class RewardsLoadRequested extends RewardsEvent {
  const new();
}
