import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/today/domain/entities/today_item.dart';
import 'package:nestling/features/today/domain/today_repository.dart';
import 'package:nestling/features/today/presentation/bloc/today_event.dart';
import 'package:nestling/features/today/presentation/bloc/today_state.dart';

class TodayBloc extends Bloc<TodayEvent, TodayState> {
  new({required this._repository}) : super(const TodayState()) {
    on<TodayLoadRequested>(_onLoadRequested);
  }

  final TodayRepository _repository;

  Future<void> _onLoadRequested(
    TodayLoadRequested event,
    Emitter<TodayState> emit,
  ) async {
    emit(state.copyWith(status: TodayStatus.loading));
    await emit.forEach<List<TodayItem>>(
      _repository.watchItems(),
      onData: (items) =>
          state.copyWith(status: TodayStatus.loaded, items: items),
      onError: (error, _) => state.copyWith(
        status: TodayStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }
}
