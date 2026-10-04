// K08 · Reward shop — bug proofs (iteration 1 + iteration 2).
//
// The iteration-1 proofs for K08-BUG-1 … -3 are kept here and now run GREEN:
// iteration 2 fixed all three (atomic payment precondition in `requestReward`,
// `SizedBox.shrink()` for the odd grid filler, `Semantics(label: 'N coins')`
// on the card price). The `6_bugs.md` iteration-2 report records the fixes.
//
// K08-BUG-4 is the one OPEN bug, and its proof runs UNSKIPPED: the loop
// forbids leaving `skip:` markers behind, so the defect stays visible in
// `flutter test` (and in the whole-app run) until a builder fixes it.
//
//   K08-BUG-1  major  FIXED — an `approved` redemption could be written
//                     without payment (two affordable cards tapped in one
//                     frame both landed `approved`, only the first deducted).
//   K08-BUG-2  major  FIXED — an ODD number of rewards crashed the grid with
//                     "Incorrect use of ParentDataWidget" (a `Spacer` — itself
//                     an `Expanded` — placed inside another `Expanded`).
//   K08-BUG-3  minor  FIXED — the card price was announced as a bare number
//                     ("50") with no unit, while every coin pill says
//                     "N coins".
//   K08-BUG-4  minor  OPEN — when K08-BUG-1's payment guard leaves a raced
//                     instant reward `requested`, the toast still says
//                     "It’s yours — enjoy!". The row and the coins are right;
//                     the child-facing copy is not.
//
// Root causes, for the record:
//   K08-BUG-1  app/lib/features/kid_shop/data/kid_shop_repository_impl.dart
//              `requestReward` / `_spendCoins` — the `approved` row was written
//              before the balance check, and `_spendCoins` silently returned
//              when the balance was short.
//   K08-BUG-2  app/lib/features/kid_shop/presentation/views/reward_shop_view.dart
//              `_ShopGrid`, the odd-row filler `const Spacer()`.
//   K08-BUG-3  app/lib/features/kid_shop/presentation/widgets/shop_reward_card.dart
//              `_ShopPrice` — the coin `SvgPicture` was excluded but the number
//              `Text` carried no label.
//   K08-BUG-4  the repository writes the real status, but `requestReward`
//              returns `Future<void>`, so the bloc toasts from the captured
//              `needsOk` flag and cannot know about the fallback.
//
// NOT a bug (checked and cleared in stage 3, iteration 1): the
// `requestingIds` double-tap guard on the SAME card. `KidShopBloc
// ._onRewardRequested` reads the set from the emitted state, so it holds while
// the write is genuinely in flight — and a real `requestReward` is a Drift
// transaction, so the second tap of a same-frame double tap is dropped. A fake
// repository that completes in a single microtask does let a second write
// through; that is a property of the fake, not of the screen.
// `reward_shop_view_test.dart` proves the real path ("a fast double tap writes
// one redemption"), and `kid_shop_bloc_test.dart` proves it at bloc level with
// a genuinely async fake.
//
// Run directly:
//   flutter test --timeout 120s test/features/kid_shop/k08_bugs_test.dart

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_shop/data/kid_shop_repository_impl.dart';
import 'package:nestling/features/kid_shop/presentation/widgets/shop_reward_card.dart';

import '../../test_scope.dart';

const String _route = '/reward-shop';

/// Removes every reward whose id is not in [keep], so a test can build the odd
/// card counts a real family reaches by adding and deleting rewards. The demo
/// seed's six is exactly what hides K08-BUG-2 from the design screenshots and
/// the UI check.
Future<void> keepOnlyRewards(AppDatabase db, Set<String> keep) {
  return (db.delete(
    db.rewards,
  )..where((r) => r.id.isNotIn(keep.toList()))).go();
}

/// The money-integrity invariant the whole shop rests on: what the child paid
/// in coins equals the value of the redemptions a grown-up already approved.
Future<int> approvedValue(AppDatabase db) async {
  final approved = await (db.select(
    db.rewardRedemptions,
  )..where((r) => r.status.equals('approved'))).get();
  var total = 0;
  for (final row in approved) {
    final reward = await (db.select(
      db.rewards,
    )..where((r) => r.id.equals(row.rewardId))).getSingle();
    total += reward.coinPrice;
  }
  return total;
}

Future<int> coinsOf(AppDatabase db, String childId) async {
  final kid = await (db.select(
    db.children,
  )..where((c) => c.id.equals(childId))).getSingle();
  return kid.coins;
}

/// Makes [rewardId] instant (no parental OK), so its price is paid in coins at
/// request time. The demo seed has exactly one instant reward, which is why the
/// overspend needs a second one.
Future<void> makeInstant(AppDatabase db, String rewardId) {
  return (db.update(db.rewards)..where((r) => r.id.equals(rewardId))).write(
    const RewardsCompanion(needsOk: Value(false)),
  );
}

