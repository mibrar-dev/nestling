// Repository contract tests over Seed.demo() in an in-memory database.
// Every feature repository is exercised through its public interface
// (streams + mutations), including the spec numbers screens depend on.

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/approvals/data/approvals_repository_impl.dart';
import 'package:nestling/features/auth/data/auth_repository_impl.dart';
import 'package:nestling/features/badges/data/badges_repository_impl.dart';
import 'package:nestling/features/family/data/family_repository_impl.dart';
import 'package:nestling/features/kid_home/data/kid_home_repository_impl.dart';
import 'package:nestling/features/kid_jar/data/kid_jar_repository_impl.dart';
import 'package:nestling/features/kid_shop/data/kid_shop_repository_impl.dart';
import 'package:nestling/features/onboarding/data/onboarding_repository_impl.dart';
import 'package:nestling/features/parental_gate/data/parental_gate_repository_impl.dart';
import 'package:nestling/features/paywall/data/paywall_repository_impl.dart';
import 'package:nestling/features/pip/data/pip_repository_impl.dart';
import 'package:nestling/features/pocket_money/data/pocket_money_repository_impl.dart';
import 'package:nestling/features/privacy_consent/data/privacy_consent_repository_impl.dart';
import 'package:nestling/features/quests/data/quests_repository_impl.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart' as domain;
import 'package:nestling/features/rewards/data/rewards_repository_impl.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart'
    as reward_domain;
