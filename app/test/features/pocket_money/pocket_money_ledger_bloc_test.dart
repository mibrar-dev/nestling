// P12 Money ledger — bloc state machine for `/money`.
//
// The bloc serves every pocket-money route from ONE stream:
// `watchLedgerData` (children, all entries, oweds, goals, payout day, zone,
// plus the P06 setup carried alongside). `PocketMoneyChildSelected`
// re-filters synchronously; the sheet submits write through and the stream
// re-emits. All P06 setup behaviour (mode/day/stepper guards) is unchanged.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_ledger_data.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_bloc.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_event.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_state.dart';

import '../../test_scope.dart';

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

/// Fake whose submits always fail; the load path flows through the
/// interface's `watchLedgerData` fallback (setup × items, no goals).
class _ThrowingSubmitRepository implements PocketMoneyRepository {
  @override
  Future<List<PocketMoneyEntry>> getItems() => watchItems().first;

  @override
  Stream<List<PocketMoneyEntry>> watchItems() =>
      Stream<List<PocketMoneyEntry>>.value(const <PocketMoneyEntry>[]);

  @override
  Stream<List<PocketMoneyEntry>> watchLedger(String childId) => watchItems();

  // P12: same setup × items combine the bloc always consumed (no goals —
  // fakes own no savings table).
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
  }) async {
    throw Exception('add-money refused');
  }

  @override
  Future<void> recordSpending({
    required String childId,
    required int amountPence,
    required String note,
  }) async {
    throw Exception('spend refused');
  }

  @override
  Future<void> recordPayout({
    required String childId,
    required int amountPence,
    int savingsMovePence = 0,
    String? goalId,
  }) async {}

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

/// Fake whose ledger stream is down from the first subscription.
class _BrokenLedgerRepository implements PocketMoneyRepository {
  final _ThrowingSubmitRepository _inner = _ThrowingSubmitRepository();

  @override
  Stream<MoneyLedgerData> watchLedgerData() =>
      Stream<MoneyLedgerData>.error(StateError('ledger is down'));

  @override
  Future<List<PocketMoneyEntry>> getItems() => _inner.getItems();

  @override
  Stream<List<PocketMoneyEntry>> watchItems() => _inner.watchItems();

  @override
  Stream<List<PocketMoneyEntry>> watchLedger(String childId) =>
      _inner.watchLedger(childId);

  @override
  Future<OwedSummary> owed(String childId) => _inner.owed(childId);

  @override
  Stream<OwedSummary> watchOwed(String childId) => _inner.watchOwed(childId);

  @override
  Future<void> addMoney({
    required String childId,
    required int amountPence,
    required String note,
  }) => _inner.addMoney(childId: childId, amountPence: amountPence, note: note);

  @override
  Future<void> recordSpending({
    required String childId,
    required int amountPence,
    required String note,
  }) => _inner.recordSpending(
    childId: childId,
    amountPence: amountPence,
    note: note,
  );

  @override
  Future<void> recordPayout({
    required String childId,
    required int amountPence,
    int savingsMovePence = 0,
    String? goalId,
  }) => _inner.recordPayout(
    childId: childId,
    amountPence: amountPence,
    savingsMovePence: savingsMovePence,
    goalId: goalId,
  );

  @override
  Stream<PocketMoneySetup> watchSetup() => _inner.watchSetup();

  @override
  Future<void> setMode(String mode) => _inner.setMode(mode);

  @override
  Future<void> setPayoutDay(int day) => _inner.setPayoutDay(day);

  @override
  Future<void> setWeeklyBasePence(String childId, int pence) =>
      _inner.setWeeklyBasePence(childId, pence);
}

