import 'package:equatable/equatable.dart';

sealed class TodayEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class TodayLoadRequested extends TodayEvent {
  const new();
}
