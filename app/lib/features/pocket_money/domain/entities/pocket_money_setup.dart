import 'package:equatable/equatable.dart';

// P06 pocket-money setup (onboarding): the family's money style, payout day,
// coin value and per-child weekly base. Money is integer pence; mode is one
// of `weekly | per_quest | both` (the `families.pocket_money_mode` values).
class PocketMoneySetupChild extends Equatable {
  const new({
    required this.id,
    required this.nickname,
    required this.avatarColour,
    required this.weeklyBasePence,
  });

  final String id;
  final String nickname;

  /// `lilac | peach | sky | leaf | coin`.
  final String avatarColour;
  final int weeklyBasePence;

  @override
  List<Object?> get props => <Object?>[
    id,
    nickname,
    avatarColour,
    weeklyBasePence,
  ];
}

class PocketMoneySetup extends Equatable {
  const new({
    required this.mode,
    required this.payoutDay,
    required this.coinValuePencePerCoin,
    required this.children,
  });

  /// `weekly | per_quest | both`.
  final String mode;

  /// 1 = Mon … 7 = Sun. 6 = Saturday (spec default).
  final int payoutDay;

  /// Pence per coin. 1 → "10 coins = 10p".
  final int coinValuePencePerCoin;

  /// Insertion order (Maya, then Leo) — never alphabetical.
  final List<PocketMoneySetupChild> children;

  PocketMoneySetupChild? childById(String id) {
    for (final child in children) {
      if (child.id == id) return child;
    }
    return null;
  }

  @override
  List<Object?> get props => <Object?>[
    mode,
    payoutDay,
    coinValuePencePerCoin,
    children,
  ];
}
