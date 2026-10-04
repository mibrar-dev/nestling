// K09 repository tests (DB-backed, Seed.demo): the jar-stream contract.
//
// `watchJar` emits the active child's money-in list (newest first) plus the
// jar summary in one atomic snapshot, and follows `app_state.activeChildId`
// switches. Demo seed, Maya: owed 420p (£3.00 base + £1.20 quests), goal
// "Lego Friends set" 1550/2499, payout Saturday. Leo: owed 210p, no goal.

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/kid_jar/data/kid_jar_repository_impl.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_snapshot.dart';

const Set<String> _moneyInTypes = <String>{
  'weekly_base',
  'quest_bonus',
  'gift',
};

/// Collects the jar stream's emissions so a test can await the one a write
/// provokes. Bounded waits only, so a stream that never emits fails fast
/// instead of hanging.
class _JarEmissions {
  _JarEmissions(Stream<JarSnapshot> stream) {
    _sub = stream.listen(_events.add, onError: _errors.add);
  }

  late final StreamSubscription<JarSnapshot> _sub;
  final List<JarSnapshot> _events = <JarSnapshot>[];
  final List<Object> _errors = <Object>[];

  List<Object> get errors => List<Object>.unmodifiable(_errors);

  Future<JarSnapshot> next() async {
    for (var i = 0; i < 30; i++) {
      if (_events.isNotEmpty) return _events.removeAt(0);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw StateError('no jar emission arrived within 300 ms');
  }

  Future<List<JarSnapshot>> settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List<JarSnapshot>.of(_events);
  }

