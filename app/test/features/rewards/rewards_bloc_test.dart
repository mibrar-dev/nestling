// P14 Rewards manager — bloc state machine for the parent reward shop.
//
// The bloc serves /rewards from one stream: `watchItems` (creation order,
// oldest first — ORCHESTRATOR_NOTES 12:27). Every P14 tap is write-through —
// the stream re-emits and the state follows. Write failures never touch the
// state: they complete the event's `result` channel (review finding 1), so a
// failed write cannot replace the loaded list.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart';
import 'package:nestling/features/rewards/domain/entities/reward_redemption.dart';
import 'package:nestling/features/rewards/domain/rewards_repository.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_bloc.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_event.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_state.dart';

import '../../test_scope.dart';

/// `Seed.demo`'s six rewards in CREATION order (the P14 list order): the seed
/// stamps each row one second after the previous. Titles/prices/`needsOk` are
/// the spec. "Baking together" is `needsOk: false` (the design shows its
/// toggle OFF); every other row is ON.
const List<String> _demoIds = <String>[
  'r-screen',
  'r-film',
  'r-bedtime',
  'r-baking',
  'r-cafe',
  'r-dinner',
];

const Map<String, String> _demoTitles = <String, String>{
  'r-screen': '30 min extra screen time',
  'r-film': 'Pick Friday film',
  'r-bedtime': 'Stay up 15 min later',
  'r-baking': 'Baking together',
  'r-cafe': 'Trip to the park café',
  'r-dinner': 'Choose dinner',
};

const Map<String, int> _demoPrices = <String, int>{
  'r-screen': 50,
  'r-film': 80,
  'r-bedtime': 60,
  'r-baking': 100,
  'r-cafe': 150,
  'r-dinner': 90,
};

const Map<String, bool> _demoNeedsOk = <String, bool>{
  'r-screen': true,
  'r-film': true,
  'r-bedtime': true,
  'r-baking': false,
  'r-cafe': true,
  'r-dinner': true,
};

/// Fails every write and the first `watchItems` subscription, so the bloc's
/// failure and retry paths are reachable without a broken database.
class _FailingRewardsRepository implements RewardsRepository {
  int watches = 0;

  @override
  Future<List<Reward>> getItems() => watchItems().first;

  @override
  Stream<List<Reward>> watchItems() {
    watches++;
    if (watches == 1) {
      return Stream<List<Reward>>.error(Exception('stream is down'));
    }
    return Stream<List<Reward>>.value(const <Reward>[]);
  }

  @override
  Stream<List<RewardRedemption>> watchRequests() =>
      Stream<List<RewardRedemption>>.value(const <RewardRedemption>[]);

  @override
  Future<void> createReward(Reward reward) async {
    throw Exception('disk is full');
  }

  @override
  Future<void> updateReward(Reward reward) async {
    throw Exception('disk is full');
  }

  @override
  Future<void> deleteReward(String id) async {
    throw Exception('disk is full');
  }

  @override
  Future<void> setNeedsOk({required String id, required bool needsOk}) async {
    throw Exception('disk is full');
  }

  @override
  Future<void> approveRedemption(int redemptionId) async {
    throw Exception('disk is full');
  }

  @override
  Future<void> denyRedemption(int redemptionId) async {
    throw Exception('disk is full');
  }
}

