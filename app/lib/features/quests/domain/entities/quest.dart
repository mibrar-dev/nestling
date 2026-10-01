import 'package:equatable/equatable.dart';

// A quest template or live quest (P09 editor, P10 library).
class Quest extends Equatable {
  const new({
    required this.id,
    required this.title,
    required this.detail,
    required this.icon,
    required this.coins,
    required this.repeatRule,
    required this.days,
    required this.dueLabel,
    required this.needsApproval,
    required this.assigneeChildId,
    required this.active,
  });

  final String id;
  final String title;
  final String detail;

  /// Icon key (dishwasher, book, bins, bed, …).
  final String icon;
  final int coins;

  /// `once | daily | weekly`.
  final String repeatRule;

  /// CSV of 1..7 (Mon..Sun); empty = no fixed days.
  final String days;
  final String? dueLabel;
  final bool needsApproval;

  /// Null = "Anyone".
  final String? assigneeChildId;
  final bool active;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    detail,
    icon,
    coins,
    repeatRule,
    days,
    dueLabel,
    needsApproval,
    assigneeChildId,
    active,
  ];
}
