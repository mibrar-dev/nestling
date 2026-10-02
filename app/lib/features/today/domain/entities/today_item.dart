import 'package:equatable/equatable.dart';

// One row on the parent Today screen (P08): a quest with its assignee and
// approval state. `title` is the quest title; `detail` is a one-line
// "Maya · waiting for thumbs-up" summary for placeholder views.
class TodayItem extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.questId,
    required this.childId,
    required this.childName,
    required this.status,
    required this.coins,
    this.repeatRule = '',
    this.iconKey = '',
  });

  final String id;
  final String title;
  final String questId;
  final String childId;
  final String childName;

  /// `to_do | done_pending | approved | not_yet`.
  final String status;
  final int coins;

  /// Quest cadence: `once | daily | weekly` (from `quests.repeat_rule`).
  final String repeatRule;

  /// Icon key (from `quests.icon`); mapped to NestIcons in the view.
  final String iconKey;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    questId,
    childId,
    childName,
    status,
    coins,
    repeatRule,
    iconKey,
  ];
}
