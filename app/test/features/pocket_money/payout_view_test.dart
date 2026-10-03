// P13 · Payout (parent) — the view's copy, semantics and interactions.
//
// Everything here pumps the real app at `/payout` on the real in-memory
// Drift database (`Seed.demo`), so the amounts, the weekday and the goal come
// from the seed — never from the design PNG (DATA OVER MOCKS: Maya £4.20,
// Leo £2.10, `payoutDay` 6 = Saturday, goal `goal-lego` on Maya).
//
// Cover contract: copy character-for-character against
// `design/html-source/screens/P13-payout.html`, every control operable by
// VoiceOver/TalkBack (`SemanticsAction.tap` → real state/DB change), the
// scrim dismiss to `/money`, the proven write, the states the happy path
// misses, and the 320 px / text-scale-1.3 / dark reflow. No simulator here.

import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_child.dart';
import 'package:nestling/features/pocket_money/presentation/views/payout_view.dart';
import 'package:nestling/features/pocket_money/presentation/widgets/payout_sheet.dart';

import '../../test_scope.dart';

/// Design copy, verbatim from `P13-payout.html`. ASCII 0x27 apostrophes and
/// U+00B7 middle dots exactly as the source writes them.
const String kSubCopy = "Tick once you've handed over the cash";
const String kCtaCopy = 'Mark as paid & start the celebration';
const String kCaptionCopy =
    'Your children will see a payout celebration next time they open '
    'Nestling.';
const String kSaveCopy = "Move £1.00 of Maya's to her Lego fund";
const String kSaveLabel = "Move one pound of Maya's money to savings";

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Past a repository write: the watch stream needs a round trip.
Future<void> _pumpPastWrite(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
  await _settle(tester);
}

/// `/payout` reached the way a parent reaches it — pushed on top of
/// `/money` — so the scrim pop and the post-write pop have something to pop
/// (launched as the initial route there is nothing to pop; see the view's
/// `_goBack`).
Future<void> _pushPayout(WidgetTester tester) async {
  await tester.tap(find.text('Payout time'));
  await _settle(tester);
  expect(pushedPath(tester), '/payout');
}

// NOTE: the in-memory Drift DB is never closed — `test_scope.dart` keeps
// `AppSession`'s watch subscription alive on purpose and closing it hangs the
// teardown.
Future<void> _pumpPayout(
  WidgetTester tester, {
  bool seedDemo = true,
  ThemeMode theme = ThemeMode.light,
  Size size = const Size(390, 844),
  double textScale = 1,
  bool fromLedger = false,
}) async {
  await setUpTestScope(seedDemo: seedDemo);
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  if (textScale != 1) {
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }
  await pumpAppRoute(tester, fromLedger ? '/money' : '/payout', theme: theme);
  if (fromLedger) await _pushPayout(tester);
}

SemanticsNode _node(WidgetTester tester, String label) =>
    tester.getSemantics(find.bySemanticsLabel(label).first);

/// State flags read the non-deprecated way.
bool _isChecked(String label, WidgetTester tester) =>
    _node(tester, label).getSemanticsData().flagsCollection.isChecked ==
    CheckedState.isTrue;
bool _isToggled(String label, WidgetTester tester) =>
    _node(tester, label).getSemanticsData().flagsCollection.isToggled ==
    Tristate.isTrue;
bool _isEnabled(String label, WidgetTester tester) =>
    _node(tester, label).getSemanticsData().flagsCollection.isEnabled ==
    Tristate.isTrue;

