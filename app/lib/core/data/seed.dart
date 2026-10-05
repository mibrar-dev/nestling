// Nestling — seed data for local-only development and screenshots.
//
// Six variants, selected with `--dart-define=SEED=…`:
// * `demo` — the exact spec family (DESIGN_SPEC §5). Every number visible in
//   the designs (P08, P10–P12, P14, K03, K08, K09, K11) is asserted in tests.
// * `empty` — onboarded parent, no children or quests (P08b legacy).
// * `new_family` — a family that has just finished onboarding (P08b): family
//   + parent Sarah + both children exactly as in `demo`, default settings,
//   NO quests/completions/ledger/goals/rewards/badges/wardrobe,
//   `onboarding_complete = true`, trial subscription starting now.
// * `fresh` — nothing at all: app_state only, onboarding incomplete.
// * `onboarding_kids` — P05 UI-check state: family + Sarah + Maya (7-9
//   lilac) + Leo (4-6 peach) exactly as in `demo`, no quests/ledger/etc.,
//   onboarding incomplete.
// * `kid_all_done` — K03b UI-check state: exactly `demo`, plus a
//   `done_pending` completion for each of Maya's quests that is not yet done
//   in the current period, so Maya reads "6 of 6 done" / "All done!". Leo
//   and every table except `quest_completions` are byte-identical to `demo`.
//
// Date anchor: the designs say "Sat 4 Oct", but 4 Oct 2026 is a Sunday, so
// the seed uses Sat 3 Oct 2026 (and Sat 26 Sep 2026 for "last Saturday") and
// every weekday label renders correctly via `family_time.dart`.

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/core/data/london_time.dart' as london;
import 'package:nestling/core/data/pin_hash.dart';

abstract final class Seed {
  static const String familyId = 'fam1';

  /// The demo story is written as if "today" were Sat 3 Oct 2026. Every seed
  /// date is shifted so that story day lands on [anchorDay] (default: today
  /// in Europe/London), so "done today" and "this week" stay meaningful on
  /// any date. Tests pin [anchorOverride] to 2026-10-03 for determinism.
  static DateTime? anchorOverride;

  static final DateTime _storyDay = DateTime.utc(2026, 10, 3);

  static DateTime get anchorDay {
    final override = anchorOverride;
    if (override != null) return override;
    final london = toFamilyZone(clock.now().toUtc(), defaultFamilyZoneId);
    return DateTime.utc(london.year, london.month, london.day);
  }

  static DateTime utc(int month, int day, int hour, [int minute = 0]) {
    final story = DateTime.utc(2026, month, day, hour, minute);
    return anchorDay.add(story.difference(_storyDay));
  }

  static Future<void> demo(AppDatabase db) async {
    await db.clearAll();
    await _family(db);
    await _members(db);
    await _childrenDemo(db);
    await _questsDemo(db);
    await _completionsDemo(db);
    await _ledgerDemo(db);
    await _goalsDemo(db);
    await _rewardsDemo(db);
    await _badgesDemo(db);
    await _wardrobeDemo(db);
    await _settingsDemo(db);
    await db
        .into(db.appState)
        .insert(
          AppStateCompanion.insert(
            id: const Value(1),
            onboardingComplete: const Value(true),
            subscriptionStatus: const Value('active'),
            trialStart: Value(utc(9, 19, 8)),
            trialStartTz: const Value(defaultFamilyZoneId),
            activeChildId: const Value('maya'),
            appMode: const Value('parent'),
          ),
        );
  }

