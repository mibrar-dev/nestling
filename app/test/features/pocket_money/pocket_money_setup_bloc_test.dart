// P06 Pocket money setup — bloc state machine for the onboarding money step.
//
// The bloc serves /pocket-money-setup, /money and /payout from one pair of
// streams: `watchItems` (ledger) × `watchSetup` (money style + payout day +
// coin value + per-child weekly base). Every P06 tap is write-through — the
// streams re-emit and the state follows.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/pocket_money/data/pocket_money_repository_impl.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_bloc.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_event.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_state.dart';

import '../../test_scope.dart';

/// The `Seed.demo` setup: `both`, Saturday, 1p/coin, Maya £3.00 then Leo
/// £1.50 in insertion order (never alphabetical).
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

/// Records every write and can be told to fail, so the bloc's error and
/// guard paths are reachable without a broken database. Streams are built by
/// factories (a Drift stream is single-subscription, and Retry re-listens).
class _RecordingRepository implements PocketMoneyRepository {
  _RecordingRepository({
    this.failFirstSetupStream = false,
    this.throwOnWrite = true,
  });

  /// The first `watchSetup()` errors (Retry must recover on the second).
  final bool failFirstSetupStream;

  /// Every setter throws — the failure path. Off for the guard tests, which
  /// only care that the write reached the repository at all.
  final bool throwOnWrite;

  final List<String> modeWrites = <String>[];
  final List<int> payoutDayWrites = <int>[];
  final List<(String, int)> weeklyBaseWrites = <(String, int)>[];

  int _setupSubscriptions = 0;

  @override
  Future<List<PocketMoneyEntry>> getItems() => watchItems().first;

  @override
  Stream<List<PocketMoneyEntry>> watchItems() =>
      Stream<List<PocketMoneyEntry>>.value(const <PocketMoneyEntry>[]);

  @override
  Stream<List<PocketMoneyEntry>> watchLedger(String childId) => watchItems();

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
  }) async {}

  @override
  Stream<PocketMoneySetup> watchSetup() {
    _setupSubscriptions++;
    if (failFirstSetupStream && _setupSubscriptions == 1) {
      return Stream<PocketMoneySetup>.error(
        StateError('stream is down'),
        StackTrace.current,
      );
    }
    return Stream<PocketMoneySetup>.value(_demoSetup);
  }

  @override
  Future<void> setMode(String mode) async {
    modeWrites.add(mode);
    if (throwOnWrite) throw Exception('disk is full');
  }

  @override
  Future<void> setPayoutDay(int day) async {
    payoutDayWrites.add(day);
    if (throwOnWrite) throw Exception('disk is full');
  }

  @override
  Future<void> setWeeklyBasePence(String childId, int pence) async {
    weeklyBaseWrites.add((childId, pence));
    if (throwOnWrite) throw Exception('disk is full');
  }
}

