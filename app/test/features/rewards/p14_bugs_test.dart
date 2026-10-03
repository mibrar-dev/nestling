// P14 · Rewards manager — adversarial bug proofs (Stage 6, iteration 1).
//
// Iteration 1 found:
//   P14-B01 (major) the editor sheet ignores the iOS keyboard — Save, Cancel
//                   and Delete sit behind the keyboard once the name field is
//                   focused.
//   P14-B02 (minor) the empty and failure surfaces are top-aligned under the
//                   nav bar instead of centred in the scroll (plan §4).
//   P14-B03 (minor) a sheet write failure closes the sheet and loses the typed
//                   input; no inline error caption (plan §4).
//   P14-B04 (minor, latent) deleting a reward does not clean up or block its
//                   pending redemption requests (foreign keys are off).
//   P14-B05 (major) the list is ordered by coin price, not creation order
//                   (ORCHESTRATOR_NOTES 12:27: "the data order is wrong";
//                   main's `watchRewardsInCreationOrder` is the fix).
//
// Every open-bug proof is `skip`-marked with its id in the test name so the
// suite stays green while the defect is unfixed. `flutter test
// test/features/rewards/p14_bugs_test.dart --run-skipped` proves each skipped
// test still fails on the current code; when a fix lands, remove its skip and
// the test must pass.
//
// The green tests at the bottom are the checks this stage verified clean:
// kid-mode guard, back navigation, restart persistence, rapid double taps,
// 9999 coins / long names at 320 × 1.3, accessibility actions, the empty-state
// create round-trip and dark mode. They separate "found broken" from
// "verified working".
//
// Full report: docs/screens/P14/6_bugs.md.

import 'dart:async';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart' as db;
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart';
import 'package:nestling/features/rewards/domain/rewards_repository.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_bloc.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_event.dart';
import 'package:nestling/features/rewards/presentation/views/rewards_view.dart';
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_card.dart';
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_editor_sheet.dart';

import '../../test_scope.dart';

class _MockRewardsRepository extends Mock implements RewardsRepository;

/// The scroll viewport's vertical centre: below `NestStatusBar` (47) and the
/// compact nav bar (60) down to the 844 px screen edge. A centred surface
/// lands on this line; the current top-aligned surfaces land near y ≈ 290.
const double _contentCentre = (47 + 60 + 844) / 2;

Future<List<db.Reward>> _rows() {
  final database = GetIt.instance<db.AppDatabase>();
  return (database.select(
    database.rewards,
  )..orderBy([(r) => OrderingTerm(expression: r.coinPrice)])).get();
}

/// Widget tests do not load the bundled families automatically; the centring
/// proofs below depend on the real text heights, so load them first.
Future<void> _loadFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  await inter.load();
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
  await nunito.load();
}

