import 'package:equatable/equatable.dart';

// A child profile (P05 cards, P15 profile): nickname, age band, avatar
// colour, Pip customisation, balances and weekly progress.
class FamilyChild extends Equatable {
  const new({
    required this.id,
    required this.nickname,
    required this.ageBand,
    required this.ageYears,
    required this.avatarColour,
    required this.pinSet,
    required this.pipStyle,
    required this.pipSkin,
    required this.pipAccessory,
    required this.pipStage,
    required this.pipTotalCoins,
    required this.coins,
    required this.happiness,
    required this.happyDays,
    required this.weeklyBasePence,
    required this.activeQuests,
    required this.doneQuests,
  });

  final String id;
  final String nickname;
  final String ageBand;
  final int ageYears;
  final String avatarColour;
  final bool pinSet;
  final String pipStyle;
  final String pipSkin;
  final String pipAccessory;
  final int pipStage;
  final int pipTotalCoins;
  final int coins;
  final int happiness;
  final int happyDays;
  final int weeklyBasePence;
  final int activeQuests;
  final int doneQuests;

  @override
  List<Object?> get props => <Object?>[
    id,
    nickname,
    ageBand,
    ageYears,
    avatarColour,
    pinSet,
    pipStyle,
    pipSkin,
    pipAccessory,
    pipStage,
    pipTotalCoins,
    coins,
    happiness,
    happyDays,
    weeklyBasePence,
    activeQuests,
    doneQuests,
  ];
}
