import 'package:equatable/equatable.dart';

// Pip's live state for one child (K06 nest, K07 evolution): look, stage and
// growth progress. Read straight from the child's row — screen agents feed
// these fields into `PipAvatar(style/stage/mood/skin/accessory/inNest)`.
class PipProfile extends Equatable {
  const new({
    required this.childId,
    required this.nickname,
    required this.style,
    required this.skin,
    required this.accessory,
    required this.stage,
    required this.totalCoins,
    required this.coins,
    required this.happiness,
  });

  /// Lifetime coins; Pip evolves into a Songbird at [evolveAtCoins].
  static const int evolveAtCoins = 250;

  final String childId;
  final String nickname;
  final String style;
  final String skin;
  final String accessory;
  final int stage;
  final int totalCoins;
  final int coins;
  final int happiness;

  int get coinsToGrow => (evolveAtCoins - totalCoins).clamp(0, evolveAtCoins);

  @override
  List<Object?> get props => <Object?>[
    childId,
    nickname,
    style,
    skin,
    accessory,
    stage,
    totalCoins,
    coins,
    happiness,
  ];
}
