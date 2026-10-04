import 'package:equatable/equatable.dart';
import 'package:nestling/features/pip/domain/entities/pip_profile.dart';

// One emission of Pip's evolution moment (K07): the active child's Pip
// profile plus their lifetime helped-times count. Null (as a stream value,
// not this type) means kid mode has no active child yet, or the active
// child's row is gone.
class PipEvolution extends Equatable {
  const new({required this.profile, required this.questsDone});

  final PipProfile profile;

  /// Lifetime completions with `status == 'done_pending' || 'approved'`
  /// (all time — a lifetime milestone, so the PERIODS ruling does NOT
  /// apply; `to_do` and `not_yet` never count). Demo: Maya 4, Leo 2.
  final int questsDone;

  @override
  List<Object?> get props => <Object?>[profile, questsDone];
}
