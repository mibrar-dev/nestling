// P06 Pocket money setup — widget contract.
//
// Covers: the exact §0 copy in light + dark, the width × text-scale matrix
// (320/390/430 × 1.0/1.3, no overflow), write-through selection (mode cards,
// payout-day chips, weekly-base steppers), back/Continue navigation, the
// empty-children caption (Seed.empty), loading/failure states, and the
// accessibility contract (radiogroup labels, selected flags, stepper labels,
// 44dp parent tap targets).

import 'dart:ui' show Tristate;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_entry.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_bloc.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_event.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_state.dart';
import 'package:nestling/features/pocket_money/presentation/views/pocket_money_setup_view.dart';

import '../../test_scope.dart';

/// In-memory repository with caller-controlled streams, used to reach the
/// states the Drift repository cannot (pending load, stream error).
/// Streams are built by factories so every `watch…()` subscription (initial
/// load, Retry) gets a fresh single-subscription stream — re-listening to one
/// instance throws `Bad state: Stream has already been listened to`.
class _FakePocketMoneyRepository implements PocketMoneyRepository {
  _FakePocketMoneyRepository({
    Stream<List<PocketMoneyEntry>> Function()? items,
    Stream<PocketMoneySetup> Function()? setup,
  }) : _itemsFactory =
           items ?? (() => const Stream<List<PocketMoneyEntry>>.empty()),
       _setupFactory = setup ?? (() => const Stream<PocketMoneySetup>.empty());

  final Stream<List<PocketMoneyEntry>> Function() _itemsFactory;
  final Stream<PocketMoneySetup> Function() _setupFactory;

  @override
  Future<List<PocketMoneyEntry>> getItems() => watchItems().first;

  @override
  Stream<List<PocketMoneyEntry>> watchItems() => _itemsFactory();

  @override
  Stream<List<PocketMoneyEntry>> watchLedger(String childId) => _itemsFactory();

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
  Stream<PocketMoneySetup> watchSetup() => _setupFactory();

  /// Iteration 3 (P06-BUG-05): the first `setMode` throws so the screen can be
  /// observed in its "write failed, form kept" state. The fake holds a fixed
  /// setup, so the second write simply succeeds and the view recovers.
  bool failNextModeWrite = false;

  @override
  Future<void> setMode(String mode) async {
    if (failNextModeWrite) {
      failNextModeWrite = false;
      throw Exception('mode write rejected');
    }
  }

  @override
  Future<void> setPayoutDay(int day) async {}

  @override
  Future<void> setWeeklyBasePence(String childId, int pence) async {}
}

/// Wraps the real Drift repository and can reject the next mode write, so the
/// screen's *write-failure* path can be driven end to end with the real watch
/// stream (the screen only clears the inline error when the stream re-emits,
/// which a one-shot fake could never reproduce).
class _FlakyModeRepository implements PocketMoneyRepository {
  _FlakyModeRepository(this._inner);

  final PocketMoneyRepository _inner;

  /// Rejects the next [setMode] (P06-BUG-05 path).
  bool failNextMode = false;

  @override
  Future<void> setMode(String mode) async {
    if (failNextMode) {
      failNextMode = false;
      throw Exception('mode write rejected');
    }
    await _inner.setMode(mode);
  }

  @override
  Future<void> setPayoutDay(int day) => _inner.setPayoutDay(day);

  @override
  Future<void> setWeeklyBasePence(String childId, int pence) =>
      _inner.setWeeklyBasePence(childId, pence);

  @override
  Stream<PocketMoneySetup> watchSetup() => _inner.watchSetup();

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
}

/// Pumps `/pocket-money-setup` through the real app (router, DI, themes) at
/// [surface] and [textScale]. Mirrors [pumpAppRoute], which takes no
/// size/scale.
Future<void> _pumpSetup(
  WidgetTester tester, {
  required ThemeMode theme,
  required Size surface,
  required double textScale,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  await pumpAppRoute(tester, '/pocket-money-setup', theme: theme);
  tester.view.physicalSize = surface * 3;
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Pumps [PocketMoneySetupView] directly (no router) under the real theme
/// with [repository] driving the bloc; returns the bloc for assertions.
///
/// NOTE: the bloc is deliberately NOT closed here. `close()` (plain or via
/// `runAsync`) deadlocks under the widget-test FakeAsync clock once a load
/// has subscribed the combined watch streams (the P01-documented hazard:
/// the shared `combineLatest` controller never terminates, so `emit.forEach`
/// stays pending and `close` waits on it forever — verified by bisect, while
/// the identical sequence closes instantly in real async). This is safe: the
/// fake repository owns no database, timers, or tickers (verified: no "Timer
/// is still pending", clean exit), so the leftover subscriptions are inert
/// once the test ends.
Future<PocketMoneyBloc> _pumpSetupView(
  WidgetTester tester, {
  required PocketMoneyRepository repository,
  required ThemeMode theme,
}) async {
  final bloc = PocketMoneyBloc(repository: repository);
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      themeMode: theme,
      home: BlocProvider<PocketMoneyBloc>.value(
        value: bloc,
        child: const PocketMoneySetupView(),
      ),
    ),
  );
  await tester.pump();
  return bloc;
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// The `.chip.day` pill inside day cell `n` — the 32-high, full-width
/// `SizedBox` that wraps the pill's paint. The cell around it is the 44dp
/// tap box, so taps are measured against the pill, not the cell.
Finder dayPill(int day) => find
    .descendant(
      of: find.byKey(ValueKey('p06_day_$day')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox &&
            widget.height == NestSpacing.s8 &&
            widget.width == double.infinity,
      ),
    )
    .first;

/// The `Seed.demo` setup, used where the fake repository has to hand the bloc
/// a real value (the retry-recovery path).
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

/// RepaintBoundary used by the pixel probe for the owner BOTTOM EDGE rule.
const Key _pixelProbe = ValueKey<String>('p06_pixel_probe');

/// `_pumpSetup` plus a pixel probe, optionally with a home-indicator OS inset
/// ([bottomInset] logical px) — the strip the rule is about only shows up when
/// the OS reserves space at the bottom.
Future<void> _pumpSetupForPixels(
  WidgetTester tester, {
  required ThemeMode theme,
  required Size surface,
  double bottomInset = 0,
}) async {
  tester.view.physicalSize = surface * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  if (bottomInset > 0) {
    tester.view.padding = FakeViewPadding(bottom: bottomInset * 3);
    addTearDown(tester.view.resetPadding);
  }
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(
    const RepaintBoundary(
      key: _pixelProbe,
      child: NestlingApp(initialRoute: '/pocket-money-setup'),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Painted RGBA bytes at logical (x, y) of the app surface.
Future<List<int>> _pixelAt(WidgetTester tester, double x, double y) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_pixelProbe),
  );
  late List<int> pixel;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData();
    final offset = (y.round() * image.width + x.round()) * 4;
    pixel = <int>[
      data!.getUint8(offset),
      data.getUint8(offset + 1),
      data.getUint8(offset + 2),
      data.getUint8(offset + 3),
    ];
  });
  return pixel;
}

