import 'package:equatable/equatable.dart';
import 'package:nestling/features/pip/domain/entities/pip_evolution.dart';
import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/entities/pip_stage.dart';

enum PipStatus { initial, loading, loaded, failure }

/// One bloc serves both pip screens, so each load stream is tracked on its own
/// ([nestSettled]/[nestError], [evolutionSettled]/[evolutionError]) and each
/// screen reads its OWN status via [nestStatus] / [evolutionStatus].
///
/// `6_bugs.md` K07-BUG-1 (major): `PipLoadRequested` subscribes the nest stream
/// first, so on a cold open the nest answered while the evolution stream was
/// still in flight. `loaded` used to be published by *either* stream, and
/// `/pip-evolution` read the sibling's arrival as its own failure — the
/// celebration screen painted "Oh no! Pip got lost." with a dead "Try again"
/// on 5 of 5 cold opens. The shared [status] is now the AND of both streams,
/// and a per-stream status is what a view must switch on.
final class PipState extends Equatable {
  const new({
    this.status = PipStatus.initial,
    this.nest,
    this.evolution,
    this.nestSettled = false,
    this.evolutionSettled = false,
    this.errorMessage,
    this.nestError,
    this.evolutionError,
    this.actionError,
    this.actionNonce = 0,
  });

  /// Feature-level status, for the shared `initial/loading/loaded/failure`
  /// vocabulary. `loaded` only once EVERY load stream has answered (see
  /// [_combine]); a stream that failed before answering makes it `failure`.
  final PipStatus status;

  /// The nest screen's data (K06); null while loading, on failure, or with no
  /// active child (the view renders the "Who's playing?" card then).
  final PipNest? nest;

  /// The evolution screen's data (K07); null under the same conditions as
  /// [nest].
  final PipEvolution? evolution;

  /// The nest stream has answered at least once — a null nest included (no
  /// active child is a healthy emission, never a failure).
  final bool nestSettled;

  /// The evolution stream has answered at least once (K07).
  final bool evolutionSettled;

  /// The last recorded load-stream error, diagnostic only: raw DB text must
  /// never reach a kid screen, so no view reads it (the failure cards render
  /// their own kind copy). Cleared by the next healthy emission. The
  /// per-stream slots below are what a view reads.
  final String? errorMessage;

  /// `watchNest()` failed and had not answered yet, or answered and then
  /// failed (then [nestSettled] stays true and the data is kept — the K03
  /// review-finding-6 keep-loaded rule).
  final String? nestError;

  /// The same, for `watchEvolution()` (K07).
  final String? evolutionError;

  /// Last care/wardrobe failure; the nest stays visible and a toast
  /// explains it. Never used for the load failure path.
  final String? actionError;

  /// Bumps on every action failure so two identical failures are still
  /// distinct states: without it the second emit is swallowed.
  final int actionNonce;

  /// The nest stream's own status (what `/pip` must switch on): `loaded` once
  /// it has answered, `failure` when it failed before answering, `loading`
  /// while it is still in flight — so a *sibling* stream can neither fake
  /// readiness nor fake a failure.
  PipStatus get nestStatus => _streamStatus(nestSettled, nestError);

  /// The evolution stream's own status (what `/pip-evolution` must switch on).
  PipStatus get evolutionStatus =>
      _streamStatus(evolutionSettled, evolutionError);

  static PipStatus _streamStatus(bool settled, String? error) {
    if (settled) return PipStatus.loaded;
    if (error != null) return PipStatus.failure;
    return PipStatus.loading;
  }

  /// `loaded` only when both streams have answered; `failure` when one failed
  /// with nothing of its own to show; otherwise the feature is still loading.
  static PipStatus _combine({
    required bool nestSettled,
    required bool evolutionSettled,
    required String? nestError,
    required String? evolutionError,
  }) {
    final failedBeforeAnswering =
        (nestError != null && !nestSettled) ||
        (evolutionError != null && !evolutionSettled);
    if (failedBeforeAnswering) return PipStatus.failure;
    if (nestSettled && evolutionSettled) return PipStatus.loaded;
    return PipStatus.loading;
  }

  /// Backwards-compatible wardrobe list for the K06 view (K07's nest view is
  /// the same list): the nest's items, empty before load.
  List<PipStage> get items => nest?.items ?? const <PipStage>[];

  /// A fresh load re-answers both streams, so both arrival flags drop: the
  /// screen goes back to its spinner while the new subscriptions stream in.
  /// The data and any pending action outcome are carried through (a reload
  /// must not blank what is on screen mid-session).
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

