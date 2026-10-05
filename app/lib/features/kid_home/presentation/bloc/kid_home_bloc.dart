import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_home_data.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_event.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_state.dart';

class KidHomeBloc extends Bloc<KidHomeEvent, KidHomeState> {
  new({required this._repository}) : super(const KidHomeState()) {
    on<KidHomeLoadRequested>(_onLoadRequested);
    on<KidHomeQuestCompleted>(_onQuestCompleted);
    on<KidHomeDataReceived>(_onDataReceived);
    on<KidHomeStreamFailed>(_onStreamFailed);
    on<KidHomeProfilesRequested>(_onProfilesRequested);
    on<KidHomeProfileSelected>(_onProfileSelected);
    on<KidHomeProfilesReceived>(_onProfilesReceived);
    on<KidHomeProfilesFailed>(_onProfilesFailed);
    on<KidHomeSelectionHandled>(_onSelectionHandled);
    on<KidHomePinSubmitted>(_onPinSubmitted);
  }

  final KidHomeRepository _repository;

  /// K04 detail checklist (K04 plan §b): `stepsFor` is a pure sync function
  /// of `questId`, so the view reads it through this presentation-supporting
  /// getter instead of touching the repository (views never use GetIt
  /// directly). No event, no state change.
  List<String> stepsFor(String questId) => _repository.stepsFor(questId);

  /// The live home subscription, or null when no load is streaming.
  /// Guards `_onLoadRequested` (K03-BUG-15): `watchHome()` never completes
  /// and the bloc transformer is concurrent, so an unguarded reload — e.g.
  /// the failure card's "Try again" — stacked another never-ending handler
  /// with its own fan-out of Drift watch queries per tap. While live, extra
  /// loads are ignored; the subscription is released on error and on close,
  /// so a retry after a failure still works.
  StreamSubscription<KidHomeData>? _homeSub;

  /// The live K01 profiles subscription, or null when not streaming. Same
  /// guard pattern as [_homeSub]: `watchProfiles()` never closes, so a
  /// retry while live is ignored, and the subscription is released on
  /// error and on close so "Try again" really reloads.
  StreamSubscription<List<KidChild>>? _profilesSub;

  /// Whether the last profiles-stream outcome was an error that released
  /// the subscription (K01-BUG-5). Cleared by the next healthy roster: a
  /// recovery then restores `loaded` when the failure was profiles-caused
  /// and the home stream is still live.
  bool _profilesFailed = false;

  /// Completions waiting for their stream flip, questId → coins. Set on the
  /// tap event; the first emission that newly marks a waiting quest done
  /// carries its celebration (K03-BUG-2, K03-BUG-8: every saved quest is
  /// celebrated exactly once, even when a later tap fails). Entries clear on
  /// their flip or on their failure.
  final Map<String, int> _awaitingCelebration = <String, int>{};

  Future<void> _onLoadRequested(
    KidHomeLoadRequested event,
    Emitter<KidHomeState> emit,
  ) async {
    // A load is already live: ignore the reload instead of stacking another
    // never-ending handler. Never re-add load events to refresh.
    if (_homeSub == null) {
      emit(state.copyWith(status: KidHomeStatus.loading));
      // One combined subscription (review finding 4, iteration 5): the child
      // row is watched exactly once per load.
      _homeSub = _repository.watchHome().listen(
        (home) => add(KidHomeDataReceived(home)),
        onError: (Object error) {
          final sub = _homeSub;
          _homeSub = null;
          unawaited(sub?.cancel());
          add(KidHomeStreamFailed(error));
        },
      );
    }
    if (_profilesSub == null) {
      // Try again on a profiles-caused failure card (K01-BUG-5, review
      // finding 3): the home stream is still live, so without this the
      // tapped card shows no spinner until the roster lands.
      if (_homeSub != null && state.status == KidHomeStatus.failure) {
        emit(state.copyWith(status: KidHomeStatus.loading));
      }
      _ensureProfilesSub();
    }
  }

