// K01 repository tests (DB-backed, Seed.demo): the picker roster contract.
//
// `watchProfiles` returns children in creation order (Maya, then Leo —
// never alphabetical) with the K01 display fields (`ageBand`, Pip look,
// `pinSet`), and `setActiveChild` persists the tapped profile to
// `app_state.activeChildId` so the PIN / home routes resolve it.

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/components/audience.dart';
import 'package:nestling/core/design_system/components/quest_icons.dart';
import 'package:nestling/features/kid_home/data/kid_home_repository_impl.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_growth.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    await Seed.demo(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('K01 profiles', () {
    test('watchProfiles lists Maya then Leo with K01 fields', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      final profiles = await repo.watchProfiles().first;

      expect(profiles.map((child) => child.id).toList(), <String>[
        'maya',
        'leo',
      ], reason: 'creation order (Maya added first), never alphabetical');

      final maya = profiles.first;
      expect(maya.nickname, 'Maya');
      expect(maya.ageBand, '7-9');
      expect(maya.avatarColour, 'lilac');
      expect(maya.pipStyle, 'mochi');
      expect(maya.pipSkin, 'sunny');
      expect(maya.pipStage, 3);
      expect(maya.pinSet, isTrue);

      final leo = profiles.last;
      expect(leo.nickname, 'Leo');
      expect(leo.ageBand, '4-6');
      expect(leo.avatarColour, 'peach');
      expect(leo.pipStyle, 'bolt');
      expect(leo.pipSkin, 'sky');
      expect(leo.pipStage, 2);
      expect(leo.pinSet, isFalse);
    });

    test('setActiveChild persists the tapped profile', () async {
      final repo = KidHomeRepositoryImpl(db: db);

      await repo.setActiveChild('leo');
      final state = await (db.select(
        db.appState,
      )..where((a) => a.id.equals(1))).getSingle();
      expect(state.activeChildId, 'leo');

      // …and the combined home stream follows it without a reload.
      final home = await repo.watchHome().first;
      expect(home.child?.id, 'leo');

      await repo.setActiveChild('maya');
      final back = await (db.select(
        db.appState,
      )..where((a) => a.id.equals(1))).getSingle();
      expect(back.activeChildId, 'maya');
    });
  });

  group('K02 PIN verification', () {
    test('Maya accepts 1234 and rejects anything else', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      expect(await repo.verifyPin('maya', '1234'), isTrue);
      expect(await repo.verifyPin('maya', '9999'), isFalse);
      expect(await repo.verifyPin('maya', ''), isFalse);
    });

    test('Leo has no PIN so any code auto-passes', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      expect(await repo.verifyPin('leo', '1234'), isTrue);
      expect(await repo.verifyPin('leo', '0000'), isTrue);
    });
  });

  // K05 growth inputs (logic layer): `pipTotalCoins` is mapped from the
  // child's row (DB truth, never the design's hard-coded 175), and the pure
  // growth helpers derive the card's remaining / fraction / copy from it.
  group('K05 pipTotalCoins mapping + growth helpers', () {
    test('watchProfiles carries lifetime coins in creation order', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      final profiles = await repo.watchProfiles().first;
      expect(profiles.map((child) => child.pipTotalCoins).toList(), <int>[
        175,
        60,
      ], reason: 'Maya 175 then Leo 60, straight from Seed.demo rows');
    });

    test('watchHome carries the active child lifetime coins', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      // Seed.demo plays Maya.
      final home = await repo.watchHome().first;
      expect(home.child?.pipTotalCoins, 175);
      expect(kidPipCoinsRemaining(home.child!.pipTotalCoins), 75);
      expect(
        kidPipGrowthFraction(home.child!.pipTotalCoins),
        closeTo(0.7, 1e-9),
      );
    });

    test('Leo maps 60 → 190 more at 0.24', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      await repo.setActiveChild('leo');
      final home = await repo.watchHome().first;
      expect(home.child?.pipTotalCoins, 60);
      expect(kidPipCoinsRemaining(60), 190);
      expect(kidPipGrowthFraction(60), closeTo(0.24, 1e-9));
    });

    test('growth copy and count match the K05 card', () {
      expect(kidPipGrowthCopy(175), 'Pip needs 75 more coins to grow');
      expect(kidPipGrowthCount(175), '175 of 250 coins');
      expect(kidPipGrowthCopy(60), 'Pip needs 190 more coins to grow');
      expect(kidPipGrowthCopy(249), 'Pip needs 1 more coin to grow');
      expect(kidPipGrowthCopy(250), 'Pip is ready to grow!');
      expect(kidPipGrowthCopy(999), 'Pip is ready to grow!');
      expect(kidPipGrowthFraction(250), 1.0);
      expect(kidPipGrowthFraction(999), 1.0);
      expect(kidPipCoinsRemaining(250), 0);
    });
  });

  // K04 ICONS audience guard — data premise (FIXES_3, "the gap I left").
  //
  // The full guard (rendered glyph == kid table) needs the view, which is
  // UI-builder owned; this group pins what the logic layer owns: the
  // database actually serves the icon keys the guard reasons about, and
  // the shared single source distinguishes the audiences on exactly
  // those keys. Read from the DB (DATA OVER MOCKS) — never hard-coded.
  group('K04 ICONS audience guard — data premise', () {
    test('Maya seed quests carry keys covering the divergent set', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      // Seed.demo plays Maya, so watchItems yields her quests directly.
      final items = await repo.watchItems().first;

      final keys = items.map((item) => item.icon).toSet();
      // The audience-divergent keys: the kid table draws its own glyph
      // for exactly these; every other key is shared.
      expect(keys, containsAll(<String>['bed', 'dishwasher', 'book']));
      // Every stored key resolves through the shared single source.
      expect(questIconKeys, containsAll(keys));
    });

    test('questIconFor splits kid from parent on the divergent keys only', () {
      for (final key in <String>[
        'bed',
        'dishwasher',
        'book',
        'reading',
        'bins',
        'bin',
      ]) {
        expect(
          questIconFor(key, audience: NestAudience.kid),
          isNot(questIconFor(key, audience: NestAudience.parent)),
          reason: '$key must render the kid glyph on K04, never the parent',
        );
      }
      for (final key in <String>['hoover', 'plate']) {
        expect(
          questIconFor(key, audience: NestAudience.kid),
          questIconFor(key, audience: NestAudience.parent),
          reason: '$key is shared between audiences',
        );
      }
    });
  });

  // K03b ROW ORDER + ROW META — logic-layer premises (FIXES_1, 04:52).
  //
  // The view renders `state.items` in order (no re-sort), so the repository
  // order IS the card order: creation order (dishwasher, reading, bins,
  // tidy, hoover, table — the seed stamps one second per quest), never
  // alphabetical. Card 1 stays 'Empty the dishwasher' either way, so K03's
  // pinned first card does not move. `needsApproval` rides straight from
  // the quest row for the view's done-row meta branch.
  group('K03b row order + approval flag', () {
    test('watchItems lists Maya quests in creation order', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      // Seed.demo plays Maya, so watchItems yields her quests directly.
      final items = await repo.watchItems().first;
      expect(items.map((item) => item.questId).toList(), <String>[
        'q-dishwasher',
        'q-reading',
        'q-bins',
        'q-tidy',
        'q-hoover',
        'q-table',
      ], reason: 'creation order, exactly the K03/K03b HTML row order');
    });

    test('seed quests carry needsApproval true from the DB default', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      final items = await repo.watchItems().first;
      expect(items, hasLength(6));
      expect(
        items.every((item) => item.needsApproval),
        isTrue,
        reason:
            'the seed never clears needs_approval; the column defaults true',
      );
    });

    test('clearing needs_approval surfaces on the entity', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      await (db.update(db.quests)..where((q) => q.id.equals('q-tidy'))).write(
        const QuestsCompanion(needsApproval: Value(false)),
      );
      final items = await repo.watchItems().first;
      final tidy = items.singleWhere((item) => item.questId == 'q-tidy');
      expect(tidy.needsApproval, isFalse);
      expect(
        items
            .where((item) => item.questId != 'q-tidy')
            .every((item) => item.needsApproval),
        isTrue,
      );
    });
  });

  // K03B-BUG-6 — terminal completion for no-approval quests (FIXES_2).
  //
  // A quest with "Needs my approval" OFF must complete as `approved` (+
  // `decidedAt`) with a `quest_bonus` ledger credit in the same
  // transaction — mirroring `ApprovalsRepositoryImpl.approve` — so it never
  // lands in the P11 queue (which lists `done_pending` only). Approval
  // quests keep the `done_pending` write with no ledger row.
  group('K03B-BUG-6 terminal completion', () {
    Future<void> setNoApproval(String questId) async {
      await (db.update(db.quests)..where((q) => q.id.equals(questId))).write(
        const QuestsCompanion(needsApproval: Value(false)),
      );
    }

    Future<List<QuestCompletion>> completionsFor(String questId) {
      return (db.select(
            db.questCompletions,
          )..where((c) => c.questId.equals(questId) & c.childId.equals('maya')))
          .get();
    }

    Future<List<LedgerEntry>> bonusesFor(String note) {
      return (db.select(db.ledgerEntries)..where(
            (l) =>
                l.childId.equals('maya') &
                l.type.equals('quest_bonus') &
                l.note.equals(note),
          ))
          .get();
    }

    test(
      'flip path writes approved + decidedAt with one ledger credit',
      () async {
        // Seed.demo leaves q-tidy `to_do` today, so this flips the open row.
        // (Seed history already holds a 28p 'Tidy your bedroom' bonus, so
        // assert the delta, not the absolute rows.)
        final repo = KidHomeRepositoryImpl(db: db);
        await setNoApproval('q-tidy');
        final before = await bonusesFor('Tidy your bedroom');
        await repo.completeQuest('maya', 'q-tidy');

        final rows = await completionsFor('q-tidy');
        expect(
          rows.where((c) => c.status == 'done_pending'),
          isEmpty,
          reason: 'no P11 queue row for a quest that needs no approval',
        );
        final done = rows.singleWhere((c) => c.status == 'approved');
        expect(done.decidedAt, isNotNull);

        final after = await bonusesFor('Tidy your bedroom');
        expect(after.length, before.length + 1);
        final fresh = after
            .where((l) => before.every((b) => b.id != l.id))
            .single;
        expect(fresh.amountPence, 15);
        expect(fresh.type, 'quest_bonus');

        final items = await repo.watchItems().first;
        expect(
          items.singleWhere((item) => item.questId == 'q-tidy').status,
          'approved',
        );
      },
    );

    test('insert path (no open row) is terminal too', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      await (db.delete(db.questCompletions)..where(
            (c) => c.questId.equals('q-tidy') & c.childId.equals('maya'),
          ))
          .go();
      await setNoApproval('q-tidy');
      final before = await bonusesFor('Tidy your bedroom');
      await repo.completeQuest('maya', 'q-tidy');

      final rows = await completionsFor('q-tidy');
      expect(rows, hasLength(1));
      expect(rows.single.status, 'approved');
      expect(rows.single.decidedAt, isNotNull);
      final after = await bonusesFor('Tidy your bedroom');
      expect(after.length, before.length + 1);
      expect(
        after
            .where((l) => before.every((b) => b.id != l.id))
            .single
            .amountPence,
        15,
      );
    });

    test('retry after a terminal completion credits nothing more', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      await setNoApproval('q-tidy');
      final before = await bonusesFor('Tidy your bedroom');
      await repo.completeQuest('maya', 'q-tidy');
      await repo.completeQuest('maya', 'q-tidy');

      final after = await bonusesFor('Tidy your bedroom');
      expect(after.length, before.length + 1);
      final rows = await completionsFor('q-tidy');
      expect(rows.where((c) => c.status == 'approved'), hasLength(1));
    });

    test(
      'approval quests still write done_pending with no ledger row',
      () async {
        final repo = KidHomeRepositoryImpl(db: db);
        await repo.completeQuest('maya', 'q-reading');

        final rows = await completionsFor('q-reading');
        expect(rows.where((c) => c.status == 'done_pending'), hasLength(1));
        final flipped = rows.singleWhere((c) => c.status == 'done_pending');
        expect(flipped.decidedAt, isNull);
        expect(await bonusesFor('Reading – 20 minutes'), isEmpty);
      },
    );
  });
}
