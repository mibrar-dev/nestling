// K11 bloc tests: every BadgesEvent/state path over a controllable fake
// repository, plus value semantics for the state object.
//
// The fake hands out FRESH streams per call (like the Drift repo does), so
// retry-after-failure and live re-emission behave like production. It is a
// stream-based fake rather than the in-memory DB because bloc tests exercise
// error and silence paths the database cannot produce.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/features/badges/domain/badges_repository.dart';
import 'package:nestling/features/badges/domain/entities/badge.dart';
import 'package:nestling/features/badges/domain/entities/badges_data.dart';
import 'package:nestling/features/badges/presentation/bloc/badges_bloc.dart';
import 'package:nestling/features/badges/presentation/bloc/badges_event.dart';
import 'package:nestling/features/badges/presentation/bloc/badges_state.dart';

/// Seed.demo's eight badges in DB insertion order (the K11 grid order):
/// first-quest first, pet-friend last — never sorted. Maya has earned the
/// first four; the detail copy is the design copy (`Got it!` / `Keep going!`).
List<Badge> _demoItems() => <Badge>[
  for (var i = 0; i < 8; i++)
    Badge(
      id: _demoIds[i],
      title: _demoTitles[i],
      detail: i < 4 ? 'Got it!' : 'Keep going!',
      icon: 'medal',
      description: '',
      earned: i < 4,
      earnedAt: null,
    ),
];

const List<String> _demoIds = <String>[
  'first-quest',
  'bed-maker-7',
  'kind-helper',
  'bookworm',
  'tidy-champion',
  'early-bird',
  'super-saver',
  'pet-friend',
];

const List<String> _demoTitles = <String>[
  'First quest',
  'Bed maker ×7',
  'Kind helper',
  'Bookworm',
  'Tidy champion',
  'Early bird',
  'Super saver',
  'Pet friend',
];

BadgesData _demoData() =>
    BadgesData(childId: 'maya', items: _demoItems(), happyDays: 4);

/// Leo's badges: 3 happy days, only the first quest earned. Same eight rows
/// in the same insertion order (the list never reorders).
BadgesData _leoData() => BadgesData(
  childId: 'leo',
  items: <Badge>[
    for (var i = 0; i < 8; i++)
      Badge(
        id: _demoIds[i],
        title: _demoTitles[i],
        detail: i == 0 ? 'Got it!' : 'Keep going!',
        icon: 'medal',
        description: '',
        earned: i == 0,
        earnedAt: null,
      ),
  ],
  happyDays: 3,
);

BadgesState _loaded() => BadgesState(
  status: BadgesStatus.loaded,
  childId: 'maya',
  items: _demoItems(),
  happyDays: 4,
);

/// Controllable fake: fresh streams per call and a switch for stream
/// failure. The first `watchActiveBadges` call can fail while later ones
/// serve data, so the retry path is reachable.
class _FakeBadgesRepository implements BadgesRepository {
  _FakeBadgesRepository({required this.data});

  BadgesData data;
  bool failFirstWatch = false;
  int watches = 0;

  /// When set, [watchActiveBadges] hands out [live] instead of a one-shot
  /// stream, so a test can push emissions and count cancellations the way
  /// Drift's watch stream behaves.
  bool controlled = false;

  /// How many times the last subscription to [live] was cancelled.
  int liveCancels = 0;

  late final StreamController<BadgesData> live =
      StreamController<BadgesData>.broadcast(onCancel: () => liveCancels++);

  /// Pushes one emission into [live] (controlled mode).
  void push(BadgesData next) => live.add(next);

  @override
  Future<List<Badge>> getItems() async => data.items;

  @override
  Stream<List<Badge>> watchItems() => Stream<List<Badge>>.value(data.items);

  @override
  Stream<BadgesData> watchActiveBadges() {
    watches++;
    if (controlled) return live.stream;
    if (failFirstWatch && watches == 1) {
      return Stream<BadgesData>.error(Exception('stream is down'));
    }
    return Stream<BadgesData>.value(data);
  }

  @override
  Stream<List<Badge>> watchShelf(String childId) =>
      Stream<List<Badge>>.value(data.items);

  @override
  Stream<int> watchHappyDays(String childId) =>
      Stream<int>.value(data.happyDays);
}

/// A bloc already showing the demo shelf through a live stream, with every
/// state recorded from the very first emission.
///
/// Recording (rather than `expectLater(bloc.stream, …)`) is deliberate: the
/// bloc stream is a broadcast stream, so a subscriber that attaches after an
/// event has already fired silently misses it, and the interesting states
/// here all land between `settle()` calls.
class _Harness {
  _Harness._(this.repo, this.bloc, this.seen, this._sub);

  final _FakeBadgesRepository repo;
  final BadgesBloc bloc;

  /// Every state the bloc emitted, in order.
  final List<BadgesState> seen;
  final StreamSubscription<BadgesState> _sub;

  /// Lets the microtask/event queue drain so pending handlers finish.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  /// Pushes one badges emission and waits for the bloc to process it.
  Future<void> emit(BadgesData data) async {
    repo.push(data);
    await settle();
  }

