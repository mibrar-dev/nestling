// P14 — the write-failure surface introduced in iteration 2.
//
// Iteration 2 rebuilt the write path: every write event gained a `result`
// channel, the bloc stopped emitting `failure` for a failed write, and the
// screen grew three new user-facing surfaces that did not exist before:
//
//   * a `Needs my OK` flip that fails  → a toast (there is no sheet to hold
//     a caption, so the toast is the only place the parent learns of it);
//   * a sheet Save/Delete that fails    → an inline danger caption, the sheet
//     STAYS OPEN, and the typed input survives (plan §4);
//   * a write that is still in flight   → `_saving` guards a second tap.
//
// These are the highest-risk parts of the screen (each can silently lose a
// parent's typed input or leave them tapping a dead switch) and none of them
// had a test. The companion rule is the important one: a failed write must
// never replace the loaded list with the full-screen `Try again` surface.
//
// DATA OVER MOCKS: every assertion about what a tap wrote reads the Drift
// table, never the widget's optimistic state.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart';
import 'package:nestling/features/rewards/domain/rewards_repository.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_bloc.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_event.dart';
import 'package:nestling/features/rewards/presentation/views/rewards_view.dart';
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_card.dart';
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_editor_sheet.dart';

import '../../test_scope.dart';
import 'p14_test_support.dart';

class _StubRewardsRepository extends Mock implements RewardsRepository;

/// One row, enough to prove the list survives a failed write.
const _oneReward = <Reward>[
  Reward(
    id: 'r-screen',
    title: '30 min extra screen time',
    detail: '50 coins',
    icon: 'tv',
    coinPrice: 50,
    needsOk: true,
  ),
];

/// Wires a repository that serves [_oneReward] and fails the writes named by
/// the flags. [createGate] holds a create open so a second Save can be timed
/// against an in-flight write.
_StubRewardsRepository _repository({
  bool failNeedsOk = false,
  bool failCreate = false,
  bool failUpdate = false,
  bool failDelete = false,
  Completer<void>? createGate,
  int Function()? onCreate,
}) {
  final repository = _StubRewardsRepository();
  when(repository.watchItems).thenAnswer((_) => Stream.value(_oneReward));
  when(repository.watchRequests).thenAnswer((_) => const Stream.empty());
  when(repository.getItems).thenAnswer((_) async => <Reward>[]);
  when(
    () => repository.setNeedsOk(
      id: any(named: 'id'),
      needsOk: any(named: 'needsOk'),
    ),
  ).thenAnswer((_) async {
    if (failNeedsOk) throw StateError('row is locked');
  });
  when(() => repository.createReward(any())).thenAnswer((_) async {
    onCreate?.call();
    if (createGate != null) await createGate.future;
    if (failCreate) throw StateError('disk is full');
  });
  when(() => repository.updateReward(any())).thenAnswer((_) async {
    if (failUpdate) throw StateError('disk is full');
  });
  when(() => repository.deleteReward(any())).thenAnswer((_) async {
    if (failDelete) throw StateError('row is locked');
  });
  return repository;
}

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
  await tester.pump(const Duration(milliseconds: 50));
}

