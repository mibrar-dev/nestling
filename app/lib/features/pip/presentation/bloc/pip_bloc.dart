import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/pip/domain/entities/pip_evolution.dart';
import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/pip_repository.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_event.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_state.dart';

/// Toast copy for an unaffordable wardrobe buy (1_plan.md §1f: kind, no
/// shame). Curly ’ (U+2019) and em dash (U+2014) exactly as rendered.
const String kPipNotEnoughCoins = 'Not enough coins yet — keep going!';

class PipBloc extends Bloc<PipEvent, PipState> {
  new({required this._repository}) : super(const PipState()) {
    on<PipLoadRequested>(_onLoadRequested);
    on<PipCareRequested>(_onCareRequested);
    on<PipWardrobeBuyRequested>(_onBuyRequested);
    on<PipWardrobeEquipRequested>(_onEquipRequested);
    on<PipNestReceived>(_onNestReceived);
    on<PipNestFailed>(_onNestFailed);
    on<PipEvolutionReceived>(_onEvolutionReceived);
    on<PipEvolutionFailed>(_onEvolutionFailed);
  }

  final PipRepository _repository;

  /// The live nest subscription, or null when no load is streaming.
  /// Guards [_onLoadRequested] (same K03-BUG-15 pattern as the kid_home
  /// bloc): `watchNest()` never completes and the bloc transformer is
  /// concurrent, so an unguarded reload — e.g. the failure card's "Try
  /// again" — would stack another never-ending handler per tap. While
  /// live, extra loads are ignored; the subscription is released on error
  /// and on close, so a retry after a failure still works.
  StreamSubscription<PipNest?>? _nestSub;

  /// The live evolution subscription (K07), or null when not streaming.
  /// Same guard pattern as [_nestSub]: `watchEvolution()` never closes, so
  /// a retry while live is ignored, and the subscription is released on
  /// error and on close so "Try again" really reloads just this stream.
  StreamSubscription<PipEvolution?>? _evolutionSub;

  Future<void> _onLoadRequested(
    PipLoadRequested event,
    Emitter<PipState> emit,
  ) async {
    // Both loads are already live: ignore the reload instead of stacking
    // more never-ending handlers. Never re-add load events to refresh.
    if (_nestSub != null && _evolutionSub != null) return;
    // The reset names what is ACTUALLY restarting: a null subscription is the
    // one that died and is being re-listened (`??=` below keeps the healthy
    // one), and only that stream's arrival flag and error slot may drop. The
    // surviving stream is still streaming and will not re-announce itself, so
    // clearing its flag would strand its screen on a spinner that has no retry
    // button (`4_review.md` finding 1). On a cold open both are null, so both
    // restart — the common case is unchanged.
    emit(
      state.toLoading(
        restartingNest: _nestSub == null,
        restartingEvolution: _evolutionSub == null,
      ),
    );
    _nestSub ??= _repository.watchNest().listen(
      (nest) => add(PipNestReceived(nest)),
      onError: (Object error) {
        final sub = _nestSub;
        _nestSub = null;
        unawaited(sub?.cancel());
        add(PipNestFailed(error));
      },
    );
    _evolutionSub ??= _repository.watchEvolution().listen(
      (evolution) => add(PipEvolutionReceived(evolution)),
      onError: (Object error) {
        final sub = _evolutionSub;
        _evolutionSub = null;
        unawaited(sub?.cancel());
        add(PipEvolutionFailed(error));
      },
    );
  }

  void _onNestReceived(PipNestReceived event, Emitter<PipState> emit) {
    emit(state.copyWithLoaded(event.nest));
  }

  void _onNestFailed(PipNestFailed event, Emitter<PipState> emit) {
    // The NEST stream's failure lands in the NEST stream's slot, never the
    // evolution one: a mid-session error keeps the loaded screen (K03
    // review-finding-6 pattern — `nestSettled` is already true when data is on
    // screen, so `/pip` stays loaded), and only a nest that failed before it
    // ever answered turns into the failure card. `/pip-evolution` is untouched
    // by a nest failure. A healthy emission clears the slot via
    // `copyWithLoaded` / `copyWithEvolution`.
    emit(state.withNestError(event.error));
  }

