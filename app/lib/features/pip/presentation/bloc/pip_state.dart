import 'package:equatable/equatable.dart';
import 'package:nestling/features/pip/domain/entities/pip_evolution.dart';
import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/entities/pip_stage.dart';

enum PipStatus { initial, loading, loaded, failure }

final class PipState extends Equatable {
  const new({
    this.status = PipStatus.initial,
    this.nest,
    this.evolution,
    this.errorMessage,
    this.actionError,
    this.actionNonce = 0,
  });

  final PipStatus status;

  /// The nest screen's data; null while loading, on failure, or with no
  /// active child (the view renders the "Who's playing?" card then).
  final PipNest? nest;

  /// The evolution screen's data (K07); null under the same conditions as
  /// [nest]. Both streams load together and either healthy emission
  /// restores `loaded`.
  final PipEvolution? evolution;
  final String? errorMessage;

  /// Last care/wardrobe failure; the nest stays visible and a toast
  /// explains it. Never used for the load failure path.
  final String? actionError;

  /// Bumps on every action failure so two identical failures are still
  /// distinct states: without it the second emit is swallowed.
  final int actionNonce;

  /// Backwards-compatible wardrobe list for the K06/K07 placeholder views
  /// (the UI builder replaces them): the nest's items, empty before load.
  List<PipStage> get items => nest?.items ?? const <PipStage>[];

  PipState toLoading() {
    return PipState(
      status: PipStatus.loading,
      nest: nest,
      evolution: evolution,
      errorMessage: errorMessage,
      actionError: actionError,
      actionNonce: actionNonce,
    );
  }

  /// Healthy nest emission: loaded (even with a null nest — the no-child
  /// card). A pending action outcome is carried through, not cleared: in a
  /// tap burst the refused tap's toast must survive the sibling write's
  /// refresh (K06-BUG-7). The outcome clears on the next attempt via
  /// [withActionStarted], so a repeated outcome is still announced again.
  /// The evolution is carried through untouched, and any stale load error
  /// is cleared.
  PipState copyWithLoaded(PipNest? next) {
    return PipState(
      status: PipStatus.loaded,
      nest: next,
      evolution: evolution,
      actionError: actionError,
      actionNonce: actionNonce,
    );
  }

  /// Healthy evolution emission (K07): loaded (even with a null evolution
  /// — the no-child card). Mirrors [copyWithLoaded]: the nest is carried
  /// through untouched, the pending action outcome survives, and any stale
  /// load error is cleared.
  PipState copyWithEvolution(PipEvolution? next) {
    return PipState(
      status: PipStatus.loaded,
      nest: nest,
      evolution: next,
      actionError: actionError,
      actionNonce: actionNonce,
    );
  }

  /// A load-stream error while something is already shown (K03
  /// review-finding-6 pattern): keep the loaded screen and record the
  /// error for the record. Only a load with nothing to show becomes the
  /// failure card (via [toFailure]).
  PipState withStreamError(Object error) {
    return PipState(
      status: status,
      nest: nest,
      evolution: evolution,
      errorMessage: error.toString(),
      actionError: actionError,
      actionNonce: actionNonce,
    );
  }

  PipState toFailure(Object error) {
    return PipState(status: PipStatus.failure, errorMessage: error.toString());
  }

  /// An action attempt starts: forget the previous outcome so a repeat
  /// outcome is announced again.
  PipState withActionStarted() {
    return PipState(
      status: status,
      nest: nest,
      evolution: evolution,
      errorMessage: errorMessage,
    );
  }

  /// The write failed (or the buy was unaffordable): distinct state per
  /// failure via [actionNonce].
  PipState withActionFailed(Object error) {
    return PipState(
      status: status,
      nest: nest,
      evolution: evolution,
      errorMessage: errorMessage,
      actionError: error.toString(),
      actionNonce: actionNonce + 1,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    nest,
    evolution,
    errorMessage,
    actionError,
    actionNonce,
  ];
}
