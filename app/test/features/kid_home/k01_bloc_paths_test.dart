// K01 · Who's playing? — bloc paths not already covered by the shared
// `kid_home_bloc_test.dart` K01 group.
//
// The fake hands out a FRESH profiles stream per call (like the Drift
// repository does) and counts subscriptions, so "the retry must not stack a
// second live stream" (the K03-BUG-15 hazard, applied to the roster) is
// observable rather than assumed.
//
// Covered here:
//   • KidHomeProfilesRequested before any load — starts the roster WITHOUT
//     emitting `loading` (the load event owns that status)
//   • KidHomeLoadRequested emits `loading` once and is idempotent while live
//   • KidHomeProfilesFailed with nothing to show becomes `failure`
//   • a profiles error releases the subscription, so a retry really reloads
//   • roster emissions never clobber status / child / items / selection
//   • the selection one-shot is consumed by the next HOME emission
//   • every field the picker reads takes part in equality
//   • K01-BUG-5: a profiles-caused failure recovers to `loaded` (with the
//     stale load error cleared) on the next healthy roster, without a new
//     home emission; Try again shows `loading` while only the roster
//     restarts (review findings 1–3); a home-caused failure is never
//     masked by a healthy roster
//   • K01-BUG-6 (fixed): a burst persists only the first selection — a
//     selection arriving while another is unconsumed returns early without
//     writing, so `app_state` always names the pushed route's child
//   • K01-BUG-3: `KidHomeSelectionHandled` consumes a pending selection so
//     tapping the same tile after coming back emits distinctly again; a
//     no-op when nothing is pending
//   • review finding 2: `profilesFailed` tracks the roster outage (set on
//     the error path, cleared by any healthy roster) so the view can gate
//     its failure-card heal instead of re-deriving it

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_home_data.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_bloc.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_event.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_state.dart';

const KidChild maya = KidChild(
  id: 'maya',
  nickname: 'Maya',
  ageBand: '7-9',
  avatarColour: 'lilac',
  coins: 120,
  pipStyle: 'mochi',
  pipSkin: 'sunny',
  pipAccessory: 'none',
  pipStage: 3,
  happiness: 4,
  pinSet: true,
);

const KidChild leo = KidChild(
  id: 'leo',
  nickname: 'Leo',
  ageBand: '4-6',
  avatarColour: 'mint',
  coins: 45,
  pipStyle: 'bolt',
  pipSkin: 'sky',
  pipAccessory: 'none',
  pipStage: 2,
  happiness: 3,
  pinSet: false,
);

List<KidQuest> _items() => const <KidQuest>[
  KidQuest(
    id: 'q-reading:maya',
    title: 'Reading – 20 minutes',
    detail: 'To do · +10',
    questId: 'q-reading',
    icon: 'book',
    coins: 10,
    status: 'to_do',
  ),
];

/// Fresh streams per call, pushable roster, injectable errors, and a
/// subscription counter for the roster so stacking is observable.
class _RosterFake extends KidHomeRepository {
  /// Fail the next [watchHome] listen (a home stream that cannot be read).
  bool failHome = false;

  /// Fail the next [watchProfiles] listen (a roster that cannot be read).
  bool failProfiles = false;

  int profileSubscriptions = 0;
  int homeSubscriptions = 0;
  final List<String> selected = <String>[];

  /// Yield a childless home that then stays quiet — the K01-BUG-5 shape:
  /// the failure card is shown while the home stream is healthy (live)
  /// but silent, so only a roster recovery can dismiss it.
  bool homeChildNull = false;

  final StreamController<List<KidChild>> _pushed =
      StreamController<List<KidChild>>.broadcast();

  @override
  Future<List<KidQuest>> getItems() async => _items();

  @override
  Stream<List<KidQuest>> watchItems() => const Stream<List<KidQuest>>.empty();

  @override
  Stream<List<KidChild>> watchProfiles() async* {
    profileSubscriptions++;
    if (failProfiles) {
      throw Exception('profiles down');
    }
    yield const <KidChild>[maya, leo];
    yield* _pushed.stream;
  }

  void pushRoster(List<KidChild> value) => _pushed.add(value);

  void failRosterNow(Object error) => _pushed.addError(error);

  @override
  Stream<KidChild?> watchActiveChild() => Stream<KidChild?>.value(maya);

