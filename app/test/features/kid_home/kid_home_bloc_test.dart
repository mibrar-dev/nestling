// K03 bloc tests: every KidHomeEvent/state path over a controllable fake
// repository, plus value semantics for the shared state object.
//
// The fake hands out FRESH streams per call (like the Drift repo does), so
// retry-after-failure and live re-emission behave like production. It is a
// stream-based fake rather than the in-memory DB because bloc tests exercise
// error and silence paths the database cannot produce.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_bloc.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_event.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_state.dart';

const KidChild _maya = KidChild(
  id: 'maya',
  nickname: 'Maya',
  avatarColour: 'lilac',
  coins: 120,
  pipStyle: 'mochi',
  pipSkin: 'sunny',
  pipAccessory: 'none',
  pipStage: 3,
  happiness: 4,
  pinSet: true,
);

/// Maya's 6 quests in repo (alphabetical) order with demo statuses:
/// 4 done (2 approved + 2 done_pending), 2 to_do.
List<KidQuest> _mayaItems() => const <KidQuest>[
  KidQuest(
    id: 'q-bins:maya',
    title: 'Put the bins out',
    detail: 'Done · +15',
    questId: 'q-bins',
    icon: 'bins',
    coins: 15,
    status: 'approved',
  ),
  KidQuest(
    id: 'q-dishwasher:maya',
    title: 'Empty the dishwasher',
    detail: 'Waiting for Mum\u2019s thumbs-up · +15',
    questId: 'q-dishwasher',
    icon: 'dishwasher',
    coins: 15,
    status: 'done_pending',
  ),
  KidQuest(
    id: 'q-hoover:maya',
    title: 'Hoover the stairs',
    detail: 'Done · +20',
    questId: 'q-hoover',
    icon: 'hoover',
    coins: 20,
    status: 'approved',
  ),
  KidQuest(
    id: 'q-table:maya',
    title: 'Lay the table',
    detail: 'Waiting for Mum\u2019s thumbs-up · +10',
    questId: 'q-table',
    icon: 'plate',
    coins: 10,
    status: 'done_pending',
  ),
  KidQuest(
    id: 'q-reading:maya',
    title: 'Reading – 20 minutes',
    detail: 'To do · +10',
    questId: 'q-reading',
    icon: 'book',
    coins: 10,
    status: 'to_do',
  ),
  KidQuest(
    id: 'q-tidy:maya',
    title: 'Tidy your bedroom',
    detail: 'To do · +15',
    questId: 'q-tidy',
    icon: 'bed',
    coins: 15,
    status: 'to_do',
  ),
];

KidQuest _quest(String questId, String status) => KidQuest(
  id: '$questId:maya',
  title: '$questId title',
  detail: status,
  questId: questId,
  icon: 'book',
  coins: 10,
  status: status,
);

KidQuest _withStatus(KidQuest quest, String status) => KidQuest(
  id: quest.id,
  title: quest.title,
  detail: quest.detail,
  questId: quest.questId,
  icon: quest.icon,
  coins: quest.coins,
  status: status,
);

Matcher _loaded({
  String nickname = 'Maya',
  int? done,
  int? total,
  bool nullChild = false,
}) {
  return predicate<KidHomeState>((state) {
    if (state.status != KidHomeStatus.loaded) {
      return false;
    }
    if (nullChild ? state.child != null : state.child?.nickname != nickname) {
      return false;
    }
    if (done != null && state.doneCount != done) {
      return false;
    }
    if (total != null && state.totalCount != total) {
      return false;
    }
    if (total != null && total > 0) {
      final expected = (done ?? state.doneCount) / total;
      if ((state.fraction - expected).abs() > 0.001) {
        return false;
      }
    }
    return true;
  });
}

final Matcher _loading = predicate<KidHomeState>(
  (state) => state.status == KidHomeStatus.loading,
);

final Matcher _failure = predicate<KidHomeState>(
  (state) =>
      state.status == KidHomeStatus.failure && state.errorMessage != null,
);

/// Loaded with a completion failure recorded (list kept, error surfaced).
final Matcher _failed = predicate<KidHomeState>(
  (state) =>
      state.status == KidHomeStatus.loaded &&
      state.doneCount == 4 &&
      state.actionError != null,
);

/// Loaded with no pending completion outcome (a retry reset the error).
final Matcher _reset = predicate<KidHomeState>(
  (state) =>
      state.status == KidHomeStatus.loaded &&
      state.doneCount == 4 &&
      state.actionError == null &&
      state.justCompletedQuestId == null,
);

