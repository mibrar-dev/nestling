import 'package:equatable/equatable.dart';
import 'package:nestling/features/auth/domain/auth_provider.dart';

sealed class AuthEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class AuthLoadRequested extends AuthEvent {
  const new();
}

final class AuthEmailChanged extends AuthEvent {
  const new(this.email);

  final String email;

  @override
  List<Object?> get props => <Object?>[email];
}

final class AuthPasswordChanged extends AuthEvent {
  const new(this.password);

  final String password;

  @override
  List<Object?> get props => <Object?>[password];
}

final class AuthSubmitted extends AuthEvent {
  const new();
}

final class AuthSocialSubmitted extends AuthEvent {
  const new(this.provider);

  final AuthProvider provider;

  @override
  List<Object?> get props => <Object?>[provider];
}

final class AuthSubmitConsumed extends AuthEvent {
  const new();
}
