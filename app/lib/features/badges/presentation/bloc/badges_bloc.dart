import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/badges/domain/badges_repository.dart';
import 'package:nestling/features/badges/domain/entities/badges_data.dart';
import 'package:nestling/features/badges/presentation/bloc/badges_event.dart';
import 'package:nestling/features/badges/presentation/bloc/badges_state.dart';

class BadgesBloc extends Bloc<BadgesEvent, BadgesState> {
  BadgesBloc({required this._repository}) : super(const BadgesState()) {
    on<BadgesLoadRequested>(_onLoadRequested);
    on<BadgesDataReceived>(_onDataReceived);
    on<BadgesStreamFailed>(_onStreamFailed);
  }

  final BadgesRepository _repository;

  /// The live badges subscription, or null when no load is streaming. Guards
  /// `_onLoadRequested` (K08 `KidShopBloc` precedent): `watchActiveBadges()`
  /// never completes, so an unguarded reload — e.g. the failure card's
  /// "Try again" — would stack another never-ending handler per tap. While
  /// live, extra loads are ignored; the subscription is released on error
  /// and on close, so a retry after a failure still works.
  StreamSubscription<BadgesData>? _sub;

  Future<void> _onLoadRequested(
    BadgesLoadRequested event,
    Emitter<BadgesState> emit,
  ) async {
    // A load is already live: ignore the reload instead of stacking another
    // never-ending handler. Never re-add load events to refresh.
    if (_sub == null) {
      emit(state.copyWithLoading());
      _sub = _repository.watchActiveBadges().listen(
        (data) => add(BadgesDataReceived(data)),
        onError: (Object error) {
          final sub = _sub;
          _sub = null;
          unawaited(sub?.cancel());
          add(BadgesStreamFailed(error));
        },
      );
    }
  }

  void _onDataReceived(BadgesDataReceived event, Emitter<BadgesState> emit) {
    final data = event.data;
    emit(
      state.copyWithLoaded(
        childId: data.childId,
        items: data.items,
        happyDays: data.happyDays,
      ),
    );
  }

  void _onStreamFailed(BadgesStreamFailed event, Emitter<BadgesState> emit) {
    emit(
      state.copyWith(
        status: BadgesStatus.failure,
        errorMessage: event.error.toString(),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    _sub = null;
    await super.close();
  }
}
