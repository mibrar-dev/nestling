// K11 · My badges — STAGE 6 adversarial bug hunt (iteration 1).
//
// Two bugs were proven in this file; both tests are marked `skip:` with their
// bug id so the suite stays green. Remove the skip (or run with
// `--run-skipped`) to watch them fail:
//
//   K11-BUG-1  `HappyWeekCard` uses an unclamped `happyDays` for both the
//              seven dots and the why-line, so a stored count above 7
//              renders an impossible week ("8 happy days" under 7 dots).
//   K11-BUG-2  `BadgesRepositoryImpl.watchActiveBadges` falls back to the
//              hard-coded child id `'maya'` when `app_state.activeChildId`
//              is null, so a deep link in a family whose children are not
//              named Maya shows a shelf that belongs to no child at all.
//
// The rest of the adversarial matrix was probed and came back clean; the
// negative results are recorded in `docs/screens/K11/6_bugs.md` (§"Checked,
// no bug found") — double-tap Back, 320 px × 1.3 text scale overflow (whole
// screen), long badge titles, negative happyDays, dark mode, app restart
// persistence, live empty→shelf, Seed.empty/zero children, the
// `_switchMap` stale-emission race (10 switch+write bursts), and the
// nine-id medal map from `ORCHESTRATOR_NOTES.md`.
//
// Scaffolding mirrors `badges_view_test.dart` (in-memory Drift via
// `setUpTestScope`, `disposeApp` after every pump, no clock reads, no
// simulator).

import 'package:drift/drift.dart' show Value;
// Material's `Badge` widget collides with the Drift row class.
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/badges/presentation/widgets/badge_grid_cell.dart';
import 'package:nestling/features/badges/presentation/widgets/happy_week_card.dart';

import '../../test_scope.dart';

const String _route = '/badges';

Future<void> _pumpRoute(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
  String route = _route,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await setUpTestScope();
  });

  // -------------------------------------------------------------------------
  // K11-BUG-1 — unclamped happyDays
  // -------------------------------------------------------------------------
  // skip reason K11-BUG-1: happyDays is used unclamped (see 6_bugs.md).
  testWidgets('K11-BUG-1 happyDays 8 renders an impossible week', (
    tester,
  ) async {
    // A stored count above the 0..7 the schema documents (`Children
    // .happyDays`, app_database.dart:93). The card draws seven days; the
    // why-line and the dots must clamp to them.
    await (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
      const ChildrenCompanion(happyDays: Value(8)),
    );
    await _pumpRoute(tester);
    expect(tester.takeException(), isNull);

    final checks = find.descendant(
      of: find.byType(HappyWeekCard),
      matching: find.byWidgetPredicate(
        (widget) => widget is NestIcon && widget.assetName == NestIcons.check,
      ),
    );
    expect(checks, findsNWidgets(7), reason: 'only seven days exist');
    expect(
      find.text('8 happy days this week — Pip hasn’t stopped singing.'),
      findsNothing,
      reason: 'the card must not claim a day it cannot draw',
    );
    expect(
      find.text('7 happy days this week — Pip hasn’t stopped singing.'),
      findsOneWidget,
      reason: 'the line clamps to the seven drawn days',
    );
    await disposeApp(tester);
  }, skip: true); // K11-BUG-1: happyDays is used unclamped (see 6_bugs.md).

  // -------------------------------------------------------------------------
  // K11-BUG-2 — hard-coded maya fallback
  // -------------------------------------------------------------------------
  // skip reason K11-BUG-2: watchActiveBadges falls back to maya.
  testWidgets(
    'K11-BUG-2 a non-Maya family with no active child shows the Maya shelf',
    (tester) async {
      // A family whose only child is Zoe, with one earned badge, and no
      // active child (deep link to /badges before a child was picked).
      final family = await db.select(db.families).getSingle();
      await db.delete(db.earnedBadges).go();
      await db.delete(db.children).go();
      await db
          .into(db.children)
          .insert(
            ChildrenCompanion.insert(
              id: 'zoe',
              familyId: family.id,
              nickname: 'Zoe',
              happyDays: const Value(2),
            ),
          );
      await db
          .into(db.earnedBadges)
          .insert(
            EarnedBadgesCompanion.insert(
              badgeId: 'bookworm',
              childId: 'zoe',
              familyId: family.id,
            ),
          );
      await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
        const AppStateCompanion(activeChildId: Value<String?>(null)),
      );

      await _pumpRoute(tester);
      expect(tester.takeException(), isNull);

      // The screen must either resolve Zoe (the first child in roster
      // order) or show the childless empty state — never the hard-coded
      // Maya fallback, which claims "No shiny ones yet" for a family where
      // Zoe has earned one.
      final showedZoe = find
          .text('One shiny one already. Pip is very impressed.')
          .evaluate()
          .isNotEmpty;
      final showedChildlessEmpty = find
          .text('No badges yet')
          .evaluate()
          .isNotEmpty;
      expect(
        showedZoe || showedChildlessEmpty,
        isTrue,
        reason:
            'activeChildId null must resolve this family (Zoe) or no child, '
            'not the hard-coded maya',
      );
      expect(
        find.text('No shiny ones yet. Finish a quest to earn your first!'),
        findsNothing,
        reason: 'that line is the maya fallback artifact for this family',
      );
      expect(find.byType(BadgeGridCell), findsWidgets);
      await disposeApp(tester);
    },
    skip: true, // K11-BUG-2: watchActiveBadges falls back to maya.
  );
}
