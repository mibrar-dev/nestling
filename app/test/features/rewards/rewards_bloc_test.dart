// P14 Rewards manager — bloc state machine for the parent reward shop.
//
// The bloc serves /rewards from one stream: `watchItems` (price order).
// Every P14 tap is write-through — the stream re-emits and the state follows.

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

/// The `Seed.demo` shop in `watchItems` order (coinPrice ASC): 50/60/80/90/
/// 100/150. All `needsOk` are true — the seed relies on the column default.
const List<String> _demoIds = <String>[
  'r-screen',
  'r-bedtime',
  'r-film',
  'r-dinner',
  'r-baking',
  'r-cafe',
];

const List<String> _demoTitles = <String>[
  '30 min extra screen time',
  'Stay up 15 min later',
  'Pick Friday film',
  'Choose dinner',
  'Baking together',
  'Trip to the park café',
];

const List<int> _demoPrices = <int>[50, 60, 80, 90, 100, 150];

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
        const RewardsNeedsOkChanged(id: 'r-baking', needsOk: false).props,
        <Object?>['r-baking', false],
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
  });

  group('RewardsBloc — P14 load', () {
    blocTest<RewardsBloc, RewardsState>(
      'load emits loading then the 6 demo rewards in price order, all ON',
      setUp: setUpTestScope,
      build: () => RewardsBloc(repository: GetIt.instance<RewardsRepository>()),
      act: (bloc) => bloc.add(const RewardsLoadRequested()),
      expect: () => <Matcher>[
        isA<RewardsState>().having(
          (state) => state.status,
          'status',
          RewardsStatus.loading,
        ),
        isA<RewardsState>()
            .having((state) => state.status, 'status', RewardsStatus.loaded)
            .having(
              (state) => state.items.map((item) => item.id).toList(),
              'ids',
              _demoIds,
            )
            .having(
              (state) => state.items.map((item) => item.title).toList(),
              'titles',
              _demoTitles,
            )
            .having(
              (state) => state.items.map((item) => item.coinPrice).toList(),
              'prices',
              _demoPrices,
            )
            .having(
              (state) => state.items.every((item) => item.needsOk),
              'all needsOk',
              isTrue,
            ),
      ],
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
        bloc.add(const RewardsNeedsOkChanged(id: 'r-baking', needsOk: false));
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
                  .firstWhere((item) => item.id == 'r-baking')
                  .needsOk,
              'baking before',
              isTrue,
            ),
        isA<RewardsState>()
            .having((state) => state.status, 'status', RewardsStatus.loaded)
            .having(
              (state) => state.items
                  .firstWhere((item) => item.id == 'r-baking')
                  .needsOk,
              'baking after',
              isFalse,
            ),
      ],
      verify: (_) async {
        final repository = GetIt.instance<RewardsRepository>();
        final items = await repository.watchItems().first;
        expect(
          items.firstWhere((item) => item.id == 'r-baking').needsOk,
          isFalse,
        );
        // The other five rows are untouched.
        expect(
          items
              .where((item) => item.id != 'r-baking')
              .every((item) => item.needsOk),
          isTrue,
        );
      },
    );

    blocTest<RewardsBloc, RewardsState>(
      'new reward appears in price order with its needsOk value',
      setUp: setUpTestScope,
      build: () => RewardsBloc(repository: GetIt.instance<RewardsRepository>()),
      act: (bloc) async {
        bloc.add(const RewardsLoadRequested());
        await bloc.stream.firstWhere(
          (state) => state.status == RewardsStatus.loaded,
        );
        bloc.add(
          const RewardsCreateRequested(
            title: 'Museum trip',
            coinPrice: 70,
            needsOk: false,
            icon: 'gift',
          ),
        );
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
            .having((state) => state.items.length, 'length', 7)
            .having(
              (state) => state.items.map((item) => item.coinPrice).toList(),
              'prices',
              <int>[50, 60, 70, 80, 90, 100, 150],
            ),
      ],
      verify: (_) async {
        final repository = GetIt.instance<RewardsRepository>();
        final items = await repository.watchItems().first;
        final created = items.firstWhere((item) => item.title == 'Museum trip');
        expect(created.coinPrice, 70);
        expect(created.needsOk, isFalse);
        expect(created.icon, 'gift');
        expect(created.id, startsWith('reward-'));
      },
    );

    blocTest<RewardsBloc, RewardsState>(
      'update rewrites the row and it moves with its new price',
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
            .having((state) => state.items.last.id, 'last id', 'r-screen')
            .having(
              (state) => state.items.last.title,
              'last title',
              '45 min extra screen time',
            )
            .having(
              (state) => state.items.last.needsOk,
              'last needsOk',
              isFalse,
            ),
      ],
      verify: (_) async {
        final repository = GetIt.instance<RewardsRepository>();
        final items = await repository.watchItems().first;
        expect(items.length, 6);
        expect(items.last.id, 'r-screen');
        expect(items.last.coinPrice, 200);
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
              (state) => state.items.map((item) => item.id).toList(),
              'ids',
              <String>[
                'r-screen',
                'r-bedtime',
                'r-film',
                'r-dinner',
                'r-baking',
              ],
            ),
      ],
      verify: (_) async {
        final repository = GetIt.instance<RewardsRepository>();
        final items = await repository.watchItems().first;
        expect(items.any((item) => item.id == 'r-cafe'), isFalse);
      },
    );
  });

  group('RewardsBloc — failure paths', () {
    blocTest<RewardsBloc, RewardsState>(
      'a throwing toggle write lands in failure with the error message',
      build: () => RewardsBloc(repository: _FailingRewardsRepository()),
      act: (bloc) =>
          bloc.add(const RewardsNeedsOkChanged(id: 'r-baking', needsOk: false)),
      expect: () => <Matcher>[
        isA<RewardsState>()
            .having((state) => state.status, 'status', RewardsStatus.failure)
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              contains('disk is full'),
            ),
      ],
    );

    blocTest<RewardsBloc, RewardsState>(
      'a throwing create lands in failure too',
      build: () => RewardsBloc(repository: _FailingRewardsRepository()),
      act: (bloc) => bloc.add(
        const RewardsCreateRequested(
          title: 'Museum trip',
          coinPrice: 70,
          needsOk: true,
          icon: 'gift',
        ),
      ),
      expect: () => <Matcher>[
        isA<RewardsState>()
            .having((state) => state.status, 'status', RewardsStatus.failure)
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              contains('disk is full'),
            ),
      ],
    );

    blocTest<RewardsBloc, RewardsState>(
      'a throwing update lands in failure too',
      build: () => RewardsBloc(repository: _FailingRewardsRepository()),
      act: (bloc) => bloc.add(
        const RewardsUpdateRequested(
          reward: Reward(
            id: 'r-screen',
            title: 'Screen time',
            detail: '50 coins',
            icon: 'tv',
            coinPrice: 50,
            needsOk: true,
          ),
        ),
      ),
      expect: () => <Matcher>[
        isA<RewardsState>()
            .having((state) => state.status, 'status', RewardsStatus.failure)
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              contains('disk is full'),
            ),
      ],
    );

    blocTest<RewardsBloc, RewardsState>(
      'a throwing delete lands in failure too',
      build: () => RewardsBloc(repository: _FailingRewardsRepository()),
      act: (bloc) => bloc.add(const RewardsDeleteRequested(id: 'r-cafe')),
      expect: () => <Matcher>[
        isA<RewardsState>()
            .having((state) => state.status, 'status', RewardsStatus.failure)
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              contains('disk is full'),
            ),
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
