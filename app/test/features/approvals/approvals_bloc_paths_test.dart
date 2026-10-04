// P11 · Approvals — the bloc paths the seeded happy path never reaches.
//
// `approvals_bloc_test.dart` (stage 2) covers load → sorted loaded, one
// approve, one not-yet, approve-all, each write's failure and the error
// consumption, one at a time. What is left of the event/state surface is
// pinned here:
//
//   * two writes in flight at once — `busyIds` is a SET and bloc's default
//     transformer subscribes to every event (`_FlatMapStreamTransformer`),
//     so handlers of the same type really do run concurrently and the UI can
//     hold two cards in their loading state.
//   * a stream re-emission while a write is in flight: the newest-first sort
//     re-runs on every event and must NOT clear `busyIds` / `approveAllBusy`.
//   * the stream draining to empty (the post-approve-all landing).
//   * a stream that fails and is then retried ("Try again").
//   * a "Not yet" failure — the one write whose error path was unproven.
//   * `ApprovalsActionErrorConsumed` with nothing left to consume.
//   * `copyWith` / equality, including the `clearActionError` flag.
//
// No widget, no database: the repository is a mocktail mock and every stream
// is hand-fed, so each assertion is about the bloc's own contract.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/features/approvals/domain/approvals_repository.dart';
import 'package:nestling/features/approvals/domain/entities/approval.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_event.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_state.dart';

class MockApprovalsRepository extends Mock implements ApprovalsRepository;

// Seeded rows, same as the stage-2 bloc test: the repository streams
// oldest-first (createdAt ASC), the bloc sorts newest-first.
Approval _row({
  required int completionId,
  required String quest,
  required String child,
  required int coins,
  required DateTime createdAt,
}) {
  return Approval(
    id: '$completionId',
    title: quest,
    detail: '$child · Today',
    completionId: completionId,
    questId: 'q-$completionId',
    questTitle: quest,
    childId: child.toLowerCase(),
    childName: child,
    avatarColour: 'lilac',
    coins: coins,
    createdAt: createdAt,
    createdAtTz: 'Europe/London',
  );
}

final Approval _bed = _row(
  completionId: 3,
  quest: 'Make your bed',
  child: 'Leo',
  coins: 5,
  createdAt: DateTime.utc(2026, 10, 3, 6, 58),
);
final Approval _table = _row(
  completionId: 2,
  quest: 'Lay the table',
  child: 'Maya',
  coins: 10,
  createdAt: DateTime.utc(2026, 10, 3, 7, 5),
);
final Approval _dishwasher = _row(
  completionId: 1,
  quest: 'Empty the dishwasher',
  child: 'Maya',
  coins: 15,
  createdAt: DateTime.utc(2026, 10, 3, 7, 12),
);

/// A fourth row that arrives later than everything else — the newest-first
/// sort must put it on top the moment the stream emits it.
final Approval _newest = _row(
  completionId: 4,
  quest: 'Feed Biscuit the cat',
  child: 'Maya',
  coins: 5,
  createdAt: DateTime.utc(2026, 10, 3, 9),
);

/// The repository's own order (oldest first).
final _streamOrder = <Approval>[_bed, _table, _dishwasher];

/// What the bloc turns that into.
final _sortedLoaded = ApprovalsState(
  status: ApprovalsStatus.loaded,
  items: <Approval>[_dishwasher, _table, _bed],
);

const _loading = ApprovalsState(status: ApprovalsStatus.loading);

/// A card mid-decision: `busyIds` says the card is busy, `busyActions` says
/// WHICH button the parent pressed (BUG-P11-4 — the state must remember the
/// decision, not just that the card is locked).
ApprovalsState _busy(int id, ApprovalsDecision action) =>
    _sortedLoaded.copyWith(
      busyIds: <int>{id},
      busyActions: <int, ApprovalsDecision>{id: action},
    );

/// Adds [event] only once the inbox has loaded, so the emission sequence has
/// no race between the stream's first delivery and the action.
Future<void> addAfterLoaded(ApprovalsBloc bloc, ApprovalsEvent event) async {
  bloc.add(const ApprovalsLoadRequested());
  await bloc.stream.firstWhere(
    (s) => s.status == ApprovalsStatus.loaded && s.actionError == null,
  );
  bloc.add(event);
}