/// Pumps [RewardsView] directly over a bloc whose writes always fail — used by
/// the P14-B03 proof (the view's own route is not needed).
Future<void> _pumpViewWithFailingWrites(
  WidgetTester tester,
  RewardsBloc bloc,
) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      home: BlocProvider<RewardsBloc>.value(
        value: bloc,
        child: const RewardsView(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  setUpAll(() async {
    await _loadFonts();
    registerFallbackValue(
      const Reward(
        id: '',
        title: '',
        detail: '',
        icon: '',
        coinPrice: 0,
        needsOk: false,
      ),
    );
  });

  // -------------------------------------------------------------------------
  // Open bugs (skip-marked with their id; `--run-skipped` proves they fail).
  // -------------------------------------------------------------------------

  testWidgets(
    '[P14-B01] the keyboard must not cover the editor sheet controls',
    (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/rewards');

      await tester.ensureVisible(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();

      // The parent focuses the name field; on iOS the keyboard then floats
      // over the Flutter view (viewInsets.bottom), it does not resize it.
      await tester.tap(find.byKey(const ValueKey('p14_name_field')));
      await tester.pump();
      tester.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();

      const keyboardTop = 844.0 - 300;
      final save = tester.getRect(find.byKey(const ValueKey('p14_save')));
      final cancel = tester.getRect(find.byKey(const ValueKey('p14_cancel')));
      expect(
        save.bottom,
        lessThanOrEqualTo(keyboardTop),
        reason:
            'Save must sit above the keyboard; measured bottom '
            '${save.bottom} vs keyboard top $keyboardTop',
      );
      expect(
        cancel.bottom,
        lessThanOrEqualTo(keyboardTop),
        reason:
            'Cancel must sit above the keyboard; measured bottom '
            '${cancel.bottom} vs keyboard top $keyboardTop',
      );

      await disposeApp(tester);
    },
    // P14-B01: major — showNestBottomSheet ignores MediaQuery.viewInsets, so
    // on iOS the keyboard covers Save/Cancel/Delete. Open.
    skip: true,
  );

  testWidgets(
    '[P14-B02] the empty state is centred in the scroll area',
    (tester) async {
      await setUpTestScope();
      final database = GetIt.instance<db.AppDatabase>();
      await database.delete(database.rewards).go();
      await pumpAppRoute(tester, '/rewards');

      final rect = tester.getRect(find.byType(NestEmptyState));
      expect(
        rect.center.dy,
        closeTo(_contentCentre, 60),
        reason:
            'plan §4 centres the empty state in the scroll; measured centre '
            '${rect.center.dy} vs viewport centre $_contentCentre',
      );

      await disposeApp(tester);
    },
    // P14-B02: minor — _RewardsScroll is a ListView, so the inner Center
    // shrink-wraps and the empty state is pinned under the nav bar. Open.
    skip: true,
  );

  testWidgets(
    '[P14-B02] the failure surface is centred in the scroll area',
    (tester) async {
      final repository = _MockRewardsRepository();
      when(repository.watchItems)
          .thenAnswer((_) => Stream<List<Reward>>.error(StateError('boom')));
      when(repository.watchRequests).thenAnswer((_) => const Stream.empty());
      when(repository.getItems).thenAnswer((_) async => <Reward>[]);
      when(
        () => repository.setNeedsOk(
          id: any(named: 'id'),
          needsOk: any(named: 'needsOk'),
        ),
      ).thenAnswer((_) async {});
      when(() => repository.createReward(any())).thenAnswer((_) async {});
      when(() => repository.updateReward(any())).thenAnswer((_) async {});
      when(() => repository.deleteReward(any())).thenAnswer((_) async {});

      final bloc = RewardsBloc(repository: repository)
        ..add(const RewardsLoadRequested());
      await _pumpViewWithFailingWrites(tester, bloc);

      final message = tester.getRect(find.textContaining('boom'));
      final button = tester.getRect(
        find.byKey(const ValueKey('p14_try_again')),
      );
      final surfaceCentre = (message.top + button.bottom) / 2;
      expect(
        surfaceCentre,
        closeTo(_contentCentre, 80),
        reason:
            'plan §4 centres the failure message; measured centre '
            '$surfaceCentre vs viewport centre $_contentCentre',
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
    // P14-B02: minor — same top-aligned root cause as the empty state. Open.
    skip: true,
  );

  testWidgets(
    '[P14-B03] a sheet write failure keeps the sheet open with an inline error',
    (tester) async {
      final repository = _MockRewardsRepository();
      when(repository.watchItems).thenAnswer(
        (_) => Stream.value(const <Reward>[
          Reward(
            id: 'r-screen',
            title: '30 min extra screen time',
            detail: '50 coins',
            icon: 'tv',
            coinPrice: 50,
            needsOk: true,
          ),
        ]),
      );
      when(repository.watchRequests).thenAnswer((_) => const Stream.empty());
      when(repository.getItems).thenAnswer((_) async => <Reward>[]);
      when(
        () => repository.setNeedsOk(
          id: any(named: 'id'),
          needsOk: any(named: 'needsOk'),
        ),
      ).thenAnswer((_) async {});
      when(() => repository.createReward(any()))
          .thenThrow(StateError('disk full'));
      when(() => repository.updateReward(any())).thenAnswer((_) async {});
      when(() => repository.deleteReward(any())).thenAnswer((_) async {});

      final bloc = RewardsBloc(repository: repository)
        ..add(const RewardsLoadRequested());
      await _pumpViewWithFailingWrites(tester, bloc);

      await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('p14_name_field')),
        'Pizza night',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('p14_save')));
      await tester.pumpAndSettle();

      expect(
        find.text('New reward'),
        findsOneWidget,
        reason: 'plan §4: a failed write keeps the sheet open',
      );
      expect(
        find.text('Pizza night'),
        findsOneWidget,
        reason: 'plan §4: the typed name must not be lost',
      );
      expect(
        find.descendant(
          of: find.byType(RewardEditorSheet),
          matching: find.textContaining('disk full'),
        ),
        findsOneWidget,
        reason: 'plan §4: inline danger caption above Save',
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
    // P14-B03: minor — RewardEditorSheet closes on Save before the write
    // result is known; the failure surfaces on the list and the input is
    // lost. Open (plan §4 wants an inline caption above Save).
    skip: true,
  );

  testWidgets(
    '[P14-B04] deleting a reward with a pending request orphans the request',
    (tester) async {
      await setUpTestScope();
      final handle = tester.ensureSemantics();
      final database = GetIt.instance<db.AppDatabase>();
      // Exactly what K08's `requestReward` writes for a `needsOk` reward.
      await database
          .into(database.rewardRedemptions)
          .insert(
            db.RewardRedemptionsCompanion.insert(
              rewardId: 'r-cafe',
              childId: 'maya',
              familyId: 'fam1',
              status: const Value('requested'),
            ),
          );

      await pumpAppRoute(tester, '/rewards');
      // `Trip to the park café` (150 coins) is the last card — bring it on
      // screen before tapping its edit button.
      final editCafe = find.bySemanticsLabel('Edit Trip to the park cafe');
      await tester.ensureVisible(editCafe);
      await tester.pumpAndSettle();
      await tester.tap(editCafe);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_delete')));
      await tester.pumpAndSettle();

      final orphaned = await (database.select(
        database.rewardRedemptions,
      )..where((r) => r.rewardId.equals('r-cafe'))).get();
      expect(
        orphaned,
        isEmpty,
        reason:
            'P14-B04: the reward row is gone but its pending redemption '
            'remains (status ${orphaned.map((r) => r.status).toList()}); '
            'approving it is a silent no-op',
      );

      handle.dispose();
      await disposeApp(tester);
    },
    // P14-B04: minor, latent — P14's delete does not clean up (or block on)
    // the reward's redemption rows; foreign keys are off. Open.
    skip: true,
  );

  testWidgets(
    '[P14-B05] rewards are listed in creation order, not price order',
    (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/rewards');

      final cards = tester
          .widgetList<RewardCard>(find.byType(RewardCard))
          .toList();
      expect(
        cards.map((c) => c.reward.title).toList(),
        <String>[
          '30 min extra screen time',
          'Pick Friday film',
          'Stay up 15 min later',
          'Baking together',
          'Trip to the park café',
          'Choose dinner',
        ],
        reason:
            'ORCHESTRATOR_NOTES 12:27: owner rule — rewards are listed in '
            'the order they were added (seed insertion order), not by '
            'coinPrice; main ships `watchRewardsInCreationOrder`',
      );

      await disposeApp(tester);
    },
    // P14-B05: major — the repository still calls `watchRewards` (coinPrice
    // ASC) instead of `watchRewardsInCreationOrder`. Open; the shared query +
    // seed fix arrive with the next main merge.
    skip: true,
  );

  // -------------------------------------------------------------------------
  // Verified clean — attacks that were run and held.
  // -------------------------------------------------------------------------

  group('verified clean', () {
    testWidgets(
      '[P14-clean] kid mode deep link to /rewards stops at the gate',
      (tester) async {
        await setUpTestScope();
        GetIt.instance<AppModeController>().selectMode(AppMode.kid);
        final session = GetIt.instance<AppSession>();
        await session.setAppMode('kid');
        await session.refresh();

        await pumpAppRoute(tester, '/rewards');
        expect(currentPath(tester), '/parental-gate');

        await disposeApp(tester);
      },
    );

    testWidgets('[P14-clean] Back pops a pushed /rewards', (tester) async {
      await setUpTestScope();
      final handle = tester.ensureSemantics();
      await pumpAppRoute(tester, '/today');
      unawaited(
        GoRouter.of(tester.element(find.byType(Navigator).first))
            .push('/rewards'),
      );
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/rewards');

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(pushedPath(tester), '/today');

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('[P14-clean] a created reward survives an app restart', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/rewards');
      await tester.ensureVisible(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('p14_name_field')),
        'Dessert night',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('p14_save')));
      await tester.pumpAndSettle();
      expect(find.text('Dessert night'), findsOneWidget);

      await disposeApp(tester);
      // A restart = a fresh app (new bloc, new view) over the same database.
      await pumpAppRoute(tester, '/rewards');
      expect(find.text('Dessert night'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('[P14-clean] rapid double taps do not duplicate writes', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/rewards');

      // A double tap on a toggle is two flips; the second tap lands after the
      // stream has re-emitted (16 ms apart — the probe shows even a 1 ms gap
      // recovers), so the row ends ON and the DB is consistent.
      final toggle = find.byType(NestToggle).first;
      await tester.tap(toggle);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(
        (await _rows()).firstWhere((r) => r.id == 'r-screen').needsOk,
        isTrue,
      );

      // Two taps on Save in the same frame create exactly one row: the pop
      // animation ignores pointers, so the second tap cannot reach the sheet.
      await tester.ensureVisible(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('p14_name_field')),
        'Pizza night',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('p14_save')));
      await tester.tap(find.byKey(const ValueKey('p14_save')));
      await tester.pumpAndSettle();
      expect(
        (await _rows()).where((r) => r.title == 'Pizza night'),
        hasLength(1),
      );

      // Two taps on + New reward open exactly one sheet.
      await tester.ensureVisible(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
      await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      expect(find.text('New reward'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('[P14-clean] 9999 coins and a long UK name at 320 px / 1.3', (
      tester,
    ) async {
      await setUpTestScope();
      final database = GetIt.instance<db.AppDatabase>();
      await database
          .into(database.rewards)
          .insert(
            db.RewardsCompanion.insert(
              id: 'r-big',
              familyId: 'fam1',
              title: 'Maximilian-Alexander’s cinema trip',
              coinPrice: 9999,
            ),
          );
      await pumpAppRoute(tester, '/rewards');
      tester.view.physicalSize = const Size(320 * 3, 844 * 3);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('9999'), findsWidgets);
      expect(find.text('Maximilian-Alexander’s cinema trip'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets(
      '[P14-clean] every control exposes a tap action; the toggle writes the DB',
      (tester) async {
        await setUpTestScope();
        final handle = tester.ensureSemantics();
        await pumpAppRoute(tester, '/rewards');

        final toggles = find.byType(NestToggle);
        expect(toggles, findsNWidgets(6));
        for (var i = 0; i < 6; i++) {
          final data = tester.getSemantics(toggles.at(i)).getSemanticsData();
          expect(
            data.hasAction(SemanticsAction.tap),
            isTrue,
            reason: 'toggle $i ("${data.label}") must be activatable',
          );
        }

        final edits = find.semantics.byLabel(RegExp('^Edit '));
        expect(edits.evaluate(), hasLength(6));
        for (final element in edits.evaluate()) {
          expect(
            element.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
            reason: '"${element.getSemanticsData().label}" must be activatable',
          );
        }

        for (final label in <String>['Back', '+ New reward']) {
          final tappable = find.semantics
              .byLabel(label)
              .evaluate()
              .where(
                (n) => n.getSemanticsData().hasAction(SemanticsAction.tap),
              );
          expect(tappable, isNotEmpty, reason: '"$label" must be activatable');
        }

        // performAction(tap) on the first toggle flips the real DB row.
        final node = tester.getSemantics(toggles.first);
        node.owner!.performAction(node.id, SemanticsAction.tap);
        await tester.pumpAndSettle();
        expect(
          (await _rows()).firstWhere((r) => r.id == 'r-screen').needsOk,
          isFalse,
        );

        handle.dispose();
        await disposeApp(tester);
      },
    );

    testWidgets('[P14-clean] empty DB → create from the empty state', (
      tester,
    ) async {
      await setUpTestScope();
      final database = GetIt.instance<db.AppDatabase>();
      await database.delete(database.rewards).go();
      await pumpAppRoute(tester, '/rewards');
      expect(find.text('No rewards yet'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('p14_empty_new_reward')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('p14_name_field')),
        'Film night',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('p14_save')));
      await tester.pumpAndSettle();
      expect(find.text('Film night'), findsOneWidget);
      expect(find.text('No rewards yet'), findsNothing);

      await disposeApp(tester);
    });

    testWidgets(
      '[P14-clean] the toggle state comes from the DB, not the view',
      (tester) async {
        await setUpTestScope();
        final database = GetIt.instance<db.AppDatabase>();
        // ORCHESTRATOR_NOTES 12:27: Baking together's seed value is false; the
        // view must render whatever `needsOk` holds (never hard-code it).
        await (database.update(database.rewards)
              ..where((r) => r.id.equals('r-baking')))
            .write(const db.RewardsCompanion(needsOk: Value(false)));
        await pumpAppRoute(tester, '/rewards');

        final card = find.ancestor(
          of: find.text('Baking together'),
          matching: find.byType(RewardCard),
        );
        final toggle = find.descendant(
          of: card,
          matching: find.byType(NestToggle),
        );
        expect(tester.widget<NestToggle>(toggle).value, isFalse);
        expect(
          tester.widget<NestToggle>(find.byType(NestToggle).first).value,
          isTrue,
          reason: 'a different row stays ON — the state is per-row DB data',
        );

        await disposeApp(tester);
      },
    );

    testWidgets('[P14-clean] dark mode at 1.3 scale renders without overflow', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/rewards', theme: ThemeMode.dark);
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Reward shop'), findsOneWidget);

      await disposeApp(tester);
    });
  });
}