  @override
  Stream<KidHomeData> watchHome() async* {
    homeSubscriptions++;
    if (failHome) {
      throw Exception('home down');
    }
    yield KidHomeData(child: homeChildNull ? null : maya, items: _items());
  }

  @override
  List<String> stepsFor(String questId) => const <String>[];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> setActiveChild(String childId) async => selected.add(childId);

  @override
  Future<void> completeQuest(String childId, String questId) async {}
}

Matcher _roster(List<String> ids) => predicate<KidHomeState>(
  (state) => listEquals(state.profiles.map((c) => c.id).toList(), ids),
  'roster $ids',
);

void main() {
  // The fake the current test handed to its bloc. `blocTest` calls `build`
  // once before `act`, so one late variable is enough and the bloc needs no
  // test-only accessor of its own.
  late _RosterFake repo;

  group('K01 — the profiles-only event', () {
    blocTest<KidHomeBloc, KidHomeState>(
      'loads the roster and emits nothing but that one state',
      build: () {
        repo = _RosterFake();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const KidHomeProfilesRequested()),
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _roster(<String>['maya', 'leo']),
      ],
      verify: (bloc) {
        expect(
          bloc.state.status,
          KidHomeStatus.initial,
          reason: 'the profiles event must never emit `loading` itself',
        );
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'repeated requests while live never stack a second subscription',
      build: () {
        repo = _RosterFake();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeProfilesRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc
          ..add(const KidHomeProfilesRequested())
          ..add(const KidHomeProfilesRequested());
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) {
        expect(repo.profileSubscriptions, 1);
        expect(bloc.state.profiles, hasLength(2));
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a roster that cannot be read with nothing to show becomes `failure`',
      build: () {
        repo = _RosterFake()..failProfiles = true;
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const KidHomeProfilesRequested()),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, KidHomeStatus.failure);
        expect(bloc.state.errorMessage, contains('profiles down'));
        expect(bloc.state.profiles, isEmpty);
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a roster error releases the subscription, so the retry really reloads',
      build: () {
        repo = _RosterFake();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeProfilesRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        repo.failRosterNow(Exception('one bad tick'));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const KidHomeProfilesRequested());
      },
      wait: const Duration(milliseconds: 200),
      verify: (bloc) {
        expect(
          repo.profileSubscriptions,
          2,
          reason: 'the error path cancels, so the retry opens a fresh stream',
        );
        expect(bloc.state.profiles, hasLength(2));
      },
    );
  });

  group('K01 — the load request', () {
    blocTest<KidHomeBloc, KidHomeState>(
      'emits `loading` first, then `loaded` with the roster',
      build: () {
        repo = _RosterFake();
        return KidHomeBloc(repository: repo);
      },
      // The order in which the two live streams deliver is not a contract
      // (Drift makes both async), so assert WHICH statuses were published,
      // not their interleaving.
      act: (bloc) async {
        final seen = <KidHomeStatus>[];
        final subscription = bloc.stream.listen((state) {
          seen.add(state.status);
        });
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();
        expect(
          seen,
          containsAll(<KidHomeStatus>[
            KidHomeStatus.loading,
            KidHomeStatus.loaded,
          ]),
          reason: 'a load publishes `loading` before anything is drawn',
        );
        expect(
          seen.where((status) => status == KidHomeStatus.loading).length,
          1,
          reason: 'and only once — a second loading would flash the spinner',
        );
        expect(seen, isNot(contains(KidHomeStatus.failure)));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, KidHomeStatus.loaded);
        expect(bloc.state.profiles.map((c) => c.id).toList(), <String>[
          'maya',
          'leo',
        ]);
        expect(bloc.state.child?.nickname, 'Maya');
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a reload while the load is live is ignored, not stacked',
      build: () {
        repo = _RosterFake();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const KidHomeLoadRequested());
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) {
        expect(repo.homeSubscriptions, 1);
        expect(repo.profileSubscriptions, 1);
        expect(bloc.state.status, KidHomeStatus.loaded);
      },
    );
  });

  group('K01 — roster emissions never clobber the rest of the state', () {
    blocTest<KidHomeBloc, KidHomeState>(
      'a roster push keeps the loaded status, child and items',
      build: () {
        repo = _RosterFake();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 40));
        repo.pushRoster(<KidChild>[leo]);
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.profiles.single.id, 'leo');
        expect(bloc.state.status, KidHomeStatus.loaded);
        expect(bloc.state.child?.nickname, 'Maya');
        expect(bloc.state.items, hasLength(1));
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a roster push does not consume a pending selection',
      build: () {
        repo = _RosterFake();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 40));
        bloc.add(const KidHomeProfileSelected(childId: 'leo', pinSet: false));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        repo.pushRoster(const <KidChild>[maya, leo]);
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(
          bloc.state.selectedProfileId,
          'leo',
          reason: 'only a HOME emission consumes the one-shot',
        );
        expect(repo.selected, <String>['leo']);
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'the selection one-shot is consumed by the next home emission',
      build: () {
        repo = _RosterFake();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 40));
        bloc.add(const KidHomeProfileSelected(childId: 'leo', pinSet: false));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        // The Drift repository watches `app_state`, so `setActiveChild`
        // re-emits the home stream; `copyWithLoaded` consumes the one-shot.
        // Emulate that here by replaying the same event the subscription
        // would raise.
        bloc.add(
          KidHomeDataReceived(KidHomeData(child: maya, items: _items())),
        );
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.selectedProfileId, isNull);
        expect(bloc.state.profiles, hasLength(2), reason: 'roster survives');
      },
    );
  });

  group('K01 — profiles recovery after a failure (K01-BUG-5)', () {
    // The review's regression test, verbatim: profiles-failure → Try again
    // → profiles-recovery asserts `loaded` without a new home emission.
    // The home stream yields its childless value once and then stays
    // quiet, so the recovery MUST come from the roster.
    blocTest<KidHomeBloc, KidHomeState>(
      'Try again recovers a profiles-caused failure without a home re-emit',
      build: () {
        repo = _RosterFake()
          ..homeChildNull = true
          ..failProfiles = true;
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        repo.failProfiles = false;
        bloc.add(const KidHomeLoadRequested());
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) {
        expect(bloc.state.status, KidHomeStatus.loaded);
        expect(bloc.state.profiles.map((c) => c.id).toList(), <String>[
          'maya',
          'leo',
        ]);
        // Review finding 2: the recovery clears the stale load error.
        expect(bloc.state.errorMessage, isNull);
        expect(
          repo.homeSubscriptions,
          1,
          reason: 'the quiet home stream was never restarted',
        );
        expect(repo.profileSubscriptions, 2);
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'Try again shows loading while only the roster restarts',
      build: () {
        repo = _RosterFake()
          ..homeChildNull = true
          ..failProfiles = true;
        return KidHomeBloc(repository: repo);
      },
      // Interleaving of the first home value and the profiles error is not
      // a contract, so capture statuses instead of asserting a sequence.
      act: (bloc) async {
        final seen = <KidHomeStatus>[];
        final subscription = bloc.stream.listen((state) {
          seen.add(state.status);
        });
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        repo.failProfiles = false;
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await subscription.cancel();
        expect(
          seen.where((status) => status == KidHomeStatus.loading).length,
          2,
          reason:
              'the first load plus the Try again spinner (review finding 3: '
              'no spinner while the home stream is live left the dead card '
              'sitting with no feedback)',
        );
        expect(
          seen,
          contains(KidHomeStatus.failure),
          reason: 'the profiles outage did show the failure card first',
        );
        expect(seen.last, KidHomeStatus.loaded);
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) {
        expect(bloc.state.status, KidHomeStatus.loaded);
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'the outage flag tracks the roster stream health',
      build: () {
        repo = _RosterFake();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(bloc.state.profilesFailed, isFalse);
        repo.failRosterNow(Exception('one bad tick'));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        expect(
          bloc.state.profilesFailed,
          isTrue,
          reason: 'review finding 2: the view gates its heal on this flag',
        );
        // The error path released the subscription, so the retry re-opens
        // the stream first — a push into the dead broadcast would go
        // nowhere, exactly as in production.
        bloc.add(const KidHomeProfilesRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        repo.pushRoster(const <KidChild>[maya, leo]);
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) {
        expect(bloc.state.profilesFailed, isFalse);
        expect(bloc.state.status, KidHomeStatus.loaded);
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a home-caused failure is NOT masked by a healthy roster',
      build: () {
        repo = _RosterFake()
          ..failHome = true
          ..failProfiles = true;
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        // The home stream stays down; only the roster recovers.
        repo.failProfiles = false;
        bloc.add(const KidHomeLoadRequested());
      },
      wait: const Duration(milliseconds: 200),
      verify: (bloc) {
        expect(
          bloc.state.status,
          KidHomeStatus.failure,
          reason:
              'the home stream is still down — a recovered roster must not '
              'mask the failure card with an empty home',
        );
        expect(bloc.state.profiles, hasLength(2));
        expect(repo.homeSubscriptions, 2);
        expect(repo.profileSubscriptions, 2);
      },
    );
  });

  group('K01 — selection handled (K01-BUG-3)', () {
    // K01-BUG-6 (fixed iteration 3). The view single-flights its NAVIGATION
    // (`_navPending`), so only the first selection of a gesture burst pushes
    // a route — and since iteration 3 the bloc single-flights the WRITES the
    // same way: a selection that arrives while another is still unconsumed
    // belongs to the same burst and returns early without writing, so
    // `app_state` always names the child whose route was pushed. The pending
    // selection clears via `KidHomeSelectionHandled` (dispatched after the
    // push starts) or via the next home emission, so a genuinely later tap
    // is never dropped.
    //
    // Written as a plain `test`, not a `blocTest`: `blocTest(skip:)` takes an
    // int RETRY count, not a marker, so a bug proof there would run (and fail)
    // in the green suite.
    test(
      'K01-BUG-6: a burst persists only the child whose route is pushed',
      () async {
        final fake = _RosterFake();
        final bloc = KidHomeBloc(repository: fake);
        addTearDown(bloc.close);
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 40));
        bloc
          ..add(const KidHomeProfileSelected(childId: 'maya', pinSet: true))
          ..add(const KidHomeProfileSelected(childId: 'leo', pinSet: false));
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(
          fake.selected,
          <String>['maya'],
          reason:
              'K01-BUG-6: the picker pushes exactly one route (the first '
              'selection, here maya), so exactly one child may be persisted. '
              'Both writes landed, so the database names ${fake.selected} — '
              'the user is authenticating as maya while the app state says '
              '"${fake.selected.last}".',
        );
        expect(
          bloc.state.selectedProfileId,
          'maya',
          reason: 'the surviving selection is the first of the burst',
        );
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a burst selection dropped by single-flight leaves no trace',
      build: () {
        repo = _RosterFake();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 40));
        bloc
          ..add(const KidHomeProfileSelected(childId: 'maya', pinSet: true))
          ..add(const KidHomeProfileSelected(childId: 'leo', pinSet: false));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        // The burst is over and the view pushed Maya's route: consume it,
        // then prove the picker is usable again with a later tap.
        bloc.add(const KidHomeSelectionHandled());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const KidHomeProfileSelected(childId: 'leo', pinSet: false));
      },
      wait: const Duration(milliseconds: 200),
      verify: (bloc) {
        expect(repo.selected, <String>['maya', 'leo']);
        expect(bloc.state.selectedProfileId, 'leo');
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'handled consumes a pending selection without touching the roster',
      build: () {
        repo = _RosterFake();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 40));
        bloc.add(const KidHomeProfileSelected(childId: 'leo', pinSet: false));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const KidHomeSelectionHandled());
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) {
        expect(bloc.state.selectedProfileId, isNull);
        expect(bloc.state.profiles.map((c) => c.id).toList(), <String>[
          'maya',
          'leo',
        ]);
        expect(repo.selected, <String>['leo']);
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a re-selection after handled emits distinctly and writes again',
      build: () {
        repo = _RosterFake();
        return KidHomeBloc(repository: repo);
      },
      // Exact interleaving of the two live streams is not a contract, so
      // count the selection emissions instead of asserting a sequence:
      // without the handled event the second selection is `==`-equal and
      // the bloc drops it (the dead tile).
      act: (bloc) async {
        var selections = 0;
        final subscription = bloc.stream.listen((state) {
          if (state.selectedProfileId == 'leo') selections++;
        });
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 40));
        bloc.add(const KidHomeProfileSelected(childId: 'leo', pinSet: false));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const KidHomeSelectionHandled());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const KidHomeProfileSelected(childId: 'leo', pinSet: false));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        await subscription.cancel();
        expect(
          selections,
          2,
          reason:
              'K01-BUG-3: the same tile tapped after coming back must '
              'navigate again — the second selection must reach the view',
        );
        expect(repo.selected, <String>['leo', 'leo']);
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) {
        expect(bloc.state.selectedProfileId, 'leo');
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'handled with no pending selection emits nothing',
      build: () {
        repo = _RosterFake();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeProfilesRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const KidHomeSelectionHandled());
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _roster(<String>['maya', 'leo']),
      ],
    );

    test('the handled event and constructors are well-behaved', () {
      expect(const KidHomeSelectionHandled(), const KidHomeSelectionHandled());
      final selected = KidHomeState(
        status: KidHomeStatus.loaded,
        child: maya,
        items: _items(),
        profiles: const <KidChild>[maya, leo],
      ).copyWithSelection('leo');
      final handled = selected.copyWithSelectionHandled();
      expect(handled.selectedProfileId, isNull);
      expect(handled.profiles, hasLength(2));
      expect(handled.child?.nickname, 'Maya');
      expect(handled.items, hasLength(1));
      final recovered = const KidHomeState(
        status: KidHomeStatus.failure,
        errorMessage: 'Exception: profiles down',
      ).copyWithProfilesRecovered(const <KidChild>[maya, leo]);
      expect(recovered.status, KidHomeStatus.loaded);
      expect(recovered.errorMessage, isNull);
      expect(recovered.profiles.map((c) => c.id).toList(), <String>[
        'maya',
        'leo',
      ]);
      expect(recovered.profilesFailed, isFalse);
    });

    test('the outage flag is set on error and cleared by health', () {
      const fresh = KidHomeState();
      expect(fresh.profilesFailed, isFalse);
      final failed = fresh.copyWith(
        status: KidHomeStatus.failure,
        errorMessage: 'Exception: profiles down',
        profilesFailed: true,
      );
      expect(failed.profilesFailed, isTrue);
      // Every other constructor carries it (a dropped flag would let the
      // view heal a home-caused failure card off a stale roster).
      expect(failed.copyWith().profilesFailed, isTrue);
      expect(
        failed.copyWithLoaded(child: maya, items: _items()).profilesFailed,
        isTrue,
      );
      expect(
        failed.withCompletionFailed(Exception('x')).profilesFailed,
        isTrue,
      );
      // Any healthy roster clears it — plain receipt and recovery alike.
      expect(
        failed.copyWithProfiles(const <KidChild>[maya]).profilesFailed,
        isFalse,
      );
      expect(
        failed.copyWithProfilesRecovered(const <KidChild>[maya]).profilesFailed,
        isFalse,
      );
      // And it takes part in equality, so the view rebuilds on the flip.
      expect(failed, isNot(failed.copyWithProfiles(const <KidChild>[maya])));
    });
  });

  group('K01 — state value semantics', () {
    test('the roster and the selection both take part in equality', () {
      final base = KidHomeState(
        status: KidHomeStatus.loaded,
        child: maya,
        items: _items(),
        profiles: const <KidChild>[maya, leo],
      );
      final same = KidHomeState(
        status: KidHomeStatus.loaded,
        child: maya,
        items: _items(),
        profiles: const <KidChild>[maya, leo],
      );
      expect(base, same, reason: 'same fields ⇒ same state');
      expect(base, isNot(base.copyWithProfiles(const <KidChild>[leo])));
      expect(
        base.copyWithSelection('leo'),
        isNot(base.copyWithSelection('leo').copyWithSelection('maya')),
        reason: 'the one-shot must be part of props or the emit is swallowed',
      );
    });

    test('an empty roster is a real loaded state, never a failure', () {
      const empty = KidHomeState(status: KidHomeStatus.loaded);
      expect(empty.status, KidHomeStatus.loaded);
      expect(empty.profiles, isEmpty);
      final one = empty.copyWithProfiles(const <KidChild>[leo]);
      expect(empty, isNot(one), reason: 'a roster change rebuilds the picker');
      expect(one.profiles.single.nickname, 'Leo');
    });

    test('the picker reads every K01 field the roster carries', () {
      // The tile renders nickname, age band, avatar colour and the Pip look,
      // and the route depends on pinSet — so all of them must survive the
      // bloc round-trip unchanged.
      const state = KidHomeState(profiles: <KidChild>[maya, leo]);
      final first = state.profiles.first;
      expect(first.nickname, 'Maya');
      expect(first.ageBand, '7-9');
      expect(first.avatarColour, 'lilac');
      expect(first.pipStyle, 'mochi');
      expect(first.pipSkin, 'sunny');
      expect(first.pipAccessory, 'none');
      expect(first.pipStage, 3);
      expect(first.pinSet, isTrue);
      expect(state.profiles.last.pinSet, isFalse, reason: 'Leo has no PIN');
    });
  });
}
