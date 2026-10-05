import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';

class KidQuestModel extends KidQuest {
  const new({
    required super.id,
    required super.title,
    required super.detail,
    required super.questId,
    required super.icon,
    required super.coins,
    required super.status,
    super.needsApproval,
  });

  factory KidQuestModel.fromJson(Map<String, dynamic> json) {
    return KidQuestModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
      questId: json['questId'] as String,
      icon: json['icon'] as String,
      coins: json['coins'] as int,
      status: json['status'] as String,
      needsApproval: json['needsApproval'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'detail': detail,
      'questId': questId,
      'icon': icon,
      'coins': coins,
      'status': status,
      'needsApproval': needsApproval,
    };
  }
}
