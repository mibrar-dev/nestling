import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_event.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_state.dart';

class PocketMoneyBloc extends Bloc<PocketMoneyEvent, PocketMoneyState> {
  new({required this._repository}) : super(const PocketMoneyState()) {
    on<PocketMoneyLoadRequested>(_onLoadRequested);
    on<PocketMoneyModeChanged>(_onModeChanged);
    on<PocketMoneyPayoutDayChanged>(_onPayoutDayChanged);
    on<PocketMoneyWeeklyBaseStepped>(_onWeeklyBaseStepped);
  }

  final PocketMoneyRepository _repository;

  Future<void> _onLoadRequested(
    PocketMoneyLoadRequested event,
    Emitter<PocketMoneyState> emit,
  ) async {
    emit(state.copyWith(status: PocketMoneyStatus.loading));
    // ONE emit.forEach: the two streams are combined first (two sequential
    // forEach calls would never reach the second).
    await emit.forEach<List<dynamic>>(
      combineLatest2(
        _repository.watchItems(),
        _repository.watchSetup(),
      ).transform(_closeOnError),
      onData: (parts) => state.copyWith(
        status: PocketMoneyStatus.loaded,
        items: parts[0] as List<PocketMoneyEntry>,
        setup: parts[1] as PocketMoneySetup,
      ),
      onError: (error, _) => state.copyWith(
        status: PocketMoneyStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onModeChanged(
    PocketMoneyModeChanged event,
    Emitter<PocketMoneyState> emit,
  ) async {
    try {
      await _repository.setMode(event.mode);
    } on Object catch (error) {
      emit(
        state.copyWith(
          status: PocketMoneyStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onPayoutDayChanged(
    PocketMoneyPayoutDayChanged event,
    Emitter<PocketMoneyState> emit,
  ) async {
    // Single-select: tapping the selected day is a no-op.
    if (event.day == state.setup?.payoutDay) return;
    try {
      await _repository.setPayoutDay(event.day);
    } on Object catch (error) {
      emit(
        state.copyWith(
          status: PocketMoneyStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onWeeklyBaseStepped(
    PocketMoneyWeeklyBaseStepped event,
    Emitter<PocketMoneyState> emit,
  ) async {
    final current = state.setup?.childById(event.childId)?.weeklyBasePence ?? 0;
    try {
      await _repository.setWeeklyBasePence(
        event.childId,
        current + event.deltaPence,
      );
    } on Object catch (error) {
      emit(
        state.copyWith(
          status: PocketMoneyStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}

/// Errors are terminal: forward the first error, then close — otherwise the
/// failed load's watchers stay subscribed and every "Try again" leaks
/// another full set (same pattern as TodayBloc). Closing lets `emit.forEach`
/// complete and cancel, so the bloc can close cleanly and Retry resubscribes
/// from scratch.
final _closeOnError =
    StreamTransformer<List<dynamic>, List<dynamic>>.fromHandlers(
      handleError: (error, stackTrace, sink) {
        sink
          ..addError(error, stackTrace)
          ..close();
      },
    );
