import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/core/data/app_database.dart' as db;
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart';
import 'package:nestling/features/rewards/domain/rewards_repository.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_bloc.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_event.dart';
import 'package:nestling/features/rewards/presentation/views/rewards_view.dart';
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_card.dart';
import 'package:nestling/features/rewards/rewards_routes.dart';

import '../../test_scope.dart';

class _FailRepository extends Mock implements RewardsRepository;

final _failRepo = _FailRepository();

/// Design order is the database order: `watchItems` is `coinPrice ASC`, so
/// the demo seed renders 50/60/80/90/100/150 — six rows, not the five the
/// HTML/PNGs draw (DATA OVER MOCKS).
const _expectedOrder = <String, int>{
  '30 min extra screen time': 50,
  'Stay up 15 min later': 60,
  'Pick Friday film': 80,
  'Choose dinner': 90,
  'Baking together': 100,
  'Trip to the park café': 150,
};

Future<void> _pumpView(
  WidgetTester tester,
  RewardsBloc bloc, {
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      themeMode: theme,
      home: BlocProvider<RewardsBloc>.value(
        value: bloc,
        child: const RewardsView(),
      ),
    ),
  );
  await tester.pump();
}

Future<List<db.Reward>> _rows() {
  final database = GetIt.instance<db.AppDatabase>();
  return (database.select(
    database.rewards,
  )..orderBy([(r) => OrderingTerm(expression: r.coinPrice)])).get();
}

