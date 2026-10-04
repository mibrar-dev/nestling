// P12 Money ledger — the states the happy path never reaches.
//
// `money_ledger_view_test.dart` covers the seeded ledger; this file covers
// every OTHER state the `/money` body can render, plus the navigation the
// screen is responsible for:
//
//   * loading   — the watch stream has not produced its first emission yet.
//   * failure   — the ledger stream errored; "Try again" must be a real,
//                 operable retry that recovers into the real seeded ledger.
//   * a child with an empty ledger (rows deleted from the in-memory DB) —
//     "No history yet", a £0.00 hero and the row buttons still live.
//   * the routes every tap must reach (hero CTA, empty CTA, tab bar).
//
// Every test pumps the real app on the real in-memory Drift DB (Seed.demo /
// Seed.empty) and only swaps the repository where a state is otherwise
// unreachable. No simulator, no screenshots here.

import 'dart:async';

// `drift` exports an `isNull` that collides with matcher's; only the delete
// builder is needed from it.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_ledger_data.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';
import 'package:nestling/features/pocket_money/presentation/views/money_ledger_view.dart';
import 'package:nestling/features/pocket_money/presentation/widgets/money_edit_sheet.dart';

import '../../test_scope.dart';

/// Every member but [watchLedgerData] forwards to the real Drift
/// repository, so a scripted state still writes and reads the real tables.
class _DelegatingLedgerRepository implements PocketMoneyRepository {
  _DelegatingLedgerRepository(this._inner);

  final PocketMoneyRepository _inner;

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
  Future<void> addMoney({
    required String childId,
    required int amountPence,
    required String note,
  }) => _inner.addMoney(childId: childId, amountPence: amountPence, note: note);

  @override
  Future<void> recordSpending({
    required String childId,
    required int amountPence,
    required String note,
  }) => _inner.recordSpending(
    childId: childId,
    amountPence: amountPence,
    note: note,
  );

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

/// Ledger stream that never produces a value — the only way to hold `/money`
/// in its loading state (Drift emits within microseconds).
class _SilentLedgerRepository extends _DelegatingLedgerRepository {
  _SilentLedgerRepository(super._inner);

  @override
  Stream<MoneyLedgerData> watchLedgerData() {
    final controller = StreamController<MoneyLedgerData>();
    // Closed with the subscription so the bloc's `close()` cannot hang and no
    // timer outlives the test.
    controller.onCancel = controller.close;
    return controller.stream;
  }
}

/// Fails its first `watchLedgerData()` subscription and then serves the real
/// seeded stream — or fails forever when [alwaysFail] is set.
class _FlakyLedgerRepository extends _DelegatingLedgerRepository {
  _FlakyLedgerRepository(super._inner, {this.alwaysFail = false});

  final bool alwaysFail;

  int attempts = 0;

  @override
  Stream<MoneyLedgerData> watchLedgerData() {
    attempts++;
    if (alwaysFail || attempts == 1) {
      return Stream<MoneyLedgerData>.error(StateError('ledger is down'));
    }
    return super.watchLedgerData();
  }
}

/// Rejects the two ledger writes while the watch stream stays healthy — the
/// "the database said no" half of the submit path, which the sheet's own
/// validation can never produce.
class _RejectingWriteRepository extends _DelegatingLedgerRepository {
  _RejectingWriteRepository(super._inner);

  @override
  Future<void> addMoney({
    required String childId,
    required int amountPence,
    required String note,
  }) async {
    throw StateError('ledger is read-only');
  }

