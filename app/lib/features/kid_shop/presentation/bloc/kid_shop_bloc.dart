import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/kid_shop/domain/entities/kid_shop_data.dart';
import 'package:nestling/features/kid_shop/domain/kid_shop_repository.dart';
import 'package:nestling/features/kid_shop/presentation/bloc/kid_shop_event.dart';
import 'package:nestling/features/kid_shop/presentation/bloc/kid_shop_state.dart';

class KidShopBloc extends Bloc<KidShopEvent, KidShopState> {
  new({required this._repository}) : super(const KidShopState()) {
    on<KidShopLoadRequested>(_onLoadRequested);
    on<KidShopDataReceived>(_onDataReceived);
    on<KidShopStreamFailed>(_onStreamFailed);
    on<KidShopRewardRequested>(_onRewardRequested);
    on<KidShopNoticeShown>(_onNoticeShown);
  }

  final KidShopRepository _repository;

  /// The live shop subscription, or null when no load is streaming. Guards
  /// `_onLoadRequested` (K03-BUG-15 precedent): `watchActiveShop()` never
  /// completes, so an unguarded reload — e.g. the failure card's "Try again"
  /// — would stack another never-ending handler per tap. While live, extra
  /// loads are ignored; the subscription is released on error and on close,
  /// so a retry after a failure still works.
  StreamSubscription<KidShopData>? _sub;

  Future<void> _onLoadRequested(
    KidShopLoadRequested event,
    Emitter<KidShopState> emit,
  ) async {
    // A load is already live: ignore the reload instead of stacking another
    // never-ending handler. Never re-add load events to refresh.
    if (_sub == null) {
      emit(state.copyWith(status: KidShopStatus.loading));
      _sub = _repository.watchActiveShop().listen(
        (data) => add(KidShopDataReceived(data)),
        onError: (Object error) {
          final sub = _sub;
          _sub = null;
          unawaited(sub?.cancel());
          add(KidShopStreamFailed(error));
        },
      );
    }
  }

  void _onDataReceived(KidShopDataReceived event, Emitter<KidShopState> emit) {
    final data = event.data;
    emit(
      state.copyWithLoaded(
        childId: data.childId,
        coins: data.coins,
        items: data.items,
      ),
    );
  }

  void _onStreamFailed(KidShopStreamFailed event, Emitter<KidShopState> emit) {
    emit(
      state.copyWith(
        status: KidShopStatus.failure,
        errorMessage: event.error.toString(),
      ),
    );
  }

  Future<void> _onRewardRequested(
    KidShopRewardRequested event,
    Emitter<KidShopState> emit,
  ) async {
    if (!state.isLoaded) return;
    // The affordability flag is only the tap-time guard — the toast below is
    // chosen from the status the write actually produced (K08-BUG-4), never
    // from a captured flag.
    var known = false;
    var affordable = false;
    for (final item in state.items) {
      if (item.id == event.rewardId) {
        known = true;
        affordable = item.affordable;
        break;
      }
    }
    // Unknown ids never reach the repository (and the repository itself is
    // a no-op for them).
    if (!known) return;
    if (!affordable) return;
    if (state.requestingIds.contains(event.rewardId)) return;
    final childId = state.childId;
    emit(state.copyWithRequestStarted(event.rewardId));
    String? written;
    try {
      written = await _repository.requestReward(childId, event.rewardId);
    } on Object catch (_) {
      written = null;
    }
    if (written == null) {
      // The write failed — or the reward vanished mid-flight, which the
      // guard above can no longer see. Either way nothing was granted.
      emit(
        state.copyWithRequestFinished(
          event.rewardId,
          'Hmm, that did not work. Try again.',
        ),
      );
      return;
    }
    emit(
      state.copyWithRequestFinished(
        event.rewardId,
        written == 'approved'
            ? 'It’s yours — enjoy!'
            : 'Mum will give it a thumbs-up soon.',
      ),
    );
  }

  void _onNoticeShown(KidShopNoticeShown event, Emitter<KidShopState> emit) {
    if (state.notice != null) {
      emit(state.copyWithNoticeCleared());
    }
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    await super.close();
  }
}
