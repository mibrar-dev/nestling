// P13 · Payout (parent) — loading / failure / retry states.
//
// `PayoutView`'s status switch has three branches the happy-path suite can
// never reach: the in-memory Drift database always loads, so `loading` and
// `failure` were untested (handed over by `2_build.md`, "Left" item 2). These
// drive them with a scripted repository in front of the real one, exactly as
// `quest_library_states_test.dart` does for P10 — the app is untouched, only
// the bloc's `watchLedgerData` is swapped.
//
// Covers `1_plan.md` §d:
//   * `initial`/`loading` → a centred leaf `CircularProgressIndicator` and
//     nothing from the loaded tree (no sheet, no scrim, no title);
//   * `failure` → the friendly parent-facing message plus the only legal
//     retry, `Try again`, which re-requests the stream and, on a healthy
//     stream, lands the real seeded sheet;
//   * the retry is operable by VoiceOver (`performAction(tap)` really
//     re-requests) and a second failure keeps offering the retry.
//
// Widget space only — no simulator, no screenshots.

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_ledger_data.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';
import 'package:nestling/features/pocket_money/presentation/views/payout_view.dart';
import 'package:nestling/features/pocket_money/presentation/widgets/payout_sheet.dart';

import '../../test_scope.dart';

/// Hands the `onWatch` callback the 0-based attempt number and returns the
/// stream for that subscription; everything else delegates to the real Drift
/// repository, so a healthy retry renders the seeded sheet rather than a
/// hand-built fixture.
class _ScriptedLedgerRepo implements PocketMoneyRepository {
  _ScriptedLedgerRepo(this._inner, this._onWatch);

  final PocketMoneyRepository _inner;
  final Stream<MoneyLedgerData> Function(int attempt) _onWatch;

  /// How many times `watchLedgerData` has been subscribed — the retry count.
  int attempts = 0;

  @override
  Stream<MoneyLedgerData> watchLedgerData() => _onWatch(attempts++);