void main() {
  group(
    'K08-BUG-1 — an approved redemption can be written without payment',
    () {
      test(
        'two instant rewards cannot both be approved beyond the balance',
        () async {
          final db = AppDatabase.memory();
          addTearDown(db.close);
          await Seed.demo(db);
          await makeInstant(db, 'r-screen'); // 50, now instant
          final repo = KidShopRepositoryImpl(db: db);

          await repo.requestReward('maya', 'r-baking'); // 100 of 120
          expect(await coinsOf(db, 'maya'), 20);

          await repo.requestReward('maya', 'r-screen'); // 50 — NOT covered

          expect(
            await approvedValue(db),
            lessThanOrEqualTo(120 - await coinsOf(db, 'maya')),
            reason:
                'Maya paid 100 of 120, so at most 100 coins of rewards may be '
                'approved — a 50-coin card must not be auto-approved',
          );
        },
      );

      testWidgets('tapping two instant cards in one frame cannot overspend', (
        tester,
      ) async {
        final db = await setUpTestScope();
        await makeInstant(db, 'r-screen');
        await _pump(tester);

        // Both cards are individually affordable at 120 coins, and both taps
        // land before the stream has rebuilt the grid — exactly what a kid
        // mashing two buttons does.
        final buttons = find.byType(NestKidButton);
        await tester.tap(buttons.at(0)); // r-screen, 50
        await tester.tap(buttons.at(3)); // r-baking, 100
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final spent = 120 - await coinsOf(db, 'maya');
        expect(
          await approvedValue(db),
          lessThanOrEqualTo(spent),
          reason:
              'approved reward value must never exceed the coins spent '
              '(spent $spent)',
        );

        await disposeApp(tester);
      });
    },
  );

  group('K08-BUG-2 — an odd number of rewards crashes the shop grid', () {
    testWidgets('five cards render with a legal empty grid cell', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await keepOnlyRewards(db, <String>{
        'r-screen',
        'r-film',
        'r-bedtime',
        'r-baking',
        'r-cafe',
      });
      await _pump(tester);

      expect(
        tester.takeException(),
        isNull,
        reason:
            'a spare grid cell must be a plain filler, not a nested '
            'Expanded',
      );
      expect(find.byType(ShopRewardCard), findsNWidgets(5));
      final lonely = tester.getRect(find.byType(ShopRewardCard).at(4));
      expect(lonely.left, closeTo(20, 0.5));
      expect(lonely.width, closeTo(167, 1));

      await disposeApp(tester);
    });

    testWidgets('one card renders on its own, at full column width', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await keepOnlyRewards(db, <String>{'r-screen'});
      await _pump(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(ShopRewardCard), findsOneWidget);
      expect(find.byType(NestKidButton), findsOneWidget);
      final only = tester.getRect(find.byType(ShopRewardCard));
      expect(only.left, closeTo(20, 0.5));
      expect(only.width, closeTo(167, 1));
      expect(find.text('Get it'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('the lone card still buys its reward', (tester) async {
      final db = await setUpTestScope();
      await keepOnlyRewards(db, <String>{'r-dinner'});
      await _pump(tester);

      expect(find.byType(ShopRewardCard), findsOneWidget);
      await tester.tap(find.text('Get it'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final rows = await db.select(db.rewardRedemptions).get();
      expect(rows.single.rewardId, 'r-dinner');
      expect(rows.single.status, 'requested');

      await disposeApp(tester);
    });
  });

  // The guard that must SURVIVE the K08-BUG-1 fix: whatever the repository
  // starts refusing, the per-card double tap and the per-id independence of
  // two different cards are still correct behaviour and are proved in
  // `reward_shop_view_test.dart`.
  group('K08-BUG-1 sibling — nothing else may regress', () {
    testWidgets('two needs-OK cards both write, once each', (tester) async {
      final db = await setUpTestScope();
      await _pump(tester);

      final buttons = find.byType(NestKidButton);
      await tester.tap(buttons.at(0));
      await tester.pump();
      await tester.tap(buttons.at(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final rows = await db.select(db.rewardRedemptions).get();
      expect(rows.map((r) => r.rewardId).toList(), <String>[
        'r-screen',
        'r-film',
      ]);
      expect(rows.map((r) => r.status).toSet(), <String>{'requested'});

      await disposeApp(tester);
    });
  });

  // -------------------------------------------------------------------------
  // K08-BUG-4 — a raced instant request is announced as already owned (minor)
  // -------------------------------------------------------------------------

  group('K08-BUG-4 — a raced request is announced as already owned', () {
    testWidgets('a reward left awaiting approval is not announced as "yours"', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await makeInstant(db, 'r-screen');
      await _pump(tester);

      // 120 coins: screen time (50) and baking (100) are each affordable;
      // both taps land in one frame and the repository — correctly, since
      // the K08-BUG-1 fix — leaves the second as `requested`. The bloc still
      // toasts from the `needsOk` flag captured at tap time, so the second
      // notice claims a reward that is waiting for a grown-up is already the
      // child's.
      final buttons = find.byType(NestKidButton);
      await tester.tap(buttons.at(0)); // r-screen, 50
      await tester.tap(buttons.at(3)); // r-baking, 100
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final rows = await db.select(db.rewardRedemptions).get();
      expect(rows.map((r) => '${r.rewardId}:${r.status}'), <String>[
        'r-screen:approved',
        'r-baking:requested',
      ]);

      // The first toast (the approved reward) is honest; advance past its 3 s
      // snackbar so the second notice — the `requested` one — is visible.
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 400));

      expect(
        find.text('It’s yours — enjoy!'),
        findsNothing,
        reason:
            'a reward the repository left awaiting a grown-up must not be '
            'announced as already owned',
      );
      expect(find.text('Mum will give it a thumbs-up soon.'), findsOneWidget);
      await disposeApp(tester);
    });
  });
}

Future<void> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const NestlingApp(initialRoute: _route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}
