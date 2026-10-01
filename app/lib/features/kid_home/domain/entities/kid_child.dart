import 'package:equatable/equatable.dart';

// The child currently playing in kid mode (K01 picker, K03 header): nickname,
// coin balance and Pip look, read live from the DB.
class KidChild extends Equatable {
  const new({
    required this.id,
    required this.nickname,
    required this.avatarColour,
    required this.coins,
    required this.pipStyle,
    required this.pipSkin,
    required this.pipAccessory,
    required this.pipStage,
    required this.happiness,
    required this.pinSet,
  });

  final String id;
  final String nickname;
  final String avatarColour;
  final int coins;
  final String pipStyle;
  final String pipSkin;
  final String pipAccessory;
  final int pipStage;
  final int happiness;
  final bool pinSet;

  @override
  List<Object?> get props => <Object?>[
    id,
    nickname,
    avatarColour,
    coins,
    pipStyle,
    pipSkin,
    pipAccessory,
    pipStage,
    happiness,
    pinSet,
  ];
}
