// K03b seed contract: Seed.kidAllDone() is exactly Seed.demo() plus a
// `done_pending` completion for each of Maya's quests that is not yet done
// in the current period — so Maya reads "6 of 6 done" ("All done!") while
// Leo and every table except `quest_completions` stay identical to `demo`.

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/london_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/kid_home/data/kid_home_repository_impl.dart';

void main() {
  late AppDatabase db;
  late AppDatabase demoDb;

  setUp(() async {
    db = AppDatabase.memory();
    demoDb = AppDatabase.memory();
    await Seed.demo(demoDb);
    await Seed.kidAllDone(db);
  });

  tearDown(() async {
    await db.close();
    await demoDb.close();
  });

  group('Seed.kidAllDone', () {
    test('Maya has 6 of 6 done in the current period', () async {
      // Driven through the real kid-home repository — the same items K03b
      // renders (active child is Maya in the demo app_state).
      final repo = KidHomeRepositoryImpl(db: db);
      final items = await repo.watchItems().first;
      expect(items, hasLength(6));
      expect(items.where((i) => i.status == 'to_do'), isEmpty);

      // Per-quest statuses mirror the K03b HTML per-row labels: the two
      // quests still open in `demo` ("Done" + coin pill) become pending;
      // the rest keep their demo state.
      final byQuest = <String, String>{
        for (final i in items) i.questId: i.status,
      };
      expect(byQuest, <String, String>{
        'q-dishwasher': 'done_pending',
        'q-reading': 'done_pending',
        'q-bins': 'approved',
        'q-tidy': 'done_pending',
        'q-hoover': 'approved',
        'q-table': 'done_pending',
      });
    });

    test(
      'every Maya quest has a done completion in the pinned period',
      () async {
        final now = appNowUtc();
        final quests = await (db.select(
          db.quests,
        )..where((q) => q.assigneeChildId.equals('maya'))).get();
        expect(quests, hasLength(6));
        for (final quest in quests) {
          final rows =
              await (db.select(db.questCompletions)..where(
                    (c) =>
                        c.questId.equals(quest.id) & c.childId.equals('maya'),
                  ))
                  .get();
          final current =
              rows
                  .where(
                    (c) => countsForCurrentPeriod(
                      quest.repeatRule,
                      c.createdAt,
                      now,
                    ),
                  )
                  .toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          // Latest in-period row decides (kid_home `_watchItemsFor`): a
          // stale `to_do` row earlier in the period does not un-do the quest.
          expect(current, isNotEmpty, reason: quest.id);
          expect(
            current.first.status == 'done_pending' ||
                current.first.status == 'approved',
            isTrue,
            reason: quest.id,
          );
        }
      },
    );

    test(
      'added completions are pending only, no ledger or coin effects',
      () async {
        final demoRows = await demoDb.select(demoDb.questCompletions).get()
          ..sort((a, b) => a.id.compareTo(b.id));
        final rows = await db.select(db.questCompletions).get()
          ..sort((a, b) => a.id.compareTo(b.id));
        expect(rows.length, demoRows.length + 2);
        for (var i = 0; i < demoRows.length; i++) {
          expect(rows[i], demoRows[i]);
        }
        final added = rows.sublist(demoRows.length);
        expect(added.map((c) => c.questId), ['q-reading', 'q-tidy']);
        for (final c in added) {
          // Exactly what `completeQuest` writes for a tap: status + coin
          // snapshot + timestamps — no ledger row, no coin change.
          expect(c.childId, 'maya');
          expect(c.familyId, Seed.familyId);
          expect(c.status, 'done_pending');
          expect(c.decidedAt, isNull);
          expect(c.kidNote, isNull);
          // Drift reads instants back in the platform zone: compare in UTC.
          expect(c.createdAt.toUtc(), Seed.utc(10, 3, 8, 30));
          expect(c.createdAtTz, 'Europe/London');
        }
        expect(added.firstWhere((c) => c.questId == 'q-reading').coins, 10);
        expect(added.firstWhere((c) => c.questId == 'q-tidy').coins, 15);

        // Balances untouched: Maya still 120 coins, ledger still £4.20 owed.
        final maya = await (db.select(
          db.children,
        )..where((c) => c.id.equals('maya'))).getSingle();
        expect(maya.coins, 120);
        Future<int> owed(AppDatabase d, String child) async {
          final entries = await (d.select(
            d.ledgerEntries,
          )..where((l) => l.childId.equals(child))).get();
          final ordered = entries.toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          var base = 0;
          var quests = 0;
          for (final row in ordered) {
            if (row.type == 'payout') break;
            if (row.type == 'weekly_base') base += row.amountPence;
            if (row.type == 'quest_bonus') quests += row.amountPence;
          }
          return base + quests;
        }

        expect(await owed(db, 'maya'), 420);
        expect(await owed(demoDb, 'maya'), 420);
      },
    );

    test('Leo unchanged vs demo', () async {
      Future<List<QuestCompletion>> completionsFor(
        AppDatabase d,
        String child,
      ) async {
        final rows = await (d.select(
          d.questCompletions,
        )..where((c) => c.childId.equals(child))).get();
        return rows..sort((a, b) => a.id.compareTo(b.id));
      }

      Future<List<LedgerEntry>> ledgerFor(AppDatabase d, String child) async {
        final rows = await (d.select(
          d.ledgerEntries,
        )..where((l) => l.childId.equals(child))).get();
        return rows..sort((a, b) => a.id.compareTo(b.id));
      }

      expect(
        await completionsFor(db, 'leo'),
        await completionsFor(demoDb, 'leo'),
      );
      expect(await ledgerFor(db, 'leo'), await ledgerFor(demoDb, 'leo'));
      final leo = await (db.select(
        db.children,
      )..where((c) => c.id.equals('leo'))).getSingle();
      final demoLeo = await (demoDb.select(
        demoDb.children,
      )..where((c) => c.id.equals('leo'))).getSingle();
      expect(leo, demoLeo);
    });

    test('every table except quest_completions is identical to demo', () async {
      Future<List<List<Object>>> snapshot(AppDatabase d) async => [
        await d.select(d.families).get(),
        await d.select(d.members).get(),
        await d.select(d.children).get(),
        await d.select(d.quests).get(),
        await d.select(d.ledgerEntries).get(),
        await d.select(d.savingsGoals).get(),
        await d.select(d.rewards).get(),
        await d.select(d.rewardRedemptions).get(),
        await d.select(d.badges).get(),
        await d.select(d.earnedBadges).get(),
        await d.select(d.pipWardrobe).get(),
        await d.select(d.settings).get(),
        await d.select(d.appState).get(),
      ];
      expect(await snapshot(db), await snapshot(demoDb));
    });
  });
}
