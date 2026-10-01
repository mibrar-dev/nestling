import 'package:flutter_bloc/flutter_bloc.dart';
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
    try {
      final items = await _repository.getItems();
      emit(state.copyWith(status: PocketMoneyStatus.loaded, items: items));
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: PocketMoneyStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
