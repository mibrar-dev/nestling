import 'package:equatable/equatable.dart';

// One row on the parent Today screen (P08): a quest with its assignee and
// approval state. `title` is the quest title; `detail` is a one-line
// "Maya · waiting for thumbs-up" summary for placeholder views.
class TodayItem extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.detail,
    required this.questId,
    required this.childId,
    required this.childName,
    required this.status,
    required this.coins,
  });

  final String id;
  final String title;
  final String detail;
  final String questId;
  final String childId;
  final String childName;

  /// `to_do | done_pending | approved`.
  final String status;
  final int coins;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    detail,
    questId,
    childId,
    childName,
    status,
    coins,
  ];
}
