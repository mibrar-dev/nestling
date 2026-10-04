// K04 (quest detail) adversarial bug hunt — Stage 6, iteration 1.
//
// Findings in this file:
//
// * K04-BUG-1 (MAJOR, open) — a quest title that fills all 3 allowed lines
//   renders INVISIBLE. `NestBalancedText` computes its balanced width with
//   `maxLines: 3` applied to the probe painter, so a text whose natural
//   layout needs 3+ lines never reports more than 3 lines at any width and
//   the binary search collapses to ~0 px (measured: 0.085 px unit, 0.1 px in
//   the widget). The heading is then laid out 0.1 px wide and clipped: the
//   screen shows an empty 102 px gap where the quest title should be. The
//   title is DB-driven (P09 has no length cap), so a parent can create such
//   a quest. Run: `flutter test --run-skipped --plain-name K04-BUG-1`.
//   Root cause is in the shared component, but K04's `maxLines: 3` call
//   site is where it renders. Suggested fix: in `NestBalancedText.build`,
//   count lines with `maxLines: null`; when that count exceeds `maxLines`,
//   skip balancing and return `_text()` at full width (the design has no
//   max-lines, so a full-width, ellipsised heading is the honest render).
//
// * K04-BUG-2 (MINOR, open) — a route `extra` that names another child
//   (`{'questId': 'q-bed', 'childId': 'leo'}` while Maya is playing) silently
//   swaps in a DIFFERENT quest (the q-tidy fallback) instead of the
//   "Pick a quest" state, contradicting the view's own doc comment ("an id
//   that no longer resolves is an unknown quest, NOT a licence to show a
//   different one"). Unreachable via K03 (which always passes the active
//   child), only via a crafted push/deep-link. Run:
//   `flutter test --run-skipped --plain-name K04-BUG-2`.
//   Suggested fix: when the extra supplies a String `questId` and it does
//   not resolve for the active child, return null (missing state); use the
//   q-tidy/first-item fallbacks only when no `questId` was supplied.
//
// * K04-BUG-3 (MAJOR, open, mandated) — `ORCHESTRATOR_NOTES.md` (14:28 QA):
//   "The quest hero icon must be the design's glyph. For the 'bed' quest it
//   is the flat bed (shared `NestIcons.questBed`, added in batch 5 from the
//   P09 HTML), not the current bed-with-figure icon." K04's `_iconFor` still
//   returns the pre-batch-5 glyphs (`bedSit`, `dishwasher`, `hoover`, `bin`),
//   so the hero tile diverges from both the P09 design mapping and the
//   mandate. Run: `flutter test --run-skipped --plain-name K04-BUG-3`.
//   Suggested fix: mirror P09's key/alias table
//   (`quest_editor_view.dart` `_questIcons`): bed/sofa → `questBed`,
//   dishwasher/plate → `questDishes`, hoover → `questHoover`,
//   bin/bins/shirt/bag → `questBins`, book → `book`, paw/leaf → `paw`,
//   anything else → `questCard`.
//
// Checked clean (kept as evidence; they run in the plain suite):
//   * double-tapping either Back pops exactly one route (no stacked pops);
//   * a deep link with `Seed.empty` (no children) offers the picker;
//   * a completed quest stays disabled after a fresh app pump (same DB);
//   * a 9999-coin quest at 320 px / 1.3x text does not overflow;
//   * the dark bottom bar surface reaches the physical edge under a 34 px
//     home-indicator inset (owner bottom-edge rule);
//   * a daily quest whose only completion is 30 h old is "to do" again
//     (London period rule, K03-BUG-4 ruling);
//   * every K04 token pair meets WCAG 4.5:1 in both themes.
//
// Also probed and deliberately NOT filed: completing and pressing Back in
// the same frame ends on /quest-complete with the DB row saved and no
// exception (the celebration wins; acceptable product behaviour). A
// staggered double tap of "I did it!" (one frame apart, write still in
// flight) dispatches twice, but the repository transaction is idempotent:
// one row, one celebration — same guard pattern K03-BUG-11 mandated.

