import 'package:equatable/equatable.dart';
import 'package:nestling/features/auth/domain/entities/auth_account.dart';

enum AuthStatus { initial, loading, loaded, failure }

/// Shared validation for P03 (single source used by the bloc and the view).
bool isAuthEmailValid(String email) {
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
}

bool isAuthPasswordValid(String password) => password.length >= 8;

const String authEmailErrorText = 'Enter a valid email address';
const String authPasswordErrorText = 'Use at least 8 characters';

final class AuthState extends Equatable {
  const new({
    this.status = AuthStatus.initial,
    this.items = const <AuthAccount>[],
    this.errorMessage,
    this.email = '',
    this.password = '',
    this.emailError,
    this.passwordError,
    this.isSubmitting = false,
    this.submitted = false,
    this.formError,
  });

  final AuthStatus status;
  final List<AuthAccount> items;
  final String? errorMessage;

  final String email;
  final String password;
  final String? emailError;
  final String? passwordError;
  final bool isSubmitting;
  final bool submitted;
  final String? formError;

  /// Submit CTA enabled iff both fields validate and no submit is in flight.
  bool get canSubmit =>
      isAuthEmailValid(email) && isAuthPasswordValid(password) && !isSubmitting;

  AuthState copyWith({
    AuthStatus? status,
    List<AuthAccount>? items,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? email,
    String? password,
    String? emailError,
    bool clearEmailError = false,
    String? passwordError,
    bool clearPasswordError = false,
    bool? isSubmitting,
    bool? submitted,
    String? formError,
    bool clearFormError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      email: email ?? this.email,
      password: password ?? this.password,
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      passwordError: clearPasswordError
          ? null
          : (passwordError ?? this.passwordError),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitted: submitted ?? this.submitted,
      formError: clearFormError ? null : (formError ?? this.formError),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    items,
    errorMessage,
    email,
    password,
    emailError,
    passwordError,
    isSubmitting,
    submitted,
    formError,
  ];
}
