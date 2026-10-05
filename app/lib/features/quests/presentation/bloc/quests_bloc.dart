import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
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

  /// Parent-safe save-failure copy (review finding 4): programmer errors
  /// must never reach the screen verbatim. The technical error is logged
  /// under `quests` instead.
  static const String saveFailedMessage =
      'Could not save the quest. Try again.';

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
      _repository.watchItems().transform(_closeOnError),
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
          editorError: _editorError(error),
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
          editorError: _editorError(error),
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
          editorError: _editorError(error),
        ),
      );
    }
  }

  /// Maps a save failure to the toast copy. Operational failures (offline,
  /// disk full) surface the repository message — the states suite pins
  /// that — but an [ArgumentError] is a programmer error (today only the
  /// coins range guard, unreachable from the clamped editor) and the
  /// parent gets [saveFailedMessage] while the detail goes to the log.
  String _editorError(Object error) {
    if (error is ArgumentError) {
      // Debug-only: release logs must never carry names, emails or PINs.
      if (kDebugMode) log('quest save rejected: $error', name: 'quests');
      return QuestsBloc.saveFailedMessage;
    }
    return error.toString();
  }
}

/// Errors are terminal: forward the first error, then close — otherwise the
/// failed load's watcher stays subscribed and every "Try again" leaks
/// another one (review finding 3). Closing lets `emit.forEach` complete and
/// cancel, so a retry starts exactly one fresh subscription. Same guard as
/// `today_bloc.dart`, `family_bloc.dart` and `pocket_money_bloc.dart`.
final _closeOnError = StreamTransformer<List<Quest>, List<Quest>>.fromHandlers(
  handleError: (error, stackTrace, sink) {
    sink
      ..addError(error, stackTrace)
      ..close();
  },
);
