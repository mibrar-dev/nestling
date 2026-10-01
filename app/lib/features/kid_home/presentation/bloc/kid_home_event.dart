import 'package:equatable/equatable.dart';

sealed class KidHomeEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class KidHomeLoadRequested extends KidHomeEvent {
  const new();
}
