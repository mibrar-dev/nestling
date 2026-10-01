import 'package:equatable/equatable.dart';

sealed class SettingsEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class SettingsLoadRequested extends SettingsEvent {
  const new();
}
