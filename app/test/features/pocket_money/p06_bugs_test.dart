// P06 Pocket money setup — Stage 6 adversarial bug tests (iteration 7).
//
// Every finding from iterations 2–6 is fixed and runs UNskipped as a
// regression guard: the rapid-tap/day chains, the pill geometry, the inline
// write error, P06-BUG-11 (balanced H1), P06-BUG-12 (stepper minus U+2212)
// and P06-BUG-13 (coin-label truncation at 320 × 1.3). Iteration 7 adds the
// ACCESSIBILITY ACTIONS guards (every feature-owned control exposes
// SemanticsAction.tap and performAction(tap) writes the DB) and the coin-row
// right-alignment guard.
//
// The group at the bottom ("attacks that hold") is NOT skipped: it documents
// the adversarial probes that passed (kid-mode guard, restart persistence,
// data extremes), so regressions are caught here too.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/semantics.dart' show SemanticsAction;
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pocket_money/data/pocket_money_repository_impl.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_ledger_data.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_bloc.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_event.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_state.dart';
import 'package:nestling/features/pocket_money/presentation/views/pocket_money_setup_view.dart';

import '../../test_scope.dart';
import 'ledger_data_fallback.dart';

/// `Seed.demo` P06 setup: `both`, Saturday, 1p/coin, Maya £3.00 then Leo
/// £1.50 (insertion order).
const PocketMoneySetup _demoSetup = PocketMoneySetup(
  mode: 'both',
  payoutDay: 6,
  coinValuePencePerCoin: 1,
  children: <PocketMoneySetupChild>[
    PocketMoneySetupChild(
      id: 'maya',
      nickname: 'Maya',
      avatarColour: 'lilac',
      weeklyBasePence: 300,
    ),
    PocketMoneySetupChild(
      id: 'leo',
      nickname: 'Leo',
      avatarColour: 'peach',
      weeklyBasePence: 150,
    ),
  ],
);

/// `Seed.demo` P06 setup with a different coin value: a distinct state used
/// to force an unrelated `watchSetup` re-emission (P06-BUG-09).
const PocketMoneySetup _demoSetupCoin2 = PocketMoneySetup(
  mode: 'both',
  payoutDay: 6,
  coinValuePencePerCoin: 2,
  children: <PocketMoneySetupChild>[
    PocketMoneySetupChild(
      id: 'maya',
      nickname: 'Maya',
      avatarColour: 'lilac',
      weeklyBasePence: 300,
    ),
    PocketMoneySetupChild(
      id: 'leo',
      nickname: 'Leo',
      avatarColour: 'peach',
      weeklyBasePence: 150,
    ),
  ],
);

/// Fake repository with caller-controlled streams and recorded writes. Owns
/// no database, timers or tickers; `watch…()` factories hand out the streams
/// the test provides.
class _RecordingPocketMoneyRepository implements PocketMoneyRepository {
  _RecordingPocketMoneyRepository({
    Stream<PocketMoneySetup>? setupStream,
    Stream<List<PocketMoneyEntry>>? itemsStream,
    this.setModeError,
    this.setModeFuture,
    this.setPayoutDayFuture,
  }) : _setupStream = setupStream ?? Stream<PocketMoneySetup>.value(_demoSetup),
       _itemsStream =
           itemsStream ??
           Stream<List<PocketMoneyEntry>>.value(const <PocketMoneyEntry>[]);

  final Stream<PocketMoneySetup> _setupStream;
  final Stream<List<PocketMoneyEntry>> _itemsStream;

  /// When set, [setMode] throws it (write-failure repro).
  final Exception? setModeError;

  /// When set, [setMode] waits for it before completing (async-gap repro).
  final Future<void>? setModeFuture;

  /// When set, [setPayoutDay] waits for it before recording the write
  /// (in-flight payout-day repro for P06-BUG-09).
  final Future<void>? setPayoutDayFuture;

  final List<({String childId, int pence})> baseWrites =
      <({String childId, int pence})>[];
  final List<String> modeWrites = <String>[];
  final List<int> dayWrites = <int>[];

  @override
  Future<List<PocketMoneyEntry>> getItems() => watchItems().first;

  @override
  Stream<List<PocketMoneyEntry>> watchItems() => _itemsStream;

  @override
  Stream<List<PocketMoneyEntry>> watchLedger(String childId) => _itemsStream;

  // P12: same setup × items combine the bloc always consumed (no goals —
  // fakes own no savings table).
  @override
  Stream<MoneyLedgerData> watchLedgerData() =>
      ledgerDataFallback(watchSetup(), watchItems());

  @override
  Future<OwedSummary> owed(String childId) async => OwedSummary(
    childId: childId,
    totalPence: 0,
    basePence: 0,
    questsPence: 0,
  );

  @override
  Stream<OwedSummary> watchOwed(String childId) => Stream<OwedSummary>.value(
    OwedSummary(childId: childId, totalPence: 0, basePence: 0, questsPence: 0),
  );

