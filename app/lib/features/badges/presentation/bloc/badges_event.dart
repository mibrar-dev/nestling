import 'package:equatable/equatable.dart';

sealed class BadgesEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class BadgesLoadRequested extends BadgesEvent {
  const new();
}