/// Loaded with the celebration signal for [questId].
Matcher _celebrating(String questId, {int? coins}) =>
    predicate<KidHomeState>((state) {
      if (state.status != KidHomeStatus.loaded) {
        return false;
      }
      if (state.justCompletedQuestId != questId) {
        return false;
      }
      return coins == null || state.justCompletedCoins == coins;
    });

/// Controllable fake: fresh streams per call, pushable updates, injectable
/// error and silence modes, and a record of `completeQuest` calls.
class _FakeKidHomeRepository implements KidHomeRepository {
  _FakeKidHomeRepository({KidChild? child, List<KidQuest>? items})
    : child = child ?? _maya,
      _items = items ?? _mayaItems();

  KidChild? child;
  List<KidQuest> _items;

  /// The items watch stream errors on listen (load-failure path). Only one
  /// source errors so the bloc surfaces a single failure state, like a real
  /// query failure.
  bool failLoad = false;

  /// [completeQuest] throws (actionError path).
  bool failComplete = false;

  /// [completeQuest] records the call but leaves the stream alone (e.g. the
  /// quest was already approved elsewhere), so nothing flips.
  bool completeIsNoop = false;

  /// Watch streams never emit (loading path).
  bool hang = false;

  final List<List<String>> completed = <List<String>>[];
  final StreamController<List<KidQuest>> _itemsPushed =
      StreamController<List<KidQuest>>.broadcast();
  final StreamController<KidChild?> _childPushed =
      StreamController<KidChild?>.broadcast();

  List<KidQuest> get items => _items;

  void pushItems(List<KidQuest> value) {
    _items = value;
    _itemsPushed.add(value);
  }

  void pushChild(KidChild? value) {
    child = value;
    _childPushed.add(value);
  }

  @override
  Future<List<KidQuest>> getItems() async => _items;

  @override
  Stream<List<KidQuest>> watchItems() async* {
    if (hang) {
      return;
    }
    if (failLoad) {
      throw Exception('items down');
    }
    yield _items;
    yield* _itemsPushed.stream;
  }

  @override
  Stream<List<KidChild>> watchProfiles() async* {
    final kid = child;
    yield <KidChild>[?kid];
  }

  @override
  Stream<KidChild?> watchActiveChild() async* {
    if (hang) {
      return;
    }
    yield child;
    yield* _childPushed.stream;
  }

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> completeQuest(String childId, String questId) async {
    completed.add(<String>[childId, questId]);
    if (failComplete) {
      throw Exception('save failed');
    }
    if (completeIsNoop) {
      return;
    }
    pushItems(<KidQuest>[
      for (final KidQuest quest in _items)
        if (quest.questId == questId)
          _withStatus(quest, 'done_pending')
        else
          quest,
    ]);
  }
}

