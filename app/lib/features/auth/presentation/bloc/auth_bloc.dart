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
    if (isAuthEmailValid(email)) {
      emit(
        state.copyWith(
          email: email,
          clearEmailError: true,
          clearFormError: state.formError != null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          email: email,
          emailError: authEmailErrorText,
          clearFormError: state.formError != null,
        ),
      );
    }
  }

  void _onPasswordChanged(AuthPasswordChanged event, Emitter<AuthState> emit) {
    final password = event.password;
    if (isAuthPasswordValid(password)) {
      emit(
        state.copyWith(
          password: password,
          clearPasswordError: true,
          clearFormError: state.formError != null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          password: password,
          passwordError: authPasswordErrorText,
          clearFormError: state.formError != null,
        ),
      );
    }
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
    } on Exception catch (error) {
      emit(state.copyWith(isSubmitting: false, formError: error.toString()));
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
    } on Exception catch (error) {
      emit(state.copyWith(isSubmitting: false, formError: error.toString()));
    }
  }

  void _onSubmitConsumed(AuthSubmitConsumed event, Emitter<AuthState> emit) {
    if (!state.submitted) return;
    emit(state.copyWith(submitted: false));
  }
}
