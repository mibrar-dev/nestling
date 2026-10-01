import 'package:equatable/equatable.dart';

// Per-child card on the parent Today screen (P08): "4 of 6 quests", coin
// balance and the Pip stage shown on the card.
class ChildDaySummary extends Equatable {
  const new({
    required this.childId,
    required this.nickname,
    required this.avatarColour,
    required this.pipStage,
    required this.done,
    required this.total,
    required this.coins,
  });

  final String childId;
  final String nickname;
  final String avatarColour;
  final int pipStage;
  final int done;
  final int total;
  final int coins;

  @override
  List<Object?> get props => <Object?>[
    childId,
    nickname,
    avatarColour,
    pipStage,
    done,
    total,
    coins,
  ];
}
