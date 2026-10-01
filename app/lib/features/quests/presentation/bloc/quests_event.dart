import 'package:equatable/equatable.dart';

sealed class QuestsEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class QuestsLoadRequested extends QuestsEvent {
  const new();
}