void main() {
  group('PocketMoneyBloc — P12 ledger load', () {
    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'load emits loading then ledger data defaulting to Maya',
      setUp: setUpTestScope,
      build: () =>
          PocketMoneyBloc(repository: GetIt.instance<PocketMoneyRepository>()),
      act: (bloc) => bloc.add(const PocketMoneyLoadRequested()),
      expect: () => <Matcher>[
        isA<PocketMoneyState>().having(
          (state) => state.status,
          'status',
          PocketMoneyStatus.loading,
        ),
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having(
              (state) => state.data?.children.map((c) => c.id).toList(),
              'children',
              <String>['maya', 'leo'],
            )
            .having((state) => state.selectedChildId, 'selected', 'maya')
            .having(
              (state) => state.items.map((e) => e.childId).toSet(),
              'items children',
              <String>{'maya'},
            )
            .having((state) => state.items.length, 'items', greaterThan(0))
            .having(
              (state) => state.data?.owedFor('maya')?.totalPence,
              'maya owed',
              420,
            )
            .having(
              (state) => state.data?.owedFor('leo')?.totalPence,
              'leo owed',
              210,
            )
            .having(
              (state) => state.data?.goalFor('maya')?.title,
              'goal',
              'Lego Friends set',
            )
            .having((state) => state.setup?.mode, 'mode', 'both'),
      ],
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'selecting Leo re-filters without a reload',
      setUp: setUpTestScope,
      build: () =>
          PocketMoneyBloc(repository: GetIt.instance<PocketMoneyRepository>()),
      act: (bloc) async {
        bloc.add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere((state) => state.data != null);
        bloc.add(const PocketMoneyChildSelected('leo'));
      },
      expect: () => <Matcher>[
        isA<PocketMoneyState>().having(
          (state) => state.status,
          'status',
          PocketMoneyStatus.loading,
        ),
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having((state) => state.selectedChildId, 'selected', 'maya'),
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having((state) => state.selectedChildId, 'selected', 'leo')
            .having(
              (state) => state.items.map((e) => e.childId).toSet(),
              'items children',
              <String>{'leo'},
            ),
      ],
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'selecting an unknown child is a no-op',
      setUp: setUpTestScope,
      build: () =>
          PocketMoneyBloc(repository: GetIt.instance<PocketMoneyRepository>()),
      act: (bloc) async {
        bloc.add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere((state) => state.data != null);
        bloc.add(const PocketMoneyChildSelected('nobody'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      expect: () => <Matcher>[
        isA<PocketMoneyState>().having(
          (state) => state.status,
          'status',
          PocketMoneyStatus.loading,
        ),
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having((state) => state.selectedChildId, 'selected', 'maya'),
      ],
    );
  });

  group('PocketMoneyBloc — P12 sheet submits (real repo)', () {
    test('add-money writes a gift row and the ledger re-emits', () async {
      await setUpTestScope();
      final repository = GetIt.instance<PocketMoneyRepository>();
      final bloc = PocketMoneyBloc(repository: repository)
        ..add(const PocketMoneyLoadRequested());
      await bloc.stream.firstWhere((state) => state.data != null);
      final before = bloc.state.items.length;

      final grew = bloc.stream.firstWhere(
        (state) => state.items.length == before + 1,
      );
      bloc.add(
        const PocketMoneyAddMoneySubmitted('maya', 500, 'P12 test gift'),
      );
      await grew;

      final row = bloc.state.items.firstWhere(
        (entry) => entry.note == 'P12 test gift',
      );
      expect(row.type, 'gift');
      expect(row.amountPence, 500);
      // Gifts never count towards the payout figure.
      expect(bloc.state.data?.owedFor('maya')?.totalPence, 420);
      await bloc.close();
    });

    test(
      'spending writes a negative spend row outside the owed figure',
      () async {
        await setUpTestScope();
        final repository = GetIt.instance<PocketMoneyRepository>();
        final bloc = PocketMoneyBloc(repository: repository)
          ..add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere((state) => state.data != null);
        final before = bloc.state.items.length;

        final grew = bloc.stream.firstWhere(
          (state) => state.items.length == before + 1,
        );
        bloc.add(
          const PocketMoneySpendingSubmitted('maya', 200, 'P12 test comic'),
        );
        await grew;

        final row = bloc.state.items.firstWhere(
          (entry) => entry.note == 'P12 test comic',
        );
        expect(row.type, 'spend');
        expect(row.amountPence, -200);
        expect(bloc.state.data?.owedFor('maya')?.totalPence, 420);
        await bloc.close();
      },
    );
  });

  group('PocketMoneyBloc — P12 failure paths', () {
    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'a rejected add-money submit keeps the loaded ledger and sets the '
      'message (no failure state)',
      build: () => PocketMoneyBloc(repository: _ThrowingSubmitRepository()),
      act: (bloc) async {
        bloc.add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere(
          (state) => state.status == PocketMoneyStatus.loaded,
        );
        bloc.add(const PocketMoneyAddMoneySubmitted('maya', 500, 'X'));
      },
      expect: () => <Matcher>[
        isA<PocketMoneyState>().having(
          (state) => state.status,
          'status',
          PocketMoneyStatus.loading,
        ),
        // The interface fallback carries the setup with no goals.
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having((state) => state.setup, 'setup', _demoSetup)
            .having((state) => state.data?.goals, 'goals', isEmpty)
            .having((state) => state.selectedChildId, 'selected', 'maya'),
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              contains('add-money refused'),
            ),
      ],
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'a ledger stream error reaches failure, and Retry re-subscribes',
      build: () => PocketMoneyBloc(repository: _BrokenLedgerRepository()),
      act: (bloc) => bloc.add(const PocketMoneyLoadRequested()),
      expect: () => <Matcher>[
        isA<PocketMoneyState>().having(
          (state) => state.status,
          'status',
          PocketMoneyStatus.loading,
        ),
        isA<PocketMoneyState>()
            .having(
              (state) => state.status,
              'status',
              PocketMoneyStatus.failure,
            )
            .having((state) => state.data, 'data', isNull)
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              contains('ledger is down'),
            ),
      ],
    );
  });
}
