// P12 Money ledger — bloc state machine for `/money`.
//
// The bloc serves every pocket-money route from ONE stream:
// `watchLedgerData` (children, all entries, oweds, goals, payout day, zone,
// plus the P06 setup carried alongside). `PocketMoneyChildSelected`
// re-filters synchronously; the sheet submits write through and the stream
// re-emits. All P06 setup behaviour (mode/day/stepper guards) is unchanged.

import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_child.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_ledger_data.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/domain/entities/savings_goal_data.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_bloc.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_event.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_state.dart';

import '../../test_scope.dart';
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

/// Fake whose submits always fail; the load path flows through the shared
/// test fallback for `watchLedgerData` (setup × items, no goals).
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

/// Fake whose **P06 setup** writes all fail while the load path stays healthy.
/// Used to pin that the friendly parent-facing copy added for P12 (review
/// finding 7) does NOT leak into the setup screens: their error strings are
/// P06's own copy and must stay byte-identical.
class _ThrowingSetupWriteRepository extends _ThrowingSubmitRepository {
  @override
  Future<void> setMode(String mode) async {
    throw Exception('mode write refused');
  }

  @override
  Future<void> setPayoutDay(int day) async {
    throw Exception('payout-day write refused');
  }

  @override
  Future<void> setWeeklyBasePence(String childId, int pence) async {
    throw Exception('weekly-base write refused');
  }
}

/// A hand-built emission — the shape `watchLedgerData` produces, without a
/// Drift database, so a test can drive the stream step by step.
MoneyLedgerData _ledgerData({
  List<MoneyChild> children = const <MoneyChild>[
    MoneyChild(id: 'maya', nickname: 'Maya'),
    MoneyChild(id: 'leo', nickname: 'Leo'),
  ],
  List<PocketMoneyEntry> entries = const <PocketMoneyEntry>[],
  List<OwedSummary> oweds = const <OwedSummary>[],
  List<SavingsGoalData> goals = const <SavingsGoalData>[],
  int payoutDay = 6,
  String zoneId = 'Europe/London',
  PocketMoneySetup? setup = _demoSetup,
}) {
  return MoneyLedgerData(
    children: children,
    entries: entries,
    oweds: oweds.isEmpty
        ? <OwedSummary>[
            for (final child in children)
              OwedSummary(
                childId: child.id,
                totalPence: 0,
                basePence: 0,
                questsPence: 0,
              ),
          ]
        : oweds,
    goals: goals,
    payoutDay: payoutDay,
    zoneId: zoneId,
    setup: setup,
  );
}

PocketMoneyEntry _entry({
  required int id,
  required String childId,
  required String type,
  required int amountPence,
  String note = '',
  DateTime? date,
}) {
  return PocketMoneyEntry(
    id: id,
    title: note,
    detail: note,
    childId: childId,
    type: type,
    amountPence: amountPence,
    note: note,
    date: date ?? DateTime.utc(2026, 10, 3, 8),
  );
}

/// Fake whose [watchLedgerData] stream the test scripts per subscription, and
/// whose writes are recorded instead of performed (so "the submit emitted
/// nothing" is observable — a write-through submit is silent until the watch
/// stream re-emits).
class _ScriptedLedgerRepository extends _ThrowingSubmitRepository {
  _ScriptedLedgerRepository(this._onSubscribe);

  final Stream<MoneyLedgerData> Function(int attempt) _onSubscribe;

  /// How many times the bloc subscribed (1 on the first load, 2 after a
  /// "Try again" re-subscription).
  int attempts = 0;

  /// `childId:amountPence:note` per accepted write.
  final List<String> addMoneyCalls = <String>[];
  final List<String> spendingCalls = <String>[];

  @override
  Stream<MoneyLedgerData> watchLedgerData() => _onSubscribe(attempts++);

  @override
  Future<void> addMoney({
    required String childId,
    required int amountPence,
    required String note,
  }) async {
    addMoneyCalls.add('$childId:$amountPence:$note');
  }