  /// Healthy nest emission: the nest stream has answered, so its own status is
  /// `loaded` (with a null nest — the no-child card). A pending action outcome
  /// is carried through, not cleared: in a tap burst the refused tap's toast
  /// must survive the sibling write's refresh (K06-BUG-7). The outcome clears
  /// on the next attempt via [withActionStarted], so a repeated outcome is
  /// still announced again. The evolution is carried through untouched, and
  /// any recorded load error is cleared.
  PipState copyWithLoaded(PipNest? next) {
    return PipState(
      status: _combine(
        nestSettled: true,
        evolutionSettled: evolutionSettled,
        nestError: null,
        evolutionError: evolutionError,
      ),
      nest: next,
      evolution: evolution,
      nestSettled: true,
      evolutionSettled: evolutionSettled,
      // The sibling's error slot is what [status] was computed FROM above, so
      // it must travel with the state: dropping it left `evolutionSettled`
      // false / `evolutionError` null, i.e. `evolutionStatus` = `loading`,
      // and `/pip-evolution` would spin forever instead of showing its
      // failure card (2b_build_ui.md §0).
      evolutionError: evolutionError,
      actionError: actionError,
      actionNonce: actionNonce,
    );
  }

  /// Healthy evolution emission (K07): mirrors [copyWithLoaded] — the nest is
  /// carried through untouched, the pending action outcome survives, and any
  /// recorded load error is cleared. Publishing `loaded` here is the point of
  /// the fix: the nest answering first can no longer claim the screen is
  /// ready.
  PipState copyWithEvolution(PipEvolution? next) {
    return PipState(
      status: _combine(
        nestSettled: nestSettled,
        evolutionSettled: true,
        nestError: nestError,
        evolutionError: null,
      ),
      nest: nest,
      evolution: next,
      nestSettled: nestSettled,
      evolutionSettled: true,
      // Mirror of [copyWithLoaded]: the sibling slot [status] was computed
      // FROM must travel with the state, or `nestStatus` would fall back to
      // `loading` and `/pip` would spin instead of retrying.
      nestError: nestError,
      actionError: actionError,
      actionNonce: actionNonce,
    );
  }

  /// The NEST stream failed. A stream that already answered keeps its data on
  /// screen (K03 review-finding-6 pattern: `nestSettled` stays true, so
  /// [nestStatus] stays `loaded`); only a nest that failed before answering
  /// becomes the failure card.
  PipState withNestError(Object error) {
    return PipState(
      status: _combine(
        nestSettled: nestSettled,
        evolutionSettled: evolutionSettled,
        nestError: error.toString(),
        evolutionError: evolutionError,
      ),
      nest: nest,
      evolution: evolution,
      nestSettled: nestSettled,
      evolutionSettled: evolutionSettled,
      errorMessage: error.toString(),
      nestError: error.toString(),
      evolutionError: evolutionError,
      actionError: actionError,
      actionNonce: actionNonce,
    );
  }

  /// The evolution stream failed — [withNestError]'s mirror, and the K07 half
  /// of K07-BUG-1: this can only ever turn `/pip-evolution`'s OWN status into
  /// a failure, never the sibling nest stream's.
  PipState withEvolutionError(Object error) {
    return PipState(
      status: _combine(
        nestSettled: nestSettled,
        evolutionSettled: evolutionSettled,
        nestError: nestError,
        evolutionError: error.toString(),
      ),
      nest: nest,
      evolution: evolution,
      nestSettled: nestSettled,
      evolutionSettled: evolutionSettled,
      errorMessage: error.toString(),
      nestError: nestError,
      evolutionError: error.toString(),
      actionError: actionError,
      actionNonce: actionNonce,
    );
  }

  /// An action attempt starts: forget the previous outcome so a repeat
  /// outcome is announced again.
  PipState withActionStarted() {
    return PipState(
      status: status,
      nest: nest,
      evolution: evolution,
      nestSettled: nestSettled,
      evolutionSettled: evolutionSettled,
      errorMessage: errorMessage,
      nestError: nestError,
      evolutionError: evolutionError,
    );
  }

  /// The write failed (or the buy was unaffordable): distinct state per
  /// failure via [actionNonce].
  PipState withActionFailed(Object error) {
    return PipState(
      status: status,
      nest: nest,
      evolution: evolution,
      nestSettled: nestSettled,
      evolutionSettled: evolutionSettled,
      errorMessage: errorMessage,
      nestError: nestError,
      evolutionError: evolutionError,
      actionError: error.toString(),
      actionNonce: actionNonce + 1,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    nest,
    evolution,
    nestSettled,
    evolutionSettled,
    errorMessage,
    nestError,
    evolutionError,
    actionError,
    actionNonce,
  ];
}