  @override
  Future<void> addMoney({
    required String childId,
    required int amountPence,
    required String note,
  }) async {}

  @override
  Future<void> recordSpending({
    required String childId,
    required int amountPence,
    required String note,
  }) async {}

  @override
  Future<void> recordPayout({
    required String childId,
    required int amountPence,
    int savingsMovePence = 0,
    String? goalId,
  }) async {}

  @override
  Stream<PocketMoneySetup> watchSetup() => _setupStream;

  @override
  Future<void> setMode(String mode) async {
    final pending = setModeFuture;
    if (pending != null) await pending;
    final error = setModeError;
    if (error != null) throw error;
    modeWrites.add(mode);
  }

  @override
  Future<void> setPayoutDay(int day) async {
    final pending = setPayoutDayFuture;
    if (pending != null) await pending;
    dayWrites.add(day);
  }

  @override
  Future<void> setWeeklyBasePence(String childId, int pence) async =>
      baseWrites.add((childId: childId, pence: pence));
}

/// Pumps [PocketMoneySetupView] directly (no router) under the real theme.
/// The bloc is deliberately not closed: under the widget-test FakeAsync clock
/// `close()` deadlocks once a load has subscribed the combined watch streams
/// (documented in `pocket_money_setup_view_test.dart`). The fake owns no
/// timers, so the leftover subscription is inert.
Future<PocketMoneyBloc> _pumpSetupView(
  WidgetTester tester, {
  required PocketMoneyRepository repository,
}) async {
  final bloc = PocketMoneyBloc(repository: repository);
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      home: BlocProvider<PocketMoneyBloc>.value(
        value: bloc,
        child: const PocketMoneySetupView(),
      ),
    ),
  );
  await tester.pump();
  return bloc;
}

/// The visible day pill for [day] (1 = Mon): its painted `DecoratedBox`.
Finder _dayPill(int day) => find
    .descendant(
      of: find.byKey(ValueKey('p06_day_$day')),
      matching: find.byType(DecoratedBox),
    )
    .first;

