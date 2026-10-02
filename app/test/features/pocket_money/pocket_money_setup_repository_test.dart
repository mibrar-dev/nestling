// P06 Pocket money setup — Drift repository contract.
//
// `watchSetup` combines the `families` row (mode/payout/coin) with the
// children in insertion order (Maya, then Leo — never the alphabetical
// Leo-first of `AppDatabase.watchChildren`). Every setter writes `families`
// AND the `settings` mirror in one transaction so P16 never diverges.

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/pocket_money/data/pocket_money_repository_impl.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';

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
  late AppDatabase db;
  late PocketMoneyRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase.memory();
    await Seed.demo(db);
    repository = PocketMoneyRepositoryImpl(db: db);
  });

  tearDown(() => db.close());

  Future<Family> familyRow() {
    return (db.select(
      db.families,
    )..where((f) => f.id.equals(Seed.familyId))).getSingle();
  }

  Future<Setting> settingsRow() {
    return (db.select(
      db.settings,
    )..where((s) => s.familyId.equals(Seed.familyId))).getSingle();
  }

  group('watchSetup', () {
    test('first emission equals the demo seed', () async {
      expect(await repository.watchSetup().first, _demoSetup);
    });

    test('children arrive in insertion order, not alphabetical', () async {
      final setup = await repository.watchSetup().first;
      expect(setup.children.map((child) => child.nickname), <String>[
        'Maya',
        'Leo',
      ]);
      expect(
        setup.children.map((child) => child.nickname).toList()..sort(),
        <String>['Leo', 'Maya'],
        reason: 'alphabetical would be Leo-first — the stream must not be',
      );
    });

    test(
      'Seed.empty still emits mode, day and coin with no children',
      () async {
        await Seed.empty(db);

        final setup = await repository.watchSetup().first;
        expect(setup.mode, 'both');
        expect(setup.payoutDay, 6);
        expect(setup.coinValuePencePerCoin, 1);
        expect(setup.children, isEmpty);
      },
    );
  });

  group('setMode', () {
    test('updates families AND the settings mirror', () async {
      await repository.setMode('per_quest');

      expect((await familyRow()).pocketMoneyMode, 'per_quest');
      expect((await settingsRow()).pocketMoneyMode, 'per_quest');
      expect((await repository.watchSetup().first).mode, 'per_quest');
    });

    test('rejects an unknown mode', () {
      expect(
        () => repository.setMode('yearly'),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('setPayoutDay', () {
    test('updates families AND the settings mirror', () async {
      await repository.setPayoutDay(7);

      expect((await familyRow()).payoutDay, 7);
      expect((await settingsRow()).payoutDay, 7);
      expect((await repository.watchSetup().first).payoutDay, 7);
    });

    test('rejects days outside 1..7', () {
      expect(() => repository.setPayoutDay(0), throwsA(isA<AssertionError>()));
      expect(() => repository.setPayoutDay(8), throwsA(isA<AssertionError>()));
    });
  });

  group('setWeeklyBasePence', () {
    test('writes the child row and re-emits', () async {
      await repository.setWeeklyBasePence('maya', 350);

      final rows = await (db.select(
        db.children,
      )..where((c) => c.id.equals('maya'))).getSingle();
      expect(rows.weeklyBasePence, 350);
      expect(
        (await repository.watchSetup().first)
            .childById('maya')
            ?.weeklyBasePence,
        350,
      );
    });

    test('clamps to 0..2000 pence', () async {
      await repository.setWeeklyBasePence('maya', 5000);
      expect(
        (await repository.watchSetup().first)
            .childById('maya')
            ?.weeklyBasePence,
        2000,
      );

      await repository.setWeeklyBasePence('leo', -250);
      expect(
        (await repository.watchSetup().first).childById('leo')?.weeklyBasePence,
        0,
      );
    });
  });
}
