// P11 · Approvals — the states, sizes, themes and navigation that the seeded
// happy path in `approvals_view_test.dart` never reaches.
//
// Matrix covered here (stage-3 brief):
//   * loading / empty / failure / action-error states — the seeded inbox is
//     always "loaded with 3 rows", so each of these needs a scripted stream or
//     the empty seed.
//   * widths 320 / 390 / 430 × text scale 1.0 and 1.3, in light AND dark.
//   * tap targets ≥ 44 (parent floor) on every control, with the kid floor
//     (56) explicitly shown not to apply.
//   * every tap's route: back (cold launch and pushed-from-Today), and the
//     three writes which must NOT navigate.
//   * semantics: one summary label per card, `SemanticsAction.tap` on every
//     control, `performAction` driving the real database, and the disabled
//     state of a busy card.
//
// Pattern follows `test/features/pocket_money/money_ledger_states_test.dart`:
// the real in-memory Drift DB (Seed.demo / Seed.empty) with only the stream or
// the write swapped, so a scripted state still reads and writes real tables.
//
// No simulator and no screenshots here (stage 5 owns those).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/approvals/domain/approvals_repository.dart';
import 'package:nestling/features/approvals/domain/entities/approval.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:nestling/features/approvals/presentation/views/approvals_view.dart';
import 'package:nestling/features/approvals/presentation/widgets/approval_card.dart';
import 'package:nestling/features/approvals/presentation/widgets/approvals_bottom_cta.dart';
import 'package:nestling/features/approvals/presentation/widgets/approvals_loaded_body.dart';

import '../../test_scope.dart';

/// The [ApprovalCard] whose `.who` line is [whoLine].
Finder _cardFor(String whoLine) =>
    find.ancestor(of: find.text(whoLine), matching: find.byType(ApprovalCard));

/// Taps one of the two row buttons on the card whose `.who` line is [whoLine].
///
/// `ensureVisible` first: the seeded inbox is taller than the scroll viewport
/// once the child's quote is rendered (ORCHESTRATOR_NOTES item 1), and a
/// lazily built row whose centre sits below the clip would swallow the tap.
/// (This file runs on the test fallback font; the geometry test loads the
/// bundled faces and pins the design's real positions.)
Future<void> _tapRowButton(
  WidgetTester tester,
  String whoLine,
  String label,
) async {
  final button = find.descendant(
    of: _cardFor(whoLine),
    matching: find.widgetWithText(NestButton, label),
  );
  await tester.ensureVisible(button);
  await tester.pump();
  await tester.tap(button);
  await tester.pump();
  await _settle(tester);
}

/// `Text.rich` cards do not match `find.textContaining`; match the flattened
/// span text instead.
Finder _richText(String plain) => find.byWidgetPredicate(
  (widget) => widget is RichText && widget.text.toPlainText() == plain,
);

/// Pumps until the frame queue is quiet. Drift writes wake the pending stream
/// one row at a time, so a fixed pump count would be flaky; `pumpAndSettle`
/// never converges here because the running app always has something
/// scheduling frames.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Every `BoxDecoration` painted by a `Container` on screen.
List<BoxDecoration> _boxDecorations(WidgetTester tester) => tester
    .widgetList<Container>(find.byType(Container))
    .map((container) => container.decoration)
    .whereType<BoxDecoration>()
    .toList();

// ── repositories ───────────────────────────────────────────────────────────

/// Every member but the ones a test overrides forwards to the real Drift
/// repository, so a scripted state still writes and reads the real tables.
class _DelegatingApprovalsRepository implements ApprovalsRepository {
  _DelegatingApprovalsRepository(this._inner);

  final ApprovalsRepository _inner;

  @override
  Future<List<Approval>> getItems() => _inner.getItems();

  @override
  Stream<List<Approval>> watchItems() => _inner.watchItems();

  @override
  Future<void> approve(int completionId) => _inner.approve(completionId);

  @override
  Future<void> markNotYet(int completionId) => _inner.markNotYet(completionId);

  @override
  Future<void> approveAll() => _inner.approveAll();
}

/// A pending stream that never produces a value — the only way to hold
/// `/approvals` in its loading state (Drift emits within microseconds).
class _SilentApprovalsRepository extends _DelegatingApprovalsRepository {
  _SilentApprovalsRepository(super._inner);

  @override
  Stream<List<Approval>> watchItems() {
    final controller = StreamController<List<Approval>>();
    // Closed with the subscription so the bloc's `close()` cannot hang and no
    // timer outlives the test.
    controller.onCancel = controller.close;
    return controller.stream;
  }
}

