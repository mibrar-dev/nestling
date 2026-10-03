import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';
import 'package:nestling/features/quests/domain/quests_repository.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_event.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_state.dart';

class QuestsBloc extends Bloc<QuestsEvent, QuestsState> {
  new({required this._repository}) : super(const QuestsState()) {
    on<QuestsLoadRequested>(_onLoadRequested);
  }

  final QuestsRepository _repository;

  Future<void> _onLoadRequested(
    QuestsLoadRequested event,
    Emitter<QuestsState> emit,
  ) async {
    // Static templates are read once per load (a const list in the
    // repository) and travel on every state, so the view never probes the
    // service locator (review finding 2 / BUG-P10-8).
    final ideas = _repository.ideas();
    emit(state.copyWith(status: QuestsStatus.loading, ideas: ideas));
    await emit.forEach<List<Quest>>(
      _repository.watchItems(),
      onData: (items) => state.copyWith(
        status: QuestsStatus.loaded,
        items: items,
        ideas: ideas,
      ),
      onError: (error, _) => state.copyWith(
        status: QuestsStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }
}