import 'dart:async';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';

import '../../test_scope.dart';

/// A realistic P09 quest name (59 chars) that fills all three 28 px lines at
/// the 350 px content width with the bundled Nunito — the exact condition
/// that collapses the balanced-width probe to ~0 px.
const String _longTitle =
    'Tidy up the playroom and put all the toys back in the boxes';

Future<void> _pump(
  WidgetTester tester, {
  String route = KidHomeRoutePaths.detail,
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
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Pushes a detail route with the same `extra` shape K03 uses.
void _pushDetail(
  WidgetTester tester, {
  required String questId,
  required String childId,
}) {
  final context = tester.element(find.byType(Navigator).first);
  unawaited(
    GoRouter.of(context).push(
      KidHomeRoutePaths.detail,
      extra: <String, Object>{'questId': questId, 'childId': childId},
    ),
  );
}

Future<void> _insertQuest(
  WidgetTester tester, {
  required String id,
  required String title,
  int coins = 10,
}) async {
  final db = GetIt.instance<AppDatabase>();
  await tester.runAsync(() async {
    await db
        .into(db.quests)
        .insert(
          QuestsCompanion.insert(
            id: id,
            familyId: Seed.familyId,
            title: title,
            coins: Value(coins),
            assigneeChildId: const Value('maya'),
          ),
        );
  });
}

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
  setUp(() async {
    await setUpTestScope();
  });

  // -------------------------------------------------------------------------
  // K04-BUG-1 — a three-line quest title renders invisible
  // -------------------------------------------------------------------------

  test(
    'K04-BUG-1: balancedWidthFor collapses to zero when the text exceeds '
    'maxLines',
    () {
      final style = NestType.kidTitle(color: NestColors.light.ink);
      final lines = NestBalancedText.lineCountFor(
        text: _longTitle,
        style: style,
        maxWidth: 350,
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        maxLines: 3,
      );
      // Sanity: the probe itself is clamped at maxLines, which is the root
      // cause — a longer text can never report more than 3 lines.
      expect(lines, 3);

      final width = NestBalancedText.balancedWidthFor(
        text: _longTitle,
        style: style,
        maxWidth: 350,
        lineCount: lines,
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
        maxLines: 3,
      );
      expect(
        width,
        greaterThan(50),
        reason:
            'the balanced heading must stay readable; it collapses to '
            '$width px because the line probe is capped at maxLines',
      );
    },
    // skip: K04-BUG-1 (open)
    skip: true,
  );

  testWidgets(
    'K04-BUG-1: a long quest title measures ~0 px on the detail screen',
    (tester) async {
      await _insertQuest(tester, id: 'q-bug1', title: _longTitle);
      await _pump(tester, route: KidHomeRoutePaths.home);
      _pushDetail(tester, questId: 'q-bug1', childId: 'maya');
      await _settle(tester);

      // The Text exists and reserves its height, but is clipped to a
      // fraction of a pixel: the child sees an empty gap, not a title.
      final size = tester.getSize(find.text(_longTitle));
      expect(
        size.width,
        greaterThan(100),
        reason:
            'the quest title must be visible; measured $size — the balanced '
            'width binary search collapsed to ~0 px',
      );
    },
    // skip: K04-BUG-1 (open)
    skip: true,
  );

  // -------------------------------------------------------------------------
  // K04-BUG-2 — an extra naming another child silently swaps the quest
  // -------------------------------------------------------------------------

  testWidgets(
    'K04-BUG-2: an extra naming another child must not show a different quest',
    (tester) async {
      await _pump(tester, route: KidHomeRoutePaths.home);
      // Leo's bed quest while Maya is the active child.
      _pushDetail(tester, questId: 'q-bed', childId: 'leo');
      await _settle(tester);

      expect(
        find.text('Tidy your bedroom'),
        findsNothing,
        reason:
            'the requested quest does not belong to the active child, so the '
            'screen must not silently swap in Maya\u2019s q-tidy',
      );
      expect(
        find.text('Pick a quest'),
        findsOneWidget,
        reason: 'an unresolvable extra is the missing-quest state',
      );
    },
    // skip: K04-BUG-2 (open)
    skip: true,
  );

  // -------------------------------------------------------------------------
  // K04-BUG-3 — hero tile must use the P09 design glyphs (ORCHESTRATOR_NOTES)
  // -------------------------------------------------------------------------

  testWidgets('K04-BUG-3: the hero tile uses the P09 design glyphs', (
    tester,
  ) async {
    const expected = <String, String>{
      'q-tidy': NestIcons.questBed,
      'q-dishwasher': NestIcons.questDishes,
      'q-hoover': NestIcons.questHoover,
      'q-bins': NestIcons.questBins,
    };
    await _pump(tester, route: KidHomeRoutePaths.home);
    for (final MapEntry(key: questId, value: glyph) in expected.entries) {
      _pushDetail(tester, questId: questId, childId: 'maya');
      await _settle(tester);
      // The hero glyph is the only 64 px NestIcon on the screen.
      final tile = tester
          .widgetList<NestIcon>(find.byType(NestIcon))
          .firstWhere((icon) => icon.size == 64);
      expect(
        tile.assetName,
        glyph,
        reason:
            '$questId must use the batch-5 P09 design glyph; the mandate '
            'rejects the pre-batch-5 icon set',
      );
      await tester.tap(find.byType(NestIconButton));
      await _settle(tester);
    }
  }, skip: true); // skip: K04-BUG-3 (open, mandated)

  // -------------------------------------------------------------------------
  // Checked clean — navigation, persistence, period, overflow, dark edge
  // -------------------------------------------------------------------------

  group('checked clean', () {
    testWidgets('double-tapping either Back pops exactly one route', (
      tester,
    ) async {
      await _pump(tester, route: KidHomeRoutePaths.home);
      _pushDetail(tester, questId: 'q-tidy', childId: 'maya');
      await _settle(tester);
      await tester.tap(find.text('Back').last);
      await tester.tap(find.text('Back').last);
      await _settle(tester);
      expect(pushedPath(tester), KidHomeRoutePaths.home);

      _pushDetail(tester, questId: 'q-tidy', childId: 'maya');
      await _settle(tester);
      await tester.tap(find.byType(NestIconButton));
      await tester.tap(find.byType(NestIconButton));
      await _settle(tester);
      expect(pushedPath(tester), KidHomeRoutePaths.home);
      await disposeApp(tester);
    });

    testWidgets('a deep link with no children offers the picker', (
      tester,
    ) async {
      await tester.runAsync(() => Seed.empty(GetIt.instance<AppDatabase>()));
      await tester.runAsync(() => GetIt.instance<AppSession>().refresh());
      await _pump(tester);
      expect(find.text("Who's playing?"), findsOneWidget);
      await tester.tap(find.text('Choose'));
      await _settle(tester);
      expect(pushedPath(tester), KidHomeRoutePaths.picker);
      await disposeApp(tester);
    });

    testWidgets('a completed quest stays disabled after a fresh app pump', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.text('I did it!'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await disposeApp(tester);

      // Same Drift database, new app instance: the restart path.
      await _pump(tester);
      final semantics = tester.ensureSemantics();
      final data = tester
          .getSemantics(find.bySemanticsLabel('I did it!'))
          .getSemanticsData();
      expect(data.flagsCollection.isEnabled.toBoolOrNull(), isFalse);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      semantics.dispose();
      await disposeApp(tester);
    });

    testWidgets('9999 coins at 320 px / 1.3x text overflow nothing', (
      tester,
    ) async {
      await _insertQuest(tester, id: 'q-fat', title: 'Big reward', coins: 9999);
      await _pump(tester, width: 320, textScale: 1.3);
      _pushDetail(tester, questId: 'q-fat', childId: 'maya');
      await _settle(tester);
      expect(find.byType(NestCoinPill), findsOneWidget);
      expect(find.text('+9999'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('the dark bar surface reaches the edge under a 34 px inset', (
      tester,
    ) async {
      tester.view.padding = const FakeViewPadding(bottom: 34);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await _pump(tester, theme: ThemeMode.dark);
      const scheme = NestColors.dark;
      final surfaces = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color == scheme.surface,
      );
      final covering = surfaces.evaluate().where((element) {
        final rect = tester.getRect(
          find.byElementPredicate((e) => identical(e, element)),
        );
        return rect.left <= 0.5 && rect.right >= 389.5 && rect.bottom >= 843.5;
      });
      expect(
        covering,
        isNotEmpty,
        reason: 'no meadow/sky strip may show below the dark bottom bar',
      );
      await disposeApp(tester);
    });

    testWidgets('a daily quest completed 30 h ago is to do again', (
      tester,
    ) async {
      final db = GetIt.instance<AppDatabase>();
      await tester.runAsync(() async {
        await (db.delete(
          db.questCompletions,
        )..where((c) => c.questId.equals('q-reading'))).go();
        await db
            .into(db.questCompletions)
            .insert(
              QuestCompletionsCompanion.insert(
                questId: 'q-reading',
                childId: 'maya',
                familyId: Seed.familyId,
                status: const Value('approved'),
                coins: const Value(10),
                createdAt: Value(
                  appNowUtc().subtract(const Duration(hours: 30)),
                ),
              ),
            );
      });
      await _pump(tester, route: KidHomeRoutePaths.home);
      _pushDetail(tester, questId: 'q-reading', childId: 'maya');
      await _settle(tester);
      final semantics = tester.ensureSemantics();
      final data = tester
          .getSemantics(find.bySemanticsLabel('I did it!'))
          .getSemanticsData();
      expect(
        data.flagsCollection.isEnabled.toBoolOrNull(),
        isTrue,
        reason: 'yesterday\u2019s completion does not count for today',
      );
      semantics.dispose();
      await disposeApp(tester);
    });

    test('every K04 token pair meets WCAG contrast in light and dark', () {
      const light = NestColors.light;
      const dark = NestColors.dark;
      final pairs = <String, (Color, Color)>{
        'light ink on kidSkyTop': (light.ink, light.kidSkyTop),
        'light ink on kidSkyBottom': (light.ink, light.kidSkyBottom),
        'light ink2 on kidSkyTop': (light.ink2, light.kidSkyTop),
        'light ink2 on kidSkyBottom': (light.ink2, light.kidSkyBottom),
        'light ink on surface': (light.ink, light.surface),
        'light coinInk on coinTint': (light.coinInk, light.coinTint),
        'light ink on peachTint': (light.ink, light.peachTint),
        'light onLeaf on leaf': (light.onLeaf, light.leaf),
        'dark ink on kidSkyTop': (dark.ink, dark.kidSkyTop),
        'dark ink on kidSkyBottom': (dark.ink, dark.kidSkyBottom),
        'dark ink2 on kidSkyTop': (dark.ink2, dark.kidSkyTop),
        'dark ink2 on kidSkyBottom': (dark.ink2, dark.kidSkyBottom),
        'dark ink on surface': (dark.ink, dark.surface),
        'dark coinInk on coinTint': (dark.coinInk, dark.coinTint),
        'dark ink on peachTint': (dark.ink, dark.peachTint),
        'dark onLeaf on leaf': (dark.onLeaf, dark.leaf),
      };
      for (final MapEntry(key: name, value: (a, b)) in pairs.entries) {
        expect(
          _contrast(a, b),
          greaterThanOrEqualTo(4.5),
          reason: '$name contrast',
        );
      }
    });
  });
}
