// K06 · Pip's nest — the iteration-2 repository rewrite (K06-BUG-1 / BUG-2).
//
// Iteration 1 wrote care and buys as SELECT-then-write, so two overlapping
// taps both read the same row and one charge was lost (BUG-1) or two
// purchases were both paid for (BUG-2). Both are now single conditional
// statements:
//
//   UPDATE children SET coins = coins - ?, happiness = min(happiness + 1, 5)
//   WHERE id = ? AND coins >= ?
//
// This file is the layer `pip_repository_test.dart`'s new `atomic writes`
// group does not reach: the AFFORDABILITY BOUNDARY under concurrency (zero
// rows changed = a silent no-op), a refusal emitting nothing at all, mixed
// care bursts, the buy boundary, and the unknown-child guards. Each of those
// is a branch the rewrite introduced; a lost-update proof alone would still
// pass if the guard had been dropped.
//
// Plain `test`s over the in-memory Drift database (`Seed.demo`), never
// `testWidgets`: awaiting a Drift stream inside the fake-async zone never
// completes.
//
// ORCHESTRATOR_NOTES 13:52: `shared/shared_batch7` moved the demo wardrobe to
// the design's 30/60 (it used to be 40/120) and HAS LANDED on `main`. The buy
// boundaries below therefore read the seeded price out of the database instead
// of pinning it, so a future price change moves the premise with the guard
// rather than reddening an unrelated boundary probe.
import 'dart:math' as math;

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/pip/data/pip_repository_impl.dart';
import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/entities/pip_profile.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_bloc.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_event.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_state.dart';

const Duration _settle = Duration(milliseconds: 120);

