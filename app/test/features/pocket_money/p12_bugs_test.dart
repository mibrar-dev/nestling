// P12 Money ledger — Stage 6 adversarial bug tests (iteration 1).
//
// Findings P12-BUG-01/02/03/05 were skipped reproducers in iteration 1 and
// are now FIXED and UN-SKIPPED (see docs/screens/P12/2b_build_ui.md): the
// sheet validates instead of stripping separators, parses integer pence with
// a £1,000,000.00 ceiling, and the view stack no longer carries the extra
// header spacer. P12-BUG-04 stays skipped — it is a shared
// `NestSegmented` fix (SHARED_REQUEST.md), and P12 must not fork the shared
// control. The group at the bottom ("attacks that hold") is NOT skipped: it
// documents the adversarial probes that passed — rapid taps, deep links,
// restart persistence, timezone/BST, dark contrast, 320dp × 1.3, parse
// guards — so regressions are caught here.
//
// All probes ran without a simulator (stage rule): widget tests on the
// in-memory/file-backed Drift DB plus pure function tests.

import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pocket_money/data/pocket_money_repository_impl.dart';
import 'package:nestling/features/pocket_money/domain/next_payout.dart';
import 'package:nestling/features/pocket_money/presentation/widgets/money_edit_sheet.dart';

import '../../test_scope.dart';

/// Loads the bundled Inter/Nunito faces so the geometry probe reproduces the
/// design's own metrics (same pattern as `p06_bugs_test.dart`).
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

/// The ledger is longer than the viewport; one fling parks it at the end so
/// the row buttons, the footer and the lower history rows are built.
Future<void> _scrollToEnd(WidgetTester tester) async {
  await tester.fling(
    find.byType(Scrollable).first,
    const Offset(0, -1400),
    1200,
  );
  await tester.pumpAndSettle();
}

/// Drift write + watch-stream re-emission + SnackBar entry.
Future<void> _pumpPastWrite(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// Scrolls the row buttons into view, taps [label] and waits for the sheet.
Future<void> _openSheet(WidgetTester tester, String label) async {
  await _scrollToEnd(tester);
  await tester.tap(find.text(label));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Pumps [MoneyEditSheet] directly on a pushed route (so its
/// `Navigator.pop()` has somewhere to go) under the real theme, and records
/// every accepted submit. Returns the captured submits list.
Future<List<({int pence, String note})>> _pumpSheet(
  WidgetTester tester,
  MoneyEditSheetMode mode,
) async {
  final submits = <({int pence, String note})>[];
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      navigatorKey: navigator,
      home: const Scaffold(body: SizedBox.shrink()),
    ),
  );
  final sheet = mode == MoneyEditSheetMode.addMoney
      ? MoneyEditSheet.addMoney(
          onSubmit: (pence, note) => submits.add((pence: pence, note: note)),
        )
      : MoneyEditSheet.recordSpending(
          onSubmit: (pence, note) => submits.add((pence: pence, note: note)),
        );
  navigator.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: sheet),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return submits;
}

/// Enters [amount] into the amount field and taps the sheet CTA. Returns the
/// captured submit (null when the sheet rejected the input).
Future<({int pence, String note})?> _submitAmount(
  WidgetTester tester,
  MoneyEditSheetMode mode,
  String amount,
) async {
  final submits = await _pumpSheet(tester, mode);
  await tester.enterText(find.byType(TextField).first, amount);
  await tester.pump();
  await tester.tap(
    find.widgetWithText(
      NestButton,
      mode == MoneyEditSheetMode.addMoney ? 'Add money' : 'Record spending',
    ),
  );
  await tester.pumpAndSettle();
  return submits.isEmpty ? null : submits.single;
}

/// The newest ledger row of [type] in the in-memory DB, read outside the
/// widget-test fake clock.
Future<LedgerEntry?> _newestRow(AppDatabase db, String type) async {
  final rows = await db.select(db.ledgerEntries).get();
  final matches = rows.where((row) => row.type == type).toList()
    ..sort((a, b) => b.date.compareTo(a.date));
  return matches.isEmpty ? null : matches.first;
}

