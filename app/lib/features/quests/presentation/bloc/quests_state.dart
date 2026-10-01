import 'package:equatable/equatable.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart';

enum QuestsStatus { initial, loading, loaded, failure }

final class QuestsState extends Equatable {
  const new({
    this.status = QuestsStatus.initial,
    this.items = const <Quest>[],
    this.errorMessage,
  });

  final QuestsStatus status;
  final List<Quest> items;
  final String? errorMessage;

  QuestsState copyWith({
    QuestsStatus? status,
    List<Quest>? items,
    String? errorMessage,
  }) {
    return QuestsState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
