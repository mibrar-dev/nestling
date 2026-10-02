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
}
