import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
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
  }

  final KidHomeRepository _repository;

  /// The live home subscription, or null when no load is streaming.
  /// Guards `_onLoadRequested` (K03-BUG-15): `watchHome()` never completes
  /// and the bloc transformer is concurrent, so an unguarded reload — e.g.
  /// the failure card's "Try again" — stacked another never-ending handler
  /// with its own fan-out of Drift watch queries per tap. While live, extra
  /// loads are ignored; the subscription is released on error and on close,
  /// so a retry after a failure still works.
  StreamSubscription<KidHomeData>? _homeSub;

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
    if (_homeSub != null) return;
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

  @override
  Future<void> close() async {
    await _homeSub?.cancel();
    _homeSub = null;
    await super.close();
  }
}

bool _isDoneStatus(String status) =>
    status == 'approved' || status == 'done_pending';
