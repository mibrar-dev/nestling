import 'package:nestling/features/today/domain/entities/today_item.dart';

class TodayItemModel extends TodayItem {
  const new({
    required super.id,
    required super.title,
    required super.detail,
    required super.questId,
    required super.childId,
    required super.childName,
    required super.status,
    required super.coins,
  });

  factory TodayItemModel.fromJson(Map<String, dynamic> json) {
    return TodayItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
      questId: json['questId'] as String,
      childId: json['childId'] as String,
      childName: json['childName'] as String,
      status: json['status'] as String,
      coins: json['coins'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'detail': detail,
      'questId': questId,
      'childId': childId,
      'childName': childName,
      'status': status,
      'coins': coins,
    };
  }
}
