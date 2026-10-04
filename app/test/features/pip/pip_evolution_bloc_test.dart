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
        errorMessage: 'stale',
      );
      final next = loaded.copyWithEvolution(_mayaEvolution);
      expect(next.status, PipStatus.loaded);
      expect(next.nest, _mayaNest);
      expect(next.evolution?.questsDone, 4);
      expect(next.errorMessage, isNull);
    });

    test('copyWithLoaded carries the evolution through', () {
      const withEvolution = PipState(
        status: PipStatus.loaded,
        evolution: _mayaEvolution,
      );
      final next = withEvolution.copyWithLoaded(_mayaNest);
      expect(next.nest, _mayaNest);
      expect(next.evolution?.questsDone, 4);
    });

    test('withStreamError keeps the shown data and records the error', () {
      const loaded = PipState(
        status: PipStatus.loaded,
        nest: _mayaNest,
        evolution: _mayaEvolution,
      );
      final next = loaded.withStreamError(Exception('boom'));
      expect(next.status, PipStatus.loaded);
      expect(next.nest, _mayaNest);
      expect(next.evolution, _mayaEvolution);
      expect(next.errorMessage, contains('boom'));
    });

    test('toFailure drops the data', () {
      const loaded = PipState(
        status: PipStatus.loaded,
        nest: _mayaNest,
        evolution: _mayaEvolution,
      );
      final next = loaded.toFailure(Exception('boom'));
      expect(next.status, PipStatus.failure);
      expect(next.nest, isNull);
      expect(next.evolution, isNull);
    });

    test('evolution events carry every field', () {
      const received = PipEvolutionReceived(_mayaEvolution);
      expect(received.evolution?.questsDone, 4);
      expect(received, const PipEvolutionReceived(_mayaEvolution));
      const failed = PipEvolutionFailed('x');
      expect(failed, isNot(const PipEvolutionFailed('y')));
    });

    test('a null evolution emission loads the no-child path, not a failure', () {
      // `watchEvolution()` emits null when there is no active child. That is a
      // HEALTHY emission: it must report `loaded` with a null evolution, which
      // the view renders as "Who's playing?" — never the failure card.
      final next = const PipState(status: PipStatus.loading)
          .copyWithEvolution(null);
      expect(next.status, PipStatus.loaded);
      expect(next.evolution, isNull);
      expect(next.nest, isNull);
      expect(next.errorMessage, isNull);
    });

    test('toLoading carries the evolution, so a reload keeps the screen', () {
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
      expect(const PipState().props, hasLength(6));
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
      expect(bloc.state.status, PipStatus.loaded);
      expect(bloc.state.nest?.profile.nickname, 'Maya');
      expect(bloc.state.evolution, isNull);

      repo.evolution.add(_mayaEvolution);
      await Future<void>.delayed(_settle);
      expect(bloc.state.status, PipStatus.loaded);
      expect(bloc.state.nest?.profile.nickname, 'Maya');
      expect(bloc.state.evolution?.questsDone, 4);

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
      expect(bloc.state.status, PipStatus.loaded);
      expect(bloc.state.nest, isNull);

      repo.nest.addError(Exception('nest down'));
      await Future<void>.delayed(_settle);

      expect(bloc.state.status, PipStatus.loaded);
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
    }, skip: true);

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
      expect(bloc.state.status, PipStatus.loaded);
      expect(bloc.state.evolution?.questsDone, 4);
      expect(bloc.state.errorMessage, isNull);

      await sub.cancel();
      await bloc.close();
      await repo.nest.close();
      await repo.evolution.close();
    });

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