  @override
  Future<void> recordSpending({
    required String childId,
    required int amountPence,
    required String note,
  }) async {
    spendingCalls.add('$childId:$amountPence:$note');
  }
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
        // The shared test fallback carries the setup with no goals.
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
              allOf(
                startsWith('We couldn\u2019t save that'),
                contains('add-money refused'),
              ),
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
              allOf(
                startsWith('We couldn\u2019t load your ledger'),
                contains('ledger is down'),
              ),
            ),
      ],
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'a rejected spending submit keeps the loaded ledger and sets the '
      'message (no failure state)',
      build: () => PocketMoneyBloc(repository: _ThrowingSubmitRepository()),
      act: (bloc) async {
        bloc.add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere(
          (state) => state.status == PocketMoneyStatus.loaded,
        );
        bloc.add(const PocketMoneySpendingSubmitted('maya', 200, 'Comic'));
      },
      expect: () => <Matcher>[
        isA<PocketMoneyState>().having(
          (state) => state.status,
          'status',
          PocketMoneyStatus.loading,
        ),
        isA<PocketMoneyState>().having(
          (state) => state.status,
          'status',
          PocketMoneyStatus.loaded,
        ),
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              allOf(
                startsWith('We couldn\u2019t save that'),
                contains('spend refused'),
              ),
            ),
      ],
    );

    // A write-through submit is silent: the row appears only when the watch
    // stream re-emits. An optimistic emission here would show a row the
    // database rejected (the failure path above sets the message instead).
    test(
      'an accepted submit reaches the repository without emitting',
      () async {
        final controller = StreamController<MoneyLedgerData>.broadcast();
        addTearDown(controller.close);
        final repository = _ScriptedLedgerRepository((_) => controller.stream);
        final bloc = PocketMoneyBloc(repository: repository);
        addTearDown(bloc.close);

        final seen = <PocketMoneyState>[];
        final subscription = bloc.stream.listen(seen.add);
        addTearDown(subscription.cancel);

        bloc.add(const PocketMoneyLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 20));
        controller.add(_ledgerData());
        await bloc.stream.firstWhere(
          (state) => state.status == PocketMoneyStatus.loaded,
        );
        final afterLoad = seen.length;

        bloc
          ..add(const PocketMoneyAddMoneySubmitted('maya', 500, 'Quiet write'))
          ..add(const PocketMoneySpendingSubmitted('maya', 200, 'Quiet spend'));
        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(repository.addMoneyCalls, <String>[
          'maya:500:Quiet write',
        ], reason: 'the write must reach the repository exactly once');
        expect(repository.spendingCalls, <String>['maya:200:Quiet spend']);
        expect(
          seen.length,
          afterLoad,
          reason: 'a write-through submit must not emit optimistically',
        );
        expect(bloc.state.errorMessage, isNull);
      },
    );
  });

  group('PocketMoneyBloc — P12 selection guards', () {
    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'selecting a child before the first load is a no-op',
      build: () => PocketMoneyBloc(repository: _ThrowingSubmitRepository()),
      act: (bloc) => bloc.add(const PocketMoneyChildSelected('leo')),
      expect: () => const <Matcher>[],
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      're-selecting the current child emits nothing further',
      setUp: setUpTestScope,
      build: () =>
          PocketMoneyBloc(repository: GetIt.instance<PocketMoneyRepository>()),
      act: (bloc) async {
        bloc.add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere((state) => state.data != null);
        // Maya is already selected — the segment must not re-emit.
        bloc.add(const PocketMoneyChildSelected('maya'));
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

    // `build` creates the controller and `act` drives it; `bloc_test` runs
    // `build` first, so the same instance is visible to both.
    late StreamController<MoneyLedgerData> controller;
    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'a stream that drops the selected child falls back to the first one',
      build: () {
        controller = StreamController<MoneyLedgerData>.broadcast();
        addTearDown(controller.close);
        return PocketMoneyBloc(
          repository: _ScriptedLedgerRepository((_) => controller.stream),
        );
      },
      act: (bloc) async {
        bloc.add(const PocketMoneyLoadRequested());
        // Let the bloc subscribe before the broadcast controller receives
        // anything — an event sent with no listener is dropped.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        controller.add(
          _ledgerData(
            entries: <PocketMoneyEntry>[
              _entry(
                id: 1,
                childId: 'maya',
                type: 'weekly_base',
                amountPence: 300,
              ),
              _entry(
                id: 2,
                childId: 'leo',
                type: 'weekly_base',
                amountPence: 150,
              ),
            ],
          ),
        );
        await bloc.stream.firstWhere((state) => state.data != null);
        bloc.add(const PocketMoneyChildSelected('leo'));
        await bloc.stream.firstWhere((state) => state.selectedChildId == 'leo');
        // Leo is deleted from the family: the next emission must not keep a
        // dangling selection (the view would render the wrong child).
        controller.add(
          _ledgerData(
            children: const <MoneyChild>[
              MoneyChild(id: 'maya', nickname: 'Maya'),
            ],
            entries: <PocketMoneyEntry>[
              _entry(
                id: 1,
                childId: 'maya',
                type: 'weekly_base',
                amountPence: 300,
              ),
            ],
          ),
        );
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
            .having((state) => state.selectedChildId, 'selected', 'leo')
            .having((state) => state.items.length, 'items', 1),
        isA<PocketMoneyState>()
            .having((state) => state.selectedChildId, 'selected', 'maya')
            .having(
              (state) => state.items.map((entry) => entry.childId).toSet(),
              'items children',
              <String>{'maya'},
            ),
      ],
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'a family with no children loads with a null selection and no items',
      build: () => PocketMoneyBloc(
        repository: _ScriptedLedgerRepository(
          (_) => Stream<MoneyLedgerData>.value(
            _ledgerData(children: const <MoneyChild>[]),
          ),
        ),
      ),
      act: (bloc) => bloc.add(const PocketMoneyLoadRequested()),
      expect: () => <Matcher>[
        isA<PocketMoneyState>().having(
          (state) => state.status,
          'status',
          PocketMoneyStatus.loading,
        ),
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having((state) => state.selectedChildId, 'selected', isNull)
            .having((state) => state.items, 'items', isEmpty)
            .having((state) => state.data?.children, 'children', isEmpty),
      ],
    );
  });

  group('PocketMoneyBloc — P12 retry', () {
    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'a second load after a failure re-subscribes and recovers',
      build: () {
        final repository = _ScriptedLedgerRepository(
          (attempt) => attempt == 0
              ? Stream<MoneyLedgerData>.error(StateError('ledger is down'))
              : Stream<MoneyLedgerData>.value(_ledgerData()),
        );
        return PocketMoneyBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere(
          (state) => state.status == PocketMoneyStatus.failure,
        );
        bloc.add(const PocketMoneyLoadRequested());
      },
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
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              contains('ledger is down'),
            ),
        // The retry must clear the stale message, not keep it beside the
        // recovered ledger.
        isA<PocketMoneyState>()
            .having(
              (state) => state.status,
              'status',
              PocketMoneyStatus.loading,
            )
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              contains('ledger is down'),
            ),
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having((state) => state.errorMessage, 'errorMessage', isNull)
            .having((state) => state.selectedChildId, 'selected', 'maya'),
      ],
    );

    test(
      'a load failure must not leave a pending retry timer behind',
      () async {
        final repository = _ScriptedLedgerRepository(
          (_) => Stream<MoneyLedgerData>.error(StateError('ledger is down')),
        );
        final bloc = PocketMoneyBloc(repository: repository)
          ..add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere(
          (state) => state.status == PocketMoneyStatus.failure,
        );
        // The error is terminal: the stream closes after the first error, so
        // `close()` completes instead of hanging on a live `emit.forEach`.
        await bloc.close().timeout(const Duration(seconds: 5));
        expect(repository.attempts, 1);
      },
    );
  });

  // Iteration 2 closed review finding 7 by mapping the two P12 failures to
  // parent-facing copy. This group pins BOTH halves of that change: the exact
  // P12 strings (curly ’ U+2019) and the fact that P06's own error copy was
  // deliberately left untouched.
  group('PocketMoneyBloc — error-message mapping (review finding 7)', () {
    test(
      'the load message is exactly the friendly sentence plus the cause',
      () async {
        final bloc = PocketMoneyBloc(
          repository: _ScriptedLedgerRepository(
            (_) => Stream<MoneyLedgerData>.error(StateError('ledger is down')),
          ),
        );
        addTearDown(bloc.close);
        bloc.add(const PocketMoneyLoadRequested());
        final failure = await bloc.stream.firstWhere(
          (state) => state.status == PocketMoneyStatus.failure,
        );

        expect(
          failure.errorMessage,
          // U+2019 curly apostrophe, exactly as `2a_build_logic.md` records.
          'We couldn\u2019t load your ledger: Bad state: ledger is down',
        );
        expect(
          failure.errorMessage!.codeUnits,
          contains(0x2019),
          reason: 'ASCII apostrophe in the parent-facing copy',
        );
        expect(failure.errorMessage!.codeUnits, isNot(contains(0x27)));
      },
    );

    test('a rejected submit reads "We couldn’t save that: <cause>"', () async {
      final bloc = PocketMoneyBloc(repository: _ThrowingSubmitRepository())
        ..add(const PocketMoneyLoadRequested());
      addTearDown(bloc.close);
      await bloc.stream.firstWhere(
        (state) => state.status == PocketMoneyStatus.loaded,
      );
      bloc.add(const PocketMoneyAddMoneySubmitted('maya', 500, 'Nope'));

      final failed = await bloc.stream.firstWhere(
        (state) => state.errorMessage != null,
      );
      expect(
        failed.errorMessage,
        'We couldn\u2019t save that: Exception: add-money refused',
      );
      expect(failed.status, isNot(PocketMoneyStatus.failure));
    });

    // The setup screens (P06) show the raw cause; the friendly lead sentence
    // is P12 copy and must not leak across.
    test('P06 setup write failures keep their own raw copy', () async {
      final scenarios = <(String, PocketMoneyEvent, String)>[
        (
          'mode',
          const PocketMoneyModeChanged('weekly'),
          'Exception: mode write refused',
        ),
        (
          'payout day',
          const PocketMoneyPayoutDayChanged(3),
          'Exception: payout-day write refused',
        ),
        (
          'weekly base',
          const PocketMoneyWeeklyBaseStepped('maya', 50),
          'Exception: weekly-base write refused',
        ),
      ];

      for (final scenario in scenarios) {
        final bloc = PocketMoneyBloc(
          repository: _ThrowingSetupWriteRepository(),
        )..add(const PocketMoneyLoadRequested());
        addTearDown(bloc.close);
        await bloc.stream.firstWhere(
          (state) => state.status == PocketMoneyStatus.loaded,
        );
        bloc.add(scenario.$2);

        final failed = await bloc.stream.firstWhere(
          (state) => state.errorMessage != null,
        );
        expect(
          failed.errorMessage,
          scenario.$3,
          reason:
              'the "${scenario.$1}" write failure must stay P06\'s raw copy, '
              'with no P12 friendly prefix',
        );
        expect(
          failed.errorMessage,
          isNot(contains('We couldn')),
          reason: 'the P12 friendly sentence must not leak into P06',
        );
      }
    });
  });
}
