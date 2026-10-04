// P14 · Rewards manager — adversarial bug proofs (Stage 6, iterations 1–3).
//
// Iteration 1 found B01–B05 (keyboard covers the sheet; empty/failure not
// centred; sheet write failure loses input; delete orphans redemptions; price
// order instead of creation order). Fixed by the iteration-2 build.
//
// Iteration 2 found B06–B08 (a stream error after data swallowed; the inline
// error caption not a live region; a sheet overflow when the keyboard caps
// the form). Fixed by the iteration-3 build.
//
// Iteration 3 re-hunted the rebuilt tree — keyboard matrix, notched safe
// area, sheet semantics, retry recovery, small screens — and found no new
// defect with a repro. Its new guards (matrix, notch, single a11y node,
// retry recovery) live in the `verified clean` group below.
//
// All B01–B08 proofs run unskipped and green; `flutter test
// test/features/rewards/p14_bugs_test.dart --run-skipped` is therefore the
// same green run (no skips remain). Full report: docs/screens/P14/6_bugs.md.

import 'dart:async';
import 'dart:ui' show Tristate;

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
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_meta.dart';

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

/// Emits one reward, then errors and closes — the mid-stream failure shape of
/// P14-B06. An `async*` generator is re-listenable, so `Try again` can call
/// `watchItems()` again and get a fresh subscription.
Stream<List<Reward>> _emitThenError() async* {
  yield const <Reward>[
    Reward(
      id: 'r-screen',
      title: '30 min extra screen time',
      detail: '50 coins',
      icon: 'tv',
      coinPrice: 50,
      needsOk: true,
    ),
  ];
  throw StateError('stream died');
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
  );

  testWidgets('[P14-B02] the empty state is centred in the scroll area', (
    tester,
  ) async {
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
  });

  testWidgets('[P14-B02] the failure surface is centred in the scroll area', (
    tester,
  ) async {
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

    final message = tester.getRect(find.text('Something went wrong'));
    final button = tester.getRect(find.byKey(const ValueKey('p14_try_again')));
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
  });

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
      // `Trip to the park café` (150 coins) is below the fold — bring it on
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
    // P14-B04 fixed: `deleteReward` removes the reward's redemption rows in
    // the same transaction. Live proof.
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
    // P14-B05 fixed: the repository serves `watchRewardsInCreationOrder`.
    // Live proof.
  );

  testWidgets(
    '[P14-B06] a stream error after data still offers the failure surface',
    (tester) async {
      final repository = _MockRewardsRepository();
      // A self-terminating stream (one list, then the error, then done) — the
      // shape a Drift `QueryStream` takes when its query fails. A hand-driven
      // `StreamController` left open across the error leaves the cancelled
      // subscription pending in the test's fake-async zone and the test never
      // returns; that is a harness artefact, not screen behaviour.
      when(repository.watchItems).thenAnswer((_) async* {
        yield const <Reward>[
          Reward(
            id: 'r-screen',
            title: '30 min extra screen time',
            detail: '50 coins',
            icon: 'tv',
            coinPrice: 50,
            needsOk: true,
          ),
        ];
        // Longer than the helper's settling pump, so the row is really on
        // screen before the stream dies.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        throw StateError('stream died');
      });
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

      await tester.pump();
      // Before the 200 ms the stream dies on: the row is on screen.
      await tester.pump(const Duration(milliseconds: 5));
      expect(find.text('30 min extra screen time'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.byKey(const ValueKey('p14_try_again')),
        findsOneWidget,
        reason:
            'plan §4: a failed stream must show the error surface with Try '
            'again, not a silently stale list',
      );

      // No drain needed: the repository is a mock and the stream has already
      // closed, so no Drift `QueryStream` is open (stage 4, finding 7).
    },
    // P14-B06 closed in the iteration-3 build: every `failure` renders the
    // error surface with `Try again` (writes no longer emit `failure`, so
    // this branch can only be the stream itself).
  );

  testWidgets(
    '[P14-B07] the inline write-error caption is announced to screen readers',
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

      final handle = tester.ensureSemantics();
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

      final caption = find.descendant(
        of: find.byType(RewardEditorSheet),
        matching: find.textContaining('disk full'),
      );
      expect(caption, findsOneWidget);
      final data = tester.getSemantics(caption).getSemanticsData();
      expect(
        data.flagsCollection.isLiveRegion,
        isTrue,
        reason:
            'the failure must be announced (NestTextField error-row '
            'precedent: Semantics(liveRegion: true, label: errorText))',
      );

      handle.dispose();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
    // P14-B07 closed in the iteration-3 build: the caption is a
    // `Semantics(liveRegion: true, label: …, child: ExcludeSemantics(…))`,
    // the `NestTextField` error-row pattern.
  );

  testWidgets(
    '[P14-B08] the sheet must not overflow when the keyboard caps the form',
    (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/rewards');
      // 390×844 at 1.3 text scale with a full iOS keyboard (336 px incl. the
      // predictive row) caps the form and exposes the chrome undercount.
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_name_field')));
      await tester.pump();
      tester.view.viewInsets = const FakeViewPadding(bottom: 336 * 3);
      addTearDown(tester.view.resetViewInsets);
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason:
            'the sheet chrome reservation must include the 44 px close '
            'button and text-scale growth, or the NestBottomSheet Column '
            'overflows when the keyboard caps the form',
      );
      final save = tester.getRect(find.byKey(const ValueKey('p14_save')));
      expect(save.bottom, lessThanOrEqualTo(844 - 336));

      await disposeApp(tester);
    },
    // P14-B08 closed in the iteration-3 build: the form no longer re-derives
    // the sheet's chrome at all — a loose `Flexible` is handed exactly what
    // the grabber and title row left over.
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
        // Shared batch 5: `NestToggle` lays out at 51×31 with the tap target
        // as hit slop (like `NestChip`), so the widget lookup no longer
        // resolves to the semantics node — address the labelled nodes
        // directly (the `NestChip` pattern).
        final toggleNodes = find.semantics.byLabel(RegExp('^Needs approval'));
        expect(toggleNodes.evaluate(), hasLength(6));
        for (final element in toggleNodes.evaluate()) {
          expect(
            element.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
            reason:
                'toggle ("${element.getSemanticsData().label}") must be activatable',
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
        // (Addressed by label — see above — since the widget lookup no
        // longer resolves to the semantics node after shared batch 5.)
        final toggleFinder = find.semantics.byLabel(RegExp('^Needs approval'));
        tester.semantics.performAction(toggleFinder.first, SemanticsAction.tap);
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
        await pumpAppRoute(tester, '/rewards');

        NestToggle bakingToggle() => tester.widget<NestToggle>(
          find.descendant(
            of: find.ancestor(
              of: find.text('Baking together'),
              matching: find.byType(RewardCard),
            ),
            matching: find.byType(NestToggle),
          ),
        );

        // ORCHESTRATOR_NOTES 12:27 / shared/rewards_seed_order: the seeded
        // Baking row is OFF, exactly as the design draws it.
        expect(bakingToggle().value, isFalse);
        expect(
          tester.widget<NestToggle>(find.byType(NestToggle).first).value,
          isTrue,
          reason: 'a different row stays ON — the state is per-row DB data',
        );

        // Flip it in the DB; the view follows (nothing is hard-coded).
        await (database.update(database.rewards)
              ..where((r) => r.id.equals('r-baking')))
            .write(const db.RewardsCompanion(needsOk: Value(true)));
        await tester.pumpAndSettle();
        expect(bakingToggle().value, isTrue);

        await disposeApp(tester);
      },
    );

    testWidgets('[P14-clean] a failed toggle shows the toast and snaps back', (
      tester,
    ) async {
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
      ).thenThrow(StateError('nope'));
      when(() => repository.createReward(any())).thenAnswer((_) async {});
      when(() => repository.updateReward(any())).thenAnswer((_) async {});
      when(() => repository.deleteReward(any())).thenAnswer((_) async {});

      final bloc = RewardsBloc(repository: repository)
        ..add(const RewardsLoadRequested());
      await _pumpViewWithFailingWrites(tester, bloc);

      await tester.tap(find.byType(NestToggle).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(RewardCopy.actionFailed), findsOneWidget);
      expect(
        tester.widget<NestToggle>(find.byType(NestToggle).first).value,
        isTrue,
        reason: 'the switch keeps the DB value — it never lies about a write',
      );
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('[P14-clean] a failed save keeps the input and a retry works', (
      tester,
    ) async {
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
      var fail = true;
      when(() => repository.createReward(any())).thenAnswer((_) async {
        if (fail) throw StateError('disk full');
      });
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
      expect(find.text('New reward'), findsOneWidget);
      expect(find.text('Pizza night'), findsOneWidget);

      fail = false;
      await tester.tap(find.byKey(const ValueKey('p14_save')));
      await tester.pumpAndSettle();
      expect(find.text('New reward'), findsNothing);
      verify(() => repository.createReward(any())).called(2);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('[P14-clean] Save is guarded while a write is in flight', (
      tester,
    ) async {
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
      final gate = Completer<void>();
      when(() => repository.createReward(any())).thenAnswer((_) => gate.future);
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
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('p14_save')),
        warnIfMissed: false,
      );
      await tester.pump();
      verify(() => repository.createReward(any())).called(1);

      gate.complete();
      await tester.pumpAndSettle();
      expect(find.text('New reward'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('[P14-clean] deleting removes only that reward’s redemptions', (
      tester,
    ) async {
      await setUpTestScope();
      final database = GetIt.instance<db.AppDatabase>();
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
      await database
          .into(database.rewardRedemptions)
          .insert(
            db.RewardRedemptionsCompanion.insert(
              rewardId: 'r-baking',
              childId: 'leo',
              familyId: 'fam1',
              status: const Value('requested'),
            ),
          );

      await pumpAppRoute(tester, '/rewards');
      final cafeEdit = find.bySemanticsLabel('Edit Trip to the park cafe');
      await tester.ensureVisible(cafeEdit);
      await tester.pumpAndSettle();
      await tester.tap(cafeEdit);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_delete')));
      await tester.pumpAndSettle();

      final left = await database.select(database.rewardRedemptions).get();
      expect(left.map((r) => '${r.rewardId}:${r.status}').toList(), <String>[
        'r-baking:requested',
      ], reason: 'the cascade must not touch another reward’s requests');

      await disposeApp(tester);
    });

    testWidgets(
      '[P14-clean] editing keeps position and a new reward lands last',
      (tester) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/rewards');

        List<String> titles() => tester
            .widgetList<RewardCard>(find.byType(RewardCard))
            .map((c) => c.reward.title)
            .toList();

        // Edit the 4th reward; creation order must not change.
        final bakingEdit = find.bySemanticsLabel('Edit Baking together');
        await tester.ensureVisible(bakingEdit);
        await tester.pumpAndSettle();
        await tester.tap(bakingEdit);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('p14_name_field')),
          'Baking with Leo',
        );
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('p14_save')));
        await tester.pumpAndSettle();
        expect(titles()[3], 'Baking with Leo');

        // Create one; it is the newest, so it lands last.
        await tester.ensureVisible(
          find.byKey(const ValueKey('p14_new_reward')),
        );
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
        expect(titles().last, 'Dessert night');
        expect(titles(), hasLength(7));

        await disposeApp(tester);
      },
    );

    testWidgets(
      '[P14-clean] the sheet does not overflow on a small screen with the keyboard',
      (tester) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/rewards');
        tester.view.physicalSize = const Size(320 * 3, 568 * 3);
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const ValueKey('p14_new_reward')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('p14_name_field')));
        await tester.pump();
        tester.view.viewInsets = const FakeViewPadding(bottom: 260 * 3);
        addTearDown(tester.view.resetViewInsets);
        await tester.pump();

        expect(tester.takeException(), isNull);
        // The capped form scrolls; Save is reachable above the keyboard.
        await tester.dragFrom(const Offset(160, 120), const Offset(0, -200));
        await tester.pumpAndSettle();
        final save = tester.getRect(find.byKey(const ValueKey('p14_save')));
        expect(save.bottom, lessThanOrEqualTo(568 - 260));

        await disposeApp(tester);
      },
    );

    testWidgets(
      '[P14-clean] the sheet title clears a notched status bar with the keyboard up',
      (tester) async {
        await setUpTestScope();
        await pumpAppRoute(tester, '/rewards');
        // A notched device reports a 47 px top safe area; `useSafeArea: true`
        // must keep the sheet (and its title) below it even when the sheet is
        // as tall as the screen.
        tester.view.padding = const FakeViewPadding(top: 47 * 3);
        addTearDown(tester.view.reset);
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle();

        await tester.ensureVisible(
          find.byKey(const ValueKey('p14_new_reward')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('p14_name_field')));
        await tester.pump();
        tester.view.viewInsets = const FakeViewPadding(bottom: 336 * 3);
        addTearDown(tester.view.resetViewInsets);
        await tester.pump();

        final sheet = tester.getRect(find.byType(NestBottomSheet));
        final title = tester.getRect(find.text('New reward'));
        expect(sheet.top, greaterThanOrEqualTo(47));
        expect(title.top, greaterThanOrEqualTo(47));
        expect(tester.takeException(), isNull);

        await disposeApp(tester);
      },
    );

    testWidgets(
      '[P14-clean] the sheet announces one Needs my OK node with tap + toggled',
      (tester) async {
        await setUpTestScope();
        final handle = tester.ensureSemantics();
        await pumpAppRoute(tester, '/rewards');
        await tester.ensureVisible(
          find.byKey(const ValueKey('p14_new_reward')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
        await tester.pumpAndSettle();

        final nodes = find.semantics
            .byLabel('Needs my OK')
            .evaluate()
            .map((e) => e.getSemanticsData())
            .toList();
        expect(nodes, hasLength(1), reason: 'one announcement, not two');
        expect(nodes.single.hasAction(SemanticsAction.tap), isTrue);
        expect(nodes.single.flagsCollection.isToggled, Tristate.isTrue);

        final toggle = find.descendant(
          of: find.byType(RewardEditorSheet),
          matching: find.byType(NestToggle),
        );
        final before = tester.widget<NestToggle>(toggle).value;
        // Shared batch 5: address by label (see above).
        tester.semantics.performAction(
          find.semantics.byLabel('Needs my OK'),
          SemanticsAction.tap,
        );
        await tester.pumpAndSettle();
        expect(tester.widget<NestToggle>(toggle).value, !before);

        handle.dispose();
        await disposeApp(tester);
      },
    );

    testWidgets(
      '[P14-clean] Try again after a mid-stream error recovers with one subscription',
      (tester) async {
        final repository = _MockRewardsRepository();
        var attempt = 0;
        when(repository.watchItems).thenAnswer((_) {
          attempt++;
          return attempt == 1
              ? _emitThenError()
              : Stream.value(const <Reward>[
                  Reward(
                    id: 'r-screen',
                    title: '30 min extra screen time',
                    detail: '50 coins',
                    icon: 'tv',
                    coinPrice: 50,
                    needsOk: true,
                  ),
                ]);
        });
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
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byKey(const ValueKey('p14_try_again')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('p14_try_again')));
        await tester.pumpAndSettle();
        expect(find.text('30 min extra screen time'), findsOneWidget);
        verify(repository.watchItems).called(2);

        await tester.pumpWidget(const SizedBox());
        await tester.pump();
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
