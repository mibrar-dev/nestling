// K09 bloc tests: the load path over a controllable fake repository, plus
// value semantics for the state object.
//
// The fake hands out FRESH streams per call (like the Drift repo does), so
// retry-after-failure and live re-emission behave like production. It is a
// stream-based fake rather than the in-memory DB because bloc tests exercise
// error paths the database cannot produce. The Maya fixture mirrors the real
// `watchJar` mapping (plan §b/§f) so the UI builder codes against pinned
// values: owed 420, Lego Friends set 1550/2499, Saturday, 9 money-in rows
// newest-first starting with the 300p weekly base.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_entry.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_snapshot.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_summary.dart';
import 'package:nestling/features/kid_jar/domain/kid_jar_repository.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_bloc.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_event.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_state.dart';

/// Maya's K09 list in the demo seed: money-in rows only, newest first
/// (payout/spend/savings_move excluded upstream of the bloc).
List<JarEntry> _mayaItems() => <JarEntry>[
  JarEntry(
    id: '1',
    title: 'Pocket money',
    detail: 'This Saturday',
    type: 'weekly_base',
    amountPence: 300,
    date: DateTime.utc(2026, 10, 3, 8),
  ),
  JarEntry(
    id: '2',
    title: 'Put the bins out',
    detail: 'Quest bonus',
    type: 'quest_bonus',
    amountPence: 12,
    date: DateTime.utc(2026, 10, 2, 19),
  ),
  JarEntry(
    id: '3',
    title: 'Hoover the stairs',
    detail: 'Quest bonus',
    type: 'quest_bonus',
    amountPence: 40,
    date: DateTime.utc(2026, 10, 1, 18),
  ),
  JarEntry(
    id: '4',
    title: 'Help with the washing',
    detail: 'Quest bonus',
    type: 'quest_bonus',
    amountPence: 40,
    date: DateTime.utc(2026, 9, 30, 17),
  ),
  JarEntry(
    id: '5',
    title: 'Tidy your bedroom',
    detail: 'Quest bonus',
    type: 'quest_bonus',
    amountPence: 28,
    date: DateTime.utc(2026, 9, 29, 17),
  ),
  JarEntry(
    id: '6',
    title: 'Birthday money',
    detail: 'From Mum',
    type: 'gift',
    amountPence: 1000,
    date: DateTime.utc(2026, 9, 28, 10),
  ),
  JarEntry(
    id: '7',
    title: 'Hoover the stairs',
    detail: 'Quest bonus',
    type: 'quest_bonus',
    amountPence: 68,
    date: DateTime.utc(2026, 9, 25, 17),
  ),
  JarEntry(
    id: '8',
    title: 'Put the bins out',
    detail: 'Quest bonus',
    type: 'quest_bonus',
    amountPence: 12,
    date: DateTime.utc(2026, 9, 21, 17),
  ),
  JarEntry(
    id: '9',
    title: 'Pocket money',
    detail: 'Last Sunday',
    type: 'weekly_base',
    amountPence: 300,
    date: DateTime.utc(2026, 9, 20, 8),
  ),
];

JarSnapshot _mayaSnapshot() => JarSnapshot(
  childId: 'maya',
  items: _mayaItems(),
  summary: const JarSummary(
    childId: 'maya',
    owedPence: 420,
    nextPayoutDay: 'Saturday',
    goalTitle: 'Lego Friends set',
    goalSavedPence: 1550,
    goalTargetPence: 2499,
  ),
);

JarSnapshot _leoSnapshot() => const JarSnapshot(
  childId: 'leo',
  items: <JarEntry>[],
  summary: JarSummary(
    childId: 'leo',
    owedPence: 210,
    nextPayoutDay: 'Saturday',
    goalTitle: 'Savings goal',
    goalSavedPence: 0,
    goalTargetPence: 0,
  ),
);

KidJarState _mayaLoaded() => KidJarState(
  status: KidJarStatus.loaded,
  childId: 'maya',
  items: _mayaItems(),
  owedPence: 420,
  goalTitle: 'Lego Friends set',
  goalSavedPence: 1550,
  goalTargetPence: 2499,
);

/// Controllable fake: fresh streams per call, and a switch for watch failure.
/// The first `watchJar` call can fail while later ones serve data, so the
/// retry path is reachable.
class _FakeKidJarRepository implements KidJarRepository {
  _FakeKidJarRepository({required this.snapshot});

  JarSnapshot snapshot;
  bool failFirstWatch = false;
  int watches = 0;