void main() {
  // mocktail needs a concrete fallback for the `Reward` arguments of the
  // failing repository stub.
  setUpAll(
    () => registerFallbackValue(
      const Reward(
        id: '',
        title: '',
        detail: '',
        icon: '',
        coinPrice: 0,
        needsOk: false,
      ),
    ),
  );

  group('P14 rewards view', () {
    testWidgets('renders the nav title, exact intro and the DB order', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, RewardsRoutePaths.rewards);

      expect(find.text('Reward shop'), findsOneWidget);
      // Em dash U+2014 and the full stop, copied from the HTML.
      expect(
        find.text(
          'Things coins can buy — you decide. Children spend coins, never pounds.',
        ),
        findsOneWidget,
      );

      final cards = tester
          .widgetList<RewardCard>(find.byType(RewardCard))
          .toList();
      expect(cards.length, 6);
      expect(
        cards.map((c) => c.reward.title).toList(),
        _expectedOrder.keys.toList(),
      );
      expect(
        cards.map((c) => c.reward.coinPrice).toList(),
        _expectedOrder.values.toList(),
      );
      // Every seeded `needsOk` is true, so all six switches render ON (the
      // light/dark PNGs draw "Baking together" off — the DB wins).
      expect(cards.every((c) => c.reward.needsOk), isTrue);

      await disposeApp(tester);
    });

    testWidgets('shows the exact coin amounts and does not overflow in dark', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(
        tester,
        RewardsRoutePaths.rewards,
        theme: ThemeMode.dark,
      );

      for (final price in _expectedOrder.values) {
        expect(find.text('$price'), findsWidgets);
      }
      expect(tester.takeException(), isNull);

      await disposeApp(tester);
    });

    testWidgets('every control exposes SemanticsAction.tap', (tester) async {
      await setUpTestScope();
      final handle = tester.ensureSemantics();
      await pumpAppRoute(tester, RewardsRoutePaths.rewards);

      for (final label in <String>[
        'Back',
        'Needs approval for screen time',
        'Edit 30 min extra screen time',
        '+ New reward',
      ]) {
        final tappable = find.semantics
            .byLabel(label)
            .evaluate()
            .where((n) => n.getSemanticsData().hasAction(SemanticsAction.tap));
        expect(
          tappable,
          isNotEmpty,
          reason: '"$label" must expose a SemanticsAction.tap node',
        );
      }

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('tapping the toggle writes through to the database', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, RewardsRoutePaths.rewards);

      final toggle = find.byType(NestToggle).first;
      expect(
        tester.widget<NestToggle>(toggle).value,
        isTrue,
        reason: 'the demo seed has needsOk true',
      );

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      var rows = await _rows();
      expect(rows.firstWhere((r) => r.id == 'r-screen').needsOk, isFalse);

      // 5 px above the 51×31 track is still inside the 44 px tap box.
      final track = tester.getRect(
        find.descendant(of: toggle, matching: find.byType(AnimatedContainer)),
      );
      await tester.tapAt(Offset(track.center.dx, track.top - 5));
      await tester.pumpAndSettle();
      rows = await _rows();
      expect(rows.firstWhere((r) => r.id == 'r-screen').needsOk, isTrue);

      await disposeApp(tester);
    });

    testWidgets('edit opens a prefilled sheet, Save writes, Delete removes', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, RewardsRoutePaths.rewards);

      await tester.tap(find.bySemanticsLabel('Edit Pick Friday film'));
      await tester.pumpAndSettle();
      expect(find.text('Edit reward'), findsOneWidget);
      expect(
        find.widgetWithText(NestTextField, 'Pick Friday film'),
        findsOneWidget,
      );
      expect(find.text('80 coins'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('p14_name_field')),
        'Pick a Saturday film',
      );
      await tester.tap(find.byKey(const ValueKey('p14_save')));
      await tester.pumpAndSettle();

      var rows = await _rows();
      expect(rows.map((r) => r.title), contains('Pick a Saturday film'));

      await tester.tap(find.bySemanticsLabel('Edit Pick a Saturday film'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_delete')));
      await tester.pumpAndSettle();
      // First tap only arms the destructive action.
      expect(find.text('Confirm delete'), findsOneWidget);
      rows = await _rows();
      expect(rows.map((r) => r.title), contains('Pick a Saturday film'));

      await tester.tap(find.byKey(const ValueKey('p14_delete')));
      await tester.pumpAndSettle();
      rows = await _rows();
      expect(rows.map((r) => r.title), isNot(contains('Pick a Saturday film')));

      await disposeApp(tester);
    });

    testWidgets('+ New reward creates with the sheet defaults, Cancel writes '
        'nothing', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, RewardsRoutePaths.rewards);

      // The button sits below the fold with six demo rows.
      await tester.ensureVisible(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      expect(find.text('New reward'), findsOneWidget);
      expect(find.text('50 coins'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('p14_name_field')),
        'Choose dessert',
      );
      await tester.tap(find.byKey(const ValueKey('p14_cancel')));
      await tester.pumpAndSettle();
      expect(
        (await _rows()).map((r) => r.title),
        isNot(contains('Choose dessert')),
      );

      await tester.ensureVisible(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      expect(find.text('New reward'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('p14_name_field')),
        'Choose dessert',
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<NestButton>(find.byKey(const ValueKey('p14_save')))
            .onPressed,
        isNotNull,
        reason: 'Save must enable once the name is non-empty',
      );
      await tester.tap(find.byKey(const ValueKey('p14_save')));
      await tester.pumpAndSettle();

      final created = (await _rows()).where((r) => r.title == 'Choose dessert');
      expect(
        created.map((r) => r.title),
        hasLength(1),
        reason:
            'rows now: ${(await _rows()).map((r) => '${r.title}@${r.coinPrice}').toList()}',
      );
      expect(created.single.coinPrice, 50);
      expect(created.single.needsOk, isTrue);
      expect(created.single.id, startsWith('reward-'));

      await disposeApp(tester);
    });

    testWidgets('an empty database shows the empty state and still creates', (
      tester,
    ) async {
      await setUpTestScope();
      final database = GetIt.instance<db.AppDatabase>();
      await database.delete(database.rewards).go();
      await pumpAppRoute(tester, RewardsRoutePaths.rewards);

      expect(find.text('No rewards yet'), findsOneWidget);
      expect(
        find.text(
          'Add something coins can buy — a film night, extra screen time, a trip out.',
        ),
        findsOneWidget,
      );
      expect(find.byType(RewardCard), findsNothing);

      await tester.tap(find.byKey(const ValueKey('p14_empty_new_reward')));
      await tester.pumpAndSettle();
      expect(find.text('New reward'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('a load failure offers Try again', (tester) async {
      await setUpTestScope();
      when(_failRepo.watchItems)
          .thenAnswer((_) => Stream<List<Reward>>.error(StateError('boom')));
      when(_failRepo.watchRequests).thenAnswer((_) => const Stream.empty());
      when(_failRepo.getItems).thenAnswer((_) async => <Reward>[]);
      when(
        () => _failRepo.setNeedsOk(
          id: any(named: 'id'),
          needsOk: any(named: 'needsOk'),
        ),
      ).thenAnswer((_) async {});
      when(() => _failRepo.deleteReward(any())).thenAnswer((_) async {});
      when(() => _failRepo.createReward(any())).thenAnswer((_) async {});
      when(() => _failRepo.updateReward(any())).thenAnswer((_) async {});

      final bloc = RewardsBloc(repository: _failRepo)
        ..add(const RewardsLoadRequested());
      await _pumpView(tester, bloc);
      // Bounded pumps, not `pumpAndSettle`: a `loading` state parks an
      // indeterminate spinner, which never settles.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const ValueKey('p14_try_again')), findsOneWidget);

      when(_failRepo.watchItems)
          .thenAnswer((_) => Stream<List<Reward>>.value(const <Reward>[]));
      await tester.tap(find.byKey(const ValueKey('p14_try_again')));
      await tester.pumpAndSettle();
      expect(find.text('No rewards yet'), findsOneWidget);
    });
  });
}
