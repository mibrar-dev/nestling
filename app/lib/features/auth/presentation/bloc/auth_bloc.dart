import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/auth/domain/auth_repository.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_event.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  new({required this._repository}) : super(const AuthState()) {
    on<AuthLoadRequested>(_onLoadRequested);
  }

  final AuthRepository _repository;

  Future<void> _onLoadRequested(
    AuthLoadRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    try {
      final items = await _repository.getItems();
      emit(state.copyWith(status: AuthStatus.loaded, items: items));
    } on Exception catch (e) {
      emit(
        state.copyWith(status: AuthStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