  /// When true, [watchJar] hands out [live] instead of a one-shot stream, so
  /// a test can push snapshots the way Drift's watch stream behaves.
  bool controlled = false;
  late final StreamController<JarSnapshot> live =
      StreamController<JarSnapshot>.broadcast();

  void push(JarSnapshot next) => live.add(next);

  @override
  Stream<JarSnapshot> watchJar() {
    watches++;
    if (controlled) return live.stream;
    if (failFirstWatch && watches == 1) {
      return Stream<JarSnapshot>.error(Exception('jar is down'));
    }
    return Stream<JarSnapshot>.value(snapshot);
  }

  @override
  Future<List<JarEntry>> getItems() async => snapshot.items;

  @override
  Stream<List<JarEntry>> watchItems() =>
      Stream<List<JarEntry>>.value(snapshot.items);

  @override
  Stream<JarSummary> watchSummary(String childId) =>
      Stream<JarSummary>.value(snapshot.summary);

  @override
  Future<void> moveToSavings({
    required String childId,
    required String goalId,
    required int amountPence,
  }) async {}
}

/// The same fake, but it keeps every stream it ever handed out so a test can
/// count LIVE listeners. A production `watchJar` never closes (Drift watch
/// streams are infinite), so "did the previous subscription get released?" is
/// only answerable by counting listeners rather than by completion.
class _CountingKidJarRepository implements KidJarRepository {
  final List<StreamController<JarSnapshot>> handed =
      <StreamController<JarSnapshot>>[];

  /// Controllers of the subscriptions the bloc still holds.
  int get liveListeners =>
      handed.where((c) => c.hasListener && !c.isClosed).length;

  /// True once [handed] has been closed — the fake's own teardown.
  void dispose() {
    for (final c in handed) {
      unawaited(c.close());
    }
  }

  @override
  Stream<JarSnapshot> watchJar() {
    final controller = StreamController<JarSnapshot>();
    // A never-ending watch stream: nothing is ever added and it never closes.
    handed.add(controller);
    return controller.stream;
  }

  @override
  Future<List<JarEntry>> getItems() async => const <JarEntry>[];

  @override
  Stream<List<JarEntry>> watchItems() => const Stream<List<JarEntry>>.empty();

  @override
  Stream<JarSummary> watchSummary(String childId) =>
      const Stream<JarSummary>.empty();

  @override
  Future<void> moveToSavings({
    required String childId,
    required String goalId,
    required int amountPence,
  }) async {}
}

