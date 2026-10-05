// K06 bloc — the event/state paths `pip_bloc_test.dart` (load + happy path)
// does not reach:
//
//   * every tap before a load has emitted a nest (no cached active child)
//   * silent no-ops (an accessory Pip already wears, wellies/crown equip)
//   * a THROWN write on every repository action (the toast channel)
//   * the same failure announced twice (actionNonce)
//   * the active-child switch in both directions, with care following it
//   * releasing the nest subscription on close()
//
// Same Drift-backed repository (Seed.demo) as the rest of the suite, plus
// two feature-local subclasses: a spy that records which write the bloc
// actually asked for — so "nothing happened" is proven, not inferred — and
// one that throws on demand.

import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/pip/data/pip_repository_impl.dart';
import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/entities/pip_profile.dart';
import 'package:nestling/features/pip/domain/pip_repository.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_bloc.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_event.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_state.dart';

/// Records every write the bloc asks for, then does the real thing.
class _SpyRepository extends PipRepositoryImpl {
  _SpyRepository({required super.db});

  /// e.g. `feed:maya`, `buy:wellies`, `look:scarf`.
  final List<String> calls = <String>[];

  @override
  Future<void> feed(String childId) {
    calls.add('feed:$childId');
    return super.feed(childId);
  }

  @override
  Future<void> play(String childId) {
    calls.add('play:$childId');
    return super.play(childId);
  }

  @override
  Future<void> bathe(String childId) {
    calls.add('bathe:$childId');
    return super.bathe(childId);
  }

  @override
  Future<PipBuyResult> buyItem(String childId, String item) {
    calls.add('buy:$item');
    return super.buyItem(childId, item);
  }

  @override
  Future<void> updateLook({
    required String childId,
    String? style,
    String? skin,
    String? accessory,
  }) {
    calls.add('look:$accessory');
    return super.updateLook(
      childId: childId,
      style: style,
      skin: skin,
      accessory: accessory,
    );
  }
}

/// Repository whose writes throw [Exception(message)] — the "the write
/// failed" toast path for every action, one at a time or all of them.
class _ThrowingRepository extends PipRepositoryImpl {
  _ThrowingRepository({required super.db, this.failing = ''});

  /// Empty = every action throws; otherwise one of
  /// `feed | play | bathe | buyItem | updateLook`.
  final String failing;

  bool _throws(String action) => failing.isEmpty || failing == action;

  Never _blow(String action) => throw Exception('$action down');

  @override
  Future<void> feed(String childId) =>
      _throws('feed') ? _blow('feed') : super.feed(childId);

  @override
  Future<void> play(String childId) =>
      _throws('play') ? _blow('play') : super.play(childId);

  @override
  Future<void> bathe(String childId) =>
      _throws('bathe') ? _blow('bathe') : super.bathe(childId);

  @override
  Future<PipBuyResult> buyItem(String childId, String item) =>
      _throws('buyItem') ? _blow('buyItem') : super.buyItem(childId, item);

  @override
  Future<void> updateLook({
    required String childId,
    String? style,
    String? skin,
    String? accessory,
  }) {
    if (_throws('updateLook')) _blow('updateLook');
    return super.updateLook(
      childId: childId,
      style: style,
      skin: skin,
      accessory: accessory,
    );
  }
}

/// `feed` throws on its first call only, so the retry really writes — the
/// "failure, then success" recovery path.
class _FlakyFeedRepository extends PipRepositoryImpl {
  _FlakyFeedRepository({required super.db});

  bool _failed = false;

  @override
  Future<void> feed(String childId) {
    if (!_failed) {
      _failed = true;
      throw Exception('feed down');
    }
    return super.feed(childId);
  }
}

const Duration _settle = Duration(milliseconds: 80);

