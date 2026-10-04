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
}