  static Future<void> empty(AppDatabase db) async {
    await db.clearAll();
    await _family(db);
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'sarah',
            familyId: familyId,
            name: 'Sarah',
            email: const Value('sarah@example.co.uk'),
          ),
        );
    await _settingsForNewFamily(db);
    await db
        .into(db.appState)
        .insert(
          AppStateCompanion.insert(
            id: const Value(1),
            onboardingComplete: const Value(true),
            subscriptionStatus: const Value('trial'),
            trialStart: Value(clock.now().toUtc()),
            appMode: const Value('parent'),
          ),
        );
  }

  /// P08b state: a family that has just finished onboarding — family +
  /// parent Sarah (same as [empty]) + both children exactly as in [demo]
  /// (Maya then Leo, creation order) + default settings, and NOTHING else:
  /// no quests, completions, ledger, goals, rewards, badges or wardrobe.
  /// `onboarding_complete = true`, trial subscription starting now, parent
  /// app mode.
  static Future<void> newFamily(AppDatabase db) async {
    await db.clearAll();
    await _family(db);
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'sarah',
            familyId: familyId,
            name: 'Sarah',
            email: const Value('sarah@example.co.uk'),
          ),
        );
    await _childrenDemo(db);
    await _settingsForNewFamily(db);
    await db
        .into(db.appState)
        .insert(
          AppStateCompanion.insert(
            id: const Value(1),
            onboardingComplete: const Value(true),
            subscriptionStatus: const Value('trial'),
            trialStart: Value(clock.now().toUtc()),
            appMode: const Value('parent'),
          ),
        );
  }

  static Future<void> fresh(AppDatabase db) async {
    await db.clearAll();
    await db
        .into(db.appState)
        .insert(
          AppStateCompanion.insert(
            id: const Value(1),
            appMode: const Value('parent'),
          ),
        );
  }

  /// P05 UI-check state: the add-children step AFTER two children were
  /// added (Maya 7–9 lilac, Leo 4–6 peach, exactly as in [demo]) while
  /// onboarding is NOT complete. Family + parent Sarah + both children
  /// only — no quests, completions, ledger, goals, rewards, badges or
  /// wardrobe — plus default settings and `onboarding_complete = false`.
  static Future<void> onboardingKids(AppDatabase db) async {
    await db.clearAll();
    await _family(db);
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'sarah',
            familyId: familyId,
            name: 'Sarah',
            email: const Value('sarah@example.co.uk'),
          ),
        );
    await _childrenDemo(db);
    await _settingsForNewFamily(db);
    await db
        .into(db.appState)
        .insert(
          AppStateCompanion.insert(
            id: const Value(1),
            onboardingComplete: const Value(false),
            appMode: const Value('parent'),
          ),
        );
  }

  /// K03b state: Maya's kid home when EVERY one of her quests for the
  /// current period is done ("6 of 6 done", "All done!").
  ///
  /// Runs exactly [demo], then inserts a `done_pending` completion for each
  /// of Maya's quests with no done/approved completion in its current
  /// period ([london.countsForCurrentPeriod] — daily → current London day,
  /// weekly → current London week, the K03-BUG-4 ruling). The row is exactly
  /// what `KidHomeRepositoryImpl.completeQuest` writes for a kid tapping
  /// "done": status + coin snapshot + timestamps, NO ledger row and NO coin
  /// change (credits land only via the approvals `approve` path).
  ///
  /// Status follows the K03b HTML per-row labels ("Approved by Mum" →
  /// approved, "Done"/waiting → pending): the two quests still open in
  /// `demo` — `q-reading` and `q-tidy`, both labelled "Done" with a coin
  /// pill — become pending. Nothing is approved here, so no other table
  /// changes: Maya keeps her 120 coins / £4.20 owed, Leo and every other
  /// table stay byte-identical to `demo`.
  static Future<void> kidAllDone(AppDatabase db) async {
    await demo(db);
    // Story-anchored morning time (08:30 UTC = 09:30 London on the anchor
    // day): inside the current London day like the pinned test clock, and
    // after every `demo` completion, so the new rows are the latest in
    // their period. Deterministic under test; "today" in production.
    final now = utc(10, 3, 8, 30);
    final quests = await (db.select(
      db.quests,
    )..where((q) => q.assigneeChildId.equals('maya'))).get();
    for (final quest in quests) {
      final rows =
          await (db.select(db.questCompletions)..where(
                (c) => c.questId.equals(quest.id) & c.childId.equals('maya'),
              ))
              .get();
      final done = rows.any(
        (c) =>
            (c.status == 'done_pending' || c.status == 'approved') &&
            london.countsForCurrentPeriod(quest.repeatRule, c.createdAt, now),
      );
      if (done) continue;
      await db
          .into(db.questCompletions)
          .insert(
            QuestCompletionsCompanion.insert(
              questId: quest.id,
              childId: 'maya',
              familyId: familyId,
              status: const Value('done_pending'),
              coins: Value(quest.coins),
              createdAt: Value(now),
              createdAtTz: const Value(defaultFamilyZoneId),
            ),
          );
    }
  }

  // -- shared -------------------------------------------------------------

  static Future<void> _family(AppDatabase db) async {
    await db
        .into(db.families)
        .insert(
          FamiliesCompanion.insert(
            id: familyId,
            name: const Value('Nestling'),
            payoutDay: const Value(6),
            coinValuePencePerCoin: const Value(1),
            pocketMoneyMode: const Value('both'),
            timeZone: const Value(defaultFamilyZoneId),
          ),
        );
  }

  /// Test/move fixture: switches the seeded family to Asia/Dubai WITHOUT
  /// rewriting any stored instant or `…_tz` column — exactly what
  /// `FamilyZoneService.confirmPendingMove` does. History keeps rendering in
  /// its stored London zone; future periods follow Dubai.
  static Future<void> movedToDubai(AppDatabase db) async {
    await (db.update(db.families)..where((f) => f.id.equals(familyId))).write(
      const FamiliesCompanion(timeZone: Value('Asia/Dubai')),
    );
    await (db.update(db.settings)..where((s) => s.familyId.equals(familyId)))
        .write(const SettingsCompanion(timeZone: Value('Asia/Dubai')));
  }

  static Future<void> _members(AppDatabase db) async {
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'sarah',
            familyId: familyId,
            name: 'Sarah',
            email: const Value('sarah@example.co.uk'),
          ),
        );
    await db
        .into(db.members)
        .insert(
          MembersCompanion.insert(
            id: 'james',
            familyId: familyId,
            name: 'James',
            role: const Value('co-parent'),
            inviteStatus: const Value('invited'),
            // No email: the P16 design shows "Invited · awaiting reply",
            // not an address, for the co-parent row (absent == NULL).
          ),
        );
  }

  static Future<void> _childrenDemo(AppDatabase db) async {
    await db
        .into(db.children)
        .insert(
          ChildrenCompanion.insert(
            id: 'maya',
            familyId: familyId,
            nickname: 'Maya',
            ageBand: const Value('7-9'),
            ageYears: const Value(9),
            avatarColour: const Value('lilac'),
            pinHash: Value(hashPin('1234')),
            pipStyle: const Value('mochi'),
            pipSkin: const Value('sunny'),
            pipAccessory: const Value('none'),
            pipStage: const Value(3),
            pipTotalCoins: const Value(175),
            coins: const Value(120),
            happiness: const Value(4),
            happyDays: const Value(4),
            weeklyBasePence: const Value(300),
            // Creation order is the roster order (CHILD ORDER ruling):
            // Maya is added before Leo.
            createdAt: Value(utc(9, 19, 8)),
            createdAtTz: const Value(defaultFamilyZoneId),
          ),
        );
    await db
        .into(db.children)
        .insert(
          ChildrenCompanion.insert(
            id: 'leo',
            familyId: familyId,
            nickname: 'Leo',
            ageBand: const Value('4-6'),
            ageYears: const Value(6),
            avatarColour: const Value('peach'),
            pipStyle: const Value('bolt'),
            pipSkin: const Value('sky'),
            pipAccessory: const Value('none'),
            pipStage: const Value(2),
            pipTotalCoins: const Value(60),
            coins: const Value(45),
            happiness: const Value(4),
            happyDays: const Value(3),
            weeklyBasePence: const Value(150),
            // Added after Maya (see above): creation order, not name order.
            createdAt: Value(utc(9, 19, 8).add(const Duration(minutes: 1))),
            createdAtTz: const Value(defaultFamilyZoneId),
          ),
        );
  }

  static Future<void> _questsDemo(AppDatabase db) async {
    // Creation order is the Active-list order (orchestrator ruling for P10
    // §5): each quest is stamped one second after the previous, so
    // `watchActiveQuests` (created_at, then id) renders the seed in the
    // order below — never alphabetical.
    var order = 0;
    Future<void> quest(
      String id,
      String title,
      String icon,
      int coins,
      String? assignee, [
      String repeat = 'daily',
    ]) {
      return db
          .into(db.quests)
          .insert(
            QuestsCompanion.insert(
              id: id,
              familyId: familyId,
              title: title,
              icon: Value(icon),
              coins: Value(coins),
              repeatRule: Value(repeat),
              assigneeChildId: assignee == null
                  ? const Value.absent()
                  : Value(assignee),
              createdAt: Value(utc(9, 19, 8).add(Duration(seconds: order++))),
              createdAtTz: const Value(defaultFamilyZoneId),
            ),
          );
    }

    // Maya — 6 active ("4 of 6" on P08).
    await quest(
      'q-dishwasher',
      'Empty the dishwasher',
      'dishwasher',
      15,
      'maya',
    );
    await quest('q-reading', 'Reading – 20 minutes', 'book', 10, 'maya');
    await quest('q-bins', 'Put the bins out', 'bins', 15, 'maya', 'weekly');
    await quest('q-tidy', 'Tidy your bedroom', 'bed', 15, 'maya');
    await quest(
      'q-hoover',
      'Hoover the stairs',
      'hoover',
      20,
      'maya',
      'weekly',
    );
    await quest('q-table', 'Lay the table', 'plate', 10, 'maya');
    // Leo — 4 active ("2 of 4" on P08).
    await quest('q-bed', 'Make your bed', 'bed', 5, 'leo');
    await quest('q-biscuit', 'Feed Biscuit the cat', 'paw', 5, 'leo');
    await quest('q-bag', 'Pack school bag', 'bag', 5, 'leo');
    await quest('q-plants', 'Water the plants', 'leaf', 10, 'leo');
    // Anyone — 2 active (P10 "Active (12)": 6 + 4 + 2).
    await quest('q-washing', 'Help with the washing', 'shirt', 15, null);
    await quest('q-living', 'Tidy the living room', 'sofa', 10, null);
  }

  static Future<void> _completionsDemo(AppDatabase db) async {
    Future<void> completion(
      String quest,
      String child,
      String status,
      int coins,
      DateTime created, [
      DateTime? decided,
      String? kidNote,
    ]) {
      return db
          .into(db.questCompletions)
          .insert(
            QuestCompletionsCompanion.insert(
              questId: quest,
              childId: child,
              familyId: familyId,
              status: Value(status),
              coins: Value(coins),
              createdAt: Value(created),
              createdAtTz: const Value(defaultFamilyZoneId),
              decidedAt: decided == null
                  ? const Value.absent()
                  : Value(decided),
              decidedAtTz: const Value(defaultFamilyZoneId),
              kidNote: kidNote == null ? const Value.absent() : Value(kidNote),
            ),
          );
    }

    // 3 awaiting approval (P11 "Waiting for you (3)"). The child's note
    // (`kid_note`) is stored WITHOUT the surrounding “ ” — P11 adds them
    // at render time. q-table has no note (NULL → no quote line).
    await completion(
      'q-dishwasher',
      'maya',
      'done_pending',
      15,
      utc(10, 3, 7, 12),
      null,
      'I stacked everything neatly!',
    );
    await completion('q-table', 'maya', 'done_pending', 10, utc(10, 3, 7, 5));
    await completion(
      'q-bed',
      'leo',
      'done_pending',
      5,
      utc(10, 3, 6, 58),
      null,
      'I did the pillows too.',
    );
    // Approved this week (drive P08 progress + ledger).
    await completion(
      'q-bins',
      'maya',
      'approved',
      15,
      utc(10, 2, 16, 40),
      utc(10, 2, 19, 2),
    );
    await completion(
      'q-hoover',
      'maya',
      'approved',
      20,
      utc(10, 1, 16, 20),
      utc(10, 1, 18, 45),
    );
    await completion(
      'q-bag',
      'leo',
      'approved',
      5,
      // Daily quest: approved this morning so it counts as done today
      // (P08 "Leo 2 of 4" under the London-day period rule).
      utc(10, 3, 6, 30),
      utc(10, 3, 7, 15),
    );
    // Still to do.
    for (final q in <List<String>>[
      ['q-reading', 'maya', '10'],
      ['q-tidy', 'maya', '15'],
      ['q-biscuit', 'leo', '5'],
      ['q-plants', 'leo', '10'],
      ['q-washing', 'maya', '15'],
      ['q-living', 'leo', '10'],
    ]) {
      await completion(q[0], q[1], 'to_do', int.parse(q[2]), utc(10, 3, 6));
    }
  }

  static Future<void> _ledgerDemo(AppDatabase db) async {
    Future<void> entry(
      String child,
      String type,
      int pence,
      String note,
      DateTime date,
    ) {
      return db
          .into(db.ledgerEntries)
          .insert(
            LedgerEntriesCompanion.insert(
              familyId: familyId,
              childId: child,
              type: type,
              amountPence: pence,
              note: Value(note),
              date: Value(date),
              dateTz: const Value(defaultFamilyZoneId),
            ),
          );
    }

    // Previous week, settled by the 26 Sep payout.
    await entry(
      'maya',
      'weekly_base',
      300,
      'Weekly pocket money',
      utc(9, 20, 8),
    );
    await entry('maya', 'quest_bonus', 12, 'Put the bins out', utc(9, 21, 17));
    await entry('maya', 'quest_bonus', 68, 'Hoover the stairs', utc(9, 25, 17));
    await entry('maya', 'payout', -380, 'Paid · Sat 26 Sep', utc(9, 26, 9));
    await entry(
      'leo',
      'weekly_base',
      150,
      'Weekly pocket money',
      utc(9, 20, 8),
    );
    await entry('leo', 'quest_bonus', 40, 'Pack school bag', utc(9, 24, 8));
    await entry('leo', 'payout', -190, 'Paid · Sat 26 Sep', utc(9, 26, 9));
    // This week: Maya is owed £4.20 = £3.00 base + £1.20 quests (P12).
    await entry(
      'maya',
      'weekly_base',
      300,
      'Weekly pocket money',
      utc(10, 3, 8),
    );
    await entry('maya', 'quest_bonus', 12, 'Put the bins out', utc(10, 2, 19));
    await entry('maya', 'quest_bonus', 40, 'Hoover the stairs', utc(10, 1, 18));
    await entry(
      'maya',
      'quest_bonus',
      40,
      'Help with the washing',
      utc(9, 30, 17),
    );
    await entry('maya', 'quest_bonus', 28, 'Tidy your bedroom', utc(9, 29, 17));
    await entry(
      'maya',
      'gift',
      1000,
      'Birthday money (added by Mum)',
      utc(9, 28, 10),
    );
    await entry('maya', 'spend', -200, 'Comic', utc(9, 30, 15));
    await entry(
      'maya',
      'savings_move',
      1000,
      'Birthday money → Lego fund',
      utc(9, 28, 10, 30),
    );
    await entry('maya', 'savings_move', 550, 'Jar → Lego fund', utc(9, 30, 16));
    // Leo is owed £2.10 = £1.50 base + £0.60 quests (P13).
    await entry(
      'leo',
      'weekly_base',
      150,
      'Weekly pocket money',
      utc(10, 3, 8),
    );
    await entry('leo', 'quest_bonus', 35, 'Pack school bag', utc(10, 2, 8));
    await entry('leo', 'quest_bonus', 25, 'Make your bed', utc(9, 30, 8));
  }

  static Future<void> _goalsDemo(AppDatabase db) async {
    await db
        .into(db.savingsGoals)
        .insert(
          SavingsGoalsCompanion.insert(
            id: 'goal-lego',
            familyId: familyId,
            childId: 'maya',
            title: 'Lego Friends set',
            targetPence: 2499,
            savedPence: const Value(1550),
          ),
        );
  }

  static Future<void> _rewardsDemo(AppDatabase db) async {
    // Creation order is the P14 list order (owner rule "listed in the order
    // they were added"): each reward is stamped one second after the
    // previous, so `watchRewardsInCreationOrder` (created_at, then id)
    // renders the seed in the order below. "Baking together" needs no
    // parental OK — the P14 design (light + dark) shows its "Needs my OK"
    // toggle OFF while every other visible reward is ON.
    var order = 0;
    Future<void> reward(
      String id,
      String title,
      String icon,
      int price, {
      bool needsOk = true,
    }) {
      return db
          .into(db.rewards)
          .insert(
            RewardsCompanion.insert(
              id: id,
              familyId: familyId,
              title: title,
              icon: Value(icon),
              coinPrice: price,
              needsOk: Value(needsOk),
              createdAt: Value(utc(9, 19, 8).add(Duration(seconds: order++))),
              createdAtTz: const Value(defaultFamilyZoneId),
            ),
          );
    }

    await reward('r-screen', '30 min extra screen time', 'tv', 50);
    await reward('r-film', 'Pick Friday film', 'film', 80);
    await reward('r-bedtime', 'Stay up 15 min later', 'moon', 60);
    await reward('r-baking', 'Baking together', 'cake', 100, needsOk: false);
    await reward('r-cafe', 'Trip to the park café', 'coffee', 150);
    await reward('r-dinner', 'Choose dinner', 'plate', 90);
  }

  static Future<void> _badgesDemo(AppDatabase db) async {
    Future<void> badge(String id, {required String title}) {
      return db
          .into(db.badges)
          .insert(BadgesCompanion.insert(id: id, title: title));
    }

    await badge('first-quest', title: 'First quest');
    await badge('bed-maker-7', title: 'Bed maker ×7');
    await badge('kind-helper', title: 'Kind helper');
    await badge('bookworm', title: 'Bookworm');
    await badge('bins-out', title: 'Bins out');
    await badge('biscuit-sitter', title: 'Biscuit sitter');
    await badge('tidy-hero', title: 'Tidy hero');
    await badge('early-bird', title: 'Early bird');
    await badge('plant-waterer', title: 'Plant waterer');

    Future<void> earned(String badge, String child, DateTime at) {
      return db
          .into(db.earnedBadges)
          .insert(
            EarnedBadgesCompanion.insert(
              badgeId: badge,
              childId: child,
              familyId: familyId,
              earnedAt: Value(at),
              earnedAtTz: const Value(defaultFamilyZoneId),
            ),
          );
    }

    await earned('first-quest', 'maya', utc(9, 21, 10));
    await earned('bed-maker-7', 'maya', utc(9, 28, 10));
    await earned('kind-helper', 'maya', utc(9, 29, 10));
    await earned('bookworm', 'maya', utc(10, 1, 10));
    await earned('first-quest', 'leo', utc(9, 24, 10));
  }

  static Future<void> _wardrobeDemo(AppDatabase db) async {
    Future<void> item(
      String child,
      String item, {
      required bool owned,
      required int price,
    }) {
      return db
          .into(db.pipWardrobe)
          .insert(
            PipWardrobeCompanion.insert(
              childId: child,
              item: item,
              owned: Value(owned),
              priceCoins: Value(price),
            ),
          );
    }

    await item('maya', 'scarf', owned: true, price: 0);
    await item('maya', 'sunhat', owned: true, price: 0);
    await item('maya', 'wellies', owned: false, price: 30);
    await item('maya', 'crown', owned: false, price: 60);
    await item('leo', 'sunhat', owned: true, price: 0);
    await item('leo', 'scarf', owned: false, price: 30);
    await item('leo', 'wellies', owned: false, price: 30);
    await item('leo', 'crown', owned: false, price: 60);
  }

  static Future<void> _settingsDemo(AppDatabase db) async {
    // Demo-exact (P16 design shows all three toggles checked): written
    // explicitly so the OFF table default for new families can never drift
    // the spec screenshots.
    await db
        .into(db.settings)
        .insert(
          SettingsCompanion.insert(
            familyId: familyId,
            notifApprovals: const Value(true),
            notifPayout: const Value(true),
            notifSummary: const Value(true),
          ),
        );
  }

  /// Default settings for a new family (OFF notifications — nudge rule).
  /// Used by every seed except [demo], which keeps the design's checked
  /// toggles via [_settingsDemo]. Written explicitly, because the DDL
  /// default only applies to databases created after the change.
  static Future<void> _settingsForNewFamily(AppDatabase db) async {
    await db
        .into(db.settings)
        .insert(
          SettingsCompanion.insert(
            familyId: familyId,
            notifApprovals: const Value(false),
            notifPayout: const Value(false),
            notifSummary: const Value(false),
          ),
        );
  }
}
