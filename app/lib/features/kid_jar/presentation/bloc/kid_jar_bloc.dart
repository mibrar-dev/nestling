import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_snapshot.dart';
import 'package:nestling/features/kid_jar/domain/entities/payout_celebration.dart';
import 'package:nestling/features/kid_jar/domain/kid_jar_repository.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_event.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_state.dart';

/// K09 is read-only: a single load subscribes to [KidJarRepository.watchJar]
/// and every snapshot emission replaces the state. Retry re-adds
/// [KidJarLoadRequested], which releases the previous subscription first.
class KidJarBloc extends Bloc<KidJarEvent, KidJarState> {
  new({required this._repository}) : super(const KidJarState()) {
    on<KidJarLoadRequested>(_onLoadRequested);
    on<KidJarSnapshotReceived>(_onSnapshotReceived);
    on<KidJarStreamFailed>(_onStreamFailed);
    on<KidJarPayoutRequested>(_onPayoutRequested);
    on<KidJarPayoutReceived>(_onPayoutReceived);
  }

  final KidJarRepository _repository;

  /// The live jar subscription, or null when no load is streaming.
  /// Cancel-before-reload guard (K09-BUG-1, same defect as K03-BUG-15):
  /// `watchJar()` never completes and the bloc transformer is concurrent,
  /// so an unguarded reload — e.g. the failure card's "Try again" — stacked
  /// another never-ending handler per tap, and a stale stream could
  /// overwrite the reloaded screen. Each load releases the previous
  /// subscription first; it is also released on error and on close, so
  /// "Try again" really reloads.
  StreamSubscription<JarSnapshot>? _jarSub;

  Future<void> _onLoadRequested(
    KidJarLoadRequested event,
    Emitter<KidJarState> emit,
  ) async {
    final previous = _jarSub;
    _jarSub = null;
    await previous?.cancel();
    emit(state.copyWith(status: KidJarStatus.loading));
    _jarSub = _repository.watchJar().listen(
      (snapshot) => add(KidJarSnapshotReceived(snapshot)),
      onError: (Object error) {
        final sub = _jarSub;
        _jarSub = null;
        unawaited(sub?.cancel());
        add(KidJarStreamFailed(error.toString()));
      },
    );
  }

  void _onSnapshotReceived(
    KidJarSnapshotReceived event,
    Emitter<KidJarState> emit,
  ) {
    final summary = event.snapshot.summary;
    emit(
      state.copyWithLoaded(
        childId: event.snapshot.childId,
        items: event.snapshot.items,
        owedPence: summary.owedPence,
        goalTitle: summary.goalTitle,
        goalSavedPence: summary.goalSavedPence,
        goalTargetPence: summary.goalTargetPence,
        nextPayoutDay: summary.nextPayoutDay,
      ),
    );
  }

  void _onStreamFailed(KidJarStreamFailed event, Emitter<KidJarState> emit) {
    emit(
      state.copyWith(status: KidJarStatus.failure, errorMessage: event.message),
    );
  }

  /// The live payout subscription, or null when no K10 load is streaming.
  /// Cancel-before-reload guard (K09-BUG-1, same defect as K03-BUG-15):
  /// `watchLatestPayout()` never completes and the bloc transformer is
  /// concurrent, so an unguarded reload stacked another never-ending handler
  /// per tap, and a stale stream could overwrite the reloaded screen. Each
  /// load releases the previous subscription first; it is also released on
  /// error and on close, so "Try again" really reloads. Independent from
  /// [_jarSub]: the K09 and K10 screens hold separate bloc instances, and
  /// each load event only touches its own stream.
  StreamSubscription<PayoutCelebration?>? _payoutSub;

  Future<void> _onPayoutRequested(
    KidJarPayoutRequested event,
    Emitter<KidJarState> emit,
  ) async {
    final previous = _payoutSub;
    _payoutSub = null;
    await previous?.cancel();
    emit(state.copyWith(status: KidJarStatus.loading));
    _payoutSub = _repository.watchLatestPayout().listen(
      (celebration) => add(KidJarPayoutReceived(celebration)),
      onError: (Object error) {
        final sub = _payoutSub;
        _payoutSub = null;
        unawaited(sub?.cancel());
        add(KidJarStreamFailed(error.toString()));
      },
    );
  }

  void _onPayoutReceived(
    KidJarPayoutReceived event,
    Emitter<KidJarState> emit,
  ) {
    emit(state.copyWithPayout(event.celebration));
  }

  @override
  Future<void> close() async {
    await _jarSub?.cancel();
    _jarSub = null;
    await _payoutSub?.cancel();
    _payoutSub = null;
    await super.close();
  }
}
