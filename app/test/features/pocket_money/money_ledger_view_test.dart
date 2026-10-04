import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_ledger_data.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/domain/next_payout.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';
import 'package:nestling/features/pocket_money/presentation/widgets/money_edit_sheet.dart';

import '../../test_scope.dart';

/// The hero breakdown's fixed half: `Weekly base £3.00 + quests £1.20 ·`
/// (U+00B7 middle dot). The payout date after it comes from the clock
/// (`payoutLabel`), so the tests assert the fixed copy plus the domain
/// value rather than freezing "Sat 3 Oct" — only the seed anchor is pinned,
/// not the wall clock.
const String _breakdownPrefix =
    'Weekly base £3.00 + quests £1.20 · Next payout ';

String _expectedPayout() {
  return payoutLabel(
    payoutWeekday: 6,
    nowUtc: appNowUtc(),
    zoneId: 'Europe/London',
  );
}

/// Every ledger row the seeded demo must render, newest first (DATA OVER
/// MOCKS: these come from `Seed.demo`, not from the design PNG).
const List<String> _historyCopy = <String>[
  'Weekly pocket money',
  '+£3.00',
  'Quest bonus · Put the bins out',
  '+12p · Approved',
  '+£0.12',
  'Quest bonus · Hoover the stairs',
  '+£0.40',
  'Quest bonus · Help with the washing',
  'Jar → Lego fund',
  'To savings goal',
  '+£5.50',
  'Spent · Comic',
  'Recorded by Mum',
  '−£2.00',
  'Quest bonus · Tidy your bedroom',
  'Birthday money → Lego fund',
  '+£10.00',
  'Birthday money (added by Mum)',
  'Paid · Sat 26 Sep',
  'Cash from Mum',
  '£3.80',
];

