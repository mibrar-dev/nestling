import 'package:equatable/equatable.dart';

// The K10 payout-day celebration for the active child (K10 plan §b): the
// latest `payout` ledger row rendered back, plus its companion savings move,
// the live savings goal and the child's Pip look. A null stream value means
// no payout was recorded yet, and the view shows its empty state.
class PayoutCelebration extends Equatable {
  const new({
    required this.childId,
    required this.nickname,
    required this.paidPence,
    required this.movedPence,
    required this.goalTitle,
    required this.goalSavedPence,
    required this.goalTargetPence,
    required this.pipStyle,
    required this.pipSkin,
    required this.pipAccessory,
    required this.pipStage,
  });

  final String childId;
  final String nickname;

  /// `abs()` of the latest `payout` row — always positive money handed over.
  final int paidPence;

  /// The companion `savings_move` (`Jar → …`) stamped at or after the payout
  /// instant, or null when the payout moved nothing to savings (note 2 is
  /// then hidden).
  final int? movedPence;

  final String goalTitle;
  final int goalSavedPence;

  /// Zero when the child has no savings goal — the fund card then reads
  /// fraction 0, `of £0.00` / `0% there!`.
  final int goalTargetPence;

  final String pipStyle;
  final String pipSkin;
  final String pipAccessory;
  final int pipStage;

  /// Goal progress clamped to 0…1 for `NestProgress` (saved can overshoot on
  /// a hand-edited row; the card must never render past full).
  double get goalFraction {
    if (goalTargetPence <= 0) return 0;
    final fraction = goalSavedPence / goalTargetPence;
    return fraction.clamp(0, 1).toDouble();
  }

  /// Pence still to go; a hand-edited overshoot reads 0, never negative.
  int get goalRemainingPence {
    final remaining = goalTargetPence - goalSavedPence;
    return remaining < 0 ? 0 : remaining;
  }

  /// Whole-percent progress for the `{percent}% there!` caption (demo Maya:
  /// 1550/2499 → 62; after the plan's `recordPayout` move: 1650/2499 → 66).
  int get goalPercent {
    if (goalTargetPence <= 0) return 0;
    return ((goalSavedPence * 100) / goalTargetPence).round();
  }

  @override
  List<Object?> get props => <Object?>[
    childId,
    nickname,
    paidPence,
    movedPence,
    goalTitle,
    goalSavedPence,
    goalTargetPence,
    pipStyle,
    pipSkin,
    pipAccessory,
    pipStage,
  ];
}
