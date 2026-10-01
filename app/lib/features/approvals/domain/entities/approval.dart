import 'package:equatable/equatable.dart';

// One card on the approvals screen (P11): a completed quest awaiting the
// parent's thumbs-up. `title` is the quest title; `detail` is a one-line
// "Maya · Today 8:12am" summary for placeholder views.
class Approval extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.detail,
    required this.completionId,
    required this.questId,
    required this.questTitle,
    required this.childId,
    required this.childName,
    required this.avatarColour,
    required this.coins,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String detail;

  /// Row id in `quest_completions` (int stored as string for view keys).
  final int completionId;
  final String questId;
  final String questTitle;
  final String childId;
  final String childName;
  final String avatarColour;
  final int coins;
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    detail,
    completionId,
    questId,
    questTitle,
    childId,
    childName,
    avatarColour,
    coins,
    createdAt,
  ];
}
