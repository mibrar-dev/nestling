import 'package:equatable/equatable.dart';
import 'package:nestling/features/family/domain/entities/family_child.dart';

// Selected-child profile for P15 (child profile): the resolved child plus
// the numbers the view renders — active-quest breakdown by repeat rule,
// completions in the current period, and the owed pocket-money total.
class ChildProfile extends Equatable {
  const new({
    required this.child,
    required this.questsThisWeek,
    required this.dailyActive,
    required this.weeklyActive,
    required this.onceActive,
    required this.owedPence,
  });

  final FamilyChild child;
  final int questsThisWeek;
  final int dailyActive;
  final int weeklyActive;
  final int onceActive;
  final int owedPence;

  @override
  List<Object?> get props => <Object?>[
    child,
    questsThisWeek,
    dailyActive,
    weeklyActive,
    onceActive,
    owedPence,
  ];
}