  /// Starts the profiles subscription when none is live. Split out so both
  /// `KidHomeLoadRequested` and `KidHomeProfilesRequested` share the guard;
  /// never emits the loading status itself (the load event owns that).
  void _ensureProfilesSub() {
    if (_profilesSub != null) return;
    _profilesSub = _repository.watchProfiles().listen(
      (profiles) => add(KidHomeProfilesReceived(profiles)),
      onError: (Object error) {
        final sub = _profilesSub;
        _profilesSub = null;
        _profilesFailed = true;
        unawaited(sub?.cancel());
        add(KidHomeProfilesFailed(error));
      },
    );
  }

  void _onProfilesRequested(
    KidHomeProfilesRequested event,
    Emitter<KidHomeState> emit,
  ) {
    _ensureProfilesSub();
  }

  void _onProfilesReceived(
    KidHomeProfilesReceived event,
    Emitter<KidHomeState> emit,
  ) {
    // Recovery from a profiles-caused outage (K01-BUG-5, review finding
    // 1): a healthy roster after the error restores `loaded` and clears
    // the stale load error (review finding 2) — but only while the home
    // stream is still live. When the home stream itself is down
    // (`_homeSub == null`) the failure stands until it recovers, so a
    // roster arriving over a dead home never masks the failure card.
    final failed = _profilesFailed;
    _profilesFailed = false;
    // K01-BUG-7: clear an orphaned selection when its child no longer
    // exists (deleted while selected). Without this the bloc's
    // `selectedProfileId` gate drops every later tap and the view's `_busy`
    // re-arms on each dropped tap — a dead picker. The view also dispatches
    // `KidHomeSelectionHandled` on its own orphan path; this is the backstop
    // for roster changes that arrive without a view resolution.
    KidHomeState next;
    if (failed &&
        _homeSub != null &&
        (state.status == KidHomeStatus.failure ||
            state.status == KidHomeStatus.loading)) {
      next = state.copyWithProfilesRecovered(event.profiles);
    } else {
      next = state.copyWithProfiles(event.profiles);
    }
    final selected = next.selectedProfileId;
    if (selected != null &&
        !event.profiles.any((profile) => profile.id == selected)) {
      next = next.copyWithSelectionHandled();
    }
    emit(next);
  }

  void _onProfilesFailed(
    KidHomeProfilesFailed event,
    Emitter<KidHomeState> emit,
  ) {
    // A mid-session error keeps the loaded picker (review finding 6,
    // iteration 7, applied to the roster): only a load with nothing to show
    // becomes the failure card. The release is recorded in `_profilesFailed`
    // so the recovery roster restores `loaded` (a healthy home emission
    // also clears this stale error via `copyWithLoaded`).
    emit(
      state.copyWith(
        status: state.profiles.isEmpty && state.child == null
            ? KidHomeStatus.failure
            : state.status,
        errorMessage: event.error.toString(),
        profilesFailed: true,
      ),
    );
  }

  /// K01 selection consumed by the view (K01-BUG-3): forget the pending
  /// profile so tapping the same tile after coming back emits a distinct
  /// state and navigates again. No-op when nothing is pending, so stray
  /// dispatches never rebuild the picker.
  void _onSelectionHandled(
    KidHomeSelectionHandled event,
    Emitter<KidHomeState> emit,
  ) {
    if (state.selectedProfileId != null) {
      emit(state.copyWithSelectionHandled());
    }
  }

  /// K01 tile tap: persist the choice, then publish the one-shot
  /// `selectedProfileId` the view's `BlocListener` pushes on. On failure the
  /// roster stays visible and the action error explains it
  /// (`Hmm, that did not work. Try again.` in the view) — same
  /// `actionError`/`actionNonce` channel as a failed quest write.
  Future<void> _onProfileSelected(
    KidHomeProfileSelected event,
    Emitter<KidHomeState> emit,
  ) async {
    // K01-BUG-6: one selection in flight = max one persisted child per
    // burst. The view already gates dispatches with a screen-level busy
    // flag; the bloc state-gate drops a stale-second event too, so
    // `app_state` always names the child whose route the picker pushed.
    if (state.selectedProfileId != null) return;
    try {
      await _repository.setActiveChild(event.childId);
      emit(state.copyWithSelection(event.childId));
    } on Object catch (error) {
      emit(state.withCompletionFailed(error));
    }
  }

