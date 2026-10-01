import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class AuthLoadRequested extends AuthEvent {
  const new();
}
