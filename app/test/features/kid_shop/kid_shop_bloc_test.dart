// K08 bloc tests: every KidShopEvent/state path over a controllable fake
// repository, plus value semantics for the state object.
//
// The fake hands out FRESH streams per call (like the Drift repo does), so
// retry-after-failure and live re-emission behave like production. It is a
// stream-based fake rather than the in-memory DB because bloc tests exercise
// error and silence paths the database cannot produce.

import 'dart:async';

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

/// Leo's shop: 45 coins, so nothing is affordable. Same six rewards in the
/// same creation order (the list never reorders, only the affordances move).
KidShopData _leoData() => KidShopData(
  childId: 'leo',
  coins: 45,
  items: <ShopReward>[
    for (final item in _demoItems())
      ShopReward(
        id: item.id,
        title: item.title,
        detail: item.detail,
        icon: item.icon,
        coinPrice: item.coinPrice,
        needsOk: item.needsOk,
        affordable: false,
      ),
  ],
);

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

  /// Makes `requestReward` take real time, like the Drift transaction it
  /// stands in for. The bloc's double-tap guard only engages while a write is
  /// genuinely in flight, so the timing-sensitive tests need this.
  Duration writeDelay = Duration.zero;

  /// When set, [watchActiveShop] hands out [live] instead of a one-shot
  /// stream, so a test can push emissions and count cancellations the way
  /// Drift's watch stream behaves.
  bool controlled = false;

  /// How many times the last subscription to [live] was cancelled.
  int liveCancels = 0;

  late final StreamController<KidShopData> live =
      StreamController<KidShopData>.broadcast(onCancel: () => liveCancels++);

  /// Pushes one emission into [live] (controlled mode).
  void push(KidShopData next) => live.add(next);

  /// Completes [live], as a Drift watch stream does when its DB closes.
  void finishLive() => live.close();

  @override
  Stream<KidShopData> watchActiveShop() {
    watches++;
    if (controlled) return live.stream;
    if (failFirstWatch && watches == 1) {
      return Stream<KidShopData>.error(Exception('stream is down'));
    }
    return Stream<KidShopData>.value(data);
  }

  @override
  Future<String?> requestReward(String childId, String rewardId) async {
    if (requestError != null) throw requestError!;
    if (writeDelay > Duration.zero) {
      await Future<void>.delayed(writeDelay);
    }
    requests.add((childId, rewardId));
    if (vanishedIds.contains(rewardId)) return null;
    // Mirrors the real repository: the written status, not the requested
    // one. Tests override [writtenStatus] per id for the raced cases the
    // seed cannot produce (an instant reward the balance stops covering).
    return writtenStatus[rewardId] ?? 'requested';
  }

  /// Per-id override for the status the write produces. Defaults to
  /// `'requested'`; a test sets `'approved'` for the grants it needs.
  final Map<String, String> writtenStatus = <String, String>{};

  /// Ids the write finds GONE (`requestReward` → `null`, nothing written) —
  /// the reward was deleted after the stream last emitted but before the tap.
  final Set<String> vanishedIds = <String>{};
}

/// A bloc already showing the demo shop through a live stream, with every
/// state recorded from the very first emission.
///
/// Recording (rather than `expectLater(bloc.stream, …)`) is deliberate: the
/// bloc stream is a broadcast stream, so a subscriber that attaches after an
/// event has already fired silently misses it, and the interesting states
/// here all land between `settle()` calls.
class _Harness {
  _Harness._(this.repo, this.bloc, this.seen, this._sub);

  final _FakeKidShopRepository repo;
  final KidShopBloc bloc;

  /// Every state the bloc emitted, in order.
  final List<KidShopState> seen;
  final StreamSubscription<KidShopState> _sub;

  /// Lets the microtask/event queue drain so pending handlers finish.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  /// Pushes one shop emission and waits for the bloc to process it.
  Future<void> emit(KidShopData data) async {
    repo.push(data);
    await settle();
  }