void main() {
  group('KidHomeState', () {
    test('defaults are idle and empty', () {
      const state = KidHomeState();
      expect(state.status, KidHomeStatus.initial);
      expect(state.child, isNull);
      expect(state.items, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.actionError, isNull);
      expect(state.doneCount, 0);
      expect(state.totalCount, 0);
      expect(state.fraction, 0);
    });

    test('done counts approved and done_pending only', () {
      final state = KidHomeState(
        items: <KidQuest>[
          _quest('a', 'approved'),
          _quest('b', 'done_pending'),
          _quest('c', 'not_yet'),
          _quest('d', 'to_do'),
        ],
      );
      expect(state.doneCount, 2);
      expect(state.totalCount, 4);
      expect(state.fraction, 0.5);
    });

    test('copyWith keeps the child; copyWithLoaded can clear it', () {
      final state = KidHomeState(
        status: KidHomeStatus.loaded,
        child: _maya,
        items: _mayaItems(),
      );
      expect(state.copyWith(status: KidHomeStatus.loading).child, _maya);
      final cleared = state.copyWithLoaded(
        child: null,
        items: const <KidQuest>[],
      );
      expect(cleared.status, KidHomeStatus.loaded);
      expect(cleared.child, isNull);
      expect(cleared.items, isEmpty);
      expect(cleared.fraction, 0);
    });

    test('states with the same fields are equal', () {
      const a = KidHomeState(status: KidHomeStatus.loading);
      const b = KidHomeState(status: KidHomeStatus.loading);
      const c = KidHomeState(status: KidHomeStatus.failure);
      expect(a, b);
      expect(a, isNot(c));
    });

    test('KidHomeQuestCompleted equality covers every field', () {
      const a = KidHomeQuestCompleted(
        childId: 'maya',
        questId: 'q-reading',
        coins: 10,
      );
      const b = KidHomeQuestCompleted(
        childId: 'maya',
        questId: 'q-reading',
        coins: 10,
      );
      const differentCoins = KidHomeQuestCompleted(
        childId: 'maya',
        questId: 'q-reading',
        coins: 15,
      );
      const differentQuest = KidHomeQuestCompleted(
        childId: 'maya',
        questId: 'q-tidy',
        coins: 10,
      );
      const differentChild = KidHomeQuestCompleted(
        childId: 'leo',
        questId: 'q-reading',
        coins: 10,
      );
      expect(a, b);
      expect(a, isNot(differentCoins));
      expect(a, isNot(differentQuest));
      expect(a, isNot(differentChild));
    });

    test('completion outcomes are explicit and nonce-bumped', () {
      final base = KidHomeState(
        status: KidHomeStatus.loaded,
        child: _maya,
        items: _mayaItems(),
      );
      final success = base.withCompletionSucceeded(
        questId: 'q-reading',
        coins: 10,
      );
      expect(success.status, KidHomeStatus.loaded);
      expect(success.child, _maya);
      expect(success.items, _mayaItems());
      expect(success.justCompletedQuestId, 'q-reading');
      expect(success.justCompletedCoins, 10);
      expect(success.actionError, isNull);

      final first = base.withCompletionFailed(Exception('save failed'));
      final second = first.withCompletionFailed(Exception('save failed'));
      expect(first.actionError, 'Exception: save failed');
      expect(first.actionNonce, 1);
      expect(second.actionNonce, 2);
      expect(first, isNot(second));
      expect(first.justCompletedQuestId, isNull);

      final started = first.withCompletionStarted();
      expect(started.actionError, isNull);
      expect(started.actionNonce, 0);
      expect(started.items, base.items);
    });

    test('copyWithLoaded clears transient completion outcomes', () {
      final state = KidHomeState(
        status: KidHomeStatus.loaded,
        child: _maya,
        items: _mayaItems(),
        actionError: 'Exception: save failed',
        actionNonce: 2,
        justCompletedQuestId: 'q-reading',
        justCompletedCoins: 10,
      );
      final reloaded = state.copyWithLoaded(child: _maya, items: _mayaItems());
      expect(reloaded.actionError, isNull);
      expect(reloaded.actionNonce, 0);
      expect(reloaded.justCompletedQuestId, isNull);
      expect(reloaded.justCompletedCoins, isNull);
    });
  });

  group('KidHomeBloc', () {
    late _FakeKidHomeRepository repo;

    blocTest<KidHomeBloc, KidHomeState>(
      'load emits loading then loaded with Maya and 4 of 6 done',
      build: () {
        repo = _FakeKidHomeRepository();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const KidHomeLoadRequested()),
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[_loading, _loaded(done: 4, total: 6)],
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'load mirrors live items and child stream updates',
      build: () {
        repo = _FakeKidHomeRepository();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        repo.pushItems(<KidQuest>[
          for (final KidQuest quest in repo.items)
            if (quest.questId == 'q-reading')
              _withStatus(quest, 'done_pending')
            else
              quest,
        ]);
        await Future<void>.delayed(const Duration(milliseconds: 20));
        repo.pushChild(null);
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading,
        _loaded(done: 4, total: 6),
        _loaded(done: 5, total: 6),
        _loaded(done: 5, total: 6, nullChild: true),
      ],
      verify: (bloc) => expect(bloc.state.child, isNull),
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'loaded child with no quests yields zero counts',
      build: () {
        repo = _FakeKidHomeRepository(items: const <KidQuest>[]);
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const KidHomeLoadRequested()),
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[_loading, _loaded(done: 0, total: 0)],
      verify: (bloc) => expect(bloc.state.fraction, 0),
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'silent streams keep the screen loading',
      build: () {
        repo = _FakeKidHomeRepository()..hang = true;
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const KidHomeLoadRequested()),
      wait: const Duration(milliseconds: 50),
      expect: () => <Matcher>[_loading],
      verify: (bloc) => expect(bloc.state.child, isNull),
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'load failure emits failure with errorMessage',
      build: () {
        repo = _FakeKidHomeRepository()..failLoad = true;
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const KidHomeLoadRequested()),
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[_loading, _failure],
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'failure is followed by a successful retry load',
      build: () {
        repo = _FakeKidHomeRepository()..failLoad = true;
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        repo.failLoad = false;
        bloc.add(const KidHomeLoadRequested());
      },
      wait: const Duration(milliseconds: 150),
      expect: () => <Matcher>[
        _loading,
        _failure,
        _loading,
        _loaded(done: 4, total: 6),
      ],
      verify: (bloc) {
        expect(bloc.state.status, KidHomeStatus.loaded);
        // Review finding 5: a healthy stream clears the stale load error.
        expect(bloc.state.errorMessage, isNull);
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'check tap completes the quest and the flip streams back in',
      build: () {
        repo = _FakeKidHomeRepository();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(
          const KidHomeQuestCompleted(
            childId: 'maya',
            questId: 'q-reading',
            coins: 10,
          ),
        );
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading,
        _loaded(done: 4, total: 6),
        // The celebration signal rides the flip emission itself.
        _celebrating('q-reading', coins: 10),
      ],
      verify: (bloc) {
        expect(repo.completed, <List<String>>[
          <String>['maya', 'q-reading'],
        ]);
        expect(
          repo.items
              .singleWhere((quest) => quest.questId == 'q-reading')
              .status,
          'done_pending',
        );
        expect(bloc.state.doneCount, 5);
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'the celebration signal clears on the next stream emission',
      build: () {
        repo = _FakeKidHomeRepository();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(
          const KidHomeQuestCompleted(
            childId: 'maya',
            questId: 'q-reading',
            coins: 10,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        // A healthy emission that does not change the data still consumes
        // the one-shot signal, so the view cannot celebrate twice.
        repo.pushItems(repo.items);
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading,
        _loaded(done: 4, total: 6),
        _celebrating('q-reading', coins: 10),
        predicate<KidHomeState>(
          (state) =>
              state.status == KidHomeStatus.loaded &&
              state.doneCount == 5 &&
              state.justCompletedQuestId == null,
        ),
      ],
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a completion that does not flip the card never celebrates',
      build: () {
        repo = _FakeKidHomeRepository()..completeIsNoop = true;
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(
          const KidHomeQuestCompleted(
            childId: 'maya',
            questId: 'q-reading',
            coins: 10,
          ),
        );
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[_loading, _loaded(done: 4, total: 6)],
      verify: (bloc) {
        expect(repo.completed, hasLength(1));
        expect(bloc.state.justCompletedQuestId, isNull);
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'completion failure keeps the list and records actionError',
      build: () {
        repo = _FakeKidHomeRepository()..failComplete = true;
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(
          const KidHomeQuestCompleted(
            childId: 'maya',
            questId: 'q-reading',
            coins: 10,
          ),
        );
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, KidHomeStatus.loaded);
        expect(bloc.state.child?.id, 'maya');
        expect(bloc.state.items, hasLength(6));
        expect(bloc.state.doneCount, 4);
        expect(bloc.state.actionError, contains('save failed'));
        expect(bloc.state.actionNonce, 1);
        expect(bloc.state.justCompletedQuestId, isNull);
        expect(bloc.state.errorMessage, isNull);
        expect(
          repo.items
              .singleWhere((quest) => quest.questId == 'q-reading')
              .status,
          'to_do',
        );
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'two identical failures both surface (reset between attempts)',
      build: () {
        repo = _FakeKidHomeRepository()..failComplete = true;
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(
          const KidHomeQuestCompleted(
            childId: 'maya',
            questId: 'q-reading',
            coins: 10,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(
          const KidHomeQuestCompleted(
            childId: 'maya',
            questId: 'q-reading',
            coins: 10,
          ),
        );
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading,
        _loaded(done: 4, total: 6),
        _failed,
        // The second attempt resets the previous outcome first, so the
        // repeat failure is a distinct state and is announced again.
        _reset,
        _failed,
      ],
      verify: (bloc) => expect(repo.completed, hasLength(2)),
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'retry after a failure clears the error and celebrates on success',
      build: () {
        repo = _FakeKidHomeRepository()..failComplete = true;
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(
          const KidHomeQuestCompleted(
            childId: 'maya',
            questId: 'q-reading',
            coins: 10,
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        repo.failComplete = false;
        bloc.add(
          const KidHomeQuestCompleted(
            childId: 'maya',
            questId: 'q-reading',
            coins: 10,
          ),
        );
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading,
        _loaded(done: 4, total: 6),
        _failed,
        _reset,
        _celebrating('q-reading', coins: 10),
      ],
      verify: (bloc) {
        expect(repo.completed, hasLength(2));
        expect(bloc.state.actionError, isNull);
        expect(bloc.state.doneCount, 5);
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'completion before a load still reaches the repository',
      build: () {
        repo = _FakeKidHomeRepository();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) => bloc.add(
        const KidHomeQuestCompleted(
          childId: 'maya',
          questId: 'q-tidy',
          coins: 15,
        ),
      ),
      wait: const Duration(milliseconds: 50),
      expect: () => const <Matcher>[],
      verify: (_) => expect(repo.completed, <List<String>>[
        <String>['maya', 'q-tidy'],
      ]),
    );
  });
}
