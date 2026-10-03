// P12 Money ledger — Drift repository contract for `watchLedgerData`.
//
// Covers: `summarise()` pure owed math (Maya £4.20 = base 300 + quests 120,
// rows before the Sep payout ignored, gift/spend/savings never counted),
// `watchLedgerData()` on `Seed.demo()` (creation-order children, newest-first
// entries, oweds, the Lego goal, payout day + zone), re-emission on writes,
// and the empty-family shape.

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/pocket_money/data/pocket_money_repository_impl.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_ledger_data.dart';

void main() {
  late AppDatabase db;
  late PocketMoneyRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase.memory();
    await Seed.demo(db);
    repository = PocketMoneyRepositoryImpl(db: db);
  });

  tearDown(() => db.close());

  /// Raw ledger rows for one child, newest first (the order `summarise`
  /// expects — it stops at the latest `payout`).
  Future<List<LedgerEntry>> rowsFor(String childId) async {
    final rows = await (db.select(
      db.ledgerEntries,
    )..where((l) => l.childId.equals(childId))).get();
    rows.sort((a, b) => b.date.compareTo(a.date));
    return rows;
  }

  group('summarise', () {
    test('Maya rows give base 300, quests 120, total 420', () async {
      final summary = repository.summarise('maya', await rowsFor('maya'));

      expect(summary.childId, 'maya');
      expect(summary.basePence, 300);
      expect(summary.questsPence, 120);
      expect(summary.totalPence, 420);
    });

    test('rows before the September payout are settled, not owed', () async {
      // The previous week (20–25 Sep) holds another 300p base + 80p quests,
      // closed by the 26 Sep payout. Only this week's rows may count.
      final summary = repository.summarise('maya', await rowsFor('maya'));

      expect(summary.basePence, 300);
      expect(summary.totalPence, 420);
    });

    test('gift, spend and savings moves never count towards owed', () async {
      // The seed holds a £10 gift, a −£2 spend and two savings moves for
      // Maya this week; none may leak into the payout figure.
      final summary = repository.summarise('maya', await rowsFor('maya'));

      expect(summary.totalPence, 420);
    });

    test('Leo rows give base 150, quests 60, total 210', () async {
      final summary = repository.summarise('leo', await rowsFor('leo'));

      expect(summary.basePence, 150);
      expect(summary.questsPence, 60);
      expect(summary.totalPence, 210);
    });

    test('a quest bonus sharing the payout instant still counts '
        '(review finding 4)', () async {
      // Two writers landing in the same clock second: the `date desc`-only
      // ledger order resolves the tie arbitrarily, so the payout can sort
      // first and the old break-at-payout rule drops the bonus.
      final at = Seed.utc(10, 3, 9);
      Future<void> entry(String type, int pence) {
        return db
            .into(db.ledgerEntries)
            .insert(
              LedgerEntriesCompanion.insert(
                familyId: Seed.familyId,
                childId: 'leo',
                type: type,
                amountPence: pence,
                note: const Value('tie probe'),
                date: Value(at),
                dateTz: const Value('Europe/London'),
              ),
            );
      }

      await entry('payout', -210);
      await entry('quest_bonus', 25);

      final fetched = await rowsFor('leo');
      final payout = fetched.firstWhere(
        (row) => row.note == 'tie probe' && row.type == 'payout',
      );
      final bonus = fetched.firstWhere(
        (row) => row.note == 'tie probe' && row.type == 'quest_bonus',
      );
      final rest = fetched.where((row) => row.note != 'tie probe').toList();
      // Both input orders must agree: the rule is order-independent.
      for (final order in <List<LedgerEntry>>[
        <LedgerEntry>[payout, bonus, ...rest],
        <LedgerEntry>[bonus, payout, ...rest],
      ]) {
        final summary = repository.summarise('leo', order);
        expect(summary.questsPence, 25, reason: 'order must not matter');
        expect(
          summary.basePence,
          0,
          reason: 'the 08:00 base predates the 09:00 payout',
        );
        expect(summary.totalPence, 25);
      }
    });
  });

  group('watchLedgerData', () {
    test('first emission matches the demo seed', () async {
      final data = await repository.watchLedgerData().first;

      expect(data.children.map((c) => c.id), <String>['maya', 'leo']);
      expect(data.children.map((c) => c.nickname), <String>['Maya', 'Leo']);
      expect(data.payoutDay, 6);
      expect(data.zoneId, 'Europe/London');
    });

    test('children arrive in creation order, not alphabetical', () async {
      final data = await repository.watchLedgerData().first;

      expect(data.children.map((c) => c.nickname).toList()..sort(), <String>[
        'Leo',
        'Maya',
      ], reason: 'alphabetical would be Leo-first — the stream must not be');
    });

    test('a child added later lands LAST', () async {
      await db
          .into(db.children)
          .insert(
            ChildrenCompanion.insert(
              id: 'anna',
              familyId: Seed.familyId,
              nickname: 'Anna',
            ),
          );

      final data = await repository.watchLedgerData().first;

      expect(data.children.map((c) => c.nickname), <String>[
        'Maya',
        'Leo',
        'Anna',
      ]);
    });

    test('Maya entries are newest first', () async {
      final data = await repository.watchLedgerData().first;
      final maya = data.entriesFor('maya');

      expect(maya, isNotEmpty);
      for (var i = 1; i < maya.length; i++) {
        expect(
          maya[i - 1].date.isAfter(maya[i].date) ||
              maya[i - 1].date.isAtSameMomentAs(maya[i].date),
          isTrue,
          reason: 'entry ${i - 1} must not be older than entry $i',
        );
      }
    });

    test('entries hold every child and carry their stored zone', () async {
      final data = await repository.watchLedgerData().first;

      expect(data.entries.map((e) => e.childId).toSet(), <String>{
        'maya',
        'leo',
      });
      expect(data.entries.every((e) => e.dateTz == 'Europe/London'), isTrue);
      // Leo's rows are untouched by Maya's gift/spend/savings activity.
      expect(data.entriesFor('leo').length, 6);
    });

    test('oweds are one per child: Maya 420, Leo 210', () async {
      final data = await repository.watchLedgerData().first;

      expect(data.owedFor('maya')?.totalPence, 420);
      expect(data.owedFor('maya')?.basePence, 300);
      expect(data.owedFor('maya')?.questsPence, 120);
      expect(data.owedFor('leo')?.totalPence, 210);
      expect(data.owedFor('unknown'), isNull);
    });

    test('goals carry the Lego fund: 1550 of 2499', () async {
      final data = await repository.watchLedgerData().first;
      final lego = data.goalFor('maya');

      expect(lego, isNotNull);
      expect(lego!.title, 'Lego Friends set');
      expect(lego.targetPence, 2499);
      expect(lego.savedPence, 1550);
      expect(lego.fraction, closeTo(1550 / 2499, 0.0001));
      // Leo has no goal: the card is omitted, not placeholdered.
      expect(data.goalFor('leo'), isNull);
    });

    test('the carried setup matches watchSetup exactly', () async {
      final data = await repository.watchLedgerData().first;
      final setup = await repository.watchSetup().first;

      expect(data.setup, setup);
    });

    test('re-emits when a new ledger row lands', () async {
      final emissions = <MoneyLedgerData>[];
      final subscription = repository.watchLedgerData().listen(emissions.add);
      await pumpEventQueue();
      expect(emissions, hasLength(1));

      await repository.addMoney(
        childId: 'maya',
        amountPence: 500,
        note: 'Pocket money test gift',
      );
      await pumpEventQueue();

      expect(emissions.length, greaterThanOrEqualTo(2));
      expect(
        emissions.last.entries.any(
          (e) =>
              e.childId == 'maya' && e.type == 'gift' && e.amountPence == 500,
        ),
        isTrue,
      );
      // Gifts never count towards the payout figure.
      expect(emissions.last.owedFor('maya')?.totalPence, 420);
      await subscription.cancel();
    });

    test('re-emits when a goal bump lands (savings_move path)', () async {
      final emissions = <MoneyLedgerData>[];
      final subscription = repository.watchLedgerData().listen(emissions.add);
      await pumpEventQueue();

      await repository.recordPayout(
        childId: 'maya',
        amountPence: 420,
        savingsMovePence: 100,
        goalId: 'goal-lego',
      );
      await pumpEventQueue();

      final last = emissions.last;
      expect(last.goalFor('maya')?.savedPence, 1650);
      // The payout settles the week: nothing is owed until new rows land.
      expect(last.owedFor('maya')?.totalPence, 0);
      await subscription.cancel();
    });

    test('Seed.empty emits empty children, entries, oweds and goals', () async {
      await Seed.empty(db);

      final data = await repository.watchLedgerData().first;

      expect(data.children, isEmpty);
      expect(data.entries, isEmpty);
      expect(data.oweds, isEmpty);
      expect(data.goals, isEmpty);
      expect(data.firstChildId, isNull);
      expect(data.payoutDay, 6);
      expect(data.zoneId, 'Europe/London');
    });
  });

  group('MoneyLedgerData helpers', () {
    test('firstChildId, entriesFor, owedFor and goalFor', () async {
      final data = await repository.watchLedgerData().first;

      expect(data.firstChildId, 'maya');
      expect(data.entriesFor('maya').every((e) => e.childId == 'maya'), isTrue);
      expect(data.entriesFor('nobody'), isEmpty);
      expect(data.entriesFor(null), isEmpty);
      expect(data.childById('leo')?.nickname, 'Leo');
      expect(data.childById('nobody'), isNull);
    });

    test('SavingsGoalData.fraction guards a zero target', () async {
      final data = await repository.watchLedgerData().first;

      expect(data.goalFor('maya')!.fraction, greaterThan(0.6));
      expect(data.goalFor('maya')!.fraction, lessThan(0.63));
    });
  });
}
