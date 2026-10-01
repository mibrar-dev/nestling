import 'package:nestling/features/kid_shop/domain/entities/shop_reward.dart';

class ShopRewardModel extends ShopReward {
  const new({
    required super.id,
    required super.title,
    required super.detail,
    required super.icon,
    required super.coinPrice,
    required super.needsOk,
    required super.affordable,
  });

  factory ShopRewardModel.fromJson(Map<String, dynamic> json) {
    return ShopRewardModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
      icon: json['icon'] as String,
      coinPrice: json['coinPrice'] as int,
      needsOk: json['needsOk'] as bool,
      affordable: json['affordable'] as bool,
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
      'affordable': affordable,
    };
  }
}
