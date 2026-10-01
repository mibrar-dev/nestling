import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/pip/domain/pip_repository.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_event.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_state.dart';

class PipBloc extends Bloc<PipEvent, PipState> {
  new({required this._repository}) : super(const PipState()) {
    on<PipLoadRequested>(_onLoadRequested);
  }

  final PipRepository _repository;

  Future<void> _onLoadRequested(
    PipLoadRequested event,
    Emitter<PipState> emit,
  ) async {
    emit(state.copyWith(status: PipStatus.loading));
    try {
      final items = await _repository.getItems();
      emit(state.copyWith(status: PipStatus.loaded, items: items));
    } on Exception catch (e) {
      emit(
        state.copyWith(status: PipStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
