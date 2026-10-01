import 'package:equatable/equatable.dart';

// The K09 jar screen state: payout figure, savings goal and fill level.
class JarSummary extends Equatable {
  const new({
    required this.childId,
    required this.owedPence,
    required this.nextPayoutDay,
    required this.goalTitle,
    required this.goalSavedPence,
    required this.goalTargetPence,
  });

  final String childId;

  /// Owed at the next payout (weekly base + quest bonuses).
  final int owedPence;

  /// e.g. "Saturday".
  final String nextPayoutDay;
  final String goalTitle;
  final int goalSavedPence;
  final int goalTargetPence;

  double get fillFraction =>
      goalTargetPence <= 0 ? 0 : goalSavedPence / goalTargetPence;

  @override
  List<Object?> get props => <Object?>[
    childId,
    owedPence,
    nextPayoutDay,
    goalTitle,
    goalSavedPence,
    goalTargetPence,
  ];
}
