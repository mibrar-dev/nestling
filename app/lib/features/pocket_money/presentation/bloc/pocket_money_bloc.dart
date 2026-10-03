import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_ledger_data.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_event.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_state.dart';

class PocketMoneyBloc extends Bloc<PocketMoneyEvent, PocketMoneyState> {
  new({required this._repository}) : super(const PocketMoneyState()) {
    on<PocketMoneyLoadRequested>(_onLoadRequested);
    on<PocketMoneyModeChanged>(_onModeChanged);
    on<PocketMoneyPayoutDayChanged>(_onPayoutDayChanged);
    on<PocketMoneyWeeklyBaseStepped>(_onWeeklyBaseStepped);
    on<PocketMoneyChildSelected>(_onChildSelected);
    on<PocketMoneyAddMoneySubmitted>(_onAddMoneySubmitted);
    on<PocketMoneySpendingSubmitted>(_onSpendingSubmitted);
    on<PocketMoneyPayoutSubmitted>(_onPayoutSubmitted);
  }

  final PocketMoneyRepository _repository;

  /// Last payout-day tap not yet confirmed by the watch stream. The no-op
  /// guard must compare against the last *requested* day, not the last
  /// *emitted* one — otherwise a fast Sun→Sat correction is dropped while the
  /// stream still reports the old day (P06-BUG-02). Cleared on every load
  /// emission, when the stream has caught up.
  int? _pendingDay;

