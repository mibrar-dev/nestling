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
    this.dueTimeLocal,
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

  /// Floating local due time `HH:MM` evaluated in `families.time_zone`
  /// (e.g. `17:00`); null = no fixed time. Presentation shows it next to
  /// [dueLabel]; the data layer stores it verbatim (no zone conversion —
  /// it is a wall-clock rule, not an instant).
  final String? dueTimeLocal;
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
    dueTimeLocal,
    needsApproval,
    assigneeChildId,
    active,
  ];
}
