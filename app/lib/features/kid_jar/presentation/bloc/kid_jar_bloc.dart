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

  /// Set synchronously on the first line of [close] (K10-BUG-1). `isClosed`
  /// cannot serve as the guard here: it flips only when the state controller
  /// closes — the LAST step of `Bloc.close()`, after queued events have been
  /// delivered and in-flight handlers awaited — so it is still false while a
  /// same-tick queued load runs during close. This flag stops those handlers
  /// before they emit or subscribe.
  bool _closing = false;

  Future<void> _onLoadRequested(
    KidJarLoadRequested event,
    Emitter<KidJarState> emit,
  ) async {
    // Same-tick close guard (K10-BUG-1, the K09-BUG-7 shape): the await
    // below suspends the handler for a microtask even on the first load, so
    // a `close()` landing in the window must stop the handler before it
    // emits or subscribes — otherwise the subscription outlives the bloc
    // and its first emission throws `add` on a closed bloc.
    if (_closing) return;
    final previous = _jarSub;
    _jarSub = null;
    await previous?.cancel();
    if (_closing) return;
    emit(state.copyWith(status: KidJarStatus.loading));
    final sub = _repository.watchJar().listen(
      (snapshot) => add(KidJarSnapshotReceived(snapshot)),
      onError: (Object error) {
        final current = _jarSub;
        _jarSub = null;
        unawaited(current?.cancel());
        add(KidJarStreamFailed(error.toString()));
      },
    );
    if (_closing) {
      unawaited(sub.cancel());
      return;
    }
    _jarSub = sub;
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
    // Same-tick close guard (K10-BUG-1, the K09-BUG-7 shape): the await
    // below suspends the handler for a microtask even on the first load, so
    // a `close()` landing in the window must stop the handler before it
    // emits or subscribes — otherwise the subscription outlives the bloc
    // and its first emission throws `add` on a closed bloc. Checked against
    // `_closing`, never `isClosed` (see the field comment).
    if (_closing) return;
    final previous = _payoutSub;
    _payoutSub = null;
    await previous?.cancel();
    if (_closing) return;
    emit(state.copyWith(status: KidJarStatus.loading));
    final sub = _repository.watchLatestPayout().listen(
      (celebration) => add(KidJarPayoutReceived(celebration)),
      onError: (Object error) {
        final current = _payoutSub;
        _payoutSub = null;
        unawaited(current?.cancel());
        add(KidJarStreamFailed(error.toString()));
      },
    );
    if (_closing) {
      unawaited(sub.cancel());
      return;
    }
    _payoutSub = sub;
  }

  void _onPayoutReceived(
    KidJarPayoutReceived event,
    Emitter<KidJarState> emit,
  ) {
    emit(state.copyWithPayout(event.celebration));
  }

  @override
  Future<void> close() async {
    // Synchronous first line (K10-BUG-1): `add()` delivers events
    // asynchronously, so no queued load handler can have run before this
    // line — every handler that runs later sees `_closing` and stops before
    // it emits or subscribes.
    _closing = true;
    await _jarSub?.cancel();
    _jarSub = null;
    await _payoutSub?.cancel();
    _payoutSub = null;
    await super.close();
  }
}
