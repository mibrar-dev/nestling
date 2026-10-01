// Seed contract tests: Seed.demo() must reproduce the DESIGN_SPEC §5
// family exactly, because every screen number derives from it.

import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  group('Seed.demo', () {
    setUp(() async {
      await Seed.demo(db);
    });

    test('Maya matches the spec', () async {
      final mayaQuery = db.select(db.children)
        ..where((c) => c.id.equals('maya'));
      final maya = await mayaQuery.getSingle();
      expect(maya.nickname, 'Maya');
      expect(maya.ageYears, 9);
      expect(maya.ageBand, '7-9');
      expect(maya.avatarColour, 'lilac');
      expect(maya.pipStyle, 'mochi');
      expect(maya.pipSkin, 'sunny');
      expect(maya.pipStage, 3);
      expect(maya.coins, 120);
      expect(maya.weeklyBasePence, 300);
      expect(maya.pinHash, isNotNull);
    });

    test('Leo matches the spec', () async {
      final leoQuery = db.select(db.children)..where((c) => c.id.equals('leo'));
      final leo = await leoQuery.getSingle();
      expect(leo.nickname, 'Leo');
      expect(leo.ageYears, 6);
      expect(leo.ageBand, '4-6');
      expect(leo.avatarColour, 'peach');
      expect(leo.pipStyle, 'bolt');
      expect(leo.pipSkin, 'sky');
      expect(leo.pipStage, 2);
      expect(leo.coins, 45);
      expect(leo.weeklyBasePence, 150);
    });

    test('Sarah + invited James', () async {
      final members = await db.select(db.members).get();
      expect(members.map((m) => m.id), containsAll(['sarah', 'james']));
      final james = members.firstWhere((m) => m.id == 'james');
      expect(james.role, 'co-parent');
      expect(james.inviteStatus, 'invited');
    });

    test('12 active quests, 3 awaiting approval', () async {
      final questsQuery = db.select(db.quests)
        ..where((q) => q.active.equals(true));
      final quests = await questsQuery.get();
      expect(quests, hasLength(12));
      final pendingQuery = db.select(db.questCompletions)
        ..where((c) => c.status.equals('done_pending'));
      final pending = await pendingQuery.get();
      expect(pending, hasLength(3));
    });

    test('Maya is owed 420p = 300 base + 120 quests', () async {
      final rowsQuery = db.select(db.ledgerEntries)
        ..where((l) => l.childId.equals('maya'));
      final rows = await rowsQuery.get();
      // Newest-first, cut at the latest payout; only base + bonus count.
      final ordered = rows.toList()..sort((a, b) => b.date.compareTo(a.date));
      var base = 0;
      var quests = 0;
      for (final row in ordered) {
        if (row.type == 'payout') break;
        if (row.type == 'weekly_base') base += row.amountPence;
        if (row.type == 'quest_bonus') quests += row.amountPence;
      }
      expect(base, 300);
      expect(quests, 120);
      expect(base + quests, 420);
    });

    test('Leo is owed 210p = 150 base + 60 quests', () async {
      final rowsQuery = db.select(db.ledgerEntries)
        ..where((l) => l.childId.equals('leo'));
      final rows = await rowsQuery.get();
      final ordered = rows.toList()..sort((a, b) => b.date.compareTo(a.date));
      var base = 0;
      var quests = 0;
      for (final row in ordered) {
        if (row.type == 'payout') break;
        if (row.type == 'weekly_base') base += row.amountPence;
        if (row.type == 'quest_bonus') quests += row.amountPence;
      }
      expect(base, 150);
      expect(quests, 60);
      expect(base + quests, 210);
    });

    test('Lego Friends goal 1550/2499', () async {
      final goal = await db.select(db.savingsGoals).getSingle();
      expect(goal.title, 'Lego Friends set');
      expect(goal.savedPence, 1550);
      expect(goal.targetPence, 2499);
    });

    test('6 rewards, badges 4+1, crash reports OFF', () async {
      expect(await db.select(db.rewards).get(), hasLength(6));
      final mayaQuery = db.select(db.earnedBadges)
        ..where((e) => e.childId.equals('maya'));
      final mayaBadges = await mayaQuery.get();
      final leoQuery = db.select(db.earnedBadges)
        ..where((e) => e.childId.equals('leo'));
      final leoBadges = await leoQuery.get();
      expect(mayaBadges, hasLength(4));
      expect(leoBadges, hasLength(1));
      final setting = await db.select(db.settings).getSingle();
      expect(setting.crashReportConsent, isFalse);
      expect(setting.payoutDay, 6);
    });

    test('app_state onboarded, active, Maya, parent', () async {
      final state = await db.select(db.appState).getSingle();
      expect(state.onboardingComplete, isTrue);
      expect(state.subscriptionStatus, 'active');
      expect(state.activeChildId, 'maya');
      expect(state.appMode, 'parent');
    });

    test('wardrobe: Maya owns 2, Leo owns 1', () async {
      Future<int> owned(String child) async {
        final wardrobeQuery = db.select(db.pipWardrobe)
          ..where((w) => w.childId.equals(child) & w.owned.equals(true));
        final rows = await wardrobeQuery.get();
        return rows.length;
      }

      expect(await owned('maya'), 2);
      expect(await owned('leo'), 1);
    });
  });

  group('Seed.empty', () {
    test('onboarded parent, no children or quests', () async {
      await Seed.empty(db);
      expect(await db.select(db.children).get(), isEmpty);
      expect(await db.select(db.quests).get(), isEmpty);
      final state = await db.select(db.appState).getSingle();
      expect(state.onboardingComplete, isTrue);
    });
  });

  group('Seed.fresh', () {
    test('nothing: onboarding incomplete', () async {
      await Seed.fresh(db);
      expect(await db.select(db.children).get(), isEmpty);
      final state = await db.select(db.appState).getSingle();
      expect(state.onboardingComplete, isFalse);
    });
  });
}