  Future<void> close() async {
    await _sub.cancel();
    await bloc.close();
    await repo.live.close();
  }
}

/// Builds a [_Harness] whose bloc has loaded [data] (the demo shop by
/// default) through the controllable stream.
Future<_Harness> _loadedHarness({KidShopData? data}) async {
  final repo = _FakeKidShopRepository(data: data ?? _demoData())
    ..controlled = true;
  final bloc = KidShopBloc(repository: repo);
  final seen = <KidShopState>[];
  final sub = bloc.stream.listen(seen.add);
  addTearDown(sub.cancel);
  final harness = _Harness._(repo, bloc, seen, sub);
  bloc.add(const KidShopLoadRequested());
  await harness.settle();
  await harness.emit(repo.data);
  return harness;
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

    test('a live emission updates coins and items in place', () async {
      final harness = await _loadedHarness();
      addTearDown(harness.close);

      expect(harness.seen, <KidShopState>[
        const KidShopState(status: KidShopStatus.loading),
        _loaded(),
      ]);

      // Leo takes over mid-session: the stream replaces the child, the coins
      // and every affordance, and nothing is lost.
      await harness.emit(_leoData());
      expect(harness.seen.last.childId, 'leo');
      expect(harness.seen.last.coins, 45);
      expect(
        harness.seen.last.items.every((item) => !item.affordable),
        isTrue,
        reason: "Leo's 45 coins buy nothing",
      );
      expect(harness.seen.last.items.map((item) => item.id).toList(), <String>[
        'r-screen',
        'r-film',
        'r-bedtime',
        'r-baking',
        'r-cafe',
        'r-dinner',
      ], reason: 'creation order survives the switch');
    });

    test('a stream error after a healthy load keeps the error text', () async {
      final harness = await _loadedHarness();
      addTearDown(harness.close);

      harness.repo.live.addError(Exception('shop is offline'));
      await harness.settle();

      expect(harness.seen.last.status, KidShopStatus.failure);
      expect(harness.seen.last.errorMessage, contains('offline'));
      expect(harness.seen.last.coins, 120, reason: 'last known coins survive');
    });

    test('close() releases the live shop subscription', () async {
      final repo = _FakeKidShopRepository(data: _demoData())..controlled = true;
      final bloc = KidShopBloc(repository: repo);
      addTearDown(repo.live.close);
      final seen = <KidShopState>[];
      final sub = bloc.stream.listen(seen.add);
      bloc.add(const KidShopLoadRequested());
      await Future<void>.delayed(Duration.zero);
      expect(repo.liveCancels, 0, reason: 'the bloc is subscribed');
      final before = bloc.state;

      await bloc.close();
      await sub.cancel();

      expect(repo.liveCancels, 1, reason: 'no leaked watch subscription');
      // A late emission after close is dropped, not thrown: no stray state.
      repo.push(_leoData());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, before, reason: 'no state after close');
      expect(seen.where((s) => s != before), isEmpty);
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
      build: () {
        final repo = _FakeKidShopRepository(data: _demoData())
          ..writtenStatus['r-baking'] = 'approved';
        return KidShopBloc(repository: repo);
      },
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
      'a raced instant request left requested toasts thumbs-up (K08-BUG-4)',
      build: () {
        // The K08-BUG-1 guard in the real repository: an instant reward the
        // balance stops covering lands `requested`, and the toast must say
        // so instead of announcing the reward as already owned.
        final repo = _FakeKidShopRepository(data: _demoData())
          ..writtenStatus['r-baking'] = 'requested';
        return KidShopBloc(repository: repo);
      },
      seed: _loaded,
      act: (bloc) => bloc.add(const KidShopRewardRequested('r-baking')),
      expect: () {
        final loaded = _loaded();
        return <KidShopState>[
          loaded.copyWithRequestStarted('r-baking'),
          loaded.copyWithRequestFinished(
            'r-baking',
            'Mum will give it a thumbs-up soon.',
          ),
        ];
      },
      verify: (bloc) {
        expect(bloc.state.notice, 'Mum will give it a thumbs-up soon.');
        expect(bloc.state.noticeSeq, 1);
      },
    );

    // The `written == null` half of the same branch: `requestReward` writes
    // nothing and returns null when the reward is GONE by the time the write
    // runs (deleted after the stream last emitted, before the tap). The
    // affordability guard still passed — it reads `state.items` — so the only
    // honest answer is the retry copy, never "it's yours".
    blocTest<KidShopBloc, KidShopState>(
      'a reward that vanished before the write toasts the retry copy',
      build: () {
        final repo = _FakeKidShopRepository(data: _demoData())
          ..vanishedIds.add('r-screen');
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
      verify: (bloc) {
        expect(bloc.state.requestingIds, isEmpty);
        expect(bloc.state.noticeSeq, 1);
      },
    );

    blocTest<KidShopBloc, KidShopState>(
      'an unexpected written status never claims the reward is owned',
      build: () {
        // Defensive: the contract is 'approved' | 'requested' | null. Anything
        // else must fall on the "a grown-up decides" side, never "it's yours".
        final repo = _FakeKidShopRepository(data: _demoData())
          ..writtenStatus['r-baking'] = 'denied';
        return KidShopBloc(repository: repo);
      },
      seed: _loaded,
      act: (bloc) => bloc.add(const KidShopRewardRequested('r-baking')),
      verify: (bloc) {
        expect(bloc.state.notice, 'Mum will give it a thumbs-up soon.');
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
      'request after a failure is ignored (no child is resolved)',
      build: () =>
          KidShopBloc(repository: _FakeKidShopRepository(data: _demoData())),
      seed: () => const KidShopState(
        status: KidShopStatus.failure,
        errorMessage: 'shop is down',
      ),
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

  // The guards above are only worth having if they stop the WRITE, not just
  // the state emission — a guard that dropped the state but still spent coins
  // would be worse than no guard at all.
  group('KidShopBloc guards never write (K08)', () {
    test('an unaffordable reward never reaches the repository', () async {
      final harness = await _loadedHarness();
      addTearDown(harness.close);
      harness.bloc.add(const KidShopRewardRequested('r-cafe'));
      await harness.settle();

      expect(harness.repo.requests, isEmpty, reason: '150 > 120 coins');
      expect(harness.bloc.state.requestingIds, isEmpty);
      expect(harness.bloc.state.notice, isNull);
    });

    test('an unknown reward id never reaches the repository', () async {
      final harness = await _loadedHarness();
      addTearDown(harness.close);
      harness.bloc.add(const KidShopRewardRequested('r-does-not-exist'));
      await harness.settle();

      expect(harness.repo.requests, isEmpty, reason: 'no such reward');
      expect(harness.bloc.state.notice, isNull);
      expect(harness.bloc.state.noticeSeq, 0);
    });

    test(
      'a request before the load resolves never reaches the repository',
      () async {
        final repo = _FakeKidShopRepository(data: _demoData())
          ..controlled = true;
        final bloc = KidShopBloc(repository: repo);
        addTearDown(() async {
          await bloc.close();
          await repo.live.close();
        });
        // No emission yet, so `childId` is still ''.
        bloc.add(const KidShopRewardRequested('r-screen'));
        await Future<void>.delayed(Duration.zero);

        expect(repo.requests, isEmpty, reason: 'no childId yet');
      },
    );

    test(
      'a second card can be requested while the first is in flight',
      () async {
        final harness = await _loadedHarness();
        addTearDown(harness.close);
        harness.bloc.add(const KidShopRewardRequested('r-screen'));
        await harness.settle();
        harness.bloc.add(const KidShopRewardRequested('r-film'));
        await harness.settle();

        // The guard is per id, not global: each card spins while its own write
        // runs, and the states arrive strictly one after the other (bloc's
        // default transformer finishes a handler before the next event starts).
        expect(harness.seen.map((s) => s.requestingIds).toList(), <Object>[
          isEmpty, // loading
          isEmpty, // loaded
          <String>{'r-screen'}, // first starts
          isEmpty, // first finishes
          <String>{'r-film'}, // second starts
          isEmpty, // second finishes
        ]);
        expect(harness.repo.requests, <(String, String)>[
          ('maya', 'r-screen'),
          ('maya', 'r-film'),
        ]);
      },
    );

    test(
      'two identical requests still toast twice (noticeSeq bumps)',
      () async {
        final harness = await _loadedHarness();
        addTearDown(harness.close);
        harness.bloc.add(const KidShopRewardRequested('r-screen'));
        await harness.settle();
        harness.bloc.add(const KidShopRewardRequested('r-screen'));
        await harness.settle();

        final toasts = harness.seen
            .where((s) => s.requestingIds.isEmpty && s.notice != null)
            .toList();
        expect(toasts.map((s) => s.noticeSeq).toList(), <int>[1, 2]);
        expect(toasts.map((s) => s.notice).toList(), <String>[
          'Mum will give it a thumbs-up soon.',
          'Mum will give it a thumbs-up soon.',
        ]);
        expect(
          harness.repo.requests,
          hasLength(2),
          reason:
              'two separate taps are two separate requests (only a '
              'same-frame double tap is swallowed — see the next test)',
        );
      },
    );

    // The guard that matters: the fake above completes `requestReward` in a
    // single microtask, which is FASTER than a real Drift transaction. With a
    // genuinely async write the second event arrives while the first is still
    // in flight, and `requestingIds` swallows it. This is the double-tap
    // protection the state doc-comment promises.
    test(
      'a double tap is swallowed while the write is still in flight',
      () async {
        final repo = _FakeKidShopRepository(data: _demoData())
          ..writeDelay = const Duration(milliseconds: 20);
        final bloc = KidShopBloc(repository: repo);
        addTearDown(bloc.close);
        bloc.add(const KidShopLoadRequested());
        await Future<void>.delayed(Duration.zero);

        bloc
          ..add(const KidShopRewardRequested('r-screen'))
          ..add(const KidShopRewardRequested('r-screen'));
        await Future<void>.delayed(const Duration(milliseconds: 80));

        expect(repo.requests, <(String, String)>[('maya', 'r-screen')]);
        expect(bloc.state.noticeSeq, 1, reason: 'one tap, one toast');
        expect(bloc.state.requestingIds, isEmpty);
      },
    );

    test('the double-tap guard is per id, never global', () async {
      final repo = _FakeKidShopRepository(data: _demoData())
        ..writeDelay = const Duration(milliseconds: 20);
      final bloc = KidShopBloc(repository: repo);
      addTearDown(bloc.close);
      bloc.add(const KidShopLoadRequested());
      await Future<void>.delayed(Duration.zero);

      bloc
        ..add(const KidShopRewardRequested('r-screen'))
        ..add(const KidShopRewardRequested('r-film'));
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(repo.requests, <(String, String)>[
        ('maya', 'r-screen'),
        ('maya', 'r-film'),
      ]);
    });
  });

  group('KidShopBloc pending-notice lifetime (K08)', () {
    test('an unshown notice survives a coin emission mid-toast', () async {
      final harness = await _loadedHarness();
      addTearDown(harness.close);

      harness.bloc.add(const KidShopRewardRequested('r-screen'));
      await harness.settle();
      expect(harness.bloc.state.notice, 'Mum will give it a thumbs-up soon.');

      // The stream pushes the new balance while the toast is still pending.
      await harness.emit(
        const KidShopData(childId: 'maya', coins: 70, items: <ShopReward>[]),
      );

      expect(harness.bloc.state.coins, 70);
      expect(
        harness.bloc.state.notice,
        'Mum will give it a thumbs-up soon.',
        reason: 'the pending toast is not swallowed by the coin emission',
      );
      expect(harness.bloc.state.noticeSeq, 1);
    });

    test(
      'a stream emission between two requests keeps the toast distinct',
      () async {
        final harness = await _loadedHarness();
        addTearDown(harness.close);

        harness.bloc.add(const KidShopRewardRequested('r-film'));
        await harness.settle();
        await harness.emit(_leoData());
        harness.bloc.add(const KidShopRewardRequested('r-dinner'));
        await harness.settle();

        // Leo is playing (45 coins), so the 90-coin dinner is out of reach and
        // the second request is guarded off — and the first toast survives.
        expect(harness.bloc.state.childId, 'leo');
        expect(
          harness.bloc.state.notice,
          'Mum will give it a thumbs-up soon.',
          reason: 'the pending toast survives the switch',
        );
        expect(harness.bloc.state.noticeSeq, 1);
        expect(harness.repo.requests, <(String, String)>[
          ('maya', 'r-film'),
        ], reason: "Leo's 45 coins cannot buy the 90-coin dinner");
      },
    );

    test('notice-shown with nothing pending emits nothing', () async {
      final bloc = KidShopBloc(
        repository: _FakeKidShopRepository(data: _demoData()),
      );
      addTearDown(bloc.close);
      final seen = <KidShopState>[];
      final sub = bloc.stream.listen(seen.add);
      bloc.add(const KidShopNoticeShown());
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      expect(seen, isEmpty);
    });
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

    test('a fresh state is initial, unloaded and request-free', () {
      const state = KidShopState();
      expect(state.status, KidShopStatus.initial);
      expect(state.isLoaded, isFalse);
      expect(state.childId, isEmpty);
      expect(state.coins, 0);
      expect(state.items, isEmpty);
      expect(state.requestingIds, isEmpty);
      expect(state.notice, isNull);
      expect(state.noticeSeq, 0);
      expect(state.errorMessage, isNull);
    });

    test('isLoaded tracks the status, not the data', () {
      const loaded = KidShopState(status: KidShopStatus.loaded);
      const loading = KidShopState(status: KidShopStatus.loading);
      const failure = KidShopState(status: KidShopStatus.failure);
      expect(loaded.isLoaded, isTrue);
      expect(loading.isLoaded, isFalse);
      expect(failure.isLoaded, isFalse);
    });

    test('copyWith leaves untouched fields alone', () {
      final started = _loaded().copyWithRequestStarted('r-screen');
      final later = started.copyWith(coins: 70);
      expect(later.coins, 70);
      expect(later.requestingIds, <String>{'r-screen'});
      expect(later.childId, 'maya');
      expect(later.status, KidShopStatus.loaded);
    });

    test('equal states compare equal so the view does not rebuild', () {
      expect(_loaded(), _loaded());
      expect(
        _loaded().copyWithRequestFinished('r-screen', 'It’s yours — enjoy!'),
        _loaded().copyWithRequestFinished('r-screen', 'It’s yours — enjoy!'),
      );
      expect(_loaded(), isNot(_loaded().copyWithRequestStarted('r-screen')));
    });

    test('requestingIds is a fresh set, never a shared one', () {
      final base = _loaded();
      final a = base.copyWithRequestStarted('r-screen');
      final b = base.copyWithRequestStarted('r-film');
      expect(a.requestingIds, <String>{'r-screen'});
      expect(b.requestingIds, <String>{'r-film'});
      expect(
        base.requestingIds,
        isEmpty,
        reason: 'the seed state is untouched',
      );
      a.requestingIds.add('r-film');
      expect(b.requestingIds, <String>{
        'r-film',
      }, reason: 'the two sets are independent copies');
    });
  });
}
