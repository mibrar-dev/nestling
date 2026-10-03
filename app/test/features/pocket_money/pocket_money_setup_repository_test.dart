// P06 Pocket money setup — Drift repository contract.
//
// `watchSetup` combines the `families` row (mode/payout/coin) with the
// children in insertion order (Maya, then Leo — never the alphabetical
// Leo-first of `AppDatabase.watchChildren`). Every setter writes `families`
// AND the `settings` mirror in one transaction so P16 never diverges.

import 'package:drift/drift.dart' show Value;
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
      'a child added later lands LAST even when it sorts first alphabetically',
      () async {
        await db
            .into(db.children)
            .insert(
              ChildrenCompanion.insert(
                id: 'anna',
                familyId: Seed.familyId,
                nickname: 'Anna',
                weeklyBasePence: const Value(200),
              ),
            );

        final setup = await repository.watchSetup().first;
        expect(
          setup.children.map((child) => child.nickname),
          <String>['Maya', 'Leo', 'Anna'],
          reason:
              'orchestrator CHILD ORDER ruling: the order they were added, '
              'never alphabetical (Anna-first would be the alphabetical read)',
        );
      },
    );

    test('re-emits when the family row changes out of band', () async {
      final emissions = <PocketMoneySetup>[];
      final subscription = repository.watchSetup().listen(emissions.add);
      await pumpEventQueue();

      await (db.update(db.families)..where((f) => f.id.equals(Seed.familyId)))
          .write(const FamiliesCompanion(coinValuePencePerCoin: Value(2)));
      await pumpEventQueue();

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(emissions.last.coinValuePencePerCoin, 2);
      await subscription.cancel();
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

    test('stamps one UTC instant on both rows', () async {
      final before = DateTime.now().toUtc();
      await repository.setMode('weekly');
      final after = DateTime.now().toUtc();

      final family = await familyRow();
      final settings = await settingsRow();
      final familyStamp = family.updatedAt!;
      final settingsStamp = settings.updatedAt!;
      // NOTE: drift reads `DateTime` columns back in local time, so the UTC
      // contract belongs to the write site (`DateTime.now().toUtc()` in the
      // impl); what the repository must guarantee here is that BOTH rows move
      // to the same fresh instant in one transaction.
      expect(familyStamp, settingsStamp);
      expect(
        familyStamp.toUtc().isBefore(
          before.subtract(const Duration(seconds: 1)),
        ),
        isFalse,
        reason: 'the stamp must be written now, not left at the seed value',
      );
      expect(
        familyStamp.toUtc().isAfter(after.add(const Duration(seconds: 1))),
        isFalse,
      );
      expect(settings.updatedAtTz, family.updatedAtTz);
    });

    test('writes both rows with no children (Seed.empty)', () async {
      await Seed.empty(db);
      await repository.setMode('weekly');

      expect((await familyRow()).pocketMoneyMode, 'weekly');
      expect((await settingsRow()).pocketMoneyMode, 'weekly');
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

    test('an unknown child id writes nothing and does not throw', () async {
      await repository.setWeeklyBasePence('nobody', 350);

      final setup = await repository.watchSetup().first;
      expect(setup.childById('nobody'), isNull);
      expect(setup.children.map((child) => child.id), <String>['maya', 'leo']);
      expect(setup.children.map((child) => child.weeklyBasePence), <int>[
        300,
        150,
      ], reason: 'an unknown id must not disturb the real children');
    });
  });
}