  Future<void> cancel() => _sub.cancel();
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    await Seed.demo(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> setActiveChild(String childId) {
    return (db.update(db.appState)..where((a) => a.id.equals(1))).write(
      AppStateCompanion(activeChildId: Value(childId)),
    );
  }

  group('KidJarRepository watchJar (K09, Maya)', () {
    test('emits the demo summary: owed 420, Lego goal, Saturday', () async {
      final repo = KidJarRepositoryImpl(db: db);
      final snapshot = await repo.watchJar().first;

      expect(snapshot.childId, 'maya');
      expect(snapshot.summary.childId, 'maya');
      expect(
        snapshot.summary.owedPence,
        420,
        reason: '300 base + 12 + 40 + 40 + 28 quest bonuses since the payout',
      );
      expect(snapshot.summary.goalTitle, 'Lego Friends set');
      expect(snapshot.summary.goalSavedPence, 1550);
      expect(snapshot.summary.goalTargetPence, 2499);
      expect(snapshot.summary.nextPayoutDay, 'Saturday');
    });

    test(
      'lists money-in rows newest-first, payout/spend/savings excluded',
      () async {
        final repo = KidJarRepositoryImpl(db: db);
        final snapshot = await repo.watchJar().first;

        expect(
          snapshot.items.map((item) => item.type),
          everyElement(isIn(_moneyInTypes)),
          reason: 'payout, spend and savings_move never reach the K09 list',
        );
        expect(snapshot.items, hasLength(9));
        final dates = snapshot.items.map((item) => item.date).toList();
        for (var i = 0; i < dates.length - 1; i++) {
          expect(
            dates[i].isAfter(dates[i + 1]) ||
                dates[i].isAtSameMomentAs(dates[i + 1]),
            isTrue,
            reason: 'newest first',
          );
        }
        final first = snapshot.items.first;
        expect(first.type, 'weekly_base');
        expect(first.amountPence, 300);
        expect(first.title, 'Pocket money');
        expect(first.detail, 'This Saturday');
      },
    );

    test('maps every demo row the way the K09 list shows it', () async {
      final repo = KidJarRepositoryImpl(db: db);
      final snapshot = await repo.watchJar().first;

      expect(snapshot.items.map((item) => item.title).toList(), <String>[
        'Pocket money',
        'Put the bins out',
        'Hoover the stairs',
        'Help with the washing',
        'Tidy your bedroom',
        'Birthday money',
        'Hoover the stairs',
        'Put the bins out',
        'Pocket money',
      ]);
      expect(snapshot.items.map((item) => item.detail).toList(), <String>[
        'This Saturday',
        'Quest bonus',
        'Quest bonus',
        'Quest bonus',
        'Quest bonus',
        'From Mum',
        'Quest bonus',
        'Quest bonus',
        'Last Sunday',
      ]);
    });

    test('amounts read +£ above £1 and +p below it', () async {
      final repo = KidJarRepositoryImpl(db: db);
      final snapshot = await repo.watchJar().first;
      final byTitle = <String, List<String>>{};
      for (final item in snapshot.items) {
        byTitle
            .putIfAbsent(item.title, () => <String>[])
            .add(formatJarAmount(item.amountPence));
      }

      expect(snapshot.items.first.amountPence, 300);
      expect(formatJarAmount(300), '+£3.00');
      expect(formatJarAmount(1000), '+£10.00');
      expect(formatJarAmount(12), '+12p');
      expect(byTitle['Birthday money'], <String>['+£10.00']);
    });
  });

  group('KidJarRepository watchJar (K09, Leo)', () {
    test('Leo is owed 210 with no savings goal', () async {
      await setActiveChild('leo');
      final repo = KidJarRepositoryImpl(db: db);
      final snapshot = await repo.watchJar().first;

      expect(snapshot.childId, 'leo');
      expect(
        snapshot.summary.owedPence,
        210,
        reason: '150 base + 35 + 25 quest bonuses since the payout',
      );
      expect(snapshot.summary.goalTargetPence, 0);
      expect(snapshot.summary.goalSavedPence, 0);
      expect(snapshot.summary.nextPayoutDay, 'Saturday');
      expect(
        snapshot.items.map((item) => item.type),
        everyElement(isIn(_moneyInTypes)),
      );
      expect(snapshot.items, hasLength(5));
      expect(snapshot.items.first.type, 'weekly_base');
      expect(snapshot.items.first.amountPence, 150);
    });
  });

  group('KidJarRepository on an empty family (K09)', () {
    test('Seed.empty has no rows: empty list, zero owed, no goal', () async {
      await Seed.empty(db);
      final repo = KidJarRepositoryImpl(db: db);

      final snapshot = await repo.watchJar().first;

      expect(snapshot.childId, 'maya', reason: 'no active child falls back');
      expect(snapshot.items, isEmpty);
      expect(snapshot.summary.owedPence, 0);
      expect(snapshot.summary.goalTargetPence, 0);
      expect(snapshot.summary.nextPayoutDay, 'Saturday');
    });
  });

  group('KidJarRepository live re-emission (K09)', () {
    late KidJarRepositoryImpl repo;
    late _JarEmissions jar;

    setUp(() {
      repo = KidJarRepositoryImpl(db: db);
      jar = _JarEmissions(repo.watchJar());
    });

    tearDown(() => jar.cancel());

    test('follows an active-child switch after the first emission', () async {
      expect((await jar.next()).childId, 'maya');

      await setActiveChild('leo');

      final second = await jar.next();
      expect(second.childId, 'leo');
      expect(second.summary.owedPence, 210);
      expect(second.summary.goalTargetPence, 0);
      expect(
        second.items.map((item) => item.type),
        everyElement(isIn(_moneyInTypes)),
      );
      expect(jar.errors, isEmpty);
    });

    test('a new money-in row lands at the head of the list', () async {
      final first = await jar.next();
      expect(first.items, hasLength(9));

      await db
          .into(db.ledgerEntries)
          .insert(
            LedgerEntriesCompanion.insert(
              familyId: Seed.familyId,
              childId: 'maya',
              type: 'quest_bonus',
              amountPence: 20,
              note: const Value('Water the plants'),
              date: Value(DateTime.utc(2026, 10, 3, 9)),
              dateTz: const Value('Europe/London'),
            ),
          );

      final next = await jar.next();
      expect(next.items, hasLength(10));
      expect(next.items.first.title, 'Water the plants');
      expect(next.items.first.detail, 'Quest bonus');
      expect(next.summary.owedPence, 440);
      expect(jar.errors, isEmpty);
    });

    test('a spend row moves the summary not at all and stays out', () async {
      await jar.next();
      // A spend row AFTER the latest money-in: newest ledger row overall,
      // but the K09 list must not show it and owed must not move.
      await db
          .into(db.ledgerEntries)
          .insert(
            LedgerEntriesCompanion.insert(
              familyId: Seed.familyId,
              childId: 'maya',
              type: 'spend',
              amountPence: -200,
              note: const Value('Comic'),
              date: Value(DateTime.utc(2026, 10, 3, 10)),
              dateTz: const Value('Europe/London'),
            ),
          );

      // The summary query re-emits on any ledger write; the snapshot must be
      // identical (same 9 money-in rows, owed still 420).
      final next = await jar.next();
      expect(next.items, hasLength(9));
      expect(next.summary.owedPence, 420);
      expect(jar.errors, isEmpty);
    });
  });

  group('formatJarAmount', () {
    test('reads +£ at/above £1 and +p below it', () {
      expect(formatJarAmount(300), '+£3.00');
      expect(formatJarAmount(1000), '+£10.00');
      expect(formatJarAmount(100), '+£1.00');
      expect(formatJarAmount(99), '+99p');
      expect(formatJarAmount(12), '+12p');
      expect(formatJarAmount(0), '+0p');
    });

    test('negatives use U+2212 minus (safety branch only)', () {
      expect(formatJarAmount(-200), '−£2.00');
      expect(formatJarAmount(-12), '−12p');
    });
  });

  group('KidJarRepository quest icon keys (K09-BUG-3)', () {
    test('quest rows carry the seeded quest icon key', () async {
      final repo = KidJarRepositoryImpl(db: db);
      final snapshot = await repo.watchJar().first;
      final keyForTitle = <String, String>{
        for (final item in snapshot.items) item.title: item.iconKey,
      };

      // Seeded quest icons (seed.dart `_questsDemo`): the proof in
      // `my_jar_view_test.dart` reads the same keys out of the database and
      // demands `questIconFor(key, audience: kid)` per row.
      expect(keyForTitle['Put the bins out'], 'bins');
      expect(keyForTitle['Hoover the stairs'], 'hoover');
      expect(keyForTitle['Tidy your bedroom'], 'bed');
      expect(keyForTitle['Help with the washing'], 'shirt');
    });

    test('pocket-money and gift rows carry no quest key', () async {
      final repo = KidJarRepositoryImpl(db: db);
      final snapshot = await repo.watchJar().first;

      expect(
        snapshot.items
            .where((item) => item.type != 'quest_bonus')
            .map((item) => item.iconKey),
        everyElement(isEmpty),
      );
    });

    test('a bonus naming no known quest falls back to empty', () async {
      await db
          .into(db.ledgerEntries)
          .insert(
            LedgerEntriesCompanion.insert(
              familyId: Seed.familyId,
              childId: 'maya',
              type: 'quest_bonus',
              amountPence: 5,
              note: const Value('Unicorn parade'),
              date: Value(DateTime.utc(2026, 10, 3, 9)),
              dateTz: const Value('Europe/London'),
            ),
          );
      final repo = KidJarRepositoryImpl(db: db);
      final snapshot = await repo.watchJar().first;

      expect(snapshot.items.first.title, 'Unicorn parade');
      expect(snapshot.items.first.iconKey, isEmpty);
    });
  });

  group('KidJarRepository owed floor (K09-BUG-5)', () {
    test(
      'a correction past zero clamps owed at 0, row keeps its sign',
      () async {
        // Maya is owed 420; a −500p correction makes the period total −80.
        await db
            .into(db.ledgerEntries)
            .insert(
              LedgerEntriesCompanion.insert(
                familyId: Seed.familyId,
                childId: 'maya',
                type: 'quest_bonus',
                amountPence: -500,
                note: const Value('Correction'),
                date: Value(DateTime.utc(2026, 10, 3, 9, 30)),
                dateTz: const Value('Europe/London'),
              ),
            );
        final repo = KidJarRepositoryImpl(db: db);
        final snapshot = await repo.watchJar().first;

        expect(
          snapshot.summary.owedPence,
          0,
          reason: 'a child can never be owed a negative amount',
        );
        expect(snapshot.items.first.title, 'Correction');
        expect(
          formatJarAmount(snapshot.items.first.amountPence),
          '−£5.00',
          reason: 'the list row keeps its sign; only the owed total clamps',
        );
      },
    );
  });

  group('KidJarRepository moveToSavings cap (K09-BUG-4)', () {
    Future<int> savedOf(String goalId) async {
      final goal = await (db.select(
        db.savingsGoals,
      )..where((g) => g.id.equals(goalId))).getSingle();
      return goal.savedPence;
    }

    Future<List<int>> savingsMovesFor(String childId) async {
      final rows =
          await (db.select(db.ledgerEntries)
                ..where((l) => l.childId.equals(childId))
                ..where((l) => l.type.equals('savings_move')))
              .get();
      return <int>[for (final row in rows) row.amountPence];
    }

    Future<void> setSaved(String goalId, int pence) {
      return (db.update(db.savingsGoals)..where((g) => g.id.equals(goalId)))
          .write(SavingsGoalsCompanion(savedPence: Value(pence)));
    }

    test('a move inside the remainder lands in full', () async {
      final repo = KidJarRepositoryImpl(db: db);

      await repo.moveToSavings(
        childId: 'maya',
        goalId: 'goal-lego',
        amountPence: 100,
      );

      expect(await savedOf('goal-lego'), 1650);
      expect(await savingsMovesFor('maya'), contains(100));
    });

    test('a move past the remainder stops at the target', () async {
      await setSaved('goal-lego', 2400);
      final repo = KidJarRepositoryImpl(db: db);

      await repo.moveToSavings(
        childId: 'maya',
        goalId: 'goal-lego',
        amountPence: 500,
      );

      expect(await savedOf('goal-lego'), 2499);
      expect(await savingsMovesFor('maya'), contains(99));
    });

    test('a move into a full goal writes nothing', () async {
      await setSaved('goal-lego', 2499);
      final before = await savingsMovesFor('maya');
      final repo = KidJarRepositoryImpl(db: db);

      await repo.moveToSavings(
        childId: 'maya',
        goalId: 'goal-lego',
        amountPence: 100,
      );

      expect(await savedOf('goal-lego'), 2499);
      expect(await savingsMovesFor('maya'), before);
    });
  });
}
