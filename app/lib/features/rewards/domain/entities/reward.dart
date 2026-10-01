import 'package:equatable/equatable.dart';

// A reward in the parent-managed shop (P14): title, coin price and whether a
// kid's request needs the parent's OK first.
class Reward extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.detail,
    required this.icon,
    required this.coinPrice,
    required this.needsOk,
  });

  final String id;
  final String title;
  final String detail;
  final String icon;
  final int coinPrice;
  final bool needsOk;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    detail,
    icon,
    coinPrice,
    needsOk,
  ];
}