/// Every failure reason is asserted by its message, never by "some error
/// happened"; combine it with `allOf` to also pin the rest of the state.
Matcher _withActionError(String needle) => predicate<ApprovalsState>(
  (s) => (s.actionError ?? '').contains(needle),
  'an actionError containing "$needle"',
);

/// Records every state the bloc emits and lets a test wait for a condition
/// without racing its own subscription or its own history.
///
/// `bloc.stream` is a broadcast stream: a handler that emits twice inside one
/// microtask turn (busy → cleared, or error → cleared) delivers both before a
/// continuation that awaited the FIRST of them can subscribe for the second.
/// Chaining `await bloc.stream.firstWhere(a); await bloc.stream.firstWhere(b);`
/// therefore hangs even though `b` was emitted. One listener plus a recorded
/// list cannot miss anything; `settled` polls the bloc's own `state`, so it
/// cannot be fooled by a state that was already seen either.
/// A hand-written repository that COUNTS its writes.
///
/// The absorb tests care about one thing — how many times `approve` /
/// `markNotYet` / `approveAll` were actually called — and the busy flag is
/// emitted one microtask BEFORE the call, so counting is both clearer and more
/// reliable than verifying a mock at a moment when the handler may not have
/// reached the repository yet.
class _CountingApprovalsRepository implements ApprovalsRepository {
  _CountingApprovalsRepository({Stream<List<Approval>>? watch})
    : _watch = watch ?? Stream.value(_streamOrder);

  final Stream<List<Approval>> _watch;

  /// Every id passed to `approve`, in call order.
  final List<int> approveCalls = <int>[];

  /// Every id passed to `markNotYet`, in call order.
  final List<int> notYetCalls = <int>[];

  int approveAllCalls = 0;

  /// When set, `approve(id)` throws it on the first call only.
  Object? failFirstApprove;

  /// When set, `approve(id)` waits for it — holds the card in its busy state.
  Completer<void>? approveGate;

  /// When set, `approveAll()` waits for it — holds the CTA busy.
  Completer<void>? approveAllGate;

  var _failed = false;

  @override
  Stream<List<Approval>> watchItems() => _watch;

  @override
  Future<List<Approval>> getItems() => _watch.first;

  @override
  Future<void> approve(int completionId) async {
    approveCalls.add(completionId);
    if (failFirstApprove != null && !_failed) {
      _failed = true;
      throw StateError('$failFirstApprove');
    }
    if (approveGate != null) await approveGate!.future;
  }

  @override
  Future<void> markNotYet(int completionId) async {
    notYetCalls.add(completionId);
  }

  @override
  Future<void> approveAll() async {
    approveAllCalls++;
    if (approveAllGate != null) await approveAllGate!.future;
  }
}

class _StateRecorder {
  _StateRecorder(this._bloc) {
    _subscription = _bloc.stream.listen(states.add);
  }

  final ApprovalsBloc _bloc;
  final List<ApprovalsState> states = <ApprovalsState>[];
  late final StreamSubscription<ApprovalsState> _subscription;

  /// How many states have been recorded — capture this BEFORE dispatching an
  /// event to assert "this event emitted nothing".
  int get length => states.length;

  /// Waits until the bloc's CURRENT state satisfies [test].
  ///
  /// Use it for "let the handler finish" — polling `bloc.state` cannot miss an
  /// emission. It deliberately cannot observe a TRANSIENT state (the busy flag
  /// lasts one microtask when the write is instant); use [until] for those.
  Future<void> settled(bool Function(ApprovalsState) test) =>
      _wait(() => test(_bloc.state), 'bloc.state');

  /// Waits until some emitted state satisfies [test] — for transient states
  /// ("did the busy flag ever appear") that a poll of the current state steps
  /// straight over, and for history assertions a settled state can no longer
  /// show.
  Future<void> until(bool Function(ApprovalsState) test) =>
      _wait(() => states.any(test), 'emitted states');

