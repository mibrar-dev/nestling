// P06 Pocket money setup — widget contract.
//
// Covers: the exact §0 copy in light + dark, the width × text-scale matrix
// (320/390/430 × 1.0/1.3, no overflow), write-through selection (mode cards,
// payout-day chips, weekly-base steppers), back/Continue navigation, the
// empty-children caption (Seed.empty), loading/failure states, and the
// accessibility contract (radiogroup labels, selected flags, stepper labels,
// 44dp parent tap targets).

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:google_fonts/google_fonts.dart';
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
class _FakePocketMoneyRepository implements PocketMoneyRepository {
  _FakePocketMoneyRepository({
    Stream<List<PocketMoneyEntry>>? items,
    Stream<PocketMoneySetup>? setup,
  }) : _items = items ?? const Stream<List<PocketMoneyEntry>>.empty(),
       _setup = setup ?? const Stream<PocketMoneySetup>.empty();

  final Stream<List<PocketMoneyEntry>> _items;
  final Stream<PocketMoneySetup> _setup;

  @override
  Future<List<PocketMoneyEntry>> getItems() => _items.first;

  @override
  Stream<List<PocketMoneyEntry>> watchItems() => _items;

  @override
  Stream<List<PocketMoneyEntry>> watchLedger(String childId) => _items;

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
  Stream<PocketMoneySetup> watchSetup() => _setup;

  @override
  Future<void> setMode(String mode) async {}

  @override
  Future<void> setPayoutDay(int day) async {}

  @override
  Future<void> setWeeklyBasePence(String childId, int pence) async {}
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
Future<PocketMoneyBloc> _pumpSetupView(
  WidgetTester tester, {
  required PocketMoneyRepository repository,
  required ThemeMode theme,
}) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  final bloc = PocketMoneyBloc(repository: repository);
  addTearDown(bloc.close);
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
      expect(selected.flagsCollection.isSelected, isTrue);
      final weekly = tester
          .getSemantics(find.byKey(const ValueKey('p06_option_weekly')))
          .getSemanticsData();
      expect(weekly.flagsCollection.isSelected, isFalse);
      final sat = tester
          .getSemantics(find.byKey(const ValueKey('p06_day_6')))
          .getSemanticsData();
      expect(sat.flagsCollection.isSelected, isTrue);
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
      expect(perQuest.flagsCollection.isSelected, isTrue);
      final both = tester
          .getSemantics(find.byKey(const ValueKey('p06_option_both')))
          .getSemanticsData();
      expect(both.flagsCollection.isSelected, isFalse);
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
      expect(sun.flagsCollection.isSelected, isTrue);
      final sat = tester
          .getSemantics(find.byKey(const ValueKey('p06_day_6')))
          .getSemanticsData();
      expect(sat.flagsCollection.isSelected, isFalse);
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
        find.bySemanticsLabel('More weekly pocket money for Maya'),
      );
      await _settle(tester);
      expect(find.text('£3.50'), findsOneWidget);

      await tester.tap(
        find.bySemanticsLabel('Less weekly pocket money for Leo'),
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

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    testWidgets('failure: message plus a Retry button', (tester) async {
      final bloc = await _pumpSetupView(
        tester,
        repository: _FakePocketMoneyRepository(
          setup: Stream<PocketMoneySetup>.error(Exception('offline')),
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

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
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
        find.bySemanticsLabel('Less weekly pocket money for Maya'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('More weekly pocket money for Maya'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('Less weekly pocket money for Leo'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('More weekly pocket money for Leo'),
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
      // Day cells keep the 44dp tap height while the pill scales down.
      for (var day = 1; day <= 7; day++) {
        final size = tester.getSize(find.byKey(ValueKey('p06_day_$day')));
        expect(size.height, 44);
      }
      for (final label in <String>[
        'Less weekly pocket money for Maya',
        'More weekly pocket money for Maya',
        'Less weekly pocket money for Leo',
        'More weekly pocket money for Leo',
      ]) {
        final size = tester.getSize(find.bySemanticsLabel(label));
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
        expect(size.height, 44);
      }
      final continueSize = tester.getSize(
        find.byKey(const ValueKey('p06_continue')),
      );
      expect(continueSize.height, greaterThanOrEqualTo(44));
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });
  });
}