/// Fails the first `watchItems()` (the `failure` branch) and then serves the
/// real seeded stream — or fails forever when [alwaysFail] is set.
class _FailingApprovalsRepository extends _DelegatingApprovalsRepository {
  _FailingApprovalsRepository(super._inner, {this.alwaysFail = false});

  final bool alwaysFail;
  int attempts = 0;

  @override
  Stream<List<Approval>> watchItems() {
    attempts++;
    if (alwaysFail || attempts == 1) {
      return Stream<List<Approval>>.error(
        StateError('approvals inbox is down'),
      );
    }
    return super.watchItems();
  }
}

/// Rejects every write while the watch stream stays healthy — "the database
/// said no", which no seeded seed can produce.
class _RejectingWritesRepository extends _DelegatingApprovalsRepository {
  _RejectingWritesRepository(super._inner);

  static const String message = 'database said no';

  @override
  Future<void> approve(int completionId) async => throw StateError(message);

  @override
  Future<void> markNotYet(int completionId) async => throw StateError(message);

  @override
  Future<void> approveAll() async => throw StateError(message);
}

/// Holds every approve open until [openGate] — the only way to observe a
/// card's busy state, since a real Drift write finishes inside one frame.
class _GatedWritesRepository extends _DelegatingApprovalsRepository {
  _GatedWritesRepository(super._inner);

  final Completer<void> _gate = Completer<void>();

  int approveCalls = 0;

  void openGate() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  Future<void> approve(int completionId) async {
    approveCalls++;
    await _gate.future;
    await super.approve(completionId);
  }
}

/// Swaps the feature's repository in GetIt — the route builds its bloc through
/// `GetIt.instance<ApprovalsBloc>()`, so the swap must happen before the pump.
Future<void> _useRepository(ApprovalsRepository repository) async {
  await GetIt.instance.unregister<ApprovalsRepository>();
  GetIt.instance.registerSingleton<ApprovalsRepository>(repository);
}

// ── database readers ───────────────────────────────────────────────────────

/// `quest_bonus` ledger rows — the money side-effect of an approval.
Future<List<LedgerEntry>> _bonusRows(WidgetTester tester) async {
  final db = GetIt.instance<AppDatabase>();
  final rows = await tester.runAsync(() => db.select(db.ledgerEntries).get());
  return (rows ?? const <LedgerEntry>[])
      .where((row) => row.type == 'quest_bonus')
      .toList();
}

/// The stored status of one `quest_completions` row.
Future<String?> _completionStatus(WidgetTester tester, int id) async {
  final db = GetIt.instance<AppDatabase>();
  final row = await tester.runAsync(
    () => (db.select(
      db.questCompletions,
    )..where((c) => c.id.equals(id))).getSingleOrNull(),
  );
  return row?.status;
}

/// How many `done_pending` rows are left in the database.
Future<int> _pendingCount(WidgetTester tester) async {
  final db = GetIt.instance<AppDatabase>();
  final rows = await tester.runAsync(
    () => (db.select(
      db.questCompletions,
    )..where((c) => c.status.equals('done_pending'))).get(),
  );
  return rows?.length ?? 0;
}

// ── misc helpers ───────────────────────────────────────────────────────────

bool _hasTap(WidgetTester tester, Finder finder) => tester
    .getSemantics(finder)
    .getSemanticsData()
    .hasAction(SemanticsAction.tap);

SemanticsData _data(WidgetTester tester, Finder finder) =>
    tester.getSemantics(finder).getSemanticsData();

/// The bloc the route created for the screen under test.
ApprovalsBloc _blocOf(WidgetTester tester) =>
    tester.element(find.byType(ApprovalsView)).read<ApprovalsBloc>();

/// Loads the bundled Inter/Nunito faces the app ships.
///
/// Without them `flutter_test` falls back to a font ~10 % wider: the helper
/// banner wraps to three lines (84 instead of 64) and every child quote wraps
/// to two lines, which slides the stack down ~92 px and pushes the LAST card's
/// button row underneath the bottom CTA — a tap then misses its target and the
/// write test fails for a reason that has nothing to do with the screen. The
/// geometry test documents the same trap and pins the real-font anchors.
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

