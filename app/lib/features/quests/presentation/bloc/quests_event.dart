import 'package:equatable/equatable.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';

sealed class QuestsEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class QuestsLoadRequested extends QuestsEvent {
  const new();
}

/// P09 editor: persist a brand-new quest, then the view navigates to
/// the library (`/quests`). The form draft lives in the view; the bloc
/// only tracks the save attempt via `QuestsState.editorStatus`.
final class QuestsCreateRequested extends QuestsEvent {
  const new(this.quest);

  final Quest quest;

  @override
  List<Object?> get props => <Object?>[quest];
}

/// P09 editor (edit mode): persist changes to an existing quest.
final class QuestsUpdateRequested extends QuestsEvent {
  const new(this.quest);

  final Quest quest;

  @override
  List<Object?> get props => <Object?>[quest];
}

/// P09 editor (edit mode only): delete the quest after the confirm modal.
final class QuestsDeleteRequested extends QuestsEvent {
  const new(this.id);

  final String id;

  @override
  List<Object?> get props => <Object?>[id];
}
