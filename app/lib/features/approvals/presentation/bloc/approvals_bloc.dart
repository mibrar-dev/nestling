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
    emit(state.copyWith(busyIds: <int>{...state.busyIds, id}));
    try {
      await _repository.approve(id);
    } on Object catch (error) {
      emit(state.copyWith(actionError: error.toString()));
    } finally {
      emit(state.copyWith(busyIds: Set<int>.of(state.busyIds)..remove(id)));
    }
  }

  Future<void> _onNotYet(
    ApprovalsNotYetRequested event,
    Emitter<ApprovalsState> emit,
  ) async {
    final id = event.completionId;
    emit(state.copyWith(busyIds: <int>{...state.busyIds, id}));
    try {
      await _repository.markNotYet(id);
    } on Object catch (error) {
      emit(state.copyWith(actionError: error.toString()));
    } finally {
      emit(state.copyWith(busyIds: Set<int>.of(state.busyIds)..remove(id)));
    }
  }

  Future<void> _onApproveAll(
    ApprovalsApproveAllRequested event,
    Emitter<ApprovalsState> emit,
  ) async {
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