/// One deliberate tap, separated from the next by [_settle]. A helper rather
/// than `bloc.add` inline so the "tap, wait, tap" sequencing reads as one
/// action and the linter does not ask for a cascade over it.
void _tap(PipBloc bloc, PipEvent event) => bloc.add(event);
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    await Seed.demo(db);
  });

  tearDown(() async {
    await db.close();
  });

  PipRepositoryImpl real() => PipRepositoryImpl(db: db);

  Future<PipProfile?> profile(String childId) =>
      real().watchProfile(childId).first;

  Future<void> setCoins(String childId, int coins) async {
    await (db.update(db.children)..where((c) => c.id.equals(childId))).write(
      ChildrenCompanion(coins: Value(coins)),
    );
  }

  Future<void> setAccessory(String childId, String accessory) async {
    await (db.update(db.children)..where((c) => c.id.equals(childId))).write(
      ChildrenCompanion(pipAccessory: Value(accessory)),
    );
  }

  Future<void> setActiveChild(String? childId) async {
    await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
      AppStateCompanion(activeChildId: Value(childId)),
    );
  }

  /// Loads, then runs [body] once the nest has settled.
  Future<PipBloc> loaded(PipRepositoryImpl repo) async {
    final bloc = PipBloc(repository: repo);
    _tap(bloc, const PipLoadRequested());
    await Future<void>.delayed(_settle);
    expect(bloc.state.status, PipStatus.loaded);
    expect(bloc.state.nest?.profile.childId, 'maya');
    return bloc;
  }

  group('taps before a load has a nest', () {
    test('care taps are ignored and never reach the repository', () async {
      final repo = _SpyRepository(db: db);
      final bloc = PipBloc(repository: repo);
      final states = <PipState>[];
      final sub = bloc.stream.listen(states.add);

      _tap(bloc, const PipCareRequested(PipCareKind.feed));
      _tap(bloc, const PipCareRequested(PipCareKind.play));
      _tap(bloc, const PipCareRequested(PipCareKind.bathe));
      await Future<void>.delayed(_settle);

      expect(states, isEmpty, reason: 'no nest, so no state may change');
      expect(repo.calls, isEmpty, reason: 'nothing may be written');
      // Neither child was touched.
      expect((await profile('maya'))!.coins, 120);
      expect((await profile('maya'))!.happiness, 4);
      expect((await profile('leo'))!.coins, 45);
      await sub.cancel();
      await bloc.close();
    });

    test('wardrobe taps are ignored and never reach the repository', () async {
      final repo = _SpyRepository(db: db);
      final bloc = PipBloc(repository: repo);
      final states = <PipState>[];
      final sub = bloc.stream.listen(states.add);

      _tap(bloc, const PipWardrobeBuyRequested('wellies'));
      _tap(bloc, const PipWardrobeEquipRequested('scarf'));
      await Future<void>.delayed(_settle);

      expect(states, isEmpty);
      expect(repo.calls, isEmpty);
      expect((await profile('maya'))!.coins, 120);
      expect((await profile('maya'))!.accessory, 'none');
      final wellies =
          await (db.select(db.pipWardrobe)..where(
                (w) => w.childId.equals('maya') & w.item.equals('wellies'),
              ))
              .getSingle();
      expect(wellies.owned, isFalse);
      await sub.cancel();
      await bloc.close();
    });
  });

  group('thrown writes (the action-error toast channel)', () {
    for (final action in const <String>[
      'feed',
      'play',
      'bathe',
      'buyItem',
      'updateLook',
    ]) {
      test('$action keeps the nest and records actionError + nonce', () async {
        final repo = _ThrowingRepository(db: db, failing: action);
        final bloc = await loaded(repo);
        final sub = bloc.stream.listen((_) {});

        switch (action) {
          case 'buyItem':
            bloc.add(const PipWardrobeBuyRequested('wellies'));
          case 'updateLook':
            bloc.add(const PipWardrobeEquipRequested('scarf'));
          default:
            bloc.add(
              PipCareRequested(switch (action) {
                'feed' => PipCareKind.feed,
                'play' => PipCareKind.play,
                _ => PipCareKind.bathe,
              }),
            );
        }
        await Future<void>.delayed(_settle);

        expect(bloc.state.status, PipStatus.loaded);
        expect(bloc.state.nest?.profile.coins, 120, reason: 'nest survives');
        expect(bloc.state.nest?.profile.nickname, 'Maya');
        expect(bloc.state.actionError, contains('$action down'));
        expect(bloc.state.actionNonce, 1);
        // The load-failure channel stays clean: this is not a screen failure.
        expect(bloc.state.errorMessage, isNull);
        await sub.cancel();
        await bloc.close();
      });
    }

    test(
      'the same failure twice is announced twice (nonce resets, then bumps)',
      () async {
        final repo = _ThrowingRepository(db: db, failing: 'feed');
        final bloc = await loaded(repo);
        final states = <PipState>[];
        final sub = bloc.stream.listen(states.add);

        bloc.add(const PipCareRequested(PipCareKind.feed));
        await Future<void>.delayed(_settle);
        bloc.add(const PipCareRequested(PipCareKind.feed));
        await Future<void>.delayed(_settle);

        // The view only re-announces when the nonce DIFFERS from the previous
        // state (`listenWhen` in pip_nest_view.dart). The bloc therefore resets
        // to 0 when an attempt starts and bumps to 1 when it fails, so the
        // sequence for two identical failures is 1 -> 0 -> 1: the second
        // refusal is a distinct transition and the toast shows again.
        // (The load's own `loading` -> `loaded` states, nonce 0, were emitted
        // before this listener attached.)
        expect(states.map((s) => s.actionNonce).toList(), <int>[1, 0, 1]);
        final failureIndexes = <int>[
          for (var i = 0; i < states.length; i++)
            if (states[i].actionError != null) i,
        ];
        expect(failureIndexes, <int>[
          0,
          2,
        ], reason: 'two refusals, each a distinct transition');
        expect(states[1].actionError, isNull, reason: 'the reset in between');
        expect(states[0].actionError, states[2].actionError);
        await sub.cancel();
        await bloc.close();
      },
    );

    test(
      'a failed action followed by a successful one clears the error',
      () async {
        // Throws the first feed only, so the second one really writes.
        final repo = _FlakyFeedRepository(db: db);
        final bloc = await loaded(repo);
        final sub = bloc.stream.listen((_) {});

        bloc.add(const PipCareRequested(PipCareKind.feed));
        await Future<void>.delayed(_settle);
        expect(bloc.state.actionError, contains('feed down'));
        expect(bloc.state.actionNonce, 1);
        expect(
          bloc.state.nest?.profile.coins,
          120,
          reason: 'nothing was spent',
        );

        bloc.add(const PipCareRequested(PipCareKind.feed));
        await Future<void>.delayed(_settle);

        // The success re-emits the nest, which drops the stale outcome: the
        // view's `listenWhen` can no longer announce the old failure twice.
        expect(bloc.state.actionError, isNull);
        expect(bloc.state.actionNonce, 0);
        expect(bloc.state.nest?.profile.coins, 115);
        await sub.cancel();
        await bloc.close();
      },
    );
  });

  group('silent no-ops', () {
    test('equipping the accessory Pip already wears writes nothing', () async {
      await setAccessory('maya', 'scarf');
      final repo = _SpyRepository(db: db);
      final bloc = await loaded(repo);
      final sub = bloc.stream.listen((_) {});

      bloc.add(const PipWardrobeEquipRequested('scarf'));
      await Future<void>.delayed(_settle);

      expect(repo.calls, isEmpty, reason: 'already wearing it');
      expect(bloc.state.actionError, isNull);
      expect(bloc.state.nest?.profile.accessory, 'scarf');
      await sub.cancel();
      await bloc.close();
    });

    test(
      'equipping wellies or crown emits no state and asks for no write',
      () async {
        final repo = _SpyRepository(db: db);
        final bloc = await loaded(repo);
        final states = <PipState>[];
        final sub = bloc.stream.listen(states.add);
        await Future<void>.delayed(_settle);
        final before = states.length;

        _tap(bloc, const PipWardrobeEquipRequested('wellies'));
        _tap(bloc, const PipWardrobeEquipRequested('crown'));
        await Future<void>.delayed(_settle);

        expect(repo.calls, isEmpty);
        expect(
          states.length,
          before,
          reason: 'no accessory node, so no toast and no state churn',
        );
        expect(bloc.state.actionError, isNull);
        await sub.cancel();
        await bloc.close();
      },
    );

    test(
      'an unknown wardrobe id is inert (the repository guards it)',
      () async {
        final repo = _SpyRepository(db: db);
        final bloc = await loaded(repo);
        final states = <PipState>[];
        final sub = bloc.stream.listen(states.add);

        bloc.add(const PipWardrobeBuyRequested('spacesuit'));
        await Future<void>.delayed(_settle);

        // No such row exists, so `buyItem` no-ops: no coins, no ownership, no
        // error. The tile can never carry an id the strip does not list.
        expect(repo.calls, <String>['buy:spacesuit']);
        expect(states, isEmpty);
        expect(bloc.state.actionError, isNull);
        expect((await profile('maya'))!.coins, 120);
        await sub.cancel();
        await bloc.close();
      },
    );

    test('an already-owned item cannot be bought again', () async {
      final repo = _SpyRepository(db: db);
      final bloc = await loaded(repo);
      final sub = bloc.stream.listen((_) {});

      // Scarf is owned in the seed and its price is 0, so the affordability
      // pre-check passes and the repository owns the guard.
      bloc.add(const PipWardrobeBuyRequested('scarf'));
      await Future<void>.delayed(_settle);

      expect(repo.calls, <String>['buy:scarf']);
      expect(bloc.state.actionError, isNull);
      expect((await profile('maya'))!.coins, 120);
      await sub.cancel();
      await bloc.close();
    });
  });

  group('the active child', () {
    test('switching to Leo re-emits his nest and care follows him', () async {
      final repo = _SpyRepository(db: db);
      final bloc = await loaded(repo);
      final sub = bloc.stream.listen((_) {});

      await setActiveChild('leo');
      await Future<void>.delayed(_settle);

      final nest = bloc.state.nest;
      expect(bloc.state.status, PipStatus.loaded);
      expect(nest?.profile.childId, 'leo');
      expect(nest?.profile.nickname, 'Leo');
      expect(nest?.profile.style, 'bolt');
      expect(nest?.profile.skin, 'sky');
      expect(nest?.profile.stage, 2);
      expect(nest?.profile.coins, 45);
      // Design order holds for every child, not just Maya.
      expect(nest!.items.map((i) => i.id).toList(), <String>[
        'scarf',
        'sunhat',
        'wellies',
        'crown',
      ]);

      bloc.add(const PipCareRequested(PipCareKind.feed));
      await Future<void>.delayed(_settle);

      expect(repo.calls, <String>['feed:leo'], reason: 'the resolved child');
      expect((await profile('leo'))!.coins, 40);
      expect((await profile('maya'))!.coins, 120, reason: 'Maya is untouched');
      await sub.cancel();
      await bloc.close();
    });

    test(
      'clearing the active child empties the nest and freezes care',
      () async {
        final repo = _SpyRepository(db: db);
        final bloc = await loaded(repo);
        final states = <PipState>[];
        final sub = bloc.stream.listen(states.add);

        await setActiveChild(null);
        await Future<void>.delayed(_settle);

        expect(bloc.state.status, PipStatus.loaded);
        expect(bloc.state.nest, isNull, reason: 'the no-child card');
        expect(states.last.nest, isNull);

        _tap(bloc, const PipCareRequested(PipCareKind.feed));
        _tap(bloc, const PipWardrobeBuyRequested('wellies'));
        await Future<void>.delayed(_settle);

        expect(repo.calls, isEmpty);
        expect((await profile('maya'))!.coins, 120);
        await sub.cancel();
        await bloc.close();
      },
    );

    test(
      'picking a child after an empty nest fills it with NO reload event',
      () async {
        await setActiveChild(null);
        final repo = _SpyRepository(db: db);
        final bloc = PipBloc(repository: repo);
        final states = <PipState>[];
        final sub = bloc.stream.listen(states.add);

        bloc.add(const PipLoadRequested());
        await Future<void>.delayed(_settle);
        expect(bloc.state.nest, isNull);
        // "A load was armed" = both arrival flags still down (a fresh load).
        // The streams now answer one after the other, so the aggregate status
        // passes through `loading` twice — the flags are the honest count of
        // load events.
        final loads = states
            .where((s) => !s.nestSettled && !s.evolutionSettled)
            .length;
        expect(loads, 1);

        // The one live subscription follows the switch: the view updates
        // without re-adding a load event (RULES §4).
        await setActiveChild('maya');
        await Future<void>.delayed(_settle);

        expect(bloc.state.status, PipStatus.loaded);
        expect(bloc.state.nest?.profile.childId, 'maya');
        expect(
          states.where((s) => !s.nestSettled && !s.evolutionSettled).length,
          loads,
        );
        await sub.cancel();
        await bloc.close();
      },
    );
  });

  group('subscription lifecycle', () {
    test('close() releases the nest subscription', () async {
      final repo = _SpyRepository(db: db);
      final bloc = PipBloc(repository: repo);
      final states = <PipState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(const PipLoadRequested());
      await Future<void>.delayed(_settle);
      expect(bloc.state.status, PipStatus.loaded);

      await bloc.close();
      await sub.cancel();
      final before = states.length;

      // A write the live subscription would have forwarded: nothing must
      // arrive (and nothing must throw) after close.
      await setCoins('maya', 7);
      await Future<void>.delayed(_settle);

      expect(states.length, before);
      expect((await profile('maya'))!.coins, 7, reason: 'the write happened');
    });

    test('PipNestReceived(null) alone loads the no-child card', () async {
      final bloc = PipBloc(repository: _SpyRepository(db: db));
      final sub = bloc.stream.listen((_) {});
      bloc.add(const PipNestReceived(null));
      await Future<void>.delayed(_settle);

      // Only the NEST stream answered here (no evolution event at all), so the
      // nest's OWN status is `loaded` — which is what `/pip` renders the
      // no-child card from — while the feature status stays `loading` because
      // K07's stream is still in flight.
      expect(bloc.state.nestStatus, PipStatus.loaded);
      expect(bloc.state.evolutionStatus, PipStatus.loading);
      expect(bloc.state.nest, isNull);
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.items, isEmpty);
      await sub.cancel();
      await bloc.close();
    });

    blocTest<PipBloc, PipState>(
      'PipNestFailed alone reports the load failure',
      build: () => PipBloc(repository: _SpyRepository(db: db)),
      act: (bloc) => bloc.add(PipNestFailed(Exception('nest down'))),
      wait: const Duration(milliseconds: 40),
      expect: () => <Matcher>[
        predicate<PipState>(
          (s) =>
              s.status == PipStatus.failure &&
              s.errorMessage != null &&
              s.errorMessage!.contains('nest down'),
        ),
      ],
    );
  });

  test('repeated plays clamp happiness at 5 and never cost coins', () async {
    final repo = _SpyRepository(db: db);
    final bloc = await loaded(repo);
    final sub = bloc.stream.listen((_) {});

    for (var i = 0; i < 3; i++) {
      bloc.add(const PipCareRequested(PipCareKind.play));
      await Future<void>.delayed(_settle);
    }

    final maya = await profile('maya');
    expect(maya!.happiness, 5);
    expect(maya.coins, 120);
    expect(repo.calls, <String>['play:maya', 'play:maya', 'play:maya']);
    await sub.cancel();
    await bloc.close();
  });

  test('care stops at zero coins and reports nothing', () async {
    await setCoins('maya', 0);
    final repo = _SpyRepository(db: db);
    final bloc = await loaded(repo);
    final sub = bloc.stream.listen((_) {});

    _tap(bloc, const PipCareRequested(PipCareKind.feed));
    _tap(bloc, const PipCareRequested(PipCareKind.bathe));
    _tap(bloc, const PipCareRequested(PipCareKind.play));
    await Future<void>.delayed(_settle);

    final maya = await profile('maya');
    expect(maya!.coins, 0, reason: 'never negative');
    expect(maya.happiness, 5, reason: 'Play is free and still counts');
    expect(bloc.state.actionError, isNull);
    await sub.cancel();
    await bloc.close();
  });

  test('PipNest entity: growth clamps to 0…1 and names every stage', () {
    const base = PipNest(
      profile: PipProfile(
        childId: 'maya',
        nickname: 'Maya',
        style: 'mochi',
        skin: 'sunny',
        accessory: 'none',
        stage: 3,
        totalCoins: 175,
        coins: 120,
        happiness: 4,
      ),
    );
    expect(base.growthFraction, closeTo(0.7, 0.0001));
    expect(base.items, isEmpty);

    const over = PipNest(
      profile: PipProfile(
        childId: 'maya',
        nickname: 'Maya',
        style: 'mochi',
        skin: 'sunny',
        accessory: 'none',
        stage: 4,
        totalCoins: 900,
        coins: 120,
        happiness: 4,
      ),
    );
    expect(over.growthFraction, 1.0, reason: 'a grown Pip never overflows');

    const under = PipNest(
      profile: PipProfile(
        childId: 'nina',
        nickname: 'Nina',
        style: 'mochi',
        skin: 'sunny',
        accessory: 'none',
        stage: 1,
        totalCoins: 0,
        coins: 0,
        happiness: 0,
      ),
    );
    expect(under.growthFraction, 0.0);
    expect(under, isNot(base));
  });
}
