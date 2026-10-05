// K11 · My badges — STAGE 6 bug hunt (iteration 2).
//
// Iteration 1 proved two bugs here (K11-BUG-1 unclamped happyDays,
// K11-BUG-2 hard-coded `'maya'` fallback). Both were fixed by the
// iteration-2 build and are now kept as UN-SKIPPED regression guards:
//
//   K11-BUG-1  `HappyWeekCard` clamps `happyDays` to 0..7 for the dots and
//              the why-line (widget + `HappyWeekCopy.why`).
//   K11-BUG-2  `BadgesRepositoryImpl` resolves the child from the roster
//              (persisted active id → first child in creation order → no
//              child = empty shelf); no hard-coded id anywhere.
//
// The iteration-2 hunt found no new bugs: the repository resolution matrix
// (0/1/6 children, deleted active child, creation order, empty family live
// recovery) and the widget states were probed clean; see
// `docs/screens/K11/6_bugs.md` for the full evidence table.
//
// Harness note: one DB write per `tester.runAsync` + a pump between writes.
// A second write in the same runAsync queues behind a stream re-query
// scheduled in the fake-async zone and deadlocks — a flutter_test/Drift
// harness behaviour, not product code (the build stage hit the same thing).
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
import 'package:nestling/core/data/seed.dart';
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

/// One real-async DB write, then a pump so the Drift stream re-query lands
/// in the fake-async zone before the next write is issued.
Future<void> _write(WidgetTester tester, Future<void> Function() body) async {
  await tester.runAsync(body);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await setUpTestScope();
  });

  // -------------------------------------------------------------------------
  // K11-BUG-1 (fixed in iteration 2) — happyDays clamp
  // -------------------------------------------------------------------------
  testWidgets('K11-BUG-1 happyDays 8 clamps to the seven drawn days', (
    tester,
  ) async {
    await _pumpRoute(tester);
    expect(
      find.text('4 happy days this week — Pip hasn’t stopped singing.'),
      findsOneWidget,
    );

    // A stored count above the 0..7 the schema documents (`Children
    // .happyDays`, app_database.dart:93). The card draws seven days; the
    // why-line and the dots must clamp to them.
    await _write(
      tester,
      () => (db.update(db.children)..where((c) => c.id.equals('maya'))).write(
        const ChildrenCompanion(happyDays: Value(8)),
      ),
    );
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
  });

  // -------------------------------------------------------------------------
  // K11-BUG-2 (fixed in iteration 2) — child resolution
  // -------------------------------------------------------------------------
  testWidgets('K11-BUG-2 a non-Maya family with no active child shows Zoe', (
    tester,
  ) async {
    await _pumpRoute(tester);

    // A family whose only child is Zoe, with one earned badge, and no
    // active child (deep link to /badges before a child was picked).
    await _write(tester, () => db.delete(db.earnedBadges).go());
    await _write(tester, () => db.delete(db.children).go());
    await _write(
      tester,
      () => db
          .into(db.children)
          .insert(
            ChildrenCompanion.insert(
              id: 'zoe',
              familyId: Seed.familyId,
              nickname: 'Zoe',
              happyDays: const Value(2),
            ),
          ),
    );
    await _write(
      tester,
      () => db
          .into(db.earnedBadges)
          .insert(
            EarnedBadgesCompanion.insert(
              badgeId: 'bookworm',
              childId: 'zoe',
              familyId: Seed.familyId,
            ),
          ),
    );
    await _write(
      tester,
      () => (db.update(db.appState)..where((a) => a.id.equals(1))).write(
        const AppStateCompanion(activeChildId: Value<String?>(null)),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.text('One shiny one already. Pip is very impressed.'),
      findsOneWidget,
      reason: 'activeChildId null resolves this family (Zoe), not maya',
    );
    expect(
      find.text('No shiny ones yet. Finish a quest to earn your first!'),
      findsNothing,
      reason: 'that line was the maya fallback artifact for this family',
    );
    expect(find.text('Got it!'), findsOneWidget);
    expect(find.byType(BadgeGridCell), findsNWidgets(9));
    await disposeApp(tester);
  });
}