  Future<void> _wait(bool Function() done, String what) async {
    var spins = 0;
    while (!done()) {
      if (++spins > 1000) {
        fail(
          'timed out waiting for $what; saw: '
          '${states.map((s) => '${s.status}/${s.items.length}items/${s.busyIds}/${s.busyActions}/${s.actionError}').join(' -> ')}',
        );
      }
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<void> dispose() => _subscription.cancel();
}

void main() {
  late MockApprovalsRepository repo;

  setUp(() {
    repo = MockApprovalsRepository();
    when(repo.watchItems).thenAnswer((_) => Stream.value(_streamOrder));
  });

  // BUG-P11-1 landed its bloc half in iteration 2: a card absorbs a repeat
  // decision both while the write is in flight (`busyIds`) and after it
  // finished (`_decided`), because with an instant write the second tap can
  // arrive after the busy flag has already cleared. One decision per card, one
  // ledger row. The database CAS is the backstop for every other path; these
  // tests pin the bloc contract so a regression is caught here and not in a
  // money-amount assertion.
  group('ApprovalsBloc decision absorb (BUG-P11-1)', () {
    test(
      'a second approve while the write is in flight never reaches the repo',
      () async {
        final gate = Completer<void>();
        final counting = _CountingApprovalsRepository()..approveGate = gate;
        final bloc = ApprovalsBloc(repository: counting);
        final seen = _StateRecorder(bloc);
        addTearDown(() async {
          if (!gate.isCompleted) gate.complete();
          await seen.dispose();
          await bloc.close();
        });

        bloc.add(const ApprovalsLoadRequested());
        await seen.settled((s) => s.status == ApprovalsStatus.loaded);
        bloc.add(const ApprovalsApproveRequested(completionId: 1));
        await seen.until((s) => s.busyIds.contains(1));
        final emissionsBefore = seen.length;

        // The same frame a second tap: absorbed, so NO new emission at all.
        bloc.add(const ApprovalsApproveRequested(completionId: 1));
        await pumpEventQueue();
        expect(seen.length, emissionsBefore);
        expect(counting.approveCalls, <int>[1], reason: 'one write, one row');
        expect(bloc.state.busyActions, <int, ApprovalsDecision>{
          1: ApprovalsDecision.approve,
        });

        gate.complete();
        await seen.settled((s) => s.busyIds.isEmpty && s.busyActions.isEmpty);
        expect(bloc.state.busyActions, isEmpty);
        expect(counting.approveCalls, <int>[1]);
      },
    );

    test(
      'a repeat approve AFTER the write finished is still absorbed',
      () async {
        final counting = _CountingApprovalsRepository();
        final bloc = ApprovalsBloc(repository: counting);
        final seen = _StateRecorder(bloc);
        addTearDown(() async {
          await seen.dispose();
          await bloc.close();
        });

        bloc.add(const ApprovalsLoadRequested());
        await seen.settled((s) => s.status == ApprovalsStatus.loaded);

        bloc.add(const ApprovalsApproveRequested(completionId: 1));
        await seen.until((s) => s.busyIds.contains(1));
        await seen.settled((s) => s.busyIds.isEmpty && s.busyActions.isEmpty);
        await pumpEventQueue();
        expect(counting.approveCalls, <int>[1]);

        // Busy flag is clear again, yet the row is still on screen with a
        // live button: the decision must not be replayed.
        final before = seen.length;
        bloc.add(const ApprovalsApproveRequested(completionId: 1));
        await pumpEventQueue();
        expect(seen.length, before, reason: 'absorbed: no new state at all');
        expect(counting.approveCalls, <int>[1]);
        expect(bloc.state.busyIds, isEmpty);
        expect(bloc.state.busyActions, isEmpty);

        // A DIFFERENT card is still fully actionable.
        bloc.add(const ApprovalsApproveRequested(completionId: 2));
        await seen.until((s) => s.busyIds.contains(2));
        await seen.settled((s) => s.busyIds.isEmpty && s.busyActions.isEmpty);
        await pumpEventQueue();
        expect(counting.approveCalls, <int>[1, 2]);
      },
    );

    test('a not-yet decision is absorbed the same way', () async {
      final counting = _CountingApprovalsRepository();
      final bloc = ApprovalsBloc(repository: counting);
      final seen = _StateRecorder(bloc);
      addTearDown(() async {
        await seen.dispose();
        await bloc.close();
      });

      bloc.add(const ApprovalsLoadRequested());
      await seen.settled((s) => s.status == ApprovalsStatus.loaded);
      bloc.add(const ApprovalsNotYetRequested(completionId: 2));
      await seen.until((s) => s.busyIds.contains(2));
      await seen.settled((s) => s.busyIds.isEmpty && s.busyActions.isEmpty);
      await pumpEventQueue();

      bloc
        ..add(const ApprovalsNotYetRequested(completionId: 2))
        ..add(const ApprovalsApproveRequested(completionId: 2));
      await pumpEventQueue();
      // One decision per card: neither the repeat nor the flip reaches the
      // repository, so the card cannot end up `not_yet` with a bonus row
      // (BUG-P11-2's screen-level half).
      expect(counting.notYetCalls, <int>[2]);
      expect(counting.approveCalls, isEmpty);
      expect(bloc.state.busyIds, isEmpty);
    });

    test(
      'a failed decision is NOT absorbed, so the parent can retry',
      () async {
        final counting = _CountingApprovalsRepository()
          ..failFirstApprove = 'write failed';
        final bloc = ApprovalsBloc(repository: counting);
        final seen = _StateRecorder(bloc);
        addTearDown(() async {
          await seen.dispose();
          await bloc.close();
        });

        bloc.add(const ApprovalsLoadRequested());
        await seen.settled((s) => s.status == ApprovalsStatus.loaded);

        bloc.add(const ApprovalsApproveRequested(completionId: 1));
        await seen.until((s) => s.actionError != null);
        await seen.settled((s) => s.busyIds.isEmpty && s.busyActions.isEmpty);
        await pumpEventQueue();
        expect(counting.approveCalls, <int>[1]);
        expect(
          seen.states.map((s) => s.actionError).whereType<String>().join(),
          contains('write failed'),
        );

        bloc.add(const ApprovalsActionErrorConsumed());
        await seen.settled((s) => s.actionError == null && s.busyIds.isEmpty);

        // A failure must not poison the card: the retry reaches the
        // repository.
        bloc.add(const ApprovalsApproveRequested(completionId: 1));
        await seen.until((s) => s.busyActions[1] == ApprovalsDecision.approve);
        await seen.settled((s) => s.busyIds.isEmpty && s.busyActions.isEmpty);
        await pumpEventQueue();
        expect(counting.approveCalls, <int>[
          1,
          1,
        ], reason: 'the retry really hit the repository');
      },
    );

    test('a decided id is released once the row leaves the inbox', () async {
      // `_decided` is pruned on every stream emission; ids are never reused in
      // production, but the pruning is what keeps the set from growing for the
      // lifetime of a long session.
      final controller = StreamController<List<Approval>>();
      final counting = _CountingApprovalsRepository(watch: controller.stream);
      final bloc = ApprovalsBloc(repository: counting);
      final seen = _StateRecorder(bloc);
      addTearDown(() async {
        await seen.dispose();
        if (!controller.isClosed) await controller.close();
        await bloc.close();
      });

      bloc.add(const ApprovalsLoadRequested());
      controller.add(_streamOrder);
      await seen.settled((s) => s.status == ApprovalsStatus.loaded);

      bloc.add(const ApprovalsApproveRequested(completionId: 1));
      await seen.until((s) => s.busyIds.contains(1));
      await seen.settled((s) => s.busyIds.isEmpty && s.busyActions.isEmpty);
      await pumpEventQueue();
      final mark = seen.length;
      bloc.add(const ApprovalsApproveRequested(completionId: 1));
      await pumpEventQueue();
      expect(seen.length, mark, reason: 'still absorbed: the row is visible');
      expect(counting.approveCalls, <int>[1]);

      // The inbox re-emits WITHOUT that row (a real write removes it).
      controller.add(<Approval>[_bed, _table]);
      await seen.settled((s) => s.items.length == 2);

      // Same id decided again is allowed now that the row is gone — the guard
      // is about the visible card, not a permanent blacklist.
      bloc.add(const ApprovalsApproveRequested(completionId: 1));
      await seen.until((s) => s.busyIds.contains(1));
      await seen.settled((s) => s.busyIds.isEmpty && s.busyActions.isEmpty);
      await pumpEventQueue();
      expect(counting.approveCalls, <int>[1, 1]);
    });

    test(
      'a second approve-all while the write is in flight is absorbed',
      () async {
        final gate = Completer<void>();
        final counting = _CountingApprovalsRepository()..approveAllGate = gate;
        final bloc = ApprovalsBloc(repository: counting);
        final seen = _StateRecorder(bloc);
        addTearDown(() async {
          if (!gate.isCompleted) gate.complete();
          await seen.dispose();
          await bloc.close();
        });

        bloc.add(const ApprovalsLoadRequested());
        await seen.settled((s) => s.status == ApprovalsStatus.loaded);
        bloc.add(const ApprovalsApproveAllRequested());
        await seen.until((s) => s.approveAllBusy);
        // Second tap on the CTA while the bulk write is running.
        final emissionsBefore = seen.length;
        bloc.add(const ApprovalsApproveAllRequested());
        await pumpEventQueue();
        expect(seen.length, emissionsBefore, reason: 'absorbed');
        expect(counting.approveAllCalls, 1, reason: 'one bulk write');
        expect(bloc.state.approveAllBusy, isTrue);
        gate.complete();
      },
    );
  });

  group('ApprovalsBloc concurrent writes', () {
    test('two approvals in flight hold both busy ids', () async {
      final gateOne = Completer<void>();
      final gateTwo = Completer<void>();
      final calls = <int>[];
      when(() => repo.approve(1)).thenAnswer((_) {
        calls.add(1);
        return gateOne.future;
      });
      when(() => repo.approve(2)).thenAnswer((_) {
        calls.add(2);
        return gateTwo.future;
      });
      final bloc = ApprovalsBloc(repository: repo);
      addTearDown(() async {
        if (!gateOne.isCompleted) gateOne.complete();
        if (!gateTwo.isCompleted) gateTwo.complete();
        await bloc.close();
      });

      bloc.add(const ApprovalsLoadRequested());
      await bloc.stream.firstWhere((s) => s.status == ApprovalsStatus.loaded);

      final both = bloc.stream.firstWhere((s) => s.busyIds.length == 2);
      bloc
        ..add(const ApprovalsApproveRequested(completionId: 1))
        ..add(const ApprovalsApproveRequested(completionId: 2));

      expect((await both).busyIds, <int>{1, 2});
      expect((await both).busyActions, <int, ApprovalsDecision>{
        1: ApprovalsDecision.approve,
        2: ApprovalsDecision.approve,
      });
      expect(calls, <int>[1, 2], reason: 'neither write may swallow the other');

      final one = bloc.stream.firstWhere((s) => s.busyIds.length == 1);
      gateOne.complete();
      final survivor = await one;
      expect(survivor.busyIds, <int>{
        2,
      }, reason: 'only the finished write clears');
      expect(survivor.busyActions, <int, ApprovalsDecision>{
        2: ApprovalsDecision.approve,
      });

      final none = bloc.stream.firstWhere((s) => s.busyIds.isEmpty);
      gateTwo.complete();
      expect((await none).busyIds, isEmpty);
      expect(
        bloc.state.items,
        hasLength(3),
        reason: 'the mocked stream never changed',
      );
    });

    test(
      'a stream re-emission re-sorts without clearing an in-flight write',
      () async {
        final controller = StreamController<List<Approval>>();
        final gate = Completer<void>();
        when(repo.watchItems).thenAnswer((_) => controller.stream);
        when(() => repo.approve(1)).thenAnswer((_) => gate.future);
        final bloc = ApprovalsBloc(repository: repo);
        addTearDown(() async {
          if (!gate.isCompleted) gate.complete();
          if (!controller.isClosed) await controller.close();
          await bloc.close();
        });

        final twoRows = bloc.stream.firstWhere(
          (s) => s.status == ApprovalsStatus.loaded && s.items.length == 2,
        );
        bloc.add(const ApprovalsLoadRequested());
        controller.add(<Approval>[_bed, _table]);
        expect((await twoRows).items, <Approval>[
          _table,
          _bed,
        ], reason: 'oldest-first in, newest-first out');

        final busy = bloc.stream.firstWhere((s) => s.busyIds.isNotEmpty);
        bloc.add(const ApprovalsApproveRequested(completionId: 1));
        expect((await busy).busyIds, <int>{1});

        final fourRows = bloc.stream.firstWhere((s) => s.items.length == 4);
        controller.add(<Approval>[_bed, _table, _dishwasher, _newest]);
        final resorted = await fourRows;
        expect(resorted.items, <Approval>[_newest, _dishwasher, _table, _bed]);
        expect(
          resorted.busyActions,
          <int, ApprovalsDecision>{1: ApprovalsDecision.approve},
          reason:
              'the sort in onData rebuilds the state from the current one — a '
              'stream emission must not re-enable a button mid-write',
        );

        final cleared = bloc.stream.firstWhere((s) => s.busyIds.isEmpty);
        gate.complete();
        await cleared;
        expect(bloc.state.busyIds, isEmpty);
      },
    );

    test('a stream re-emission keeps approveAllBusy set', () async {
      final controller = StreamController<List<Approval>>();
      final gate = Completer<void>();
      when(repo.watchItems).thenAnswer((_) => controller.stream);
      when(repo.approveAll).thenAnswer((_) => gate.future);
      final bloc = ApprovalsBloc(repository: repo);
      addTearDown(() async {
        if (!gate.isCompleted) gate.complete();
        if (!controller.isClosed) await controller.close();
        await bloc.close();
      });

      final loaded = bloc.stream.firstWhere(
        (s) => s.status == ApprovalsStatus.loaded,
      );
      bloc.add(const ApprovalsLoadRequested());
      controller.add(_streamOrder);
      await loaded;

      final bulkBusy = bloc.stream.firstWhere((s) => s.approveAllBusy);
      bloc.add(const ApprovalsApproveAllRequested());
      await bulkBusy;

      final stillBusy = bloc.stream.firstWhere((s) => s.items.length == 1);
      controller.add(<Approval>[_bed]);
      expect(
        (await stillBusy).approveAllBusy,
        isTrue,
        reason: 'the CTA must stay locked for the whole approve-all write',
      );

      final done = bloc.stream.firstWhere((s) => !s.approveAllBusy);
      gate.complete();
      expect((await done).approveAllBusy, isFalse);
    });

    test(
      'the stream draining to empty lands on an empty loaded inbox',
      () async {
        final controller = StreamController<List<Approval>>();
        when(repo.watchItems).thenAnswer((_) => controller.stream);
        final bloc = ApprovalsBloc(repository: repo);
        addTearDown(() async {
          if (!controller.isClosed) await controller.close();
          await bloc.close();
        });

        final loaded = bloc.stream.firstWhere(
          (s) => s.status == ApprovalsStatus.loaded,
        );
        bloc.add(const ApprovalsLoadRequested());
        controller.add(_streamOrder);
        await loaded;

        final drained = bloc.stream.firstWhere(
          (s) => s.status == ApprovalsStatus.loaded && s.items.isEmpty,
        );
        controller.add(<Approval>[]);

        final state = await drained;
        expect(state.items, isEmpty);
        expect(
          state.status,
          ApprovalsStatus.loaded,
          reason: 'an empty inbox is loaded, not a failure',
        );
        expect(state.errorMessage, isNull);
      },
    );
  });

  group('ApprovalsBloc failure and retry', () {
    blocTest<ApprovalsBloc, ApprovalsState>(
      'a failed stream can be retried and recovers into the inbox',
      build: () {
        var attempts = 0;
        when(repo.watchItems).thenAnswer((_) {
          attempts++;
          return attempts == 1
              ? Stream<List<Approval>>.error(StateError('inbox is down'))
              : Stream<List<Approval>>.value(_streamOrder);
        });
        return ApprovalsBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const ApprovalsLoadRequested());
        await bloc.stream.firstWhere(
          (s) => s.status == ApprovalsStatus.failure,
        );
        bloc.add(const ApprovalsLoadRequested());
      },
      expect: () => [
        _loading,
        predicate<ApprovalsState>(
          (s) =>
              s.status == ApprovalsStatus.failure &&
              (s.errorMessage ?? '').contains('inbox is down'),
        ),
        // `copyWith` cannot null a field, so `errorMessage` survives the retry
        // (only a fresh bloc drops it). That is invisible to the parent — the
        // loaded branch never reads it — so what is pinned here is that the
        // retry leaves the failure state and lands back on the inbox.
        predicate<ApprovalsState>(
          (s) =>
              s.status == ApprovalsStatus.loading &&
              (s.errorMessage ?? '').contains('inbox is down'),
        ),
        predicate<ApprovalsState>(
          (s) =>
              s.status == ApprovalsStatus.loaded &&
              s.items.length == 3 &&
              s.busyIds.isEmpty &&
              !s.approveAllBusy,
        ),
      ],
    );

    blocTest<ApprovalsBloc, ApprovalsState>(
      'a not-yet failure sets actionError and clears the busy id',
      build: () {
        when(() => repo.markNotYet(any())).thenThrow(Exception('note failed'));
        return ApprovalsBloc(repository: repo);
      },
      act: (bloc) =>
          addAfterLoaded(bloc, const ApprovalsNotYetRequested(completionId: 2)),
      expect: () => [
        _loading,
        _sortedLoaded,
        _busy(2, ApprovalsDecision.notYet),
        allOf(
          _withActionError('note failed'),
          predicate<ApprovalsState>((s) => s.busyIds.contains(2)),
        ),
        allOf(
          _withActionError('note failed'),
          predicate<ApprovalsState>((s) => s.busyIds.isEmpty),
        ),
      ],
      verify: (_) {
        verify(() => repo.markNotYet(2)).called(1);
        verifyNever(() => repo.approve(any()));
      },
    );

    blocTest<ApprovalsBloc, ApprovalsState>(
      'consuming an action error that was never set emits nothing',
      build: () => ApprovalsBloc(repository: repo),
      act: (bloc) => addAfterLoaded(bloc, const ApprovalsActionErrorConsumed()),
      expect: () => [_loading, _sortedLoaded],
      verify: (_) {
        // A no-op must not touch the repository either.
        verifyNever(() => repo.approve(any()));
        verifyNever(() => repo.markNotYet(any()));
        verifyNever(repo.approveAll);
      },
    );
  });

  group('ApprovalsState', () {
    test('copyWith() with no arguments returns an equal state', () {
      final state = ApprovalsState(
        status: ApprovalsStatus.loaded,
        items: <Approval>[_dishwasher],
        busyIds: const <int>{1},
        approveAllBusy: true,
        actionError: 'boom',
      );
      expect(state.copyWith(), state);
    });

    test('clearActionError nulls the message and keeps every other field', () {
      final state = ApprovalsState(
        status: ApprovalsStatus.loaded,
        items: <Approval>[_dishwasher],
        errorMessage: 'stream is down',
        busyIds: const <int>{1},
        approveAllBusy: true,
        actionError: 'boom',
      );
      final cleared = state.copyWith(clearActionError: true);
      expect(cleared.actionError, isNull);
      expect(cleared.status, ApprovalsStatus.loaded);
      expect(cleared.items, <Approval>[_dishwasher]);
      expect(cleared.errorMessage, 'stream is down');
      expect(cleared.busyIds, <int>{1});
      expect(cleared.approveAllBusy, isTrue);
    });

    test('copyWith only touches the fields it is given', () {
      // `actionError` has an implicit `null` default, so a copy that does not
      // mention it must leave it alone — only `clearActionError: true` clears.
      const state = ApprovalsState(
        status: ApprovalsStatus.loaded,
        actionError: 'boom',
      );
      expect(state.copyWith(approveAllBusy: true).actionError, 'boom');
      expect(
        state.copyWith(status: ApprovalsStatus.failure).actionError,
        'boom',
      );
      expect(state.copyWith(busyIds: const <int>{1}).actionError, 'boom');
      expect(state.copyWith(actionError: 'other').actionError, 'other');
    });

    test('every field takes part in equality', () {
      const base = ApprovalsState(status: ApprovalsStatus.loaded);
      expect(base, isNot(base.copyWith(status: ApprovalsStatus.loading)));
      expect(base, isNot(base.copyWith(items: <Approval>[_bed])));
      expect(base, isNot(base.copyWith(errorMessage: 'x')));
      expect(base, isNot(base.copyWith(busyIds: const <int>{1})));
      expect(base, isNot(base.copyWith(approveAllBusy: true)));
      expect(base, isNot(base.copyWith(actionError: 'x')));
      expect(base.copyWith(), base);
    });

    test('the default inbox is empty and idle', () {
      const state = ApprovalsState();
      expect(state.status, ApprovalsStatus.initial);
      expect(state.items, isEmpty);
      expect(state.busyIds, isEmpty);
      expect(state.approveAllBusy, isFalse);
      expect(state.actionError, isNull);
      expect(state.errorMessage, isNull);
    });
  });
}