/// Loads the bundled Inter/Nunito faces so the widget tree reproduces the
/// design's own metrics (same pattern as
/// `test/features/privacy_consent/privacy_consent_geometry_test.dart`).
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
  // -- P06-BUG-01 ---------------------------------------------------------

  test(
    'P06-BUG-01 (fixed): two quick "+" taps must each add 50p (real repo)',
    () async {
      await setUpTestScope();
      final repository = GetIt.instance<PocketMoneyRepository>();
      final bloc = PocketMoneyBloc(repository: repository)
        ..add(const PocketMoneyLoadRequested());
      await bloc.stream.firstWhere((state) => state.setup != null);

      bloc
        ..add(const PocketMoneyWeeklyBaseStepped('maya', 50))
        ..add(const PocketMoneyWeeklyBaseStepped('maya', 50));
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final setup = await repository.watchSetup().first;
      // Two taps on "+" must move £3.00 → £3.50 → £4.00.
      expect(setup.childById('maya')!.weeklyBasePence, 400);
      await bloc.close();
    },
  );

  test(
    'P06-BUG-01b (fixed): three quick "+" taps chain to £4.50 (real repo)',
    () async {
      await setUpTestScope();
      final repository = GetIt.instance<PocketMoneyRepository>();
      final bloc = PocketMoneyBloc(repository: repository)
        ..add(const PocketMoneyLoadRequested());
      await bloc.stream.firstWhere((state) => state.setup != null);

      bloc
        ..add(const PocketMoneyWeeklyBaseStepped('maya', 50))
        ..add(const PocketMoneyWeeklyBaseStepped('maya', 50))
        ..add(const PocketMoneyWeeklyBaseStepped('maya', 50));
      await Future<void>.delayed(const Duration(milliseconds: 400));

      final setup = await repository.watchSetup().first;
      expect(setup.childById('maya')!.weeklyBasePence, 450);
      await bloc.close();
    },
  );

  test(
    'P06-BUG-01c (fixed): a quick "+" then "−" nets back to £3.00 (real repo)',
    () async {
      await setUpTestScope();
      final repository = GetIt.instance<PocketMoneyRepository>();
      final bloc = PocketMoneyBloc(repository: repository)
        ..add(const PocketMoneyLoadRequested());
      await bloc.stream.firstWhere((state) => state.setup != null);

      bloc
        ..add(const PocketMoneyWeeklyBaseStepped('maya', 50))
        ..add(const PocketMoneyWeeklyBaseStepped('maya', -50));
      await Future<void>.delayed(const Duration(milliseconds: 300));

      final setup = await repository.watchSetup().first;
      expect(setup.childById('maya')!.weeklyBasePence, 300);
      await bloc.close();
    },
  );

  // -- P06-BUG-02 ---------------------------------------------------------

  test('P06-BUG-02 (fixed): a fast Sun→Sat correction must end on Saturday '
      '(real repo)', () async {
    await setUpTestScope();
    final repository = GetIt.instance<PocketMoneyRepository>();
    final bloc = PocketMoneyBloc(repository: repository)
      ..add(const PocketMoneyLoadRequested());
    await bloc.stream.firstWhere((state) => state.setup != null);

    // Parent taps Sun, changes their mind and taps Sat straight away.
    bloc
      ..add(const PocketMoneyPayoutDayChanged(7))
      ..add(const PocketMoneyPayoutDayChanged(6));
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final setup = await repository.watchSetup().first;
    // FIXED (iteration 3, logic chunk): the guard now compares against the
    // last requested day; must stay green.
    expect(setup.payoutDay, 6);
    await bloc.close();
  });

  test(
    'P06-BUG-02b (fixed): three rapid day taps end on the last requested day',
    () async {
      await setUpTestScope();
      final repository = GetIt.instance<PocketMoneyRepository>();
      final bloc = PocketMoneyBloc(repository: repository)
        ..add(const PocketMoneyLoadRequested());
      await bloc.stream.firstWhere((state) => state.setup != null);

      // Sun → Sat → Mon in one turn; the last tap must win.
      bloc
        ..add(const PocketMoneyPayoutDayChanged(7))
        ..add(const PocketMoneyPayoutDayChanged(6))
        ..add(const PocketMoneyPayoutDayChanged(1));
      await Future<void>.delayed(const Duration(milliseconds: 400));

      final setup = await repository.watchSetup().first;
      expect(setup.payoutDay, 1);
      await bloc.close();
    },
  );

  // -- P06-BUG-03 ---------------------------------------------------------

  testWidgets('P06-BUG-03 (fixed): a day pill paints at the design size '
      '(32 high, 13px label)', (tester) async {
    await setUpTestScope();
    await pumpAppRoute(tester, '/pocket-money-setup');

    // The design `.chip.day` is a 32-high pill with a 13px centred label
    // filling the cell. Measured on the pill's own box inside the cell;
    // the iteration-2 FittedBox-scaled NestChip is gone.
    final pill = tester.getSize(
      find
          .descendant(
            of: find.byKey(const ValueKey('p06_day_1')),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect(pill.height, greaterThanOrEqualTo(30));
    expect(pill.height, lessThanOrEqualTo(34));

    final label = tester.widget<Text>(find.text('Mon'));
    expect(label.style?.fontSize, 13);

    await disposeApp(tester);
  });

  // P06-BUG-04 (iteration 3, ≥44 day cells) DELETED: the demand is
  // superseded by ORCHESTRATOR_NOTES iter 4 #2 — the 7 chips must sit
  // inside the card's 16px inset, 32px high with even gaps, and the ≥44
  // tap band is the NestChipWrap hitSlop (guarded below + in
  // pocket_money_setup_view_test.dart).

  // -- P06-BUG-05 ---------------------------------------------------------

  testWidgets(
    'P06-BUG-05 (fixed): a failed write keeps the form and shows an inline '
    'error',
    (tester) async {
      final repository = _RecordingPocketMoneyRepository(
        setModeError: Exception('database is locked'),
      );
      final bloc = await _pumpSetupView(tester, repository: repository);
      bloc.add(const PocketMoneyLoadRequested());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Weekly amount'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('p06_option_weekly')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // The write failed; the parent must still see the options with the
      // error inline, not lose the whole form to the load-failure body.
      expect(find.text('Weekly amount'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
      expect(find.textContaining('database is locked'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  // -- P06-BUG-06 ---------------------------------------------------------

  test(
    'P06-BUG-06 (fixed): errorMessage must clear when the setup recovers',
    () async {
      final setupController = StreamController<PocketMoneySetup>.broadcast();
      final itemsController =
          StreamController<List<PocketMoneyEntry>>.broadcast();
      final repository = _RecordingPocketMoneyRepository(
        setupStream: setupController.stream,
        itemsStream: itemsController.stream,
        setModeError: Exception('database is locked'),
      );
      final bloc = PocketMoneyBloc(repository: repository)
        ..add(const PocketMoneyLoadRequested());
      // The load handler subscribes to both sources before the first emission,
      // so wait for its `loading` state (broadcast streams have no replay).
      await bloc.stream.firstWhere(
        (state) => state.status == PocketMoneyStatus.loading,
      );
      setupController.add(_demoSetup);
      itemsController.add(const <PocketMoneyEntry>[]);
      await bloc.stream.firstWhere(
        (state) => state.status == PocketMoneyStatus.loaded,
      );

      bloc.add(const PocketMoneyModeChanged('weekly'));
      await bloc.stream.firstWhere(
        (state) => state.status == PocketMoneyStatus.failure,
      );
      expect(bloc.state.errorMessage, isNotNull);

      // The next stream emission proves the database is healthy again; the
      // stale error must not stay in state.
      setupController.add(
        const PocketMoneySetup(
          mode: 'both',
          payoutDay: 5,
          coinValuePencePerCoin: 1,
          children: <PocketMoneySetupChild>[
            PocketMoneySetupChild(
              id: 'maya',
              nickname: 'Maya',
              avatarColour: 'lilac',
              weeklyBasePence: 300,
            ),
            PocketMoneySetupChild(
              id: 'leo',
              nickname: 'Leo',
              avatarColour: 'peach',
              weeklyBasePence: 150,
            ),
          ],
        ),
      );
      await bloc.stream.firstWhere(
        (state) => state.status == PocketMoneyStatus.loaded,
      );

      expect(bloc.state.errorMessage, isNull);
      await bloc.close();
      await setupController.close();
      await itemsController.close();
    },
  );

  // -- P06-BUG-07 ---------------------------------------------------------

  test(
    'P06-BUG-07 (fixed): a stepper event for an unknown child must not write',
    () async {
      final repository = _RecordingPocketMoneyRepository();
      final bloc = PocketMoneyBloc(repository: repository)
        ..add(const PocketMoneyLoadRequested());
      await bloc.stream.firstWhere((state) => state.setup != null);

      bloc.add(const PocketMoneyWeeklyBaseStepped('ghost', 50));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // FIXED (iteration 3, logic chunk): the handler no-ops on an unknown
      // child; must stay green.
      expect(repository.baseWrites, isEmpty);
      await bloc.close();
    },
  );

  // -- P06-BUG-08 ---------------------------------------------------------

  testWidgets(
    'P06-BUG-08 (fixed): day chips align with the card section labels',
    (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/pocket-money-setup');

      // The design keeps the day row inside the card's 16px inset, so the
      // first chip's left edge lines up with the `Payout day` label above
      // it (iteration-3's 2px breakout is gone).
      final labelLeft = tester.getTopLeft(find.text('Payout day')).dx;
      final firstCellLeft = tester
          .getTopLeft(find.byKey(const ValueKey('p06_day_1')))
          .dx;
      expect(firstCellLeft, moreOrLessEquals(labelLeft, epsilon: 1));

      await disposeApp(tester);
    },
  );

  // -- P06-BUG-09 ---------------------------------------------------------

  test(
    'P06-BUG-09 (fixed): a day correction survives an unrelated re-emission',
    () async {
      final setupController = StreamController<PocketMoneySetup>.broadcast();
      final itemsController =
          StreamController<List<PocketMoneyEntry>>.broadcast();
      final pending = Completer<void>();
      final repository = _RecordingPocketMoneyRepository(
        setupStream: setupController.stream,
        itemsStream: itemsController.stream,
        setPayoutDayFuture: pending.future,
      );
      final bloc = PocketMoneyBloc(repository: repository)
        ..add(const PocketMoneyLoadRequested());
      await bloc.stream.firstWhere(
        (state) => state.status == PocketMoneyStatus.loading,
      );
      setupController.add(_demoSetup);
      itemsController.add(const <PocketMoneyEntry>[]);
      await bloc.stream.firstWhere(
        (state) => state.status == PocketMoneyStatus.loaded,
      );

      // Tap Sun; the write is still in flight.
      bloc.add(const PocketMoneyPayoutDayChanged(7));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // An unrelated emission arrives before the Sun write commits (e.g. the
      // ledger or children tables changed on another screen); it still
      // reports the old day 6 and clears the pending request.
      setupController.add(_demoSetupCoin2);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      // The parent corrects back to Sat.
      bloc.add(const PocketMoneyPayoutDayChanged(6));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      pending.complete();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      // The last tap was Sat, so the day write chain must end on 6.
      // FIXED (iteration 4, logic chunk): un-skipped, must stay green.
      expect(repository.dayWrites, <int>[7, 6]);
      await bloc.close();
      await setupController.close();
      await itemsController.close();
    },
  );

  // -- iteration-4 ORCHESTRATOR_NOTES guards -------------------------------

  group('P06 iteration-4 orchestrator-note guards', () {
    testWidgets('seed onboarding_kids: children and amounts come from the DB', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.onboardingKids(db);
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/pocket-money-setup');

      // NOTE item 1: Maya £3.00 then Leo £1.50, insertion order, steppers
      // present, nothing hard-coded against the seed.
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('Leo'), findsOneWidget);
      expect(find.text('£3.00'), findsOneWidget);
      expect(find.text('£1.50'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Maya')).dy,
        lessThan(tester.getTopLeft(find.text('Leo')).dy),
      );
      expect(
        find.bySemanticsLabel(RegExp('Less weekly pocket money for Maya')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('More weekly pocket money for Leo')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets(
      'day chips stay inside the card 16px inset: 32px pills, 6px gaps '
      '(390/320/430)',
      (tester) async {
        // NOTE item 2: no chip rect leaves the card's padded rect.
        await setUpTestScope();
        for (final width in <int>[390, 320, 430]) {
          await pumpAppRoute(tester, '/pocket-money-setup');
          tester.view.physicalSize = Size(width * 3, 844 * 3);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));

          final card = tester.getRect(find.byType(NestCard));
          double? previousRight;
          for (var day = 1; day <= 7; day++) {
            final pill = tester.getRect(
              find
                  .descendant(
                    of: find.byKey(ValueKey('p06_day_$day')),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            );
            expect(
              pill.height,
              moreOrLessEquals(NestSpacing.s8, epsilon: 1),
              reason: 'day $day pill height at ${width}dp',
            );
            expect(
              pill.left,
              greaterThanOrEqualTo(card.left + NestSpacing.s4 - 0.01),
              reason: 'day $day leaves the left inset at ${width}dp',
            );
            expect(
              pill.right,
              lessThanOrEqualTo(card.right - NestSpacing.s4 + 0.01),
              reason: 'day $day leaves the right inset at ${width}dp',
            );
            if (previousRight != null) {
              expect(
                pill.left - previousRight,
                moreOrLessEquals(NestSpacing.gap6, epsilon: 0.2),
                reason: 'uneven gap before day $day at ${width}dp',
              );
            }
            previousRight = pill.right;
          }
          expect(tester.takeException(), isNull);
          await disposeApp(tester);
        }
      },
    );

    testWidgets(
      'NestChipWrap: taps 5px above/below and in the gaps reach the chip',
      (tester) async {
        // NOTE item 6: the 32px pills keep the 44px tap target.
        await setUpTestScope();
        await pumpAppRoute(tester, '/pocket-money-setup');

        Finder pill(int day) => find
            .descendant(
              of: find.byKey(ValueKey('p06_day_$day')),
              matching: find.byType(DecoratedBox),
            )
            .first;
        bool selected(int day) =>
            tester
                .getSemantics(find.byKey(ValueKey('p06_day_$day')))
                .getSemanticsData()
                .flagsCollection
                .isSelected ==
            Tristate.isTrue;
        Future<void> settle() async {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 250));
        }

        final sun = tester.getRect(pill(7));
        await tester.tapAt(Offset(sun.center.dx, sun.top - 5));
        await settle();
        expect(selected(7), isTrue, reason: '5px above Sun');

        final mon = tester.getRect(pill(1));
        await tester.tapAt(Offset(mon.center.dx, mon.bottom + 5));
        await settle();
        expect(selected(1), isTrue, reason: '5px below Mon');

        // Gap tap (1px right of Mon's right edge): forwarded to the nearest.
        final tue = tester.getRect(pill(2));
        await tester.tapAt(Offset(mon.right + 1, tue.center.dy));
        await settle();
        expect(selected(1), isTrue, reason: 'gap tap nearest Mon');
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      },
    );

    testWidgets('option cards use the HTML 22/20 line heights and 2px gap', (
      tester,
    ) async {
      // NOTE item 5: card heights match the design so the settings card
      // lands at the design y.
      await setUpTestScope();
      await pumpAppRoute(tester, '/pocket-money-setup');

      for (final pair in <(String, String)>[
        ('Weekly amount', 'A set amount every week'),
        ('Earn per quest', 'Coins turn into pence at payout'),
        ('Both', 'Weekly base + bonus for extra quests'),
      ]) {
        final title = tester.widget<Text>(find.text(pair.$1));
        expect(title.style?.fontSize, 16);
        expect(title.style?.height, 22 / 16);
        final sub = tester.widget<Text>(find.text(pair.$2));
        expect(sub.style?.fontSize, 15);
        expect(sub.style?.height, 20 / 15);
      }
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('coin tile: gold coin asset in the 40×40 token tile', (
      tester,
    ) async {
      // NOTE item 4: the gold coin glyph, not a £ symbol.
      await setUpTestScope();
      await pumpAppRoute(tester, '/pocket-money-setup');

      final coin = find.byWidgetPredicate(
        (widget) =>
            widget is SvgPicture &&
            widget.bytesLoader is SvgAssetLoader &&
            (widget.bytesLoader as SvgAssetLoader).assetName ==
                NestlingIllustrations.coin,
      );
      expect(coin, findsOneWidget);
      final tile = find.ancestor(
        of: coin,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.constraints?.maxWidth == NestSpacing.s10 &&
              widget.constraints?.maxHeight == NestSpacing.s10,
        ),
      );
      expect(tile, findsOneWidget);
      expect(tester.getSize(tile), const Size(40, 40));
      expect(
        find.ancestor(of: coin, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  // -- real-font geometry (light + dark, Inter/Nunito metrics) -------------

  group('P06 geometry at 390×844 (real fonts)', () {
    setUpAll(_loadBundledFonts);

    testWidgets("the payout card keeps the design's 270 height and gap chain "
        '(light + dark)', (tester) async {
      await setUpTestScope();
      for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
        await pumpAppRoute(tester, '/pocket-money-setup', theme: theme);

        final h1 = tester.getRect(
          find.text('How does pocket money work in your house?'),
        );
        final card = tester.getRect(find.byType(NestCard));
        final label = tester.getRect(find.text('Payout day'));
        final pill1 = tester.getRect(_dayPill(1));
        final pill7 = tester.getRect(_dayPill(7));
        final weekly = tester.getRect(find.text('Weekly base'));
        final maya = tester.getRect(find.text('Maya'));
        final leo = tester.getRect(find.text('Leo'));
        final coin = tester.getRect(find.text('Coin value'));

        // ORCHESTRATOR_NOTES (07:22/07:58) design anchors at 390×844,
        // measured off `P06-pocket-money.png` ÷3: H1 107/68, card 415/270,
        // pills 455/32 flush with the card's 16 px inset, Weekly base 503,
        // Maya/Coo text boxes 534/639.
        expect(h1.top, moreOrLessEquals(107, epsilon: 1));
        expect(h1.height, moreOrLessEquals(68, epsilon: 1));
        expect(card.top, moreOrLessEquals(415, epsilon: 1));
        expect(card.height, moreOrLessEquals(270, epsilon: 1));
        expect(pill1.top, moreOrLessEquals(455, epsilon: 1));
        expect(pill1.height, moreOrLessEquals(32, epsilon: 0.5));
        expect(
          pill7.right,
          moreOrLessEquals(card.right - NestSpacing.s4, epsilon: 0.5),
        );
        expect(weekly.top, moreOrLessEquals(503, epsilon: 1));
        expect(maya.top, moreOrLessEquals(534, epsilon: 1));
        expect(leo.top, moreOrLessEquals(578, epsilon: 1));
        expect(coin.top, moreOrLessEquals(639, epsilon: 1));

        // HTML gap chain inside the card: label→row 6, row→divider→label
        // 8+1+8, label→row 2, rows 44, divider 8+1+8, bottom padding 12.
        expect(pill1.top - label.bottom, moreOrLessEquals(6, epsilon: 0.5));
        expect(weekly.top - pill1.bottom, moreOrLessEquals(17, epsilon: 0.5));
        expect(maya.top - weekly.bottom, moreOrLessEquals(13, epsilon: 0.5));
        expect(leo.top - maya.bottom, moreOrLessEquals(22, epsilon: 0.5));
        expect(coin.top - leo.bottom, moreOrLessEquals(39, epsilon: 0.5));
        expect(card.bottom - coin.bottom, moreOrLessEquals(23, epsilon: 0.5));

        // ORCHESTRATOR_NOTES (07:58) #3: the same targets measured from the
        // title's bottom (design H1 bottom 175 → 296/329/359/403/464).
        expect(pill1.center.dy - h1.bottom, moreOrLessEquals(296, epsilon: 1));
        expect(weekly.top - h1.bottom, moreOrLessEquals(329, epsilon: 1));
        expect(maya.top - h1.bottom, moreOrLessEquals(359, epsilon: 1));
        expect(leo.top - h1.bottom, moreOrLessEquals(403, epsilon: 1));
        expect(coin.top - h1.bottom, moreOrLessEquals(464, epsilon: 1));
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      }
    });

    testWidgets(
      "P06-BUG-11 (fixed): the H1 wraps to the design's two lines and "
      'balanced break',
      (tester) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/pocket-money-setup');

        final h1Finder = find.text('How does pocket money work in your house?');
        final h1 = tester.renderObject<RenderParagraph>(
          find.descendant(of: h1Finder, matching: find.byType(RichText)),
        );
        // Design (`P06-pocket-money.png` ÷3): H1 107–175 = two 34 px lines.
        // FIXED via main's shared/balanced_text_ellipsis: no ellipsis when
        // maxLines is null, so the paragraph wraps instead of collapsing.
        expect(h1.size.height, moreOrLessEquals(68, epsilon: 1));
        expect(h1.didExceedMaxLines, isFalse);

        // CSS text-wrap: balance → line 1 ends after "money" (the design's
        // break), never orphaning "work" onto its own second line.
        final data = tester.widget<Text>(h1Finder).data!;
        final line1End = h1
            .getPositionForOffset(Offset(h1.size.width, h1.size.height / 4))
            .offset
            .clamp(0, data.length);
        expect(data.substring(0, line1End).trim(), 'How does pocket money');

        // With the title back at two lines the card returns to the design y.
        final card = tester.getRect(find.byType(NestCard));
        expect(card.top, moreOrLessEquals(415, epsilon: 1));
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      },
    );

    testWidgets("P06-BUG-12 (fixed): the stepper minus is the design's U+2212 "
        '(&minus;)', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/pocket-money-setup');

      final minus = tester.widget<Text>(
        find
            .descendant(
              of: find.bySemanticsLabel(
                RegExp('Less weekly pocket money for Maya'),
              ),
              matching: find.byType(Text),
            )
            .first,
      );
      // The design HTML prints `&minus;` (U+2212); P06WeeklyStepper renders
      // the same glyph next to `+` (the shared NestStepper keeps U+002D).
      expect(minus.data, '\u2212');
      final plus = tester.widget<Text>(
        find
            .descendant(
              of: find.bySemanticsLabel(
                RegExp('More weekly pocket money for Maya'),
              ),
              matching: find.byType(Text),
            )
            .first,
      );
      expect(plus.data, '+');
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets(
      'P06-BUG-13: the "Coin value" label must not ellipsize at 320dp × 1.3',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await setUpTestScope();
        await pumpAppRoute(tester, '/pocket-money-setup');
        tester.view.physicalSize = const Size(320 * 3, 844 * 3);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // The coin row is one line with two flex children; at 320 × 1.3 the
        // label gets half of 196 px (98) while Inter 16 × 1.3 needs ~105, so
        // it must wrap to a second line rather than truncate: `_CoinValueRow`
        // gives the label `maxLines: 2` and lets the *value* — the text
        // `1_plan.md` §5 sanctions for ellipsis — take the shortfall. Above
        // 320 dp the label still prints on one line, as the design draws it.
        final label = tester.renderObject<RenderParagraph>(
          find.descendant(
            of: find.text('Coin value'),
            matching: find.byType(RichText),
          ),
        );
        expect(label.didExceedMaxLines, isFalse);
        expect(tester.getRect(_dayPill(1)).height, NestSpacing.s8);
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      },
    );
  });

  // -- iteration-7 accessibility actions + coin row -------------------------

  group('P06 iteration-7: semantics actions and coin-row alignment', () {
    testWidgets('every feature-owned control exposes SemanticsAction.tap', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/pocket-money-setup');

      final finders = <Finder>[
        for (final key in <String>[
          'p06_option_weekly',
          'p06_option_per_quest',
          'p06_option_both',
        ])
          find.byKey(ValueKey<String>(key)),
        for (var day = 1; day <= 7; day++)
          find.byKey(ValueKey<String>('p06_day_$day')),
        for (final label in <String>[
          'Less weekly pocket money for Maya',
          'More weekly pocket money for Maya',
          'Less weekly pocket money for Leo',
          'More weekly pocket money for Leo',
        ])
          find.bySemanticsLabel(RegExp(label)),
      ];
      for (final finder in finders) {
        final data = tester.getSemantics(finder).getSemanticsData();
        expect(
          data.hasAction(SemanticsAction.tap),
          isTrue,
          reason:
              'a VoiceOver/TalkBack user must be able to activate '
              '${data.label}',
        );
      }
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('performAction(tap) on the feature controls writes the DB', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/pocket-money-setup');
      final repository = GetIt.instance<PocketMoneyRepository>();

      void dispatch(Finder finder) {
        final node = tester.getSemantics(finder);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        node.owner!.performAction(node.id, SemanticsAction.tap);
      }

      Future<void> settle() async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
      }

      // Money style: "Earn per quest" → the card announces selected.
      dispatch(find.byKey(const ValueKey('p06_option_per_quest')));
      await settle();
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('p06_option_per_quest')))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );

      // Payout day: Sun → the cell announces selected.
      dispatch(find.byKey(const ValueKey('p06_day_7')));
      await settle();
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('p06_day_7')))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );

      // Weekly base: Maya + → the value renders £3.50.
      dispatch(
        find.bySemanticsLabel(RegExp('More weekly pocket money for Maya')),
      );
      await settle();
      expect(find.text('£3.50'), findsOneWidget);

      // Database truth, read outside the fake test clock (awaiting a fresh
      // Drift stream inside the widget clock hangs — learned this iteration).
      await tester.runAsync(() async {
        final setup = await repository.watchSetup().first;
        expect(setup.mode, 'per_quest');
        expect(setup.payoutDay, 7);
        expect(setup.childById('maya')!.weeklyBasePence, 350);
      });
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the coin value is right-aligned to the card content edge', (
      tester,
    ) async {
      await setUpTestScope();
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final scenario in <({int width, double scale})>[
        (width: 390, scale: 1),
        (width: 320, scale: 1),
        (width: 320, scale: 1.3),
        (width: 430, scale: 1),
      ]) {
        tester.platformDispatcher.textScaleFactorTestValue = scenario.scale;
        await pumpAppRoute(tester, '/pocket-money-setup');
        tester.view.physicalSize = Size(scenario.width * 3, 844 * 3);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final card = tester.getRect(find.byType(NestCard));
        final value = tester.getRect(find.text('10 coins = 10p'));
        expect(
          value.right,
          moreOrLessEquals(card.right - NestSpacing.s4, epsilon: 1),
          reason:
              'coin value right edge at ${scenario.width}dp '
              '× ${scenario.scale}',
        );
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      }
    });
  });

  // -- attacks that hold --------------------------------------------------

  group('P06 attacks that hold', () {
    testWidgets(
      'two quick widget taps land under test timing (bloc race stays, '
      'P06-BUG-01)',
      (tester) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/pocket-money-setup');
        expect(find.text('£3.00'), findsOneWidget);

        final plus = find.bySemanticsLabel(
          RegExp('More weekly pocket money for Maya'),
        );
        await tester.tap(plus);
        await tester.tap(plus);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('£4.00'), findsOneWidget);
        await disposeApp(tester);
      },
    );

    testWidgets('kid-mode deep link is stopped by the parental gate', (
      tester,
    ) async {
      await setUpTestScope();
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/pocket-money-setup');

      expect(currentPath(tester), '/parental-gate');
      expect(
        find.text('How does pocket money work in your house?'),
        findsNothing,
      );

      await disposeApp(tester);
    });

    test(
      'mode/day/base survive a database restart (file-backed Drift)',
      () async {
        final dir = Directory.systemTemp.createTempSync('p06_restart');
        final file = File('${dir.path}/nestling.db');
        try {
          var db = AppDatabase(NativeDatabase(file));
          await Seed.demo(db);
          final first = PocketMoneyRepositoryImpl(db: db);
          await first.setMode('weekly');
          await first.setPayoutDay(2);
          await first.setWeeklyBasePence('maya', 450);
          await db.close();

          db = AppDatabase(NativeDatabase(file));
          final second = PocketMoneyRepositoryImpl(db: db);
          final setup = await second.watchSetup().first;
          expect(setup.mode, 'weekly');
          expect(setup.payoutDay, 2);
          expect(setup.childById('maya')!.weeklyBasePence, 450);
          expect(setup.children.map((child) => child.id).toList(), <String>[
            'maya',
            'leo',
          ]);
          await db.close();
        } finally {
          dir.deleteSync(recursive: true);
        }
      },
    );

    testWidgets(
      'six children incl. a long UK name survive 320dp × 1.3 with no overflow',
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

        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpAppRoute(tester, '/pocket-money-setup');
        tester.view.physicalSize = const Size(320 * 3, 844 * 3);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Maya'), findsOneWidget);
        expect(find.text('Maximilian-Alexander'), findsOneWidget);

        // Canonical insertion order end-to-end (`watchChildren` now orders by
        // createdAt, rowid): Maya → Leo → the four added after the seed.
        final order = <String>[
          'Maya',
          'Leo',
          'Maximilian-Alexander',
          'Noah',
          'Ava',
          'Ethan',
        ];
        for (var i = 1; i < order.length; i++) {
          expect(
            tester.getTopLeft(find.text(order[i - 1])).dy,
            lessThan(tester.getTopLeft(find.text(order[i])).dy),
            reason: '${order[i - 1]} must sit above ${order[i]}',
          );
        }
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      },
    );

    testWidgets('no children at 320dp × 1.3 shows the add-children caption', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();

      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpAppRoute(tester, '/pocket-money-setup');
      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Add children to set weekly amounts.'), findsOneWidget);
      expect(find.text('£0.00'), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('£0.00 and £20.00 render exactly from the database', (
      tester,
    ) async {
      await setUpTestScope();
      final repository = GetIt.instance<PocketMoneyRepository>();
      await repository.setWeeklyBasePence('maya', 0);
      await repository.setWeeklyBasePence('leo', 2000);
      await pumpAppRoute(tester, '/pocket-money-setup');

      expect(find.text('£0.00'), findsOneWidget);
      expect(find.text('£20.00'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    test(
      'async gap: a late write failure during dispose stays contained',
      () async {
        final pending = Completer<void>();
        final repository = _RecordingPocketMoneyRepository(
          setModeFuture: pending.future,
        );
        final bloc = PocketMoneyBloc(repository: repository)
          ..add(const PocketMoneyLoadRequested());
        await bloc.stream.firstWhere((state) => state.setup != null);

        bloc.add(const PocketMoneyModeChanged('weekly'));
        // Let the handler reach the pending write.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        final closing = bloc.close();
        // The write fails only after disposal started; the bloc emitter is
        // already cancelled, so `emit` is a no-op instead of a StateError.
        pending.completeError(Exception('late failure'));
        await closing;

        expect(bloc.isClosed, isTrue);
      },
    );

    test('light and dark text pairs used by P06 pass 4.5:1', () {
      for (final theme in <ThemeData>[NestTheme.light(), NestTheme.dark()]) {
        final tokens = theme.extension<NestTokens>()!;
        expect(
          _contrast(tokens.ink, tokens.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(tokens.ink2, tokens.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(tokens.ink2, tokens.leafTint),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          _contrast(tokens.leafInk, tokens.leafTint),
          greaterThanOrEqualTo(4.5),
        );
        expect(_contrast(tokens.ink2, tokens.paper), greaterThanOrEqualTo(4.5));
      }
    });
  });
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
