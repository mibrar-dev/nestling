// P13 Payout — bloc submit path for `/payout`.
//
// `PocketMoneyPayoutSubmitted` is write-through (mirroring the P12 add/spend
// submits): the bloc forwards (childId, amount, savings, goal) to
// `recordPayout` and emits nothing until the `watchLedgerData` stream
// re-emits. A rejected write keeps the loaded sheet and sets the friendly
// `We couldn’t save that` message (curly ’ U+2019, same `_submitErrorMessage`
// as P12) without leaving `loaded`.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_ledger_data.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_bloc.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_event.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_state.dart';

import 'ledger_data_fallback.dart';

/// The `Seed.demo` setup, carried inside every `MoneyLedgerData`.
const PocketMoneySetup _demoSetup = PocketMoneySetup(
  mode: 'both',
  payoutDay: 6,
  coinValuePencePerCoin: 1,
  children: <PocketMoneySetupChild>[
    PocketMoneySetupChild(
      id: 'maya',
      nickname: 'Maya',
      avatarColour: 'lilac',
      weeklyBasePence: 300,
    ),
    PocketMoneySetupChild(
      id: 'leo',
      nickname: 'Leo',
      avatarColour: 'peach',
      weeklyBasePence: 150,
    ),
  ],
);

/// Fake whose load path flows through the shared test fallback (setup ×
/// items, no goals) and whose payout writes are recorded instead of
/// performed. Throws when [refusePayout] is set.
class _PayoutRecordingRepository implements PocketMoneyRepository {
  _PayoutRecordingRepository({this.refusePayout = false});

  final bool refusePayout;

  /// `childId:amountPence:savingsMovePence:goalId` per accepted write, in
  /// creation-order dispatch order (the view sends one event per ticked
  /// child, Maya before Leo).
  final List<String> payoutCalls = <String>[];

  @override
  Future<List<PocketMoneyEntry>> getItems() => watchItems().first;

  @override
  Stream<List<PocketMoneyEntry>> watchItems() =>
      Stream<List<PocketMoneyEntry>>.value(const <PocketMoneyEntry>[]);

  @override
  Stream<List<PocketMoneyEntry>> watchLedger(String childId) => watchItems();

  @override
  Stream<MoneyLedgerData> watchLedgerData() =>
      ledgerDataFallback(watchSetup(), watchItems());

  @override
  Future<OwedSummary> owed(String childId) => watchOwed(childId).first;

  @override
  Stream<OwedSummary> watchOwed(String childId) => Stream<OwedSummary>.value(
    OwedSummary(childId: childId, totalPence: 0, basePence: 0, questsPence: 0),
  );

  @override
  Future<void> addMoney({
    required String childId,
    required int amountPence,
    required String note,
  }) async {}

  @override
  Future<void> recordSpending({
    required String childId,
    required int amountPence,
    required String note,
  }) async {}

  @override
  Future<void> recordPayout({
    required String childId,
    required int amountPence,
    int savingsMovePence = 0,
    String? goalId,
  }) async {
    if (refusePayout) throw Exception('payout refused');
    payoutCalls.add('$childId:$amountPence:$savingsMovePence:$goalId');
  }

  @override
  Stream<PocketMoneySetup> watchSetup() =>
      Stream<PocketMoneySetup>.value(_demoSetup);

  @override
  Future<void> setMode(String mode) async {}

  @override
  Future<void> setPayoutDay(int day) async {}

  @override
  Future<void> setWeeklyBasePence(String childId, int pence) async {}
}

/// Same recording load path, but the payout write hangs on [gate] until the
/// test releases it — so the double-tap race (P13-BUG-01) is deterministic
/// instead of timing-dependent.
class _GatedPayoutRepository extends _PayoutRecordingRepository {
  Completer<void> gate = Completer<void>();

  @override
  Future<void> recordPayout({
    required String childId,
    required int amountPence,
    int savingsMovePence = 0,
    String? goalId,
  }) async {
    payoutCalls.add('$childId:$amountPence:$savingsMovePence:$goalId');
    await gate.future;
  }
}

Future<PocketMoneyBloc> _loadedBloc(PocketMoneyRepository repository) async {
  final bloc = PocketMoneyBloc(repository: repository)
    ..add(const PocketMoneyLoadRequested());
  await bloc.stream.firstWhere(
    (state) => state.status == PocketMoneyStatus.loaded,
  );
  return bloc;
}

