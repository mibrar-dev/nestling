import 'package:equatable/equatable.dart';
import 'package:nestling/features/auth/domain/entities/auth_account.dart';

enum AuthStatus { initial, loading, loaded, failure }

final class AuthState extends Equatable {
  const new({
    this.status = AuthStatus.initial,
    this.items = const <AuthAccount>[],
    this.errorMessage,
  });

  final AuthStatus status;
  final List<AuthAccount> items;
  final String? errorMessage;

  AuthState copyWith({
    AuthStatus? status,
    List<AuthAccount>? items,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
