import 'package:equatable/equatable.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';

enum KidHomeStatus { initial, loading, loaded, failure }

final class KidHomeState extends Equatable {
  const new({
    this.status = KidHomeStatus.initial,
    this.child,
    this.items = const <KidQuest>[],
    this.errorMessage,
    this.actionError,
    this.actionNonce = 0,
    this.justCompletedQuestId,
    this.justCompletedCoins,
  });

  final KidHomeStatus status;

  /// The child currently playing (null when no active child in kid mode).
  final KidChild? child;
  final List<KidQuest> items;
  final String? errorMessage;

  /// Last `completeQuest` failure; the list stays visible and a SnackBar
  /// explains it. Never used for the load failure path.
  final String? actionError;

  /// Bumps on every completion failure so two identical failures are still
  /// distinct states (K03-BUG-3): without it the second emit is swallowed.
  final int actionNonce;

  /// Quest id + coins of the completion that just saved. The view pushes
  /// `/quest-complete` for this value (K03-BUG-2: never celebrate a failed
  /// write) and it clears on the next stream emission.
  final String? justCompletedQuestId;
  final int? justCompletedCoins;

  /// Done = `approved` + `done_pending` (live counts from the DB).
  int get doneCount => items
      .where((q) => q.status == 'approved' || q.status == 'done_pending')
      .length;

  int get totalCount => items.length;

  double get fraction => totalCount == 0 ? 0 : doneCount / totalCount;

  KidHomeState copyWith({
    KidHomeStatus? status,
    List<KidQuest>? items,
    String? errorMessage,
  }) {
    return KidHomeState(
      status: status ?? this.status,
      child: child,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
      actionError: actionError,
      actionNonce: actionNonce,
      justCompletedQuestId: justCompletedQuestId,
      justCompletedCoins: justCompletedCoins,
    );
  }

  /// A completion attempt starts: forget the previous outcome so a repeat
  /// failure is announced again (K03-BUG-3).
  KidHomeState withCompletionStarted() {
    return KidHomeState(
      status: status,
      child: child,
      items: items,
      errorMessage: errorMessage,
    );
  }

  /// The write failed: distinct state per failure via [actionNonce].
  KidHomeState withCompletionFailed(Object error) {
    return KidHomeState(
      status: status,
      child: child,
      items: items,
      errorMessage: errorMessage,
      actionError: error.toString(),
      actionNonce: actionNonce + 1,
    );
  }

  /// The write saved: the view celebrates exactly this completion.
  KidHomeState withCompletionSucceeded({
    required String questId,
    required int coins,
  }) {
    return KidHomeState(
      status: status,
      child: child,
      items: items,
      errorMessage: errorMessage,
      justCompletedQuestId: questId,
      justCompletedCoins: coins,
    );
  }

  /// Loaded emission from the combined child + items streams. Built
  /// explicitly (not via [copyWith]) so a null child clears the previous
  /// one; a healthy stream also clears transient completion outcomes and
  /// any stale load error (review finding 5).
  KidHomeState copyWithLoaded({
    required KidChild? child,
    required List<KidQuest> items,
  }) {
    return KidHomeState(
      status: KidHomeStatus.loaded,
      child: child,
      items: items,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    child,
    items,
    errorMessage,
    actionError,
    actionNonce,
    justCompletedQuestId,
    justCompletedCoins,
  ];
}
