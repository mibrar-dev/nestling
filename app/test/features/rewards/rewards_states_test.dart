// P14 Rewards manager — states (loading / empty / failure) and the token + copy
// contract for the loaded screen.
//
// DATA OVER MOCKS: the six rows, their order (50/60/80/90/100/150, price ASC)
// and their `needsOk` values all come from `Seed.demo()` through Drift. Only
// the loading and failure states need a stubbed stream — with a real database
// the first frame is already `loaded`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart';
import 'package:nestling/features/rewards/domain/rewards_repository.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_bloc.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_event.dart';
import 'package:nestling/features/rewards/presentation/views/rewards_view.dart';
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_card.dart';

import '../../test_scope.dart';
import 'p14_test_support.dart';

class _StubRewardsRepository extends Mock implements RewardsRepository;

NestTokens tokensFor(ThemeMode theme) =>
    (theme == ThemeMode.dark ? NestTheme.dark() : NestTheme.light())
        .extension<NestTokens>()!;

/// Pumps just the view around a hand-driven bloc (for the states a real
/// database cannot reach).
Future<void> pumpViewWithBloc(
  WidgetTester tester,
  RewardsBloc bloc, {
  ThemeMode theme = ThemeMode.light,
  double width = 390,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
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
  // Bounded pumps: an indeterminate spinner parks the frame scheduler, so
  // `pumpAndSettle` would hang in the loading state.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUpAll(() {
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
  setUpAll(loadBundledFonts);

  group('P14 loading state', () {
    testWidgets('initial and loading both show the tinted spinner', (
      tester,
    ) async {
      final repository = _StubRewardsRepository();
      // Never emits: the screen must stay in `loading`, which is the state a
      // cold start shows before Drift answers.
      final completer = Completer<List<Reward>>();
      when(repository.watchItems)
          .thenAnswer((_) => completer.future.asStream());

      final bloc = RewardsBloc(repository: repository);
      // No load event yet: `initial`.
      await pumpViewWithBloc(tester, bloc);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(RewardCard), findsNothing);
      expect(
        tester
            .widget<CircularProgressIndicator>(
              find.byType(CircularProgressIndicator),
            )
            .color,
        tokensFor(ThemeMode.light).leaf,
        reason: 'the spinner is tinted with the leaf token',
      );

      // `loading` looks the same.
      bloc.add(const RewardsLoadRequested());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(<Reward>[]);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No rewards yet'), findsOneWidget);
    });
  });

  group('P14 failure state', () {
    testWidgets('shows the error message and Try again re-subscribes', (
      tester,
    ) async {
      final repository = _StubRewardsRepository();
      var attempt = 0;
      when(repository.watchItems).thenAnswer((_) {
        attempt++;
        return attempt == 1
            ? Stream<List<Reward>>.error(StateError('boom'))
            : Stream<List<Reward>>.value(const <Reward>[]);
      });

      final bloc = RewardsBloc(repository: repository)
        ..add(const RewardsLoadRequested());
      await pumpViewWithBloc(tester, bloc);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Static copy only — the raw `Bad state: boom` exception never reaches
      // user-facing text (stage 4, finding 2; `paywall_view.dart` precedent).
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.textContaining('boom'), findsNothing);
      expect(find.byKey(const ValueKey('p14_try_again')), findsOneWidget);
      expect(find.byType(RewardCard), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('p14_try_again')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('No rewards yet'), findsOneWidget);
      expect(attempt, 2, reason: 'Try again resubscribes to watchItems');
    });
  });

  group('P14 empty state', () {
    testWidgets('Seed.empty renders the copy and creates a first reward', (
      tester,
    ) async {
      await pumpRewardsApp(tester, seedDemo: false, prepare: Seed.empty);

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
      await tester.enterText(
        find.byKey(const ValueKey('p14_name_field')),
        'Ice cream trip',
      );
      // A blank sheet starts with Save disabled; typing enables it on the next
      // frame, so pump before tapping.
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_save')));
      await tester.pumpAndSettle();

      // The stream re-emits: the empty state gives way to the new card. Await
      // the write first, then a frame for the rebuild.
      final created = await rewardRows();
      expect(created.single.title, 'Ice cream trip');
      expect(created.single.coinPrice, 50);
      expect(created.single.needsOk, isTrue);
      await tester.pumpAndSettle();
      expect(find.text('No rewards yet'), findsNothing);
      expect(find.byType(RewardCard), findsOneWidget);
      expect(find.text('Ice cream trip'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('deleting the last reward returns to the empty state', (
      tester,
    ) async {
      await pumpRewardsApp(
        tester,
        prepare: (database) => database.delete(database.rewards).go(),
      );
      expect(find.text('No rewards yet'), findsOneWidget);

      // Create one, then delete it again through the editor.
      await tester.tap(find.byKey(const ValueKey('p14_empty_new_reward')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('p14_name_field')),
        'One off reward',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_save')));
      await tester.pumpAndSettle();
      expect(await rewardRows(), hasLength(1));
      await tester.pumpAndSettle();
      expect(find.byType(RewardCard), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Edit One off reward'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('p14_delete')));
      await tester.pumpAndSettle();

      expect(await rewardRows(), isEmpty);
      await tester.pumpAndSettle();
      expect(find.byType(RewardCard), findsNothing);
      expect(find.text('No rewards yet'), findsOneWidget);

      await disposeApp(tester);
    });
  });

  group('P14 copy and tokens', () {
    testWidgets('the loaded screen copies the HTML character for character', (
      tester,
    ) async {
      await pumpRewardsApp(tester);

      expect(find.text('Reward shop'), findsOneWidget);
      expect(
        find.text(
          'Things coins can buy — you decide. Children spend coins, never pounds.',
        ),
        findsOneWidget,
      );
      // ASCII plus, not U+FF0B.
      expect(find.text('+ New reward'), findsOneWidget);
      expect(find.text('Needs my OK'), findsNWidgets(6));
      // `é` in the visible title; ASCII "cafe" in the shortened aria-label.
      expect(find.text('Trip to the park café'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Edit Trip to the park cafe'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Edit Stay up later'), findsOneWidget);
      // The DB-only sixth row the HTML does not draw.
      expect(find.text('Choose dinner'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('the intro keeps its em dash through a rebuild', (
      tester,
    ) async {
      await pumpRewardsApp(tester);
      final intro = tester.widget<Text>(
        find.text(
          'Things coins can buy — you decide. Children spend coins, never pounds.',
        ),
      );
      expect(
        intro.data!.contains('—'),
        isTrue,
        reason: 'em dash U+2014, not a hyphen',
      );
      expect(intro.style!.fontSize, 15);
      expect(intro.style!.height, 22 / 15);
      expect(intro.maxLines, 4);

      await disposeApp(tester);
    });

    testWidgets('light and dark both paint the token surfaces', (tester) async {
      for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
        await pumpRewardsApp(tester, theme: theme);
        final tokens = tokensFor(theme);
        final card = find.byType(RewardCard).first;

        // `.coin-pill` fill.
        final pill = tester.widget<Container>(
          find
              .descendant(
                of: find.descendant(
                  of: card,
                  matching: find.byType(NestCoinPill),
                ),
                matching: find.byType(Container),
              )
              .first,
        );
        expect(
          (pill.decoration! as BoxDecoration).color,
          tokens.coinTint,
          reason: 'coin pill fill in $theme',
        );

        // Switch track: ON is `leaf`, OFF is `track` — read from the row's own
        // `needsOk`, never from a constant (ORCHESTRATOR_NOTES 12:27).
        final firstCard = tester.widget<RewardCard>(
          find.byType(RewardCard).first,
        );
        final toggle = find.byType(NestToggle).first;
        Color trackColour() {
          final decoration = tester
              .widget<AnimatedContainer>(
                find.descendant(
                  of: toggle,
                  matching: find.byType(AnimatedContainer),
                ),
              )
              .decoration;
          return (decoration! as BoxDecoration).color!;
        }

        final seeded = await rewardNeedsOk(firstCard.reward.id);
        expect(
          trackColour(),
          seeded ? tokens.leaf : tokens.track,
          reason: 'the track follows ${firstCard.reward.id}.needsOk in $theme',
        );

        await tester.tap(toggle);
        await tester.pumpAndSettle();
        expect(
          trackColour(),
          seeded ? tokens.track : tokens.leaf,
          reason: 'flipped in $theme',
        );

        // The edit button is `surface` with a 1 px `line` border in both
        // themes — never `paper`, which would vanish into the page.
        final ink = tester.widget<Ink>(find.byType(Ink).last);
        final box = ink.decoration! as BoxDecoration;
        expect(
          (box.border! as Border).top.color,
          tokens.line,
          reason: '$theme',
        );
        expect(
          tester.widget<Material>(find.byType(Material).last).color,
          tokens.surface,
          reason: 'edit button fill in $theme',
        );

        await disposeApp(tester);
      }
    });
  });
}