  Future<void> close() async {
    await _sub.cancel();
    await bloc.close();
    await repo.live.close();
  }
}

/// Builds a [_Harness] whose bloc has loaded [data] (the demo shelf by
/// default) through the controllable stream.
Future<_Harness> _loadedHarness({BadgesData? data}) async {
  final repo = _FakeBadgesRepository(data: data ?? _demoData())
    ..controlled = true;
  final bloc = BadgesBloc(repository: repo);
  final seen = <BadgesState>[];
  final sub = bloc.stream.listen(seen.add);
  addTearDown(sub.cancel);
  final harness = _Harness._(repo, bloc, seen, sub);
  bloc.add(const BadgesLoadRequested());
  await harness.settle();
  await harness.emit(repo.data);
  return harness;
}

void main() {
  group('BadgesBloc load (K11)', () {
    blocTest<BadgesBloc, BadgesState>(
      'emits loading then loaded with Maya shelf and 4 happy days',
      build: () =>
          BadgesBloc(repository: _FakeBadgesRepository(data: _demoData())),
      act: (bloc) => bloc.add(const BadgesLoadRequested()),
      expect: () => <BadgesState>[
        const BadgesState(status: BadgesStatus.loading),
        _loaded(),
      ],
    );

    blocTest<BadgesBloc, BadgesState>(
      'the first four badges are earned with Got it! copy',
      build: () =>
          BadgesBloc(repository: _FakeBadgesRepository(data: _demoData())),
      seed: _loaded,
      expect: () => const <BadgesState>[],
      verify: (bloc) {
        expect(bloc.state.items.map((b) => b.id).toList(), _demoIds);
        expect(
          bloc.state.items.where((b) => b.earned).map((b) => b.id).toList(),
          <String>['first-quest', 'bed-maker-7', 'kind-helper', 'bookworm'],
        );
        expect(
          <String, String>{for (final b in bloc.state.items) b.id: b.detail},
          <String, String>{
            'first-quest': 'Got it!',
            'bed-maker-7': 'Got it!',
            'kind-helper': 'Got it!',
            'bookworm': 'Got it!',
            'tidy-champion': 'Keep going!',
            'early-bird': 'Keep going!',
            'super-saver': 'Keep going!',
            'pet-friend': 'Keep going!',
          },
        );
        expect(bloc.state.happyDays, 4);
        expect(bloc.state.childId, 'maya');
      },
    );

    test(
      'a second load while live is ignored (no stacked subscription)',
      () async {
        final repo = _FakeBadgesRepository(data: _demoData());
        final bloc = BadgesBloc(repository: repo);
        addTearDown(bloc.close);
        bloc
          ..add(const BadgesLoadRequested())
          ..add(const BadgesLoadRequested());
        await expectLater(
          bloc.stream,
          emitsInOrder([
            const BadgesState(status: BadgesStatus.loading),
            predicate<BadgesState>(
              (state) =>
                  state.status == BadgesStatus.loaded && state.happyDays == 4,
            ),
          ]),
        );
        expect(repo.watches, 1);
      },
    );

    test('stream error emits failure and a retry reloads', () async {
      final repo = _FakeBadgesRepository(data: _demoData())
        ..failFirstWatch = true;
      final bloc = BadgesBloc(repository: repo);
      addTearDown(bloc.close);
      bloc.add(const BadgesLoadRequested());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          const BadgesState(status: BadgesStatus.loading),
          predicate<BadgesState>(
            (state) => state.status == BadgesStatus.failure,
          ),
        ]),
      );
      expect(repo.watches, 1);

      bloc.add(const BadgesLoadRequested());
      await expectLater(
        bloc.stream,
        emitsInOrder([
          // The retry spinner carries the load error through (K08 precedent:
          // only a healthy emission clears it), so match on status only.
          predicate<BadgesState>(
            (state) => state.status == BadgesStatus.loading,
          ),
          predicate<BadgesState>(
            (state) =>
                state.status == BadgesStatus.loaded && state.happyDays == 4,
          ),
        ]),
      );
      expect(repo.watches, 2);
    });

    test('a live emission swaps the child, shelf and count in place', () async {
      final harness = await _loadedHarness();
      addTearDown(harness.close);

      expect(harness.seen, <BadgesState>[
        const BadgesState(status: BadgesStatus.loading),
        _loaded(),
      ]);

      // Leo takes over mid-session: the stream replaces the child, the
      // happy-day count and every earned flag, and nothing is lost.
      await harness.emit(_leoData());
      expect(harness.seen.last.childId, 'leo');
      expect(harness.seen.last.happyDays, 3);
      expect(
        harness.seen.last.items
            .where((b) => b.earned)
            .map((b) => b.id)
            .toList(),
        <String>['first-quest'],
      );
      expect(
        harness.seen.last.items.map((b) => b.id).toList(),
        _demoIds,
        reason: 'insertion order survives the switch',
      );
    });

    test('a stream error after a healthy load keeps the error text', () async {
      final harness = await _loadedHarness();
      addTearDown(harness.close);

      harness.repo.live.addError(Exception('badges are offline'));
      await harness.settle();

      expect(harness.seen.last.status, BadgesStatus.failure);
      expect(harness.seen.last.errorMessage, contains('offline'));
      expect(
        harness.seen.last.happyDays,
        4,
        reason: 'the last known count survives',
      );
    });

    test('a data event before any load still populates the state', () async {
      // The route always adds `BadgesLoadRequested`, but the bloc must not
      // depend on that ordering: a stream emission that lands first must not
      // be dropped or crash the handler.
      final repo = _FakeBadgesRepository(data: _demoData());
      final bloc = BadgesBloc(repository: repo);
      addTearDown(bloc.close);
      final seen = <BadgesState>[];
      final sub = bloc.stream.listen(seen.add);
      addTearDown(sub.cancel);

      bloc.add(BadgesDataReceived(_demoData()));
      await Future<void>.delayed(Duration.zero);

      expect(seen.single.status, BadgesStatus.loaded);
      expect(seen.single.childId, 'maya');
      expect(seen.single.happyDays, 4);
      expect(
        repo.watches,
        0,
        reason: 'a data event never starts a watch — only a load does',
      );
    });

    test('a failure event before any load shows the retry surface', () async {
      final repo = _FakeBadgesRepository(data: _demoData());
      final bloc = BadgesBloc(repository: repo);
      addTearDown(bloc.close);
      final seen = <BadgesState>[];
      final sub = bloc.stream.listen(seen.add);
      addTearDown(sub.cancel);

      bloc.add(BadgesStreamFailed(Exception('offline')));
      await Future<void>.delayed(Duration.zero);

      expect(seen.single.status, BadgesStatus.failure);
      expect(seen.single.errorMessage, contains('offline'));
      expect(seen.single.items, isEmpty);
      expect(repo.watches, 0);
    });

    test('a failed load keeps the last known shelf in state', () async {
      // The view switches on status, so the shelf survives for any future
      // decision — and, more importantly, a failure never blanks the state.
      final repo = _FakeBadgesRepository(data: _demoData())..controlled = true;
      final bloc = BadgesBloc(repository: repo);
      addTearDown(repo.live.close);
      addTearDown(bloc.close);
      final seen = <BadgesState>[];
      final sub = bloc.stream.listen(seen.add);
      addTearDown(sub.cancel);

      bloc.add(const BadgesLoadRequested());
      await Future<void>.delayed(Duration.zero);
      repo.push(_demoData());
      await Future<void>.delayed(Duration.zero);
      repo.live.addError(Exception('stream lost'));
      await Future<void>.delayed(Duration.zero);

      final failure = seen.last;
      expect(failure.status, BadgesStatus.failure);
      expect(failure.childId, 'maya');
      expect(failure.items, hasLength(8));
      expect(failure.happyDays, 4);
      expect(
        repo.liveCancels,
        1,
        reason: 'the error releases the subscription so Try again can work',
      );
    });

    test('close() releases the live badges subscription', () async {
      final repo = _FakeBadgesRepository(data: _demoData())..controlled = true;
      final bloc = BadgesBloc(repository: repo);
      addTearDown(repo.live.close);
      final seen = <BadgesState>[];
      final sub = bloc.stream.listen(seen.add);
      bloc.add(const BadgesLoadRequested());
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

  group('BadgesState value semantics', () {
    test('loaded emission clears a stale load error', () {
      const failed = BadgesState(
        status: BadgesStatus.failure,
        errorMessage: 'stream is down',
      );
      final recovered = failed.copyWithLoaded(
        childId: 'maya',
        items: _demoItems(),
        happyDays: 4,
      );
      expect(recovered.status, BadgesStatus.loaded);
      expect(recovered.errorMessage, isNull);
      expect(recovered.childId, 'maya');
      expect(recovered.happyDays, 4);
    });

    test('a fresh state is initial, childless and count-free', () {
      const state = BadgesState();
      expect(state.status, BadgesStatus.initial);
      expect(state.isLoaded, isFalse);
      expect(state.childId, isEmpty);
      expect(state.items, isEmpty);
      expect(state.happyDays, 0);
      expect(state.errorMessage, isNull);
    });

    test('isLoaded tracks the status, not the data', () {
      const loaded = BadgesState(status: BadgesStatus.loaded);
      const loading = BadgesState(status: BadgesStatus.loading);
      const failure = BadgesState(status: BadgesStatus.failure);
      expect(loaded.isLoaded, isTrue);
      expect(loading.isLoaded, isFalse);
      expect(failure.isLoaded, isFalse);
    });

    test('copyWith leaves untouched fields alone', () {
      final later = _loaded().copyWith(happyDays: 5);
      expect(later.happyDays, 5);
      expect(later.childId, 'maya');
      expect(later.items.map((b) => b.id).toList(), _demoIds);
      expect(later.status, BadgesStatus.loaded);
    });

    test('equal states compare equal so the view does not rebuild', () {
      expect(_loaded(), _loaded());
      expect(_loaded(), isNot(_loaded().copyWith(happyDays: 5)));
      expect(
        _demoData(),
        BadgesData(childId: 'maya', items: _demoItems(), happyDays: 4),
      );
    });
  });
}
