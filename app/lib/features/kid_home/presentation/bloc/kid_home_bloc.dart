import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_event.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_state.dart';

class KidHomeBloc extends Bloc<KidHomeEvent, KidHomeState> {
  new({required this._repository}) : super(const KidHomeState()) {
    on<KidHomeLoadRequested>(_onLoadRequested);
  }

  final KidHomeRepository _repository;

  Future<void> _onLoadRequested(
    KidHomeLoadRequested event,
    Emitter<KidHomeState> emit,
  ) async {
    emit(state.copyWith(status: KidHomeStatus.loading));
    await emit.forEach<List<KidQuest>>(
      _repository.watchItems(),
      onData: (items) =>
          state.copyWith(status: KidHomeStatus.loaded, items: items),
      onError: (error, _) => state.copyWith(
        status: KidHomeStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }
}
