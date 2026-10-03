import 'package:equatable/equatable.dart';

// One savings goal (P12 goal card). The demo seed has a single goal:
// `goal-lego` (Maya) — "Lego Friends set", target 2499p, saved 1550p → 62%.
class SavingsGoalData extends Equatable {
  const new({
    required this.id,
    required this.childId,
    required this.title,
    required this.targetPence,
    required this.savedPence,
  });

  final String id;
  final String childId;
  final String title;
  final int targetPence;
  final int savedPence;

  /// Saved fraction (`savedPence / targetPence`, 0 when the target is not
  /// positive). The view clamps to 0..1 for `NestProgress`.
  double get fraction {
    if (targetPence <= 0) return 0;
    return savedPence / targetPence;
  }

  @override
  List<Object?> get props => <Object?>[
    id,
    childId,
    title,
    targetPence,
    savedPence,
  ];
}
