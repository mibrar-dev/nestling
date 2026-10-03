import 'package:equatable/equatable.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';

enum QuestsStatus { initial, loading, loaded, failure }

final class QuestsState extends Equatable {
  const new({
    this.status = QuestsStatus.initial,
    this.items = const <Quest>[],
    this.ideas = const <Quest>[],
    this.errorMessage,
  });

  final QuestsStatus status;
  final List<Quest> items;

  /// Static, never stored P10 "Ideas" templates from the repository. The bloc
  /// owns all repository access (ARCHITECTURE per-feature contract), so the
  /// view reads these from state instead of probing the service locator
  /// (review finding 2 / BUG-P10-8).
  final List<Quest> ideas;
  final String? errorMessage;

  QuestsState copyWith({
    QuestsStatus? status,
    List<Quest>? items,
    List<Quest>? ideas,
    String? errorMessage,
  }) {
    return QuestsState(
      status: status ?? this.status,
      items: items ?? this.items,
      ideas: ideas ?? this.ideas,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, ideas, errorMessage];
}