void main() {
  setUpAll(_loadBundledFonts);
  setUp(() async {
    await setUpTestScope();
  });

  Future<void> pump(WidgetTester tester, {ThemeMode theme = ThemeMode.light}) =>
      pumpAppRoute(tester, '/approvals', theme: theme);

  group('P11 approvals — loading state', () {
    testWidgets('spinner only: no helper, no cards and no CTA while silent', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _useRepository(
        _SilentApprovalsRepository(GetIt.instance<ApprovalsRepository>()),
      );
      await pump(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ApprovalsHelperBanner), findsNothing);
      expect(find.byType(ApprovalCard), findsNothing);
      expect(find.byType(ApprovalsBottomCta), findsNothing);
      expect(find.text('All caught up'), findsNothing);
      expect(find.text('Try again'), findsNothing);
      // The count is `state.items.length`, so it is 0 until the first emission.
      expect(find.text('Waiting for you (0)'), findsOneWidget);
      // The back chevron is live even while loading — a parent must never be
      // trapped on a spinner.
      expect(_hasTap(tester, find.bySemanticsLabel('Back to Today')), isTrue);
      expect(tester.takeException(), isNull);
      semantics.dispose();

      await disposeApp(tester);
    });
  });

  group('P11 approvals — empty state', () {
    testWidgets('Seed.empty (onboarded, no children) shows the empty state', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      // `Seed.empty` = onboarded parent, no children. Without it the router
      // redirects `/approvals` to `/welcome` (onboarding incomplete).
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();
      await pump(tester);

      expect(find.text('Waiting for you (0)'), findsOneWidget);
      expect(find.text('All caught up'), findsOneWidget);
      expect(
        find.text(
          'When your children finish a quest, it will appear here for your '
          'thumbs-up.',
        ),
        findsOneWidget,
      );
      // The helper explains buttons that are not there, so it must not render.
      expect(find.byType(ApprovalsHelperBanner), findsNothing);
      expect(find.byType(ApprovalCard), findsNothing);
      expect(find.byType(ApprovalsBottomCta), findsNothing);
      expect(find.text('Approve all (0)'), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('a drained inbox shows the empty state with no scroll view', (
      tester,
    ) async {
      // Drain the seeded inbox through the real database BEFORE the first
      // frame, so the bloc's very first (and only) emission is the empty list.
      await tester.runAsync(
        () => GetIt.instance<ApprovalsRepository>().approveAll(),
      );
      await pump(tester);
      expect(await _pendingCount(tester), 0);

      expect(find.text('All caught up'), findsOneWidget);
      expect(find.text('Waiting for you (0)'), findsOneWidget);
      // The empty state is not a scroll view — nothing to scroll.
      expect(find.byType(ListView), findsNothing);
      expect(find.byType(ApprovalsBottomCta), findsNothing);
      final empty = tester.getRect(find.byType(NestEmptyState));
      expect(empty.height, lessThan(844));
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('P11 approvals — failure state', () {
    testWidgets('a failed stream shows the message and a 52 px Try again', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _useRepository(
        _FailingApprovalsRepository(
          GetIt.instance<ApprovalsRepository>(),
          alwaysFail: true,
        ),
      );
      await pump(tester);

      expect(find.textContaining('approvals inbox is down'), findsOneWidget);
      final retry = find.byKey(const ValueKey<String>('p11_try_again'));
      expect(retry, findsOneWidget);
      expect(
        tester.widget<NestButton>(retry).minHeight,
        52,
        reason: 'the shared .btn default from components.css',
      );
      expect(
        tester.getRect(retry).height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );
      expect(_hasTap(tester, retry), isTrue);
      // No inbox chrome behind the error.
      expect(find.byType(ApprovalCard), findsNothing);
      expect(find.byType(ApprovalsHelperBanner), findsNothing);
      expect(find.byType(ApprovalsBottomCta), findsNothing);
      expect(find.text('All caught up'), findsNothing);
      expect(tester.takeException(), isNull);
      semantics.dispose();

      await disposeApp(tester);
    });

    testWidgets('Try again re-subscribes and recovers into the seeded inbox', (
      tester,
    ) async {
      final repository = _FailingApprovalsRepository(
        GetIt.instance<ApprovalsRepository>(),
      );
      final semantics = tester.ensureSemantics();
      await _useRepository(repository);
      await pump(tester);

      expect(find.text('All caught up'), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('p11_try_again')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey<String>('p11_try_again')));
      await tester.pump();
      await _settle(tester);

      expect(repository.attempts, 2, reason: 'the retry must re-subscribe');
      expect(find.text('Waiting for you (3)'), findsOneWidget);
      expect(find.text('Maya · Empty the dishwasher'), findsOneWidget);
      expect(find.text('Approve all (3)'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('p11_try_again')), findsNothing);
      semantics.dispose();

      await disposeApp(tester);
    });
  });

  group('P11 approvals — writes reach the database', () {
    testWidgets('Approve writes the quest_bonus row and drops the card', (
      tester,
    ) async {
      await pump(tester);
      // The seed already carries historical `quest_bonus` rows from quests
      // approved earlier; the inbox owes 3 more, so the delta is what matters.
      final bonusBefore = await _bonusRows(tester);
      expect(await _pendingCount(tester), 3);

      await _tapRowButton(tester, 'Maya · Empty the dishwasher', 'Approve');

      expect(find.text('Maya · Empty the dishwasher'), findsNothing);
      expect(find.text('Waiting for you (2)'), findsOneWidget);
      expect(find.text('Approve all (2)'), findsOneWidget);
      expect(await _pendingCount(tester), 2);
      expect(await _completionStatus(tester, 1), 'approved');

      final bonus = await _bonusRows(tester);
      expect(bonus, hasLength(bonusBefore.length + 1));
      final written = bonus.firstWhere(
        (row) => row.note == 'Empty the dishwasher' && row.childId == 'maya',
      );
      expect(written.amountPence, 15);
      expect(written.type, 'quest_bonus');

      await disposeApp(tester);
    });

    testWidgets('"Not yet" flips the completion and writes no ledger row', (
      tester,
    ) async {
      await pump(tester);
      final bonusBefore = await _bonusRows(tester);

      await _tapRowButton(tester, 'Leo · Make your bed', 'Not yet');

      expect(find.text('Leo · Make your bed'), findsNothing);
      expect(find.text('Waiting for you (2)'), findsOneWidget);
      expect(await _pendingCount(tester), 2);
      expect(await _completionStatus(tester, 3), 'not_yet');
      expect(
        await _bonusRows(tester),
        bonusBefore,
        reason: 'the kind note moves no coins — the ledger is the money truth',
      );
      expect(find.byType(SnackBar), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('"Approve all (3)" drains the inbox into the ledger', (
      tester,
    ) async {
      await pump(tester);
      final bonusBefore = await _bonusRows(tester);

      await tester.tap(find.byKey(const ValueKey<String>('p11_approve_all')));
      await tester.pump();
      await _settle(tester);

      expect(await _pendingCount(tester), 0);
      final bonus = await _bonusRows(tester);
      expect(bonus, hasLength(bonusBefore.length + 3));
      final written = bonus.sublist(bonusBefore.length);
      expect(written.fold<int>(0, (sum, row) => sum + row.amountPence), 30);
      // The landing state, not an error: empty copy, no CTA, no cards.
      expect(find.text('All caught up'), findsOneWidget);
      expect(find.byType(ApprovalsBottomCta), findsNothing);
      expect(find.byType(ApprovalCard), findsNothing);
      expect(find.text('Waiting for you (0)'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('a second tap on the same Approve writes only once', (
      tester,
    ) async {
      // A gated repository holds the row in its busy state long enough for a
      // second tap to land — against the real database otherwise the write
      // finishes inside the first frame and the window closes.
      final repository = _GatedWritesRepository(
        GetIt.instance<ApprovalsRepository>(),
      );
      await _useRepository(repository);
      await pump(tester);
      final bonusBefore = await _bonusRows(tester);

      final approve = find.byKey(const ValueKey<String>('p11_approve_1'));
      await tester.tap(approve);
      await tester.pump();

      // The card is busy: loading, disabled, so a second tap cannot queue a
      // second write.
      final busy = tester.widget<NestButton>(approve);
      expect(busy.loading, isTrue);
      expect(busy.onPressed, isNull);
      expect(repository.approveCalls, 1);
      await tester.tap(approve, warnIfMissed: false);
      await tester.pump();
      expect(repository.approveCalls, 1, reason: 'a disabled pill is inert');

      repository.openGate();
      await _settle(tester);

      expect(await _pendingCount(tester), 2);
      expect(
        await _bonusRows(tester),
        hasLength(bonusBefore.length + 1),
        reason: 'one tap, one ledger row',
      );

      await disposeApp(tester);
    });

    testWidgets('two cards can be busy at once, and both writes land', (
      tester,
    ) async {
      final repository = _GatedWritesRepository(
        GetIt.instance<ApprovalsRepository>(),
      );
      await _useRepository(repository);
      await pump(tester);
      final bonusBefore = await _bonusRows(tester);

      await tester.tap(find.byKey(const ValueKey<String>('p11_approve_1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('p11_approve_2')));
      await tester.pump();

      // `busyIds` is a set, and bloc runs the two handlers concurrently: both
      // cards spin at once while neither has finished.
      expect(repository.approveCalls, 2);
      for (final key in const <String>['p11_approve_1', 'p11_approve_2']) {
        final button = tester.widget<NestButton>(
          find.byKey(ValueKey<String>(key)),
        );
        expect(button.loading, isTrue, reason: key);
        expect(button.onPressed, isNull, reason: key);
      }
      // BUG-P11-4: the decision the parent did NOT make must not go busy —
      // only the tapped pill spins.
      for (final key in const <String>['p11_not_yet_1', 'p11_not_yet_2']) {
        final button = tester.widget<NestButton>(
          find.byKey(ValueKey<String>(key)),
        );
        expect(button.loading, isFalse, reason: key);
        expect(
          button.onPressed,
          isNull,
          reason: '$key stays inert while the card is busy',
        );
      }
      // The third card is untouched and still actionable.
      expect(
        tester
            .widget<NestButton>(
              find.byKey(const ValueKey<String>('p11_approve_3')),
            )
            .onPressed,
        isNotNull,
      );

      repository.openGate();
      await _settle(tester);

      expect(await _pendingCount(tester), 1);
      expect(await _bonusRows(tester), hasLength(bonusBefore.length + 2));
      expect(find.text('Waiting for you (1)'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('the last row scrolls into view and still approves', (
      tester,
    ) async {
      await pump(tester);
      // A short screen puts the third card below the fold, so the lazily built
      // tail of the list has to scroll and keep working.
      tester.view.physicalSize = const Size(320 * 3, 600 * 3);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final listBottom = tester.getRect(find.byType(ListView)).bottom;
      expect(
        find.text('Leo · Make your bed'),
        findsNothing,
        reason: 'on a short screen the third card is not even built yet',
      );
      expect(
        find.byType(ListView),
        findsOneWidget,
        reason: 'the inbox is a lazily built list that must scroll',
      );

      await tester.fling(find.byType(ListView), const Offset(0, -600), 1200);
      await _settle(tester);

      expect(find.text('Leo · Make your bed'), findsOneWidget);
      expect(
        tester.getRect(find.text('Leo · Make your bed')).top,
        lessThan(listBottom),
        reason: 'scrolling brings the last row inside the viewport',
      );
      await _tapRowButton(tester, 'Leo · Make your bed', 'Approve');
      expect(find.text('Waiting for you (2)'), findsOneWidget);
      expect(await _pendingCount(tester), 2);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P11 approvals — action errors', () {
    testWidgets('a rejected write keeps the card and shows the error once', (
      tester,
    ) async {
      await _useRepository(
        _RejectingWritesRepository(GetIt.instance<ApprovalsRepository>()),
      );
      await pump(tester);

      await _tapRowButton(tester, 'Maya · Empty the dishwasher', 'Approve');

      // The row did not leave the inbox and no money moved.
      expect(find.text('Maya · Empty the dishwasher'), findsOneWidget);
      expect(find.text('Waiting for you (3)'), findsOneWidget);
      expect(await _pendingCount(tester), 3);

      final tokens = tester.element(find.byType(ApprovalsView)).nest;
      final snack = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snack.backgroundColor, tokens.danger);
      final message = tester.widget<Text>(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining(_RejectingWritesRepository.message),
        ),
      );
      expect(message.style?.color, tokens.onLeaf);
      // The listener consumes the error so a rebuild cannot re-fire it.
      expect(_blocOf(tester).state.actionError, isNull);

      await disposeApp(tester);
    });

    testWidgets('the next rejected write surfaces the same error again', (
      tester,
    ) async {
      await _useRepository(
        _RejectingWritesRepository(GetIt.instance<ApprovalsRepository>()),
      );
      await pump(tester);

      await _tapRowButton(tester, 'Maya · Empty the dishwasher', 'Approve');
      expect(find.byType(SnackBar), findsOneWidget);

      // Same message, second failure: the SnackBar can only reappear because
      // the first error was cleared. Without `ApprovalsActionErrorConsumed` the
      // bloc would dedupe the identical string and stay silent.
      await _tapRowButton(tester, 'Maya · Lay the table', 'Approve');
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.textContaining(_RejectingWritesRepository.message),
        ),
        findsOneWidget,
      );
      expect(find.text('Waiting for you (3)'), findsOneWidget);

      await disposeApp(tester);
    });
  });

  group('P11 approvals — widths and text scale', () {
    for (final width in const <double>[320, 390, 430]) {
      for (final scale in const <double>[1, 1.3]) {
        for (final theme in ThemeMode.values) {
          testWidgets(
            '${width.toInt()} wide, text scale $scale, ${theme.name}',
            (tester) async {
              await pump(tester, theme: theme);
              tester.view.physicalSize = Size(width * 3, 844 * 3);
              tester.platformDispatcher.textScaleFactorTestValue = scale;
              addTearDown(
                tester.platformDispatcher.clearTextScaleFactorTestValue,
              );
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 300));

              expect(tester.takeException(), isNull);
              expect(find.text('Waiting for you (3)'), findsOneWidget);
              expect(find.text('Approve all (3)'), findsOneWidget);

              // ALIGNMENT (owner rule): the same 20 px gutter at every width,
              // banner / card / CTA aligned to the same two edges.
              for (final rect in <(String, Rect)>[
                ('helper', tester.getRect(find.byType(ApprovalsHelperBanner))),
                (
                  'card',
                  tester.getRect(_cardFor('Maya · Empty the dishwasher')),
                ),
                (
                  'cta',
                  tester.getRect(
                    find.byKey(const ValueKey<String>('p11_approve_all')),
                  ),
                ),
              ]) {
                expect(
                  rect.$2.left,
                  closeTo(NestSpacing.padSide, 0.01),
                  reason: '${rect.$1} left gutter at ${width}px',
                );
                expect(
                  rect.$2.right,
                  closeTo(width - NestSpacing.padSide, 0.01),
                  reason: '${rect.$1} right gutter at ${width}px',
                );
              }

              // Every parent control still clears the 44 px floor.
              final notYet = tester.getRect(
                find.byKey(const ValueKey<String>('p11_not_yet_1')),
              );
              expect(notYet.height, greaterThanOrEqualTo(NestDevice.tapParent));
              expect(notYet.width, greaterThanOrEqualTo(NestDevice.tapParent));
              expect(
                tester
                    .getRect(
                      find.byKey(const ValueKey<String>('p11_approve_all')),
                    )
                    .height,
                greaterThanOrEqualTo(NestDevice.tapParent),
              );
              // The title is one clipped line, never an overflow.
              expect(tester.takeException(), isNull);

              await disposeApp(tester);
            },
          );
        }
      }
    }
  });

  group('P11 approvals — dark mode', () {
    testWidgets(
      'dark mode paints dark paper, surface cards and a leaf banner',
      (tester) async {
        await pump(tester, theme: ThemeMode.dark);

        final tokens = tester.element(find.byType(ApprovalsView)).nest;
        final light = NestTheme.light().extension<NestTokens>()!;
        // The dark scheme must actually be in play.
        expect(tokens.paper, isNot(light.paper));
        expect(tokens.surface, isNot(light.surface));
        expect(tokens.leafTint, isNot(light.leafTint));

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(scaffold.backgroundColor, tokens.paper);

        final shapes = _boxDecorations(tester);
        expect(
          shapes.any(
            (d) =>
                d.color == tokens.leafTint && d.borderRadius == NestRadii.allM,
          ),
          isTrue,
          reason: '.helper keeps its leaf-tint fill in dark',
        );
        expect(
          shapes.where(
            (d) =>
                d.color == tokens.surface && d.borderRadius == NestRadii.allL,
          ),
          hasLength(3),
          reason: 'three cards, each a 24-radius surface box in dark',
        );

        // BOTTOM EDGE (owner rule) in dark too: no page strip under the bar.
        final screen = tester.getRect(find.byType(Scaffold).first);
        final cta = tester.getRect(find.byType(ApprovalsBottomCta));
        expect(cta.bottom, screen.bottom);
        final bar = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(ApprovalsBottomCta),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        expect((bar.decoration as BoxDecoration).color, tokens.surface);

        await disposeApp(tester);
      },
    );
  });

  group('P11 approvals — tap targets', () {
    testWidgets('every parent control is at least 44 × 44', (tester) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);

      final back = tester.getRect(find.bySemanticsLabel('Back to Today'));
      expect(back.width, greaterThanOrEqualTo(NestDevice.tapParent));
      expect(back.height, greaterThanOrEqualTo(NestDevice.tapParent));

      for (final completionId in const <int>[1, 2, 3]) {
        for (final prefix in const <String>['p11_not_yet_', 'p11_approve_']) {
          final rect = tester.getRect(
            find.byKey(ValueKey<String>('$prefix$completionId')),
          );
          expect(
            rect.height,
            greaterThanOrEqualTo(NestDevice.tapParent),
            reason: '$prefix$completionId',
          );
          expect(rect.width, greaterThanOrEqualTo(NestDevice.tapParent));
        }
      }

      final cta = tester.getRect(
        find.byKey(const ValueKey<String>('p11_approve_all')),
      );
      expect(cta.height, greaterThanOrEqualTo(NestDevice.tapParent));
      expect(cta.width, greaterThanOrEqualTo(NestDevice.tapParent));
      semantics.dispose();

      await disposeApp(tester);
    });

    testWidgets('this is a parent screen: no KidScope, so 56 does not apply', (
      tester,
    ) async {
      await pump(tester);

      // The kid floor (`NestDevice.tapKid`) only applies inside `KidScope`;
      // `/approvals` is parent mode, so the applicable floor is 44.
      expect(find.byType(KidScope), findsNothing);
      expect(NestDevice.tapParent, 44);
      expect(NestDevice.tapKid, 56);

      await disposeApp(tester);
    });
  });

  group('P11 approvals — navigation', () {
    testWidgets('a cold /approvals launch has nothing to pop: back → /today', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);

      final router = GoRouter.of(tester.element(find.byType(ApprovalsView)));
      expect(
        router.canPop(),
        isFalse,
        reason: 'INITIAL_ROUTE=/approvals renders one page with no stack below',
      );

      tester.semantics.performAction(
        find.semantics.byLabel('Back to Today'),
        SemanticsAction.tap,
      );
      await tester.pump();
      await _settle(tester);

      expect(pushedPath(tester), '/today');
      expect(find.byType(ApprovalsView), findsNothing);
      semantics.dispose();

      await disposeApp(tester);
    });

    testWidgets('pushed from Today, back pops back to Today', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpAppRoute(tester, '/today');

      await tester.tap(find.text('Review'));
      await tester.pump();
      await _settle(tester);
      expect(pushedPath(tester), '/approvals');

      final router = GoRouter.of(tester.element(find.byType(ApprovalsView)));
      expect(router.canPop(), isTrue, reason: 'Today sits below the push');

      tester.semantics.performAction(
        find.semantics.byLabel('Back to Today'),
        SemanticsAction.tap,
      );
      await tester.pump();
      await _settle(tester);

      expect(pushedPath(tester), '/today');
      expect(find.byType(ApprovalsView), findsNothing);
      semantics.dispose();

      await disposeApp(tester);
    });

    testWidgets('approve, not-yet and approve all never navigate away', (
      tester,
    ) async {
      await pump(tester);
      expect(pushedPath(tester), '/approvals');

      await _tapRowButton(tester, 'Maya · Empty the dishwasher', 'Approve');
      expect(pushedPath(tester), '/approvals');

      await _tapRowButton(tester, 'Maya · Lay the table', 'Not yet');
      expect(pushedPath(tester), '/approvals');

      await tester.tap(find.byKey(const ValueKey<String>('p11_approve_all')));
      await tester.pump();
      await _settle(tester);

      expect(pushedPath(tester), '/approvals');
      expect(find.text('All caught up'), findsOneWidget);
      expect(find.byType(ApprovalsView), findsOneWidget);

      await disposeApp(tester);
    });
  });

  group('P11 approvals — semantics', () {
    testWidgets('performAction(tap) on "Approve all (3)" drains the database', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);
      final bonusBefore = await _bonusRows(tester);

      tester.semantics.performAction(
        find.semantics.byLabel('Approve all (3)'),
        SemanticsAction.tap,
      );
      await tester.pump();
      await _settle(tester);

      expect(find.text('All caught up'), findsOneWidget);
      expect(await _pendingCount(tester), 0);
      expect(
        (await _bonusRows(tester)).length,
        bonusBefore.length + 3,
        reason: 'performAction must drive the real writes, not just the flag',
      );
      semantics.dispose();

      await disposeApp(tester);
    });

    testWidgets('each card announces one summary label, buttons stay live', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pump(tester);

      const summaries = <String>[
        'Maya, Empty the dishwasher, Today 8:12am, 15 coins',
        'Maya, Lay the table, Today 8:05am, 10 coins',
        'Leo, Make your bed, Today 7:58am, 5 coins',
      ];
      for (final summary in summaries) {
        expect(find.bySemanticsLabel(summary), findsOneWidget);
      }
      for (final card in <String>[
        'Maya · Empty the dishwasher',
        'Maya · Lay the table',
        'Leo · Make your bed',
      ]) {
        final inside = _cardFor(card);
        expect(
          _hasTap(
            tester,
            find.descendant(
              of: inside,
              matching: find.bySemanticsLabel('Not yet'),
            ),
          ),
          isTrue,
          reason: '$card · Not yet',
        );
        expect(
          _hasTap(
            tester,
            find.descendant(
              of: inside,
              matching: find.bySemanticsLabel('Approve'),
            ),
          ),
          isTrue,
          reason: '$card · Approve',
        );
      }
      semantics.dispose();

      await disposeApp(tester);
    });

    testWidgets(
      "only the tapped pill spins; the busy card's other pill is inert",
      (tester) async {
        final semantics = tester.ensureSemantics();
        // Driven through the real screen with a gated write so the busy state
        // lasts long enough to inspect: `ApprovalCard` remembers WHICH button
        // was pressed (BUG-P11-4), which a hand-built `busyIds` list cannot
        // express.
        final repository = _GatedWritesRepository(
          GetIt.instance<ApprovalsRepository>(),
        );
        await _useRepository(repository);
        await pump(tester);

        await tester.tap(find.byKey(const ValueKey<String>('p11_approve_1')));
        await tester.pump();

        // The tapped pill: loading, disabled, no tap action, announced as
        // disabled (RULES §8).
        final approve = find.byKey(const ValueKey<String>('p11_approve_1'));
        expect(tester.widget<NestButton>(approve).loading, isTrue);
        expect(tester.widget<NestButton>(approve).onPressed, isNull);
        expect(
          _data(tester, approve).flagsCollection.isEnabled.toBoolOrNull(),
          isFalse,
        );
        expect(_data(tester, approve).hasAction(SemanticsAction.tap), isFalse);

        // BUG-P11-4: the decision the parent did not make must NOT spin, and
        // it must not be tappable either while its card is locked.
        final notYet = find.byKey(const ValueKey<String>('p11_not_yet_1'));
        expect(tester.widget<NestButton>(notYet).loading, isFalse);
        expect(tester.widget<NestButton>(notYet).onPressed, isNull);
        expect(
          _data(tester, notYet).hasAction(SemanticsAction.tap),
          isFalse,
          reason: 'a disabled control passes no tap action (RULES §8)',
        );

        // The other cards stay fully live.
        for (final key in const <String>['p11_not_yet_2', 'p11_approve_2']) {
          final button = tester.widget<NestButton>(
            find.byKey(ValueKey<String>(key)),
          );
          expect(button.loading, isFalse, reason: key);
          expect(button.onPressed, isNotNull, reason: key);
          expect(_hasTap(tester, find.byKey(ValueKey<String>(key))), isTrue);
        }

        repository.openGate();
        await _settle(tester);
        semantics.dispose();

        await disposeApp(tester);
      },
    );
  });

  group('P11 approvals — copy', () {
    testWidgets("the screen uses the design's exact characters", (
      tester,
    ) async {
      await pump(tester);

      // `“Not yet” sends a kind note — no coins are taken away.`
      final helper = tester.widget<Text>(find.text(approvalsHelperCopy));
      final helperRunes = approvalsHelperCopy.runes.toSet();
      expect(helperRunes, contains(0x201C), reason: 'left curly quote');
      expect(helperRunes, contains(0x201D), reason: 'right curly quote');
      expect(helperRunes, contains(0x2014), reason: 'em dash');
      expect(helperRunes, isNot(contains(0x0022)), reason: 'no straight quote');
      expect(approvalsHelperCopy, isNot(contains('--')));
      expect(helper.data, approvalsHelperCopy);

      // `Maya · Empty the dishwasher` — middle dot U+00B7 with single spaces.
      final who = tester
          .widget<Text>(find.text('Maya · Empty the dishwasher'))
          .data!;
      expect(who, contains(' \u00B7 '));
      expect(who.runes, contains(0x00B7));
      expect(who.runes, isNot(contains(0x2022)), reason: 'not a bullet');
      expect(who.runes.every((rune) => rune < 0x2019), isTrue);

      // `Today 8:12am · 15 coins` — same separator, no typographic rewrite.
      final stamp = tester
          .widget<RichText>(_richText('Today 8:12am · 15 coins'))
          .text
          .toPlainText();
      expect(stamp, 'Today 8:12am \u00B7 15 coins');

      // The title and the CTA carry the live count, in ASCII parens as in the
      // HTML (`Waiting for you (3)`).
      expect(find.text('Waiting for you (3)'), findsOneWidget);
      expect(find.text('Approve all (3)'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });
}