void main() {
  group('RewardsState', () {
    test('starts initial with no items and no error', () {
      const state = RewardsState();
      expect(state.status, RewardsStatus.initial);
      expect(state.items, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('copyWith replaces only the given fields', () {
      const loaded = RewardsState(
        status: RewardsStatus.loaded,
        items: <Reward>[
          Reward(
            id: 'r-screen',
            title: '30 min extra screen time',
            detail: '50 coins',
            icon: 'tv',
            coinPrice: 50,
            needsOk: true,
          ),
        ],
      );
      expect(
        loaded.copyWith(status: RewardsStatus.loading).items,
        loaded.items,
      );
      expect(
        loaded
            .copyWith(status: RewardsStatus.failure, errorMessage: 'offline')
            .errorMessage,
        'offline',
      );
    });
  });

  group('RewardsEvent', () {
    test('carries its fields in props', () {
      expect(
        const RewardsNeedsOkChanged(id: 'r-screen', needsOk: false).props,
        <Object?>['r-screen', false],
      );
      expect(
        const RewardsCreateRequested(
          title: 'Museum trip',
          coinPrice: 70,
          needsOk: true,
          icon: 'gift',
        ).props,
        <Object?>['Museum trip', 70, true, 'gift'],
      );
      expect(const RewardsDeleteRequested(id: 'r-cafe').props, <Object?>[
        'r-cafe',
      ]);
    });

    test('result is a channel outside props', () {
      final event = RewardsDeleteRequested(
        id: 'r-cafe',
        result: Completer<void>(),
      );
      expect(event.props, <Object?>['r-cafe']);
      expect(event.result, isA<Completer<void>>());
      expect(
        const RewardsDeleteRequested(id: 'r-cafe'),
        const RewardsDeleteRequested(id: 'r-cafe'),
        reason: 'equality is value-only, with or without a channel',
      );
    });
  });

  group('RewardsBloc — P14 load', () {
    blocTest<RewardsBloc, RewardsState>(
      'load emits loading then the 6 demo rows in creation order',
      setUp: setUpTestScope,
      build: () => RewardsBloc(repository: GetIt.instance<RewardsRepository>()),
      act: (bloc) => bloc.add(const RewardsLoadRequested()),
      expect: () => <Matcher>[
        isA<RewardsState>().having(
          (state) => state.status,
          'status',
          RewardsStatus.loading,
        ),
        // Creation order, not price: r-film (80) before r-bedtime (60),
        // r-dinner (90) last (ORCHESTRATOR_NOTES 12:27, P14-B05).
        isA<RewardsState>()
            .having((state) => state.status, 'status', RewardsStatus.loaded)
            .having(
              (state) => state.items.map((item) => item.id).toList(),
              'ids',
              _demoIds,
            )
            .having(
              (state) => <String, String>{
                for (final item in state.items) item.id: item.title,
              },
              'titles',
              _demoTitles,
            )
            .having(
              (state) => <String, int>{
                for (final item in state.items) item.id: item.coinPrice,
              },
              'prices',
              _demoPrices,
            )
            .having(
              (state) => <String, bool>{
                for (final item in state.items) item.id: item.needsOk,
              },
              'needsOk',
              _demoNeedsOk,
            ),
      ],
      verify: (bloc) async {
        // The state order is the database order verbatim.
        final repository = GetIt.instance<RewardsRepository>();
        final databaseOrder = (await repository.watchItems().first)
            .map((item) => item.id)
            .toList();
        final stateOrder = bloc.state.items.map((item) => item.id).toList();
        expect(stateOrder, databaseOrder);
      },
    );
  });

  group('RewardsBloc — P14 writes round-trip through the database', () {
    blocTest<RewardsBloc, RewardsState>(
      'toggle flips needsOk in the DB and the stream re-emits',
      setUp: setUpTestScope,
      build: () => RewardsBloc(repository: GetIt.instance<RewardsRepository>()),
      act: (bloc) async {
        bloc.add(const RewardsLoadRequested());
        await bloc.stream.firstWhere(
          (state) => state.status == RewardsStatus.loaded,
        );
        bloc.add(const RewardsNeedsOkChanged(id: 'r-screen', needsOk: false));
      },
      expect: () => <Matcher>[
        isA<RewardsState>().having(
          (state) => state.status,
          'status',
          RewardsStatus.loading,
        ),
        isA<RewardsState>()
            .having((state) => state.status, 'status', RewardsStatus.loaded)
            .having(
              (state) => state.items
                  .firstWhere((item) => item.id == 'r-screen')
                  .needsOk,
              'screen before',
              isTrue,
            ),
        isA<RewardsState>()
            .having((state) => state.status, 'status', RewardsStatus.loaded)
            .having(
              (state) => state.items
                  .firstWhere((item) => item.id == 'r-screen')
                  .needsOk,
              'screen after',
              isFalse,
            ),
      ],
      verify: (_) async {
        final repository = GetIt.instance<RewardsRepository>();
        final items = await repository.watchItems().first;
        expect(
          items.firstWhere((item) => item.id == 'r-screen').needsOk,
          isFalse,
        );
        // Every other row keeps its seeded value (baking stays OFF).
        expect(
          <String, bool>{
            for (final item in items.where((item) => item.id != 'r-screen'))
              item.id: item.needsOk,
          },
          <String, bool>{
            for (final id in _demoIds.where((id) => id != 'r-screen'))
              id: _demoNeedsOk[id]!,
          },
        );
      },
    );

    blocTest<RewardsBloc, RewardsState>(
      'a successful write completes its result channel',
      setUp: setUpTestScope,
      build: () => RewardsBloc(repository: GetIt.instance<RewardsRepository>()),
      act: (bloc) async {
        bloc.add(const RewardsLoadRequested());
        await bloc.stream.firstWhere(
          (state) => state.status == RewardsStatus.loaded,
        );
        final result = Completer<void>();
        final completed = expectLater(result.future, completes);
        bloc.add(
          RewardsCreateRequested(
            title: 'Museum trip',
            coinPrice: 70,
            needsOk: true,
            icon: 'gift',
            result: result,
          ),
        );
        await completed;
      },
      expect: () => <Matcher>[
        isA<RewardsState>().having(
          (state) => state.status,
          'status',
          RewardsStatus.loading,
        ),
        isA<RewardsState>()
            .having((state) => state.status, 'status', RewardsStatus.loaded)
            .having((state) => state.items.length, 'length', 6),
        isA<RewardsState>()
            .having((state) => state.status, 'status', RewardsStatus.loaded)
            .having((state) => state.items.length, 'length', 7),
      ],
      verify: (_) async {
        final repository = GetIt.instance<RewardsRepository>();
        final items = await repository.watchItems().first;
        final created = items.firstWhere((item) => item.title == 'Museum trip');
        expect(created.coinPrice, 70);
        expect(created.id, startsWith('reward-'));
        // Creation order: a row added now sorts last.
        expect(items.last.title, 'Museum trip');
      },
    );

    blocTest<RewardsBloc, RewardsState>(
      'update rewrites the row and keeps its creation slot',
      setUp: setUpTestScope,
      build: () => RewardsBloc(repository: GetIt.instance<RewardsRepository>()),
      act: (bloc) async {
        bloc.add(const RewardsLoadRequested());
        final loaded = await bloc.stream.firstWhere(
          (state) => state.status == RewardsStatus.loaded,
        );
        final screen = loaded.items.firstWhere((item) => item.id == 'r-screen');
        bloc.add(
          RewardsUpdateRequested(
            reward: Reward(
              id: screen.id,
              title: '45 min extra screen time',
              detail: screen.detail,
              icon: screen.icon,
              coinPrice: 200,
              needsOk: false,
            ),
          ),
        );
      },
      expect: () => <Matcher>[
        isA<RewardsState>().having(
          (state) => state.status,
          'status',
          RewardsStatus.loading,
        ),
        isA<RewardsState>().having(
          (state) => state.status,
          'status',
          RewardsStatus.loaded,
        ),
        isA<RewardsState>()
            .having((state) => state.status, 'status', RewardsStatus.loaded)
            .having((state) => state.items.first.id, 'first id', 'r-screen')
            .having(
              (state) => state.items.first.title,
              'first title',
              '45 min extra screen time',
            )
            .having(
              (state) => state.items.first.needsOk,
              'first needsOk',
              isFalse,
            ),
      ],
      verify: (_) async {
        final repository = GetIt.instance<RewardsRepository>();
        final items = await repository.watchItems().first;
        expect(items.length, 6);
        expect(items.first.id, 'r-screen');
        expect(items.first.coinPrice, 200);
      },
    );

    blocTest<RewardsBloc, RewardsState>(
      'delete removes the row',
      setUp: setUpTestScope,
      build: () => RewardsBloc(repository: GetIt.instance<RewardsRepository>()),
      act: (bloc) async {
        bloc.add(const RewardsLoadRequested());
        await bloc.stream.firstWhere(
          (state) => state.status == RewardsStatus.loaded,
        );
        bloc.add(const RewardsDeleteRequested(id: 'r-cafe'));
      },
      expect: () => <Matcher>[
        isA<RewardsState>().having(
          (state) => state.status,
          'status',
          RewardsStatus.loading,
        ),
        isA<RewardsState>()
            .having((state) => state.status, 'status', RewardsStatus.loaded)
            .having((state) => state.items.length, 'length', 6),
        isA<RewardsState>()
            .having((state) => state.status, 'status', RewardsStatus.loaded)
            .having((state) => state.items.length, 'length', 5)
            .having(
              (state) => state.items.map((item) => item.id).toSet(),
              'ids without r-cafe',
              <String>{..._demoIds}..remove('r-cafe'),
            ),
      ],
      verify: (_) async {
        final repository = GetIt.instance<RewardsRepository>();
        final items = await repository.watchItems().first;
        expect(items.any((item) => item.id == 'r-cafe'), isFalse);
      },
    );
  });

  group('RewardsBloc — write failures complete the result, never the state', () {
    blocTest<RewardsBloc, RewardsState>(
      'a throwing toggle completes its result with the error, emitting nothing',
      build: () => RewardsBloc(repository: _FailingRewardsRepository()),
      act: (bloc) async {
        final result = Completer<void>();
        final failed = expectLater(
          result.future,
          throwsA(
            isA<Exception>().having(
              (e) => '$e',
              'text',
              contains('disk is full'),
            ),
          ),
        );
        bloc.add(
          RewardsNeedsOkChanged(id: 'r-screen', needsOk: false, result: result),
        );
        await failed;
      },
      expect: () => <Matcher>[],
    );

    blocTest<RewardsBloc, RewardsState>(
      'a throwing create completes its result with the error, emitting nothing',
      build: () => RewardsBloc(repository: _FailingRewardsRepository()),
      act: (bloc) async {
        final result = Completer<void>();
        final failed = expectLater(
          result.future,
          throwsA(
            isA<Exception>().having(
              (e) => '$e',
              'text',
              contains('disk is full'),
            ),
          ),
        );
        bloc.add(
          RewardsCreateRequested(
            title: 'Museum trip',
            coinPrice: 70,
            needsOk: true,
            icon: 'gift',
            result: result,
          ),
        );
        await failed;
      },
      expect: () => <Matcher>[],
    );

    blocTest<RewardsBloc, RewardsState>(
      'a throwing update completes its result with the error, emitting nothing',
      build: () => RewardsBloc(repository: _FailingRewardsRepository()),
      act: (bloc) async {
        final result = Completer<void>();
        final failed = expectLater(
          result.future,
          throwsA(
            isA<Exception>().having(
              (e) => '$e',
              'text',
              contains('disk is full'),
            ),
          ),
        );
        bloc.add(
          RewardsUpdateRequested(
            reward: const Reward(
              id: 'r-screen',
              title: 'Screen time',
              detail: '50 coins',
              icon: 'tv',
              coinPrice: 50,
              needsOk: true,
            ),
            result: result,
          ),
        );
        await failed;
      },
      expect: () => <Matcher>[],
    );

    blocTest<RewardsBloc, RewardsState>(
      'a throwing delete completes its result with the error, emitting nothing',
      build: () => RewardsBloc(repository: _FailingRewardsRepository()),
      act: (bloc) async {
        final result = Completer<void>();
        final failed = expectLater(
          result.future,
          throwsA(
            isA<Exception>().having(
              (e) => '$e',
              'text',
              contains('disk is full'),
            ),
          ),
        );
        bloc.add(RewardsDeleteRequested(id: 'r-cafe', result: result));
        await failed;
      },
      expect: () => <Matcher>[],
    );

    blocTest<RewardsBloc, RewardsState>(
      'a failed write without a result still emits nothing: the list stays',
      build: () => RewardsBloc(repository: _FailingRewardsRepository()),
      act: (bloc) async {
        bloc.add(const RewardsLoadRequested());
        await bloc.stream.firstWhere(
          (state) => state.status == RewardsStatus.failure,
        );
        bloc.add(const RewardsLoadRequested());
        await bloc.stream.firstWhere(
          (state) => state.status == RewardsStatus.loaded,
        );
        // Fire-and-forget with no result channel: the write throws, but with
        // nobody listening the bloc must not replace the loaded list — the
        // only observable outcome is silence.
        bloc.add(const RewardsNeedsOkChanged(id: 'r-screen', needsOk: false));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      expect: () => <Matcher>[
        isA<RewardsState>().having(
          (state) => state.status,
          'status',
          RewardsStatus.loading,
        ),
        isA<RewardsState>()
            .having((state) => state.status, 'status', RewardsStatus.failure)
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              contains('stream is down'),
            ),
        isA<RewardsState>().having(
          (state) => state.status,
          'status',
          RewardsStatus.loading,
        ),
        isA<RewardsState>()
            .having((state) => state.status, 'status', RewardsStatus.loaded)
            .having((state) => state.items, 'items', isEmpty),
      ],
    );

    blocTest<RewardsBloc, RewardsState>(
      'a stream error reaches failure, and retry resubscribes to recovery',
      build: () => RewardsBloc(repository: _FailingRewardsRepository()),
      act: (bloc) async {
        bloc.add(const RewardsLoadRequested());
        await bloc.stream.firstWhere(
          (state) => state.status == RewardsStatus.failure,
        );
        bloc.add(const RewardsLoadRequested());
      },
      expect: () => <Matcher>[
        isA<RewardsState>().having(
          (state) => state.status,
          'status',
          RewardsStatus.loading,
        ),
        isA<RewardsState>()
            .having((state) => state.status, 'status', RewardsStatus.failure)
            .having((state) => state.items, 'items', isEmpty)
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              contains('stream is down'),
            ),
        // Retry: loading again, then the (empty) recovered list.
        isA<RewardsState>().having(
          (state) => state.status,
          'status',
          RewardsStatus.loading,
        ),
        isA<RewardsState>()
            .having((state) => state.status, 'status', RewardsStatus.loaded)
            .having((state) => state.items, 'items', isEmpty),
      ],
    );
  });
}
