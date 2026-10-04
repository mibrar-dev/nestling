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
  /// Fail the next [watchProfiles] listen (a roster that cannot be read).
  bool failProfiles = false;

  int profileSubscriptions = 0;
  int homeSubscriptions = 0;
  final List<String> selected = <String>[];

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
    yield KidHomeData(child: maya, items: _items());
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
