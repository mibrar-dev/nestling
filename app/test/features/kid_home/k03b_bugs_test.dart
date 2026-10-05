// K03b — adversarial bug hunt (stage 6, iteration 1).
//
// Two kinds of proof live here:
//
//  * PARKED PROOFS of open bugs — marked `skip: '<bug id>'` so the suite stays
//    green. Run one with:
//      flutter test --run-skipped --plain-name K03B-BUG-1
//  * CLEAN PROBES that pass and stay in the plain run as evidence for the
//    "checked, clean" categories (edge data, taps, deep links, restart,
//    dark contrast, overflow, BST, integer coins, a11y actions).
//
// Geometry proofs run at the design's real font metrics (`loadBundledFonts`,
// same isolation as `kid_home_geometry_test.dart`); the design rows come from
// `design/screens/light/K03b-kid-home-done.png` ÷3, measured with PIL:
//   bubble 125…191 (2 lines), pet box top 221 (bubble + 16 + 14),
//   chip 464…496 (centre 480), progress 513…529, card 1 top 545,
//   confetti plate 320×250 at stage top + 4 (pet top − 10),
//   nest art 226×226 → outline 190×104, rim 310, bowl bottom 414,
//   Pip centre y 280 (box −16…134 from the pet top).
// Everything is measured against `SEED=kid_all_done` (Maya 6/6).
//
// The file-level setUp opens the in-memory DB (NOT inside a testWidgets body:
// `setUpTestScope` in the body binds the Drift executor to the fake-async
// zone and the first `tester.runAsync` DB call then never completes).

import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show BooleanExpressionOperators, Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/london_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipMood;
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/data/kid_home_repository_impl.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_home_data.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_state.dart';
import 'package:nestling/features/kid_home/presentation/widgets/kid_status_chip.dart';

import '../../test_scope.dart';

// ---------------------------------------------------------------------------
// Design rows (light PNG ÷3)
// ---------------------------------------------------------------------------

const double _dPetTop = 221;
const double _dChipCenter = 480;
const double _dProgressTop = 513;
const double _dCard1Top = 545;
const double _dPetBlockHeight = 226;
const double _dNestWidth = 226;
const double _dRimTop = 310.4;
const double _dBowlBottom = 413.9;
const double _dPipCenterY = 280.3;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Loads the bundled faces so the metrics match a device run.
Future<void> _loadBundledFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
  await inter.load();
  await nunito.load();
}

