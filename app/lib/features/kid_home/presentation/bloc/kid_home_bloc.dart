import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_event.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_state.dart';

class KidHomeBloc extends Bloc<KidHomeEvent, KidHomeState> {
  new({required this._repository}) : super(const KidHomeState()) {
    on<KidHomeLoadRequested>(_onLoadRequested);
    on<KidHomeQuestCompleted>(_onQuestCompleted);
  }

  final KidHomeRepository _repository;

  Future<void> _onLoadRequested(
    KidHomeLoadRequested event,
    Emitter<KidHomeState> emit,
  ) async {
    emit(state.copyWith(status: KidHomeStatus.loading));
    await emit.forEach<List<dynamic>>(
      combineLatest2(_repository.watchActiveChild(), _repository.watchItems()),
      onData: (parts) => state.copyWithLoaded(
        child: parts[0] as KidChild?,
        items: (parts[1] as List<dynamic>).cast<KidQuest>(),
      ),
      onError: (error, _) => state.copyWith(
        status: KidHomeStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onQuestCompleted(
    KidHomeQuestCompleted event,
    Emitter<KidHomeState> emit,
  ) async {
    try {
      await _repository.completeQuest(event.childId, event.questId);
    } on Object catch (error) {
      emit(state.copyWith(actionError: error.toString()));
    }
  }
}
