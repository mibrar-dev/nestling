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
    this.ideas = const <Quest>[],
    this.errorMessage,
    this.editorStatus = QuestEditorStatus.initial,
    this.editorError,
  });

  final QuestsStatus status;
  final List<Quest> items;

  /// Static, never stored P10 "Ideas" templates from the repository. The bloc
  /// owns all repository access (ARCHITECTURE per-feature contract), so the
  /// view reads these from state instead of probing the service locator
  /// (review finding 2 / BUG-P10-8).
  final List<Quest> ideas;
  final String? errorMessage;
  final QuestEditorStatus editorStatus;
  final String? editorError;

  QuestsState copyWith({
    QuestsStatus? status,
    List<Quest>? items,
    List<Quest>? ideas,
    String? errorMessage,
    QuestEditorStatus? editorStatus,
    String? editorError,
    bool clearEditorError = false,
  }) {
    return QuestsState(
      status: status ?? this.status,
      items: items ?? this.items,
      ideas: ideas ?? this.ideas,
      errorMessage: errorMessage ?? this.errorMessage,
      editorStatus: editorStatus ?? this.editorStatus,
      editorError: clearEditorError ? null : editorError ?? this.editorError,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    items,
    ideas,
    errorMessage,
    editorStatus,
    editorError,
  ];
}