Future<void> _pump(
  WidgetTester tester, {
  String route = '/kid-home-done',
  bool kidMode = true,
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  if (kidMode) {
    GetIt.instance<AppModeController>().selectMode(AppMode.kid);
  }
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// `SEED=kid_all_done` for the in-memory DB (Maya 6/6 for the current period).
Future<void> _seedAllDone(WidgetTester tester) async {
  await tester.runAsync(() => Seed.kidAllDone(GetIt.instance<AppDatabase>()));
}

List<KidQuest> _items(List<String> statuses) => <KidQuest>[
  for (var i = 0; i < statuses.length; i++)
    KidQuest(
      id: 'q$i:maya',
      title: 'Quest $i',
      detail: '',
      questId: 'q$i',
      icon: 'book',
      coins: 10,
      status: statuses[i],
    ),
];

double _linear(double channel) => channel <= 0.03928
    ? channel / 12.92
    : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _linear(c.r) + 0.7152 * _linear(c.g) + 0.0722 * _linear(c.b);

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  setUpAll(_loadBundledFonts);
  setUp(() async {
    await setUpTestScope();
  });

  // =========================================================================
  // PARKED GEOMETRY PROOFS (open bugs, see docs/screens/K03b/6_bugs.md)
  // =========================================================================

  testWidgets('K03B-BUG-1: the bubble→pet gap is the design 30 px, not 14', (
    tester,
  ) async {
    await _seedAllDone(tester);
    await _pump(tester);
    final bubble = tester.getRect(find.byType(NestSpeechBubble));
    final pet = tester.getRect(find.byType(NestPetStage));
    // `.scroll > * + *` (16) + `.k3-pet { margin: 14px auto 0 }` (14).
    expect(
      pet.top - bubble.bottom,
      closeTo(30, 2),
      reason:
          'design: stage margin 16 + pet margin 14 = 30; the app uses a '
          'single 14 px SizedBox, so the hero sits 16 px high',
    );
    await disposeApp(tester);
  }, skip: true);

  testWidgets('K03B-BUG-1: every row below the hero is on the design row', (
    tester,
  ) async {
    await _seedAllDone(tester);
    await _pump(tester);
    final pet = tester.getRect(find.byType(NestPetStage));
    final chip = tester.getRect(find.byType(KidStatusChip).first);
    final progress = tester.getRect(find.byType(NestProgress));
    final card1 = tester.getRect(find.byType(NestKidQuestCard).first);
    expect(pet.top, closeTo(_dPetTop, 2), reason: '.k3-pet box top');
    expect(chip.center.dy, closeTo(_dChipCenter, 2), reason: 'chip centre');
    expect(progress.top, closeTo(_dProgressTop, 2), reason: 'progress top');
    expect(card1.top, closeTo(_dCard1Top, 2), reason: 'card 1 top');
    await disposeApp(tester);
  }, skip: true);

  testWidgets('K03B-BUG-2: the slotHeight pet block is the design 226 px', (
    tester,
  ) async {
    // Unit form first: `slotHeight` is documented as the block height.
    final g = PipNestFallback.explicitGeometry(
      nestH: 188,
      pipH: 152,
      contactFrac: PipNestFallback.contactInSvg(PipStage.fledgling),
      slotHeight: _dPetBlockHeight,
    );
    expect(g.stageH, _dPetBlockHeight);
    // Widget form: the composed stage must be the same block.
    await _seedAllDone(tester);
    await _pump(tester);
    expect(
      tester.getSize(find.byType(PipNestFallback)).height,
      closeTo(_dPetBlockHeight, 0.5),
    );
    await disposeApp(tester);
  }, skip: true);

  testWidgets(
    'K03B-BUG-3: the nest art is the design 226×226 (outline 190×104)',
    (tester) async {
      await _seedAllDone(tester);
      await _pump(tester);
      final nest = tester.getRect(
        find
            .descendant(
              of: find.byType(PipNestFallback),
              matching: find.byWidgetPredicate(
                (w) => w is SvgPicture && (w.width ?? 0) > 150,
              ),
            )
            .first,
      );
      expect(nest.width, closeTo(_dNestWidth, 2), reason: 'nest art width');
      expect(
        nest.width * PipNestFallback.visibleNestRatio,
        closeTo(190.2, 2),
        reason: 'design bowl outline 202/240 × 226 = 190.2',
      );
      expect(
        nest.top + PipNestFallback.nestRimTopFraction * nest.height,
        closeTo(_dRimTop, 2),
        reason: 'design rim row',
      );
      expect(
        nest.top + PipNestFallback.nestBowlBottomFraction * nest.height,
        closeTo(_dBowlBottom, 2),
        reason: 'design bowl bottom row',
      );
      final pip = tester.getRect(find.byType(PipAvatar));
      expect(pip.center.dy, closeTo(_dPipCenterY, 2), reason: 'Pip centre');
      await disposeApp(tester);
    },
    skip: true,
  );

  // =========================================================================
  // PARKED PROOFS for the 04:52 ORCHESTRATOR_NOTES row rules
  // =========================================================================

  testWidgets(
    'K03B-BUG-4: an approved quest that needed approval says “Mum said yes!”',
    (tester) async {
      await _seedAllDone(tester);
      await tester.runAsync(() async {
        final db = GetIt.instance<AppDatabase>();
        await (db.update(db.questCompletions)..where(
              (c) =>
                  c.questId.equals('q-reading') &
                  c.status.equals('done_pending'),
            ))
            .write(const QuestCompletionsCompanion(status: Value('approved')));
      });
      await _pump(tester);
      // ORCHESTRATOR_NOTES 04:52 ROW META / K03b HTML l.85.
      expect(find.text('Mum said yes!'), findsOneWidget);
      await disposeApp(tester);
    },
    skip: true,
  );

  testWidgets(
    'K03B-BUG-4: a done quest needing no approval shows its +N coin chip',
    (tester) async {
      await _seedAllDone(tester);
      await tester.runAsync(() async {
        final db = GetIt.instance<AppDatabase>();
        await (db.update(db.quests)..where((q) => q.id.equals('q-tidy'))).write(
          const QuestsCompanion(needsApproval: Value(false)),
        );
        await (db.update(db.questCompletions)..where(
              (c) =>
                  c.questId.equals('q-tidy') & c.status.equals('done_pending'),
            ))
            .write(const QuestCompletionsCompanion(status: Value('approved')));
      });
      await _pump(tester);
      // ORCHESTRATOR_NOTES 04:52 ROW META / K03b HTML l.101.
      expect(find.text('+15'), findsOneWidget);
      await disposeApp(tester);
    },
    skip: true,
  );

  testWidgets(
    'K03B-BUG-5: quests are listed in creation order, never re-sorted',
    (tester) async {
      await _seedAllDone(tester);
      await _pump(tester);
      // ORCHESTRATOR_NOTES 04:52 ROW ORDER: the seed stamps one second per
      // quest, so creation order is dishwasher, reading, bins, tidy, hoover,
      // table — exactly the HTML row order. The repository re-sorts by title.
      final cards = tester
          .widgetList<NestKidQuestCard>(find.byType(NestKidQuestCard))
          .toList();
      expect(cards.map((c) => c.title).toList(), <String>[
        'Empty the dishwasher',
        'Reading \u2013 20 minutes',
        'Put the bins out',
        'Tidy your bedroom',
        'Hoover the stairs',
        'Lay the table',
      ]);
      await disposeApp(tester);
    },
    skip: true,
  );

  // =========================================================================
  // CLEAN PROBES
  // =========================================================================

  group('allDone truth table', () {
    test('empty is false, partial is false, all approved/pending is true', () {
      expect(const KidHomeState().allDone, isFalse);
      expect(
        KidHomeState(items: _items(<String>['approved', 'to_do'])).allDone,
        isFalse,
      );
      expect(
        KidHomeState(items: _items(<String>['approved', 'done_pending']))
            .allDone,
        isTrue,
      );
      // Any non-done status (including a legacy/unknown one) keeps it false.
      expect(
        KidHomeState(items: _items(<String>['approved', 'not_yet'])).allDone,
        isFalse,
      );
    });
  });

  testWidgets('completing the last quests on /kid-home shows the K03b state', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final repo = GetIt.instance<KidHomeRepository>();
      await repo.completeQuest('maya', 'q-reading');
      await repo.completeQuest('maya', 'q-tidy');
    });
    await _pump(tester, route: '/kid-home');
    expect(find.text('All done!'), findsOneWidget);
    expect(find.text('6 of 6 done'), findsOneWidget);
    expect(find.text('Visit Pip'), findsOneWidget);
    expect(find.text('My jar'), findsNothing);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets(
    'the all-done state flips back live when a quest stops counting',
    (tester) async {
      await _seedAllDone(tester);
      await _pump(tester);
      expect(find.text('All done!'), findsOneWidget);
      await tester.runAsync(() async {
        final db = GetIt.instance<AppDatabase>();
        await (db.update(db.questCompletions)..where(
              (c) =>
                  c.questId.equals('q-reading') &
                  c.status.equals('done_pending'),
            ))
            .write(const QuestCompletionsCompanion(status: Value('to_do')));
      });
      await _settle(tester);
      expect(find.text('All done!'), findsNothing);
      expect(find.text('5 done today'), findsOneWidget);
      expect(find.text('My jar'), findsOneWidget);
      await disposeApp(tester);
    },
  );

  testWidgets('the all-done state expires when the London day rolls over', (
    tester,
  ) async {
    await _seedAllDone(tester); // completions at 08:30 on the anchor day
    // The next London day: the four daily completions fall out of period, the
    // two weekly ones (bins/hoover) still count. `appNowUtc()` reads the
    // anchor (not the zone clock) by design, so moving it is the way to move
    // "now" for the whole app.
    Seed.anchorOverride = DateTime.utc(2026, 10, 4);
    addTearDown(() => Seed.anchorOverride = DateTime.utc(2026, 10, 3));
    await _pump(tester);
    expect(find.text('All done!'), findsNothing);
    expect(find.text('2 done today'), findsOneWidget);
    expect(find.text('My jar'), findsOneWidget);
    await disposeApp(tester);
  });

  test('period boundary: a daily completion counts until London midnight', () {
    final completion = DateTime.utc(2026, 10, 3, 8, 30);
    expect(
      countsForCurrentPeriod(
        'daily',
        completion,
        DateTime.utc(2026, 10, 3, 22, 55),
      ),
      isTrue,
      reason: 'Sat 23:55 London is still the same day',
    );
    expect(
      countsForCurrentPeriod(
        'daily',
        completion,
        DateTime.utc(2026, 10, 3, 23, 5),
      ),
      isFalse,
      reason: 'Sun 00:05 London starts a new day',
    );
    expect(
      countsForCurrentPeriod(
        'weekly',
        completion,
        DateTime.utc(2026, 10, 4, 22),
      ),
      isTrue,
      reason: 'still the same Mon–Sun week',
    );
    expect(
      countsForCurrentPeriod(
        'weekly',
        completion,
        DateTime.utc(2026, 10, 5, 0, 30),
      ),
      isFalse,
      reason: 'Monday starts a new week',
    );
  });

  test('BST fall-back: a 00:30 BST completion counts all London day', () {
    // Clocks go back 02:00 BST → 01:00 GMT on Sun 25 Oct 2026. A completion
    // at 00:30 BST is still the same London day at 04:00 GMT.
    final completion = DateTime.utc(2026, 10, 24, 23, 30);
    expect(
      countsForCurrentPeriod(
        'daily',
        completion,
        DateTime.utc(2026, 10, 25, 4),
      ),
      isTrue,
      reason: '00:30 BST and 04:00 GMT are the same London day',
    );
    expect(
      countsForCurrentPeriod(
        'daily',
        completion,
        DateTime.utc(2026, 10, 26, 0, 30),
      ),
      isFalse,
      reason: 'the next London day starts fresh',
    );
  });

  testWidgets('/kid-home-done with no children shows the picker', (
    tester,
  ) async {
    await tester.runAsync(() => Seed.empty(GetIt.instance<AppDatabase>()));
    await tester.runAsync(() => GetIt.instance<AppSession>().refresh());
    await _pump(tester);
    expect(find.text("Who's playing?"), findsOneWidget);
    expect(find.text('All done!'), findsNothing);
    expect(find.text('Visit Pip'), findsNothing);
    await disposeApp(tester);
  });

  testWidgets('a child with zero quests sees the empty state, never All done', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final db = GetIt.instance<AppDatabase>();
      final quests = await (db.select(
        db.quests,
      )..where((q) => q.assigneeChildId.equals('maya'))).get();
      for (final quest in quests) {
        await (db.delete(
          db.questCompletions,
        )..where((c) => c.questId.equals(quest.id))).go();
      }
      await (db.delete(
        db.quests,
      )..where((q) => q.assigneeChildId.equals('maya'))).go();
    });
    await _pump(tester);
    expect(find.text('No quests today'), findsOneWidget);
    expect(find.text('All done!'), findsNothing);
    expect(find.text('Visit Pip'), findsNothing);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('a single done quest reads 1 of 1 done and celebrates', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final db = GetIt.instance<AppDatabase>();
      final quests = await (db.select(
        db.quests,
      )..where((q) => q.assigneeChildId.equals('maya'))).get();
      for (final quest in quests) {
        await (db.delete(
          db.questCompletions,
        )..where((c) => c.questId.equals(quest.id))).go();
      }
      for (final quest in quests) {
        if (quest.id == 'q-reading') continue;
        await (db.delete(db.quests)..where((q) => q.id.equals(quest.id))).go();
      }
      await GetIt.instance<KidHomeRepository>().completeQuest(
        'maya',
        'q-reading',
      );
    });
    await _pump(tester);
    expect(find.text('All done!'), findsOneWidget);
    expect(find.text('1 of 1 done'), findsOneWidget);
    expect(find.text('Visit Pip'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets(
    '9999 coins and a long UK name fit the all-done header at 320/1.3',
    (tester) async {
      await _seedAllDone(tester);
      await tester.runAsync(() async {
        final db = GetIt.instance<AppDatabase>();
        await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
          const ChildrenCompanion(
            nickname: Value('Maximilian-Alexander'),
            coins: Value(9999),
          ),
        );
      });
      await _pump(tester, width: 320, textScale: 1.3);
      expect(find.text('Hi Maximilian-Alexander!'), findsOneWidget);
      expect(find.text('9999'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    },
  );

  testWidgets('0 coins renders 0 and the kid screen never shows £', (
    tester,
  ) async {
    await _seedAllDone(tester);
    await tester.runAsync(() async {
      final db = GetIt.instance<AppDatabase>();
      await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(coins: Value(0)),
      );
    });
    await _pump(tester);
    expect(find.text('0'), findsOneWidget);
    expect(find.textContaining('\u00a3'), findsNothing);
    await disposeApp(tester);
  });

  testWidgets('Visit Pip exposes a tap action and opens /pip', (tester) async {
    final semantics = tester.ensureSemantics();
    await _seedAllDone(tester);
    await _pump(tester);
    final button = find.descendant(
      of: find.byType(NestKidButton),
      matching: find.text('Visit Pip'),
    );
    expect(
      tester
          .getSemantics(button)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    tester.semantics.performAction(
      find.semantics.byLabel('Visit Pip'),
      SemanticsAction.tap,
    );
    await _settle(tester);
    expect(currentPath(tester), '/pip');
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('double-tapping Visit Pip opens exactly one Pip screen', (
    tester,
  ) async {
    await _seedAllDone(tester);
    await _pump(tester);
    final visit = find.text('Visit Pip');
    await tester.tap(visit);
    await tester.tap(visit);
    await _settle(tester);
    expect(currentPath(tester), '/pip');
    expect(find.text('Visit Pip'), findsNothing);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('all-done cards open the detail; checks are display-only', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _seedAllDone(tester);
    await _pump(tester);
    // Every card is done: one tappable node per card, and no separate
    // decorative check node (the design's checks are not controls).
    expect(find.semantics.byLabel('Done'), findsNothing);
    expect(find.semantics.byLabel('Mark done'), findsNothing);
    final card = find.semantics.byLabel(
      "Empty the dishwasher, Waiting for Mum's thumbs-up",
    );
    expect(card, findsOneWidget);
    tester.semantics.performAction(card, SemanticsAction.tap);
    await _settle(tester);
    expect(pushedPath(tester), '/quest-detail');
    // Back from the detail returns to the same live all-done state.
    await tester.tap(find.byType(NestIconButton).first);
    await _settle(tester);
    expect(find.text('All done!'), findsOneWidget);
    expect(find.text('Visit Pip'), findsOneWidget);
    semantics.dispose();
    await disposeApp(tester);
  });

  testWidgets('six children in the family do not change the all-done state', (
    tester,
  ) async {
    await _seedAllDone(tester);
    await tester.runAsync(() async {
      final db = GetIt.instance<AppDatabase>();
      for (var i = 0; i < 4; i++) {
        await db
            .into(db.children)
            .insert(
              ChildrenCompanion.insert(
                id: 'extra$i',
                familyId: Seed.familyId,
                nickname: 'Extra Child $i',
              ),
            );
      }
    });
    await _pump(tester);
    expect(find.text('Hi Maya!'), findsOneWidget);
    expect(find.text('All done!'), findsOneWidget);
    expect(find.text('6 of 6 done'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('kid mode reaches /kid-home-done but not /approvals', (
    tester,
  ) async {
    await _seedAllDone(tester);
    await _pump(tester);
    expect(currentPath(tester), '/kid-home-done');
    await disposeApp(tester);
    await _pump(tester, route: '/approvals');
    expect(currentPath(tester), '/parental-gate');
    await disposeApp(tester);
  });

  testWidgets('scrolling the all-done list at 320/1.3 never overflows', (
    tester,
  ) async {
    await _seedAllDone(tester);
    await _pump(tester, width: 320, textScale: 1.3);
    expect(find.text('All done!'), findsOneWidget);
    final list = find.byType(Scrollable).first;
    for (var i = 0; i < 8; i++) {
      await tester.drag(list, const Offset(0, -220));
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  testWidgets('the all-done bar uses the child\u2019s own PipAvatar', (
    tester,
  ) async {
    await _seedAllDone(tester);
    await _pump(tester);
    final avatars = tester
        .widgetList<PipAvatar>(find.byType(PipAvatar))
        .toList();
    expect(avatars, isNotEmpty);
    final av = avatars.first;
    expect(av.style, PipStyle.mochi);
    expect(av.skin, PipSkin.sunny);
    expect(av.accessory, PipAccessory.none);
    expect(av.stage, 3);
    await disposeApp(tester);
  });

  testWidgets('Leo\u2019s all-done state uses bolt/sky/stage 2 and 4 of 4', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final db = GetIt.instance<AppDatabase>();
      final now = Seed.utc(10, 3, 8, 30);
      for (final entry in <String, int>{
        'q-biscuit': 5,
        'q-plants': 10,
      }.entries) {
        await db
            .into(db.questCompletions)
            .insert(
              QuestCompletionsCompanion.insert(
                questId: entry.key,
                childId: 'leo',
                familyId: Seed.familyId,
                status: const Value('done_pending'),
                coins: Value(entry.value),
                createdAt: Value(now),
                createdAtTz: const Value('Europe/London'),
              ),
            );
      }
      await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
        const AppStateCompanion(activeChildId: Value<String?>('leo')),
      );
      await GetIt.instance<AppSession>().refresh();
    });
    await _pump(tester);
    expect(find.text('All done!'), findsOneWidget);
    expect(find.text('4 of 4 done'), findsOneWidget);
    final avatars = tester
        .widgetList<PipAvatar>(find.byType(PipAvatar))
        .toList();
    expect(avatars.first.style, PipStyle.bolt);
    expect(avatars.first.skin, PipSkin.sky);
    expect(avatars.first.stage, 2);
    await disposeApp(tester);
  });

  testWidgets('the all-done bar surface reaches the physical bottom edge', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await _seedAllDone(tester);
    await _pump(tester);
    const scheme = NestColors.light;
    final screenH =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final surfaceBoxes = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).color == scheme.surface,
    );
    final covering = surfaceBoxes.evaluate().where((element) {
      final rect = tester.getRect(
        find.byElementPredicate((e) => identical(e, element)),
      );
      return rect.left <= 0.5 &&
          rect.right >= 389.5 &&
          rect.bottom >= screenH - 0.5;
    });
    expect(covering, isNotEmpty, reason: 'no meadow strip below the bar');
    await disposeApp(tester);
  });

  testWidgets('the all-done bar surface reaches the edge in dark mode too', (
    tester,
  ) async {
    tester.view.padding = const FakeViewPadding(bottom: 34);
    tester.view.viewPadding = const FakeViewPadding(bottom: 34);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);
    await _seedAllDone(tester);
    await _pump(tester, theme: ThemeMode.dark);
    const scheme = NestColors.dark;
    final screenH =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final surfaceBoxes = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration! as BoxDecoration).color == scheme.surface,
    );
    final covering = surfaceBoxes.evaluate().where((element) {
      final rect = tester.getRect(
        find.byElementPredicate((e) => identical(e, element)),
      );
      return rect.left <= 0.5 &&
          rect.right >= 389.5 &&
          rect.bottom >= screenH - 0.5;
    });
    expect(covering, isNotEmpty, reason: 'no meadow strip below the dark bar');
    await disposeApp(tester);
  });

  testWidgets('dark mode shows the all-done state with dark tokens', (
    tester,
  ) async {
    await _seedAllDone(tester);
    await _pump(tester, theme: ThemeMode.dark);
    expect(find.text('All done!'), findsOneWidget);
    expect(find.text('Visit Pip'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await disposeApp(tester);
  });

  test('the all-done token pairs meet WCAG contrast in light and dark', () {
    const light = NestColors.light;
    const dark = NestColors.dark;
    final pairs = <String, (Color, Color)>{
      'light leafInk on skyTop': (light.leafInk, light.kidSkyTop),
      'light leafInk on skyBottom': (light.leafInk, light.kidSkyBottom),
      'light leafInk on leafTint': (light.leafInk, light.leafTint),
      'light onAccent on lilacStrong': (light.onAccent, light.lilacStrong),
      'dark leafInk on skyTop': (dark.leafInk, dark.kidSkyTop),
      'dark leafInk on skyBottom': (dark.leafInk, dark.kidSkyBottom),
      'dark leafInk on leafTint': (dark.leafInk, dark.leafTint),
      'dark onAccent on lilacStrong': (dark.onAccent, dark.lilacStrong),
    };
    for (final MapEntry(key: name, value: (a, b)) in pairs.entries) {
      expect(
        _contrast(a, b),
        greaterThanOrEqualTo(4.5),
        reason: '$name contrast',
      );
    }
  });

  test('restart: the all-done state survives a database reopen', () async {
    final dir = Directory.systemTemp.createTempSync('k03b_restart_');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/nestling.db');
    final db1 = AppDatabase(NativeDatabase(file));
    await Seed.kidAllDone(db1);
    final home1 = await KidHomeRepositoryImpl(db: db1).watchHome().first;
    await db1.close();
    final db2 = AppDatabase(NativeDatabase(file));
    final home2 = await KidHomeRepositoryImpl(db: db2).watchHome().first;
    await db2.close();
    for (final home in <KidHomeData>[home1, home2]) {
      expect(home.child?.id, 'maya');
      expect(home.items, hasLength(6));
      expect(
        home.items.every((i) => i.status != 'to_do'),
        isTrue,
        reason: 'all six stay done across a restart',
      );
    }
  });
}
