import 'package:equatable/equatable.dart';

// A kid's request for a reward: `requested | approved | denied`.
class RewardRedemption extends Equatable {
  const new({
    required this.id,
    required this.rewardId,
    required this.rewardTitle,
    required this.childId,
    required this.childName,
    required this.coinPrice,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final String rewardId;
  final String rewardTitle;
  final String childId;
  final String childName;
  final int coinPrice;
  final String status;
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[
    id,
    rewardId,
    rewardTitle,
    childId,
    childName,
    coinPrice,
    status,
    createdAt,
  ];
}
