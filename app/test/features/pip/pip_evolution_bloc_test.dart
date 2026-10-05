// K07 bloc tests: the evolution half of `PipBloc` (1_plan.md §(b), §(f)).
//
// The K06 nest/care/wardrobe paths keep their exact sequences in
// `pip_bloc_test.dart` (where the evolution stream is silent); here the
// nest stream is controlled instead, so every dual-stream interleaving is
// deterministic:
//
//   * `PipLoadRequested` starts BOTH subscriptions; loading -> loaded with
//     the evolution once it arrives.
//   * A stream error with nothing shown becomes the failure card; a
//     mid-session error keeps the loaded screen (K03 review-finding-6).
//   * Errors release only their own subscription, so "Try again" reloads.
//   * `close()` cancels both subscriptions (no stray timers).
//
// Plus one end-to-end load over the real Drift-backed repository
// (Seed.demo): Maya ends loaded with `{stage 3, questsDone 4}`.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/pip/data/pip_repository_impl.dart';
import 'package:nestling/features/pip/domain/entities/pip_evolution.dart';
import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/entities/pip_profile.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_bloc.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_event.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_state.dart';

const PipProfile _mayaProfile = PipProfile(
  childId: 'maya',
  nickname: 'Maya',
  style: 'mochi',
  skin: 'sunny',
  accessory: 'none',
  stage: 3,
  totalCoins: 175,
  coins: 120,
  happiness: 4,
);

const PipNest _mayaNest = PipNest(profile: _mayaProfile);

const PipEvolution _mayaEvolution = PipEvolution(
  profile: _mayaProfile,
  questsDone: 4,
);

/// Repository with both load streams under test control (broadcast, so a
/// retry after an error-release can listen again). Anything pushed after
/// the bloc has subscribed is forwarded; anything pushed before is
/// dropped — tests always push after a settle.
class _ControlledPipRepository extends PipRepositoryImpl {
  _ControlledPipRepository({required super.db})
    : nest = StreamController<PipNest?>.broadcast(),
      evolution = StreamController<PipEvolution?>.broadcast();

  final StreamController<PipNest?> nest;
  final StreamController<PipEvolution?> evolution;

  @override
  Stream<PipNest?> watchNest() => nest.stream;

  @override
  Stream<PipEvolution?> watchEvolution() => evolution.stream;
}

