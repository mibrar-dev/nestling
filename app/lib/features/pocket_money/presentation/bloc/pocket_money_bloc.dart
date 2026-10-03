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

  /// Last payout-day tap not yet confirmed by the watch stream. The no-op
  /// guard must compare against the last *requested* day, not the last
  /// *emitted* one — otherwise a fast Sun→Sat correction is dropped while the
  /// stream still reports the old day (P06-BUG-02). Cleared on every load
  /// emission, when the stream has caught up.
  int? _pendingDay;

  /// Latest requested weekly base per child, recorded synchronously when a
  /// step event arrives (before the first await). Step handlers can overlap:
  /// the second `+` tap may run while the first write is still in flight, so
  /// each request must build on the previous *request*, not on the
  /// still-stale `state.setup` — otherwise every tap after the first is lost
  /// (P06-BUG-01). Entries are dropped when the watch stream confirms them
  /// (load emission) or when their write fails.
  final Map<String, int> _requestedBase = {};

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
      onData: (parts) {
        // The stream has caught up: forget confirmed step requests and clear
        // any stale write error (P06-BUG-01, P06-BUG-06). The unconfirmed day
        // request is dropped only once the stream confirms it — an unrelated
        // re-emission still reporting the old day must not swallow a
        // correction tap (P06-BUG-09).
        final setup = parts[1] as PocketMoneySetup;
        if (setup.payoutDay == _pendingDay) _pendingDay = null;
        for (final child in setup.children) {
          if (_requestedBase[child.id] == child.weeklyBasePence) {
            _requestedBase.remove(child.id);
          }
        }
        return state.copyWith(
          status: PocketMoneyStatus.loaded,
          items: parts[0] as List<PocketMoneyEntry>,
          setup: setup,
          clearErrorMessage: true,
        );
      },
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
      // The write may have been in flight when the bloc closed (review #10).
      if (emit.isDone) return;
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
    // Single-select: tapping the requested day is a no-op. Compare against
    // the last requested day (P06-BUG-02), not just the last emitted one.
    final confirmed = _pendingDay ?? state.setup?.payoutDay;
    if (event.day == confirmed) return;
    _pendingDay = event.day;
    try {
      await _repository.setPayoutDay(event.day);
    } on Object catch (error) {
      // The write never landed: unstick the guard so the tap can be retried.
      // Bookkeeping first — it must run even if the emitter is gone.
      if (_pendingDay == event.day) _pendingDay = null;
      if (emit.isDone) return;
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
    // Unknown ids never reach a write (P06-BUG-07). This also covers the
    // pre-load case: with no setup yet there is nothing to step.
    final confirmed = state.setup?.childById(event.childId)?.weeklyBasePence;
    if (confirmed == null) return;
    // Build on the previous request, not on the possibly stale setup: the
    // lines above run synchronously in event order, so an overlapping second
    // tap sees the first tap's request even while its write is in flight
    // (P06-BUG-01). The repository clamps identically, hence the local clamp.
    final target =
        ((_requestedBase[event.childId] ?? confirmed) + event.deltaPence).clamp(
          0,
          2000,
        );
    _requestedBase[event.childId] = target;
    try {
      await _repository.setWeeklyBasePence(event.childId, target);
    } on Object catch (error) {
      // The write never landed: forget the request so the next tap builds on
      // the database truth again.
      _requestedBase.remove(event.childId);
      emit(
        state.copyWith(
          status: PocketMoneyStatus.failure,
          errorMessage: error.toString(),
        ),
      );
      return;
    }
    if (emit.isDone) return;
    // Surface the confirmed value immediately (the stream emission
    // converges to the same value and is deduped; a clamped no-op matches
    // the current state, which bloc suppresses, so the "no further emission"
    // contract still holds).
    final fresh = state.setup?.childById(event.childId)?.weeklyBasePence;
    final setup = state.setup;
    if (setup == null || fresh == target) return;
    emit(
      state.copyWith(
        status: PocketMoneyStatus.loaded,
        setup: setup.withChildBase(event.childId, target),
        clearErrorMessage: true,
      ),
    );
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