  @override
  Future<List<PocketMoneyEntry>> getItems() => _inner.getItems();
  @override
  Stream<List<PocketMoneyEntry>> watchItems() => _inner.watchItems();
  @override
  Stream<List<PocketMoneyEntry>> watchLedger(String childId) =>
      _inner.watchLedger(childId);
  @override
  Stream<OwedSummary> watchOwed(String childId) => _inner.watchOwed(childId);
  @override
  Future<OwedSummary> owed(String childId) => _inner.owed(childId);
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

/// `1_plan.md` §d: the message the bloc builds (`_loadErrorMessage`), with the
/// curly U+2019 apostrophe and the raw cause kept after the colon.
const String kFailureCopy =
    'We couldn\u2019t load your ledger: Exception: ledger offline';

/// Pumps the real `/payout` route. The scripted repository is already in GetIt
/// (see [_scripted]) and `pocketMoneyBloc` is a **factory** that reads
/// `sl<PocketMoneyRepository>()`, so the route's `BlocProvider` builds the bloc
/// over the scripted stream.
///
/// Do NOT hand this file its own `PocketMoneyBloc` and `await bloc.close()`:
/// `_onLoadRequested` holds a live `await emit.forEach(...)` on an infinite
/// Drift stream, so `close()` never completes and the test dies on the 10
/// minute framework timeout. The route's `BlocProvider` closes the bloc
/// without awaiting it, which is why every other P13 test gets away with it
/// (see `pocket_money_ledger_bloc_test.dart:803` for the same hazard and the
/// `close().timeout(...)` workaround it uses for a terminating stream).
///
/// [surface] is applied AFTER the first frame because `pumpAppRoute`
/// hard-codes 390×844 (see docs/screens/P13/SHARED_REQUEST.md).
Future<void> _pumpView(
  WidgetTester tester, {
  ThemeMode theme = ThemeMode.light,
  Size? surface,
}) async {
  await pumpAppRoute(tester, '/payout', theme: theme);
  if (surface == null) return;
  tester.view.physicalSize = surface * 3;
  tester.view.devicePixelRatio = 3;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<_ScriptedLedgerRepo> _scripted(
  PocketMoneyRepository inner,
  Stream<MoneyLedgerData> Function(int attempt) onWatch,
) async {
  final repository = _ScriptedLedgerRepo(inner, onWatch);
  await GetIt.instance.unregister<PocketMoneyRepository>();
  GetIt.instance.registerSingleton<PocketMoneyRepository>(repository);
  return repository;
}

/// The real repository, captured BEFORE the scripted one replaces it in GetIt
/// (asking GetIt for it afterwards would re-enter the scripted wrapper).
PocketMoneyRepository _real() => GetIt.instance<PocketMoneyRepository>();

/// Attempt 0 never emits — the view stays in `loading` for the whole test.
Future<_ScriptedLedgerRepo> _neverEmits() {
  final real = _real();
  return _scripted(real, (_) => const Stream<MoneyLedgerData>.empty());
}

/// Every attempt emits the real seeded ledger (the `loaded` path).
Future<_ScriptedLedgerRepo> _alwaysReal() {
  final real = _real();
  return _scripted(real, (_) => real.watchLedgerData());
}

/// Every attempt fails — the `failure` path.
Future<_ScriptedLedgerRepo> _alwaysFails() {
  final real = _real();
  return _scripted(
    real,
    (_) => Stream<MoneyLedgerData>.error(Exception('ledger offline')),
  );
}

/// Attempt 0 fails, every later attempt emits the real ledger — the retry.
Future<_ScriptedLedgerRepo> _failsThenReal() {
  final real = _real();
  return _scripted(
    real,
    (attempt) => attempt == 0
        ? Stream<MoneyLedgerData>.error(Exception('ledger offline'))
        : real.watchLedgerData(),
  );
}

void main() {
  group('P13 payout — loading state', () {
    testWidgets('a stream that never emits shows only a leaf spinner', (
      tester,
    ) async {
      await setUpTestScope();
      await _neverEmits();
      await _pumpView(tester);

      final spinner = find.byType(CircularProgressIndicator);
      expect(spinner, findsOneWidget);
      expect(
        tester.widget<CircularProgressIndicator>(spinner).color,
        tester.element(spinner).nest.leaf,
        reason: 'the spinner wears the leaf token (1_plan.md §d)',
      );
      expect(
        tester.getRect(spinner).center.dx,
        moreOrLessEquals(195, epsilon: 1),
        reason: 'centred, not pinned to the gutter',
      );

      // Nothing from the loaded tree may leak in behind it.
      expect(find.text('Saturday payout'), findsNothing);
      expect(find.text('Pocket money'), findsNothing);
      expect(find.byType(PayoutSheet), findsNothing);
      expect(find.byType(PayoutChildRow), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the first emission replaces the spinner with the sheet', (
      tester,
    ) async {
      await setUpTestScope();
      await _alwaysReal();
      await _pumpView(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(PayoutSheet), findsOneWidget);
      expect(find.text('Saturday payout'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P13 payout — load failure state', () {
    testWidgets('a stream error shows the message and `Try again`, no sheet', (
      tester,
    ) async {
      await setUpTestScope();
      await _alwaysFails();
      await _pumpView(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text(kFailureCopy), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      // A secondary, auto-width button centred in the viewport.
      final button = tester.widget<NestButton>(
        find.widgetWithText(NestButton, 'Try again'),
      );
      expect(button.variant, NestButtonVariant.secondary);
      expect(button.fullWidth, isFalse);
      expect(
        tester.getRect(find.text('Try again')).center.dx,
        moreOrLessEquals(195, epsilon: 1),
      );

      // Parent copy: bodySmall in ink-2, centred, capped at five lines.
      final message = tester.widget<Text>(find.text(kFailureCopy));
      final tokens = tester.element(find.text(kFailureCopy)).nest;
      expect(message.style!.color, tokens.ink2);
      expect(message.textAlign, TextAlign.center);
      expect(message.maxLines, 5);

      // No sheet, no scrim, no title behind a full-screen swap.
      expect(find.byType(PayoutSheet), findsNothing);
      expect(find.text('Pocket money'), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('`Try again` re-requests and a healthy retry loads the sheet', (
      tester,
    ) async {
      await setUpTestScope();
      final repository = await _failsThenReal();
      await _pumpView(tester);
      expect(repository.attempts, 1);
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repository.attempts, 2, reason: 'the retry re-subscribes');
      expect(find.text('Try again'), findsNothing);
      expect(find.byType(PayoutSheet), findsOneWidget);
      // The retry renders the SEEDED sheet, not a fixture.
      expect(find.text('Saturday payout'), findsOneWidget);
      expect(find.text('Weekly + quests · £4.20'), findsOneWidget);
      expect(find.text('Weekly + quests · £2.10'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('`Try again` is operable by VoiceOver and really re-requests', (
      tester,
    ) async {
      await setUpTestScope();
      final repository = await _failsThenReal();
      await _pumpView(tester);

      final handle = tester.ensureSemantics();
      final node = tester.getSemantics(find.text('Try again'));
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repository.attempts, 2);
      expect(find.byType(PayoutSheet), findsOneWidget);
      handle.dispose();

      await disposeApp(tester);
    });

    testWidgets('a repeated failure keeps offering the retry', (tester) async {
      await setUpTestScope();
      final repository = await _alwaysFails();
      await _pumpView(tester);

      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repository.attempts, 2);
      expect(find.text(kFailureCopy), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('dark mode: the same failure copy in ink-2 on paper', (
      tester,
    ) async {
      await setUpTestScope();
      await _alwaysFails();
      await _pumpView(tester, theme: ThemeMode.dark);

      final message = tester.widget<Text>(find.text(kFailureCopy));
      final tokens = tester.element(find.text(kFailureCopy)).nest;
      expect(message.style!.color, tokens.ink2);
      // `Try again` stays operable and keeps its secondary styling.
      expect(find.text('Try again'), findsOneWidget);
      expect(
        tester
            .widget<NestButton>(find.widgetWithText(NestButton, 'Try again'))
            .variant,
        NestButtonVariant.secondary,
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the failure body is narrow-safe at 320 dp', (tester) async {
      await setUpTestScope();
      await _alwaysFails();
      await _pumpView(tester, surface: const Size(320, 568));

      expect(
        MediaQuery.sizeOf(tester.element(find.byType(PayoutView))).width,
        moreOrLessEquals(320, epsilon: 0.01),
      );
      expect(find.text(kFailureCopy), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });
}