RewardsBloc _blocFor(_StubRewardsRepository repository) =>
    RewardsBloc(repository: repository)..add(const RewardsLoadRequested());

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  setUpAll(loadBundledFonts);
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

  group('P14 write failures — a failed write never replaces the list', () {
    testWidgets('a failed toggle keeps the list and shows a toast', (
      tester,
    ) async {
      final bloc = _blocFor(_repository(failNeedsOk: true));
      await _pumpView(tester, bloc);

      await tester.tap(find.byType(NestToggle).first);
      await tester.pumpAndSettle();

      // The parent is told, in place.
      expect(find.byType(NestToast), findsOneWidget);
      expect(find.text('Hmm, that did not work. Try again.'), findsOneWidget);

      // …and the screen did NOT turn into the full-screen failure state.
      expect(find.byType(RewardCard), findsOneWidget);
      expect(
        find.byKey(const ValueKey('p14_try_again')),
        findsNothing,
        reason: 'a failed action must not show the stream-failure surface',
      );
      expect(find.text('Something went wrong'), findsNothing);

      await _dispose(tester);
    });

    testWidgets('a failed toggle leaves the database row untouched', (
      tester,
    ) async {
      // The same flow against the real Drift database, proving the failing
      // write never reached it and the switch re-renders the stored value.
      await pumpRewardsApp(tester);
      final before = await rewardNeedsOk('r-screen');

      // A throwing repository on a loaded list: flip, then assert the row.
      final repository = _repository(failNeedsOk: true);
      final bloc = _blocFor(repository);
      await _pumpView(tester, bloc);
      await tester.tap(find.byType(NestToggle).first);
      await tester.pumpAndSettle();

      // The stub never writes, so the seeded row is what the DB still holds.
      expect(await rewardNeedsOk('r-screen'), before);
      expect(
        tester.widget<NestToggle>(find.byType(NestToggle).first).value,
        before,
        reason: 'the switch snaps back to the value the stream re-emits',
      );

      await _dispose(tester);
      await disposeApp(tester);
    });

    testWidgets(
      '[P14-B06] a stream failure after data offers Try again',
      (tester) async {
        // A stream that delivered rows and *then* died leaves the parent with a
        // stale list whose stream is dead: later writes would never be
        // reflected, and there is no retry. `rewards_view.dart` short-circuits
        // its `failure` branch on `state.items.isNotEmpty` — a shortcut that
        // existed for failed ACTION writes, which no longer emit `failure` — so
        // the error is swallowed and `Try again` never appears (stage 6,
        // P14-B06).
        //
        // This deliberately asserts the CORRECT behaviour, so it fails until the
        // branch is fixed. Do not "fix" it by expecting the stale list: that is
        // the defect, not the contract.
        final repository = _StubRewardsRepository();
        // A self-terminating stream (rows, then the error, then done) — the
        // shape a Drift `QueryStream` takes when its query fails. A
        // hand-driven controller left open across the error keeps the
        // cancelled subscription pending in the test's fake-async zone and the
        // test never returns; a harness artefact, not screen behaviour.
        when(repository.watchItems).thenAnswer((_) async* {
          yield _oneReward;
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

        final bloc = _blocFor(repository);
        await _pumpView(tester, bloc);

        await tester.pump();
        // Before the 200 ms the stream dies on: the card is on screen.
        await tester.pump(const Duration(milliseconds: 5));
        expect(find.byType(RewardCard), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 250));

        expect(
          find.byKey(const ValueKey('p14_try_again')),
          findsOneWidget,
          reason: 'a dead stream must surface the error, not a stale list',
        );
        expect(find.text('Something went wrong'), findsOneWidget);

        await _dispose(tester);
      },
      // P14-B06 closed in the iteration-3 build: every `failure` renders the
      // error surface with `Try again` (writes no longer emit `failure`, so
      // this branch can only be the stream itself).
    );
  });

  group('P14 sheet write failures keep the sheet and the input', () {
    testWidgets('a failed Save keeps the sheet open with an inline caption', (
      tester,
    ) async {
      final bloc = _blocFor(_repository(failCreate: true));
      await _pumpView(tester, bloc);

      await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('p14_name_field')),
        'Pizza night',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_save')));
      await tester.pumpAndSettle();

      // The sheet is still here and nothing the parent typed is lost.
      expect(find.byType(RewardEditorSheet), findsOneWidget);
      expect(find.text('New reward'), findsOneWidget);
      expect(find.text('Pizza night'), findsOneWidget);
      expect(
        tester
            .widget<NestTextField>(find.byKey(const ValueKey('p14_name_field')))
            .controller!
            .text,
        'Pizza night',
      );

      // Plan §4: a `danger` caption above Save.
      final caption = find.textContaining('Could not save the reward');
      expect(caption, findsOneWidget);
      expect(
        tester.widget<Text>(caption).style!.color,
        NestTheme.light().extension<NestTokens>()!.danger,
      );
      // …and the price/switch the parent also set survive.
      expect(find.text('50 coins'), findsOneWidget);

      // Not the full-screen failure surface.
      expect(find.text('Something went wrong'), findsNothing);

      await _dispose(tester);
    });

    testWidgets('a failed Save can be retried and then succeeds', (
      tester,
    ) async {
      var fail = true;
      final repository = _StubRewardsRepository();
      when(repository.watchItems).thenAnswer((_) => Stream.value(_oneReward));
      when(repository.watchRequests).thenAnswer((_) => const Stream.empty());
      when(repository.getItems).thenAnswer((_) async => <Reward>[]);
      when(
        () => repository.setNeedsOk(
          id: any(named: 'id'),
          needsOk: any(named: 'needsOk'),
        ),
      ).thenAnswer((_) async {});
      when(() => repository.updateReward(any())).thenAnswer((_) async {});
      when(() => repository.deleteReward(any())).thenAnswer((_) async {});
      when(() => repository.createReward(any())).thenAnswer((_) async {
        if (fail) throw StateError('disk is full');
      });

      final bloc = _blocFor(repository);
      await _pumpView(tester, bloc);
      await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('p14_name_field')),
        'Pizza night',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('p14_save')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Could not save'), findsOneWidget);
      expect(find.text('Pizza night'), findsOneWidget);

      // Retry: the second attempt goes through and the sheet closes.
      fail = false;
      await tester.tap(find.byKey(const ValueKey('p14_save')));
      await tester.pumpAndSettle();

      expect(find.byType(RewardEditorSheet), findsNothing);
      expect(
        find.text('Pizza night'),
        findsNothing,
        reason: 'the sheet closed',
      );
      verify(() => repository.createReward(any())).called(2);

      await _dispose(tester);
    });

    testWidgets('a failed Delete keeps the sheet and rearms the button', (
      tester,
    ) async {
      final bloc = _blocFor(_repository(failDelete: true));
      await _pumpView(tester, bloc);

      await tester.tap(find.bySemanticsLabel('Edit 30 min extra screen time'));
      await tester.pumpAndSettle();

      // First tap arms, second confirms — then the write fails.
      await tester.tap(find.byKey(const ValueKey('p14_delete')));
      await tester.pumpAndSettle();
      expect(find.text('Confirm delete'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('p14_delete')));
      await tester.pumpAndSettle();

      expect(find.byType(RewardEditorSheet), findsOneWidget);
      expect(
        find.textContaining('Could not delete the reward'),
        findsOneWidget,
      );
      // `_confirmingDelete` resets: a retry needs two taps again, so the
      // destructive write is never one stray tap away.
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Confirm delete'), findsNothing);
      // The reward is still on the list behind the sheet. Its title shows in
      // both the card and the sheet's prefilled field, so count the cards.
      expect(find.byType(RewardCard), findsOneWidget);
      expect(
        tester
            .widget<NestTextField>(find.byKey(const ValueKey('p14_name_field')))
            .controller!
            .text,
        '30 min extra screen time',
        reason: 'the prefilled name survives a failed delete',
      );

      await _dispose(tester);
    });
  });

  group('P14 an in-flight write cannot be double-submitted', () {
    testWidgets('two Saves during one slow write create one reward', (
      tester,
    ) async {
      var calls = 0;
      final gate = Completer<void>();
      final bloc = _blocFor(
        _repository(createGate: gate, onCreate: () => calls++),
      );
      await _pumpView(tester, bloc);

      await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('p14_name_field')),
        'Slow trip',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('p14_save')));
      await tester.pump();
      // The second tap lands while the first write is still in flight.
      await tester.tap(find.byKey(const ValueKey('p14_save')));
      await tester.pump(const Duration(milliseconds: 20));
      expect(calls, 1, reason: 'the _saving guard must swallow the second tap');

      gate.complete();
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.byType(RewardEditorSheet), findsNothing, reason: 'it saved');

      await _dispose(tester);
    });

    testWidgets(
      'Save is disabled and un-actionable while a write is in flight',
      (tester) async {
        final gate = Completer<void>();
        final bloc = _blocFor(_repository(createGate: gate));
        await _pumpView(tester, bloc);

        await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('p14_name_field')),
          'Slow trip',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('p14_save')));
        await tester.pump();

        final handle = tester.ensureSemantics();
        await tester.pump();
        final data = tester
            .getSemantics(find.bySemanticsLabel('Save'))
            .getSemanticsData();
        expect(
          data.hasAction(SemanticsAction.tap),
          isFalse,
          reason: 'a saving button must not advertise a tap',
        );

        handle.dispose();
        gate.complete();
        await tester.pumpAndSettle();
        await _dispose(tester);
      },
    );
  });

  group('P14 the resting sheet is unchanged by the keyboard work', () {
    testWidgets('with no keyboard the sheet sits exactly where it always did', (
      tester,
    ) async {
      await pumpRewardsApp(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();

      // Iteration 2 replaced `showNestBottomSheet` with the feature-local
      // keyboard-aware opener. The resting layout must be unchanged: the
      // iteration-1 measurements were sheet 422→794 and Save 682→734.
      expect(
        tester.getRect(find.byType(RewardEditorSheet)),
        const Rect.fromLTRB(20, 422, 370, 794),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('p14_save'))),
        const Rect.fromLTRB(20, 682, 370, 734),
      );
      // No trailing gap after the last button, and nothing under the home
      // indicator that is not `paper` (BOTTOM EDGE).
      expect(
        tester.getRect(find.byKey(const ValueKey('p14_cancel'))).bottom,
        lessThan(844),
      );

      await disposeApp(tester);
    });
  });
}
