import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/settings/domain/settings_repository.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_event.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  new({required this._repository}) : super(const SettingsState()) {
    on<SettingsLoadRequested>(_onLoadRequested);
  }

  final SettingsRepository _repository;

  Future<void> _onLoadRequested(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(state.copyWith(status: SettingsStatus.loading));
    try {
      final items = await _repository.getItems();
      emit(state.copyWith(status: SettingsStatus.loaded, items: items));
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: SettingsStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
