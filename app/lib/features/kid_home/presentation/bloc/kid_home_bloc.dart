import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/core/data/stream_combine.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_event.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_state.dart';

class KidHomeBloc extends Bloc<KidHomeEvent, KidHomeState> {
  new({required this._repository}) : super(const KidHomeState()) {
    on<KidHomeLoadRequested>(_onLoadRequested);
    on<KidHomeQuestCompleted>(_onQuestCompleted);
  }

  final KidHomeRepository _repository;

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
    emit(state.copyWith(status: KidHomeStatus.loading));
    await emit.forEach<List<dynamic>>(
      combineLatest2(_repository.watchActiveChild(), _repository.watchItems()),
      onData: (parts) {
        final previouslyDone = state.items
            .where((item) => _isDoneStatus(item.status))
            .map((item) => item.questId)
            .toSet();
        final next = state.copyWithLoaded(
          child: parts[0] as KidChild?,
          items: (parts[1] as List<dynamic>).cast<KidQuest>(),
        );
        final pending = _awaitingCelebration.keys.toSet();
        if (pending.isNotEmpty) {
          String? celebrate;
          for (final item in next.items) {
            if (pending.contains(item.questId) &&
                _isDoneStatus(item.status) &&
                !previouslyDone.contains(item.questId)) {
              celebrate = item.questId;
              break;
            }
          }
          if (celebrate != null) {
            final coins = _awaitingCelebration.remove(celebrate)!;
            return next.withCompletionSucceeded(
              questId: celebrate,
              coins: coins,
            );
          }
        }
        return next;
      },
      onError: (error, _) => state.copyWith(
        status: KidHomeStatus.failure,
        errorMessage: error.toString(),
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
}

bool _isDoneStatus(String status) =>
    status == 'approved' || status == 'done_pending';
