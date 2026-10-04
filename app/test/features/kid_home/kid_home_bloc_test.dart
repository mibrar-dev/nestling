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
import 'package:nestling/features/kid_home/domain/entities/kid_home_data.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_bloc.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_event.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_state.dart';

const KidChild _leo = KidChild(
  id: 'leo',
  nickname: 'Leo',
  ageBand: '4-6',
  avatarColour: 'mint',
  coins: 60,
  pipStyle: 'bolt',
  pipSkin: 'sky',
  pipAccessory: 'none',
  pipStage: 2,
  happiness: 3,
  pinSet: true,
);

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
    detail: "Waiting for Mum's thumbs-up · +15",
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
    detail: "Waiting for Mum's thumbs-up · +10",
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

/// Loading with the K01 roster already arrived: on a fresh load the
/// profiles stream emits before the combined home stream, so every load
/// passes through `loading` (empty roster) then `loading` (roster shown)
/// before `loaded`. Named so the sequence reads deliberately.
final Matcher _loadingWithProfiles = predicate<KidHomeState>(
  (state) =>
      state.status == KidHomeStatus.loading && state.profiles.length == 2,
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
class _FakeKidHomeRepository extends KidHomeRepository {
  _FakeKidHomeRepository({KidChild? child, List<KidQuest>? items})
    : child = child ?? _maya,
      _items = items ?? _mayaItems();

  KidChild? child;
  List<KidQuest> _items;

  /// K01 roster in creation order (Maya, then Leo — never re-sorted).
  List<KidChild> profiles = <KidChild>[_maya, _leo];

  /// The items watch stream errors on listen (load-failure path). Only one
  /// source errors so the bloc surfaces a single failure state, like a real
  /// query failure.
  bool failLoad = false;

  /// The profiles watch stream errors on listen (profiles-load failure).
  bool failProfiles = false;

  /// [setActiveChild] throws (selection actionError path).
  bool failSelect = false;

  /// [completeQuest] throws (actionError path).
  bool failComplete = false;

  /// [completeQuest] records the call but leaves the stream alone (e.g. the
  /// quest was already approved elsewhere), so nothing flips.
  bool completeIsNoop = false;

  /// K02 PIN: the code that verifies (Maya's demo PIN `1234`).
  String correctPin = '1234';

  /// [verifyPin] throws (wrong-PIN path, stream stays healthy).
  bool failVerify = false;

  /// When set, [verifyPin] waits on this gate before answering, so a second
  /// submit can land mid-check (re-entry guard test).
  Completer<bool>? verifyGate;

  /// Every `verifyPin` call as [childId, pin] pairs.
  final List<List<String>> verified = <List<String>>[];

  /// Watch streams never emit (loading path).
  bool hang = false;

  final List<List<String>> completed = <List<String>>[];
  final List<String> selected = <String>[];
  final StreamController<List<KidQuest>> _itemsPushed =
      StreamController<List<KidQuest>>.broadcast();
  final StreamController<KidChild?> _childPushed =
      StreamController<KidChild?>.broadcast();
  final StreamController<List<KidChild>> _profilesPushed =
      StreamController<List<KidChild>>.broadcast();

  /// Subscription counts (review finding 4, iteration 5): a load must watch
  /// the child row exactly once, no matter how many list updates follow.
  int activeChildSubscriptions = 0;
  int itemsSubscriptions = 0;

  List<KidQuest> get items => _items;

  void pushItems(List<KidQuest> value) {
    _items = value;
    _itemsPushed.add(value);
  }

  void pushChild(KidChild? value) {
    child = value;
    _childPushed.add(value);
  }

  void pushProfiles(List<KidChild> value) {
    profiles = value;
    _profilesPushed.add(value);
  }

  /// Fails the live profiles stream mid-session: with a roster already
  /// shown the list must be kept, like the items mid-session probe below.
  void failProfilesNow(Object error) {
    _profilesPushed.addError(error);
  }

  /// Fails the live items stream mid-session (review finding 6,
  /// iteration 7): a single bad watch tick must not discard the list.
  void failItemsNow(Object error) {
    _itemsPushed.addError(error);
  }

  @override
  Future<List<KidQuest>> getItems() async => _items;

  @override
  Stream<List<KidQuest>> watchItems() async* {
    itemsSubscriptions++;
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
    if (hang) {
      return;
    }
    if (failProfiles) {
      throw Exception('profiles down');
    }
    yield profiles;
    yield* _profilesPushed.stream;
  }

  @override
  Stream<KidChild?> watchActiveChild() async* {
    activeChildSubscriptions++;
    if (hang) {
      return;
    }
    yield child;
    yield* _childPushed.stream;
  }

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async {
    verified.add(<String>[childId, pin]);
    if (failVerify) {
      throw Exception('pin store down');
    }
    final gate = verifyGate;
    if (gate != null) {
      await gate.future;
    }
    return pin == correctPin;
  }

  @override
  Future<void> setActiveChild(String childId) async {
    selected.add(childId);
    if (failSelect) {
      throw Exception('select failed');
    }
  }

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
      expect: () => <Matcher>[
        _loading,
        _loadingWithProfiles,
        _loaded(done: 4, total: 6),
      ],
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
        _loadingWithProfiles,
        _loaded(done: 4, total: 6),
        _loaded(done: 5, total: 6),
        // A cleared child arrives WITH an empty list (atomic home emission),
        // never paired with the previous child's quests.
        _loaded(done: 0, total: 0, nullChild: true),
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
      expect: () => <Matcher>[
        _loading,
        _loadingWithProfiles,
        _loaded(done: 0, total: 0),
      ],
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
      expect: () => <Matcher>[_loading, _loadingWithProfiles, _failure],
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
        _loadingWithProfiles,
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
        _loadingWithProfiles,
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
        _loadingWithProfiles,
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
      expect: () => <Matcher>[
        _loading,
        _loadingWithProfiles,
        _loaded(done: 4, total: 6),
      ],
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
        _loadingWithProfiles,
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
        _loadingWithProfiles,
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

    blocTest<KidHomeBloc, KidHomeState>(
      'a load watches the child row exactly once (finding 4, iteration 5)',
      build: () {
        repo = _FakeKidHomeRepository();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        // A list update must not open a second child subscription.
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
      verify: (bloc) {
        expect(
          repo.activeChildSubscriptions,
          1,
          reason: 'the child row is watched once per load, not twice',
        );
        expect(bloc.state.child, isNull);
        expect(bloc.state.doneCount, 0);
      },
    );

    test(
      'watchHome default emits the child together with their quests',
      () async {
        final repo = _FakeKidHomeRepository();
        final home = await repo.watchHome().first;
        expect(home, KidHomeData(child: _maya, items: _mayaItems()));
        expect(home.child?.nickname, 'Maya');
        expect(home.items, hasLength(6));
      },
    );

    // K03-BUG-15 (fixed iteration 8): `_onLoadRequested` guards on the live
    // home subscription, so the failure state's "Try again" cannot stack a
    // second never-ending handler while the first is still subscribed.
    // The review's smaller fix: early-return while a subscription is live
    // (released on error and on close, so retries still work).
    test(
      'K03-BUG-15: a retry must not stack a second live subscription',
      () async {
        final repo = _FakeKidHomeRepository();
        final bloc = KidHomeBloc(repository: repo);
        final sub = bloc.stream.listen((_) {});
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 30));
        // Two retries while the first load is still streaming.
        bloc
          ..add(const KidHomeLoadRequested())
          ..add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 60));
        expect(
          repo.activeChildSubscriptions,
          1,
          reason:
              'the child row must be watched once per load; every extra '
              'handler keeps a whole watch fan-out alive',
        );
        expect(
          repo.itemsSubscriptions,
          1,
          reason: 'same for the quest list stream',
        );
        await sub.cancel();
        await bloc.close();
      },
    );

    // The guard must not become a wedge: the subscription is released when
    // the stream fails, so the failure card's "Try again" really reloads.
    test('a retry after a stream failure opens a fresh subscription', () async {
      final repo = _FakeKidHomeRepository()..failLoad = true;
      final bloc = KidHomeBloc(repository: repo);
      final sub = bloc.stream.listen((_) {});
      bloc.add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(bloc.state.status, KidHomeStatus.failure);
      expect(bloc.state.errorMessage, isNotNull);
      expect(repo.activeChildSubscriptions, 1);

      repo.failLoad = false;
      bloc.add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(
        repo.activeChildSubscriptions,
        2,
        reason:
            'the failed subscription must be released on error, otherwise '
            '"Try again" would be ignored and the card is a dead end',
      );
      expect(bloc.state.status, KidHomeStatus.loaded);
      expect(bloc.state.child?.nickname, 'Maya');
      await sub.cancel();
      await bloc.close();
    });

    // …and it must not need a reload to follow the active child: the live
    // `watchHome()` stream already re-emits on an `app_state` change, which is
    // what the K01 picker relies on when it returns to this screen.
    test('a child switch on the live stream needs no reload', () async {
      final repo = _FakeKidHomeRepository();
      final bloc = KidHomeBloc(repository: repo);
      final sub = bloc.stream.listen((_) {});
      bloc.add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(bloc.state.child?.nickname, 'Maya');

      repo.pushChild(_leo);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(
        bloc.state.child?.nickname,
        'Leo',
        reason: 'the live stream follows the active child on its own',
      );
      expect(bloc.state.items, isNotEmpty);

      // The router re-dispatches a load after the picker returns; the guard
      // ignores it and the screen keeps the child the stream already gave.
      bloc.add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(
        repo.activeChildSubscriptions,
        1,
        reason: 'the ignored reload must not open a second subscription',
      );
      expect(bloc.state.child?.nickname, 'Leo');
      await sub.cancel();
      await bloc.close();
    });

    blocTest<KidHomeBloc, KidHomeState>(
      'two completion taps one frame apart celebrate exactly once',
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
        // Second tap lands a frame later, after the card already flipped.
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
        _loadingWithProfiles,
        _loaded(done: 4, total: 6),
        _celebrating('q-reading', coins: 10),
        // Already done on arrival: no second celebration, list kept.
        predicate<KidHomeState>(
          (state) =>
              state.status == KidHomeStatus.loaded &&
              state.doneCount == 5 &&
              state.justCompletedQuestId == null,
        ),
      ],
      verify: (bloc) {
        // Both taps reach the repository (its transaction dedupes the row —
        // K03-BUG-1 proves the single `done_pending` row); the bloc
        // celebrates only the first.
        expect(repo.completed, hasLength(2));
        expect(bloc.state.doneCount, 5);
        expect(bloc.state.justCompletedQuestId, isNull);
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a mid-session stream error keeps the loaded list',
      build: () {
        repo = _FakeKidHomeRepository();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        repo.failItemsNow(Exception('one bad tick'));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading,
        _loadingWithProfiles,
        _loaded(done: 4, total: 6),
        // No failure card: the child keeps the list they were looking at.
        predicate<KidHomeState>(
          (state) =>
              state.status == KidHomeStatus.loaded &&
              state.child?.nickname == 'Maya' &&
              state.doneCount == 4 &&
              state.totalCount == 6,
        ),
      ],
      verify: (bloc) {
        expect(bloc.state.status, KidHomeStatus.loaded);
        expect(bloc.state.items, hasLength(6));
      },
    );
  });

  group('K01 profiles (picker roster + selection)', () {
    late _FakeKidHomeRepository repo;

    blocTest<KidHomeBloc, KidHomeState>(
      'load delivers the roster Maya-first alongside the home',
      build: () {
        repo = _FakeKidHomeRepository();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const KidHomeLoadRequested()),
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.profiles.map((child) => child.id).toList(), <String>[
          'maya',
          'leo',
        ], reason: 'children are listed in creation order, never alphabetical');
        expect(bloc.state.profiles.first.ageBand, '7-9');
        expect(bloc.state.profiles.last.ageBand, '4-6');
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a profiles-only retry while home is live restarts just that stream',
      build: () {
        repo = _FakeKidHomeRepository()..failProfiles = true;
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        repo.failProfiles = false;
        bloc.add(const KidHomeProfilesRequested());
      },
      wait: const Duration(milliseconds: 150),
      verify: (bloc) {
        expect(bloc.state.profiles.map((child) => child.id).toList(), <String>[
          'maya',
          'leo',
        ]);
        // The home subscription was never stacked: one child + one items
        // watch for the whole sequence (K03-BUG-15 applies to both streams).
        expect(repo.activeChildSubscriptions, 1);
        expect(repo.itemsSubscriptions, 1);
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'selecting a profile writes app_state and emits selectedProfileId',
      build: () {
        repo = _FakeKidHomeRepository();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const KidHomeProfileSelected(childId: 'leo', pinSet: false));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(repo.selected, <String>['leo']);
        expect(bloc.state.selectedProfileId, 'leo');
        // The roster and the home list survive the selection emit.
        expect(bloc.state.profiles.map((child) => child.id).toList(), <String>[
          'maya',
          'leo',
        ]);
        expect(bloc.state.items, hasLength(6));
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a failed selection keeps the roster and records actionError',
      build: () {
        repo = _FakeKidHomeRepository()..failSelect = true;
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const KidHomeProfileSelected(childId: 'maya', pinSet: true));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(repo.selected, <String>['maya']);
        expect(bloc.state.selectedProfileId, isNull);
        expect(bloc.state.actionError, contains('select failed'));
        expect(bloc.state.actionNonce, 1);
        expect(bloc.state.profiles, hasLength(2));
        expect(bloc.state.items, hasLength(6));
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a mid-session profiles error keeps the shown roster',
      build: () {
        repo = _FakeKidHomeRepository();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        repo.failProfilesNow(Exception('one bad tick'));
      },
      wait: const Duration(milliseconds: 100),
      verify: (bloc) {
        expect(bloc.state.status, KidHomeStatus.loaded);
        expect(bloc.state.profiles.map((child) => child.id).toList(), <String>[
          'maya',
          'leo',
        ]);
      },
    );

    test('copyWith and completion outcomes carry the K01 roster', () {
      final loaded = KidHomeState(
        status: KidHomeStatus.loaded,
        child: _maya,
        items: _mayaItems(),
        profiles: const <KidChild>[_maya, _leo],
      );
      expect(
        loaded.copyWith(status: KidHomeStatus.loading).profiles,
        hasLength(2),
      );
      expect(
        loaded.copyWithLoaded(child: _maya, items: _mayaItems()).profiles,
        hasLength(2),
        reason: 'a quest completion emit must not blank the picker',
      );
      expect(
        loaded.withCompletionFailed(Exception('x')).profiles,
        hasLength(2),
      );
      expect(
        loaded
            .withCompletionSucceeded(questId: 'q-reading', coins: 10)
            .profiles,
        hasLength(2),
      );
      final selected = loaded.copyWithSelection('leo');
      expect(selected.selectedProfileId, 'leo');
      expect(selected.profiles, hasLength(2));
      // One-shot: the next home emission consumes the selection.
      expect(
        selected
            .copyWithLoaded(child: _leo, items: _mayaItems())
            .selectedProfileId,
        isNull,
      );
    });

    test('KidHomeProfileSelected equality covers every field', () {
      const a = KidHomeProfileSelected(childId: 'maya', pinSet: true);
      const b = KidHomeProfileSelected(childId: 'maya', pinSet: true);
      const differentChild = KidHomeProfileSelected(
        childId: 'leo',
        pinSet: true,
      );
      const differentPin = KidHomeProfileSelected(
        childId: 'maya',
        pinSet: false,
      );
      expect(a, b);
      expect(a, isNot(differentChild));
      expect(a, isNot(differentPin));
    });
  });

  group('K02 PIN (kid secret code)', () {
    late _FakeKidHomeRepository repo;

    /// Loaded with a check in flight.
    final checking = predicate<KidHomeState>(
      (state) =>
          state.status == KidHomeStatus.loaded &&
          state.pinChecking &&
          !state.pinPassed,
    );

    /// Loaded with the one-shot success signal.
    final passed = predicate<KidHomeState>(
      (state) =>
          state.status == KidHomeStatus.loaded &&
          !state.pinChecking &&
          state.pinPassed,
    );

    /// Loaded with [nonce] wrong attempts recorded, list kept.
    Matcher wrong(int nonce) => predicate<KidHomeState>(
      (state) =>
          state.status == KidHomeStatus.loaded &&
          !state.pinChecking &&
          !state.pinPassed &&
          state.pinWrongNonce == nonce &&
          state.doneCount == 4,
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'correct PIN emits checking then pinPassed',
      build: () {
        repo = _FakeKidHomeRepository();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const KidHomePinSubmitted(childId: 'maya', pin: '1234'));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading,
        _loadingWithProfiles,
        _loaded(done: 4, total: 6),
        checking,
        passed,
      ],
      verify: (bloc) {
        expect(repo.verified, <List<String>>[
          <String>['maya', '1234'],
        ]);
        expect(bloc.state.items, hasLength(6));
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'wrong PIN bumps pinWrongNonce and keeps the list',
      build: () {
        repo = _FakeKidHomeRepository();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const KidHomePinSubmitted(childId: 'maya', pin: '9999'));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading,
        _loadingWithProfiles,
        _loaded(done: 4, total: 6),
        checking,
        wrong(1),
      ],
      verify: (bloc) {
        expect(bloc.state.status, KidHomeStatus.loaded);
        expect(bloc.state.errorMessage, isNull);
        expect(bloc.state.actionError, isNull);
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'two identical wrong attempts both surface (nonce-bumped)',
      build: () {
        repo = _FakeKidHomeRepository();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const KidHomePinSubmitted(childId: 'maya', pin: '9999'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const KidHomePinSubmitted(childId: 'maya', pin: '9999'));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading,
        _loadingWithProfiles,
        _loaded(done: 4, total: 6),
        checking,
        wrong(1),
        checking,
        wrong(2),
      ],
      verify: (bloc) => expect(repo.verified, hasLength(2)),
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a correct retry after a wrong attempt still passes',
      build: () {
        repo = _FakeKidHomeRepository();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const KidHomePinSubmitted(childId: 'maya', pin: '9999'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const KidHomePinSubmitted(childId: 'maya', pin: '1234'));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading,
        _loadingWithProfiles,
        _loaded(done: 4, total: 6),
        checking,
        wrong(1),
        checking,
        passed,
      ],
      verify: (bloc) {
        // The nonce survives the later success; the next home emission
        // consumes `pinPassed`, not the wrong count.
        expect(bloc.state.pinWrongNonce, 1);
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a verify throw reads as the wrong path, never the failure card',
      build: () {
        repo = _FakeKidHomeRepository()..failVerify = true;
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const KidHomePinSubmitted(childId: 'maya', pin: '1234'));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading,
        _loadingWithProfiles,
        _loaded(done: 4, total: 6),
        checking,
        wrong(1),
      ],
      verify: (bloc) {
        expect(bloc.state.status, KidHomeStatus.loaded);
        expect(bloc.state.errorMessage, isNull);
        expect(bloc.state.items, hasLength(6));
      },
    );

    test(
      'a second submit mid-check is ignored (double-tap backstop)',
      () async {
        repo = _FakeKidHomeRepository()..verifyGate = Completer<bool>();
        final bloc = KidHomeBloc(repository: repo);
        final sub = bloc.stream.listen((_) {});
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 40));
        bloc.add(const KidHomePinSubmitted(childId: 'maya', pin: '1234'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(bloc.state.pinChecking, isTrue);
        // Second tap lands while the first check is still in flight.
        bloc.add(const KidHomePinSubmitted(childId: 'maya', pin: '1234'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        repo.verifyGate!.complete(true);
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(repo.verified, hasLength(1));
        expect(bloc.state.pinPassed, isTrue);
        expect(bloc.state.pinChecking, isFalse);
        await sub.cancel();
        await bloc.close();
      },
    );

    test('an interleaved stream emission cannot swallow the outcome', () async {
      repo = _FakeKidHomeRepository()..verifyGate = Completer<bool>();
      final bloc = KidHomeBloc(repository: repo);
      final sub = bloc.stream.listen((_) {});
      bloc.add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 40));
      bloc.add(const KidHomePinSubmitted(childId: 'maya', pin: '1234'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // A home emission lands mid-check (e.g. a quest flip elsewhere).
      repo.pushItems(<KidQuest>[
        for (final KidQuest quest in repo.items)
          if (quest.questId == 'q-reading')
            _withStatus(quest, 'done_pending')
          else
            quest,
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      repo.verifyGate!.complete(true);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      // Built from the state at completion time: the fresh list survives
      // AND the success signal lands.
      expect(bloc.state.pinPassed, isTrue);
      expect(bloc.state.doneCount, 5);
      await sub.cancel();
      await bloc.close();
    });

    test('the next home emission consumes pinPassed, not the nonce', () async {
      repo = _FakeKidHomeRepository();
      final bloc = KidHomeBloc(repository: repo);
      final sub = bloc.stream.listen((_) {});
      bloc.add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 40));
      bloc.add(const KidHomePinSubmitted(childId: 'maya', pin: '9999'));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(bloc.state.pinWrongNonce, 1);
      bloc.add(const KidHomePinSubmitted(childId: 'maya', pin: '1234'));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(bloc.state.pinPassed, isTrue);
      // A healthy emission after the success consumes the one-shot, so the
      // view cannot navigate twice — same pattern as justCompletedQuestId.
      repo.pushItems(repo.items);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(bloc.state.pinPassed, isFalse);
      expect(bloc.state.pinWrongNonce, 1);
      expect(bloc.state.pinChecking, isFalse);
      await sub.cancel();
      await bloc.close();
    });

    test('copyWith and completion outcomes carry the K02 PIN channel', () {
      const loaded = KidHomeState(
        status: KidHomeStatus.loaded,
        child: _maya,
        pinChecking: true,
        pinWrongNonce: 2,
        pinPassed: true,
      );
      final copied = loaded.copyWith(status: KidHomeStatus.loading);
      expect(copied.pinChecking, isTrue);
      expect(copied.pinWrongNonce, 2);
      expect(copied.pinPassed, isTrue);
      expect(loaded.withCompletionFailed(Exception('x')).pinWrongNonce, 2);
      expect(
        loaded
            .withCompletionSucceeded(questId: 'q-reading', coins: 10)
            .pinPassed,
        isTrue,
      );
      expect(loaded.copyWithProfiles(loaded.profiles).pinPassed, isTrue);
      expect(
        loaded.copyWithProfilesRecovered(loaded.profiles).pinWrongNonce,
        2,
      );
      expect(loaded.copyWithSelection('leo').pinPassed, isTrue);
      // A fresh home emission keeps an in-flight check and the wrong count
      // but consumes the one-shot success.
      final reloaded = loaded.copyWithLoaded(child: _maya, items: _mayaItems());
      expect(reloaded.pinChecking, isTrue);
      expect(reloaded.pinWrongNonce, 2);
      expect(reloaded.pinPassed, isFalse);
      // Distinct PIN fields make distinct states.
      expect(loaded, isNot(loaded.copyWith(pinWrongNonce: 3)));
      expect(loaded, isNot(const KidHomeState()));
    });

    test('KidHomePinSubmitted equality covers every field', () {
      const a = KidHomePinSubmitted(childId: 'maya', pin: '1234');
      const b = KidHomePinSubmitted(childId: 'maya', pin: '1234');
      const differentPin = KidHomePinSubmitted(childId: 'maya', pin: '9999');
      const differentChild = KidHomePinSubmitted(childId: 'leo', pin: '1234');
      expect(a, b);
      expect(a, isNot(differentPin));
      expect(a, isNot(differentChild));
    });

    blocTest<KidHomeBloc, KidHomeState>(
      "the check passes the event's own child id to the repository",
      build: () {
        repo = _FakeKidHomeRepository();
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        // Maya is the active child, but the event carries its own id: the
        // handler must not re-resolve it (the view is the only caller and it
        // already has the row).
        bloc.add(const KidHomePinSubmitted(childId: 'leo', pin: '1234'));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading,
        _loadingWithProfiles,
        _loaded(done: 4, total: 6),
        checking,
        passed,
      ],
      verify: (bloc) => expect(repo.verified, <List<String>>[
        <String>['leo', '1234'],
      ]),
    );

    test(
      'a wrong attempt never turns the failure card into a loaded screen',
      () async {
        repo = _FakeKidHomeRepository()..failLoad = true;
        final bloc = KidHomeBloc(repository: repo);
        final sub = bloc.stream.listen((_) {});
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 40));
        expect(bloc.state.status, KidHomeStatus.failure);
        bloc.add(const KidHomePinSubmitted(childId: 'maya', pin: '9999'));
        await Future<void>.delayed(const Duration(milliseconds: 40));
        // The PIN outcome rides on the state; the status is untouched, so a
        // failed load keeps its retry card and a wrong code still nudges.
        expect(bloc.state.status, KidHomeStatus.failure);
        expect(bloc.state.pinWrongNonce, 1);
        expect(bloc.state.pinPassed, isFalse);
        expect(bloc.state.pinChecking, isFalse);
        await sub.cancel();
        await bloc.close();
      },
    );

    test('a submit before the load lands still resolves its outcome', () async {
      repo = _FakeKidHomeRepository();
      final bloc = KidHomeBloc(repository: repo);
      final sub = bloc.stream.listen((_) {});
      // No `KidHomeLoadRequested`: the check must not depend on a loaded
      // child (the view dispatches from the row it already holds).
      bloc.add(const KidHomePinSubmitted(childId: 'maya', pin: '1234'));
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(bloc.state.pinPassed, isTrue);
      expect(bloc.state.pinChecking, isFalse);
      expect(bloc.state.status, KidHomeStatus.initial);
      expect(repo.verified, <List<String>>[
        <String>['maya', '1234'],
      ]);
      await sub.cancel();
      await bloc.close();
    });
  });

  // -------------------------------------------------------------------------
  // `switchMapStream` — the helper `watchHome` is built on
  // -------------------------------------------------------------------------
  //
  // Two hazards this helper exists for, both reachable in production:
  //  1. `Stream.asyncExpand` pauses the outer subscription until the current
  //     inner stream CLOSES. Drift watch streams never close, so a child
  //     switch after the first emission would stall forever.
  //  2. The outer stream may legitimately end after one value (`Stream.value`
  //     — which `watchActiveChild` returns for "no active child", and any
  //     `async*` that yields the row once). If the result closed there, the
  //     inner quest subscription would be torn down one tick in and every
  //     later completion flip would be silently dropped — the screen would
  //     stop updating after its first frame.

  group('switchMapStream', () {
    test(
      'keeps forwarding the live inner stream after the outer completes',
      () async {
        final outer = Stream<String>.value('maya');
        final inner = StreamController<String>();
        final seen = <String>[];
        final sub = switchMapStream<String, String>(
          outer,
          (_) => inner.stream,
        ).listen(seen.add);
        await Future<void>.delayed(Duration.zero);
        inner.add('items-1');
        await Future<void>.delayed(Duration.zero);
        // The outer is already done; the inner is still live.
        inner.add('items-2');
        await Future<void>.delayed(Duration.zero);
        expect(seen, <String>[
          'items-1',
          'items-2',
        ], reason: 'an outer that completes must not end the result stream');
        await sub.cancel();
        await inner.close();
      },
    );

    test('a second outer emission replaces the inner subscription', () async {
      final outer = StreamController<String>();
      final first = StreamController<String>();
      final second = StreamController<String>();
      final seen = <String>[];
      final sub = switchMapStream<String, String>(
        outer.stream,
        (child) => (child == 'maya' ? first.stream : second.stream),
      ).listen(seen.add);
      outer.add('maya');
      await Future<void>.delayed(Duration.zero);
      first.add('maya-items');
      await Future<void>.delayed(Duration.zero);
      outer.add('leo');
      await Future<void>.delayed(Duration.zero);
      // The old child's stream must be detached…
      first.add('maya-stale');
      // …and the new child's must flow.
      second.add('leo-items');
      await Future<void>.delayed(Duration.zero);
      expect(seen, <String>['maya-items', 'leo-items']);
      await sub.cancel();
      await outer.close();
      await first.close();
      await second.close();
    });

    test('forwards an inner error without closing the result', () async {
      final inner = StreamController<String>();
      final seen = <String>[];
      final errors = <Object>[];
      final sub = switchMapStream<String, String>(
        Stream<String>.value('maya'),
        (_) => inner.stream,
      ).listen(seen.add, onError: errors.add);
      await Future<void>.delayed(Duration.zero);
      inner
        ..addError(Exception('load failed'))
        ..add('after-error');
      await Future<void>.delayed(Duration.zero);
      expect(errors, hasLength(1));
      expect(seen, <String>['after-error'], reason: 'the stream stays usable');
      await sub.cancel();
      await inner.close();
    });

    test('cancelling the result cancels the inner subscription', () async {
      final inner = StreamController<String>();
      var innerCancelled = false;
      final sub = switchMapStream<String, String>(
        Stream<String>.value('maya'),
        (_) => inner.stream,
      ).listen((_) {});
      await Future<void>.delayed(Duration.zero);
      inner.onCancel = () => innerCancelled = true;
      await sub.cancel();
      expect(innerCancelled, isTrue, reason: 'no leaked quest subscription');
      await inner.close();
    });
  });
}
