import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/approvals/domain/approvals_repository.dart';
import 'package:nestling/features/approvals/domain/entities/approval.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_event.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_state.dart';

class ApprovalsBloc extends Bloc<ApprovalsEvent, ApprovalsState> {
  new({required this._repository}) : super(const ApprovalsState()) {
    on<ApprovalsLoadRequested>(_onLoadRequested);
    on<ApprovalsApproveRequested>(_onApprove);
    on<ApprovalsNotYetRequested>(_onNotYet);
    on<ApprovalsApproveAllRequested>(_onApproveAll);
    on<ApprovalsActionErrorConsumed>(_onActionErrorConsumed);
  }

  final ApprovalsRepository _repository;

  /// Completion ids already decided in this inbox lifetime (BUG-P11-1).
  /// The busy flag only covers the in-flight window: with an instant write
  /// (or a static stream) a same-frame second tap lands after the first
  /// finished, so it must ALSO be absorbed — otherwise one decision
  /// dispatches two writes. Ids leave the set when the inbox no longer
  /// contains them; failures never enter it, so retry stays possible.
  /// Row ids are never reused, so a retained id can never match a future
  /// completion.
  final Set<int> _decided = <int>{};

  Future<void> _onLoadRequested(
    ApprovalsLoadRequested event,
    Emitter<ApprovalsState> emit,
  ) async {
    emit(state.copyWith(status: ApprovalsStatus.loading));
    await emit.forEach<List<Approval>>(
      _repository.watchItems(),
      onData: (items) {
        // Newest first (matches the design order). The repository streams
        // oldest-first; sorting lives here because the stream order comes
        // from shared core code this feature must not touch. `busyIds` /
        // `approveAllBusy` / `actionError` are preserved: a stream emission
        // racing an in-flight write must not clear its loading state.
        // Decided ids for vanished rows are pruned (see `_decided`).
        _decided.retainWhere((id) => items.any((i) => i.completionId == id));
        final sorted = List<Approval>.of(items)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return state.copyWith(status: ApprovalsStatus.loaded, items: sorted);
      },
      onError: (error, _) => state.copyWith(
        status: ApprovalsStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onApprove(
    ApprovalsApproveRequested event,
    Emitter<ApprovalsState> emit,
  ) async {
    final id = event.completionId;
    // Absorb same-frame repeat taps (BUG-P11-1 widget proof): the busy
    // state only paints on the next frame, so a double-tap dispatches twice
    // before anything disables — and with an instant write the second tap
    // can even land after the first finished (`_decided`). The database CAS
    // below is the backstop for any other path.
    if (state.busyIds.contains(id) || _decided.contains(id)) return;
    emit(
      state.copyWith(
        busyIds: <int>{...state.busyIds, id},
        busyActions: <int, ApprovalsDecision>{
          ...state.busyActions,
          id: ApprovalsDecision.approve,
        },
      ),
    );
    try {
      await _repository.approve(id);
      _decided.add(id);
    } on Object catch (error) {
      emit(state.copyWith(actionError: error.toString()));
    } finally {
      emit(
        state.copyWith(
          busyIds: Set<int>.of(state.busyIds)..remove(id),
          busyActions: Map<int, ApprovalsDecision>.of(state.busyActions)
            ..remove(id),
        ),
      );
    }
  }

  Future<void> _onNotYet(
    ApprovalsNotYetRequested event,
    Emitter<ApprovalsState> emit,
  ) async {
    final id = event.completionId;
    // Same absorb as approve: one decision per card per moment (BUG-P11-1).
    if (state.busyIds.contains(id) || _decided.contains(id)) return;
    emit(
      state.copyWith(
        busyIds: <int>{...state.busyIds, id},
        busyActions: <int, ApprovalsDecision>{
          ...state.busyActions,
          id: ApprovalsDecision.notYet,
        },
      ),
    );
    try {
      await _repository.markNotYet(id);
      _decided.add(id);
    } on Object catch (error) {
      emit(state.copyWith(actionError: error.toString()));
    } finally {
      emit(
        state.copyWith(
          busyIds: Set<int>.of(state.busyIds)..remove(id),
          busyActions: Map<int, ApprovalsDecision>.of(state.busyActions)
            ..remove(id),
        ),
      );
    }
  }

  Future<void> _onApproveAll(
    ApprovalsApproveAllRequested event,
    Emitter<ApprovalsState> emit,
  ) async {
    // Absorb a same-frame second tap on the CTA (BUG-P11-1 widget proof).
    if (state.approveAllBusy) return;
    emit(state.copyWith(approveAllBusy: true));
    try {
      await _repository.approveAll();
    } on Object catch (error) {
      emit(state.copyWith(actionError: error.toString()));
    } finally {
      emit(state.copyWith(approveAllBusy: false));
    }
  }

  void _onActionErrorConsumed(
    ApprovalsActionErrorConsumed event,
    Emitter<ApprovalsState> emit,
  ) {
    emit(state.copyWith(clearActionError: true));
  }
}
