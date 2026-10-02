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
    this.ageYears,
    this.happyDays = 0,
    this.pipStyle = 'mochi',
    this.pipSkin = 'sunny',
    this.pipAccessory = 'none',
  });

  final String childId;
  final String nickname;
  final String avatarColour;
  final int pipStage;
  final int done;
  final int total;
  final int coins;

  /// Age in years (from `children.age_years`); drives the `MAYA · 9` label.
  final int? ageYears;

  /// Happy days this week, 0..7 (from `children.happy_days`).
  final int happyDays;

  /// Pip look (from `children.pip_style/pip_skin/pip_accessory`); fed into
  /// `PipAvatar`. Raw DB strings, mapped in the view.
  final String pipStyle;
  final String pipSkin;
  final String pipAccessory;

  @override
  List<Object?> get props => <Object?>[
    childId,
    nickname,
    avatarColour,
    pipStage,
    done,
    total,
    coins,
    ageYears,
    happyDays,
    pipStyle,
    pipSkin,
    pipAccessory,
  ];
}
