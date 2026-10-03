import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';
import 'package:nestling/features/quests/domain/quests_repository.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_event.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_state.dart';

class QuestsBloc extends Bloc<QuestsEvent, QuestsState> {
  new({required this._repository}) : super(const QuestsState()) {
    on<QuestsLoadRequested>(_onLoadRequested);
    on<QuestsCreateRequested>(_onCreateRequested);
    on<QuestsUpdateRequested>(_onUpdateRequested);
    on<QuestsDeleteRequested>(_onDeleteRequested);
  }

  final QuestsRepository _repository;

  Future<void> _onLoadRequested(
    QuestsLoadRequested event,
    Emitter<QuestsState> emit,
  ) async {
    emit(state.copyWith(status: QuestsStatus.loading));
    await emit.forEach<List<Quest>>(
      _repository.watchItems(),
      onData: (items) =>
          state.copyWith(status: QuestsStatus.loaded, items: items),
      onError: (error, _) => state.copyWith(
        status: QuestsStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onCreateRequested(
    QuestsCreateRequested event,
    Emitter<QuestsState> emit,
  ) async {
    emit(
      state.copyWith(
        editorStatus: QuestEditorStatus.saving,
        clearEditorError: true,
      ),
    );
    try {
      await _repository.createQuest(event.quest);
      emit(state.copyWith(editorStatus: QuestEditorStatus.saved));
    } on Object catch (error) {
      emit(
        state.copyWith(
          editorStatus: QuestEditorStatus.failure,
          editorError: error.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateRequested(
    QuestsUpdateRequested event,
    Emitter<QuestsState> emit,
  ) async {
    emit(
      state.copyWith(
        editorStatus: QuestEditorStatus.saving,
        clearEditorError: true,
      ),
    );
    try {
      await _repository.updateQuest(event.quest);
      emit(state.copyWith(editorStatus: QuestEditorStatus.saved));
    } on Object catch (error) {
      emit(
        state.copyWith(
          editorStatus: QuestEditorStatus.failure,
          editorError: error.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    QuestsDeleteRequested event,
    Emitter<QuestsState> emit,
  ) async {
    emit(
      state.copyWith(
        editorStatus: QuestEditorStatus.saving,
        clearEditorError: true,
      ),
    );
    try {
      await _repository.deleteQuest(event.id);
      emit(state.copyWith(editorStatus: QuestEditorStatus.saved));
    } on Object catch (error) {
      emit(
        state.copyWith(
          editorStatus: QuestEditorStatus.failure,
          editorError: error.toString(),
        ),
      );
    }
  }
}
