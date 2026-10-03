import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/auth/domain/auth_repository.dart';
import 'package:nestling/features/auth/domain/entities/auth_account.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_event.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  new({required this._repository}) : super(const AuthState()) {
    on<AuthLoadRequested>(_onLoadRequested);
    on<AuthEmailChanged>(_onEmailChanged);
    on<AuthPasswordChanged>(_onPasswordChanged);
    on<AuthSubmitted>(_onSubmitted);
    on<AuthSocialSubmitted>(_onSocialSubmitted);
    on<AuthSubmitConsumed>(_onSubmitConsumed);
  }

  final AuthRepository _repository;

  Future<void> _onLoadRequested(
    AuthLoadRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    await emit.forEach<List<AuthAccount>>(
      _repository.watchItems(),
      onData: (items) =>
          state.copyWith(status: AuthStatus.loaded, items: items),
      onError: (error, _) => state.copyWith(
        status: AuthStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  void _onEmailChanged(AuthEmailChanged event, Emitter<AuthState> emit) {
    final email = event.email;
    // P03-BUG-2: the value is always written, but the error only appears
    // once the field is dirty (already errored or a submit was attempted).
    // A stale server error still clears on any edit so the form recovers.
    final dirty = state.emailError != null || state.submitAttempted;
    final invalid = dirty && !isAuthEmailValid(email);
    emit(
      state.copyWith(
        email: email,
        emailError: invalid ? authEmailErrorText : null,
        clearEmailError: !invalid,
        clearFormError: state.formError != null,
      ),
    );
  }

  void _onPasswordChanged(AuthPasswordChanged event, Emitter<AuthState> emit) {
    final password = event.password;
    final dirty = state.passwordError != null || state.submitAttempted;
    final invalid = dirty && !isAuthPasswordValid(password);
    emit(
      state.copyWith(
        password: password,
        passwordError: invalid ? authPasswordErrorText : null,
        clearPasswordError: !invalid,
        clearFormError: state.formError != null,
      ),
    );
  }

  Future<void> _onSubmitted(
    AuthSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (state.isSubmitting) return;
    final emailValid = isAuthEmailValid(state.email);
    final passwordValid = isAuthPasswordValid(state.password);
    if (!emailValid || !passwordValid) {
      emit(
        state.copyWith(
          emailError: emailValid ? null : authEmailErrorText,
          clearEmailError: emailValid,
          passwordError: passwordValid ? null : authPasswordErrorText,
          clearPasswordError: passwordValid,
          // From here on the fields are dirty: later keystrokes re-validate
          // live until they are fixed (P03-BUG-2, plan §(b)).
          submitAttempted: true,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        isSubmitting: true,
        clearEmailError: true,
        clearPasswordError: true,
        clearFormError: true,
      ),
    );
    try {
      await _repository.createAccount(email: state.email.trim());
      emit(state.copyWith(isSubmitting: false, submitted: true));
      // P03-BUG-5: a repository failure may be an Error, not an Exception
      // (Drift/SDK internals). Catch Object so a failure always surfaces as
      // a formError instead of stranding the screen in a spinner. P03-BUG-14:
      // re-report to the bloc observer so the stack trace is kept.
    } on Object catch (error, stackTrace) {
      emit(state.copyWith(isSubmitting: false, formError: error.toString()));
      addError(error, stackTrace);
    }
  }

  Future<void> _onSocialSubmitted(
    AuthSocialSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    if (state.isSubmitting) return;
    final provider = event.provider;
    emit(state.copyWith(isSubmitting: true, clearFormError: true));
    try {
      await _repository.createAccountSocial(provider: provider);
      emit(state.copyWith(isSubmitting: false, submitted: true));
      // P03-BUG-5: see _onSubmitted — Errors must surface, not spin forever.
      // P03-BUG-14: keep the stack trace for observers.
    } on Object catch (error, stackTrace) {
      emit(state.copyWith(isSubmitting: false, formError: error.toString()));
      addError(error, stackTrace);
    }
  }

  void _onSubmitConsumed(AuthSubmitConsumed event, Emitter<AuthState> emit) {
    if (!state.submitted) return;
    emit(state.copyWith(submitted: false));
  }
}
