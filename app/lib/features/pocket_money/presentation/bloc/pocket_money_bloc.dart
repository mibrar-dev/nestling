import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_event.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_state.dart';

class PocketMoneyBloc extends Bloc<PocketMoneyEvent, PocketMoneyState> {
  new({required this._repository}) : super(const PocketMoneyState()) {
    on<PocketMoneyLoadRequested>(_onLoadRequested);
  }

  final PocketMoneyRepository _repository;

  Future<void> _onLoadRequested(
    PocketMoneyLoadRequested event,
    Emitter<PocketMoneyState> emit,
  ) async {
    emit(state.copyWith(status: PocketMoneyStatus.loading));
    await emit.forEach<List<PocketMoneyEntry>>(
      _repository.watchItems(),
      onData: (items) =>
          state.copyWith(status: PocketMoneyStatus.loaded, items: items),
      onError: (error, _) => state.copyWith(
        status: PocketMoneyStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }
}
