import 'package:nestling/features/quests/domain/entities/quest.dart';

class QuestModel extends Quest {
  const new({
    required super.id,
    required super.title,
    required super.detail,
    required super.icon,
    required super.coins,
    required super.repeatRule,
    required super.days,
    required super.dueLabel,
    required super.needsApproval,
    required super.assigneeChildId,
    required super.active,
    super.dueTimeLocal,
  });

  factory QuestModel.fromJson(Map<String, dynamic> json) {
    return QuestModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
      icon: json['icon'] as String,
      coins: json['coins'] as int,
      repeatRule: json['repeatRule'] as String,
      days: json['days'] as String,
      dueLabel: json['dueLabel'] as String?,
      dueTimeLocal: json['dueTimeLocal'] as String?,
      needsApproval: json['needsApproval'] as bool,
      assigneeChildId: json['assigneeChildId'] as String?,
      active: json['active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'detail': detail,
      'icon': icon,
      'coins': coins,
      'repeatRule': repeatRule,
      'days': days,
      'dueLabel': dueLabel,
      'dueTimeLocal': dueTimeLocal,
      'needsApproval': needsApproval,
      'assigneeChildId': assigneeChildId,
      'active': active,
    };
  }
}
