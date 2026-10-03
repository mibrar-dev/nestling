// P06 Pocket money setup — Stage 6 adversarial bug tests (iteration 2).
//
// Every test that PROVES an OPEN bug is marked `skip: true` (the test name
// carries the `P06-BUG-nn` id) so the default suite stays green; delete the
// skip (or run the copy without skips) to watch the test fail. Each skipped
// test is the executable repro for the matching entry in
// `docs/screens/P06/6_bugs.md`.
//
// FIXED in iteration 3: P06-BUG-01/02/06/07 (logic chunk) and
// P06-BUG-04/05 (UI chunk) are un-skipped below and must stay green.
// Still skipped: P06-BUG-03 (day-pill paint size, needs the shared
// `NestChip` compact mode — see `docs/screens/P06/SHARED_REQUEST.md`).
//
// The group at the bottom ("attacks that hold") is NOT skipped: it documents
// the adversarial probes that passed (kid-mode guard, restart persistence,
// data extremes), so regressions are caught here too.

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pocket_money/data/pocket_money_repository_impl.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_bloc.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_event.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_state.dart';
import 'package:nestling/features/pocket_money/presentation/views/pocket_money_setup_view.dart';

import '../../test_scope.dart';

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

/// Fake repository with caller-controlled streams and recorded writes. Owns
/// no database, timers or tickers; `watch…()` factories hand out the streams
/// the test provides.
class _RecordingPocketMoneyRepository implements PocketMoneyRepository {
  _RecordingPocketMoneyRepository({
    Stream<PocketMoneySetup>? setupStream,
    Stream<List<PocketMoneyEntry>>? itemsStream,
    this.setModeError,
    this.setModeFuture,
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
  Future<void> setPayoutDay(int day) async => dayWrites.add(day);

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

void main() {
  // -- P06-BUG-01 ---------------------------------------------------------

  test(
    'P06-BUG-01: two quick "+" taps must each add 50p (real repo)',
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
      // FIXED (iteration 3, logic chunk): un-skipped, must stay green.
      expect(setup.childById('maya')!.weeklyBasePence, 400);
      await bloc.close();
    },
  );

  // -- P06-BUG-02 ---------------------------------------------------------

  test(
    'P06-BUG-02: a fast Sun→Sat correction must end on Saturday (real repo)',
    () async {
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
      // FIXED (iteration 3, logic chunk): un-skipped, must stay green.
      expect(setup.payoutDay, 6);
      await bloc.close();
    },
  );

  // -- P06-BUG-03 ---------------------------------------------------------

  testWidgets(
    'P06-BUG-03: a day pill must paint at the design height (32, ±2)',
    (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/pocket-money-setup');

      // The painted pill is the FittedBox output; the design `.chip.day` is
      // 32 high with 13px labels. The app scales the whole NestChip down to
      // fit 7 cells, so the pill paints far below 30.
      final painted = tester.getSize(
        find
            .ancestor(
              of: find.byType(NestChip).first,
              matching: find.byType(FittedBox),
            )
            .first,
      );
      expect(painted.height, greaterThanOrEqualTo(30));

      await disposeApp(tester);
    },
    skip: true,
  );

  // -- P06-BUG-04 ---------------------------------------------------------

  testWidgets('P06-BUG-04: every day cell must be a 44×44 parent tap target', (
    tester,
  ) async {
    await setUpTestScope();
    await pumpAppRoute(tester, '/pocket-money-setup');

    final cell = tester.getSize(find.byKey(const ValueKey('p06_day_1')));
    expect(cell.width, greaterThanOrEqualTo(NestDevice.tapParent));
    expect(cell.height, greaterThanOrEqualTo(NestDevice.tapParent));

    await disposeApp(tester);
  });
  // FIXED (iteration 3, UI chunk): cell width is clamped to ≥44 and the
  // row breaks out of the card inset (see _DayRow); must stay green.

  // -- P06-BUG-05 ---------------------------------------------------------

  testWidgets('P06-BUG-05: a failed write must not blank the setup controls', (
    tester,
  ) async {
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

    // The write failed; the parent must still see the options (with an
    // inline error), not lose the whole form to the load-failure body.
    expect(find.text('Weekly amount'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  // FIXED (iteration 3, UI chunk): the failure branch keeps the loaded
  // form and shows an inline error caption when setup is still valid.

  // -- P06-BUG-06 ---------------------------------------------------------

  test('P06-BUG-06: errorMessage must clear when the setup recovers', () async {
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
  });

  // -- P06-BUG-07 ---------------------------------------------------------

  test(
    'P06-BUG-07: a stepper event for an unknown child must not write',
    () async {
      final repository = _RecordingPocketMoneyRepository();
      final bloc = PocketMoneyBloc(repository: repository)
        ..add(const PocketMoneyLoadRequested());
      await bloc.stream.firstWhere((state) => state.setup != null);

      bloc.add(const PocketMoneyWeeklyBaseStepped('ghost', 50));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // FIXED (iteration 3, logic chunk): un-skipped, must stay green.
      expect(repository.baseWrites, isEmpty);
      await bloc.close();
    },
  );

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