/// WCAG 2.x relative luminance.
double _luminance(Color color) {
  double channel(double value) => value <= 0.03928
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  // -- P12-BUG-01 ---------------------------------------------------------

  testWidgets(
    'P12-BUG-01: an unbounded amount is clamped to int64 and overflows the '
    'history row',
    (tester) async {
      final db = await setUpTestScope();
      await pumpAppRoute(tester, '/money');
      await _openSheet(tester, 'Add money');

      await tester.enterText(
        find.byType(TextField).first,
        '99999999999999999999999',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(NestButton, 'Add money').last);
      await _pumpPastWrite(tester);

      // The sheet accepted a 23-digit numpad mashtroke and the history row
      // cannot lay the resulting amount out (98 px RenderFlex overflow).
      expect(
        tester.takeException(),
        isNull,
        reason:
            'P12-BUG-01: the amount input must be bounded so the history '
            'row cannot overflow',
      );

      late LedgerEntry? stored;
      await tester.runAsync(() async {
        stored = await _newestRow(db, 'gift');
      });
      expect(
        stored?.amountPence ?? 0,
        lessThanOrEqualTo(100000000),
        reason:
            'P12-BUG-01: (double * 100).round() silently clamps to '
            'int64 max (9223372036854775807 p = £92 quadrillion)',
      );
      // The clamp also loses pence precision: int64 max pence renders as
      // '+£92233720368547760.00' (two pence short of the stored value).
      expect(find.textContaining('92233720368547760'), findsNothing);

      await disposeApp(tester);
    },
  );

  // -- P12-BUG-02 ---------------------------------------------------------

  testWidgets('P12-BUG-02: "1,50" is silently recorded as £150.00 (100x)', (
    tester,
  ) async {
    final submit = await _submitAmount(
      tester,
      MoneyEditSheetMode.recordSpending,
      '1,50',
    );

    // A comma-decimal keyboard (or a paste) types `1,50` for one pound
    // fifty. The greedier `replaceAll(RegExp('[^0-9.]'), '')` turns it
    // into 150 pounds. Correct behaviour: 150 pence, or reject the input
    // with the inline error and write nothing.
    expect(
      submit == null || submit.pence == 150,
      isTrue,
      reason:
          'P12-BUG-02: "1,50" was parsed as ${submit?.pence}p '
          '(£${(submit?.pence ?? 0) / 100}) — 100x the intended amount',
    );
    expect(tester.takeException(), isNull);
  });

  // -- P12-BUG-03 ---------------------------------------------------------

  testWidgets(
    'P12-BUG-03: "1.005" silently stores £1.00 (half-penny dropped)',
    (tester) async {
      final submit = await _submitAmount(
        tester,
        MoneyEditSheetMode.addMoney,
        '1.005',
      );

      // `(1.005 * 100) == 100.49999999999999`, and `round()` floors it to
      // 100p. Either round the decimal half up (101p) or reject amounts
      // with more than two decimals; never store the float artefact.
      expect(
        submit == null || submit.pence == 101,
        isTrue,
        reason: 'P12-BUG-03: "1.005" was parsed as ${submit?.pence}p',
      );
      expect(tester.takeException(), isNull);
    },
  );

  // -- P12-BUG-04 ---------------------------------------------------------

  testWidgets(
    'P12-BUG-04: six children at 320dp collapse the segment below the 44px '
    'tap target',
    (tester) async {
      final db = await setUpTestScope();
      for (final row in <({String id, String name})>[
        (id: 'mia', name: 'Maximilian-Alexander'),
        (id: 'noah', name: 'Noah'),
        (id: 'ava', name: 'Ava'),
        (id: 'ethan', name: 'Ethan'),
      ]) {
        await db
            .into(db.children)
            .insert(
              ChildrenCompanion.insert(
                id: row.id,
                familyId: Seed.familyId,
                nickname: row.name,
              ),
            );
      }
      await GetIt.instance<AppSession>().refresh();
      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const NestlingApp(initialRoute: '/money'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final handle = tester.ensureSemantics();
      for (final name in <String>[
        'Maya',
        'Leo',
        'Maximilian-Alexander',
        'Noah',
        'Ava',
        'Ethan',
      ]) {
        final rect = find.semantics
            .byLabel(name)
            .evaluate()
            .first
            .getSemanticsData()
            .rect;
        expect(
          rect.width,
          greaterThanOrEqualTo(NestDevice.tapParent),
          reason:
              'P12-BUG-04: the "$name" segment is ${rect.width} px wide '
              'at 320dp (six children, 5 gaps of 4 px, 4 px track padding)',
        );
      }
      handle.dispose();
      await disposeApp(tester);
    },
    // P12-BUG-04: minor — shared `NestSegmented` shrinks options below 44 px
    // with 6 children at 320dp. P12 must not fork the shared control, so
    // this one stays skipped pending the cross-screen fix filed in
    // docs/screens/P12/SHARED_REQUEST.md.
    skip: true,
  );

  // -- P12-BUG-05 ---------------------------------------------------------

  group('P12-BUG-05 — ORCHESTRATOR_NOTES geometry targets', () {
    setUpAll(_loadBundledFonts);

    testWidgets('P12-BUG-05: the whole stack sits 15-21px below the design', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      // ORCHESTRATOR_NOTES (12:08, overruling the stage-5 PASS): measured
      // off `P12-money.png` ÷3 at 390 wide — title centre 72, segmented
      // top 106, owed card top 173, goal card top 400, history card top
      // 504. The app renders 88 / 121 / 189 / 419 / 525: an extra 16 px
      // above the title (the `SizedBox(height: NestSpacing.s4)` between
      // `NestStatusBar` and `_PageTitle`) plus a few px inside the cards.
      final title = tester.getRect(find.text('Pocket money'));
      expect(
        title.center.dy,
        moreOrLessEquals(72, epsilon: 1.5),
        reason: 'P12-BUG-05: title centre is ${title.center.dy}',
      );

      final segmented = tester.getRect(find.byType(NestSegmented<String>));
      expect(
        segmented.top,
        moreOrLessEquals(106, epsilon: 1.5),
        reason: 'P12-BUG-05: segmented top is ${segmented.top}',
      );

      final cards = find.byType(NestCard);
      expect(
        tester.getRect(cards.at(0)).top,
        moreOrLessEquals(173, epsilon: 1.5),
        reason:
            'P12-BUG-05: owed card top is '
            '${tester.getRect(cards.at(0)).top}',
      );
      expect(
        tester.getRect(cards.at(1)).top,
        moreOrLessEquals(400, epsilon: 1.5),
        reason:
            'P12-BUG-05: goal card top is '
            '${tester.getRect(cards.at(1)).top}',
      );
      expect(
        tester.getRect(cards.at(2)).top,
        moreOrLessEquals(504, epsilon: 1.5),
        reason:
            'P12-BUG-05: history card top is '
            '${tester.getRect(cards.at(2)).top}',
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  // -- attacks that hold --------------------------------------------------

  group('P12 attacks that hold', () {
    testWidgets('the amount sheet maps 2dp pounds to exact pence', (
      tester,
    ) async {
      // Integer pence: the classic float traps (0.29, 1.15) must not drift.
      for (final scenario in <({String input, int pence})>[
        (input: '5.00', pence: 500),
        (input: '£5', pence: 500),
        (input: '.5', pence: 50),
        (input: '0.01', pence: 1),
        (input: '1.15', pence: 115),
        (input: '999.99', pence: 99999),
      ]) {
        final submit = await _submitAmount(
          tester,
          MoneyEditSheetMode.addMoney,
          scenario.input,
        );
        expect(
          submit?.pence,
          scenario.pence,
          reason: '"${scenario.input}" must be ${scenario.pence}p',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('the amount sheet rejects unparseable and zero amounts', (
      tester,
    ) async {
      for (final input in <String>['', 'abc', '0', '0.00', '1.2.3', '.']) {
        final submit = await _submitAmount(
          tester,
          MoneyEditSheetMode.recordSpending,
          input,
        );
        expect(submit, isNull, reason: '"$input" must not reach the bloc');
        expect(
          find.textContaining('Enter an amount'),
          findsOneWidget,
          reason: '"$input" must show the inline error',
        );
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('double taps on the sheet and the sheet opener write once', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await pumpAppRoute(tester, '/money');
      await _scrollToEnd(tester);

      // Two same-frame taps on "Add money" must not stack two sheets.
      final add = find.text('Add money');
      await tester.tap(add);
      await tester.tap(add);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(MoneyEditSheet), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '5.00');
      await tester.enterText(find.byType(TextField).last, 'Double probe');
      await tester.pump();
      final save = find.widgetWithText(NestButton, 'Add money').last;
      await tester.tap(save);
      await tester.pump(const Duration(milliseconds: 120));
      // The sheet is mid-pop; a fast second press must not double-write.
      await tester.tap(save, warnIfMissed: false);
      await _pumpPastWrite(tester);

      late List<LedgerEntry> writes;
      await tester.runAsync(() async {
        final rows = await db.select(db.ledgerEntries).get();
        writes = rows.where((row) => row.note == 'Double probe').toList();
      });
      expect(writes, hasLength(1));
      await disposeApp(tester);
    });

    testWidgets('six children stay in creation order and fit at 390dp', (
      tester,
    ) async {
      final db = await setUpTestScope();
      for (final row in <({String id, String name})>[
        (id: 'mia', name: 'Maximilian-Alexander'),
        (id: 'noah', name: 'Noah'),
        (id: 'ava', name: 'Ava'),
        (id: 'ethan', name: 'Ethan'),
      ]) {
        await db
            .into(db.children)
            .insert(
              ChildrenCompanion.insert(
                id: row.id,
                familyId: Seed.familyId,
                nickname: row.name,
              ),
            );
      }
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/money');

      const order = <String>[
        'Maya',
        'Leo',
        'Maximilian-Alexander',
        'Noah',
        'Ava',
        'Ethan',
      ];
      // The segment is one horizontal row: creation order is left to right.
      for (var i = 1; i < order.length; i++) {
        expect(
          tester.getTopLeft(find.text(order[i - 1])).dx,
          lessThan(tester.getTopLeft(find.text(order[i])).dx),
          reason: '${order[i - 1]} must sit left of ${order[i]}',
        );
      }
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a long UK name survives 320dp x 1.3 in the hero', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await db
          .into(db.children)
          .insert(
            ChildrenCompanion.insert(
              id: 'max',
              familyId: Seed.familyId,
              nickname: 'Maximilian-Alexander',
            ),
          );
      await GetIt.instance<AppSession>().refresh();
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const NestlingApp(initialRoute: '/money'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Maximilian-Alexander'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Maximilian-Alexander is owed'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a child with no ledger rows shows £0.00 and No history yet', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await db
          .into(db.children)
          .insert(
            ChildrenCompanion.insert(
              id: 'ada',
              familyId: Seed.familyId,
              nickname: 'Ada',
            ),
          );
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/money');
      await tester.tap(find.text('Ada'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Ada is owed'), findsOneWidget);
      expect(find.text('£0.00'), findsOneWidget);
      expect(find.text('No history yet'), findsOneWidget);
      expect(find.text('Add money'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a single-child family renders one segment', (tester) async {
      final db = await setUpTestScope();
      await (db.delete(db.children)..where((c) => c.id.equals('leo'))).go();
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/money');

      expect(find.text('Maya is owed'), findsOneWidget);
      expect(find.text('Leo'), findsNothing);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a £999.99 top-up stores 99999p and toasts', (tester) async {
      final db = await setUpTestScope();
      await pumpAppRoute(tester, '/money');
      await _openSheet(tester, 'Add money');
      await tester.enterText(find.byType(TextField).first, '£999.99');
      await tester.pump();
      await tester.tap(find.widgetWithText(NestButton, 'Add money').last);
      await _pumpPastWrite(tester);

      expect(find.text('Added £999.99 for Maya'), findsOneWidget);
      late LedgerEntry? stored;
      await tester.runAsync(() async {
        stored = await _newestRow(db, 'gift');
      });
      expect(stored?.amountPence, 99999);
      await disposeApp(tester);
    });

    testWidgets('rapid child switching ends on the last tapped child', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Leo'));
        await tester.pump(const Duration(milliseconds: 10));
        await tester.tap(find.text('Maya'));
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.tap(find.text('Leo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Leo is owed'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('back from /payout restores the ledger', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');
      await tester.tap(find.text('Payout time'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(pushedPath(tester), '/payout');

      Navigator.of(tester.element(find.byType(Scaffold).last)).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(pushedPath(tester), '/money');
      expect(find.text('Maya is owed'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('kid-mode deep link stops at the parental gate', (
      tester,
    ) async {
      await setUpTestScope();
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/money');
      expect(currentPath(tester), '/parental-gate');
      expect(find.text('Pocket money'), findsNothing);
      await disposeApp(tester);
    });

    testWidgets('a fresh (never onboarded) deep link lands on /welcome', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.fresh(db);
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/money');
      expect(currentPath(tester), '/welcome');
      await disposeApp(tester);
    });

    testWidgets('empty state: Add a child is a tappable semantic control', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/money');
      final handle = tester.ensureSemantics();

      final node = tester.getSemantics(find.text('Add a child'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(pushedPath(tester), '/add-children');
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('dark mode renders the same ledger copy', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money', theme: ThemeMode.dark);

      expect(find.text('Maya is owed'), findsOneWidget);
      expect(find.text('£4.20'), findsOneWidget);
      expect(find.text('Lego Friends set — £24.99'), findsOneWidget);
      await _scrollToEnd(tester);
      expect(find.text('Add money'), findsOneWidget);
      expect(find.text('Record spending'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    test('light and dark P12 text pairs pass 4.5:1', () {
      for (final theme in <ThemeData>[NestTheme.light(), NestTheme.dark()]) {
        final tokens = theme.extension<NestTokens>()!;
        for (final pair in <(String, Color, Color)>[
          ('onHero2/heroBg', tokens.onHero2, tokens.heroBg),
          ('onHero/heroBg', tokens.onHero, tokens.heroBg),
          ('ink/surface', tokens.ink, tokens.surface),
          ('ink2/surface', tokens.ink2, tokens.surface),
          ('ink/paper', tokens.ink, tokens.paper),
          ('ink2/paper', tokens.ink2, tokens.paper),
          ('danger/paper', tokens.danger, tokens.paper),
        ]) {
          expect(
            _contrast(pair.$2, pair.$3),
            greaterThanOrEqualTo(4.5),
            reason: '${pair.$1} fails contrast on ${theme.brightness}',
          );
        }
      }
    });

    test('BST boundaries and payout labels render in Europe/London', () {
      // 23:30 UTC on 24 Oct 2026 is 00:30 BST on 25 Oct (BST ends 25 Oct at
      // 02:00 local = 01:00 UTC), so the day flips before the wall clock.
      expect(
        formatDay(DateTime.utc(2026, 10, 24, 23, 30), 'Europe/London'),
        'Sun 25 Oct',
      );
      expect(
        formatTime(DateTime.utc(2026, 10, 24, 23, 30), 'Europe/London'),
        '12:30am',
      );
      // After the fall-back (01:00 UTC), the same instant is GMT.
      expect(
        formatTime(DateTime.utc(2026, 10, 25, 1, 30), 'Europe/London'),
        '1:30am',
      );
      expect(
        payoutLabel(
          payoutWeekday: 6,
          nowUtc: DateTime.utc(2026, 10, 4, 12),
          zoneId: 'Europe/London',
        ),
        'Sat 10 Oct',
      );
      // Saturday 23:59 local still names today.
      expect(
        payoutLabel(
          payoutWeekday: 6,
          nowUtc: DateTime.utc(2026, 10, 3, 22, 59),
          zoneId: 'Europe/London',
        ),
        'Sat 3 Oct',
      );
    });

    test(
      'gift and spend rows survive a database restart (file-backed)',
      () async {
        final dir = Directory.systemTemp.createTempSync('p12_bugs_restart');
        final file = File('${dir.path}/nestling.db');
        try {
          var db = AppDatabase(NativeDatabase(file));
          await Seed.demo(db);
          var repository = PocketMoneyRepositoryImpl(db: db);
          await repository.addMoney(
            childId: 'maya',
            amountPence: 500,
            note: 'Restart gift',
          );
          await repository.recordSpending(
            childId: 'maya',
            amountPence: 150,
            note: 'Restart spend',
          );
          await db.close();

          db = AppDatabase(NativeDatabase(file));
          repository = PocketMoneyRepositoryImpl(db: db);
          final data = await repository.watchLedgerData().first;
          final rows = data.entriesFor('maya');
          expect(
            rows.any((row) => row.note == 'Restart gift' && row.type == 'gift'),
            isTrue,
          );
          expect(
            rows.any(
              (row) =>
                  row.note == 'Restart spend' &&
                  row.type == 'spend' &&
                  row.amountPence == -150,
            ),
            isTrue,
          );
          // Gifts/spends never change the owed figure.
          expect(data.owedFor('maya')?.totalPence, 420);
          await db.close();
        } finally {
          dir.deleteSync(recursive: true);
        }
      },
    );

    testWidgets('Asia/Dubai family zone: labels float, history keeps London', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await (db.update(db.families)..where((f) => f.id.equals(Seed.familyId)))
          .write(const FamiliesCompanion(timeZone: Value('Asia/Dubai')));
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/money');

      // The payout rule floats with the family zone; stored rows keep their
      // own zone and are named when it differs. Expected label computed with
      // the same pure function the view uses (never a frozen date).
      final expected = payoutLabel(
        payoutWeekday: 6,
        nowUtc: DateTime.now().toUtc(),
        zoneId: 'Asia/Dubai',
      );
      final breakdown = tester
          .widget<Text>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  (widget.data ?? '').startsWith('Weekly base'),
            ),
          )
          .data!;
      expect(breakdown, endsWith('Next payout $expected'));
      expect(find.textContaining('(London)'), findsWidgets);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });
}