void main() {
  group('PocketMoneyBloc — P13 payout submit', () {
    test('forwards the savings move: (maya, 420, 100, goal-lego)', () async {
      final repository = _PayoutRecordingRepository();
      final bloc = await _loadedBloc(repository);
      addTearDown(bloc.close);
      final afterLoad = repository.payoutCalls.length;

      bloc.add(const PocketMoneyPayoutSubmitted('maya', 420, 100, 'goal-lego'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repository.payoutCalls, <String>['maya:420:100:goal-lego']);
      expect(repository.payoutCalls.length, afterLoad + 1);
      expect(bloc.state.status, PocketMoneyStatus.loaded);
      expect(bloc.state.errorMessage, isNull);
    });

    test('zero-save variant passes (0, null)', () async {
      final repository = _PayoutRecordingRepository();
      final bloc = await _loadedBloc(repository);
      addTearDown(bloc.close);

      // Leo has no goal: no savings move, no goal id.
      bloc.add(const PocketMoneyPayoutSubmitted('leo', 210, 0, null));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repository.payoutCalls, <String>['leo:210:0:null']);
      expect(bloc.state.status, PocketMoneyStatus.loaded);
      expect(bloc.state.errorMessage, isNull);
    });

    test(
      'a rejected payout keeps loaded and sets the friendly message',
      () async {
        final repository = _PayoutRecordingRepository(refusePayout: true);
        final bloc = await _loadedBloc(repository);
        addTearDown(bloc.close);

        bloc.add(
          const PocketMoneyPayoutSubmitted('maya', 420, 100, 'goal-lego'),
        );
        final failed = await bloc.stream.firstWhere(
          (state) => state.errorMessage != null,
        );

        expect(
          failed.errorMessage,
          'We couldn\u2019t save that: Exception: payout refused',
        );
        expect(failed.status, PocketMoneyStatus.loaded);
        expect(failed.status, isNot(PocketMoneyStatus.failure));
      },
    );

    test('an accepted submit emits nothing optimistically', () async {
      final repository = _PayoutRecordingRepository();
      final bloc = await _loadedBloc(repository);
      addTearDown(bloc.close);

      final seen = <PocketMoneyState>[];
      final subscription = bloc.stream.listen(seen.add);
      addTearDown(subscription.cancel);

      bloc.add(const PocketMoneyPayoutSubmitted('maya', 420, 100, 'goal-lego'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(
        seen,
        isEmpty,
        reason: 'a write-through submit must not emit optimistically',
      );
      expect(repository.payoutCalls, hasLength(1));
    });

    test('a duplicate submit while the write is in flight is dropped '
        '(P13-BUG-01)', () async {
      final repository = _GatedPayoutRepository();
      final bloc = await _loadedBloc(repository);
      addTearDown(bloc.close);

      bloc.add(const PocketMoneyPayoutSubmitted('maya', 420, 100, 'goal-lego'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repository.payoutCalls, hasLength(1));

      // The second tap (same child, same amounts) lands while the first
      // write is still held by the gate: it must not reach the repository.
      bloc.add(const PocketMoneyPayoutSubmitted('maya', 420, 100, 'goal-lego'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(
        repository.payoutCalls,
        hasLength(1),
        reason: 'the in-flight duplicate must be dropped before its write',
      );

      repository.gate.complete();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repository.payoutCalls, hasLength(1));
      expect(bloc.state.status, PocketMoneyStatus.loaded);
      expect(bloc.state.errorMessage, isNull);
    });

    test(
      'a ticked sibling still proceeds while another child is in flight',
      () async {
        final repository = _GatedPayoutRepository();
        final bloc = await _loadedBloc(repository);
        addTearDown(bloc.close);

        bloc.add(
          const PocketMoneyPayoutSubmitted('maya', 420, 100, 'goal-lego'),
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));
        // Leo's payout is a different child: the guard is per-child, not
        // global, so the view's one-event-per-ticked-child dispatch still
        // lands for every sibling.
        bloc.add(const PocketMoneyPayoutSubmitted('leo', 210, 0, null));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(repository.payoutCalls, <String>[
          'maya:420:100:goal-lego',
          'leo:210:0:null',
        ]);

        repository.gate.complete();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(repository.payoutCalls, hasLength(2));
      },
    );

    test('a retry after an identical failure surfaces the message again '
        '(P13-BUG-04)', () async {
      final repository = _PayoutRecordingRepository(refusePayout: true);
      final bloc = await _loadedBloc(repository);
      addTearDown(bloc.close);

      const submit = PocketMoneyPayoutSubmitted('maya', 420, 100, 'goal-lego');
      bloc.add(submit);
      await bloc.stream.firstWhere((s) => s.errorMessage != null);

      final messages = <String?>[];
      final subscription = bloc.stream
          .map((s) => s.errorMessage)
          .listen(messages.add);
      addTearDown(subscription.cancel);

      bloc.add(submit);
      final second = await bloc.stream
          .firstWhere((s) => s.errorMessage != null)
          .timeout(const Duration(seconds: 5));

      expect(
        second.errorMessage,
        'We couldn\u2019t save that: Exception: payout refused',
      );
      // The retry cleared the stale message first (null), so the repeat
      // failure is a state change again instead of a suppressed equal.
      expect(messages, contains(isNull));
      expect(second.status, PocketMoneyStatus.loaded);
    });
  });
}
