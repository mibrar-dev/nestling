import 'package:equatable/equatable.dart';

// "Maya is owed £4.20": weekly base + quest bonuses accrued since the last
// payout. Gift/spend/savings moves never count towards the payout figure.
class OwedSummary extends Equatable {
  const new({
    required this.childId,
    required this.totalPence,
    required this.basePence,
    required this.questsPence,
  });

  final String childId;
  final int totalPence;
  final int basePence;
  final int questsPence;

  @override
  List<Object?> get props => <Object?>[
    childId,
    totalPence,
    basePence,
    questsPence,
  ];
}
