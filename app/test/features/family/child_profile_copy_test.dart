// P15 · Child profile — the copy and count branches the demo family never
// reaches.
//
// `child_profile_view_test.dart` pins the strings the seeded demo renders
// (Maya: PIN on, no one-off quests, 175/250 coins). The functions in
// `child_profile_copy.dart` have four more branches — a child with no PIN, a
// family WITH one-off quests, a full Pip bar, a stage-1 Pip — and
// `FamilyRepositoryImpl._toProfile` has three more (`once` quests, unknown
// repeat rules, other children's quests). They are pure functions over real
// data, so they are tested directly here, character by character, against the
// design's HTML source (`design/html-source/screens/P15-child-profile.html`).
//
// Typographic characters under test: U+2013 EN DASH (age band), U+00B7 MIDDLE
// DOT (clause separator), U+203A SINGLE RIGHT-POINTING ANGLE QUOTATION MARK
// (`Change ›`), U+00A3 POUND SIGN (money).

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart' hide Quest;
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/family/data/family_repository_impl.dart';
import 'package:nestling/features/family/domain/entities/family_child.dart';
import 'package:nestling/features/family/presentation/widgets/child_profile_copy.dart';

const String _dash = '\u2013'; // –
const String _dot = '\u00B7'; // ·
const String _chevron = '\u203A'; // ›
const String _pound = '\u00A3'; // £

/// A 13+ child at the last Pip stage — every branch the demo seed misses:
/// no PIN, a band with no hyphen, stage 4, a full bar, a Pukka accessory.
const _songbird = FamilyChild(
  id: 'kit',
  nickname: 'Kit',
  ageBand: '13+',
  ageYears: 13,
  avatarColour: 'sky',
  pinSet: false,
  pipStyle: 'storybook',
  pipSkin: 'berry',
  pipAccessory: 'glasses',
  pipStage: 4,
  pipTotalCoins: 260,
  coins: 0,
  happiness: 0,
  happyDays: 0,
  weeklyBasePence: 0,
  activeQuests: 0,
  doneQuests: 0,
);

/// The same child at the FIRST stage — what `addChild` gives a brand-new
/// child (`family_repository_impl.dart:_toChild`, `pipStage: 1`).
const _egg = FamilyChild(
  id: 'new',
  nickname: 'Robin',
  ageBand: '7-9',
  ageYears: 7,
  avatarColour: 'leaf',
  pinSet: false,
  pipStyle: 'mochi',
  pipSkin: 'sunny',
  pipAccessory: 'none',
  pipStage: 1,
  pipTotalCoins: 0,
  coins: 0,
  happiness: 0,
  happyDays: 0,
  weeklyBasePence: 0,
  activeQuests: 0,
  doneQuests: 0,
);