import 'package:nestling/features/settings/data/settings_repository_impl.dart';
import 'package:nestling/features/today/data/today_repository_impl.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    await Seed.demo(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('today', () {
    test('Maya 4 of 6, Leo 2 of 4', () async {
      final repo = TodayRepositoryImpl(db: db);
      final items = await repo.watchItems().first;
      expect(items.where((i) => i.childId == 'maya'), hasLength(6));
      expect(items.where((i) => i.childId == 'leo'), hasLength(4));
      final summaries = await repo.watchSummaries().first;
      final maya = summaries.firstWhere((s) => s.childId == 'maya');
      expect(maya.done, 4);
      expect(maya.total, 6);
      expect(maya.coins, 120);
      final leo = summaries.firstWhere((s) => s.childId == 'leo');
      expect(leo.done, 2);
      expect(leo.total, 4);
      expect(leo.coins, 45);
    });
  });

  group('quests', () {
    test('ideas + CRUD', () async {
      final repo = QuestsRepositoryImpl(db: db);
      expect(repo.ideas(), hasLength(10));
      expect(await repo.watchItems().first, hasLength(12));
      await repo.createQuest(
        const domain.Quest(
          id: 'q-test',
          title: 'Test quest',
          detail: 'Weekly · 5 coins',
          icon: 'star',
          coins: 5,
          repeatRule: 'weekly',
          days: '',
          dueLabel: null,
          needsApproval: true,
          assigneeChildId: 'maya',
          active: true,
        ),
      );
      expect(await repo.watchItems().first, hasLength(13));
      final created = await repo.getQuest('q-test');
      expect(created?.title, 'Test quest');
      await repo.updateQuest(
        const domain.Quest(
          id: 'q-test',
          title: 'Test quest',
          detail: 'Weekly · 7 coins',
          icon: 'star',
          coins: 7,
          repeatRule: 'weekly',
          days: '',
          dueLabel: null,
          needsApproval: true,
          assigneeChildId: 'maya',
          active: true,
        ),
      );
      expect((await repo.getQuest('q-test'))?.coins, 7);
      await repo.deleteQuest('q-test');
      expect(await repo.watchItems().first, hasLength(12));
    });
  });

  group('approvals', () {
    test('approve moves coins via the ledger', () async {
      final approvals = ApprovalsRepositoryImpl(db: db);
      final pocket = PocketMoneyRepositoryImpl(db: db);
      expect(await approvals.watchItems().first, hasLength(3));
      expect((await pocket.owed('maya')).totalPence, 420);

      final dishwasher = (await approvals.watchItems().first).firstWhere(
        (a) => a.questId == 'q-dishwasher',
      );
      await approvals.approve(dishwasher.completionId);

      expect(await approvals.watchItems().first, hasLength(2));
      expect((await pocket.owed('maya')).totalPence, 435);
    });

    test('not-yet sends a kind note, moves nothing', () async {
      final approvals = ApprovalsRepositoryImpl(db: db);
      final pocket = PocketMoneyRepositoryImpl(db: db);
      final pending = await approvals.watchItems().first;
      await approvals.markNotYet(pending.first.completionId);
      expect(await approvals.watchItems().first, hasLength(2));
      expect((await pocket.owed('maya')).totalPence, 420);
    });

    test('approveAll clears the inbox', () async {
      final approvals = ApprovalsRepositoryImpl(db: db);
      await approvals.approveAll();
      expect(await approvals.watchItems().first, isEmpty);
    });
  });

  group('pocket money', () {
    test('owed, gifts, spending and payout', () async {
      final repo = PocketMoneyRepositoryImpl(db: db);
      expect((await repo.owed('maya')).totalPence, 420);
      expect((await repo.owed('leo')).totalPence, 210);

      await repo.addMoney(childId: 'maya', amountPence: 500, note: 'Test gift');
      expect((await repo.owed('maya')).totalPence, 420);

      await repo.recordSpending(
        childId: 'maya',
        amountPence: 200,
        note: 'Test spend',
      );
      final ledger = await repo.watchLedger('maya').first;
      expect(
        ledger.where((e) => e.note == 'Test spend' && e.amountPence == -200),
        hasLength(1),
      );

      await repo.recordPayout(
        childId: 'maya',
        amountPence: 420,
        savingsMovePence: 100,
        goalId: 'goal-lego',
      );
      // Only entries newer than the payout still count (the figure is
      // time-independent: the seed holds future-dated accruals).
      final after = await repo.watchLedger('maya').first;
      final payoutDate = after.firstWhere((e) => e.type == 'payout').date;
      var expected = 0;
      for (final entry in after) {
        if (!entry.date.isAfter(payoutDate)) continue;
        if (entry.type == 'weekly_base') expected += entry.amountPence;
        if (entry.type == 'quest_bonus') expected += entry.amountPence;
      }
      expect((await repo.owed('maya')).totalPence, expected);
      final goalQuery = db.select(db.savingsGoals)
        ..where((g) => g.id.equals('goal-lego'));
      final goal = await goalQuery.getSingle();
      expect(goal.savedPence, 1650);
    });
  });

  group('family', () {
    test('add, remove and invite', () async {
      final repo = FamilyRepositoryImpl(db: db);
      expect(await repo.watchChildren().first, hasLength(2));

      await repo.addChild(
        nickname: 'Noah',
        ageBand: '4-6',
        avatarColour: 'sky',
        weeklyBasePence: 100,
      );
      final kids = await repo.watchChildren().first;
      expect(kids, hasLength(3));
      final noah = kids.firstWhere((k) => k.nickname == 'Noah');
      expect(noah.weeklyBasePence, 100);

      await repo.removeChild(noah.id);
      expect(await repo.watchChildren().first, hasLength(2));

      await repo.inviteCoParent('Alex');
      final members = await repo.watchItems().first;
      expect(members, hasLength(3));
      expect(
        members.where((m) => m.name == 'Alex' && m.inviteStatus == 'invited'),
        hasLength(1),
      );
    });

    test('Maya profile aggregates', () async {
      final repo = FamilyRepositoryImpl(db: db);
      final maya = await repo.getChild('maya');
      expect(maya?.activeQuests, 6);
      expect(maya?.doneQuests, 4);
      expect(maya?.pinSet, isTrue);
    });
  });

  group('kid home', () {
    test('quests, completion and PIN', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      // Active child defaults to Maya via app_state.
      final items = await repo.watchItems().first;
      expect(items, hasLength(6));

      await repo.completeQuest('maya', 'q-reading');
      final after = await repo.watchItems().first;
      expect(
        after.firstWhere((q) => q.questId == 'q-reading').status,
        'done_pending',
      );

      expect(await repo.verifyPin('maya', '1234'), isTrue);
      expect(await repo.verifyPin('maya', '0000'), isFalse);
      expect(await repo.verifyPin('leo', '0000'), isTrue);
      expect(repo.stepsFor('q-tidy'), hasLength(3));
    });

    test('profiles list both children', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      expect(await repo.watchProfiles().first, hasLength(2));
    });
  });

  group('kid jar', () {
    test('summary mirrors the parent ledger', () async {
      final repo = KidJarRepositoryImpl(db: db);
      final summary = await repo.watchSummary('maya').first;
      expect(summary.owedPence, 420);
      expect(summary.nextPayoutDay, 'Saturday');
      expect(summary.goalTitle, 'Lego Friends set');
      expect(summary.goalSavedPence, 1550);
      expect(summary.goalTargetPence, 2499);
    });

    test('move to savings bumps the goal', () async {
      final repo = KidJarRepositoryImpl(db: db);
      await repo.moveToSavings(
        childId: 'maya',
        goalId: 'goal-lego',
        amountPence: 100,
      );
      final summary = await repo.watchSummary('maya').first;
      expect(summary.goalSavedPence, 1650);
    });
  });

  group('shop + rewards', () {
    test('affordability, request, approve', () async {
      final shop = KidShopRepositoryImpl(db: db);
      final rewards = RewardsRepositoryImpl(db: db);

      final maya = await shop.watchShop('maya').first;
      expect(maya, hasLength(6));
      expect(maya.firstWhere((r) => r.id == 'r-screen').affordable, isTrue);
      expect(maya.firstWhere((r) => r.id == 'r-cafe').affordable, isFalse);

      await shop.requestReward('maya', 'r-screen');
      var requests = await rewards.watchRequests().first;
      expect(requests.where((r) => r.status == 'requested'), hasLength(1));

      await rewards.approveRedemption(requests.first.id);
      requests = await rewards.watchRequests().first;
      expect(requests.first.status, 'approved');
      final kidQuery = db.select(db.children)
        ..where((c) => c.id.equals('maya'));
      final kid = await kidQuery.getSingle();
      expect(kid.coins, 70);
    });

    test('rewards CRUD + needs-OK toggle', () async {
      final rewards = RewardsRepositoryImpl(db: db);
      await rewards.createReward(
        const reward_domain.Reward(
          id: 'r-test',
          title: 'Test reward',
          detail: '25 coins',
          icon: 'gift',
          coinPrice: 25,
          needsOk: true,
        ),
      );
      expect(await rewards.watchItems().first, hasLength(7));
      await rewards.setNeedsOk(id: 'r-test', needsOk: false);
      final updated = (await rewards.watchItems().first).firstWhere(
        (r) => r.id == 'r-test',
      );
      expect(updated.needsOk, isFalse);
      await rewards.deleteReward('r-test');
      expect(await rewards.watchItems().first, hasLength(6));
    });
  });

  group('pip', () {
    test('care, wardrobe and look', () async {
      final repo = PipRepositoryImpl(db: db);
      var profile = await repo.watchProfile('maya').first;
      expect(profile?.coinsToGrow, 75);

      await repo.feed('maya');
      profile = await repo.watchProfile('maya').first;
      expect(profile?.coins, 115);
      expect(profile?.happiness, 5);

      await repo.buyItem('maya', 'wellies');
      profile = await repo.watchProfile('maya').first;
      expect(profile?.coins, 85);
      final items = await repo.watchItems().first;
      expect(items.firstWhere((i) => i.id == 'wellies').owned, isTrue);

      await repo.updateLook(childId: 'maya', skin: 'mint');
      profile = await repo.watchProfile('maya').first;
      expect(profile?.skin, 'mint');
    });
  });

  group('badges', () {
    test('shelf + happy days', () async {
      final repo = BadgesRepositoryImpl(db: db);
      final shelf = await repo.watchShelf('maya').first;
      expect(shelf, hasLength(8));
      expect(shelf.where((b) => b.earned), hasLength(4));
      expect(await repo.watchHappyDays('maya').first, 4);
    });
  });

  group('settings', () {
    test('toggles round-trip', () async {
      final repo = SettingsRepositoryImpl(db: db);
      var current = await repo.watchSettings().first;
      expect(current.payoutDay, 6);
      expect(current.crashReportConsent, isFalse);

      await repo.setNotifications(approvals: false);
      await repo.setPayoutDay(5);
      await repo.setCrashConsent(consent: true);
      current = await repo.watchSettings().first;
      expect(current.notifApprovals, isFalse);
      expect(current.payoutDay, 5);
      expect(current.crashReportConsent, isTrue);

      final rows = await repo.watchItems().first;
      expect(rows.firstWhere((r) => r.id == 'notif-approvals').detail, 'Off');
    });
  });

  group('parental gate', () {
    test('deterministic daily challenge', () async {
      final repo = ParentalGateRepositoryImpl(db: db);
      final challenge = repo.challengeFor(DateTime.utc(2026, 10, 3));
      expect(challenge.a, 3);
      expect(challenge.b, 9);
      expect(challenge.answer, 27);
      expect(challenge.verify(27), isTrue);
      expect(challenge.verify(26), isFalse);
      expect(await repo.watchGateEnabled().first, isTrue);

      await repo.setGateEnabled(enabled: false);
      expect(await repo.watchItems().first, isEmpty);
      await repo.setGateEnabled(enabled: true);
      expect(await repo.watchItems().first, hasLength(1));
    });
  });

  group('paywall', () {
    test('trial lifecycle', () async {
      final repo = PaywallRepositoryImpl(db: db);
      expect(await repo.getItems(), hasLength(1));
      expect((await repo.watchSubscription().first).status, 'active');
      await repo.startTrial();
      var status = await repo.watchSubscription().first;
      expect(status.status, 'trial');
      expect(status.trialStart, isNotNull);
      await repo.activate();
      status = await repo.watchSubscription().first;
      expect(status.status, 'active');
    });
  });

  group('privacy + onboarding + auth', () {
    test('crash consent is opt-in', () async {
      final repo = PrivacyConsentRepositoryImpl(db: db);
      expect(await repo.watchCrashConsent().first, isFalse);
      await repo.setCrashConsent(consent: true);
      expect(await repo.watchCrashConsent().first, isTrue);
    });

    test('onboarding completion', () async {
      final repo = OnboardingRepositoryImpl(db: db);
      expect(await repo.watchComplete().first, isTrue);
    });

    test('accounts mirror members', () async {
      final repo = AuthRepositoryImpl(db: db);
      final before = await repo.watchItems().first;
      expect(before.map((a) => a.name), contains('Sarah'));
      await repo.createAccount(name: 'Sarah');
      expect(await repo.watchItems().first, hasLength(before.length));
    });
  });
}
