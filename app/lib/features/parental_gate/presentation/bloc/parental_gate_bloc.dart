import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/parental_gate/domain/entities/parental_gate_challenge.dart';
import 'package:nestling/features/parental_gate/domain/parental_gate_repository.dart';
import 'package:nestling/features/parental_gate/presentation/bloc/parental_gate_event.dart';
import 'package:nestling/features/parental_gate/presentation/bloc/parental_gate_state.dart';

class ParentalGateBloc extends Bloc<ParentalGateEvent, ParentalGateState> {
  new({required this._repository}) : super(const ParentalGateState()) {
    on<ParentalGateLoadRequested>(_onLoadRequested);
  }

  final ParentalGateRepository _repository;

  Future<void> _onLoadRequested(
    ParentalGateLoadRequested event,
    Emitter<ParentalGateState> emit,
  ) async {
    emit(state.copyWith(status: ParentalGateStatus.loading));
    await emit.forEach<List<ParentalGateChallenge>>(
      _repository.watchItems(),
      onData: (items) =>
          state.copyWith(status: ParentalGateStatus.loaded, items: items),
      onError: (error, _) => state.copyWith(
        status: ParentalGateStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }
}