  @override
  Future<void> recordSpending({
    required String childId,
    required int amountPence,
    required String note,
  }) async {
    throw StateError('ledger is read-only');
  }
}

/// Swaps the feature's repository in GetIt — the route builds its bloc through
/// `GetIt.instance<PocketMoneyBloc>()`, so the swap must happen before the
/// pump.
Future<void> _useRepository(PocketMoneyRepository repository) async {
  await GetIt.instance.unregister<PocketMoneyRepository>();
  GetIt.instance.registerSingleton<PocketMoneyRepository>(repository);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Back to the top — a ListView disposes what it scrolls past, so the hero
/// only exists in the tree again once the scroll position returns to 0.
Future<void> _scrollToStart(WidgetTester tester) async {
  await tester.fling(
    find.byType(Scrollable).first,
    const Offset(0, 1400),
    1200,
  );
  await tester.pumpAndSettle();
}

/// Drift write + watch-stream re-emission + SnackBar/toast entry.
Future<void> _pumpPastWrite(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// The ledger is taller than the viewport; park it at the end so the row
/// buttons and the footer are built.
Future<void> _scrollToEnd(WidgetTester tester) async {
  await tester.fling(
    find.byType(Scrollable).first,
    const Offset(0, -1400),
    1200,
  );
  await tester.pumpAndSettle();
}

/// Row counts read straight from Drift — a widget test's fake clock only
/// drains real async inside `runAsync` (same pattern as `p12_bugs_test.dart`).
Future<int> _ledgerRows(WidgetTester tester, AppDatabase db) async {
  final rows = await tester.runAsync(() => db.select(db.ledgerEntries).get());
  return rows?.length ?? 0;
}

Future<int> _giftRows(WidgetTester tester, AppDatabase db) async {
  final rows = await tester.runAsync(
    () => (db.select(
      db.ledgerEntries,
    )..where((row) => row.type.equals('gift'))).get(),
  );
  return rows?.length ?? 0;
}

/// The hero card — the `NestCard` that owns the "is owed" line.
Finder _heroCard() => find
    .ancestor(
      of: find.textContaining('is owed'),
      matching: find.byType(NestCard),
    )
    .first;

/// The painted background of [card] (the shapes rule: measure the visible
/// surface, not where the text lands).
Color? cardBackground(WidgetTester tester, Finder card) {
  final container = tester.widget<Container>(
    find.descendant(of: card, matching: find.byType(Container)).first,
  );
  final decoration = container.decoration;
  return decoration is BoxDecoration ? decoration.color : null;
}

void main() {
  group('P12 Money ledger — loading state', () {
    testWidgets('shows the spinner while the ledger stream is silent', (
      tester,
    ) async {
      await setUpTestScope();
      await _useRepository(
        _SilentLedgerRepository(GetIt.instance<PocketMoneyRepository>()),
      );
      await pumpAppRoute(tester, '/money');

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // No ledger chrome before the first emission — no hero, no rows, no
      // misleading £0.00.
      expect(find.text('Pocket money'), findsNothing);
      expect(find.text('History'), findsNothing);
      expect(find.text('Try again'), findsNothing);
      expect(find.text('Maya is owed'), findsNothing);
      expect(find.text('Add money'), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P12 Money ledger — failure state', () {
    testWidgets('renders the message and an operable Try again', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      final repository = _FlakyLedgerRepository(
        GetIt.instance<PocketMoneyRepository>(),
      );
      await _useRepository(repository);
      await pumpAppRoute(tester, '/money');
      await _settle(tester);

      expect(find.textContaining('ledger is down'), findsOneWidget);
      // Review finding 7 (iteration 2): the parent-facing copy is the
      // friendly lead sentence + the raw cause, with a curly ’ U+2019 — never
      // the bare `Bad state: …` on its own.
      expect(
        find.text(
          'We couldn\u2019t load your ledger: Bad state: ledger is down',
        ),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Maya is owed'), findsNothing);
      // The shell chrome stays: the failure is inside the tab, not a dead app.
      expect(find.text('Money'), findsWidgets);
      expect(tester.takeException(), isNull);

      final node = tester.getSemantics(
        find.widgetWithText(NestButton, 'Try again').first,
      );
      final data = node.getSemanticsData();
      expect(
        data.hasAction(SemanticsAction.tap),
        isTrue,
        reason: 'Try again must be operable by VoiceOver/TalkBack',
      );
      expect(data.label, contains('Try again'));
      expect(data.rect.height, greaterThanOrEqualTo(NestDevice.tapParent));

      // The a11y action must drive the REAL behaviour: a second subscription
      // to the live watch stream, not just repaint the button.
      tester.semantics.performAction(
        find.semantics.byPredicate((candidate) => candidate.id == node.id),
        SemanticsAction.tap,
      );
      await _settle(tester);
      await _settle(tester);

      expect(repository.attempts, 2, reason: 'Try again must re-subscribe');
      expect(find.text('Maya is owed'), findsOneWidget);
      expect(find.text('£4.20'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      expect(find.textContaining('ledger is down'), findsNothing);
      expect(tester.takeException(), isNull);

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('repeated failures keep the failure body and the retry live', (
      tester,
    ) async {
      await setUpTestScope();
      final repository = _FlakyLedgerRepository(
        GetIt.instance<PocketMoneyRepository>(),
        alwaysFail: true,
      );
      await _useRepository(repository);
      await pumpAppRoute(tester, '/money');
      await _settle(tester);

      for (var attempt = 0; attempt < 3; attempt++) {
        expect(find.text('Try again'), findsOneWidget);
        expect(find.textContaining('ledger is down'), findsOneWidget);
        await tester.tap(find.text('Try again'));
        await _settle(tester);
      }
      expect(
        repository.attempts,
        4,
        reason: 'each retry must open a fresh subscription',
      );
      expect(find.text('Maya is owed'), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    // Iteration 2 moved the success toast onto a second `BlocListener` that
    // fires when the watch stream re-emits (review finding 6), so a success
    // message can no longer precede a write the database rejected. These two
    // cover the rejection half; `money_ledger_view_test.dart` covers the
    // sheet-validation half (which never reaches the bloc at all).
    testWidgets('a rejected Add money toasts the reason, never a success', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final db = await setUpTestScope();
      final before = await _giftRows(tester, db);
      await _useRepository(
        _RejectingWriteRepository(GetIt.instance<PocketMoneyRepository>()),
      );
      await pumpAppRoute(tester, '/money');

      expect(find.text('£4.20'), findsOneWidget);
      await _scrollToEnd(tester);
      await tester.tap(find.text('Add money'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField).first, '5.00');
      await tester.enterText(find.byType(TextField).last, 'Rejected top-up');
      await tester.pump();
      await tester.tap(find.widgetWithText(NestButton, 'Add money').last);
      await _pumpPastWrite(tester);

      // No success toast — the money was not added.
      expect(find.textContaining('Added £'), findsNothing);
      // The parent-facing reason, as a live region a screen reader announces.
      final toast = find.textContaining('We couldn\u2019t save that:');
      expect(toast, findsOneWidget);
      expect(
        tester.widgetList<Text>(toast).map((widget) => widget.data ?? ''),
        everyElement(contains('ledger is read-only')),
      );
      expect(
        tester
            .getSemantics(toast)
            .getSemanticsData()
            .flagsCollection
            .isLiveRegion,
        isTrue,
        reason: 'a toast that appears without any focus change must announce',
      );
      // The ledger is untouched: same owed figure, same rows, still navigable.
      await _scrollToStart(tester);
      expect(find.text('£4.20'), findsOneWidget);
      expect(find.text('Rejected top-up'), findsNothing);
      expect(await _giftRows(tester, db), before);
      expect(tester.takeException(), isNull);

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('a rejected Record spending toasts the reason and keeps the '
        'ledger', (tester) async {
      final db = await setUpTestScope();
      final before = await _ledgerRows(tester, db);
      await _useRepository(
        _RejectingWriteRepository(GetIt.instance<PocketMoneyRepository>()),
      );
      await pumpAppRoute(tester, '/money');

      await _scrollToEnd(tester);
      await tester.tap(find.text('Record spending'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField).first, '2');
      await tester.pump();
      await tester.tap(find.widgetWithText(NestButton, 'Record spending').last);
      await _pumpPastWrite(tester);

      expect(find.textContaining('Spent £'), findsNothing);
      expect(
        find.textContaining('We couldn\u2019t save that:'),
        findsOneWidget,
      );
      expect(await _ledgerRows(tester, db), before);
      await _scrollToStart(tester);
      expect(find.text('£4.20'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P12 Money ledger — a child with an empty ledger', () {
    testWidgets('No history yet, £0.00 hero, row buttons still live', (
      tester,
    ) async {
      final db = await setUpTestScope();
      // Leo's rows removed from the real in-memory database: the owed maths
      // (weekly base + quest bonuses) must fall to zero with them, and the
      // card must say so instead of rendering an empty list.
      await (db.delete(
        db.ledgerEntries,
      )..where((row) => row.childId.equals('leo'))).go();

      await pumpAppRoute(tester, '/money');
      await tester.tap(find.text('Leo'));
      await _settle(tester);

      expect(find.text('Leo is owed'), findsOneWidget);
      expect(find.text('£0.00'), findsWidgets);
      expect(find.text('No history yet'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Lego Friends set — £24.99'), findsNothing);
      expect(
        tester
            .widget<Text>(
              find.byWidgetPredicate(
                (widget) =>
                    widget is Text &&
                    (widget.data ?? '').startsWith('Weekly base £0.00'),
              ),
            )
            .data,
        contains('quests £0.00 · Next payout '),
      );
      expect(tester.takeException(), isNull);

      // The payout and both writes stay available for an empty ledger.
      await _scrollToEnd(tester);
      expect(find.text('Add money'), findsOneWidget);
      expect(find.text('Record spending'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Record spending'));
      await _settle(tester);
      expect(find.text('Record spending for Leo'), findsOneWidget);
      expect(find.byType(MoneyEditSheet), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P12 Money ledger — navigation', () {
    testWidgets('Payout time pushes /payout, not a replacement of /money', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      expect(currentPath(tester), '/money');
      await tester.tap(find.text('Payout time'));
      await _settle(tester);

      expect(
        pushedPath(tester),
        '/payout',
        reason: 'the ledger is a tab root: it must push, not go',
      );
      // Back returns to the ledger with its state intact. P13's real
      // `/payout` renders no app bar (the design has none), so the platform
      // back button is driven directly instead of a back-widget lookup.
      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(currentPath(tester), '/money');
      expect(find.text('Maya is owed'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('every tab bar item routes to its own branch', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      for (final entry in const <(String, String)>[
        ('Today', '/today'),
        ('Quests', '/quests'),
        ('Family', '/child-profile'),
      ]) {
        await tester.tap(find.text(entry.$1).last);
        await _settle(tester);
        expect(
          currentPath(tester),
          entry.$2,
          reason: 'tapping "${entry.$1}" must land on ${entry.$2}',
        );
        await tester.tap(find.text('Money').last);
        await _settle(tester);
        expect(currentPath(tester), '/money');
      }

      // The ledger's own state survived every branch switch.
      expect(find.text('Maya is owed'), findsOneWidget);
      expect(find.text('£4.20'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the segment is not a navigation: the route never changes', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      await tester.tap(find.text('Leo'));
      await _settle(tester);
      await tester.tap(find.text('Maya'));
      await _settle(tester);

      expect(currentPath(tester), '/money');
      expect(pushedPath(tester), '/money');
      expect(find.text('£4.20'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('the segment lists children in creation order', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      // Maya was added first, so she comes first — alphabetical order would
      // put Leo ("Le" < "Ma") before her.
      final maya = tester.getTopLeft(find.text('Maya')).dx;
      final leo = tester.getTopLeft(find.text('Leo')).dx;
      expect(
        maya,
        lessThan(leo),
        reason: 'children must be listed in creation order (Maya, then Leo)',
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the sheet fields are labelled and report their inline error', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      await _scrollToEnd(tester);
      await tester.tap(find.text('Add money'));
      await _settle(tester);

      for (final field in const <String>['Amount', 'Note']) {
        expect(
          find.bySemanticsLabel(field),
          findsWidgets,
          reason: 'the "$field" field must be labelled for a screen reader',
        );
      }
      expect(find.text('£0.00'), findsOneWidget, reason: 'the amount hint');
      expect(find.text('e.g. Birthday money'), findsOneWidget);

      // A rejected amount explains itself instead of silently doing nothing.
      await tester.tap(find.widgetWithText(NestButton, 'Add money').last);
      await _settle(tester);
      expect(find.text('Enter an amount like £1.00'), findsOneWidget);
      expect(find.byType(MoneyEditSheet), findsOneWidget);
      expect(
        find.text('Add money for Maya'),
        findsOneWidget,
        reason: 'the sheet must stay open so the error can be fixed',
      );
      expect(tester.takeException(), isNull);

      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P12 Money ledger — surfaces and semantics', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final themeName = theme == ThemeMode.light ? 'light' : 'dark';

      testWidgets('$themeName: the hero paints heroBg, never the ink colour', (
        tester,
      ) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/money', theme: theme);

        final tokens = tester.element(find.byType(MoneyLedgerView)).nest;
        expect(
          cardBackground(tester, _heroCard()),
          tokens.heroBg,
          reason:
              'the hero must paint tokens.heroBg; in dark mode that is NOT '
              'tokens.ink',
        );
        if (theme == ThemeMode.dark) {
          expect(
            tokens.heroBg,
            isNot(tokens.ink),
            reason: 'the probe must discriminate in dark mode too',
          );
        }

        await disposeApp(tester);
      });

      testWidgets('$themeName: the history card paints surface, not paper', (
        tester,
      ) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/money', theme: theme);

        final tokens = tester.element(find.byType(MoneyLedgerView)).nest;
        final historyCard = find
            .ancestor(of: find.text('History'), matching: find.byType(NestCard))
            .first;
        expect(cardBackground(tester, historyCard), tokens.surface);
        expect(
          tokens.surface,
          isNot(tokens.paper),
          reason: 'the probe must discriminate: card vs page background',
        );

        await disposeApp(tester);
      });
    }

    testWidgets('the savings goal announces itself as a progress bar', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      // `NestProgress` sets its own label without `container: true`, so
      // Flutter merges the node into the goal card's column — the required
      // label and value must still reach the screen reader inside that node.
      final finder = find.bySemanticsLabel(RegExp('Savings goal progress'));
      expect(finder, findsOneWidget);
      final data = tester.getSemantics(finder).getSemanticsData();
      expect(data.label, contains('Savings goal progress'));
      expect(
        data.value,
        contains('62 percent'),
        reason: 'the design sets aria-valuenow=62 on the progressbar',
      );
      expect(
        data.hasAction(SemanticsAction.tap),
        isFalse,
        reason: 'the goal card is display-only, not a button',
      );
      expect(tester.takeException(), isNull);

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('the icon-only sheet button is a labelled 44 px button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpTestScope();
      await pumpAppRoute(tester, '/money');

      await _scrollToEnd(tester);
      await tester.tap(find.text('Add money'));
      await _settle(tester);

      // The label lives on the button's Semantics wrapper, not on the glyph.
      expect(
        find.byWidgetPredicate(
          (widget) => widget is NestIcon && widget.assetName == NestIcons.close,
        ),
        findsOneWidget,
        reason: 'the sheet must have its icon-only close control',
      );
      final close = tester.getSemantics(find.bySemanticsLabel('Close'));
      final data = close.getSemanticsData();
      expect(
        data.label,
        'Close',
        reason: 'an icon-only button is unlabelled without it',
      );
      expect(
        data.hasAction(SemanticsAction.tap),
        isTrue,
        reason:
            'the close glyph carries no text, so the Semantics node must '
            'expose the action itself',
      );
      expect(data.rect.width, greaterThanOrEqualTo(NestDevice.tapParent));
      expect(data.rect.height, greaterThanOrEqualTo(NestDevice.tapParent));
      // The glyph must not add a second, competing label.
      expect(find.bySemanticsLabel('Close'), findsOneWidget);

      // …and the action dismisses the sheet.
      tester.semantics.performAction(
        find.semantics.byPredicate((candidate) => candidate.id == close.id),
        SemanticsAction.tap,
      );
      await _settle(tester);
      expect(find.byType(MoneyEditSheet), findsNothing);
      expect(tester.takeException(), isNull);

      handle.dispose();
      await disposeApp(tester);
    });
  });
}