const Duration _settle = Duration(milliseconds: 60);

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    await Seed.demo(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('PipState evolution', () {
    test('defaults carry no evolution', () {
      const state = PipState();
      expect(state.evolution, isNull);
    });

    test('copyWithEvolution loads the evolution and carries the nest', () {
      const loaded = PipState(
        status: PipStatus.loaded,
        nest: _mayaNest,
        nestSettled: true,
        evolutionSettled: true,
        errorMessage: 'stale',
      );
      final next = loaded.copyWithEvolution(_mayaEvolution);
      expect(next.status, PipStatus.loaded);
      expect(next.nest, _mayaNest);
      expect(next.evolution?.questsDone, 4);
      expect(next.evolutionSettled, isTrue);
      expect(next.errorMessage, isNull);
    });

    test('copyWithLoaded carries the evolution through', () {
      const withEvolution = PipState(
        status: PipStatus.loaded,
        evolution: _mayaEvolution,
        nestSettled: true,
        evolutionSettled: true,
      );
      final next = withEvolution.copyWithLoaded(_mayaNest);
      expect(next.nest, _mayaNest);
      expect(next.evolution?.questsDone, 4);
    });

    test('a stream error lands in its OWN slot, and only that stream can fail '
        'its own screen', () {
      // 6_bugs.md K07-BUG-1 / `4_review.md` finding 2: one error slot per
      // stream, so a nest failure can neither fake readiness nor fake a
      // failure on the evolution screen (and the mirror holds).
      const loaded = PipState(
        status: PipStatus.loaded,
        nest: _mayaNest,
        evolution: _mayaEvolution,
        nestSettled: true,
        evolutionSettled: true,
      );

      final nestFailed = loaded.withNestError(Exception('nest boom'));
      expect(nestFailed.nestError, contains('nest boom'));
      expect(nestFailed.evolutionError, isNull, reason: 'the sibling slot');
      expect(
        nestFailed.evolutionStatus,
        PipStatus.loaded,
        reason: 'a nest failure must not turn /pip-evolution into a failure',
      );
      expect(nestFailed.nest, _mayaNest, reason: 'the shown data is kept');

      final evolutionFailed = loaded.withEvolutionError(Exception('evo boom'));
      expect(evolutionFailed.evolutionError, contains('evo boom'));
      expect(evolutionFailed.nestError, isNull);
      expect(
        evolutionFailed.nestStatus,
        PipStatus.loaded,
        reason: 'the sibling is untouched',
      );

      // The failure verdict belongs to a stream that failed BEFORE it ever
      // answered; one that already showed its data keeps it (the keep-loaded
      // rule above), so a kid never loses a screen to a late hiccup.
      const pending = PipState(status: PipStatus.loading);
      final early = pending.withEvolutionError(Exception('evo boom'));
      expect(early.evolutionStatus, PipStatus.failure);
      expect(early.status, PipStatus.failure);
      expect(
        pending.withNestError(Exception('nest boom')).nestStatus,
        PipStatus.failure,
        reason: 'the mirror: a nest failure is never a K07 failure',
      );
    });

    test('a stream that already answered keeps its status loaded through an '
        'error (K03 review-finding-6)', () {
      // Data is on screen, so a mid-session error must not blank it.
      final next = const PipState(status: PipStatus.loading)
          .copyWithLoaded(_mayaNest)
          .copyWithEvolution(_mayaEvolution)
          .withEvolutionError(Exception('boom'));
      expect(next.evolutionStatus, PipStatus.loaded);
      expect(next.evolution?.questsDone, 4);
      expect(
        next.errorMessage,
        contains('boom'),
        reason: 'recorded, not shown',
      );
    });

    test('a stream that failed BEFORE answering fails, dropping nothing', () {
      final next = const PipState(status: PipStatus.loading)
          .withEvolutionError(Exception('boom'));
      expect(next.status, PipStatus.failure);
      expect(next.evolutionStatus, PipStatus.failure);
      expect(next.nestStatus, PipStatus.loading, reason: 'still in flight');
      expect(next.evolution, isNull);
      expect(next.nest, isNull);
    });

    test('the per-stream statuses ignore the sibling entirely', () {
      const initial = PipState();
      expect(initial.nestStatus, PipStatus.loading);
      expect(initial.evolutionStatus, PipStatus.loading);
      expect(initial.status, PipStatus.initial);

      // K06 answers first: the evolution screen is still loading, and nothing
      // about the nest's arrival can call it a failure.
      final nestOnly = initial.copyWithLoaded(_mayaNest);
      expect(nestOnly.nestStatus, PipStatus.loaded);
      expect(nestOnly.evolutionStatus, PipStatus.loading);
      expect(nestOnly.status, PipStatus.loading);

      // K07 answers: now — and only now — the feature is loaded.
      final both = nestOnly.copyWithEvolution(_mayaEvolution);
      expect(both.status, PipStatus.loaded);
      expect(both.nestStatus, PipStatus.loaded);
      expect(both.evolutionStatus, PipStatus.loaded);
    });

    test(
      'a healthy emission CARRIES the sibling error slot status came from',
      () {
        // The nest answers AFTER the evolution stream failed. `copyWithLoaded`
        // derives `status` from `evolutionError`, so that slot must travel into
        // the state it produced: dropped, `evolutionStatus` reads `loading`
        // from a settled-false / error-null pair and `/pip-evolution` would
        // spin forever instead of showing its failure card (2b_build_ui.md
        // §0 — the real stream's `Stream.error` lands first, the nest needs
        // Drift I/O).
        final afterNest = const PipState(status: PipStatus.loading)
            .withEvolutionError(Exception('boom'))
            .copyWithLoaded(_mayaNest);
        expect(afterNest.status, PipStatus.failure, reason: 'computed from it');
        expect(
          afterNest.evolutionError,
          contains('boom'),
          reason: 'carried into the state that computed from it',
        );
        expect(
          afterNest.evolutionStatus,
          PipStatus.failure,
          reason: 'the slot and the per-stream status must agree',
        );

        // The mirror: the nest error must survive K07's healthy emission.
        final afterEvolution = const PipState(status: PipStatus.loading)
            .withNestError(Exception('bang'))
            .copyWithEvolution(_mayaEvolution);
        expect(afterEvolution.nestError, contains('bang'));
        expect(afterEvolution.nestStatus, PipStatus.failure);
      },
    );

    test(
      'a null evolution emission settles the stream as loaded (no-child)',
      () {
        final next = const PipState(status: PipStatus.loading)
            .copyWithEvolution(null);
        expect(next.evolutionSettled, isTrue);
        expect(next.evolutionStatus, PipStatus.loaded);
        expect(next.evolutionError, isNull);
        expect(next.evolution, isNull);
      },
    );

    test('toLoading re-arms both arrival flags but keeps the data', () {
      const loaded = PipState(
        status: PipStatus.loaded,
        nest: _mayaNest,
        evolution: _mayaEvolution,
        nestSettled: true,
        evolutionSettled: true,
      );
      final loading = loaded.toLoading();
      expect(loading.status, PipStatus.loading);
      expect(loading.nestSettled, isFalse);
      expect(loading.evolutionSettled, isFalse);
      expect(
        loading.nestStatus,
        PipStatus.loading,
        reason: 'the fresh subscriptions have not answered yet',
      );
      expect(loading.evolution?.questsDone, 4, reason: 'no blanking');
    });

    test('a retry resets only the stream it actually restarts '
        '(4_review.md finding 1)', () {
      // `PipLoadRequested` re-subscribes with `??=`, so a retry after ONE
      // stream's failure keeps the healthy subscription. Clearing both
      // arrival flags would report that live stream as `loading` until some
      // unrelated table write re-emitted it — a screen on a spinner with no
      // retry button. The reset is therefore explicit per stream.
      const loaded = PipState(
        status: PipStatus.loaded,
        nest: _mayaNest,
        evolution: _mayaEvolution,
        nestSettled: true,
        evolutionSettled: true,
      );

      final nestRetry = loaded.toLoading(restartingEvolution: false);
      expect(nestRetry.status, PipStatus.loading);
      expect(nestRetry.nestSettled, isFalse);
      expect(nestRetry.nestStatus, PipStatus.loading);
      expect(
        nestRetry.evolutionSettled,
        isTrue,
        reason: 'the evolution subscription was never released',
      );
      expect(
        nestRetry.evolutionStatus,
        PipStatus.loaded,
        reason: 'K07 must not drop to a spinner while K06 retries',
      );
      expect(nestRetry.evolution?.questsDone, 4);

      final evolutionRetry = loaded.toLoading(restartingNest: false);
      expect(evolutionRetry.nestSettled, isTrue);
      expect(evolutionRetry.nestStatus, PipStatus.loaded);
      expect(evolutionRetry.evolutionSettled, isFalse);
      expect(evolutionRetry.evolutionStatus, PipStatus.loading);

      // A restart also clears THAT stream's error slot only: the sibling's
      // recorded error must survive so its own status stays honest.
      final withErrors = loaded
          .withNestError(Exception('nest down'))
          .withEvolutionError(Exception('evolution down'));
      expect(withErrors.status, PipStatus.loaded);
      final evolutionRetry2 = withErrors.toLoading(restartingNest: false);
      expect(evolutionRetry2.nestError, contains('nest down'));
      expect(evolutionRetry2.evolutionError, isNull);
      expect(evolutionRetry2.nestStatus, PipStatus.loaded);

      // The defaults still describe a full reload, so any caller that has no
      // reason to think (and every existing fixture) keeps today's behaviour.
      final full = loaded.toLoading();
      expect(full.nestSettled, isFalse);
      expect(full.evolutionSettled, isFalse);
      expect(full.status, PipStatus.loading);
      expect(full.evolution?.questsDone, 4, reason: 'no blanking');
    });

    test('evolution events carry every field', () {
      const received = PipEvolutionReceived(_mayaEvolution);
      expect(received.evolution?.questsDone, 4);
      expect(received, const PipEvolutionReceived(_mayaEvolution));
      const failed = PipEvolutionFailed('x');
      expect(failed, isNot(const PipEvolutionFailed('y')));
    });

    test('a null evolution emission settles the no-child path, not a failure', () {
      // `watchEvolution()` emits null when there is no active child. That is a
      // HEALTHY emission: it must report its own stream as `loaded` with a null
      // evolution, which the view renders as "Who's playing?" — never the
      // failure card.
      final next = const PipState(status: PipStatus.loading)
          .copyWithLoaded(_mayaNest)
          .copyWithEvolution(null);
      expect(next.status, PipStatus.loaded);
      expect(next.evolutionStatus, PipStatus.loaded);
      expect(next.evolution, isNull);
      expect(next.nest, _mayaNest);
      expect(next.errorMessage, isNull);
    });

    test('toLoading keeps the data a reload must not blank', () {
      const loaded = PipState(
        status: PipStatus.loaded,
        evolution: _mayaEvolution,
      );
      final loading = loaded.toLoading();
      expect(loading.status, PipStatus.loading);
      expect(loading.evolution?.questsDone, 4);
      // The load list is `items` (the K06 wardrobe), which reads off the nest —
      // so a reload must not blank what is on screen mid-session.
      expect(loading.items, isEmpty);
    });

    test('the action paths carry the evolution through untouched', () {
      // K06's care/wardrobe actions share this state, and a toast must survive
      // the sibling stream's refresh (K06-BUG-7) — so every constructor that
      // keeps `status` must keep the evolution too.
      const loaded = PipState(
        status: PipStatus.loaded,
        evolution: _mayaEvolution,
      );
      expect(loaded.withActionStarted().evolution?.questsDone, 4);
      expect(
        loaded.withActionFailed(Exception('boom')).evolution?.questsDone,
        4,
      );
      // The nonce makes two SUCCESSIVE identical failures distinct states, so
      // the second toast is still announced.
      final first = loaded.withActionFailed(Exception('boom'));
      final second = first.withActionFailed(Exception('boom'));
      expect(first.actionNonce, 1);
      expect(second.actionNonce, 2);
      expect(second, isNot(first));
      expect(second.evolution?.questsDone, 4);
    });

    test('the evolution is part of state equality and props', () {
      const a = PipState(evolution: _mayaEvolution);
      const b = PipState(evolution: _mayaEvolution);
      const c = PipState(
        evolution: PipEvolution(profile: _mayaProfile, questsDone: 5),
      );
      expect(a, b);
      expect(a, isNot(c));
      expect(a.props, contains(_mayaEvolution));
      // Every field is in `props`, the two arrival flags included: two states
      // that differ only in whether a stream has answered must not collapse.
      expect(const PipState().props, hasLength(10));
      expect(
        const PipState(nestSettled: true),
        isNot(const PipState()),
        reason: 'the arrival flags are part of state identity',
      );
    });

    test('the distinct-quest count (K07-BUG-3) defaults to the row count', () {
      // `PipEvolution(profile:, questsDone:)` — what the older fixtures build —
      // must keep working, and the card then shows the row count.
      const rowsOnly = PipEvolution(profile: _mayaProfile, questsDone: 5);
      expect(rowsOnly.questsFinished, isNull);
      expect(rowsOnly.questsFinishedCount, 5);

      const split = PipEvolution(
        profile: _mayaProfile,
        questsDone: 5,
        questsFinished: 4,
      );
      expect(split.questsFinishedCount, 4, reason: 'the card counts quests');
      expect(split.questsDone, 5, reason: 'the sub-line counts times');
      expect(
        split.props,
        contains(4),
        reason: 'the card number is part of entity equality',
      );
    });
  });

  group('PipBloc evolution (controlled streams)', () {
    test('load ends loaded with the evolution once it arrives', () async {
      final repo = _ControlledPipRepository(db: db);
      final bloc = PipBloc(repository: repo);
      final states = <PipState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const PipLoadRequested());
      await Future<void>.delayed(_settle);
      expect(bloc.state.status, PipStatus.loading);

      repo.nest.add(_mayaNest);
      await Future<void>.delayed(_settle);
      expect(bloc.state.nestStatus, PipStatus.loaded, reason: 'K06 answered');
      expect(
        bloc.state.evolutionStatus,
        PipStatus.loading,
        reason: 'K07 is still in flight — K06 says nothing about it',
      );
      expect(bloc.state.nest?.profile.nickname, 'Maya');
      expect(bloc.state.evolution, isNull);

      repo.evolution.add(_mayaEvolution);
      await Future<void>.delayed(_settle);
      expect(bloc.state.status, PipStatus.loaded);
      expect(bloc.state.nest?.profile.nickname, 'Maya');
      expect(bloc.state.evolution?.questsDone, 4);
      expect(bloc.state.evolution?.questsFinishedCount, 4);

      await sub.cancel();
      await bloc.close();
      await repo.nest.close();
      await repo.evolution.close();
    });

    test('an evolution error with nothing shown becomes failure', () async {
      final repo = _ControlledPipRepository(db: db);
      final bloc = PipBloc(repository: repo);
      final sub = bloc.stream.listen((_) {});

      bloc.add(const PipLoadRequested());
      await Future<void>.delayed(_settle);
      repo.evolution.addError(Exception('evolution down'));
      await Future<void>.delayed(_settle);

      expect(bloc.state.status, PipStatus.failure);
      expect(bloc.state.errorMessage, contains('evolution down'));
      expect(bloc.state.nest, isNull);
      expect(bloc.state.evolution, isNull);

      await sub.cancel();
      await bloc.close();
      await repo.nest.close();
      await repo.evolution.close();
    });

    test('a mid-session evolution error keeps the loaded screen', () async {
      final repo = _ControlledPipRepository(db: db);
      final bloc = PipBloc(repository: repo);
      final sub = bloc.stream.listen((_) {});

      bloc.add(const PipLoadRequested());
      await Future<void>.delayed(_settle);
      repo.nest.add(_mayaNest);
      repo.evolution.add(_mayaEvolution);
      await Future<void>.delayed(_settle);
      expect(bloc.state.status, PipStatus.loaded);

      repo.evolution.addError(Exception('evolution down'));
      await Future<void>.delayed(_settle);

      expect(bloc.state.status, PipStatus.loaded);
      expect(bloc.state.nest?.profile.nickname, 'Maya');
      expect(bloc.state.evolution?.questsDone, 4);

      await sub.cancel();
      await bloc.close();
      await repo.nest.close();
      await repo.evolution.close();
    });

    test('a mid-session nest error keeps the shown evolution', () async {
      final repo = _ControlledPipRepository(db: db);
      final bloc = PipBloc(repository: repo);
      final sub = bloc.stream.listen((_) {});

      bloc.add(const PipLoadRequested());
      await Future<void>.delayed(_settle);
      repo.evolution.add(_mayaEvolution);
      await Future<void>.delayed(_settle);
      expect(
        bloc.state.evolutionStatus,
        PipStatus.loaded,
        reason: 'K07 answered; K06 is still in flight',
      );

      repo.nest.addError(Exception('nest down'));
      await Future<void>.delayed(_settle);

      expect(
        bloc.state.evolutionStatus,
        PipStatus.loaded,
        reason: 'a NEST failure must not blank the celebration screen',
      );
      expect(bloc.state.nestStatus, PipStatus.failure);
      expect(bloc.state.evolution?.questsDone, 4);

      await sub.cancel();
      await bloc.close();
      await repo.nest.close();
      await repo.evolution.close();
    });

    test('the recorded error is never shown to the child, and is cleared by the '
        'next healthy emission', () async {
      // `4_review.md` finding 4: `errorMessage` is written from two places and
      // read by neither view, so nothing pinned it. It stays diagnostic-only
      // (raw DB text must not reach a kid screen), but a refactor must not be
      // able to drop the recording silently.
      final repo = _ControlledPipRepository(db: db);
      final bloc = PipBloc(repository: repo);
      final sub = bloc.stream.listen((_) {});

      bloc.add(const PipLoadRequested());
      await Future<void>.delayed(_settle);
      repo.nest.add(_mayaNest);
      repo.evolution.add(_mayaEvolution);
      await Future<void>.delayed(_settle);
      expect(bloc.state.errorMessage, isNull);

      repo.evolution.addError(Exception('evolution down'));
      await Future<void>.delayed(_settle);
      expect(bloc.state.status, PipStatus.loaded, reason: 'still showing');
      expect(bloc.state.errorMessage, contains('evolution down'));
      // The K07 view renders copy, never `errorMessage` — proven in
      // `pip_evolution_view_test.dart` (no raw exception on screen).
      expect(bloc.state.evolution?.questsDone, 4);

      repo.evolution.add(_mayaEvolution);
      await Future<void>.delayed(_settle);
      expect(
        bloc.state.errorMessage,
        isNotNull,
        reason:
            'the failed stream is RELEASED, so nothing arrives until the '
            'retry re-subscribes',
      );
      bloc.add(const PipLoadRequested());
      await Future<void>.delayed(_settle);
      repo.evolution.add(_mayaEvolution);
      await Future<void>.delayed(_settle);
      expect(
        bloc.state.errorMessage,
        isNull,
        reason: 'a healthy load clears the recorded error',
      );

      await sub.cancel();
      await bloc.close();
      await repo.nest.close();
      await repo.evolution.close();
    });

    test(
      'a load error with nothing shown records the message on the failure',
      () async {
        final repo = _ControlledPipRepository(db: db);
        final bloc = PipBloc(repository: repo);
        final sub = bloc.stream.listen((_) {});

        bloc.add(const PipLoadRequested());
        await Future<void>.delayed(_settle);
        repo.nest.addError(Exception('nest down'));
        repo.evolution.addError(Exception('evolution down'));
        await Future<void>.delayed(_settle);

        expect(bloc.state.status, PipStatus.failure);
        expect(bloc.state.errorMessage, contains('down'));
        expect(bloc.state.nest, isNull);
        expect(bloc.state.evolution, isNull);

        await sub.cancel();
        await bloc.close();
        await repo.nest.close();
        await repo.evolution.close();
      },
    );

    test('K07-BUG-1: a NEST emission alone must not report loaded while this '
        'screen’s stream is still pending', () async {
      // Stage 6's major finding (`6_bugs.md` K07-BUG-1), pinned at the
      // state level so the fix is verified by both stages' proofs.
      // `watchNest()` combines three Drift tables and `watchEvolution()`
      // two, so the nest can answer first; `copyWithLoaded` then promotes
      // `loaded`, and `/pip-evolution` renders a null evolution as the
      // "Oh no! Pip got lost." card (5/5 cold opens).
      final repo = _ControlledPipRepository(db: db);
      final bloc = PipBloc(repository: repo);
      final seen = <PipStatus>[];
      final sub = bloc.stream.listen((state) => seen.add(state.status));
      bloc.add(const PipLoadRequested());

      await Future<void>.delayed(_settle);
      repo.nest.add(_mayaNest);
      await Future<void>.delayed(_settle);

      expect(
        bloc.state.status,
        PipStatus.loading,
        reason: 'this screen’s own stream has not answered yet',
      );
      expect(bloc.state.nest, isNotNull, reason: 'K06’s data did arrive');
      expect(bloc.state.evolutionStatus, PipStatus.loading);
      expect(
        bloc.state.evolutionError,
        isNull,
        reason: 'pending is not failure — nothing has errored',
      );

      // Only its OWN stream may say the screen is ready.
      repo.evolution.add(_mayaEvolution);
      await Future<void>.delayed(_settle);
      expect(bloc.state.status, PipStatus.loaded);
      expect(bloc.state.evolution?.questsDone, 4);
      // The whole point: `loaded` is published exactly once, and only after
      // this screen's own stream answered.
      expect(seen.where((s) => s == PipStatus.loaded), hasLength(1));

      await sub.cancel();
      await bloc.close();
      await repo.nest.close();
      await repo.evolution.close();
    });

    test('retry after an evolution failure really reloads', () async {
      final repo = _ControlledPipRepository(db: db);
      final bloc = PipBloc(repository: repo);
      final sub = bloc.stream.listen((_) {});

      bloc.add(const PipLoadRequested());
      await Future<void>.delayed(_settle);
      repo.evolution.addError(Exception('evolution down'));
      await Future<void>.delayed(_settle);
      expect(bloc.state.status, PipStatus.failure);

      // The failed subscription was released, so the retry re-subscribes
      // (broadcast controllers allow the second listen) and the healthy
      // emission restores `loaded` with a cleared load error.
      bloc.add(const PipLoadRequested());
      await Future<void>.delayed(_settle);
      expect(bloc.state.status, PipStatus.loading);
      repo.evolution.add(_mayaEvolution);
      await Future<void>.delayed(_settle);
      // The nest stream is deliberately silent in this test (only the failed
      // one is retried), so the K07 half of the state is what may say "ready":
      // the aggregate `status` needs BOTH streams answered.
      expect(bloc.state.evolutionStatus, PipStatus.loaded);
      expect(bloc.state.status, PipStatus.loading);
      expect(bloc.state.evolution?.questsDone, 4);
      expect(bloc.state.errorMessage, isNull);

      await sub.cancel();
      await bloc.close();
      await repo.nest.close();
      await repo.evolution.close();
    });

    test('a retry keeps the SURVIVING stream loaded '
        '(4_review.md finding 1)', () async {
      // The review's requested proof: one stream fails before answering, the
      // other is healthy and has already loaded, and the sibling NEVER
      // re-emits. Before the fix `toLoading()` cleared both arrival flags, so
      // the healthy stream reported `loading` and its screen sat on a spinner
      // forever (the retry button only exists on the `failure` branch). The
      // mirror case is asserted too, so neither direction can regress.
      final repo = _ControlledPipRepository(db: db);
      final bloc = PipBloc(repository: repo);
      final evolutionStatuses = <PipStatus>[];
      final sub = bloc.stream.listen((state) {
        evolutionStatuses.add(state.evolutionStatus);
      });

      bloc.add(const PipLoadRequested());
      await Future<void>.delayed(_settle);
      repo.evolution.add(_mayaEvolution);
      repo.nest.addError(Exception('nest down'));
      await Future<void>.delayed(_settle);

      expect(bloc.state.nestStatus, PipStatus.failure, reason: 'K06 retries');
      expect(bloc.state.evolutionStatus, PipStatus.loaded);
      evolutionStatuses.clear(); // only what is published from here on

      // K06's "Try again": the dead stream is re-subscribed, the live
      // evolution subscription is untouched (it never emits again).
      bloc.add(const PipLoadRequested());
      await Future<void>.delayed(_settle);

      expect(bloc.state.nestStatus, PipStatus.loading, reason: 're-subscribed');
      expect(
        bloc.state.evolutionStatus,
        PipStatus.loaded,
        reason: 'the surviving subscription keeps its own loaded status',
      );
      expect(
        bloc.state.evolution?.questsDone,
        4,
        reason: 'the celebration is never blanked by the sibling’s retry',
      );
      expect(
        evolutionStatuses,
        everyElement(PipStatus.loaded),
        reason: 'evolutionStatus must never dip back to loading once loaded',
      );

      repo.nest.add(_mayaNest);
      await Future<void>.delayed(_settle);
      expect(bloc.state.status, PipStatus.loaded);
      expect(bloc.state.nestStatus, PipStatus.loaded);

      await sub.cancel();
      await bloc.close();
      await repo.nest.close();
      await repo.evolution.close();
    });

    test(
      'the mirror: a retried evolution leaves the NEST stream loaded',
      () async {
        final repo = _ControlledPipRepository(db: db);
        final bloc = PipBloc(repository: repo);
        final nestStatuses = <PipStatus>[];
        final sub = bloc.stream.listen(
          (state) => nestStatuses.add(state.nestStatus),
        );

        bloc.add(const PipLoadRequested());
        await Future<void>.delayed(_settle);
        repo.nest.add(_mayaNest);
        repo.evolution.addError(Exception('evolution down'));
        await Future<void>.delayed(_settle);
        expect(bloc.state.evolutionStatus, PipStatus.failure);
        expect(bloc.state.nestStatus, PipStatus.loaded);
        nestStatuses.clear(); // only what is published from here on

        bloc.add(const PipLoadRequested());
        await Future<void>.delayed(_settle);

        expect(bloc.state.evolutionStatus, PipStatus.loading);
        expect(bloc.state.nestStatus, PipStatus.loaded);
        expect(bloc.state.nest?.profile.nickname, 'Maya');
        expect(nestStatuses, everyElement(PipStatus.loaded));

        repo.evolution.add(_mayaEvolution);
        await Future<void>.delayed(_settle);
        expect(bloc.state.status, PipStatus.loaded);

        await sub.cancel();
        await bloc.close();
        await repo.nest.close();
        await repo.evolution.close();
      },
    );

    test('a second load while both streams are live is ignored', () async {
      final repo = _ControlledPipRepository(db: db);
      final bloc = PipBloc(repository: repo);
      final states = <PipState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const PipLoadRequested());
      await Future<void>.delayed(_settle);
      repo.nest.add(_mayaNest);
      repo.evolution.add(_mayaEvolution);
      await Future<void>.delayed(_settle);
      final settled = states.length;
      expect(settled, greaterThan(0));

      bloc
        ..add(const PipLoadRequested())
        ..add(const PipLoadRequested());
      await Future<void>.delayed(_settle);

      expect(states.length, settled);
      expect(repo.nest.hasListener, isTrue);
      expect(repo.evolution.hasListener, isTrue);

      await sub.cancel();
      await bloc.close();
      await repo.nest.close();
      await repo.evolution.close();
    });

    test('close() cancels both subscriptions', () async {
      final repo = _ControlledPipRepository(db: db);
      final bloc = PipBloc(repository: repo);
      final sub = bloc.stream.listen((_) {});

      bloc.add(const PipLoadRequested());
      await Future<void>.delayed(_settle);
      expect(repo.nest.hasListener, isTrue);
      expect(repo.evolution.hasListener, isTrue);

      await bloc.close();
      await sub.cancel();
      expect(repo.nest.hasListener, isFalse);
      expect(repo.evolution.hasListener, isFalse);

      await repo.nest.close();
      await repo.evolution.close();
    });
  });

  group('PipBloc evolution (Seed.demo end to end)', () {
    test('load ends loaded with Maya stage 3 and 4 helped times', () async {
      final bloc = PipBloc(repository: PipRepositoryImpl(db: db));
      final sub = bloc.stream.listen((_) {});

      bloc.add(const PipLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(bloc.state.status, PipStatus.loaded);
      expect(bloc.state.nest?.profile.nickname, 'Maya');
      final evolution = bloc.state.evolution;
      expect(evolution, isNotNull);
      expect(evolution!.profile.stage, 3);
      expect(evolution.profile.totalCoins, 175);
      expect(evolution.questsDone, 4);

      await sub.cancel();
      await bloc.close();
    });
  });
}
