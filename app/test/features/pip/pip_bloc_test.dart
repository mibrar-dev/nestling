// K06 bloc tests: every PipEvent path over the real Drift-backed
// repository (Seed.demo), plus failure paths over throwing fakes.
//
// The bloc resolves the active child from the last `watchNest` emission;
// care/wardrobe writes stream back in with no extra events, and failures
// surface on the `actionError`/`actionNonce` toast channel.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/pip/data/pip_repository_impl.dart';
import 'package:nestling/features/pip/domain/entities/pip_evolution.dart';
import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/entities/pip_profile.dart';
import 'package:nestling/features/pip/domain/pip_repository.dart';
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

/// Repository whose `feed` write throws (care actionError path); the nest
/// stream itself stays healthy so the load succeeds first.
class _FailingFeedRepository extends PipRepositoryImpl {
  _FailingFeedRepository({required super.db});

  @override
  Future<void> feed(String childId) => throw Exception('feed down');
}

/// Repository whose `buyItem` reports a fresh-balance refusal even though
/// the cached nest looks affordable (K06-BUG-7: the sibling tap spent the
/// coins first). Pins the bloc's result mapping deterministically; the
/// burst proof lives in `k06_bugs_test.dart`.
class _RefusingBuyRepository extends PipRepositoryImpl {
  _RefusingBuyRepository({required super.db});

  @override
  Future<PipBuyResult> buyItem(String childId, String item) =>
      Future.value(PipBuyResult.cannotAfford);
}

/// Repository whose nest stream errors on listen (load-failure path) until
/// released, so the failure card's "Try again" can be exercised.
class _FailingNestRepository extends _EvolutionSilentRepository {
  _FailingNestRepository({required super.db});

  bool failNest = true;

  @override
  Stream<PipNest?> watchNest() {
    if (failNest) return Stream<PipNest?>.error(Exception('nest down'));
    return super.watchNest();
  }
}

/// K06 nest-path repository: the K07 evolution stream stays silent (never
/// emits), so the exact load/care/wardrobe sequences below read exactly as
/// before. Evolution behaviour itself is covered in
/// `pip_evolution_bloc_test.dart` with controlled fakes.
///
/// A silent sibling means the feature-level `PipStatus` never reaches `loaded`
/// (`loaded` is the AND of both streams — 6_bugs.md K07-BUG-1), so every K06
/// assertion below reads `PipState.nestStatus`, the NEST stream's own status,
/// which is what `/pip` switches on.
class _EvolutionSilentRepository extends PipRepositoryImpl {
  _EvolutionSilentRepository({required super.db});

  final StreamController<PipEvolution?> _silent =
      StreamController<PipEvolution?>.broadcast();

  @override
  Stream<PipEvolution?> watchEvolution() => _silent.stream;
}