  /// Child ids with a payout write still in flight (P13-BUG-01). Bloc
  /// handlers overlap (see `_requestedBase` above), so a second tap before
  /// the ledger stream proves the first write would otherwise dispatch the
  /// same `recordPayout` again — a duplicate `payout` row, a doubled
  /// `savings_move` and a twice-credited goal. Entries are dropped when the
  /// write settles (success or failure), so a retry after a failure stays
  /// reachable (P13-BUG-04).
  final Set<String> _payoutInFlight = <String>{};

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
    // ONE emit.forEach: `watchLedgerData` already carries the P06 setup
    // inside every emission, so the same bloc serves `/money`,
    // `/pocket-money-setup` and `/payout` from this single subscription
    // (two sequential forEach calls would never reach the second).
    await emit.forEach<MoneyLedgerData>(
      _repository.watchLedgerData().transform(_closeOnError),
      onData: (data) {
        // The stream has caught up: forget confirmed step requests and clear
        // any stale write error (P06-BUG-01, P06-BUG-06). The unconfirmed day
        // request is dropped only once the stream confirms it — an unrelated
        // re-emission still reporting the old day must not swallow a
        // correction tap (P06-BUG-09). The setup arrives inside `data`
        // (fakes without a savings table carry it via the shared test
        // fallback); a previous emission is kept only when the new one has
        // none (hand-built fixtures).
        final setup = data.setup ?? state.setup;
        if (setup != null) {
          if (setup.payoutDay == _pendingDay) _pendingDay = null;
          for (final child in setup.children) {
            if (_requestedBase[child.id] == child.weeklyBasePence) {
              _requestedBase.remove(child.id);
            }
          }
        }
        // Keep the current selection while it still exists; otherwise fall
        // back to the first child in creation order (Maya, then Leo).
        final current = state.selectedChildId;
        final resolved = current != null && data.childById(current) != null
            ? current
            : data.firstChildId;
        return state.copyWith(
          status: PocketMoneyStatus.loaded,
          data: data,
          setup: setup,
          selectedChildId: resolved,
          clearSelectedChildId: resolved == null,
          items: data.entriesFor(resolved),
          clearErrorMessage: true,
        );
      },
      onError: (error, _) => state.copyWith(
        status: PocketMoneyStatus.failure,
        errorMessage: _loadErrorMessage(error),
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

  void _onChildSelected(
    PocketMoneyChildSelected event,
    Emitter<PocketMoneyState> emit,
  ) {
    // Synchronous re-filter: no stream work, no reload. Unknown ids (or a
    // tap before the first load) are a no-op — same guard spirit as the
    // stepper's P06-BUG-07.
    final data = state.data;
    if (data == null || data.childById(event.childId) == null) return;
    if (state.selectedChildId == event.childId) return;
    emit(
      state.copyWith(
        selectedChildId: event.childId,
        items: data.entriesFor(event.childId),
      ),
    );
  }

  Future<void> _onAddMoneySubmitted(
    PocketMoneyAddMoneySubmitted event,
    Emitter<PocketMoneyState> emit,
  ) async {
    // Write-through: the `watchLedgerData` stream re-emits with the new
    // `gift` row. Nothing optimistic — the sheet already validated.
    // A failed submit keeps the loaded ledger and surfaces the message for
    // the view's `NestToast` (unlike the P06 setup writes, which take the
    // whole state to `failure`).
    try {
      await _repository.addMoney(
        childId: event.childId,
        amountPence: event.amountPence,
        note: event.note,
      );
    } on Object catch (error) {
      if (emit.isDone) return;
      emit(state.copyWith(errorMessage: _submitErrorMessage(error)));
    }
  }

  Future<void> _onSpendingSubmitted(
    PocketMoneySpendingSubmitted event,
    Emitter<PocketMoneyState> emit,
  ) async {
    try {
      await _repository.recordSpending(
        childId: event.childId,
        amountPence: event.amountPence,
        note: event.note,
      );
    } on Object catch (error) {
      if (emit.isDone) return;
      emit(state.copyWith(errorMessage: _submitErrorMessage(error)));
    }
  }

  Future<void> _onPayoutSubmitted(
    PocketMoneyPayoutSubmitted event,
    Emitter<PocketMoneyState> emit,
  ) async {
    // P13 "Mark as paid": write-through, mirroring the P12 add/spend
    // submits — the `watchLedgerData` stream re-emits with the new `payout`
    // row (plus the optional `savings_move` + goal bump). A failed submit
    // keeps the loaded sheet and surfaces the message for the view's
    // `NestToast` (no full-screen swap).
    //
    // Non-reentrant per child (P13-BUG-01): the view dispatches one event
    // per ticked child, and a second tap while the first write is still in
    // flight dispatches the same event again. The synchronous `Set.add`
    // runs in event order, so the duplicate is dropped before its write —
    // while a ticked sibling still proceeds. The entry is dropped in
    // `finally`, so a retry after a failure (P13-BUG-04) stays reachable.
    if (!_payoutInFlight.add(event.childId)) return;
    try {
      // A repeated identical failure must stay visible: without this, the
      // retry emits an equal state, Bloc suppresses it and the view's
      // `listenWhen` never fires (P13-BUG-04). Clearing first turns the
      // repeat into null → message again. On the happy path the message is
      // already null, so `copyWith` is equal and nothing emits — the
      // write-through stays silent.
      if (state.errorMessage != null) {
        emit(state.copyWith(clearErrorMessage: true));
      }
      await _repository.recordPayout(
        childId: event.childId,
        amountPence: event.amountPence,
        savingsMovePence: event.savingsMovePence,
        goalId: event.goalId,
      );
    } on Object catch (error) {
      if (emit.isDone) return;
      emit(state.copyWith(errorMessage: _submitErrorMessage(error)));
    } finally {
      _payoutInFlight.remove(event.childId);
    }
  }
}

/// Parent-facing failure copy (review finding 7): a friendly lead sentence
/// a parent can act on, with the raw cause retained after the colon so
/// diagnostics — and the pinned `contains(...)` test expectations — still
/// match. Only the P12 paths use these; the P06 setup writes keep their
/// inherited inline-error format.
String _loadErrorMessage(Object error) =>
    'We couldn\u2019t load your ledger: $error';

String _submitErrorMessage(Object error) =>
    'We couldn\u2019t save that: $error';

/// Errors are terminal: forward the first error, then close — otherwise the
/// failed load's watchers stay subscribed and every "Try again" leaks
/// another full set (same pattern as TodayBloc). Closing lets `emit.forEach`
/// complete and cancel, so the bloc can close cleanly and Retry resubscribes
/// from scratch.
final _closeOnError =
    StreamTransformer<MoneyLedgerData, MoneyLedgerData>.fromHandlers(
      handleError: (error, stackTrace, sink) {
        sink
          ..addError(error, stackTrace)
          ..close();
      },
    );
