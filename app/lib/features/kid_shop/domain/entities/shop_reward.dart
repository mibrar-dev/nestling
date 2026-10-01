import 'package:equatable/equatable.dart';

// A reward card in the kid shop (K08): price in coins only, with whether the
// active child can afford it right now.
class ShopReward extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.detail,
    required this.icon,
    required this.coinPrice,
    required this.needsOk,
    required this.affordable,
  });

  final String id;
  final String title;
  final String detail;
  final String icon;
  final int coinPrice;
  final bool needsOk;
  final bool affordable;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    detail,
    icon,
    coinPrice,
    needsOk,
    affordable,
  ];
}
