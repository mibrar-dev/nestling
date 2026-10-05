// K03b all-done logic layer: the `allDone` derivation and every BLoC event /
// state path that can flip the shared kid home into (or out of) the K03b
// celebration.
//
// Why a separate file from `kid_home_bloc_test.dart`: that suite covers the
// whole `KidHomeBloc` for K03/K01/K02/K04. K03b adds exactly ONE piece of
// logic — `KidHomeState.allDone` — but that piece is the branch that decides
// whether a child sees the celebration at all, so it needs its own truth table
// (every status, the empty case, `not_yet`) AND bloc-level proofs that the
// live paths reach it: the initial load, a completion that finishes the LAST
// quest (celebration + all-done together), a completion failure, a mid-session
// stream error, a load failure, silence, and the empty-quest-list case (which
// must NOT celebrate).
//
// The data-driven paths use the in-memory Drift database with `Seed.demo`
// (`test_scope.dart`) so the counts are the seeded ones; the paths a healthy
// database cannot produce (silence, errors, silent writes) use a feature-local
// fake repository registered over the real one.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/london_time.dart';
import 'package:nestling/features/kid_home/data/kid_home_repository_impl.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
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
  pipTotalCoins: 175,
);

KidQuest _quest(String questId, String status) => KidQuest(
  id: '$questId:maya',
  title: 'Quest $questId',
  detail: '',
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
  needsApproval: quest.needsApproval,
);

/// [count] quests, the first [doneCount] of them already finished.
List<KidQuest> _quests(int count, int doneCount, {String status = 'approved'}) {
  return <KidQuest>[
    for (var i = 0; i < count; i++)
      _quest('q$i', i < doneCount ? status : 'to_do'),
  ];
}

/// Every item finished with the given status (`approved` / `done_pending`).
List<KidQuest> _allDone(int count, {String status = 'approved'}) =>
    _quests(count, count, status: status);

/// Marks the named quests as finished this period in the seeded database, so
/// the real `KidHomeRepositoryImpl` reports them done without any mock.
Future<void> _completeInDb(
  AppDatabase db,
  List<String> questIds, {
  String status = 'done_pending',
}) async {
  final now = appNowUtc();
  for (final questId in questIds) {
    await (db.update(db.questCompletions)
          ..where((c) => c.questId.equals(questId) & c.childId.equals('maya')))
        .write(
          QuestCompletionsCompanion(
            status: Value(status),
            createdAt: Value(now),
          ),
        );
  }
}

/// Fake repository: fresh streams per call (like the Drift repository),
/// pushable items, and injectable silence / error / write-failure modes, so
/// the bloc paths a healthy database cannot produce are still covered.
class _FakeRepo extends KidHomeRepository {
  _FakeRepo({List<KidQuest>? items}) : _items = items ?? _allDone(6);

  List<KidQuest> _items;

  /// `watchHome()`/`watchItems()` never emit (loading channel).
  bool hang = false;

  /// The home stream errors on listen (load-failure channel).
  bool failLoad = false;

  /// `completeQuest` throws (action-error channel).
  bool failComplete = false;

  /// `completeQuest` records the call but never flips the stream (silent
  /// no-op write — the tap must not celebrate).
  bool completeIsNoop = false;

  final List<List<String>> completed = <List<String>>[];
  final StreamController<List<KidQuest>> _pushed =
      StreamController<List<KidQuest>>.broadcast();

  List<KidQuest> get items => _items;

  void pushItems(List<KidQuest> value) {
    _items = value;
    _pushed.add(value);
  }

  void failStreamNow(Object error) => _pushed.addError(error);

  @override
  Future<List<KidQuest>> getItems() async => _items;

  @override
  Stream<List<KidQuest>> watchItems() async* {
    if (hang) return;
    if (failLoad) throw Exception('items down');
    yield _items;
    yield* _pushed.stream;
  }

  @override
  Stream<KidChild?> watchActiveChild() async* {
    if (hang) return;
    if (failLoad) throw Exception('child down');
    yield _maya;
  }

  @override
  Stream<List<KidChild>> watchProfiles() =>
      Stream<List<KidChild>>.value(const <KidChild>[_maya]);

  @override
  List<String> stepsFor(String questId) => const <String>['Step one'];

