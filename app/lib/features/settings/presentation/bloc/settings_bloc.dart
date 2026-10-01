import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/settings/domain/entities/settings_item.dart';
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
    await emit.forEach<List<SettingsItem>>(
      _repository.watchItems(),
      onData: (items) =>
          state.copyWith(status: SettingsStatus.loaded, items: items),
      onError: (error, _) => state.copyWith(
        status: SettingsStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }
}
