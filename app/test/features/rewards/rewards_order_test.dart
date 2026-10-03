// P14 — the reward list ORDER, per ORCHESTRATOR_NOTES (12:27).
//
// The ruling: the list is CREATION order (the order rewards were added), not
// price order. `Seed.demo()` inserts r-screen, r-film, r-bedtime, r-baking,
// r-cafe, r-dinner — the same sequence the design HTML draws — and
// `AppDatabase.watchRewardsInCreationOrder` is the canonical query on main.
//
// Two layers, deliberately:
//
//   * GREEN — the screen renders the DATABASE order verbatim. This holds
//     whatever the query is (price today, creation order after the merge) and
//     is what the screen actually owns: it must not re-sort. It would fail if
//     the view ever added `.sort()` or reversed the list.
//   * SKIPPED — the rendered order equals `Seed.demo()`'s insertion order.
//     This is the orchestrator's mandatory behaviour and it does NOT hold
//     until the shared seed/query change lands on main. Run it with
//     `flutter test test/features/rewards/rewards_order_test.dart
//     --run-skipped`; remove the `skip` once the merge is in.

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_card.dart';

import '../../test_scope.dart';
import 'p14_test_support.dart';

void main() {
  setUpAll(loadBundledFonts);

  testWidgets('the screen renders the database order verbatim', (tester) async {
    await pumpRewardsApp(tester);

    final rendered = tester
        .widgetList<RewardCard>(find.byType(RewardCard))
        .map((card) => card.reward.id)
        .toList();

    expect(
      rendered,
      await rewardIdsInAppOrder(tester),
      reason: 'the view must not re-sort the stream',
    );
    expect(
      rendered.toSet(),
      seedInsertionOrder.toSet(),
      reason: 'the same six seeded rewards, in some order',
    );

    await disposeApp(tester);
  });

  testWidgets(
    '[P14-ORDER] the rendered list is in Seed.demo creation order',
    (tester) async {
      // ORCHESTRATOR_NOTES 12:27: creation order, not price order. Blocked on
      // main's `rewards.created_at` + `watchRewardsInCreationOrder` landing in
      // this branch (P14-B05 in 6_bugs.md). Remove this skip when it does.
      await pumpRewardsApp(tester);

      final rendered = tester
          .widgetList<RewardCard>(find.byType(RewardCard))
          .map((card) => card.reward.id)
          .toList();

      expect(
        rendered,
        seedInsertionOrder,
        reason: 'r-film(80) before r-bedtime(60): creation, not price',
      );

      await disposeApp(tester);
    },
    // Blocked on main: rewards.created_at + watchRewardsInCreationOrder
    // (ORCHESTRATOR_NOTES 12:27, P14-B05). `flutter test ... --run-skipped`.
    skip: true,
  );

  testWidgets('the toggle state of each row is its database value', (
    tester,
  ) async {
    // The opposite trap: hard-coding "every seeded toggle is ON" breaks the
    // moment the seed correction lands (Baking together is false in the
    // design). Read it from the database instead.
    await pumpRewardsApp(tester);

    final cards = tester.widgetList<RewardCard>(find.byType(RewardCard));
    final toggles = tester.widgetList<NestToggle>(find.byType(NestToggle));
    expect(cards.length, toggles.length);

    for (var i = 0; i < cards.length; i++) {
      final reward = cards.elementAt(i);
      expect(
        toggles.elementAt(i).value,
        await rewardNeedsOk(reward.reward.id),
        reason: '${reward.reward.id}: the switch mirrors needsOk',
      );
    }

    await disposeApp(tester);
  });
}
