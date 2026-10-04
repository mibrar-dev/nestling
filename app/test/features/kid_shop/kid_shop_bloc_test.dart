// K08 bloc tests: every KidShopEvent/state path over a controllable fake
// repository, plus value semantics for the state object.
//
// The fake hands out FRESH streams per call (like the Drift repo does), so
// retry-after-failure and live re-emission behave like production. It is a
// stream-based fake rather than the in-memory DB because bloc tests exercise
// error and silence paths the database cannot produce.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/features/kid_shop/domain/entities/kid_shop_data.dart';
import 'package:nestling/features/kid_shop/domain/entities/shop_reward.dart';
import 'package:nestling/features/kid_shop/domain/kid_shop_repository.dart';
import 'package:nestling/features/kid_shop/presentation/bloc/kid_shop_bloc.dart';
import 'package:nestling/features/kid_shop/presentation/bloc/kid_shop_event.dart';
import 'package:nestling/features/kid_shop/presentation/bloc/kid_shop_state.dart';

/// Seed.demo's six rewards in CREATION order (the K08 list order): the seed
/// stamps each row one second after the previous, so this is r-screen first
/// and r-dinner last — never price order. Titles/prices/`needsOk` are the
/// spec; at Maya's 120 coins only the 150-coin park café is unaffordable.
List<ShopReward> _demoItems() => const <ShopReward>[
  ShopReward(
    id: 'r-screen',
    title: '30 min extra screen time',
    detail: '50 coins',
    icon: 'tv',
    coinPrice: 50,
    needsOk: true,
    affordable: true,
  ),
  ShopReward(
    id: 'r-film',
    title: 'Pick Friday film',
    detail: '80 coins',
    icon: 'film',
    coinPrice: 80,
    needsOk: true,
    affordable: true,
  ),
  ShopReward(
    id: 'r-bedtime',
    title: 'Stay up 15 min later',
    detail: '60 coins',
    icon: 'moon',
    coinPrice: 60,
    needsOk: true,
    affordable: true,
  ),
  ShopReward(
    id: 'r-baking',
    title: 'Baking together',
    detail: '100 coins',
    icon: 'cake',
    coinPrice: 100,
    needsOk: false,
    affordable: true,
  ),
  ShopReward(
    id: 'r-cafe',
    title: 'Trip to the park café',
    detail: '150 coins',
    icon: 'coffee',
    coinPrice: 150,
    needsOk: true,
    affordable: false,
  ),
  ShopReward(
    id: 'r-dinner',
    title: 'Choose dinner',
    detail: '90 coins',
    icon: 'plate',
    coinPrice: 90,
    needsOk: true,
    affordable: true,
  ),
];

KidShopData _demoData() =>
    KidShopData(childId: 'maya', coins: 120, items: _demoItems());

KidShopState _loaded() => KidShopState(
  status: KidShopStatus.loaded,
  childId: 'maya',
  coins: 120,
  items: _demoItems(),
);

/// Controllable fake: fresh streams per call, a recorded request log, and
/// switches for stream/request failure. The first `watchActiveShop` call can
/// fail while later ones serve data, so the retry path is reachable.
class _FakeKidShopRepository implements KidShopRepository {
  _FakeKidShopRepository({required this.data});

  KidShopData data;
  final List<(String, String)> requests = <(String, String)>[];
  Exception? requestError;
  bool failFirstWatch = false;
  int watches = 0;

  @override
  Stream<KidShopData> watchActiveShop() {
    watches++;
    if (failFirstWatch && watches == 1) {
      return Stream<KidShopData>.error(Exception('stream is down'));
    }
    return Stream<KidShopData>.value(data);
  }

  @override
  Future<void> requestReward(String childId, String rewardId) async {
    if (requestError != null) throw requestError!;
    requests.add((childId, rewardId));
  }
}