void main() {
  group('P15 stage names', () {
    test('they are the design four, shared with P08 and K03', () {
      expect(pipStageName(1), 'Egg');
      expect(pipStageName(2), 'Hatchling');
      expect(pipStageName(3), 'Fledgling');
      expect(pipStageName(4), 'Songbird');
    });
  });

  group('P15 age line', () {
    test('a band with no hyphen is left alone', () {
      expect(profileAgeLine(_songbird), 'Age 13+ $_dot Pip is a Songbird');
    });

    test('the DB hyphen becomes an EN DASH (U+2013), never ASCII -', () {
      final line = profileAgeLine(_egg);
      expect(line, startsWith('Age 7${_dash}9 $_dot '));
      expect(line, isNot(contains('7-9')));
      expect(line, contains(_dash));
      expect(line, contains(_dot));
    });

    test('the band, the middot and the stage name are all present', () {
      expect(profileAgeLine(_songbird), 'Age 13+ $_dot Pip is a Songbird');
      expect(
        profileAgeLine(
          const FamilyChild(
            id: 'h',
            nickname: 'H',
            ageBand: '4-6',
            ageYears: 4,
            avatarColour: 'sky',
            pinSet: false,
            pipStyle: 'bolt',
            pipSkin: 'sky',
            pipAccessory: 'none',
            pipStage: 2,
            pipTotalCoins: 10,
            coins: 0,
            happiness: 0,
            happyDays: 0,
            weeklyBasePence: 0,
            activeQuests: 0,
            doneQuests: 0,
          ),
        ),
        'Age 4${_dash}6 $_dot Pip is a Hatchling',
      );
    });

    // ── BUG P15-BUG-4 (failing repro — do not "fix" the test) ──────────────
    // `profileAgeLine` hard-codes the article: `'Pip is a ${pipStageName(…)}'`
    // (`child_profile_copy.dart:48-50`), so a stage-1 child — which is what
    // EVERY child added through P05 is, since `children.pipStage` defaults to
    // 1 (`app_database.dart:82` and `addChild` never overrides it) — reads
    // "Pip is a Egg". The same file already knows the rule for the spoken
    // label (`pipStagePhrase` → "an egg", `child_profile_copy.dart:119-124`),
    // and the design's own alt text is "Pip the fledgling"; the visible line
    // simply never had a stage-1 case to render.
    test('BUG P15-BUG-4: a stage-1 Pip reads "an Egg"', () {
      expect(profileAgeLine(_egg), 'Age 7${_dash}9 $_dot Pip is an Egg');
    });
  });

  group('P15 Pip card copy', () {
    test('the heading mirrors the stage', () {
      expect(profilePipTitle(_songbird), 'Pip $_dot Songbird');
      expect(profilePipTitle(_egg), 'Pip $_dot Egg');
    });

    test(
      'the growth caption rounds the same fraction the bar is drawn from',
      () {
        expect(profileGrowthCaption(175, 250), '175 of 250 $_dot 70%');
        expect(profileGrowthCaption(125, 250), '125 of 250 $_dot 50%');
        // `.round()`, not floor: 249/250 is 99.6 % → 100 %.
        expect(profileGrowthCaption(249, 250), '249 of 250 $_dot 100%');
        expect(profileGrowthCaption(0, 250), '0 of 250 $_dot 0%');
      },
    );

    test('a full or over-full Pip bar is clamped, never above 100 %', () {
      expect(pipGrowthFraction(250, 250), 1.0);
      expect(pipGrowthFraction(999, 250), 1.0);
      expect(pipGrowthFraction(0, 250), 0.0);
      expect(profileGrowthCaption(999, 250), '999 of 250 $_dot 100%');
      // A defensive division by zero must not produce NaN.
      expect(pipGrowthFraction(10, 0), 0.0);
    });

    test('the accessibility label takes "an" for stage 1', () {
      expect(profilePipSemanticLabel(_songbird), "Kit's Pip, a songbird");
      expect(profilePipSemanticLabel(_egg), "Robin's Pip, an egg");
      expect(pipStagePhrase(1), 'an egg');
      expect(pipStagePhrase(2), 'a hatchling');
      expect(pipStagePhrase(3), 'a fledgling');
      expect(pipStagePhrase(4), 'a songbird');
    });

    test('the evolve caption names the threshold', () {
      expect(profileEvolvesCaption(250), 'Evolves at 250 total coins');
    });
  });

  group('P15 list-row copy', () {
    test('a child with no PIN reads Off', () {
      expect(profilePinSubtitle(_songbird), 'Off $_dot No code set yet');
    });

    test('a child with a PIN names them and their code', () {
      expect(
        profilePinSubtitle(
          const FamilyChild(
            id: 'kit',
            nickname: 'Kit',
            ageBand: '13+',
            ageYears: 13,
            avatarColour: 'sky',
            pinSet: true,
            pipStyle: 'storybook',
            pipSkin: 'berry',
            pipAccessory: 'glasses',
            pipStage: 4,
            pipTotalCoins: 260,
            coins: 0,
            happiness: 0,
            happyDays: 0,
            weeklyBasePence: 0,
            activeQuests: 0,
            doneQuests: 0,
          ),
        ),
        'On $_dot Kit knows their code',
      );
    });

    test('one-off quests are named only when there are any', () {
      expect(
        profileQuestsSubtitle(daily: 4, weekly: 2, once: 0),
        '6 active $_dot 4 daily, 2 weekly',
        reason: 'the design two-clause shape',
      );
      expect(
        profileQuestsSubtitle(daily: 4, weekly: 2, once: 3),
        '9 active $_dot 4 daily, 2 weekly $_dot 3 one-off',
      );
      expect(
        profileQuestsSubtitle(daily: 0, weekly: 0, once: 0),
        '0 active $_dot 0 daily, 0 weekly',
      );
    });

    test('pocket money always shows two decimals and the owed balance', () {
      expect(
        profileMoneySubtitle(300, 420),
        '$_pound'
        '3.00 a week $_dot Owed $_pound'
        '4.20',
      );
      expect(
        profileMoneySubtitle(0, 0),
        '$_pound'
        '0.00 a week $_dot Owed $_pound'
        '0.00',
      );
      expect(
        profileMoneySubtitle(155, 5),
        '$_pound'
        '1.55 a week $_dot Owed $_pound'
        '0.05',
      );
    });

    // Iteration 3 swapped the cross-feature `moneyPounds` import for the
    // design-system barrel's `formatPounds` (the per-feature boundary in
    // `ARCHITECTURE.md:75`). The rendered copy must stay byte-identical, and
    // the pence → pounds division must never leak float noise (`29.99`, never
    // `29.98999…`).
    test("the formatPounds swap keeps the ledger's exact rendering", () {
      const pound = '\u00A3';
      String row(int weekly, int owed) => profileMoneySubtitle(weekly, owed);

      expect(row(2999, 1234), '${pound}29.99 a week $_dot Owed ${pound}12.34');
      expect(row(1, 1), '${pound}0.01 a week $_dot Owed ${pound}0.01');
      expect(row(9, 99), '${pound}0.09 a week $_dot Owed ${pound}0.99');
      expect(row(999, 999), '${pound}9.99 a week $_dot Owed ${pound}9.99');
      expect(
        row(100000, 250000),
        '${pound}1000.00 a week $_dot Owed ${pound}2500.00',
      );
      // Sign-free, exactly like the ledger's `moneyPounds`: a negative
      // balance (a refund row) reads as a plain amount, never `-£`.
      expect(
        row(-500, -50),
        '${pound}5.00 a week $_dot Owed ${pound}0.50',
        reason: 'the ledger renders magnitudes',
      );
      for (final pence in <int>[0, 7, 70, 105, 1010, 2999, 12345, 99999]) {
        expect(row(pence, pence), matches(RegExp(r'^£\d+\.\d{2} a week')));
      }
    });

    test('the trailing chevron is U+203A, not U+00BB', () {
      expect(profilePinTrailing(), 'Change $_chevron');
      expect(profilePinTrailing(), isNot(contains('\u00BB')));
      expect(kProfileChevron, _chevron);
      expect(kProfileDot, _dot);
    });
  });

  group('P15 remove copy', () {
    test('title, label and body interpolate the nickname', () {
      expect(profileRemoveLabel(_songbird.nickname), 'Remove Kit from family');
      expect(profileRemoveTitle(_songbird.nickname), 'Remove Kit?');
      expect(
        profileRemoveBody,
        'They will lose their quests, coins and Pip. This cannot be undone.',
      );
    });
  });

  group('P15 quest counting against the real database', () {
    Future<AppDatabase> dbWithQuest(
      String repeatRule, {
      String? forChild,
    }) async {
      final db = AppDatabase.memory();
      await Seed.demo(db);
      await db
          .into(db.quests)
          .insert(
            QuestsCompanion.insert(
              id: 'probe-quest',
              familyId: Seed.familyId,
              title: 'Probe quest',
              repeatRule: Value(repeatRule),
              assigneeChildId: Value(forChild ?? 'maya'),
            ),
          );
      return db;
    }

    test('a `once` quest lands in the one-off bucket', () async {
      final db = await dbWithQuest('once');
      final profile = await FamilyRepositoryImpl(db: db).watchProfile().first;

      // Demo Maya: 4 daily + 2 weekly, plus this one.
      expect(profile!.dailyActive, 4);
      expect(profile.weeklyActive, 2);
      expect(profile.onceActive, 1);
      expect(
        profileQuestsSubtitle(
          daily: profile.dailyActive,
          weekly: profile.weeklyActive,
          once: profile.onceActive,
        ),
        '7 active $_dot 4 daily, 2 weekly $_dot 1 one-off',
      );
    });

    test('an unknown repeat rule is counted as one-off, not dropped', () async {
      final db = await dbWithQuest('fortnightly');
      final profile = await FamilyRepositoryImpl(db: db).watchProfile().first;
      expect(profile!.onceActive, 1);
    });

    test("another child's quest is not counted", () async {
      final db = await dbWithQuest('daily', forChild: 'leo');
      final profile = await FamilyRepositoryImpl(db: db).watchProfile().first;
      expect(profile!.child.id, 'maya');
      expect(profile.dailyActive, 4, reason: "Leo's quest is not Maya's");
    });

    test('an inactive quest is not counted', () async {
      final db = await dbWithQuest('daily');
      await (db.update(db.quests)..where((q) => q.id.equals('probe-quest')))
          .write(const QuestsCompanion(active: Value(false)));
      final profile = await FamilyRepositoryImpl(db: db).watchProfile().first;
      expect(
        profile!.dailyActive + profile.weeklyActive + profile.onceActive,
        6,
        reason: 'the demo roster, unchanged',
      );
    });
  });
}