Matcher _loadedWithCoins(int coins) => predicate<PipState>(
  (state) =>
      state.nestStatus == PipStatus.loaded &&
      state.nest?.profile.coins == coins,
);

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    await Seed.demo(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('PipState', () {
    test('defaults are idle with no nest', () {
      const state = PipState();
      expect(state.status, PipStatus.initial);
      expect(state.nest, isNull);
      expect(state.items, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.actionError, isNull);
      expect(state.actionNonce, 0);
    });

    test('action failures are explicit and nonce-bumped', () {
      const base = PipState(status: PipStatus.loaded);
      final first = base.withActionFailed(Exception('save failed'));
      final second = first.withActionFailed(Exception('save failed'));
      expect(first.actionError, 'Exception: save failed');
      expect(first.actionNonce, 1);
      expect(second.actionNonce, 2);
      expect(first, isNot(second));

      final started = first.withActionStarted();
      expect(started.actionError, isNull);
      expect(started.actionNonce, 0);
    });

    test('copyWithLoaded carries a pending action outcome through', () {
      const nest = PipNest(profile: _mayaProfile);
      const failed = PipState(
        status: PipStatus.loaded,
        actionError: 'Exception: x',
        actionNonce: 2,
        nestSettled: true,
        evolutionSettled: true,
      );
      final reloaded = failed.copyWithLoaded(nest);
      expect(reloaded.status, PipStatus.loaded);
      expect(reloaded.nest?.profile.childId, 'maya');
      // K06-BUG-7: a refusal announced during a burst must survive the
      // sibling write's refresh; it clears on the next attempt instead.
      expect(reloaded.actionError, 'Exception: x');
      expect(reloaded.actionNonce, 2);
    });

    test('care and wardrobe events carry every field', () {
      const feed = PipCareRequested(PipCareKind.feed);
      expect(feed, const PipCareRequested(PipCareKind.feed));
      expect(feed, isNot(const PipCareRequested(PipCareKind.bathe)));
      const buy = PipWardrobeBuyRequested('wellies');
      expect(buy, const PipWardrobeBuyRequested('wellies'));
      expect(buy, isNot(const PipWardrobeBuyRequested('crown')));
      const equip = PipWardrobeEquipRequested('scarf');
      expect(equip, const PipWardrobeEquipRequested('scarf'));
      expect(equip, isNot(const PipWardrobeEquipRequested('sunhat')));
    });
  });

  group('PipBloc load', () {
    blocTest<PipBloc, PipState>(
      'load emits loading then loaded with Maya nest in design order',
      build: () => PipBloc(repository: _EvolutionSilentRepository(db: db)),
      act: (bloc) => bloc.add(const PipLoadRequested()),
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        predicate<PipState>((s) => s.status == PipStatus.loading),
        predicate<PipState>((state) {
          final nest = state.nest;
          if (state.nestStatus != PipStatus.loaded || nest == null) {
            return false;
          }
          if (nest.profile.nickname != 'Maya') return false;
          if (nest.profile.coins != 120) return false;
          return nest.items.map((i) => i.id).join(',') ==
              'scarf,sunhat,wellies,crown';
        }),
      ],
    );

    blocTest<PipBloc, PipState>(
      'a second load while live is ignored (no stacked subscription)',
      build: () => PipBloc(repository: _EvolutionSilentRepository(db: db)),
      act: (bloc) async {
        bloc
          ..add(const PipLoadRequested())
          ..add(const PipLoadRequested())
          ..add(const PipLoadRequested());
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        predicate<PipState>((s) => s.status == PipStatus.loading),
        predicate<PipState>((s) => s.nestStatus == PipStatus.loaded),
      ],
    );

    blocTest<PipBloc, PipState>(
      'load failure emits failure with errorMessage',
      build: () => PipBloc(repository: _FailingNestRepository(db: db)),
      act: (bloc) => bloc.add(const PipLoadRequested()),
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        predicate<PipState>((s) => s.status == PipStatus.loading),
        predicate<PipState>(
          (s) =>
              s.status == PipStatus.failure &&
              s.errorMessage != null &&
              s.errorMessage!.contains('nest down'),
        ),
      ],
    );

    test('retry after a stream failure really reloads', () async {
      final repo = _FailingNestRepository(db: db);
      final bloc = PipBloc(repository: repo);
      final sub = bloc.stream.listen((_) {});
      bloc.add(const PipLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(bloc.state.status, PipStatus.failure);

      repo.failNest = false;
      bloc.add(const PipLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(
        bloc.state.nestStatus,
        PipStatus.loaded,
        reason: 'the nest stream answered again',
      );
      expect(bloc.state.nest?.profile.nickname, 'Maya');
      // The failed subscription was released: only one live handler, and
      // the healthy stream clears the stale load error.
      expect(bloc.state.errorMessage, isNull);
      await sub.cancel();
      await bloc.close();
    });
  });

  group('PipBloc care', () {
    blocTest<PipBloc, PipState>(
      'feed deducts 5 coins and the stream emits the new profile',
      build: () => PipBloc(repository: _EvolutionSilentRepository(db: db)),
      act: (bloc) async {
        bloc.add(const PipLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const PipCareRequested(PipCareKind.feed));
      },
      wait: const Duration(milliseconds: 150),
      expect: () => <Matcher>[
        predicate<PipState>((s) => s.status == PipStatus.loading),
        _loadedWithCoins(120),
        _loadedWithCoins(115),
      ],
      verify: (bloc) => expect(bloc.state.nest?.profile.happiness, 5),
    );

    blocTest<PipBloc, PipState>(
      'bathe deducts 3 coins',
      build: () => PipBloc(repository: _EvolutionSilentRepository(db: db)),
      act: (bloc) async {
        bloc.add(const PipLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const PipCareRequested(PipCareKind.bathe));
      },
      wait: const Duration(milliseconds: 150),
      expect: () => <Matcher>[
        predicate<PipState>((s) => s.status == PipStatus.loading),
        _loadedWithCoins(120),
        _loadedWithCoins(117),
      ],
    );

    blocTest<PipBloc, PipState>(
      'play is free',
      build: () => PipBloc(repository: PipRepositoryImpl(db: db)),
      act: (bloc) async {
        bloc.add(const PipLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const PipCareRequested(PipCareKind.play));
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) async {
        final profile = await PipRepositoryImpl(db: db)
            .watchProfile('maya')
            .first;
        expect(profile?.coins, 120);
        expect(profile?.happiness, 5);
      },
    );

    blocTest<PipBloc, PipState>(
      'care before a load is ignored (no active child cached)',
      build: () => PipBloc(repository: PipRepositoryImpl(db: db)),
      act: (bloc) => bloc.add(const PipCareRequested(PipCareKind.feed)),
      wait: const Duration(milliseconds: 50),
      expect: () => const <Matcher>[],
      verify: (_) async {
        final profile = await PipRepositoryImpl(db: db)
            .watchProfile('maya')
            .first;
        expect(profile?.coins, 120);
      },
    );

    blocTest<PipBloc, PipState>(
      'a thrown care write keeps the nest and records actionError',
      build: () => PipBloc(repository: _FailingFeedRepository(db: db)),
      act: (bloc) async {
        bloc.add(const PipLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const PipCareRequested(PipCareKind.feed));
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) {
        expect(bloc.state.status, PipStatus.loaded);
        expect(bloc.state.nest?.profile.coins, 120);
        expect(bloc.state.actionError, contains('feed down'));
        expect(bloc.state.actionNonce, 1);
        expect(bloc.state.errorMessage, isNull);
      },
    );
  });

  group('PipBloc wardrobe', () {
    blocTest<PipBloc, PipState>(
      'affordable buy marks owned and deducts the DB price',
      build: () => PipBloc(repository: _EvolutionSilentRepository(db: db)),
      act: (bloc) async {
        bloc.add(const PipLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const PipWardrobeBuyRequested('wellies'));
      },
      wait: const Duration(milliseconds: 150),
      expect: () => <Matcher>[
        predicate<PipState>((s) => s.status == PipStatus.loading),
        _loadedWithCoins(120),
        // The buy writes coins first, then the owned flag: the combined
        // stream emits once per write, so both land as loaded states.
        predicate<PipState>(
          (s) =>
              s.nestStatus == PipStatus.loaded &&
              s.nest?.profile.coins == 90 &&
              !s.nest!.items.firstWhere((i) => i.id == 'wellies').owned,
        ),
        predicate<PipState>(
          (s) =>
              s.nestStatus == PipStatus.loaded &&
              s.nest?.profile.coins == 90 &&
              s.nest!.items.firstWhere((i) => i.id == 'wellies').owned,
        ),
      ],
    );

    blocTest<PipBloc, PipState>(
      'unaffordable buy toasts the kind copy and writes nothing',
      build: () => PipBloc(repository: PipRepositoryImpl(db: db)),
      act: (bloc) async {
        await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
          const ChildrenCompanion(coins: Value(10)),
        );
        bloc.add(const PipLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const PipWardrobeBuyRequested('wellies'));
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) async {
        expect(bloc.state.status, PipStatus.loaded);
        expect(bloc.state.actionError, kPipNotEnoughCoins);
        expect(bloc.state.actionNonce, 1);
        final nest = await PipRepositoryImpl(db: db).watchNest().first;
        expect(nest?.profile.coins, 10);
        expect(nest!.items.firstWhere((i) => i.id == 'wellies').owned, isFalse);
      },
    );

    blocTest<PipBloc, PipState>(
      'a fresh-balance refusal toasts the kind copy (K06-BUG-7)',
      build: () => PipBloc(repository: _RefusingBuyRepository(db: db)),
      act: (bloc) async {
        bloc.add(const PipLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        // The cached nest shows 120 coins, so the pre-check passes; the
        // repository reports the sibling tap spent them first.
        bloc.add(const PipWardrobeBuyRequested('crown'));
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) async {
        expect(bloc.state.status, PipStatus.loaded);
        expect(bloc.state.actionError, kPipNotEnoughCoins);
        expect(bloc.state.actionNonce, 1);
        final nest = await PipRepositoryImpl(db: db).watchNest().first;
        expect(nest?.profile.coins, 120);
        expect(nest!.items.firstWhere((i) => i.id == 'crown').owned, isFalse);
      },
    );

    blocTest<PipBloc, PipState>(
      'equipping the scarf writes the scarf accessory',
      build: () => PipBloc(repository: PipRepositoryImpl(db: db)),
      act: (bloc) async {
        bloc.add(const PipLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const PipWardrobeEquipRequested('scarf'));
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) async {
        final profile = await PipRepositoryImpl(db: db)
            .watchProfile('maya')
            .first;
        expect(profile?.accessory, 'scarf');
        expect(bloc.state.actionError, isNull);
      },
    );

    blocTest<PipBloc, PipState>(
      'equipping the sun hat writes the cap accessory',
      build: () => PipBloc(repository: PipRepositoryImpl(db: db)),
      act: (bloc) async {
        bloc.add(const PipLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const PipWardrobeEquipRequested('sunhat'));
      },
      wait: const Duration(milliseconds: 150),
      verify: (_) async {
        final profile = await PipRepositoryImpl(db: db)
            .watchProfile('maya')
            .first;
        expect(profile?.accessory, 'cap');
      },
    );

    blocTest<PipBloc, PipState>(
      'equipping wellies or crown changes nothing (no accessory node)',
      build: () => PipBloc(repository: PipRepositoryImpl(db: db)),
      act: (bloc) async {
        bloc.add(const PipLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const PipWardrobeEquipRequested('crown'));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const PipWardrobeEquipRequested('wellies'));
      },
      wait: const Duration(milliseconds: 150),
      verify: (_) async {
        final profile = await PipRepositoryImpl(db: db)
            .watchProfile('maya')
            .first;
        expect(profile?.accessory, 'none');
        expect(profile?.coins, 120);
      },
    );
  });
}
