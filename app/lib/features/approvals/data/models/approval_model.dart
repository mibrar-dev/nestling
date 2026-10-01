import 'package:nestling/features/approvals/domain/entities/approval.dart';

class ApprovalModel extends Approval {
  const new({
    required super.id,
    required super.title,
    required super.detail,
    required super.completionId,
    required super.questId,
    required super.questTitle,
    required super.childId,
    required super.childName,
    required super.avatarColour,
    required super.coins,
    required super.createdAt,
  });

  factory ApprovalModel.fromJson(Map<String, dynamic> json) {
    return ApprovalModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
      completionId: json['completionId'] as int,
      questId: json['questId'] as String,
      questTitle: json['questTitle'] as String,
      childId: json['childId'] as String,
      childName: json['childName'] as String,
      avatarColour: json['avatarColour'] as String,
      coins: json['coins'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'detail': detail,
      'completionId': completionId,
      'questId': questId,
      'questTitle': questTitle,
      'childId': childId,
      'childName': childName,
      'avatarColour': avatarColour,
      'coins': coins,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
