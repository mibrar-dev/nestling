// K04 quest-detail BLoC paths.
//
// `quest_detail_view.dart` depends on exactly two things from the bloc, and
// both are pinned here:
//
//   1. `KidHomeLoadRequested` (dispatched by the route builder) must walk
//      initial -> loading -> loaded and expose `items`, `child`,
//      `justCompletedQuestId` / `justCompletedCoins` and the `actionError` /
//      `actionNonce` channel the view's two `BlocListener`s ride.
//   2. `KidHomeBloc.stepsFor(questId)` — the presentation-supporting getter
//      stage 2a added — must return the repository's checklist for the quest
//      the view resolved, including against the REAL seeded Drift database,
//      because the whole checklist column hangs off that one call.
//
// Stream-based fakes (rather than the in-memory DB) because bloc tests must
// exercise silence and error paths the database cannot produce; the one test
// that can run against real data — the `stepsFor` contract — does.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_home_data.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_bloc.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_event.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_state.dart';

import '../../test_scope.dart';

const KidChild _maya = KidChild(
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

KidQuest _quest({
  String id = 'q-tidy',
  String status = 'to_do',
  int coins = 15,
}) {
  return KidQuest(
    id: '$id:maya',
    title: 'Tidy your bedroom',
    detail: 'To do · +$coins',
    questId: id,
    icon: 'bed',
    coins: coins,
    status: status,
  );
}

/// The states a healthy database cannot produce. Fresh streams per
/// `watchHome()` call (like the Drift repo), so a retry after an error really
/// re-subscribes instead of reading a dead controller.
class _ScriptedRepo extends KidHomeRepository {
  // `KidHomeData.items` already defaults to an empty list, so the neutral
  // fake state is just a null child.
  _ScriptedRepo({KidHomeData? home})
    : home = home ?? const KidHomeData(child: null);

  KidHomeData home;
  bool failNext = false;
  int watchHomeCalls = 0;
  final List<String> completed = <String>[];
  bool failComplete = false;

  /// Emit a fresh home emission to whoever is subscribed.
  void push(KidHomeData next) {
    home = next;
    _pushed.add(next);
  }

  final StreamController<KidHomeData> _pushed =
      StreamController<KidHomeData>.broadcast();

  @override
  Stream<KidHomeData> watchHome() {
    watchHomeCalls++;
    if (failNext) {
      return Stream<KidHomeData>.error(Exception('home down'));
    }
    return _stream();
  }

  Stream<KidHomeData> _stream() async* {
    yield home;
    yield* _pushed.stream;
  }

  @override
  Stream<List<KidChild>> watchProfiles() => Stream<List<KidChild>>.value(
    home.child == null ? const <KidChild>[] : <KidChild>[home.child!],
  );

  @override
  List<String> stepsFor(String questId) => const <String>[
    'Clothes in the basket',
    'Toys in the box',
    'Books on the shelf',
  ];

  @override
  Future<void> completeQuest(String childId, String questId) async {
    completed.add(questId);
    if (failComplete) throw Exception('save failed');
    push(
      KidHomeData(
        child: home.child,
        items: <KidQuest>[
          for (final quest in home.items)
            if (quest.questId == questId)
              _quest(
                id: quest.questId,
                status: 'done_pending',
                coins: quest.coins,
              )
            else
              quest,
        ],
      ),
    );
  }

  @override
  Future<List<KidQuest>> getItems() async => home.items;

  @override
  Stream<List<KidQuest>> watchItems() =>
      Stream<List<KidQuest>>.value(home.items);

  @override
  Stream<KidChild?> watchActiveChild() => Stream<KidChild?>.value(home.child);

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> setActiveChild(String childId) async {}
}

void main() {
  setUp(() async {
    await setUpTestScope();
  });

  group('K04 — the load the route dispatches', () {
    blocTest<KidHomeBloc, KidHomeState>(
      'LoadRequested walks initial -> loading -> loaded with the quest',
      build: () => KidHomeBloc(
        repository: _ScriptedRepo(
          home: KidHomeData(child: _maya, items: <KidQuest>[_quest()]),
        ),
      ),
      act: (bloc) => bloc.add(const KidHomeLoadRequested()),
      wait: const Duration(milliseconds: 20),
      // Three emissions, not two: `_onLoadRequested` starts BOTH subscriptions
      // (home + profiles, per the review finding 3 fix), so the roster lands as
      // its own distinct state after the home data. Both keep `loaded`, which
      // is why the view's `loaded` branch is stable across the arrival.
      expect: () => <Matcher>[
        isA<KidHomeState>().having(
          (s) => s.status,
          'status',
          KidHomeStatus.loading,
        ),
        isA<KidHomeState>()
            .having((s) => s.status, 'status', KidHomeStatus.loaded)
            .having((s) => s.child?.id, 'child', 'maya')
            .having((s) => s.items.length, 'items', 1)
            .having((s) => s.items.first.questId, 'questId', 'q-tidy')
            .having((s) => s.items.first.coins, 'coins', 15),
        isA<KidHomeState>()
            .having((s) => s.status, 'status', KidHomeStatus.loaded)
            .having((s) => s.profiles.length, 'profiles', 1)
            .having((s) => s.profiles.first.id, 'profile order', 'maya'),
      ],
    );

    test('the load guard ignores a reload while the stream is live', () async {
      // K03-BUG-15: `watchHome()` never completes and the transformer is
      // concurrent, so an unguarded reload would stack a second never-ending
      // handler with its own fan-out of Drift watch queries per tap.
      final repo = _ScriptedRepo(
        home: KidHomeData(child: _maya, items: <KidQuest>[_quest()]),
      );
      final bloc = KidHomeBloc(repository: repo);
      addTearDown(bloc.close);

      bloc.add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      bloc.add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(repo.watchHomeCalls, 1);
      expect(bloc.state.status, KidHomeStatus.loaded);
    });

    test('a load after a stream failure really re-subscribes', () async {
      // The K04 failure card's "Try again" dispatches exactly this event, so a
      // swallowed retry would leave the child stuck on "Oh no! Pip got lost."
      final repo = _ScriptedRepo()..failNext = true;
      final bloc = KidHomeBloc(repository: repo);
      addTearDown(bloc.close);

      bloc.add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.status, KidHomeStatus.failure);

      repo
        ..failNext = false
        ..push(KidHomeData(child: _maya, items: <KidQuest>[_quest()]));
      bloc.add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(repo.watchHomeCalls, 2);
      expect(bloc.state.status, KidHomeStatus.loaded);
      expect(bloc.state.child?.id, 'maya');
    });
  });

  group('K04 — the completion channel the celebration rides', () {
    blocTest<KidHomeBloc, KidHomeState>(
      'QuestCompleted celebrates once, on the stream flip',
      build: () => KidHomeBloc(
        repository: _ScriptedRepo(
          home: KidHomeData(child: _maya, items: <KidQuest>[_quest()]),
        ),
      ),
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(
          const KidHomeQuestCompleted(
            childId: 'maya',
            questId: 'q-tidy',
            coins: 15,
          ),
        );
      },
      wait: const Duration(milliseconds: 40),
      verify: (bloc) {
        // `justCompletedQuestId` is the ONE-SHOT the view pushes
        // `/quest-complete` on, and `coins` rides into the route extra.
        expect(bloc.state.justCompletedQuestId, 'q-tidy');
        expect(bloc.state.justCompletedCoins, 15);
        expect(bloc.state.items.first.status, 'done_pending');
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a failing write raises actionError and bumps actionNonce, and a retry '
      'then succeeds',
      build: () {
        final repo = _ScriptedRepo(
          home: KidHomeData(child: _maya, items: <KidQuest>[_quest()]),
        )..failComplete = true;
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(
          const KidHomeQuestCompleted(
            childId: 'maya',
            questId: 'q-tidy',
            coins: 15,
          ),
        );
      },
      wait: const Duration(milliseconds: 40),
      verify: (bloc) {
        expect(bloc.state.actionError, isNotNull);
        expect(bloc.state.actionNonce, greaterThan(0));
        // No celebration on a failed write: the view toasts and stays.
        expect(bloc.state.justCompletedQuestId, isNull);
        expect(bloc.state.items.first.status, 'to_do');
      },
    );

    test(
      'a quest that vanishes mid-flight never celebrates a recycled id',
      () async {
        // K03-BUG-11: the awaiting entry is evicted when the quest leaves the
        // list, so a later quest reusing the id cannot celebrate a dead tap.
        final repo = _ScriptedRepo(
          home: KidHomeData(child: _maya, items: <KidQuest>[_quest()]),
        );
        final bloc = KidHomeBloc(repository: repo);
        addTearDown(bloc.close);

        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        repo.failComplete = true;
        bloc.add(
          const KidHomeQuestCompleted(
            childId: 'maya',
            questId: 'q-tidy',
            coins: 15,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        // Drop the quest, then bring a DIFFERENT done quest back on a fresh id.
        repo.push(const KidHomeData(child: _maya));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        repo.push(
          const KidHomeData(
            child: _maya,
            items: <KidQuest>[
              KidQuest(
                id: 'q-other:maya',
                title: 'Tidy your bedroom',
                detail: 'Done · +15',
                questId: 'q-other',
                icon: 'bed',
                coins: 15,
                status: 'approved',
              ),
            ],
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(bloc.state.justCompletedQuestId, isNull);
      },
    );
  });

  group('K04 — the stepsFor seam (the view has no other source)', () {
    test('the bloc delegates to the repository', () async {
      final bloc = KidHomeBloc(repository: _ScriptedRepo());
      addTearDown(bloc.close);
      expect(bloc.stepsFor('q-tidy'), <String>[
        'Clothes in the basket',
        'Toys in the box',
        'Books on the shelf',
      ]);
      // Pure function of the id in v1, but the contract the view relies on is
      // that it never throws for an id it was handed.
      expect(() => bloc.stepsFor('q-unknown'), returnsNormally);
    });

    test('against the real seeded database it returns the q-tidy checklist', () async {
      // The one assertion here that uses production data: the checklist column
      // the view renders must be the seeded one, in seed order.
      final bloc = KidHomeBloc(repository: GetIt.instance<KidHomeRepository>());
      addTearDown(bloc.close);
      expect(bloc.stepsFor('q-tidy'), <String>[
        'Clothes in the basket',
        'Toys in the box',
        'Books on the shelf',
      ]);
    });

    test('it is readable before any load event', () async {
      // The view calls `context.read<KidHomeBloc>().stepsFor(...)` inside its
      // builder; it must not depend on load state.
      final bloc = KidHomeBloc(repository: _ScriptedRepo());
      addTearDown(bloc.close);
      expect(bloc.state.status, KidHomeStatus.initial);
      expect(bloc.stepsFor('q-tidy'), isNotEmpty);
    });
  });
}
