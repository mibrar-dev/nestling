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
