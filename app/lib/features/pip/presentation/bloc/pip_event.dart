import 'package:equatable/equatable.dart';

sealed class PipEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class PipLoadRequested extends PipEvent {
  const new();
}