  @override
  Future<bool> verifyPin(String childId, String pin) async => true;

  @override
  Future<void> setActiveChild(String childId) async {}

  @override
  Future<void> completeQuest(String childId, String questId) async {
    completed.add(<String>[childId, questId]);
    if (failComplete) throw Exception('save failed');
    if (completeIsNoop) return;
    pushItems(<KidQuest>[
      for (final quest in _items)
        if (quest.questId == questId)
          _withStatus(quest, 'done_pending')
        else
          quest,
    ]);
  }
}

Matcher _loading() =>
    predicate<KidHomeState>((state) => state.status == KidHomeStatus.loading);

/// Loading once the K01 roster has landed. Every load passes through it: the
/// profiles stream answers before the combined home stream does, so the
/// sequence is loading (empty roster) → loading (roster) → loaded. Named so
/// the expected sequences read deliberately (same convention as
/// `kid_home_bloc_test.dart`).
Matcher _loadingWithProfiles() => predicate<KidHomeState>(
  (state) =>
      state.status == KidHomeStatus.loading && state.profiles.length == 1,
);

Matcher _loaded({int? done, int? total, bool? allDone}) {
  return predicate<KidHomeState>((state) {
    if (state.status != KidHomeStatus.loaded) return false;
    if (state.child?.nickname != 'Maya') return false;
    if (done != null && state.doneCount != done) return false;
    if (total != null && state.totalCount != total) return false;
    if (allDone != null && state.allDone != allDone) return false;
    return true;
  });
}

Matcher _failure() =>
    predicate<KidHomeState>((state) => state.status == KidHomeStatus.failure);