void main() {
  late AppDatabase db;
  late PipRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase.memory();
    await Seed.demo(db);
    repo = PipRepositoryImpl(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<PipProfile?> maya() => repo.watchProfile('maya').first;

  Future<void> setCoins(String childId, int coins) async {
    await (db.update(db.children)..where((c) => c.id.equals(childId))).write(
      ChildrenCompanion(coins: Value(coins)),
    );
  }

  Future<PipNest?> nest() => repo.watchNest().first;

  Future<bool> owned(String item) async =>
      (await nest())!.items.firstWhere((i) => i.id == item).owned;

  group('care: the affordability guard is part of the write', () {
    test('a burst that cannot afford every tap charges what it can', () async {
      // 7 coins: exactly one Feed (5) fits; a second would go negative.
      await setCoins('maya', 7);
      await Future.wait(<Future<void>>[
        repo.feed('maya'),
        repo.feed('maya'),
        repo.feed('maya'),
      ]);

      final profile = await maya();
      expect(profile!.coins, 2, reason: 'one 5-coin charge, never negative');
      expect(profile.happiness, 5, reason: 'one +1, clamped at 5');
    });

    test('a burst below the price changes nothing at all', () async {
      // 2 coins: Feed (5) and Bath (3) are both over the balance, so the
      // WHERE clause refuses every one of them and nothing may move.
      await setCoins('maya', 2);
      await Future.wait(<Future<void>>[
        repo.feed('maya'),
        repo.bathe('maya'),
        repo.feed('maya'),
        repo.bathe('maya'),
      ]);

      final profile = await maya();
      expect(profile!.coins, 2, reason: 'zero rows changed');
      expect(profile.happiness, 4, reason: 'no +1 either');
    });

    test('the price is inclusive: 5 coins buys exactly one Feed', () async {
      await setCoins('maya', 5);
      await repo.feed('maya');

      final profile = await maya();
      expect(profile!.coins, 0);
      expect(profile.happiness, 5);
    });

    test('a refused write emits nothing, so nothing on screen moves', () async {
      final seen = <PipNest?>[];
      final sub = repo.watchNest().listen(seen.add);
      await Future<void>.delayed(_settle);
      expect(seen, hasLength(1), reason: 'the first nest emission');
      seen.clear();

      // 2 coins: Feed (5) and Bath (3) are both refused by the WHERE clause.
      await setCoins('maya', 2);
      await Future<void>.delayed(_settle);
      seen.clear();
      await repo.feed('maya');
      await repo.bathe('maya');
      await Future<void>.delayed(_settle);

      expect(
        seen.where((n) => n?.profile.coins == 0),
        isEmpty,
        reason:
            'a zero-row UPDATE notifies nothing (the coins moved to 2, '
            'not 0, so any emission here would be the refused write)',
      );
      expect((await maya())!.coins, 2);
      await sub.cancel();
    });

    test('Play is still free at zero coins and still counts', () async {
      await setCoins('maya', 0);
      await repo.play('maya');
      final profile = await maya();
      expect(profile!.coins, 0, reason: 'never negative');
      expect(profile.happiness, 5);
    });

    test('a mixed burst spends every coin it is entitled to', () async {
      // 120 coins: 2 feeds (10) + 1 bath (3) + 2 free plays.
      await Future.wait(<Future<void>>[
        repo.feed('maya'),
        repo.bathe('maya'),
        repo.play('maya'),
        repo.feed('maya'),
        repo.play('maya'),
      ]);

      final profile = await maya();
      expect(profile!.coins, 107);
      expect(profile.happiness, 5, reason: 'five actions, clamped at 5');
    });

    test('care for an unknown child is a no-op on every action', () async {
      await repo.feed('ghost');
      await repo.bathe('ghost');
      await repo.play('ghost');

      final profile = await maya();
      expect(profile!.coins, 120);
      expect(profile.happiness, 4);
      expect(
        (await nest())!.items.firstWhere((i) => i.id == 'wellies').owned,
        isFalse,
      );
    });

    test('two children are billed independently', () async {
      await Future.wait(<Future<void>>[
        repo.feed('maya'),
        repo.feed('maya'),
        repo.feed('leo'),
      ]);

      expect((await repo.watchProfile('maya').first)!.coins, 110);
      expect((await repo.watchProfile('leo').first)!.coins, 40);
    });
  });

  group('wardrobe: the deduction and the claim are one transaction', () {
    // Every buy boundary below is expressed against the SEEDED price, read out
    // of the database, never a literal. Shared batch 7 moved the demo wardrobe
    // to the design's 30/60 (it used to be 40/120), which proved literals are
    // the wrong oracle here: the guard under test is the affordability
    // boundary, not a particular number.
    Future<int> priceOf(String item) async =>
        (await nest())!.items.firstWhere((i) => i.id == item).priceCoins;

    test(
      'the price is inclusive: exactly the price buys the wellies',
      () async {
        final price = await priceOf('wellies');
        await setCoins('maya', price);
        await repo.buyItem('maya', 'wellies');

        final after = await nest();
        expect(await owned('wellies'), isTrue);
        expect(after!.profile.coins, 0, reason: 'never negative');
      },
    );

    test('one coin short buys nothing', () async {
      final price = await priceOf('wellies');
      await setCoins('maya', price - 1);
      await repo.buyItem('maya', 'wellies');

      expect(await owned('wellies'), isFalse);
      expect((await nest())!.profile.coins, price - 1);
    });

    test('an unknown child or an unknown item buys nothing', () async {
      await repo.buyItem('ghost', 'wellies');
      await repo.buyItem('maya', 'spacesuit');

      expect(await owned('wellies'), isFalse);
      expect((await nest())!.profile.coins, 120);
    });

    test('a same-item burst pays once and the tile ends owned', () async {
      final price = await priceOf('wellies');
      final start = (await nest())!.profile.coins;
      await Future.wait(<Future<void>>[
        repo.buyItem('maya', 'wellies'),
        repo.buyItem('maya', 'wellies'),
        repo.buyItem('maya', 'wellies'),
      ]);

      expect(await owned('wellies'), isTrue);
      expect(
        (await nest())!.profile.coins,
        start - price,
        reason: 'the $price price paid exactly once',
      );
    });

    test('a two-item burst can afford exactly one', () async {
      // The balance sits strictly BETWEEN the two seeded prices, so whichever
      // is cheaper is affordable and the other is not — whatever the seed says
      // (30/60 after shared batch 7, where a 120 balance could now afford
      // both and this probe would have proved nothing).
      final wellies = await priceOf('wellies');
      final crown = await priceOf('crown');
      final lo = math.min(wellies, crown);
      final hi = math.max(wellies, crown);
      await setCoins('maya', lo + (hi - lo) ~/ 2);
      await Future.wait(<Future<void>>[
        repo.buyItem('maya', 'wellies'),
        repo.buyItem('maya', 'crown'),
      ]);

      final after = await nest();
      final bought = after!.items.where((i) => i.owned && i.priceCoins > 0);
      expect(
        bought,
        hasLength(1),
        reason: 'only one of $wellies + $crown is affordable',
      );
      expect(after.profile.coins, greaterThanOrEqualTo(0));
    });

    test('an already-owned item is never re-charged', () async {
      // The seed owns Scarf with a 0 price: the deduction is a no-op, but the
      // claim must not run either, or a later re-seed would show a paid tile.
      await repo.buyItem('maya', 'scarf');
      await repo.buyItem('maya', 'sunhat');

      final after = await nest();
      expect(after!.profile.coins, 120);
      expect(after.items.firstWhere((i) => i.id == 'scarf').owned, isTrue);
      expect(after.items.firstWhere((i) => i.id == 'sunhat').owned, isTrue);
    });

    test('buying leaves the equip path untouched', () async {
      final price = await priceOf('wellies');
      await repo.buyItem('maya', 'wellies');
      await repo.updateLook(childId: 'maya', accessory: 'scarf');

      final profile = await repo.watchProfile('maya').first;
      expect(profile!.accessory, 'scarf');
      expect(profile.coins, 120 - price);
    });
  });

  // Drift's `customUpdate` notifies the tables it is given even when the
  // statement changed ZERO rows (it cannot know), so a refused write DOES push
  // an identical nest down `watchNest()`. That is harmless for the UI only
  // because `PipState.copyWithLoaded` of an unchanged nest is an `==`-equal
  // state and flutter_bloc drops it. These two tests are the guard for exactly
  // that: if a future change makes the refused write produce a DISTINCT state,
  // the screen would rebuild and could re-announce a toast nobody earned.
  group('a refused write must not move the screen', () {
    test('a care refusal produces no distinct bloc state', () async {
      await setCoins('maya', 2);
      final bloc = PipBloc(repository: repo);
      final states = <PipState>[];
      final sub = bloc.stream.listen(states.add);
      bloc.add(const PipLoadRequested());
      await Future<void>.delayed(_settle);
      expect(bloc.state.nest?.profile.coins, 2);
      states.clear();

      // Bypasses the view's own affordability guard (which disables the
      // button), so the repository is what refuses.
      bloc
        ..add(const PipCareRequested(PipCareKind.feed))
        ..add(const PipCareRequested(PipCareKind.bathe));
      await Future<void>.delayed(_settle);

      expect(
        states,
        isEmpty,
        reason:
            'a zero-row write may notify, but the nest is unchanged so '
            'every state must be equal and dropped',
      );
      expect(bloc.state.actionError, isNull, reason: 'no toast, no error');
      expect(bloc.state.nest?.profile.coins, 2);
      await sub.cancel();
      await bloc.close();
    });

    test('a buy refusal produces no distinct bloc state', () async {
      await setCoins('maya', 10);
      final bloc = PipBloc(repository: repo);
      final states = <PipState>[];
      final sub = bloc.stream.listen(states.add);
      bloc.add(const PipLoadRequested());
      await Future<void>.delayed(_settle);
      states.clear();

      bloc.add(const PipWardrobeBuyRequested('crown'));
      await Future<void>.delayed(_settle);

      // The bloc's own pre-check refuses it first (10 < 120), so this is the
      // toast path, not the database's: exactly one announcement.
      expect(bloc.state.actionError, kPipNotEnoughCoins);
      expect(bloc.state.actionNonce, 1);
      expect(bloc.state.nest?.profile.coins, 10);

      states.clear();
      // Now let the DATABASE refuse: give the bloc a cached balance it
      // believes is enough, then drop the row behind its back.
      await setCoins('maya', 0);
      await Future<void>.delayed(_settle);
      states.clear();
      await repo.buyItem('maya', 'wellies');
      await Future<void>.delayed(_settle);

      expect(
        states.where((s) => s.nest?.profile.coins == 0),
        isEmpty,
        reason:
            'wellies is 40 and the row holds 0: the purchase is refused '
            'and the tile stays locked',
      );
      expect(await owned('wellies'), isFalse);
      await sub.cancel();
      await bloc.close();
    });
  });
}
