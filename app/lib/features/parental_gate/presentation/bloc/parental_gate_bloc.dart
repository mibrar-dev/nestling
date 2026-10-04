import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/parental_gate/domain/entities/parental_gate_challenge.dart';
import 'package:nestling/features/parental_gate/domain/parental_gate_repository.dart';
import 'package:nestling/features/parental_gate/presentation/bloc/parental_gate_event.dart';
import 'package:nestling/features/parental_gate/presentation/bloc/parental_gate_state.dart';

class ParentalGateBloc extends Bloc<ParentalGateEvent, ParentalGateState> {
  new({required this._repository}) : super(const ParentalGateState()) {
    on<ParentalGateLoadRequested>(_onLoadRequested);
    on<ParentalGateDigitEntered>(_onDigitEntered);
    on<ParentalGateDeletePressed>(_onDeletePressed);
    on<ParentalGateUnlockAcknowledged>(_onUnlockAcknowledged);
  }

  final ParentalGateRepository _repository;

  Future<void> _onLoadRequested(
    ParentalGateLoadRequested event,
    Emitter<ParentalGateState> emit,
  ) async {
    emit(state.copyWith(status: ParentalGateStatus.loading, clearError: true));
    await emit.forEach<List<ParentalGateChallenge>>(
      _repository.watchItems(),
      onData: (items) {
        final nextId = items.isEmpty ? null : items.first.id;
        if (nextId != state.challenge?.id) {
          // A new challenge (or the gate toggled): the typed digits and the
          // attempt count belonged to the old question, and the unlock
          // one-shot with it — reset all three (P17-BUG-3). A same-challenge
          // re-emit (an unrelated settings write) keeps the entry.
          return state.copyWith(
            status: ParentalGateStatus.loaded,
            items: items,
            entered: '',
            attempts: 0,
            unlocked: false,
            clearError: true,
          );
        }
        return state.copyWith(
          status: ParentalGateStatus.loaded,
          items: items,
          clearError: true,
        );
      },
      onError: (error, _) => state.copyWith(
        status: ParentalGateStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  void _onDigitEntered(
    ParentalGateDigitEntered event,
    Emitter<ParentalGateState> emit,
  ) {
    if (state.status != ParentalGateStatus.loaded) return;
    if (state.unlocked) return;
    final challenge = state.challenge;
    if (challenge == null) return;
    final digit = event.digit;
    if (digit.length != 1) return;
    final code = digit.codeUnitAt(0);
    if (code < 0x30 || code > 0x39) return;
    if (state.entered.length >= state.expectedLength) return;
    final next = state.entered + digit;
    if (next.length < state.expectedLength) {
      emit(state.copyWith(entered: next));
      return;
    }
    if (challenge.verify(int.parse(next))) {
      emit(state.copyWith(entered: next, unlocked: true));
    } else {
      emit(state.copyWith(entered: '', attempts: state.attempts + 1));
    }
  }

  void _onDeletePressed(
    ParentalGateDeletePressed event,
    Emitter<ParentalGateState> emit,
  ) {
    if (state.unlocked) return;
    if (state.entered.isEmpty) return;
    emit(
      state.copyWith(
        entered: state.entered.substring(0, state.entered.length - 1),
      ),
    );
  }

  void _onUnlockAcknowledged(
    ParentalGateUnlockAcknowledged event,
    Emitter<ParentalGateState> emit,
  ) {
    if (!state.unlocked) return;
    emit(state.copyWith(unlocked: false));
  }
}