  void _onEvolutionReceived(
    PipEvolutionReceived event,
    Emitter<PipState> emit,
  ) {
    emit(state.copyWithEvolution(event.evolution));
  }

  void _onEvolutionFailed(PipEvolutionFailed event, Emitter<PipState> emit) {
    // [_onNestFailed]'s mirror: only this stream's slot takes the error, so a
    // nest failure can never blank the celebration screen and a still-pending
    // evolution stream is not a failure (6_bugs.md K07-BUG-1).
    emit(state.withEvolutionError(event.error));
  }

  Future<void> _onCareRequested(
    PipCareRequested event,
    Emitter<PipState> emit,
  ) async {
    final childId = state.nest?.profile.childId;
    if (childId == null) return;
    // The bloc emits `==`-equal states, so only announce the reset when a
    // previous outcome is actually pending.
    if (state.actionError != null) emit(state.withActionStarted());
    try {
      switch (event.kind) {
        case PipCareKind.feed:
          await _repository.feed(childId);
        case PipCareKind.play:
          await _repository.play(childId);
        case PipCareKind.bathe:
          await _repository.bathe(childId);
      }
    } on Object catch (error) {
      emit(state.withActionFailed(error));
    }
    // Success needs no event: the nest stream re-emits the new profile.
  }

  Future<void> _onBuyRequested(
    PipWardrobeBuyRequested event,
    Emitter<PipState> emit,
  ) async {
    final nest = state.nest;
    if (nest == null) return;
    if (state.actionError != null) emit(state.withActionStarted());
    final price = _priceOf(nest, event.item);
    // Unaffordable: toast only, no DB write (the repository would no-op
    // too — the pre-check is what produces the toast).
    if (price != null && nest.profile.coins < price) {
      emit(state.withActionFailed(kPipNotEnoughCoins));
      return;
    }
    try {
      // The result tells apart what a silent void could not (K06-BUG-7):
      // a buy the fresh balance refuses still gets the kind toast, while
      // bought / already-owned / unavailable stay event-free (the stream
      // re-emits the new wardrobe on success).
      final result = await _repository.buyItem(
        nest.profile.childId,
        event.item,
      );
      if (result == PipBuyResult.cannotAfford) {
        emit(state.withActionFailed(kPipNotEnoughCoins));
      }
    } on Object catch (error) {
      emit(state.withActionFailed(error));
    }
    // Success needs no event: the nest stream re-emits the owned item.
  }

  Future<void> _onEquipRequested(
    PipWardrobeEquipRequested event,
    Emitter<PipState> emit,
  ) async {
    final nest = state.nest;
    if (nest == null) return;
    // Only scarf/sunhat map onto a Pip accessory node (scarf -> scarf,
    // sunhat -> cap); wellies/crown have none: toast only, no DB write.
    final accessory = switch (event.item) {
      'scarf' => 'scarf',
      'sunhat' => 'cap',
      _ => null,
    };
    if (accessory == null) return;
    if (accessory == nest.profile.accessory) return;
    if (state.actionError != null) emit(state.withActionStarted());
    try {
      await _repository.updateLook(
        childId: nest.profile.childId,
        accessory: accessory,
      );
    } on Object catch (error) {
      emit(state.withActionFailed(error));
    }
    // Success needs no event: the nest stream re-emits the new look.
  }

  static int? _priceOf(PipNest nest, String item) {
    for (final stage in nest.items) {
      if (stage.id == item) return stage.priceCoins;
    }
    return null;
  }

  @override
  Future<void> close() async {
    await _nestSub?.cancel();
    _nestSub = null;
    await _evolutionSub?.cancel();
    _evolutionSub = null;
    await super.close();
  }
}
