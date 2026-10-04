import 'package:equatable/equatable.dart';
import 'package:nestling/features/pip/domain/entities/pip_profile.dart';

// One emission of Pip's evolution moment (K07): the active child's Pip
// profile plus their lifetime helped counts. Null (as a stream value,
// not this type) means kid mode has no active child yet, or the active
// child's row is gone.
class PipEvolution extends Equatable {
  const new({
    required this.profile,
    required this.questsDone,
    this.questsFinished,
  });

  final PipProfile profile;

  /// Lifetime completions with `status == 'done_pending' || 'approved'`
  /// (all time — a lifetime milestone, so the PERIODS ruling does NOT
  /// apply; `to_do` and `not_yet` never count). Demo: Maya 4, Leo 2.
  ///
  /// This is the honest PER-COMPLETION count, so it backs the sub-line
  /// "Because you helped N times": a re-completable daily/weekly quest adds
  /// one each time it is done.
  final int questsDone;

  /// The DISTINCT quests behind [questsDone] — the number the "quests done"
  /// milestone card shows. Null when not supplied (hand-built fixtures), and
  /// it then falls back to [questsDone].
  ///
  /// `6_bugs.md` K07-BUG-3: one quest completed twice used to read as two
  /// quests done, so a month of one daily quest claimed "30 quests done"
  /// while the two sentences on the screen contradicted each other. The card
  /// is a milestone about quests, so it counts quests; the sub-line honestly
  /// counts times.
  final int? questsFinished;

  /// The card's number: distinct quests when known, else [questsDone].
  int get questsFinishedCount => questsFinished ?? questsDone;

  @override
  List<Object?> get props => <Object?>[
    profile,
    questsDone,
    questsFinishedCount,
  ];
}