void main() {
  late _FakeKidShopRepository sharedRepo;
  group('KidShopBloc load (K08)', () {
    blocTest<KidShopBloc, KidShopState>(
      'emits loading then loaded with Maya coins and creation order',
      build: () =>
          KidShopBloc(repository: _FakeKidShopRepository(data: _demoData())),
      act: (bloc) => bloc.add(const KidShopLoadRequested()),
      expect: () => <KidShopState>[
        const KidShopState(status: KidShopStatus.loading),
        _loaded(),
      ],
    );

    blocTest<KidShopBloc, KidShopState>(
      'the park cafe is the only unaffordable card at 120 coins',
      build: () =>
          KidShopBloc(repository: _FakeKidShopRepository(data: _demoData())),
      seed: _loaded,
      expect: () => const <KidShopState>[],
      verify: (bloc) {
        final flags = <String, bool>{
          for (final item in bloc.state.items) item.id: item.affordable,
        };
        expect(flags, <String, bool>{
          'r-screen': true,
          'r-film': true,
          'r-bedtime': true,
          'r-baking': true,
          'r-cafe': false,
          'r-dinner': true,
        });
        expect(bloc.state.items.map((item) => item.id).toList(), <String>[
          'r-screen',
          'r-film',
          'r-bedtime',
          'r-baking',
          'r-cafe',
          'r-dinner',
        ]);
      },
    );

    test(
      'a second load while live is ignored (no stacked subscription)',
      () async {
        final repo = _FakeKidShopRepository(data: _demoData());
        final bloc = KidShopBloc(repository: repo);
        addTearDown(bloc.close);
        bloc
          ..add(const KidShopLoadRequested())
          ..add(const KidShopLoadRequested());
        await expectLater(
          bloc.stream,
          emitsInOrder([
            const KidShopState(status: KidShopStatus.loading),
            predicate<KidShopState>(
              (state) =>
                  state.status == KidShopStatus.loaded && state.coins == 120,
            ),
          ]),
        );
        expect(repo.watches, 1);
      },
    );

    test('stream error emits failure and a retry reloads', () async {
      final repo = _FakeKidShopRepository(data: _demoData())
        ..failFirstWatch = true;
      final bloc = KidShopBloc(repository: repo);
      addTearDown(bloc.close);
      bloc.add(const KidShopLoadRequested());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          const KidShopState(status: KidShopStatus.loading),
          predicate<KidShopState>(
            (state) => state.status == KidShopStatus.failure,
          ),
        ]),
      );
      expect(repo.watches, 1);

      bloc.add(const KidShopLoadRequested());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          // The retry spinner carries the load error through (K03 precedent:
          // only a healthy emission clears it), so match on status only.
          predicate<KidShopState>(
            (state) => state.status == KidShopStatus.loading,
          ),
          predicate<KidShopState>(
            (state) =>
                state.status == KidShopStatus.loaded && state.coins == 120,
          ),
        ]),
      );
      expect(repo.watches, 2);
    });
  });

  group('KidShopBloc requests (K08)', () {
    blocTest<KidShopBloc, KidShopState>(
      'needsOk request spins then toasts the thumbs-up copy',
      build: () =>
          KidShopBloc(repository: _FakeKidShopRepository(data: _demoData())),
      seed: _loaded,
      act: (bloc) => bloc.add(const KidShopRewardRequested('r-screen')),
      expect: () {
        final loaded = _loaded();
        return <KidShopState>[
          loaded.copyWithRequestStarted('r-screen'),
          loaded.copyWithRequestFinished(
            'r-screen',
            'Mum will give it a thumbs-up soon.',
          ),
        ];
      },
      verify: (bloc) {
        expect(bloc.state.requestingIds, isEmpty);
        expect(bloc.state.notice, 'Mum will give it a thumbs-up soon.');
        expect(bloc.state.noticeSeq, 1);
      },
    );

    blocTest<KidShopBloc, KidShopState>(
      'instant request toasts the enjoy copy',
      build: () =>
          KidShopBloc(repository: _FakeKidShopRepository(data: _demoData())),
      seed: _loaded,
      act: (bloc) => bloc.add(const KidShopRewardRequested('r-baking')),
      expect: () {
        final loaded = _loaded();
        return <KidShopState>[
          loaded.copyWithRequestStarted('r-baking'),
          loaded.copyWithRequestFinished('r-baking', 'It’s yours — enjoy!'),
        ];
      },
    );

    blocTest<KidShopBloc, KidShopState>(
      'the request writes (maya, rewardId) to the repository',
      build: () {
        sharedRepo = _FakeKidShopRepository(data: _demoData());
        return KidShopBloc(repository: sharedRepo);
      },
      seed: _loaded,
      act: (bloc) => bloc.add(const KidShopRewardRequested('r-dinner')),
      verify: (bloc) {
        expect(sharedRepo.requests, <(String, String)>[('maya', 'r-dinner')]);
      },
    );

    blocTest<KidShopBloc, KidShopState>(
      'failed request clears the spinner and toasts the retry copy',
      build: () {
        final repo = _FakeKidShopRepository(data: _demoData())
          ..requestError = Exception('disk is full');
        return KidShopBloc(repository: repo);
      },
      seed: _loaded,
      act: (bloc) => bloc.add(const KidShopRewardRequested('r-screen')),
      expect: () {
        final loaded = _loaded();
        return <KidShopState>[
          loaded.copyWithRequestStarted('r-screen'),
          loaded.copyWithRequestFinished(
            'r-screen',
            'Hmm, that did not work. Try again.',
          ),
        ];
      },
    );

    blocTest<KidShopBloc, KidShopState>(
      'unaffordable request is ignored',
      build: () =>
          KidShopBloc(repository: _FakeKidShopRepository(data: _demoData())),
      seed: _loaded,
      act: (bloc) => bloc.add(const KidShopRewardRequested('r-cafe')),
      expect: () => const <KidShopState>[],
    );

    blocTest<KidShopBloc, KidShopState>(
      'unknown reward is ignored',
      build: () =>
          KidShopBloc(repository: _FakeKidShopRepository(data: _demoData())),
      seed: _loaded,
      act: (bloc) => bloc.add(const KidShopRewardRequested('r-nope')),
      expect: () => const <KidShopState>[],
    );

    blocTest<KidShopBloc, KidShopState>(
      'duplicate request while one is in flight is ignored',
      build: () =>
          KidShopBloc(repository: _FakeKidShopRepository(data: _demoData())),
      seed: () => _loaded().copyWithRequestStarted('r-screen'),
      act: (bloc) => bloc.add(const KidShopRewardRequested('r-screen')),
      expect: () => const <KidShopState>[],
    );

    blocTest<KidShopBloc, KidShopState>(
      'request before load is ignored',
      build: () =>
          KidShopBloc(repository: _FakeKidShopRepository(data: _demoData())),
      act: (bloc) => bloc.add(const KidShopRewardRequested('r-screen')),
      expect: () => const <KidShopState>[],
    );

    blocTest<KidShopBloc, KidShopState>(
      'notice clears after the view shows it',
      build: () =>
          KidShopBloc(repository: _FakeKidShopRepository(data: _demoData())),
      seed: () => _loaded().copyWithRequestFinished(
        'r-screen',
        'Mum will give it a thumbs-up soon.',
      ),
      act: (bloc) => bloc.add(const KidShopNoticeShown()),
      expect: () => <KidShopState>[
        _loaded()
            .copyWithRequestFinished(
              'r-screen',
              'Mum will give it a thumbs-up soon.',
            )
            .copyWithNoticeCleared(),
      ],
      verify: (bloc) {
        expect(bloc.state.notice, isNull);
        expect(bloc.state.noticeSeq, 1);
      },
    );
  });

  group('KidShopState value semantics', () {
    test('request constructors keep the coin balance and child', () {
      final started = _loaded().copyWithRequestStarted('r-screen');
      expect(started.requestingIds, <String>{'r-screen'});
      expect(started.coins, 120);
      expect(started.childId, 'maya');
      expect(started.notice, isNull);

      final done = started.copyWithRequestFinished(
        'r-screen',
        'Mum will give it a thumbs-up soon.',
      );
      expect(done.requestingIds, isEmpty);
      expect(done.noticeSeq, 1);
    });

    test('loaded emission clears a stale load error', () {
      const failed = KidShopState(
        status: KidShopStatus.failure,
        errorMessage: 'stream is down',
      );
      final recovered = failed.copyWithLoaded(
        childId: 'maya',
        coins: 120,
        items: _demoItems(),
      );
      expect(recovered.status, KidShopStatus.loaded);
      expect(recovered.errorMessage, isNull);
    });
  });
}
