import 'package:equatable/equatable.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_entry.dart';

enum KidJarStatus { initial, loading, loaded, failure }

final class KidJarState extends Equatable {
  const new({
    this.status = KidJarStatus.initial,
    this.childId = '',
    this.items = const <JarEntry>[],
    this.owedPence = 0,
    this.goalTitle = '',
    this.goalSavedPence = 0,
    this.goalTargetPence = 0,
    this.nextPayoutDay = 'Saturday',
    this.errorMessage,
  });

  final KidJarStatus status;

  /// Active child the snapshot belongs to (`''` before the first load).
  final String childId;

  /// Money-in rows only (`weekly_base`, `quest_bonus`, `gift`), newest first.
  final List<JarEntry> items;

  /// Owed at the next payout (weekly base + quest bonuses since the last
  /// payout break), in pence — the K09 hero amount.
  final int owedPence;
  final String goalTitle;
  final int goalSavedPence;

  /// Zero when the child has no savings goal — the view hides the goal card
  /// and the jar fill reads 0.
  final int goalTargetPence;

  /// Full weekday name from the payout-day setting (`Saturday` default).
  final String nextPayoutDay;
  final String? errorMessage;

  KidJarState copyWith({
    KidJarStatus? status,
    String? childId,
    List<JarEntry>? items,
    int? owedPence,
    String? goalTitle,
    int? goalSavedPence,
    int? goalTargetPence,
    String? nextPayoutDay,
    String? errorMessage,
  }) {
    return KidJarState(
      status: status ?? this.status,
      childId: childId ?? this.childId,
      items: items ?? this.items,
      owedPence: owedPence ?? this.owedPence,
      goalTitle: goalTitle ?? this.goalTitle,
      goalSavedPence: goalSavedPence ?? this.goalSavedPence,
      goalTargetPence: goalTargetPence ?? this.goalTargetPence,
      nextPayoutDay: nextPayoutDay ?? this.nextPayoutDay,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// A healthy snapshot emission: replaces every jar field and clears a
  /// stale load error, while a loading retry keeps the error until the
  /// healthy emission arrives (K03 precedent).
  KidJarState copyWithLoaded({
    required String childId,
    required List<JarEntry> items,
    required int owedPence,
    required String goalTitle,
    required int goalSavedPence,
    required int goalTargetPence,
    required String nextPayoutDay,
  }) {
    return KidJarState(
      status: KidJarStatus.loaded,
      childId: childId,
      items: items,
      owedPence: owedPence,
      goalTitle: goalTitle,
      goalSavedPence: goalSavedPence,
      goalTargetPence: goalTargetPence,
      nextPayoutDay: nextPayoutDay,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    childId,
    items,
    owedPence,
    goalTitle,
    goalSavedPence,
    goalTargetPence,
    nextPayoutDay,
    errorMessage,
  ];
}
