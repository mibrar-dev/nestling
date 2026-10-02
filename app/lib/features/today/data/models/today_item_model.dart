import 'package:nestling/features/today/domain/entities/today_item.dart';

class TodayItemModel extends TodayItem {
  const new({
    required super.id,
    required super.title,
    required super.questId,
    required super.childId,
    required super.childName,
    required super.status,
    required super.coins,
    super.repeatRule,
    super.iconKey,
  });

  factory TodayItemModel.fromJson(Map<String, dynamic> json) {
    return TodayItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      questId: json['questId'] as String,
      childId: json['childId'] as String,
      childName: json['childName'] as String,
      status: json['status'] as String,
      coins: json['coins'] as int,
      repeatRule: json['repeatRule'] as String? ?? '',
      iconKey: json['iconKey'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'questId': questId,
      'childId': childId,
      'childName': childName,
      'status': status,
      'coins': coins,
      'repeatRule': repeatRule,
      'iconKey': iconKey,
    };
  }
}
