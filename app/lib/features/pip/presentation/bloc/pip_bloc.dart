import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/pip/domain/entities/pip_stage.dart';
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
    await emit.forEach<List<PipStage>>(
      _repository.watchItems(),
      onData: (items) => state.copyWith(status: PipStatus.loaded, items: items),
      onError: (error, _) => state.copyWith(
        status: PipStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }
}