void main() {
  group('P13 payout — copy and content', () {
    testWidgets('renders the design copy with database amounts', (
      tester,
    ) async {
      await _pumpPayout(tester);

      // Sheet title: the weekday comes from `families.payout_day` (6).
      expect(find.text('Saturday payout'), findsOneWidget);
      expect(find.text(kSubCopy), findsOneWidget);

      // Children in CREATION order (Maya, then Leo), never alphabetical.
      final maya = tester.getTopLeft(find.text('Maya'));
      final leo = tester.getTopLeft(find.text('Leo'));
      expect(maya.dy, lessThan(leo.dy));
      expect(maya.dx, closeTo(leo.dx, 0.01), reason: 'one 20 px gutter');

      // Amounts from `Seed.demo`, never hard-coded.
      expect(find.text('Weekly + quests · £4.20'), findsOneWidget);
      expect(find.text('Weekly + quests · £2.10'), findsOneWidget);
      expect(find.text(kSaveCopy), findsOneWidget);
      expect(find.text(kCtaCopy), findsOneWidget);
      expect(find.text(kCaptionCopy), findsOneWidget);

      // The dimmed ledger behind the scrim keeps the P12 chrome.
      expect(find.text('Pocket money'), findsOneWidget);
      expect(
        find.text('Maya is owed £4.20 · Leo is owed £2.10'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the saverow hides when no child has a savings goal', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await db.transaction(() async {
        await db.delete(db.savingsGoals).go();
      });
      await pumpAppRoute(tester, '/payout');
      await _settle(tester);

      expect(find.text(kSaveCopy), findsNothing);
      // Everything else still renders and the CTA is still operable.
      expect(find.text(kCtaCopy), findsOneWidget);
      expect(find.text('Weekly + quests · £4.20'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the seeded day 6 is Saturday, not a hard-coded label', (
      tester,
    ) async {
      await _pumpPayout(tester);

      expect(payoutSheetTitle(6), 'Saturday payout');
      expect(payoutSheetTitle(1), 'Monday payout');
      expect(payoutSheetTitle(7), 'Sunday payout');

      await disposeApp(tester);
    });
  });

  group('P13 payout — accessibility actions', () {
    testWidgets('every control exposes a tap action', (tester) async {
      await _pumpPayout(tester);
      final handle = tester.ensureSemantics();

      for (final label in <String>[
        'Maya paid in cash',
        'Leo paid in cash',
        kSaveLabel,
        kCtaCopy,
      ]) {
        final node = _node(tester, label);
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: '"$label" must be operable by VoiceOver/TalkBack',
        );
      }
      // Every tap target is at least the 44 px parent minimum.
      for (final label in <String>['Maya paid in cash', 'Leo paid in cash']) {
        expect(
          _node(tester, label).getSemanticsData().rect.height,
          greaterThanOrEqualTo(NestDevice.tapParent),
        );
      }
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('the check tap action flips the real ticked state', (
      tester,
    ) async {
      await _pumpPayout(tester);
      final handle = tester.ensureSemantics();

      // The design ships Maya ticked (she is the one who owes money) and Leo
      // unticked.
      expect(_isChecked('Maya paid in cash', tester), isTrue);
      expect(_isChecked('Leo paid in cash', tester), isFalse);

      final leo = _node(tester, 'Leo paid in cash');
      leo.owner!.performAction(leo.id, SemanticsAction.tap);
      await _settle(tester);
      expect(
        _isChecked('Leo paid in cash', tester),
        isTrue,
        reason: 'performAction(tap) must change the real state, not a shadow',
      );

      // Back again, this time by tapping the widget itself.
      await tester.tap(find.bySemanticsLabel('Maya paid in cash'));
      await _settle(tester);
      expect(_isChecked('Maya paid in cash', tester), isFalse);

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('the toggle tap action flips the saverow', (tester) async {
      await _pumpPayout(tester);
      final handle = tester.ensureSemantics();

      expect(_isToggled(kSaveLabel, tester), isTrue);

      final node = _node(tester, kSaveLabel);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await _settle(tester);
      expect(_isToggled(kSaveLabel, tester), isFalse);

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('unticking everyone disables the CTA', (tester) async {
      await _pumpPayout(tester);
      final handle = tester.ensureSemantics();

      await tester.tap(find.bySemanticsLabel('Maya paid in cash'));
      await _settle(tester);

      expect(
        _node(
          tester,
          kCtaCopy,
        ).getSemanticsData().hasAction(SemanticsAction.tap),
        isFalse,
        reason: 'nothing ticked ⇒ nothing to pay',
      );
      expect(_isEnabled(kCtaCopy, tester), isFalse);

      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P13 payout — the write', () {
    testWidgets('the CTA records the payout and returns to /money', (
      tester,
    ) async {
      await _pumpPayout(tester, fromLedger: true);

      await tester.tap(find.widgetWithText(NestButton, kCtaCopy));
      await _pumpPastWrite(tester);

      // The ledger stream proves the write, and only then does the sheet pop.
      expect(
        pushedPath(tester),
        '/money',
        reason: 'the confirmation is the stream, not the tap',
      );
      expect(
        find.text('Payout recorded — enjoy the celebration'),
        findsOneWidget,
      );
      expect(currentPath(tester), '/money');
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('a tick-only payout pays exactly what is owed', (tester) async {
      final db = await setUpTestScope();
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pumpAppRoute(tester, '/money');
      await _settle(tester);
      await _pushPayout(tester);

      // The seed already carries historical payout/savings rows, so only the
      // rows written by THIS submit are asserted.
      final seededIds = (await db.select(db.ledgerEntries).get())
          .map((row) => row.id)
          .toSet();

      // Tick Leo too: one submit, two children, two payout rows.
      await tester.tap(find.bySemanticsLabel('Leo paid in cash'));
      await _settle(tester);
      await tester.tap(find.widgetWithText(NestButton, kCtaCopy));
      await _pumpPastWrite(tester);

      final written = (await db.select(db.ledgerEntries).get())
          .where((row) => !seededIds.contains(row.id))
          .toList();
      final payoutRows = written.where((row) => row.type == 'payout');
      expect(payoutRows.length, 2, reason: 'one payout row per ticked child');
      expect(payoutRows.map((row) => row.amountPence).toSet(), <int>{
        -420,
        -210,
      }, reason: 'DATA OVER MOCKS: £4.20 for Maya, £2.10 for Leo');
      // The £1.00 savings move belongs to Maya (the goal-bearing child) alone.
      final savingsRows = written.where((row) => row.type == 'savings_move');
      expect(savingsRows.length, 1);
      expect(savingsRows.single.amountPence, 100);
      expect(savingsRows.single.childId, 'maya');
      expect(pushedPath(tester), '/money');

      await disposeApp(tester);
    });

    testWidgets('nothing is written when the saverow toggle is off', (
      tester,
    ) async {
      final db = await setUpTestScope();
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pumpAppRoute(tester, '/money');
      await _settle(tester);
      await _pushPayout(tester);

      final seededIds = (await db.select(db.ledgerEntries).get())
          .map((row) => row.id)
          .toSet();

      await tester.tap(find.bySemanticsLabel(kSaveLabel));
      await _settle(tester);
      await tester.tap(find.widgetWithText(NestButton, kCtaCopy));
      await _pumpPastWrite(tester);

      final written = (await db.select(db.ledgerEntries).get())
          .where((row) => !seededIds.contains(row.id))
          .toList();
      expect(
        written.where((row) => row.type == 'savings_move'),
        isEmpty,
        reason: 'the toggle is the only thing that moves money to savings',
      );
      expect(written.where((row) => row.type == 'payout').length, 1);

      await disposeApp(tester);
    });
  });

  group('P13 payout — navigation and states', () {
    testWidgets('the scrim tap dismisses back to /money', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');
      await _settle(tester);
      await _pushPayout(tester);

      // Tap well above the sheet — the scrim covers the whole screen above it.
      await tester.tapAt(const Offset(195, 200));
      await _settle(tester);
      expect(currentPath(tester), '/money');
      expect(find.text('Maya is owed'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('system back returns to /money', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');
      await _settle(tester);
      await _pushPayout(tester);

      // `/payout` renders no app bar (the design has none), so drive the
      // platform back button directly rather than looking for a back widget.
      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(currentPath(tester), '/money');

      await disposeApp(tester);
    });

    testWidgets('no children yet: the empty state, no sheet, no scrim', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await pumpAppRoute(tester, '/payout');
      await _settle(tester);

      expect(find.text('Pocket money'), findsOneWidget);
      expect(find.text('No payouts yet'), findsOneWidget);
      expect(
        find.text('Add a child to start tracking pocket money.'),
        findsOneWidget,
      );
      expect(find.text('Saturday payout'), findsNothing);

      final handle = tester.ensureSemantics();
      final node = tester.getSemantics(find.text('Add a child').first);
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await _settle(tester);
      expect(pushedPath(tester), '/add-children');
      handle.dispose();

      await disposeApp(tester);
    });

    testWidgets('dark mode renders the same copy', (tester) async {
      await _pumpPayout(tester, theme: ThemeMode.dark);

      expect(find.text('Saturday payout'), findsOneWidget);
      expect(find.text(kSubCopy), findsOneWidget);
      expect(find.text('Weekly + quests · £4.20'), findsOneWidget);
      expect(find.text(kSaveCopy), findsOneWidget);
      expect(find.text(kCtaCopy), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P13 payout — narrow and large text', () {
    // HARNESS TRAP — the two cases below set `size`, but `test_scope.pumpAppRoute`
    // (test/test_scope.dart:39) overwrites `physicalSize` with 390×844, so they
    // actually run at 390×844 and cannot catch a 320 dp overflow.
    // `payout_responsive_test.dart` covers the REAL 320 dp (it pumps
    // `NestlingApp` directly). Fix on main: docs/screens/P13/SHARED_REQUEST.md.
    testWidgets('320 px at text scale 1.3 overflows nothing', (tester) async {
      await _pumpPayout(tester, size: const Size(320, 844), textScale: 1.3);

      expect(find.text('Saturday payout'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // The checks stay operable at the narrow width.
      await tester.tap(find.bySemanticsLabel('Leo paid in cash'));
      await _settle(tester);
      expect(_isChecked('Leo paid in cash', tester), isTrue);

      // The gutters stay the 20 px the whole app uses.
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('a short screen scrolls the sheet instead of overflowing', (
      tester,
    ) async {
      await _pumpPayout(tester, size: const Size(320, 568));

      expect(find.text(kCtaCopy), findsOneWidget);
      await tester.scrollUntilVisible(find.text(kCtaCopy), 120);
      await _settle(tester);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P13 payout — view contract', () {
    testWidgets('the view is a StatefulWidget that keeps its ticked set', (
      tester,
    ) async {
      await _pumpPayout(tester);

      // Rebuilding through the bloc (a stream re-emission) must not wipe the
      // parent's ticks — hence a State, not a build-time derivation.
      expect(find.byType(PayoutView), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Leo paid in cash'));
      await _settle(tester);
      await _pumpPastWrite(tester);
      expect(_isChecked('Leo paid in cash', tester), isTrue);

      await disposeApp(tester);
    });

    testWidgets('the sheet lists every child in creation order', (
      tester,
    ) async {
      await _pumpPayout(tester);

      final rows = find.byType(PayoutChildRow);
      expect(rows, findsNWidgets(2));
      final first = tester.widget<PayoutChildRow>(rows.at(0));
      final second = tester.widget<PayoutChildRow>(rows.at(1));
      expect(first.child, const MoneyChild(id: 'maya', nickname: 'Maya'));
      expect(second.child, const MoneyChild(id: 'leo', nickname: 'Leo'));

      await disposeApp(tester);
    });
  });
}
