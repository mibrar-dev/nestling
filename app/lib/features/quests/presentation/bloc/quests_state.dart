import 'package:equatable/equatable.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';

enum QuestsStatus { initial, loading, loaded, failure }

/// Save-attempt status for the P09 quest editor. Independent from the
/// list-load [QuestsState.status]: the `items` stream keeps flowing while
/// a save is in flight.
enum QuestEditorStatus { initial, saving, saved, failure }

final class QuestsState extends Equatable {
  const new({
    this.status = QuestsStatus.initial,
    this.items = const <Quest>[],
    this.errorMessage,
    this.editorStatus = QuestEditorStatus.initial,
    this.editorError,
  });

  final QuestsStatus status;
  final List<Quest> items;
  final String? errorMessage;
  final QuestEditorStatus editorStatus;
  final String? editorError;

  QuestsState copyWith({
    QuestsStatus? status,
    List<Quest>? items,
    String? errorMessage,
    QuestEditorStatus? editorStatus,
    String? editorError,
    bool clearEditorError = false,
  }) {
    return QuestsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
      editorStatus: editorStatus ?? this.editorStatus,
      editorError: clearEditorError ? null : editorError ?? this.editorError,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    items,
    errorMessage,
    editorStatus,
    editorError,
  ];
}
