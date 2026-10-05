// K11 · My badges — stage 3 width × text-scale × theme matrix, plus the
// database-driven copy variants and the `Seed.empty` family.
//
// Separate from `badges_view_test.dart` (behaviour / navigation) and
// `badges_widget_geometry_test.dart` (design geometry at the real bundled
// Nunito metrics) because this file is about SURVIVAL of the layout and the
// copy branches the seeded numbers select: 3 device widths × 2 text scales ×
// 2 themes, and every earned / happy-day count the copy can be handed.
//
// Every pumped app ends with `disposeApp` (test_scope.dart). No
// `DateTime.now`, no `google_fonts`, no simulator, no clock reads: the counts
// come from the database exactly as the app reads them.

import 'package:drift/drift.dart' show Value;
// Material's `Badge` widget collides with the Drift row class for the
// `badges` table these tests write to.
import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/badges/presentation/views/badges_view.dart';
import 'package:nestling/features/badges/presentation/widgets/badge_grid_cell.dart';
import 'package:nestling/features/badges/presentation/widgets/happy_week_card.dart';

import '../../test_scope.dart';

const String _route = '/badges';

Future<void> _pumpRoute(
  WidgetTester tester, {
  double width = 390,
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(const NestlingApp(initialRoute: _route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Runs a Drift write inside `tester.runAsync`.
///
/// `testWidgets` runs on a fake async zone: a raw `await db…write(…)` never
/// completes there (the sqlite3 worker needs the real event loop), which hangs
/// the whole file until the runner's SIGTERM. Every mutation in this file goes
/// through here — the K11 view tests use the same `runAsync` wrapper.
Future<void> _write(WidgetTester tester, Future<void> Function() action) async {
  await tester.runAsync(() async {
    await action();
    await Future<void>.delayed(Duration.zero);
  });
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await setUpTestScope();
  });

  group('K11 width x text-scale x theme matrix', () {
    for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in <double>[320, 390, 430]) {
        for (final scale in <double>[1, 1.3]) {
          testWidgets(
            '${width.toInt()} px at scale $scale in ${theme.name}: the whole '
            'shelf lays out, stays on the gutters and keeps its chrome',
            (tester) async {
              await _pumpRoute(
                tester,
                width: width,
                textScale: scale,
                theme: theme,
              );
              expect(
                tester.takeException(),
                isNull,
                reason: 'no overflow / no layout exception at this corner',
              );
              // Chrome survives every corner: the child can always leave.
              expect(find.byType(NestIconButton), findsOneWidget);
              expect(find.byType(NestLockButton), findsOneWidget);
              // Title and subtitle keep their copy at every scale.
              expect(find.text('My badges'), findsOneWidget);
              expect(
                find.text('Four shiny ones already. Pip is very impressed.'),
                findsOneWidget,
              );
              // Gutters are 20 on both sides whatever the width (ALIGNMENT
              // owner rule), and the grid never leaves the screen.
              final cells = find.byType(BadgeGridCell);
              expect(cells, findsWidgets);
              expect(tester.getRect(cells.first).left, closeTo(20, 0.5));
              expect(
                tester.getRect(cells.at(2)).right,
                closeTo(width - 20, 0.5),
                reason: 'the third column ends on the right gutter',
              );
              await disposeApp(tester);
            },
          );
        }
      }
    }

    testWidgets('the week card stays inside the gutters at every corner', (
      tester,
    ) async {
      for (final width in <double>[320, 390, 430]) {
        db = await setUpTestScope();
        await _pumpRoute(tester, width: width);
        await tester.scrollUntilVisible(find.byType(HappyWeekCard), 120);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final week = tester.getRect(find.byType(HappyWeekCard));
        expect(week.left, closeTo(20, 0.5), reason: 'at ${width.toInt()}');
        expect(
          week.right,
          closeTo(width - 20, 0.5),
          reason: 'at ${width.toInt()}',
        );
        await disposeApp(tester);
      }
    });

    testWidgets('a long badge name ellipsises instead of overflowing', (
      tester,
    ) async {
      // Two lines are the design's allowance (`.k11-n { min-height: 38px }`);
      // anything longer must clip, never paint over the card below.
      await _write(tester, () async {
        await (db.update(
          db.badges,
        )..where((b) => b.id.equals('first-quest'))).write(
          const BadgesCompanion(
            title: Value('An extremely long badge name that cannot fit'),
          ),
        );
      });
      await _pumpRoute(tester, width: 320, textScale: 1.3);
      expect(tester.takeException(), isNull);
      final tile = tester.widget<Text>(
        find.text('An extremely long badge name that cannot fit'),
      );
      expect(tile.maxLines, 2);
      expect(tile.overflow, TextOverflow.ellipsis);
      await disposeApp(tester);
    });
  });

  group('K11 database-driven copy variants', () {
    // Each mutation is a closure the test hands to `_write`, so the database
    // work happens on the real event loop while the widget tree is pumped
    // afterwards.
    Future<void> happyDays(WidgetTester tester, int days) =>
        _write(tester, () async {
          await (db.update(db.children)..where((c) => c.id.equals('maya')))
              .write(ChildrenCompanion(happyDays: Value(days)));
        });

    Future<void> clearEarned(WidgetTester tester) =>
        _write(tester, () => db.delete(db.earnedBadges).go());

    Future<void> earnAll(WidgetTester tester) => _write(tester, () async {
      // Clear first: the demo seed already earned four of these, and
      // `earned_badges` is unique on (badge_id, child_id).
      await db.delete(db.earnedBadges).go();
      final family = await db.select(db.families).getSingle();
      for (final row in await db.select(db.badges).get()) {
        await db
            .into(db.earnedBadges)
            .insert(
              EarnedBadgesCompanion.insert(
                badgeId: row.id,
                childId: 'maya',
                familyId: family.id,
              ),
            );
      }
    });

    Future<void> earnOne(WidgetTester tester) => _write(tester, () async {
      final family = await db.select(db.families).getSingle();
      await db
          .into(db.earnedBadges)
          .insert(
            EarnedBadgesCompanion.insert(
              badgeId: 'first-quest',
              childId: 'maya',
              familyId: family.id,
            ),
          );
    });

    /// The `NestIcons.check` glyphs inside the week card — one per filled
    /// happy day.
    Finder filledDots() => find.descendant(
      of: find.byType(HappyWeekCard),
      matching: find.byWidgetPredicate(
        (w) => w is NestIcon && w.assetName == NestIcons.check,
      ),
    );

    testWidgets('no happy days keeps the positive zero line', (tester) async {
      await happyDays(tester, 0);
      await _pumpRoute(tester);
      expect(
        find.text('Let’s make today a happy day!'),
        findsOneWidget,
        reason:
            'no loss-aversion, no broken-streak copy '
            '(Children’s Code std 13)',
      );
      expect(filledDots(), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('one happy day is singular', (tester) async {
      await happyDays(tester, 1);
      await _pumpRoute(tester);
      expect(
        find.text('1 happy day this week — Pip hasn’t stopped singing.'),
        findsOneWidget,
      );
      expect(filledDots(), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('seven happy days fills every dot', (tester) async {
      await happyDays(tester, 7);
      await _pumpRoute(tester);
      expect(
        find.text('7 happy days this week — Pip hasn’t stopped singing.'),
        findsOneWidget,
      );
      expect(filledDots(), findsNWidgets(7));
      await disposeApp(tester);
    });

    testWidgets('zero earned badges uses the zero subtitle and no Got it!', (
      tester,
    ) async {
      await clearEarned(tester);
      await _pumpRoute(tester);
      expect(
        find.text('No shiny ones yet. Finish a quest to earn your first!'),
        findsOneWidget,
      );
      expect(find.text('Got it!'), findsNothing);
      expect(find.text('Keep going!'), findsWidgets);
      // The week card is independent of the shelf: it still celebrates.
      expect(find.byType(HappyWeekCard), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('one earned badge is singular in the subtitle', (tester) async {
      await clearEarned(tester);
      await earnOne(tester);
      await _pumpRoute(tester);
      expect(
        find.text('One shiny one already. Pip is very impressed.'),
        findsOneWidget,
      );
      expect(find.text('Got it!'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('every badge earned reads as a full shelf', (tester) async {
      await earnAll(tester);
      await _pumpRoute(tester);
      final rows =
          await tester.runAsync(() => db.select(db.badges).get()) ?? <Badge>[];
      expect(find.text('Got it!'), findsNWidgets(rows.length));
      expect(find.text('Keep going!'), findsNothing);
      final word = rows.length <= 9
          ? const <String>[
              'One',
              'Two',
              'Three',
              'Four',
              'Five',
              'Six',
              'Seven',
              'Eight',
              'Nine',
            ][rows.length - 1]
          : '${rows.length}';
      expect(
        find.text('$word shiny ones already. Pip is very impressed.'),
        findsOneWidget,
      );
      await disposeApp(tester);
    });
  });

  group('K11 on an empty family (Seed.empty)', () {
    testWidgets('a family with no children shows the empty shelf, no crash', (
      tester,
    ) async {
      await _write(tester, () async {
        await Seed.empty(db);
        await GetIt.instance<AppSession>().refresh();
      });
      await _pumpRoute(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('No badges yet'), findsOneWidget);
      expect(
        find.text('Finish a quest and your first badge will shine here.'),
        findsOneWidget,
      );
      expect(find.byType(BadgeGridCell), findsNothing);
      expect(find.byType(HappyWeekCard), findsNothing);
      // The empty surface is still escapable and still reaches a grown-up.
      expect(find.byType(NestIconButton), findsOneWidget);
      expect(find.byType(NestLockButton), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('the empty copy is the design invention, not a mangled line', (
      tester,
    ) async {
      await _write(tester, () async {
        await Seed.empty(db);
        await GetIt.instance<AppSession>().refresh();
      });
      await _pumpRoute(tester);
      // Character-exact, from `BadgesCopy` (plan §d flags both as invented
      // kid voice — the design has no empty-shelf source).
      expect(BadgesCopy.emptyTitle, 'No badges yet');
      expect(
        BadgesCopy.emptyMessage,
        'Finish a quest and your first badge will shine here.',
      );
      expect(BadgesCopy.subtitle(0), contains('No shiny ones yet'));
      expect(HappyWeekCopy.why(0), 'Let’s make today a happy day!');
      await disposeApp(tester);
    });
  });
}
