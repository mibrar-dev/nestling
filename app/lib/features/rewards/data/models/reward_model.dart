import 'package:nestling/features/rewards/domain/entities/reward.dart';

class RewardModel extends Reward {
  const new({
    required super.id,
    required super.title,
    required super.detail,
    required super.icon,
    required super.coinPrice,
    required super.needsOk,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
      icon: json['icon'] as String,
      coinPrice: json['coinPrice'] as int,
      needsOk: json['needsOk'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'detail': detail,
      'icon': icon,
      'coinPrice': coinPrice,
      'needsOk': needsOk,
    };
  }
}
