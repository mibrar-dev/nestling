import 'dart:async';

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
      _repository.watchItems().transform(_closeOnError),
      onData: (items) =>
          state.copyWith(status: RewardsStatus.loaded, items: items),
      onError: (error, _) => state.copyWith(
        status: RewardsStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  // Write handlers never emit on success: the `watchItems` stream re-emits
  // after every write and the load subscription delivers the new list. They
  // never emit `failure` either (review finding 1 / P14-B03): a failed write
  // must not replace the loaded list with a full-screen error. The only
  // source of the full-screen `failure` state — what `Try again` is for —
  // is the stream's own error in [_onLoadRequested]. A write failure is
  // reported to whoever asked through the event's [result] channel; callers
  // without one (legacy fire-and-forget adds) observe no change, and the
  // list stays as it was.
  Future<void> _onNeedsOkChanged(
    RewardsNeedsOkChanged event,
    Emitter<RewardsState> emit,
  ) async {
    try {
      await _repository.setNeedsOk(id: event.id, needsOk: event.needsOk);
      event.result?.complete();
    } on Object catch (error) {
      _completeError(event.result, error);
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
      event.result?.complete();
    } on Object catch (error) {
      _completeError(event.result, error);
    }
  }

  Future<void> _onUpdateRequested(
    RewardsUpdateRequested event,
    Emitter<RewardsState> emit,
  ) async {
    try {
      await _repository.updateReward(event.reward);
      event.result?.complete();
    } on Object catch (error) {
      _completeError(event.result, error);
    }
  }

  Future<void> _onDeleteRequested(
    RewardsDeleteRequested event,
    Emitter<RewardsState> emit,
  ) async {
    try {
      await _repository.deleteReward(event.id);
      event.result?.complete();
    } on Object catch (error) {
      _completeError(event.result, error);
    }
  }
}

/// Completes a write-event result channel with its error. A settled channel
/// is left alone; a missing channel means a legacy fire-and-forget caller,
/// which observes nothing (the list is unchanged either way).
void _completeError(Completer<void>? result, Object error) {
  if (result == null || result.isCompleted) return;
  result.completeError(error);
}

/// Errors are terminal: forward the first error, then close — otherwise the
/// failed load's subscription stays alive on the dead stream and every
/// `Try again` stacks another subscription on top of it (house pattern:
/// TodayBloc, PocketMoneyBloc; the logic half of P14-B06). Closing lets
/// `emit.forEach` complete and cancel, so the retry resubscribes from
/// scratch with exactly one live subscription.
final _closeOnError =
    StreamTransformer<List<Reward>, List<Reward>>.fromHandlers(
      handleError: (error, stackTrace, sink) {
        sink
          ..addError(error, stackTrace)
          ..close();
      },
    );