Future<void> _pumpMoney(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double textScale = 1,
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  if (textScale != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(const NestlingApp(initialRoute: '/money'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
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

/// Back to the top — a ListView disposes what it scrolls past, so the hero
/// only exists again once the scroll position returns to 0.
Future<void> _scrollToStart(WidgetTester tester) async {
  await tester.fling(
    find.byType(Scrollable).first,
    const Offset(0, 1400),
    1200,
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpPastWrite(WidgetTester tester) async {
  // Drift write + watch-stream re-emission + SnackBar entry.
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  group('P12 Money ledger (light, demo seed)', () {
    testWidgets('renders the seeded ledger copy', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      expect(find.text('Pocket money'), findsOneWidget);
      expect(find.text('Maya is owed'), findsOneWidget);
      expect(find.text('£4.20'), findsOneWidget);

      final breakdown = tester
          .widget<Text>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is Text &&
                  (widget.data ?? '').startsWith(_breakdownPrefix),
            ),
          )
          .data!;
      expect(
        breakdown,
        '$_breakdownPrefix${_expectedPayout()}',
        reason: 'the hero breakdown must read the payout day from the bloc',
      );

      expect(find.text('Payout time'), findsOneWidget);
      // Goal card — em dash U+2014, middle dot U+00B7.
      expect(find.text('Lego Friends set — £24.99'), findsOneWidget);
      expect(find.text('£15.50 saved · 62%'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _scrollToEnd(tester);
      for (final copy in _historyCopy) {
        expect(find.text(copy), findsWidgets, reason: 'missing "$copy"');
      }
      expect(find.text('Add money'), findsOneWidget);
      expect(find.text('Record spending'), findsOneWidget);
      expect(
        find.text('Nestling keeps track — the real money stays with you.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('segment switches the child and re-renders the hero', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      expect(find.text('Maya is owed'), findsOneWidget);
      await tester.tap(find.text('Leo'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Leo is owed'), findsOneWidget);
      expect(find.text('£2.10'), findsOneWidget);
      expect(find.text('Maya is owed'), findsNothing);
      // Leo has no savings goal: the card is omitted, not stubbed.
      expect(find.text('Lego Friends set — £24.99'), findsNothing);
      expect(find.text('History'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('Payout time pushes /payout', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      await tester.tap(find.text('Payout time'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(pushedPath(tester), '/payout');
      await disposeApp(tester);
    });

    testWidgets('Add money writes a ledger row and toasts', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      await _scrollToEnd(tester);
      await tester.tap(find.text('Add money'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Add money for Maya'), findsOneWidget);
      expect(find.text('Amount'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '£5.00');
      await tester.enterText(find.byType(TextField).last, 'Test top-up');
      await tester.pump();

      await tester.tap(find.widgetWithText(NestButton, 'Add money').last);
      await _pumpPastWrite(tester);

      expect(find.text('Added £5.00 for Maya'), findsOneWidget);
      expect(find.text('Add money for Maya'), findsNothing);
      await _scrollToEnd(tester);
      expect(find.text('Test top-up'), findsOneWidget);
      expect(find.text('+£5.00'), findsWidgets);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('Record spending validates the amount, then writes', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      await _scrollToEnd(tester);
      await tester.tap(find.text('Record spending'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Record spending for Maya'), findsOneWidget);

      // Unparseable → inline error, sheet stays open, nothing written.
      await tester.tap(find.widgetWithText(NestButton, 'Record spending').last);
      await tester.pump();
      expect(find.text('Enter an amount like £1.00'), findsOneWidget);
      expect(find.text('Record spending for Maya'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '2');
      await tester.pump();
      await tester.tap(find.widgetWithText(NestButton, 'Record spending').last);
      await _pumpPastWrite(tester);

      expect(find.text('Spent £2.00 recorded'), findsOneWidget);
      await _scrollToEnd(tester);
      // Empty note falls back to readable copy, never an empty row title.
      expect(find.text('Spent · Something else'), findsOneWidget);
      expect(find.text('−£2.00'), findsWidgets);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('sheet close is reachable and dismisses it', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      await _scrollToEnd(tester);
      await tester.tap(find.text('Add money'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(MoneyEditSheet), findsOneWidget);

      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is NestIcon && widget.assetName == NestIcons.close,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MoneyEditSheet), findsNothing);
      expect(find.text('Add money for Maya'), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('dark mode renders the same ledger copy', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money', theme: ThemeMode.dark);

      expect(find.text('Maya is owed'), findsOneWidget);
      expect(find.text('£4.20'), findsOneWidget);
      expect(find.text('Lego Friends set — £24.99'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _scrollToEnd(tester);
      expect(find.text('Add money'), findsOneWidget);
      expect(find.text('Record spending'), findsOneWidget);
      expect(find.text('Paid · Sat 26 Sep'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P12 empty state (no children)', () {
    testWidgets('offers Add a child and routes to /add-children', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/money');

      expect(find.text('No pocket money yet'), findsOneWidget);
      expect(
        find.text('Add a child to start tracking pocket money.'),
        findsOneWidget,
      );
      expect(find.text('Add a child'), findsOneWidget);
      // No hero / goal / history / row buttons in this state.
      expect(find.text('Maya is owed'), findsNothing);
      expect(find.text('History'), findsNothing);
      expect(find.text('Record spending'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Add a child'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(pushedPath(tester), '/add-children');

      await disposeApp(tester);
    });
  });

  group('P12 copy audit (code points)', () {
    testWidgets("uses the design's typographic characters", (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      List<String> texts() => tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data ?? '')
          .toList();

      // The goal title uses U+2014 (em dash), never ASCII hyphen-minus.
      final goalTitle = texts().firstWhere(
        (text) => text.startsWith('Lego Friends set'),
      );
      expect(goalTitle.codeUnits, contains(0x2014));
      expect(goalTitle.codeUnits, isNot(contains(0x2D)));
      for (final text in texts()) {
        expect(
          text.contains('-'),
          isFalse,
          reason: 'ASCII hyphen in "$text" — the design uses U+2014/U+2212',
        );
      }
      expect(
        texts().where((text) => text.contains('·')).length,
        greaterThan(2),
      );
      expect(texts(), contains('+12p · Approved'));

      await _scrollToEnd(tester);
      expect(
        texts(),
        contains('Nestling keeps track — the real money stays with you.'),
      );
      expect(texts(), contains('Spent · Comic'));
      expect(texts(), contains('−£2.00'));
      expect(texts(), contains('Birthday money → Lego fund'));
      expect(texts(), contains('Paid · Sat 26 Sep'));
      expect(texts(), contains('£3.80'));

      await disposeApp(tester);
    });
  });

  group('P12 accessibility', () {
    /// Every interactive control must expose `SemanticsAction.tap`.
    void expectTappable(SemanticsFinder finder) {
      final nodes = finder.evaluate().toList();
      expect(nodes, isNotEmpty, reason: '$finder matched no semantics node');
      for (final node in nodes) {
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: '$finder must expose SemanticsAction.tap',
        );
      }
    }

    /// Semantics rect of the control — the frame an assistive technology's
    /// target actually covers (owner rule: ≥ 44 px in parent mode).
    double tapHeight(SemanticsFinder finder) {
      final heights = finder
          .evaluate()
          .map((node) => node.getSemanticsData().rect.height)
          .toList();
      expect(heights, isNotEmpty, reason: '$finder matched no semantics node');
      return heights.reduce((a, b) => a > b ? a : b);
    }

    /// `SemanticsAction.tap` on the first matching node.
    void performTap(WidgetTester tester, SemanticsFinder finder) {
      tester.semantics.performAction(finder.first, SemanticsAction.tap);
    }

    testWidgets('every control exposes a tap action that changes state', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      // Segmented option → the hero re-renders for Leo (real bloc state).
      final leoOption = find.semantics.byLabel('Leo');
      expectTappable(leoOption);
      performTap(tester, leoOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Leo is owed'), findsOneWidget);
      expect(find.text('£2.10'), findsOneWidget);

      // Back to Maya.
      performTap(tester, find.semantics.byLabel('Maya'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Maya is owed'), findsOneWidget);
      expect(find.text('£4.20'), findsOneWidget);

      await _scrollToEnd(tester);
      final addMoney = find.semantics.byLabel('Add money');
      expectTappable(addMoney);
      performTap(tester, addMoney);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(MoneyEditSheet), findsOneWidget);

      final close = find.semantics.byLabel('Close');
      expectTappable(close);
      performTap(tester, close);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(MoneyEditSheet), findsNothing);

      final spending = find.semantics.byLabel('Record spending');
      expectTappable(spending);
      performTap(tester, spending);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Record spending for Maya'), findsOneWidget);

      // The sheet CTA writes through the bloc (real DB change). Its label
      // duplicates the row button behind the scrim, so target the node by
      // element instead of by label.
      await tester.enterText(find.byType(TextField).first, '1');
      await tester.pump();
      final ctaNode = tester.getSemantics(
        find.widgetWithText(NestButton, 'Record spending').last,
      );
      expect(ctaNode.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      // `performAction` on that one node — the label alone cannot select it
      // because the row button behind the scrim carries the same text.
      tester.semantics.performAction(
        find.semantics.byPredicate((node) => node.id == ctaNode.id),
        SemanticsAction.tap,
      );
      await _pumpPastWrite(tester);
      expect(find.text('Spent £1.00 recorded'), findsOneWidget);

      // The payout button last, so the pushed route is the end state. Its
      // node carries the hero card's merged label (the same merge the
      // shipped P08 banner shows), so match on the label it contains.
      await _scrollToStart(tester);
      final payout = find.semantics.byLabel(RegExp('Payout time for Maya'));
      expectTappable(payout);
      performTap(tester, payout);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(pushedPath(tester), '/payout');

      expect(tester.takeException(), isNull);
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('interactive controls keep 44 px tap targets', (tester) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      for (final option in const <String>['Maya', 'Leo']) {
        expect(
          tapHeight(find.semantics.byLabel(option)),
          greaterThanOrEqualTo(NestDevice.tapParent),
          reason: 'segmented option "$option" is below the 44 px target',
        );
      }
      expect(
        tapHeight(find.semantics.byLabel(RegExp('Payout time for Maya'))),
        greaterThanOrEqualTo(NestDevice.tapParent),
      );

      await _scrollToEnd(tester);
      expect(
        tapHeight(find.semantics.byLabel('Add money')),
        greaterThanOrEqualTo(NestDevice.tapParent),
      );
      expect(
        tapHeight(find.semantics.byLabel('Record spending')),
        greaterThanOrEqualTo(NestDevice.tapParent),
      );

      performTap(tester, find.semantics.byLabel('Add money'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester
            .getSize(find.widgetWithText(NestButton, 'Add money').last)
            .height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );
      expect(
        tapHeight(find.semantics.byLabel('Close')),
        greaterThanOrEqualTo(NestDevice.tapParent),
      );
      expect(tester.takeException(), isNull);

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('no overflow at 320 wide and text scale 1.3', (tester) async {
      await setUpTestScope();
      await _pumpMoney(tester, size: const Size(320, 844), textScale: 1.3);

      expect(find.text('Maya is owed'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _scrollToEnd(tester);
      expect(find.text('Add money'), findsOneWidget);
      expect(find.text('Record spending'), findsOneWidget);
      expect(
        find.text('Nestling keeps track — the real money stays with you.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P12 sheet validation (P12-BUG-01/02/03, finding 5)', () {
    testWidgets('rejects a comma decimal, a third decimal and a numpad mash', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      await _scrollToEnd(tester);
      await tester.tap(find.text('Add money'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // One sheet session: a rejected amount never closes it, so every bad
      // input is probed without re-opening.
      for (final input in const <String>[
        '1,50', // a comma-decimal keyboard: never £150.00
        '1.005', // a third decimal: never a floored half-penny
        '99999999999999999999999', // a 23-digit mash: never int64 max
        '99999999', // £99,999,999 — over the £1,000,000.00 ceiling
      ]) {
        await tester.enterText(find.byType(TextField).first, input);
        await tester.pump();
        await tester.tap(find.widgetWithText(NestButton, 'Add money').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          find.textContaining('Enter an amount'),
          findsOneWidget,
          reason: '"$input" must show the inline error and stay in the sheet',
        );
        expect(
          find.text('Add money for Maya'),
          findsOneWidget,
          reason: '"$input" must never write a row',
        );
        // Finding 6: nothing was submitted, so the success toast must never
        // be armed — the parent is told the amount was not accepted, not
        // that the money was added.
        expect(find.textContaining('Added £'), findsNothing);
      }

      // No `gift` row was written by any of the four inputs.
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await _scrollToStart(tester);
      expect(find.textContaining('9223372036854'), findsNothing);
      expect(find.textContaining('+£999,999'), findsNothing);
      expect(find.textContaining('+£15'), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the inline error is announced by VoiceOver / TalkBack', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      await _scrollToEnd(tester);
      await tester.tap(find.text('Add money'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.widgetWithText(NestButton, 'Add money').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Finding 5: the error appears only after a tap, so without a live
      // region the screen reader never says why the sheet stayed open.
      //
      // Finding 2 (iteration 2 review): the shared
      // `NestTextField.errorText` owns that live region now — its inner
      // Text is `ExcludeSemantics`, so the message is announced once,
      // through the labelled node.
      final data = tester
          .getSemantics(
            find.bySemanticsLabel('Enter an amount like £1.00').first,
          )
          .getSemanticsData();
      expect(data.flagsCollection.isLiveRegion, isTrue);
      expect(find.text('Enter an amount like £1.00'), findsOneWidget);
      // …and it belongs to the Amount input, never detached under Note.
      expect(
        tester.getRect(find.text('Enter an amount like £1.00')).top,
        lessThan(tester.getRect(find.text('Note')).top),
        reason: 'the error row belongs to the Amount field that was rejected',
      );
      expect(tester.takeException(), isNull);

      handle.dispose();
      await disposeApp(tester);
    });

    // Finding 3 (iteration 2 review): the armed confirmation carries the
    // child id, so a write confirmed after the parent switched children is
    // retired instead of resurfacing on the next write. The write is gated
    // (a fake repository) because the real one lands within the same pump.
    testWidgets('a write confirmed after a child switch names its own child', (
      tester,
    ) async {
      await setUpTestScope();
      final gate = _GatedLedgerRepository(
        GetIt.instance<PocketMoneyRepository>(),
      );
      await _useRepository(gate);
      await pumpAppRoute(tester, '/money');

      await _scrollToEnd(tester);
      await tester.tap(find.text('Add money'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField).first, '5.00');
      await tester.enterText(find.byType(TextField).last, 'Switch probe');
      await tester.pump();
      await tester.tap(find.widgetWithText(NestButton, 'Add money').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The sheet is closed but the write has not reached the database yet —
      // the parent switches children in that window.
      expect(gate.writes, 1);
      expect(find.textContaining('Added £'), findsNothing);
      await _scrollToStart(tester);
      await tester.tap(find.text('Leo'));
      await tester.pump();
      expect(find.text('Leo is owed'), findsOneWidget);

      // Release the write: the ledger stream re-emits for Maya, but the armed
      // confirmation belonged to Maya while Leo is the selected child, so it
      // is retired, not announced.
      gate.releaseAll();
      await _pumpPastWrite(tester);
      expect(find.textContaining('Added £'), findsNothing);

      // …and it must not resurface on the next write, which announces Leo.
      await _scrollToEnd(tester);
      await tester.tap(find.text('Add money'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.enterText(find.byType(TextField).first, '1.00');
      await tester.pump();
      await tester.tap(find.widgetWithText(NestButton, 'Add money').last);
      await tester.pump();
      gate.releaseAll();
      await _pumpPastWrite(tester);
      expect(find.text('Added £1.00 for Leo'), findsOneWidget);
      expect(find.text('Added £5.00 for Maya'), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });
}

/// Holds every ledger write until the test releases it, so "the parent
/// switched children before the stream round-tripped" is a reachable state
/// rather than a race. Everything else is the real Drift repository, so the
/// rows the release produces are read back from the real tables.
class _GatedLedgerRepository implements PocketMoneyRepository {
  _GatedLedgerRepository(this._inner);

  final PocketMoneyRepository _inner;
  final List<Future<void> Function()> _held = <Future<void> Function()>[];

  /// How many writes are currently being held.
  int get writes => _held.length;

  void releaseAll() {
    final pending = _held.toList(growable: false);
    _held.clear();
    for (final write in pending) {
      unawaited(write());
    }
  }

  void _hold(Future<void> Function() write) {
    _held.add(write);
  }

  @override
  Future<void> addMoney({
    required String childId,
    required int amountPence,
    required String note,
  }) async {
    final done = Completer<void>();
    _hold(() async {
      await _inner.addMoney(
        childId: childId,
        amountPence: amountPence,
        note: note,
      );
      done.complete();
    });
    await done.future;
  }

  @override
  Future<void> recordSpending({
    required String childId,
    required int amountPence,
    required String note,
  }) async {
    final done = Completer<void>();
    _hold(() async {
      await _inner.recordSpending(
        childId: childId,
        amountPence: amountPence,
        note: note,
      );
      done.complete();
    });
    await done.future;
  }

  @override
  Stream<MoneyLedgerData> watchLedgerData() => _inner.watchLedgerData();

  @override
  Future<List<PocketMoneyEntry>> getItems() => _inner.getItems();

  @override
  Stream<List<PocketMoneyEntry>> watchItems() => _inner.watchItems();

  @override
  Stream<List<PocketMoneyEntry>> watchLedger(String childId) =>
      _inner.watchLedger(childId);

  @override
  Future<OwedSummary> owed(String childId) => _inner.owed(childId);

  @override
  Stream<OwedSummary> watchOwed(String childId) => _inner.watchOwed(childId);

  @override
  Future<void> recordPayout({
    required String childId,
    required int amountPence,
    int savingsMovePence = 0,
    String? goalId,
  }) => _inner.recordPayout(
    childId: childId,
    amountPence: amountPence,
    savingsMovePence: savingsMovePence,
    goalId: goalId,
  );

  @override
  Stream<PocketMoneySetup> watchSetup() => _inner.watchSetup();

  @override
  Future<void> setMode(String mode) => _inner.setMode(mode);

  @override
  Future<void> setPayoutDay(int day) => _inner.setPayoutDay(day);

  @override
  Future<void> setWeeklyBasePence(String childId, int pence) =>
      _inner.setWeeklyBasePence(childId, pence);
}

/// The route builds its bloc through `GetIt.instance<PocketMoneyBloc>()`, so
/// the swap must happen before the pump.
Future<void> _useRepository(PocketMoneyRepository repository) async {
  await GetIt.instance.unregister<PocketMoneyRepository>();
  GetIt.instance.registerSingleton<PocketMoneyRepository>(repository);
}
