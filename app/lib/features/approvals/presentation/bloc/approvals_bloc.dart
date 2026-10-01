import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/approvals/domain/approvals_repository.dart';
import 'package:nestling/features/approvals/domain/entities/approval.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_event.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_state.dart';

class ApprovalsBloc extends Bloc<ApprovalsEvent, ApprovalsState> {
  new({required this._repository}) : super(const ApprovalsState()) {
    on<ApprovalsLoadRequested>(_onLoadRequested);
  }

  final ApprovalsRepository _repository;

  Future<void> _onLoadRequested(
    ApprovalsLoadRequested event,
    Emitter<ApprovalsState> emit,
  ) async {
    emit(state.copyWith(status: ApprovalsStatus.loading));
    await emit.forEach<List<Approval>>(
      _repository.watchItems(),
      onData: (items) =>
          state.copyWith(status: ApprovalsStatus.loaded, items: items),
      onError: (error, _) => state.copyWith(
        status: ApprovalsStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }
}