void main() {
  group('KidJarBloc load (K09)', () {
    blocTest<KidJarBloc, KidJarState>(
      'emits loading then loaded with the Maya snapshot',
      build: () => KidJarBloc(
        repository: _FakeKidJarRepository(snapshot: _mayaSnapshot()),
      ),
      act: (bloc) => bloc.add(const KidJarLoadRequested()),
      expect: () => <KidJarState>[
        const KidJarState(status: KidJarStatus.loading),
        _mayaLoaded(),
      ],
    );

    blocTest<KidJarBloc, KidJarState>(
      'the failed stream reports failure and keeps the error message',
      build: () {
        final repo = _FakeKidJarRepository(snapshot: _mayaSnapshot())
          ..failFirstWatch = true;
        return KidJarBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const KidJarLoadRequested()),
      verify: (bloc) {
        expect(bloc.state.status, KidJarStatus.failure);
        expect(bloc.state.errorMessage, contains('down'));
        // Nothing from a failed load may reach the screen as data.
        expect(bloc.state.items, isEmpty);
        expect(bloc.state.owedPence, 0);
        expect(bloc.state.goalTargetPence, 0);
      },
    );

    blocTest<KidJarBloc, KidJarState>(
      'the loaded state carries owed 420, the Lego goal and Saturday',
      build: () => KidJarBloc(
        repository: _FakeKidJarRepository(snapshot: _mayaSnapshot()),
      ),
      act: (bloc) => bloc.add(const KidJarLoadRequested()),
      verify: (bloc) {
        expect(bloc.state.childId, 'maya');
        expect(bloc.state.owedPence, 420);
        expect(bloc.state.goalTitle, 'Lego Friends set');
        expect(bloc.state.goalSavedPence, 1550);
        expect(bloc.state.goalTargetPence, 2499);
        expect(bloc.state.nextPayoutDay, 'Saturday');
        expect(
          bloc.state.items.map((item) => item.type),
          everyElement(isIn(<String>{'weekly_base', 'quest_bonus', 'gift'})),
        );
        expect(bloc.state.items.first.type, 'weekly_base');
        expect(bloc.state.items.first.amountPence, 300);
      },
    );

    test('stream error emits failure and a retry reloads', () async {
      final repo = _FakeKidJarRepository(snapshot: _mayaSnapshot())
        ..failFirstWatch = true;
      final bloc = KidJarBloc(repository: repo);
      addTearDown(bloc.close);
      bloc.add(const KidJarLoadRequested());
      await expectLater(
        bloc.stream,
        emitsInOrder(<Object>[
          const KidJarState(status: KidJarStatus.loading),
          predicate<KidJarState>(
            (state) => state.status == KidJarStatus.failure,
          ),
        ]),
      );
      expect(repo.watches, 1);

      bloc.add(const KidJarLoadRequested());
      await expectLater(
        bloc.stream,
        emitsInOrder(<Object>[
          // The retry spinner carries the load error through (K03 precedent:
          // only a healthy emission clears it), so match on status only.
          predicate<KidJarState>(
            (state) => state.status == KidJarStatus.loading,
          ),
          predicate<KidJarState>(
            (state) =>
                state.status == KidJarStatus.loaded &&
                state.owedPence == 420 &&
                state.errorMessage == null,
          ),
        ]),
      );
      expect(repo.watches, 2);
    });

    test(
      'a live snapshot replaces the child, list and summary in place',
      () async {
        final repo = _FakeKidJarRepository(snapshot: _mayaSnapshot())
          ..controlled = true;
        final bloc = KidJarBloc(repository: repo);
        addTearDown(() async {
          await bloc.close();
          await repo.live.close();
        });
        final seen = <KidJarState>[];
        final sub = bloc.stream.listen(seen.add);
        addTearDown(sub.cancel);
        bloc.add(const KidJarLoadRequested());
        await Future<void>.delayed(Duration.zero);
        repo.push(_mayaSnapshot());
        await Future<void>.delayed(Duration.zero);

        expect(seen.last, _mayaLoaded());

        // Leo takes over mid-session: the stream replaces the child, the list
        // and the summary together — never a mixed frame.
        repo.push(_leoSnapshot());
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.childId, 'leo');
        expect(bloc.state.owedPence, 210);
        expect(bloc.state.goalTargetPence, 0);
        expect(bloc.state.items, isEmpty);
      },
    );

    test(
      'a stream error after a healthy load keeps the last snapshot',
      () async {
        final repo = _FakeKidJarRepository(snapshot: _mayaSnapshot())
          ..controlled = true;
        final bloc = KidJarBloc(repository: repo);
        addTearDown(() async {
          await bloc.close();
          await repo.live.close();
        });
        bloc.add(const KidJarLoadRequested());
        await Future<void>.delayed(Duration.zero);
        repo.push(_mayaSnapshot());
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.status, KidJarStatus.loaded);

        repo.live.addError(Exception('jar is offline'));
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.status, KidJarStatus.failure);
        expect(bloc.state.errorMessage, contains('offline'));
        expect(bloc.state.owedPence, 420, reason: 'last known figures survive');
        expect(bloc.state.items, hasLength(9));
      },
    );
  });

  group('K09-BUG-1 — a reload must not stack a live subscription', () {
    // The `KidJarBloc` header and `1_plan.md` §b both claim that `emit.forEach`
    // "cancels the prior subscription" on a reload. It does not: bloc's default
    // event transformer is CONCURRENT ("By default events are processed
    // concurrently", bloc 9.2.1 `src/bloc.dart:32`), so each
    // `KidJarLoadRequested` starts another never-ending handler while the
    // previous one is still subscribed. The same defect was filed and fixed
    // for K03 as K03-BUG-15 (`docs/screens/K03/FIXES_7.md:94`), whose fix was a
    // guarded `StreamSubscription` cancelled at the top of the load handler.
    //
    // Reached from `my_jar_view.dart:325` — the failure state's "Try again"
    // dispatches `KidJarLoadRequested` again, and a Drift watch stream that
    // errors does not close, so the first handler is still subscribed at that
    // moment. Each stacked subscription is a live fan-out of THREE Drift
    // queries (`watchLedger` + `watchGoals` + `watchSetting`,
    // `kid_jar_repository_impl.dart:43`).
    test('K09-BUG-1: retry does not stack live stream subscriptions', () async {
      final repo = _CountingKidJarRepository();
      addTearDown(repo.dispose);
      final bloc = KidJarBloc(repository: repo);
      addTearDown(bloc.close);

      bloc.add(const KidJarLoadRequested());
      await Future<void>.delayed(Duration.zero);
      expect(repo.liveListeners, 1);

      // "Try again" (a second load) must REPLACE the first subscription.
      bloc.add(const KidJarLoadRequested());
      await Future<void>.delayed(Duration.zero);
      expect(
        repo.liveListeners,
        1,
        reason:
            "the second load must cancel the first; bloc's concurrent "
            'transformer leaves it subscribed',
      );

      // A third, for the shape of the leak the bugs stage reported for K03.
      bloc.add(const KidJarLoadRequested());
      await Future<void>.delayed(Duration.zero);
      expect(repo.liveListeners, 1);
    });

    test('K09-BUG-1: a stale subscription can overwrite the reloaded state', () async {
      final repo = _CountingKidJarRepository();
      addTearDown(repo.dispose);
      final bloc = KidJarBloc(repository: repo);
      addTearDown(bloc.close);

      bloc.add(const KidJarLoadRequested());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const KidJarLoadRequested());
      await Future<void>.delayed(Duration.zero);

      // The CURRENT subscription speaks last, and the state is correct…
      repo.handed.last.add(_mayaSnapshot());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.owedPence, 420);
      expect(bloc.state.childId, 'maya');

      // …but the abandoned first subscription still has the right to emit, and
      // whatever it says becomes the screen's state.
      repo.handed.first.add(_leoSnapshot());
      await Future<void>.delayed(Duration.zero);
      expect(
        bloc.state.childId,
        'maya',
        reason:
            'a released subscription must not be able to overwrite the '
            'snapshot the recovered screen is showing',
      );
      expect(bloc.state.owedPence, 420);
    });
  });

  group('KidJarState value semantics', () {
    test('a fresh state is initial and empty', () {
      const state = KidJarState();
      expect(state.status, KidJarStatus.initial);
      expect(state.childId, isEmpty);
      expect(state.items, isEmpty);
      expect(state.owedPence, 0);
      expect(state.goalTitle, isEmpty);
      expect(state.goalSavedPence, 0);
      expect(state.goalTargetPence, 0);
      expect(state.nextPayoutDay, 'Saturday');
      expect(state.errorMessage, isNull);
    });

    test('copyWithLoaded replaces every jar field and clears the error', () {
      const failed = KidJarState(
        status: KidJarStatus.failure,
        errorMessage: 'jar is down',
      );
      final recovered = failed.copyWithLoaded(
        childId: 'maya',
        items: _mayaItems(),
        owedPence: 420,
        goalTitle: 'Lego Friends set',
        goalSavedPence: 1550,
        goalTargetPence: 2499,
        nextPayoutDay: 'Saturday',
      );

      expect(recovered, _mayaLoaded());
      expect(recovered.errorMessage, isNull);
    });

    test('copyWith leaves untouched fields alone', () {
      final loading = _mayaLoaded().copyWith(status: KidJarStatus.loading);
      expect(loading.status, KidJarStatus.loading);
      expect(loading.owedPence, 420);
      expect(loading.childId, 'maya');
      expect(loading.items, hasLength(9));
    });

    test('equal states compare equal so the view does not rebuild', () {
      expect(_mayaLoaded(), _mayaLoaded());
      expect(_mayaLoaded(), isNot(_mayaLoaded().copyWith(owedPence: 421)));
    });
  });

  group('KidJarBloc guarded subscription (K09-BUG-1)', () {
    test('close() releases the live subscription', () async {
      final repo = _CountingKidJarRepository();
      addTearDown(repo.dispose);
      final bloc = KidJarBloc(repository: repo);
      addTearDown(bloc.close);
      bloc.add(const KidJarLoadRequested());
      await Future<void>.delayed(Duration.zero);
      expect(repo.liveListeners, 1);

      // Closing releases the guarded subscription (K09-BUG-1).
      await bloc.close();
      expect(repo.liveListeners, 0);
    });

    test('a snapshot emission carries the quest icon key through', () async {
      final snapshot = JarSnapshot(
        childId: 'maya',
        items: <JarEntry>[
          JarEntry(
            id: '3',
            title: 'Hoover the stairs',
            detail: 'Quest bonus',
            type: 'quest_bonus',
            amountPence: 40,
            date: DateTime.utc(2026, 10, 1, 18),
            iconKey: 'hoover',
          ),
        ],
        summary: const JarSummary(
          childId: 'maya',
          owedPence: 420,
          nextPayoutDay: 'Saturday',
          goalTitle: 'Lego Friends set',
          goalSavedPence: 1550,
          goalTargetPence: 2499,
        ),
      );
      final bloc = KidJarBloc(
        repository: _FakeKidJarRepository(snapshot: snapshot),
      );
      addTearDown(bloc.close);
      bloc.add(const KidJarLoadRequested());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.status, KidJarStatus.loaded);
      expect(bloc.state.items.single.iconKey, 'hoover');
    });
  });
}