  void _onDataReceived(KidHomeDataReceived event, Emitter<KidHomeState> emit) {
    final home = event.home;
    final previouslyDone = state.items
        .where((item) => _isDoneStatus(item.status))
        .map((item) => item.questId)
        .toSet();
    final next = state.copyWithLoaded(child: home.child, items: home.items);
    if (_awaitingCelebration.isNotEmpty) {
      // Evict entries for quests that vanished from the list
      // (K03-BUG-11): no flip can ever arrive for them, and a later
      // flip of a recycled id must not celebrate this tap. Silent —
      // eviction alone changes no observable state.
      _awaitingCelebration.removeWhere(
        (questId, _) => !next.items.any((q) => q.questId == questId),
      );
      String? celebrate;
      for (final item in next.items) {
        if (_awaitingCelebration.containsKey(item.questId) &&
            _isDoneStatus(item.status) &&
            !previouslyDone.contains(item.questId)) {
          celebrate = item.questId;
          break;
        }
      }
      if (celebrate != null) {
        final coins = _awaitingCelebration.remove(celebrate)!;
        emit(next.withCompletionSucceeded(questId: celebrate, coins: coins));
        return;
      }
    }
    emit(next);
  }

  void _onStreamFailed(KidHomeStreamFailed event, Emitter<KidHomeState> emit) {
    // A mid-session error keeps the loaded list (review finding 6,
    // iteration 7): only a load with nothing to show becomes the failure
    // card. A healthy emission restores `loaded` via `copyWithLoaded`.
    emit(
      state.copyWith(
        status: state.child == null ? KidHomeStatus.failure : state.status,
        errorMessage: event.error.toString(),
      ),
    );
  }

  Future<void> _onQuestCompleted(
    KidHomeQuestCompleted event,
    Emitter<KidHomeState> emit,
  ) async {
    _awaitingCelebration[event.questId] = event.coins;
    // The bloc emits `==`-equal states, so only announce the reset when a
    // previous outcome is actually pending.
    if (state.actionError != null || state.justCompletedQuestId != null) {
      emit(state.withCompletionStarted());
    }
    try {
      await _repository.completeQuest(event.childId, event.questId);
    } on Object catch (error) {
      _awaitingCelebration.remove(event.questId);
      emit(state.withCompletionFailed(error));
    }
  }

  /// K02 PIN submit: checks the 4-digit code via `verifyPin` (`pinHash ==
  /// null` already reads as pass in the repository, so no-PIN children never
  /// reach a wrong path). Re-entry while a check is in flight is ignored
  /// (same guard style as [_homeSub]): the view already gates dispatches
  /// with its local `_awaiting` flag, this is the backstop so a double-tap
  /// of the 4th digit submits once. The outcome is built from the state at
  /// completion time, so an interleaved home-stream emission cannot swallow
  /// it; a repository throw reads as the wrong path (the stream is healthy,
  /// the code just did not match).
  Future<void> _onPinSubmitted(
    KidHomePinSubmitted event,
    Emitter<KidHomeState> emit,
  ) async {
    if (state.pinChecking) return;
    emit(state.copyWith(pinChecking: true));
    final bool ok;
    try {
      ok = await _repository.verifyPin(event.childId, event.pin);
    } on Object catch (_) {
      // Repository errors read as a wrong PIN; the list stays usable.
      emit(
        state.copyWith(
          pinChecking: false,
          pinWrongNonce: state.pinWrongNonce + 1,
        ),
      );
      return;
    }
    if (ok) {
      emit(state.copyWith(pinChecking: false, pinPassed: true));
    } else {
      emit(
        state.copyWith(
          pinChecking: false,
          pinWrongNonce: state.pinWrongNonce + 1,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _homeSub?.cancel();
    _homeSub = null;
    await _profilesSub?.cancel();
    _profilesSub = null;
    await super.close();
  }
}

bool _isDoneStatus(String status) =>
    status == 'approved' || status == 'done_pending';
