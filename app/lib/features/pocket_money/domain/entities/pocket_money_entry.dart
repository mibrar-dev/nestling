import 'package:equatable/equatable.dart';

// One row in the money ledger (P12): weekly base, quest bonus, gift, spend,
// payout or savings move. Amounts are signed integer pence.
class PocketMoneyEntry extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.detail,
    required this.childId,
    required this.type,
    required this.amountPence,
    required this.note,
    required this.date,
  });

  final int id;
  final String title;
  final String detail;
  final String childId;

  /// `weekly_base | quest_bonus | gift | spend | payout | savings_move`.
  final String type;
  final int amountPence;
  final String note;
  final DateTime date;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    detail,
    childId,
    type,
    amountPence,
    note,
    date,
  ];
}
