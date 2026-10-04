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
    this.profiles = const <KidChild>[],
    this.selectedProfileId,
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

  /// K01 picker roster in creation order (Maya, then Leo — never re-sorted).
  /// Shared with the K03 instance on its own route bloc, so every
  /// `copyWith`/`withCompletion*` constructor must carry it through: a
  /// dropped list blanks the picker after any quest completion emit.
  final List<KidChild> profiles;

  /// K01 tile tap, set by `KidHomeProfileSelected` after the
  /// `setActiveChild` write saves. One-shot: the view pushes
  /// `/kid-pin` (`pinSet`) or `/kid-home` for this id, then dispatches
  /// `KidHomeSelectionHandled`. Consumed by the handled event or by the
  /// next home-stream emission, whichever comes first (same pattern as
  /// `justCompletedQuestId`). Never drives navigation inside the bloc.
  final String? selectedProfileId;

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
    List<KidChild>? profiles,
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
      profiles: profiles ?? this.profiles,
      selectedProfileId: selectedProfileId,
    );
  }

  /// K01 selection: records the tapped profile, keeping everything else.
  KidHomeState copyWithSelection(String childId) {
    return KidHomeState(
      status: status,
      child: child,
      items: items,
      errorMessage: errorMessage,
      actionError: actionError,
      actionNonce: actionNonce,
      justCompletedQuestId: justCompletedQuestId,
      justCompletedCoins: justCompletedCoins,
      profiles: profiles,
      selectedProfileId: childId,
    );
  }

  /// K01 selection consumed (K01-BUG-3): the view pushed the PIN/home route
  /// for the pending profile, so forget it. Everything else is carried
  /// through untouched; the next home emission would clear it anyway, this
  /// just stops depending on a stream round-trip that may never come.
  KidHomeState copyWithSelectionHandled() {
    return KidHomeState(
      status: status,
      child: child,
      items: items,
      errorMessage: errorMessage,
      actionError: actionError,
      actionNonce: actionNonce,
      justCompletedQuestId: justCompletedQuestId,
      justCompletedCoins: justCompletedCoins,
      profiles: profiles,
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
      profiles: profiles,
      selectedProfileId: selectedProfileId,
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
      profiles: profiles,
      selectedProfileId: selectedProfileId,
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
      profiles: profiles,
      selectedProfileId: selectedProfileId,
    );
  }

  /// Loaded emission from the combined child + items streams. Built
  /// explicitly (not via [copyWith]) so a null child clears the previous
  /// one; a healthy stream also clears transient completion outcomes and
  /// any stale load error (review finding 5). Carries the K01 [profiles]
  /// through untouched, and consumes a pending [selectedProfileId]
  /// one-shot signal (same pattern as [justCompletedQuestId]).
  KidHomeState copyWithLoaded({
    required KidChild? child,
    required List<KidQuest> items,
  }) {
    return KidHomeState(
      status: KidHomeStatus.loaded,
      child: child,
      items: items,
      profiles: profiles,
    );
  }

  /// Loaded emission from the profiles stream: same child + items, new
  /// roster. Never touches the load status, the load error or the pending
  /// selection — the home stream owns the status, and the selection is
  /// consumed by `KidHomeSelectionHandled` or [copyWithLoaded]. (A roster
  /// that arrives after a profiles-caused outage goes through
  /// [copyWithProfilesRecovered] instead.)
  KidHomeState copyWithProfiles(List<KidChild> next) {
    return KidHomeState(
      status: status,
      child: child,
      items: items,
      errorMessage: errorMessage,
      actionError: actionError,
      actionNonce: actionNonce,
      justCompletedQuestId: justCompletedQuestId,
      justCompletedCoins: justCompletedCoins,
      profiles: next,
      selectedProfileId: selectedProfileId,
    );
  }

  /// Healthy roster after a profiles-caused outage (K01-BUG-5, review
  /// finding 1): restore `loaded` and clear the stale load error (review
  /// finding 2) instead of leaving the failure card up forever. The
  /// completion channel (`actionError`/`justCompleted…`) is carried
  /// through — only the load failure is forgiven. Used only when the home
  /// subscription is still live; when the home stream itself is down the
  /// failure stands until it recovers.
  KidHomeState copyWithProfilesRecovered(List<KidChild> next) {
    return KidHomeState(
      status: KidHomeStatus.loaded,
      child: child,
      items: items,
      actionError: actionError,
      actionNonce: actionNonce,
      justCompletedQuestId: justCompletedQuestId,
      justCompletedCoins: justCompletedCoins,
      profiles: next,
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
    profiles,
    selectedProfileId,
  ];
}