void main() {
  group('PocketMoneyState', () {
    test('starts initial with no items, no setup and no error', () {
      const state = PocketMoneyState();
      expect(state.status, PocketMoneyStatus.initial);
      expect(const PocketMoneyState().items, isEmpty);
      expect(const PocketMoneyState().setup, isNull);
      expect(const PocketMoneyState().errorMessage, isNull);
    });

    test('copyWith replaces only the given fields', () {
      const loaded = PocketMoneyState(
        status: PocketMoneyStatus.loaded,
        setup: _demoSetup,
      );
      expect(
        loaded.copyWith(status: PocketMoneyStatus.loading).setup,
        _demoSetup,
      );
      expect(
        loaded
            .copyWith(
              status: PocketMoneyStatus.failure,
              errorMessage: 'offline',
            )
            .errorMessage,
        'offline',
      );
    });

    test('equality includes the setup', () {
      expect(
        const PocketMoneyState(
          status: PocketMoneyStatus.loaded,
          setup: _demoSetup,
        ),
        const PocketMoneyState(
          status: PocketMoneyStatus.loaded,
          setup: _demoSetup,
        ),
      );
      expect(
        const PocketMoneyState(
          status: PocketMoneyStatus.loaded,
          setup: _demoSetup,
        ),
        isNot(const PocketMoneyState(status: PocketMoneyStatus.loaded)),
      );
    });
  });

  group('PocketMoneyBloc — P06 setup load', () {
    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'load emits loading then the demo setup in insertion order',
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
            .having((state) => state.setup, 'setup', _demoSetup)
            .having(
              (state) => state.items.length,
              'items.length',
              greaterThan(0),
            ),
      ],
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'mode change persists and re-emits with the new mode',
      setUp: setUpTestScope,
      build: () =>
          PocketMoneyBloc(repository: GetIt.instance<PocketMoneyRepository>()),
      act: (bloc) async {
        bloc.add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere((state) => state.setup != null);
        bloc.add(const PocketMoneyModeChanged('per_quest'));
      },
      expect: () => <Matcher>[
        isA<PocketMoneyState>().having(
          (state) => state.status,
          'status',
          PocketMoneyStatus.loading,
        ),
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having((state) => state.setup?.mode, 'mode', 'both'),
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having((state) => state.setup?.mode, 'mode', 'per_quest'),
      ],
      verify: (_) async {
        final repository = GetIt.instance<PocketMoneyRepository>();
        final setup = await repository.watchSetup().first;
        expect(setup.mode, 'per_quest');
      },
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'payout-day change re-emits; re-tapping the selected day is a no-op',
      setUp: setUpTestScope,
      build: () =>
          PocketMoneyBloc(repository: GetIt.instance<PocketMoneyRepository>()),
      act: (bloc) async {
        bloc.add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere((state) => state.setup != null);
        // No-op first: tapping Sat while Sat is selected writes nothing.
        bloc.add(const PocketMoneyPayoutDayChanged(6));
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const PocketMoneyPayoutDayChanged(7));
      },
      expect: () => <Matcher>[
        isA<PocketMoneyState>().having(
          (state) => state.status,
          'status',
          PocketMoneyStatus.loading,
        ),
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having((state) => state.setup?.payoutDay, 'payoutDay', 6),
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having((state) => state.setup?.payoutDay, 'payoutDay', 7),
      ],
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'stepper adds one 50p step to the current base (Maya £3.00 → £3.50)',
      setUp: setUpTestScope,
      build: () =>
          PocketMoneyBloc(repository: GetIt.instance<PocketMoneyRepository>()),
      act: (bloc) async {
        bloc.add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere((state) => state.setup != null);
        bloc.add(const PocketMoneyWeeklyBaseStepped('maya', 50));
      },
      expect: () => <Matcher>[
        isA<PocketMoneyState>().having(
          (state) => state.status,
          'status',
          PocketMoneyStatus.loading,
        ),
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having(
              (state) => state.setup?.childById('maya')?.weeklyBasePence,
              'maya base',
              300,
            ),
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having(
              (state) => state.setup?.childById('maya')?.weeklyBasePence,
              'maya base',
              350,
            ),
      ],
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'step past £20.00 clamps at 2000p with no further emission',
      setUp: setUpTestScope,
      build: () =>
          PocketMoneyBloc(repository: GetIt.instance<PocketMoneyRepository>()),
      act: (bloc) async {
        await GetIt.instance<PocketMoneyRepository>().setWeeklyBasePence(
          'maya',
          2000,
        );
        bloc.add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere((state) => state.setup != null);
        bloc.add(const PocketMoneyWeeklyBaseStepped('maya', 50));
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
            .having(
              (state) => state.setup?.childById('maya')?.weeklyBasePence,
              'maya base',
              2000,
            ),
      ],
      verify: (_) async {
        final repository = GetIt.instance<PocketMoneyRepository>();
        final setup = await repository.watchSetup().first;
        expect(setup.childById('maya')?.weeklyBasePence, 2000);
      },
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'step below £0.00 clamps at 0p',
      setUp: setUpTestScope,
      build: () =>
          PocketMoneyBloc(repository: GetIt.instance<PocketMoneyRepository>()),
      act: (bloc) async {
        await GetIt.instance<PocketMoneyRepository>().setWeeklyBasePence(
          'leo',
          0,
        );
        bloc.add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere((state) => state.setup != null);
        bloc.add(const PocketMoneyWeeklyBaseStepped('leo', -50));
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
            .having(
              (state) => state.setup?.childById('leo')?.weeklyBasePence,
              'leo base',
              0,
            ),
      ],
      verify: (_) async {
        final repository = GetIt.instance<PocketMoneyRepository>();
        final setup = await repository.watchSetup().first;
        expect(setup.childById('leo')?.weeklyBasePence, 0);
      },
    );
  });

  group('PocketMoneyRepository setup validation', () {
    late AppDatabase db;
    late PocketMoneyRepository repository;

    setUp(() async {
      db = AppDatabase.memory();
      await Seed.demo(db);
      repository = PocketMoneyRepositoryImpl(db: db);
    });

    tearDown(() => db.close());

    test('rejects an unknown mode', () {
      expect(
        () => repository.setMode('yearly'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects a payout day outside 1..7', () {
      expect(() => repository.setPayoutDay(0), throwsA(isA<AssertionError>()));
      expect(() => repository.setPayoutDay(8), throwsA(isA<AssertionError>()));
    });
  });

  group('PocketMoneyBloc — failure and guard paths', () {
    late _RecordingRepository repository;

    // FIXED (iteration 3) — was P06-BUG-01: `_onWeeklyBaseStepped` used to
    // compute `current + delta` from `state.setup` and write it absolute, so
    // two step events in one turn read the same stale base and the second
    // tap was lost. The handler now confirms each successful write in state
    // (`withChildBase`) so the next event reads the new base; the stream
    // emission converges to the same value. Was P06-BUG-07: unknown ids used
    // to fall back to `?? 0` and still call the repository — now a no-op.
    // Proofs: `p06_bugs_test.dart` P06-BUG-01/02/06/07 (un-skipped) + the
    // regression tests below.
    setUp(() {
      repository = _RecordingRepository();
    });

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'a throwing write lands in failure with the error message',
      build: () => PocketMoneyBloc(repository: repository),
      act: (bloc) => bloc.add(const PocketMoneyModeChanged('weekly')),
      expect: () => <Matcher>[
        isA<PocketMoneyState>()
            .having(
              (state) => state.status,
              'status',
              PocketMoneyStatus.failure,
            )
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              contains('disk is full'),
            ),
      ],
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'a throwing payout-day write lands in failure too',
      build: () => PocketMoneyBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere((state) => state.setup != null);
        bloc.add(const PocketMoneyPayoutDayChanged(2));
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
            .having(
              (state) => state.status,
              'status',
              PocketMoneyStatus.failure,
            )
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              contains('disk is full'),
            ),
      ],
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'a throwing stepper write lands in failure too',
      build: () => PocketMoneyBloc(repository: repository),
      act: (bloc) async {
        bloc.add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere((state) => state.setup != null);
        bloc.add(const PocketMoneyWeeklyBaseStepped('maya', 50));
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
            .having(
              (state) => state.status,
              'status',
              PocketMoneyStatus.failure,
            )
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              contains('disk is full'),
            ),
      ],
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'a stream error reaches failure, and Retry re-subscribes to recovery',
      build: () {
        repository = _RecordingRepository(failFirstSetupStream: true);
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
            .having((state) => state.setup, 'setup', isNull)
            .having(
              (state) => state.errorMessage,
              'errorMessage',
              contains('stream is down'),
            ),
        // Retry: loading again, then the real DB truth — no stuck UI.
        isA<PocketMoneyState>().having(
          (state) => state.status,
          'status',
          PocketMoneyStatus.loading,
        ),
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having((state) => state.setup, 'setup', _demoSetup),
      ],
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'a day tap before the first emission still writes (the guard reads '
      'state.setup, which is null then)',
      build: () {
        repository = _RecordingRepository(throwOnWrite: false);
        return PocketMoneyBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const PocketMoneyPayoutDayChanged(7)),
      expect: () => <Matcher>[],
      verify: (_) {
        expect(repository.payoutDayWrites, <int>[7]);
      },
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'stepping a child that is not in the setup writes nothing (P06-BUG-07)',
      build: () {
        repository = _RecordingRepository(throwOnWrite: false);
        return PocketMoneyBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere((state) => state.setup != null);
        bloc.add(const PocketMoneyWeeklyBaseStepped('nobody', 50));
        await Future<void>.delayed(const Duration(milliseconds: 50));
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
      ],
      verify: (_) {
        // Unknown ids return before any repository call (used to write
        // `0 + delta` for the phantom id).
        expect(repository.weeklyBaseWrites, isEmpty);
      },
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'two quick steps accumulate instead of losing one (P06-BUG-01)',
      build: () {
        repository = _RecordingRepository(throwOnWrite: false);
        return PocketMoneyBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere((state) => state.setup != null);
        // Same event-loop turn: the second event must build on the first
        // event's requested 350p, not the stale emitted 300p.
        bloc
          ..add(const PocketMoneyWeeklyBaseStepped('maya', 50))
          ..add(const PocketMoneyWeeklyBaseStepped('maya', 50));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
      expect: () => <Matcher>[
        isA<PocketMoneyState>().having(
          (state) => state.status,
          'status',
          PocketMoneyStatus.loading,
        ),
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having(
              (state) => state.setup?.childById('maya')?.weeklyBasePence,
              'maya base',
              300,
            ),
        // Each successful write is confirmed in state without waiting for
        // the watch stream (the stream emission converges to the same value
        // and is deduped).
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having(
              (state) => state.setup?.childById('maya')?.weeklyBasePence,
              'maya base',
              350,
            ),
        isA<PocketMoneyState>()
            .having((state) => state.status, 'status', PocketMoneyStatus.loaded)
            .having(
              (state) => state.setup?.childById('maya')?.weeklyBasePence,
              'maya base',
              400,
            ),
      ],
      verify: (_) {
        expect(repository.weeklyBaseWrites, <(String, int)>[
          ('maya', 350),
          ('maya', 400),
        ]);
      },
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'a fast Sun→Sat correction is not dropped (P06-BUG-02)',
      build: () {
        repository = _RecordingRepository(throwOnWrite: false);
        return PocketMoneyBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere((state) => state.setup != null);
        bloc
          ..add(const PocketMoneyPayoutDayChanged(7))
          ..add(const PocketMoneyPayoutDayChanged(6));
        await Future<void>.delayed(const Duration(milliseconds: 100));
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
      ],
      verify: (_) {
        // The no-op guard compares against the last requested day, so the
        // correction reaches the repository (used to be dropped: [7]).
        expect(repository.payoutDayWrites, <int>[7, 6]);
      },
    );

    blocTest<PocketMoneyBloc, PocketMoneyState>(
      'errorMessage clears when the setup re-emits after a failure '
      '(P06-BUG-06)',
      build: () {
        repository = _RecordingRepository(failFirstSetupStream: true);
        return PocketMoneyBloc(repository: repository);
      },
      act: (bloc) async {
        bloc.add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere(
          (state) => state.status == PocketMoneyStatus.failure,
        );
        bloc.add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere(
          (state) => state.status == PocketMoneyStatus.loaded,
        );
      },
      verify: (bloc) {
        expect(bloc.state.status, PocketMoneyStatus.loaded);
        expect(bloc.state.setup, _demoSetup);
        expect(bloc.state.errorMessage, isNull);
      },
    );
  });
}
