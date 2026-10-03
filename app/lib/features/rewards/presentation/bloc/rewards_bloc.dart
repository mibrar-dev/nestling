import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart';
import 'package:nestling/features/rewards/domain/rewards_repository.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_event.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_state.dart';

class RewardsBloc extends Bloc<RewardsEvent, RewardsState> {
  new({required this._repository}) : super(const RewardsState()) {
    on<RewardsLoadRequested>(_onLoadRequested);
    on<RewardsNeedsOkChanged>(_onNeedsOkChanged);
    on<RewardsCreateRequested>(_onCreateRequested);
    on<RewardsUpdateRequested>(_onUpdateRequested);
    on<RewardsDeleteRequested>(_onDeleteRequested);
  }

  final RewardsRepository _repository;

  Future<void> _onLoadRequested(
    RewardsLoadRequested event,
    Emitter<RewardsState> emit,
  ) async {
    emit(state.copyWith(status: RewardsStatus.loading));
    await emit.forEach<List<Reward>>(
      _repository.watchItems(),
      onData: (items) =>
          state.copyWith(status: RewardsStatus.loaded, items: items),
      onError: (error, _) => state.copyWith(
        status: RewardsStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  // Write handlers below never emit on success: the `watchItems` stream
  // re-emits after every write and the load subscription delivers the new
  // list. Errors surface as `failure` with the message; the next
  // `RewardsLoadRequested` resubscribes from scratch.
  Future<void> _onNeedsOkChanged(
    RewardsNeedsOkChanged event,
    Emitter<RewardsState> emit,
  ) async {
    try {
      await _repository.setNeedsOk(id: event.id, needsOk: event.needsOk);
    } on Object catch (error) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          status: RewardsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onCreateRequested(
    RewardsCreateRequested event,
    Emitter<RewardsState> emit,
  ) async {
    try {
      await _repository.createReward(
        Reward(
          id: '',
          title: event.title,
          detail: '${event.coinPrice} coins',
          icon: event.icon,
          coinPrice: event.coinPrice,
          needsOk: event.needsOk,
        ),
      );
    } on Object catch (error) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          status: RewardsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateRequested(
    RewardsUpdateRequested event,
    Emitter<RewardsState> emit,
  ) async {
    try {
      await _repository.updateReward(event.reward);
    } on Object catch (error) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          status: RewardsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    RewardsDeleteRequested event,
    Emitter<RewardsState> emit,
  ) async {
    try {
      await _repository.deleteReward(event.id);
    } on Object catch (error) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          status: RewardsStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