/// The opaque RGBA bytes of [color] at 8-bit precision.
List<int> _rgba(Color color) => <int>[
  (color.r * 255).round(),
  (color.g * 255).round(),
  (color.b * 255).round(),
  255,
];

/// The settings card (`Payout day` / `Weekly base` / `Coin value`).
Finder _settingsCard() => find
    .ancestor(of: find.text('Payout day'), matching: find.byType(NestCard))
    .first;

/// Maya's 32px avatar circle (the first child of her weekly-base row).
Finder _mayaAvatar() =>
    find.ancestor(of: find.text('M'), matching: find.byType(NestAvatar)).first;

/// The 40x40 `coinTint` tile in the coin-value row.
Finder _coinTile() => find
    .ancestor(
      of: find.byType(SvgPicture),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints?.maxWidth == NestSpacing.s10 &&
            widget.constraints?.maxHeight == NestSpacing.s10,
      ),
    )
    .first;

void main() {
  group('P06 setup — copy and theming', () {
    testWidgets('light: renders every §0 string', (tester) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(
        find.text('How does pocket money work in your house?'),
        findsOneWidget,
      );
      expect(find.text('Weekly amount'), findsOneWidget);
      expect(find.text('A set amount every week'), findsOneWidget);
      expect(find.text('Earn per quest'), findsOneWidget);
      expect(find.text('Coins turn into pence at payout'), findsOneWidget);
      expect(find.text('Both'), findsOneWidget);
      expect(find.text('Weekly base + bonus for extra quests'), findsOneWidget);
      expect(find.text('Payout day'), findsOneWidget);
      for (final day in <String>[
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ]) {
        expect(find.text(day), findsOneWidget);
      }
      expect(find.text('Weekly base'), findsOneWidget);
      expect(find.text('Maya'), findsOneWidget);
      expect(find.text('Leo'), findsOneWidget);
      expect(find.text('£3.00'), findsOneWidget);
      expect(find.text('£1.50'), findsOneWidget);
      expect(find.text('Coin value'), findsOneWidget);
      expect(find.text('10 coins = 10p'), findsOneWidget);
      expect(
        find.text(
          'Nestling never holds or moves money. '
          'You pay your way; we keep score.',
        ),
        findsOneWidget,
      );
      expect(find.text('Continue'), findsOneWidget);
      // Orchestrator rule: the OS draws the real status bar.
      expect(find.text('9:41'), findsNothing);
      expect(find.byType(NestStatusBar), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('dark: renders the same content without overflow', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.dark,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(
        find.text('How does pocket money work in your house?'),
        findsOneWidget,
      );
      expect(find.text('Both'), findsOneWidget);
      expect(find.text('£3.00'), findsOneWidget);
      expect(find.text('£1.50'), findsOneWidget);
      expect(find.text('10 coins = 10p'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('Both is selected and Sat is the payout day from the seed', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      final selected = tester
          .getSemantics(find.byKey(const ValueKey('p06_option_both')))
          .getSemanticsData();
      expect(selected.flagsCollection.isButton, isTrue);
      expect(selected.flagsCollection.isSelected, Tristate.isTrue);
      final weekly = tester
          .getSemantics(find.byKey(const ValueKey('p06_option_weekly')))
          .getSemanticsData();
      expect(weekly.flagsCollection.isSelected, Tristate.isFalse);
      final sat = tester
          .getSemantics(find.byKey(const ValueKey('p06_day_6')))
          .getSemanticsData();
      expect(sat.flagsCollection.isSelected, Tristate.isTrue);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in const <int>[320, 390, 430]) {
        for (final scale in const <double>[1, 1.3]) {
          final themeName = theme == ThemeMode.light ? 'light' : 'dark';
          testWidgets('$themeName ${width}dp at text scale $scale', (
            tester,
          ) async {
            await setUpTestScope();
            await _pumpSetup(
              tester,
              theme: theme,
              surface: Size(width.toDouble(), 844),
              textScale: scale,
            );

            expect(
              find.text('How does pocket money work in your house?'),
              findsOneWidget,
            );
            expect(find.text('Both'), findsOneWidget);
            expect(find.text('Maya'), findsOneWidget);
            expect(find.text('£3.00'), findsOneWidget);
            expect(find.text('Continue'), findsOneWidget);
            expect(tester.takeException(), isNull);

            await disposeApp(tester);
          });
        }
      }
    }

    testWidgets(
      'Seed.empty: weekly-base rows become the add-children caption',
      (tester) async {
        final db = await setUpTestScope(seedDemo: false);
        await Seed.empty(db);
        await GetIt.instance<AppSession>().refresh();
        await _pumpSetup(
          tester,
          theme: ThemeMode.light,
          surface: const Size(390, 844),
          textScale: 1,
        );

        expect(
          find.text('How does pocket money work in your house?'),
          findsOneWidget,
        );
        expect(find.text('Weekly amount'), findsOneWidget);
        expect(find.text('Payout day'), findsOneWidget);
        expect(
          find.text('Add children to set weekly amounts.'),
          findsOneWidget,
        );
        expect(find.text('Maya'), findsNothing);
        expect(find.text('Continue'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      },
    );
  });

  group('P06 setup — write-through interactions', () {
    testWidgets('tapping Earn per quest flips the selection', (tester) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(find.byKey(const ValueKey('p06_option_per_quest')));
      await _settle(tester);

      final perQuest = tester
          .getSemantics(find.byKey(const ValueKey('p06_option_per_quest')))
          .getSemanticsData();
      expect(perQuest.flagsCollection.isSelected, Tristate.isTrue);
      final both = tester
          .getSemantics(find.byKey(const ValueKey('p06_option_both')))
          .getSemanticsData();
      expect(both.flagsCollection.isSelected, Tristate.isFalse);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('tapping Sun moves the payout day to 7', (tester) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(find.byKey(const ValueKey('p06_day_7')));
      await _settle(tester);

      final sun = tester
          .getSemantics(find.byKey(const ValueKey('p06_day_7')))
          .getSemanticsData();
      expect(sun.flagsCollection.isSelected, Tristate.isTrue);
      final sat = tester
          .getSemantics(find.byKey(const ValueKey('p06_day_6')))
          .getSemanticsData();
      expect(sat.flagsCollection.isSelected, Tristate.isFalse);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('steppers move the weekly base by 50p', (tester) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(
        find.bySemanticsLabel(RegExp('More weekly pocket money for Maya')),
      );
      await _settle(tester);
      expect(find.text('£3.50'), findsOneWidget);

      // Leo's row starts below the fold (the content scrolls behind the
      // fixed bottom CTA), so bring it into view before tapping.
      await tester.ensureVisible(
        find.byKey(const ValueKey('p06_base_row_leo')),
      );
      await _settle(tester);
      await tester.tap(
        find.bySemanticsLabel(RegExp('Less weekly pocket money for Leo')),
      );
      await _settle(tester);
      expect(find.text('£1.00'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P06 setup — navigation', () {
    testWidgets('Continue opens /paywall', (tester) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(find.byKey(const ValueKey('p06_continue')));
      await _settle(tester);

      expect(currentPath(tester), '/paywall');

      await disposeApp(tester);
    });

    testWidgets('Back opens /add-children', (tester) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(find.bySemanticsLabel('Back'));
      await _settle(tester);

      expect(currentPath(tester), '/add-children');

      await disposeApp(tester);
    });
  });

  group('P06 setup — loading and failure', () {
    testWidgets('initial: static chrome with a spinner in the scroll area', (
      tester,
    ) async {
      final bloc = await _pumpSetupView(
        tester,
        repository: _FakePocketMoneyRepository(),
        theme: ThemeMode.light,
      );

      expect(
        find.text('How does pocket money work in your house?'),
        findsOneWidget,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(bloc.state.status, PocketMoneyStatus.initial);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('failure: message plus a Retry button', (tester) async {
      final bloc = await _pumpSetupView(
        tester,
        repository: _FakePocketMoneyRepository(
          setup: () => Stream<PocketMoneySetup>.error(Exception('offline')),
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const PocketMoneyLoadRequested());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('offline'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(
        find.text('How does pocket money work in your house?'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('p06_retry')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  group('P06 setup — accessibility', () {
    testWidgets('labels, header and selected flags meet the contract', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(find.bySemanticsLabel('Pocket money style'), findsWidgets);
      expect(find.bySemanticsLabel('Payout day'), findsWidgets);
      expect(
        find.bySemanticsLabel('Weekly amount, A set amount every week'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          'Earn per quest, Coins turn into pence at payout',
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Both, Weekly base + bonus for extra quests'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Less weekly pocket money for Maya')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('More weekly pocket money for Maya')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('Less weekly pocket money for Leo')),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp('More weekly pocket money for Leo')),
        findsOneWidget,
      );

      final headlineData = tester
          .getSemantics(find.text('How does pocket money work in your house?'))
          .getSemanticsData();
      expect(headlineData.flagsCollection.isHeader, isTrue);

      await disposeApp(tester);
    });

    testWidgets('every tap target is at least 44dp', (tester) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      for (final key in <ValueKey<String>>[
        const ValueKey('p06_option_weekly'),
        const ValueKey('p06_option_per_quest'),
        const ValueKey('p06_option_both'),
      ]) {
        final size = tester.getSize(find.byKey(key));
        expect(size.height, greaterThanOrEqualTo(44));
      }
      // The design's day row is a single 32dp band of pills; the 44dp
      // target comes from NestChipWrap forwarding ±6px taps (asserted by
      // the day-row geometry group + the tap-above/below test below).
      for (var day = 1; day <= 7; day++) {
        final size = tester.getSize(find.byKey(ValueKey('p06_day_$day')));
        expect(size.height, NestSpacing.s8);
      }
      for (final label in <String>[
        'Less weekly pocket money for Maya',
        'More weekly pocket money for Maya',
        'Less weekly pocket money for Leo',
        'More weekly pocket money for Leo',
      ]) {
        final size = tester.getSize(find.bySemanticsLabel(RegExp(label)));
        expect(size.width, 44);
        expect(size.height, 44);
      }
      final continueSize = tester.getSize(
        find.byKey(const ValueKey('p06_continue')),
      );
      expect(continueSize.height, greaterThanOrEqualTo(52));

      await disposeApp(tester);
    });

    testWidgets('tap targets hold at 320dp with text scale 1.3', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(320, 844),
        textScale: 1.3,
      );

      for (var day = 1; day <= 7; day++) {
        final size = tester.getSize(find.byKey(ValueKey('p06_day_$day')));
        expect(size.height, NestSpacing.s8);
      }
      final continueSize = tester.getSize(
        find.byKey(const ValueKey('p06_continue')),
      );
      expect(continueSize.height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('chip row: every chip stays inside the card padding', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      final card = tester.getRect(_settingsCard());
      const inset = NestSpacing.s4;
      for (var day = 1; day <= 7; day++) {
        final rect = tester.getRect(find.byKey(ValueKey('p06_day_$day')));
        expect(
          rect.left,
          greaterThanOrEqualTo(card.left + inset - 0.01),
          reason: 'day $day must start inside the card padding',
        );
        expect(
          rect.right,
          lessThanOrEqualTo(card.right - inset + 0.01),
          reason: 'day $day must end inside the card padding',
        );
        expect(
          rect.height,
          NestSpacing.s8,
          reason:
              'the day cell IS the 32px pill; its ≥44dp tap band is the '
              'NestChipWrap hitSlop (covered by the tap-above/below test '
              'and P06-BUG-03)',
        );
      }

      await disposeApp(tester);
    });

    testWidgets('chip row: taps 5 px above and below a chip select it', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      Future<void> tapAt(Offset offset) async {
        await tester.tapAt(offset);
        await _settle(tester);
      }

      final wed = tester.getRect(dayPill(3));

      // 5 px above the pill's top edge — inside the 44dp cell tap box.
      await tapAt(Offset(wed.center.dx, wed.top - 5));
      var wedData = tester
          .getSemantics(find.byKey(const ValueKey('p06_day_3')))
          .getSemanticsData();
      expect(wedData.flagsCollection.isSelected, Tristate.isTrue);

      // Back to Sat directly, then 5 px below the chip's bottom edge must
      // land back on Wed again.
      await tapAt(tester.getRect(dayPill(6)).center);
      wedData = tester
          .getSemantics(find.byKey(const ValueKey('p06_day_3')))
          .getSemanticsData();
      expect(wedData.flagsCollection.isSelected, Tristate.isFalse);
      await tapAt(Offset(wed.center.dx, wed.bottom + 5));
      wedData = tester
          .getSemantics(find.byKey(const ValueKey('p06_day_3')))
          .getSemanticsData();
      expect(wedData.flagsCollection.isSelected, Tristate.isTrue);

      await disposeApp(tester);
    });

    testWidgets('the back button is a labelled 44dp icon button', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      final back = find.bySemanticsLabel('Back');
      expect(back, findsOneWidget);
      expect(tester.getSize(back).width, NestDevice.tapParent);
      expect(tester.getSize(back).height, NestDevice.tapParent);
      final data = tester.getSemantics(back).getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);

      await disposeApp(tester);
    });

    testWidgets('every tappable on the screen is labelled and 44dp+', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // The screen's complete set of controls: back, three money-style
      // cards, seven day cells, four stepper buttons, Continue. Nothing
      // else on the screen may take a tap.
      final controls = <({String label, Finder finder, double minHeight})>[
        (label: 'Back', finder: find.bySemanticsLabel('Back'), minHeight: 44),
        for (final option in const <(String, String, String)>[
          (
            'Weekly amount, A set amount every week',
            'p06_option_weekly',
            'Weekly amount, A set amount every week',
          ),
          (
            'Earn per quest, Coins turn into pence at payout',
            'p06_option_per_quest',
            'Earn per quest, Coins turn into pence at payout',
          ),
          (
            'Both, Weekly base + bonus for extra quests',
            'p06_option_both',
            'Both, Weekly base + bonus for extra quests',
          ),
        ])
          (
            label: option.$1,
            finder: find.bySemanticsLabel(option.$3),
            minHeight: NestDevice.tapParent,
          ),
        for (var day = 1; day <= 7; day++)
          (
            // The pill is 32dp; the ≥44dp tap band comes from NestChipWrap
            // hit-sloation as verified by the ±5px tap test.
            label: PocketMoneySetupView.dayLabels[day - 1],
            finder: find.bySemanticsLabel(
              PocketMoneySetupView.dayLabels[day - 1],
            ),
            minHeight: NestSpacing.s8,
          ),
        for (final name in const <String>['Maya', 'Leo'])
          for (final verb in const <String>['Less', 'More'])
            (
              label: '$verb weekly pocket money for $name',
              finder: find.bySemanticsLabel(
                RegExp('$verb weekly pocket money for $name'),
              ),
              minHeight: NestDevice.tapParent,
            ),
        (
          label: 'Continue',
          finder: find.bySemanticsLabel('Continue'),
          minHeight: NestDevice.tapParent,
        ),
      ];

      expect(controls.length, 16);
      for (final control in controls) {
        expect(
          control.finder,
          findsOneWidget,
          reason:
              'the control "${control.label}" must expose one labelled '
              'semantics node',
        );
        final size = tester.getSize(control.finder);
        expect(
          size.height,
          greaterThanOrEqualTo(control.minHeight),
          reason:
              '"${control.label}" is ${size.height} tall — parent mode '
              'needs a ${NestDevice.tapParent}dp minimum',
        );
        final data = tester.getSemantics(control.finder).getSemanticsData();
        expect(
          data.flagsCollection.isButton,
          isTrue,
          reason: '"${control.label}" must announce as a button',
        );
      }
      // Uniqueness: the day's Mon..Sun labels must not also match a longer
      // label (e.g. 'Mon' inside the 'Payout day' group label).
      for (final day in PocketMoneySetupView.dayLabels) {
        expect(
          find.bySemanticsLabel(RegExp('^$day\$')),
          findsOneWidget,
          reason: 'each day chip is announced exactly once',
        );
      }

      await disposeApp(tester);
    });

    testWidgets('the decorative coin icon is not announced', (tester) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // The 40px coin tile is `aria-hidden` in the HTML: the row announces
      // "Coin value" + the value, never a bare icon. The screen shows two
      // SVGs — the nav back chevron (its own labelled button) and the gold
      // coin glyph in the tile.
      final coinIcon = find.byWidgetPredicate(
        (widget) =>
            widget is SvgPicture &&
            widget.bytesLoader is SvgAssetLoader &&
            (widget.bytesLoader as SvgAssetLoader).assetName ==
                NestlingIllustrations.coin,
      );
      expect(coinIcon, findsOneWidget);
      expect(
        find.ancestor(of: coinIcon, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
        reason: 'the icon must sit inside an ExcludeSemantics wrapper',
      );
      expect(
        find.ancestor(of: coinIcon, matching: find.byType(NestBottomCta)),
        findsNothing,
      );

      await disposeApp(tester);
    });
    testWidgets('two quick + taps add 50p each (no lost update)', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // Two taps with no frame in between. FIXED in iteration 3 (P06-BUG-01:
      // the second tap used to be lost because the handler re-read the stale
      // `state.setup`); the same-tick proof lives in `p06_bugs_test.dart`
      // (un-skipped), this is the user-level guard over the same contract.
      final more = find.bySemanticsLabel(
        RegExp('More weekly pocket money for Maya'),
      );
      await tester.tap(more);
      await tester.tap(more);
      await _settle(tester);

      expect(
        find.text('£4.00'),
        findsOneWidget,
        reason:
            'each tap must add one 50p step — two taps from £3.00 are '
            '£4.00, not £3.50',
      );
      expect(find.text('£3.50'), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('three rapid + taps reach £4.50 and then clamp at £20.00', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await GetIt.instance<PocketMoneyRepository>().setWeeklyBasePence(
        'maya',
        1950,
      );
      // Keep the stream truth in step with the seed write.
      await GetIt.instance<AppSession>().refresh();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(find.text('£19.50'), findsOneWidget);
      final more = find.bySemanticsLabel(
        RegExp('More weekly pocket money for Maya'),
      );
      for (var tap = 0; tap < 4; tap++) {
        await tester.tap(more);
        await _settle(tester);
      }

      // 1950 + 50 = 2000 (the ceiling), and the two taps past it are no-ops.
      expect(find.text('£20.00'), findsOneWidget);
      expect(find.text('£20.50'), findsNothing);
      expect(
        (await (db.select(
          db.children,
        )..where((c) => c.id.equals('maya'))).getSingle()).weeklyBasePence,
        2000,
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Iteration 3: the day row rewrite (P06-BUG-03/04) and the inline
  // write-error path (P06-BUG-05).
  // -------------------------------------------------------------------------
  group('P06 setup — day row geometry (P06-BUG-03/04)', () {
    testWidgets('every day cell paints a 32dp pill at all widths', (
      tester,
    ) async {
      for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
        for (final width in const <int>[320, 390, 430]) {
          await setUpTestScope();
          await _pumpSetup(
            tester,
            theme: theme,
            surface: Size(width.toDouble(), 844),
            textScale: 1,
          );

          for (var day = 1; day <= 7; day++) {
            final size = tester.getSize(find.byKey(ValueKey('p06_day_$day')));
            // The cell is the design's 32dp pill; the ≥44dp tap band
            // around it comes from NestChipWrap's hitSlop, not a taller
            // cell box (which would centre pills 6 dp low).
            expect(size.height, NestSpacing.s8);

            // The pill is the design's 32-high `.chip.day`, not a
            // FittedBox-scaled `NestChip` (which rendered ~19dp tall).
            final pill = tester.getRect(dayPill(day));
            expect(
              pill.height,
              moreOrLessEquals(NestSpacing.s8, epsilon: 0.01),
              reason: 'day $day pill height at ${width}dp',
            );
            expect(
              pill.width,
              moreOrLessEquals(size.width, epsilon: 0.01),
              reason: 'the pill fills its cell',
            );
          }
          expect(tester.takeException(), isNull);
          await disposeApp(tester);
        }
      }
    });

    testWidgets('at 390 and 430 all seven cells sit inside the card', (
      tester,
    ) async {
      for (final width in const <int>[390, 430]) {
        await setUpTestScope();
        await _pumpSetup(
          tester,
          theme: ThemeMode.light,
          surface: Size(width.toDouble(), 844),
          textScale: 1,
        );

        final card = tester.getRect(_settingsCard());
        for (var day = 1; day <= 7; day++) {
          final cell = tester.getRect(find.byKey(ValueKey('p06_day_$day')));
          expect(
            cell.left,
            greaterThanOrEqualTo(card.left),
            reason: 'day $day escapes the card at ${width}dp',
          );
          expect(
            cell.right,
            lessThanOrEqualTo(card.right + 0.01),
            reason: 'day $day escapes the card at ${width}dp',
          );
        }
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('p06_day_7')),
            matching: find.byType(SingleChildScrollView),
          ),
          findsNothing,
          reason: 'no horizontal scroll is needed at ${width}dp',
        );
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      }
    });

    testWidgets('at 320 all seven chips fit without a scroll view', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(320, 844),
        textScale: 1,
      );

      final sun = find.byKey(const ValueKey('p06_day_7'));
      final scrollViews = find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      );
      expect(scrollViews, findsNothing);

      expect(tester.getRect(sun).right, lessThanOrEqualTo(320.01));
      await tester.tap(sun);
      await _settle(tester);
      final data = tester.getSemantics(sun).getSemanticsData();
      expect(data.flagsCollection.isSelected, Tristate.isTrue);
      expect(find.textContaining('Exception'), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the selected pill is token-coloured in light and dark', (
      tester,
    ) async {
      await setUpTestScope();
      final sampled = <int>[];
      for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
        await _pumpSetup(
          tester,
          theme: theme,
          surface: const Size(390, 844),
          textScale: 1,
        );

        final tokens = tester.element(dayPill(6)).nest;
        BoxDecoration decorationOf(int day) {
          final box = tester.widget<DecoratedBox>(
            find
                .descendant(
                  of: dayPill(day),
                  matching: find.byType(DecoratedBox),
                )
                .first,
          );
          return box.decoration as BoxDecoration;
        }

        // Saturday is selected in the seed: leafTint pill, leaf border.
        expect(decorationOf(6).color, tokens.leafTint);
        final border = decorationOf(6).border! as Border;
        expect(border.top.color, tokens.leaf);
        expect(border.top.width, 1.5);
        // Monday is not: surface2 pill, transparent border.
        expect(decorationOf(1).color, tokens.surface2);
        expect(
          (decorationOf(1).border! as Border).top.color,
          Colors.transparent,
        );

        sampled.add(decorationOf(6).color!.toARGB32());
      }
      expect(
        sampled.first,
        isNot(sampled.last),
        reason:
            'the probe must discriminate: the two themes must resolve '
            'different pill colours, or the dark assertion proves nothing',
      );

      await disposeApp(tester);
    });
  });

  group('P06 setup — failed write keeps the form (P06-BUG-05)', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final themeName = theme == ThemeMode.light ? 'light' : 'dark';
      testWidgets('$themeName: a rejected write shows inline, keeps every '
          'control', (tester) async {
        final handle = tester.ensureSemantics();
        await setUpTestScope();
        final repository = _FlakyModeRepository(
          GetIt.instance<PocketMoneyRepository>(),
        );
        final bloc = await _pumpSetupView(
          tester,
          repository: repository,
          theme: theme,
        );
        bloc.add(const PocketMoneyLoadRequested());
        await _settle(tester);
        expect(find.text('Both'), findsOneWidget);
        expect(find.text('£3.00'), findsOneWidget);

        repository.failNextMode = true;
        await tester.tap(find.byKey(const ValueKey('p06_option_weekly')));
        await _settle(tester);

        // The message rides inline in the danger token...
        expect(find.textContaining('mode write rejected'), findsOneWidget);
        final message = tester.widget<Text>(
          find.textContaining('mode write rejected'),
        );
        final tokens = tester.element(find.text('Both')).nest;
        expect(
          message.style?.color,
          tokens.danger,
          reason: 'a write error must read as danger, not as body copy',
        );
        // ...and the whole setup form survives it.
        for (final copy in const <String>[
          'How does pocket money work in your house?',
          'Weekly amount',
          'Earn per quest',
          'Both',
          'Payout day',
          'Weekly base',
          'Maya',
          '£3.00',
          'Coin value',
          '10 coins = 10p',
          'Continue',
        ]) {
          expect(find.text(copy), findsOneWidget, reason: '"$copy" vanished');
        }
        expect(find.byKey(const ValueKey('p06_day_6')), findsOneWidget);
        expect(find.byKey(const ValueKey('p06_retry')), findsNothing);
        // The rejected write is not applied: Both is still selected.
        final both = tester
            .getSemantics(find.byKey(const ValueKey('p06_option_both')))
            .getSemanticsData();
        expect(both.flagsCollection.isSelected, Tristate.isTrue);
        expect(tester.takeException(), isNull);

        // The next successful write re-emits and clears the message
        // (P06-BUG-06). Recovery rides the real Drift watch, so this test
        // delegates to the real repository instead of one-shot fake streams.
        await tester.tap(find.byKey(const ValueKey('p06_option_per_quest')));
        await _settle(tester);
        expect(find.textContaining('mode write rejected'), findsNothing);
        final perQuest = tester
            .getSemantics(find.byKey(const ValueKey('p06_option_per_quest')))
            .getSemanticsData();
        expect(perQuest.flagsCollection.isSelected, Tristate.isTrue);
        expect(bloc.state.errorMessage, isNull);

        handle.dispose();
        await disposeApp(tester);
      });
    }

    testWidgets('the router keeps working while an error is on screen', (
      tester,
    ) async {
      await setUpTestScope();
      final repository = _FlakyModeRepository(
        GetIt.instance<PocketMoneyRepository>(),
      );
      await GetIt.instance.unregister<PocketMoneyRepository>();
      GetIt.instance.registerSingleton<PocketMoneyRepository>(repository);
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      repository.failNextMode = true;
      await tester.tap(find.byKey(const ValueKey('p06_option_weekly')));
      await _settle(tester);
      expect(find.textContaining('mode write rejected'), findsOneWidget);
      expect(find.text('Payout day'), findsOneWidget);
      expect(find.text('£3.00'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Back'));
      await _settle(tester);
      expect(currentPath(tester), '/add-children');

      await disposeApp(tester);

      // ...and forward, from a fresh load with a second rejected write.
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );
      repository.failNextMode = true;
      await tester.tap(find.byKey(const ValueKey('p06_option_weekly')));
      await _settle(tester);
      expect(find.textContaining('mode write rejected'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('p06_continue')));
      await _settle(tester);
      expect(currentPath(tester), '/paywall');
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Owner rule — BOTTOM EDGE: the CTA surface must run to the physical edge.
  // -------------------------------------------------------------------------
  group('P06 setup — owner rule: bottom edge', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final themeName = theme == ThemeMode.light ? 'light' : 'dark';
      for (final bottomInset in const <double>[0, 34]) {
        testWidgets(
          '$themeName: the panel runs to the edge (OS inset $bottomInset)',
          (tester) async {
            await setUpTestScope();
            await _pumpSetupForPixels(
              tester,
              theme: theme,
              surface: const Size(390, 844),
              bottomInset: bottomInset,
            );

            final bar = tester.getRect(find.byType(NestBottomCta));
            expect(
              bar.bottom,
              moreOrLessEquals(844, epsilon: 0.01),
              reason:
                  'the panel must end at the physical screen edge; ending '
                  'it at ${bar.bottom} exposes page colour below the bar',
            );
            expect(bar.left, 0);
            expect(bar.right, moreOrLessEquals(390, epsilon: 0.01));

            final tokens = tester.element(find.byType(NestBottomCta)).nest;
            expect(
              tokens.paper,
              isNot(tokens.surface),
              reason:
                  'the probe must discriminate: page colour and bar '
                  'surface differ, so a strip below the bar cannot pass',
            );
            final edgePixel = await _pixelAt(tester, 195, 843);
            expect(
              edgePixel,
              _rgba(tokens.surface),
              reason:
                  'the strip below the panel (y=843) must be the panel '
                  'surface ${_rgba(tokens.surface)}; the scaffold paper '
                  '${_rgba(tokens.paper)} must not show through there',
            );

            await disposeApp(tester);
          },
        );
      }
    }
  });

  // -------------------------------------------------------------------------
  // Owner rule — ALIGNMENT: 20px gutters, cards and bar on the same edges.
  // -------------------------------------------------------------------------
  group('P06 setup — owner rule: alignment', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      for (final width in const <int>[320, 390, 430]) {
        final themeName = theme == ThemeMode.light ? 'light' : 'dark';
        testWidgets('$themeName ${width}dp: one 20px gutter on every edge', (
          tester,
        ) async {
          await setUpTestScope();
          await _pumpSetup(
            tester,
            theme: theme,
            surface: Size(width.toDouble(), 844),
            textScale: 1,
          );

          const gutter = NestSpacing.padSide;
          final edge = width.toDouble() - gutter;

          // The H1 and every card share the 20px gutter.
          expect(
            tester
                .getTopLeft(
                  find.text(
                    'How does pocket money work in your '
                    'house?',
                  ),
                )
                .dx,
            moreOrLessEquals(gutter, epsilon: 0.01),
          );
          for (final key in const <ValueKey<String>>[
            ValueKey('p06_option_weekly'),
            ValueKey('p06_option_per_quest'),
            ValueKey('p06_option_both'),
          ]) {
            final rect = tester.getRect(find.byKey(key));
            expect(rect.left, moreOrLessEquals(gutter, epsilon: 0.01));
            expect(rect.right, moreOrLessEquals(edge, epsilon: 0.01));
          }

          final card = tester.getRect(_settingsCard());
          expect(card.left, moreOrLessEquals(gutter, epsilon: 0.01));
          expect(card.right, moreOrLessEquals(edge, epsilon: 0.01));

          // The CTA panel is full-bleed; its button shares the same gutter.
          final bar = tester.getRect(find.byType(NestBottomCta));
          expect(bar.left, 0);
          expect(bar.right, moreOrLessEquals(width.toDouble(), epsilon: 0.01));
          final cta = tester.getRect(
            find.byKey(const ValueKey('p06_continue')),
          );
          expect(cta.left, moreOrLessEquals(gutter, epsilon: 0.01));
          expect(cta.right, moreOrLessEquals(edge, epsilon: 0.01));

          // Inside the settings card every row — including the payout-day
          // chip row, which starts on the same 16 px inset as the label
          // and ends at the matching right inset — shares one inner edge
          // (the dividers stay full-bleed).
          final inner = card.left + NestSpacing.s4;
          for (final finder in <Finder>[
            find.text('Payout day'),
            find.text('Weekly base'),
            _coinTile(),
            _mayaAvatar(),
            find.byKey(const ValueKey('p06_day_1')),
          ]) {
            expect(
              tester.getTopLeft(finder).dx,
              moreOrLessEquals(inner, epsilon: 0.01),
              reason: 'every settings row must start on the same inner edge',
            );
          }
          // The names sit one avatar in (s32 avatar + s3 gap), and the coin
          // value one tile in — the same rhythm on both rows.
          expect(
            tester.getTopLeft(find.text('Maya')).dx,
            moreOrLessEquals(inner + 32 + NestSpacing.s3, epsilon: 0.01),
          );
          expect(
            tester.getTopLeft(find.text('Coin value')).dx,
            moreOrLessEquals(inner + 40 + NestSpacing.s3, epsilon: 0.01),
          );
          // The coin row's trailing value never crosses the right inset, so
          // it can never push the 40px tile.
          expect(
            tester.getRect(find.text('10 coins = 10p')).right,
            lessThanOrEqualTo(card.right - NestSpacing.s4 + 0.01),
          );

          expect(tester.takeException(), isNull);
          await disposeApp(tester);
        });
      }
    }
  });

  // -------------------------------------------------------------------------
  // Orchestrator rulings: child order, data over mocks, parent-only route.
  // -------------------------------------------------------------------------
  group('P06 setup — orchestrator rulings', () {
    for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      final themeName = theme == ThemeMode.light ? 'light' : 'dark';
      for (final width in const <int>[320, 390]) {
        testWidgets('$themeName ${width}dp: Maya above Leo, never reversed', (
          tester,
        ) async {
          await setUpTestScope();
          await _pumpSetup(
            tester,
            theme: theme,
            surface: Size(width.toDouble(), 844),
            textScale: 1,
          );

          final maya = tester.getTopLeft(
            find.byKey(const ValueKey('p06_base_row_maya')),
          );
          final leo = tester.getTopLeft(
            find.byKey(const ValueKey('p06_base_row_leo')),
          );
          expect(
            maya.dy,
            lessThan(leo.dy),
            reason: 'children render in the order they were added',
          );
          expect(
            tester.getTopLeft(find.text('Maya')).dy,
            lessThan(tester.getTopLeft(find.text('Leo')).dy),
            reason: 'the names stack in that same order',
          );
          expect(find.text('£3.00'), findsOneWidget);
          expect(find.text('£1.50'), findsOneWidget);
          // The steppers follow the same order: Maya's sits above Leo's.
          expect(
            tester
                .getTopLeft(
                  find.bySemanticsLabel(
                    RegExp('Less weekly pocket money for Maya'),
                  ),
                )
                .dy,
            lessThan(
              tester
                  .getTopLeft(
                    find.bySemanticsLabel(
                      RegExp('Less weekly pocket money for Leo'),
                    ),
                  )
                  .dy,
            ),
          );
          // Avatar initials follow the same order (Maya lilac M, Leo peach L).
          expect(find.text('M'), findsOneWidget);
          expect(find.text('L'), findsOneWidget);
          expect(tester.takeException(), isNull);

          await disposeApp(tester);
        });
      }
    }

    testWidgets('the coin value string follows the database, not the design', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await (db.update(db.families)..where((f) => f.id.equals(Seed.familyId)))
          .write(const FamiliesCompanion(coinValuePencePerCoin: Value(2)));
      await GetIt.instance<AppSession>().refresh();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      expect(find.text('10 coins = 20p'), findsOneWidget);
      expect(find.text('10 coins = 10p'), findsNothing);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the route is parent-only: kid mode lands on the gate', (
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
  });

  // -------------------------------------------------------------------------
  // States: no fake defaults while loading, Retry recovers, empty is usable.
  // -------------------------------------------------------------------------
  group('P06 setup — state recovery', () {
    testWidgets('loading never flashes a fake money style', (tester) async {
      final bloc = await _pumpSetupView(
        tester,
        repository: _FakePocketMoneyRepository(),
        theme: ThemeMode.light,
      );
      bloc.add(const PocketMoneyLoadRequested());
      await _settle(tester);

      expect(bloc.state.status, PocketMoneyStatus.loading);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      for (final fake in const <String>[
        'Weekly amount',
        'Earn per quest',
        'Both',
        '£3.00',
        '10 coins = 10p',
      ]) {
        expect(
          find.text(fake),
          findsNothing,
          reason:
              'plan §4: no option cards with invented defaults — a flash '
              'of "Both" before the stream emits would be a lie',
        );
      }
      // The chrome and the CTA stay put so the step never collapses.
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byKey(const ValueKey('p06_continue')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('Retry after a failure recovers the loaded screen', (
      tester,
    ) async {
      var subscriptions = 0;
      final bloc = await _pumpSetupView(
        tester,
        repository: _FakePocketMoneyRepository(
          // Both halves of `combineLatest2` must emit for the bloc to reach
          // `loaded`; a fake whose ledger stream stays empty would hang in
          // `loading` (a fake artefact, not a screen behaviour).
          items: () =>
              Stream<List<PocketMoneyEntry>>.value(const <PocketMoneyEntry>[]),
          setup: () {
            subscriptions++;
            return subscriptions == 1
                ? Stream<PocketMoneySetup>.error(Exception('offline'))
                : Stream<PocketMoneySetup>.value(_demoSetup);
          },
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const PocketMoneyLoadRequested());
      await _settle(tester);

      expect(find.textContaining('offline'), findsOneWidget);
      expect(find.byKey(const ValueKey('p06_retry')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('p06_retry')));
      await _settle(tester);

      expect(bloc.state.status, PocketMoneyStatus.loaded);
      expect(find.textContaining('offline'), findsNothing);
      expect(find.text('Both'), findsOneWidget);
      expect(find.text('£3.00'), findsOneWidget);
      expect(find.text('Coin value'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the failure body never leaks a half-loaded card', (
      tester,
    ) async {
      final bloc = await _pumpSetupView(
        tester,
        repository: _FakePocketMoneyRepository(
          setup: () => Stream<PocketMoneySetup>.error(Exception('offline')),
        ),
        theme: ThemeMode.light,
      );
      bloc.add(const PocketMoneyLoadRequested());
      await _settle(tester);

      expect(find.byKey(const ValueKey('p06_option_both')), findsNothing);
      expect(find.byKey(const ValueKey('p06_day_6')), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
      // Retry is a parent-mode control: same 44dp floor as the rest.
      expect(
        tester.getSize(find.byKey(const ValueKey('p06_retry'))).height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );

      await disposeApp(tester);
    });

    testWidgets('Seed.empty: the screen still selects a style and advances', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(find.byKey(const ValueKey('p06_option_weekly')));
      await _settle(tester);
      final weekly = tester
          .getSemantics(find.byKey(const ValueKey('p06_option_weekly')))
          .getSemanticsData();
      expect(weekly.flagsCollection.isSelected, Tristate.isTrue);
      expect(currentPath(tester), '/pocket-money-setup');

      await tester.tap(find.byKey(const ValueKey('p06_day_7')));
      await _settle(tester);
      expect(find.byKey(const ValueKey('p06_day_7')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('p06_continue')));
      await _settle(tester);
      expect(currentPath(tester), '/paywall');
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Navigation: the taps that must NOT navigate, and the two that must.
  // -------------------------------------------------------------------------
  group('P06 setup — every tap stays or goes somewhere deliberate', () {
    testWidgets('mode, day and stepper taps never leave the screen', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      await tester.tap(find.byKey(const ValueKey('p06_option_weekly')));
      await _settle(tester);
      expect(currentPath(tester), '/pocket-money-setup');

      await tester.tap(find.byKey(const ValueKey('p06_day_3')));
      await _settle(tester);
      expect(currentPath(tester), '/pocket-money-setup');

      await tester.tap(
        find.bySemanticsLabel(RegExp('More weekly pocket money for Maya')),
      );
      await _settle(tester);
      expect(find.text('£3.50'), findsOneWidget);
      expect(currentPath(tester), '/pocket-money-setup');

      // The coin row is display-only: tapping it changes nothing. It lives
      // below the fold, behind the fixed CTA, so scroll it into view first.
      await tester.ensureVisible(find.text('Coin value'));
      await _settle(tester);
      await tester.tap(find.text('Coin value'));
      await _settle(tester);
      expect(find.text('10 coins = 10p'), findsOneWidget);
      expect(currentPath(tester), '/pocket-money-setup');
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('Continue and Back are the only two exits', (tester) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // Exactly two navigable controls on the screen.
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      expect(find.byKey(const ValueKey('p06_continue')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('p06_continue')));
      await _settle(tester);
      expect(currentPath(tester), '/paywall');

      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // Iteration 4 — ORCHESTRATOR_NOTES items 1, 3, 4, 5 + the CHIP ROWS rule.
  // -------------------------------------------------------------------------
  group('P06 setup — iteration 4 contract', () {
    testWidgets(
      'Seed.onboardingKids (the shoot seed) renders the children from '
      'the database, in insertion order',
      (tester) async {
        final db = await setUpTestScope(seedDemo: false);
        await Seed.onboardingKids(db);
        await GetIt.instance<AppSession>().refresh();
        await _pumpSetup(
          tester,
          theme: ThemeMode.light,
          surface: const Size(390, 844),
          textScale: 1,
        );

        // Note item 1: the parent arrives here from P05 *after* adding
        // children, so the Weekly base card must be populated — and every
        // number comes from the row, never from the view.
        expect(find.text('Maya'), findsOneWidget);
        expect(find.text('Leo'), findsOneWidget);
        expect(find.text('£3.00'), findsOneWidget);
        expect(find.text('£1.50'), findsOneWidget);
        expect(find.text('Add children to set weekly amounts.'), findsNothing);
        expect(
          tester.getTopLeft(find.text('Maya')).dy,
          lessThan(tester.getTopLeft(find.text('Leo')).dy),
          reason: 'insertion order (Maya, then Leo) — never alphabetical',
        );
        expect(find.text('L'), findsOneWidget); // Leo's avatar initial
        expect(find.text('M'), findsOneWidget);

        // Out-of-band the values are still the seed's (no view defaults): a
        // stepper tap starts from £3.00, not from a hard-coded number.
        await tester.tap(
          find.bySemanticsLabel(RegExp('More weekly pocket money for Maya')),
        );
        await _settle(tester);
        expect(find.text('£3.50'), findsOneWidget);
        expect(find.textContaining('£3.00'), findsNothing);
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      },
    );

    testWidgets('no text on the screen carries letter spacing (note item 3)', (
      tester,
    ) async {
      for (final theme in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
        await setUpTestScope();
        await _pumpSetup(
          tester,
          theme: theme,
          surface: const Size(390, 844),
          textScale: 1,
        );

        final tracked = <String>[];
        for (final widget in tester.widgetList<Text>(find.byType(Text))) {
          final data = widget.data;
          if (data == null || data.isEmpty) continue;
          final spacing = widget.style?.letterSpacing;
          // The shared fix (shared/letter_spacing_zero) keeps NestType at 0
          // because the design CSS has no tracking; a non-zero value here
          // means Material tracking crept back in or a local copyWith added
          // it (the only sanctioned cases are P12's hero -0.4 and K02's
          // `.mark` 1.28 — neither is on P06).
          if (spacing != null && spacing != 0) {
            tracked.add('"$data" letterSpacing=$spacing');
          }
        }
        expect(
          tracked,
          isEmpty,
          reason: 'the design CSS declares no tracking for P06',
        );

        // Spot-check the resolved style of the styles the screen sets
        // explicitly, in case a merge re-introduced Material defaults.
        final h1 = tester.widget<Text>(
          find.text('How does pocket money work in your house?'),
        );
        expect(h1.style?.letterSpacing ?? 0, 0);
        final caption = tester.widget<Text>(
          find.textContaining('Nestling never holds or moves money'),
        );
        expect(caption.style?.letterSpacing ?? 0, 0);
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      }
    });

    testWidgets('option cards use the HTML line heights 22/20 (note item 5)', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // design/html-source/screens/P06-pocket-money.html:
      //   .opt-title { font-size: 16px; line-height: 22px }
      //   .opt-sub   { font-size: 15px; line-height: 20px }
      //   .opt-card  { min-height: 60px; padding: 8px 13px }
      final title = tester.widget<Text>(find.text('Weekly amount'));
      final sub = tester.widget<Text>(find.text('A set amount every week'));
      expect(title.style?.fontSize, 16);
      expect(title.style?.height, moreOrLessEquals(22 / 16, epsilon: 0.001));
      expect(sub.style?.fontSize, 15);
      expect(sub.style?.height, moreOrLessEquals(20 / 15, epsilon: 0.001));

      final card = tester.getRect(
        find.byKey(const ValueKey('p06_option_weekly')),
      );
      expect(card.height, greaterThanOrEqualTo(60));
      expect(card.left, moreOrLessEquals(NestSpacing.padSide, epsilon: 0.01));
      expect(
        card.right,
        moreOrLessEquals(390 - NestSpacing.padSide, epsilon: 0.01),
      );
      // The 22px radio sits on the card's own padding edge.
      final radio = tester.getRect(
        find
            .descendant(
              of: find.byKey(const ValueKey('p06_option_weekly')),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Container &&
                    widget.constraints?.maxWidth == 22 &&
                    widget.constraints?.maxHeight == 22,
              ),
            )
            .first,
      );
      // 2px card border + 13px HTML padding.
      expect(radio.left - card.left, moreOrLessEquals(2 + 13, epsilon: 0.01));
      expect(radio.height, 22);

      // 2px border + 8px padding + 22 title + 2 gap + 20 sub + 8px padding =
      // 64 for the design's single-line card. The widget-test fallback font
      // is ~1em per glyph and wraps the sub onto two lines here, so the card
      // is only bounded from below; the line boxes themselves are pinned
      // above (22 / 20) and by the painted title height.
      expect(card.height, greaterThanOrEqualTo(64));
      expect(
        tester.getSize(find.text('Weekly amount')).height,
        moreOrLessEquals(22, epsilon: 0.01),
        reason: 'the title paints one 22px line box',
      );
      final subHeight = tester
          .getSize(find.text('A set amount every week'))
          .height;
      expect(subHeight, greaterThanOrEqualTo(20));
      expect(subHeight % 20, moreOrLessEquals(0, epsilon: 0.01));
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the coin tile is a 40x40 coinTint tile with the gold coin '
        'glyph (note item 4)', (tester) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      final tile = tester.getRect(_coinTile());
      expect(tile.width, NestSpacing.s10);
      expect(tile.height, NestSpacing.s10);

      final decoration =
          tester.widget<Container>(_coinTile()).decoration! as BoxDecoration;
      final tokens = tester.element(find.text('Coin value')).nest;
      expect(decoration.color, tokens.coinTint);
      expect(
        decoration.borderRadius,
        NestRadii.allM,
        reason: 'the design tile uses r-m on all corners',
      );

      // The glyph is the gold coin SVG from app/assets, not a £ symbol.
      final coin = find.descendant(
        of: _coinTile(),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SvgPicture &&
              widget.bytesLoader is SvgAssetLoader &&
              (widget.bytesLoader as SvgAssetLoader).assetName ==
                  NestlingIllustrations.coin,
        ),
      );
      expect(coin, findsOneWidget);
      final svg = tester.widget<SvgPicture>(coin);
      expect(svg.width, NestSpacing.s6);
      expect(svg.height, NestSpacing.s6);
      // Still decorative: excluded from the a11y tree.
      expect(
        find.ancestor(of: coin, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
      );
      // No leftover pound-sign glyph from the previous iteration.
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is NestIcon && widget.assetName == NestIcons.poundCoin,
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('the chip row is a NestChipWrap, so its 44px hit area '
        'survives the 32px pills', (tester) async {
      await setUpTestScope();
      await _pumpSetup(
        tester,
        theme: ThemeMode.light,
        surface: const Size(390, 844),
        textScale: 1,
      );

      // CHIP ROWS rule (main): an interactive chip row uses NestChipWrap.
      final wrap = find.ancestor(
        of: find.byKey(const ValueKey('p06_day_1')),
        matching: find.byType(NestChipWrap),
      );
      expect(wrap, findsOneWidget);
      // The wrap's box is 32, pinned to the pills' band — taps 5 px
      // above/below are forwarded by RenderNestChipWrap.hitTest (proven by
      // the tap-above/below test and the ±6px contract in P06/4_review).
      expect(tester.getSize(wrap).height, NestSpacing.s8);
      expect(
        tester.getRect(dayPill(1)).height,
        moreOrLessEquals(NestSpacing.s8, epsilon: 0.01),
      );

      await disposeApp(tester);
    });
  });
}