void main() {
  group('KidHomeState.allDone truth table', () {
    test('an empty list is NOT all done (that is the empty-quests state)', () {
      const state = KidHomeState();
      expect(state.allDone, isFalse);
      expect(state.fraction, 0);
    });

    test('nothing done is false', () {
      final state = KidHomeState(items: _quests(6, 0));
      expect(state.allDone, isFalse);
      expect(state.doneCount, 0);
    });

    test('one quest short is false', () {
      final state = KidHomeState(items: _quests(6, 5));
      expect(state.allDone, isFalse);
      expect(state.fraction, closeTo(5 / 6, 1e-9));
    });

    test('a single finished quest IS all done', () {
      final state = KidHomeState(items: _quests(1, 1));
      expect(state.allDone, isTrue);
      expect(state.fraction, 1);
    });

    test('every approved quest is all done', () {
      final state = KidHomeState(items: _allDone(6));
      expect(state.allDone, isTrue);
    });

    test('every done_pending quest is all done', () {
      final state = KidHomeState(items: _allDone(6, status: 'done_pending'));
      expect(state.allDone, isTrue, reason: 'waiting for Mum still counts');
    });

    test('a mixed approved/done_pending list is all done', () {
      final state = KidHomeState(
        items: <KidQuest>[
          _quest('a', 'approved'),
          _quest('b', 'done_pending'),
          _quest('c', 'approved'),
        ],
      );
      expect(state.allDone, isTrue);
    });

    test('not_yet never counts as done', () {
      final state = KidHomeState(
        items: <KidQuest>[_quest('a', 'approved'), _quest('b', 'not_yet')],
      );
      expect(state.doneCount, 1);
      expect(state.allDone, isFalse);
    });

    test('needsApproval never changes the done count or the branch', () {
      // ROW META (orchestrator 04:52): the flag shapes the row copy only.
      // Done-ness is the status alone, so a no-approval quest still counts.
      final state = KidHomeState(
        items: <KidQuest>[
          _quest('a', 'approved'),
          const KidQuest(
            id: 'b:maya',
            title: 'Quest b',
            detail: '',
            questId: 'b',
            icon: 'book',
            coins: 15,
            status: 'approved',
            needsApproval: false,
          ),
          const KidQuest(
            id: 'c:maya',
            title: 'Quest c',
            detail: '',
            questId: 'c',
            icon: 'book',
            coins: 10,
            status: 'done_pending',
            needsApproval: false,
          ),
        ],
      );
      expect(state.doneCount, 3);
      expect(state.totalCount, 3);
      expect(state.allDone, isTrue);
      expect(state.fraction, 1);
    });

    test('a to-do quest breaks all-done even when it needs no approval', () {
      final state = KidHomeState(
        items: <KidQuest>[
          _quest('a', 'approved'),
          const KidQuest(
            id: 'b:maya',
            title: 'Quest b',
            detail: '',
            questId: 'b',
            icon: 'book',
            coins: 10,
            status: 'to_do',
            needsApproval: false,
          ),
        ],
      );
      expect(state.doneCount, 1);
      expect(state.allDone, isFalse);
    });

    test('allDone is derived, never stored: copyWithLoaded recomputes it', () {
      final partial = KidHomeState(
        status: KidHomeStatus.loaded,
        child: _maya,
        items: _quests(6, 5),
      );
      expect(partial.allDone, isFalse);
      final finished = partial.copyWithLoaded(child: _maya, items: _allDone(6));
      expect(finished.allDone, isTrue);
      // The equality contract keeps the derived flag consistent: two states
      // with the same items are equal, so `BlocBuilder` can never skip a
      // rebuild that would change the branch.
      expect(finished, isNot(partial));
    });
  });

  group('KidHomeBloc — all-done paths', () {
    late _FakeRepo repo;

    blocTest<KidHomeBloc, KidHomeState>(
      'a load where every quest is done lands on the celebration branch',
      build: () {
        repo = _FakeRepo(items: _allDone(6));
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const KidHomeLoadRequested()),
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading(),
        _loadingWithProfiles(),
        _loaded(done: 6, total: 6, allDone: true),
      ],
      verify: (_) {
        // The branch never opens the celebration route by itself:
        // `justCompletedQuestId` stays null on a plain load.
        expect(repo.completed, isEmpty);
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a load with one quest left keeps the K03 branch',
      build: () {
        repo = _FakeRepo(items: _quests(6, 5));
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const KidHomeLoadRequested()),
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading(),
        _loadingWithProfiles(),
        _loaded(done: 5, total: 6, allDone: false),
      ],
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a load with no quests at all is the empty state, never a celebration',
      build: () {
        repo = _FakeRepo(items: const <KidQuest>[]);
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const KidHomeLoadRequested()),
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading(),
        _loadingWithProfiles(),
        _loaded(done: 0, total: 0, allDone: false),
      ],
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'finishing the LAST quest celebrates and flips the branch in one state',
      build: () {
        // Five of six done: the K03 branch, one quest left.
        repo = _FakeRepo(items: _quests(6, 5));
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(
          const KidHomeQuestCompleted(
            childId: 'maya',
            questId: 'q5',
            coins: 10,
          ),
        );
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading(),
        _loadingWithProfiles(),
        _loaded(done: 5, total: 6, allDone: false),
        // The flip carries the one-shot celebration, so the view pushes K05
        // and the screen underneath is already the K03b branch.
        predicate<KidHomeState>(
          (state) =>
              state.status == KidHomeStatus.loaded &&
              state.allDone &&
              state.justCompletedQuestId == 'q5' &&
              state.justCompletedCoins == 10,
        ),
      ],
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a silent no-op write never reaches the celebration branch',
      build: () {
        repo = _FakeRepo(items: _quests(6, 5))..completeIsNoop = true;
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(
          const KidHomeQuestCompleted(
            childId: 'maya',
            questId: 'q5',
            coins: 10,
          ),
        );
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading(),
        _loadingWithProfiles(),
        _loaded(done: 5, total: 6, allDone: false),
      ],
      verify: (bloc) {
        expect(repo.completed, <List<String>>[
          <String>['maya', 'q5'],
        ], reason: 'the tap reached the repository');
        expect(bloc.state.allDone, isFalse, reason: 'nothing flipped');
        expect(bloc.state.justCompletedQuestId, isNull);
      },
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a failed write keeps the list and never celebrates',
      build: () {
        repo = _FakeRepo(items: _quests(6, 5))..failComplete = true;
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(
          const KidHomeQuestCompleted(
            childId: 'maya',
            questId: 'q5',
            coins: 10,
          ),
        );
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading(),
        _loadingWithProfiles(),
        _loaded(done: 5, total: 6, allDone: false),
        predicate<KidHomeState>(
          (state) =>
              state.status == KidHomeStatus.loaded &&
              !state.allDone &&
              state.actionError != null &&
              state.actionNonce == 1 &&
              state.justCompletedQuestId == null,
        ),
      ],
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a live stream error keeps the celebration branch up',
      build: () {
        repo = _FakeRepo(items: _allDone(6));
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const KidHomeLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        repo.failStreamNow(Exception('transient'));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[
        _loading(),
        _loadingWithProfiles(),
        _loaded(done: 6, total: 6, allDone: true),
        // A single bad watch tick must never replace the screen the child is
        // looking at (mid-session error keeps the list).
        predicate<KidHomeState>(
          (state) => state.status == KidHomeStatus.loaded && state.allDone,
        ),
      ],
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a load failure never celebrates (it is the shared failure card)',
      build: () {
        repo = _FakeRepo(items: _allDone(6))..failLoad = true;
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const KidHomeLoadRequested()),
      wait: const Duration(milliseconds: 100),
      expect: () => <Matcher>[_loading(), _loadingWithProfiles(), _failure()],
    );

    blocTest<KidHomeBloc, KidHomeState>(
      'a silent stream stays on the loading channel',
      build: () {
        repo = _FakeRepo(items: _allDone(6))..hang = true;
        return KidHomeBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const KidHomeLoadRequested()),
      wait: const Duration(milliseconds: 100),
      // The roster still arrives, so the loading state repeats with profiles
      // before the home stream goes quiet.
      expect: () => <Matcher>[_loading(), _loadingWithProfiles()],
    );
  });

  group('all-done is derived from the seeded database', () {
    setUp(() async {
      await setUpTestScope();
    });

    test('demo Maya is 4 of 6 (K03, never the celebration)', () async {
      final repo = GetIt.instance<KidHomeRepository>();
      final items = await repo.getItems();
      final bloc = KidHomeBloc(repository: repo)
        ..add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(items, hasLength(6));
      expect(bloc.state.doneCount, 4);
      expect(bloc.state.allDone, isFalse);
      await bloc.close();
    });

    test('finishing the two open quests reaches 6 of 6', () async {
      final repo = GetIt.instance<KidHomeRepository>();
      final bloc = KidHomeBloc(repository: repo)
        ..add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.allDone, isFalse);
      await repo.completeQuest('maya', 'q-reading');
      await repo.completeQuest('maya', 'q-tidy');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.doneCount, 6);
      expect(bloc.state.totalCount, 6);
      expect(
        bloc.state.allDone,
        isTrue,
        reason: 'K03b is a STATE, not a route',
      );
      expect(bloc.state.fraction, 1);
      await bloc.close();
    });

    test('PERIODS: a weekly completion from last week drops the screen back to K03', () async {
      final db = GetIt.instance<AppDatabase>();
      final repo = GetIt.instance<KidHomeRepository>();
      // Finish everything for the current period…
      await _completeInDb(db, <String>['q-reading', 'q-tidy']);
      var bloc = KidHomeBloc(repository: repo)
        ..add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.allDone, isTrue);
      await bloc.close();

      // …then move ONE weekly completion out of the current London week:
      // `q-hoover` is weekly, so it reads "to do" again and the all-done
      // branch must disappear (the period ruling governs the celebration).
      final weekStart = londonWeekStartUtc(appNowUtc());
      await (db.update(
        db.questCompletions,
      )..where((c) => c.questId.equals('q-hoover'))).write(
        QuestCompletionsCompanion(
          createdAt: Value(weekStart.subtract(const Duration(seconds: 1))),
        ),
      );
      bloc = KidHomeBloc(repository: repo)..add(const KidHomeLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.doneCount, 5);
      expect(bloc.state.allDone, isFalse);
      await bloc.close();
    });

    test(
      'a child with no quests reports an empty list, not all done',
      () async {
        final db = GetIt.instance<AppDatabase>();
        final repo = KidHomeRepositoryImpl(db: db);
        await (db.delete(
          db.quests,
        )..where((q) => q.assigneeChildId.equals('maya'))).go();
        final items = await repo.getItems();
        expect(items, isEmpty);
        final state = KidHomeState(
          status: KidHomeStatus.loaded,
          child: _maya,
          items: items,
        );
        expect(state.totalCount, 0);
        expect(state.allDone, isFalse);
      },
    );
  });
}
