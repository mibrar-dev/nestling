// K06 · Pip's nest — the iteration-3 contract (`PipBuyResult` + the carried
// action outcome), at the two layers the build's own proofs do not work at.
//
// K06-BUG-7 (a purchase the fresh balance refuses answered the tap with
// silence) was fixed by giving `buyItem` a return value and by carrying a
// pending outcome through `PipState.copyWithLoaded`. Both halves are contract
// changes, so this file pins:
//
//   * the one enum value no other test names — `unavailable` (unknown item or
//     unknown child) — and that a purchase is charged the ROW's price, read
//     back from the database, never a number typed in here;
//   * that ONLY `cannotAfford` announces. `bought`, `alreadyOwned` and
//     `unavailable` must leave the toast channel silent, or a double tap on
//     one tile would nag the child about a purchase that simply worked;
//   * the carried outcome as a SEQUENCE, which is what the fix is really
//     about: it survives the sibling write's stream refresh, it is announced
//     exactly once (the view's own `listenWhen` predicate is evaluated here,
//     not a lookalike), and it still clears on the next attempt.
//
// Plain `test`s over the in-memory Drift database (`Seed.demo`), never
// `testWidgets`: awaiting a Drift stream inside the fake-async zone never
// completes.

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/pip/data/pip_repository_impl.dart';
import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/pip_repository.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_bloc.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_event.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_state.dart';

const Duration _settle = Duration(milliseconds: 120);

/// The view's own gate, copied so a change to `pip_nest_view.dart`'s
/// `BlocListener.listenWhen` has to be mirrored here deliberately:
///
/// ```dart
/// listenWhen: (previous, current) =>
///     previous.actionNonce != current.actionNonce &&
///     current.actionError != null,
/// ```
bool _viewWouldToast(PipState previous, PipState current) =>
    previous.actionNonce != current.actionNonce && current.actionError != null;

/// How many times [states] would make the view toast.
///
/// Walks consecutive PAIRS rather than looking each state up by value: two
/// identical states are `==`, so `indexOf` would always return the first one
/// and the walk would be meaningless.
int _toasts(List<PipState> states) {
  var count = 0;
  for (var i = 1; i < states.length; i++) {
    if (_viewWouldToast(states[i - 1], states[i])) count++;
  }
  return count;
}

/// Repository whose `buyItem` reports a chosen [PipBuyResult] without touching
/// the database, so the bloc's mapping can be walked one outcome at a time —
/// including a sequence that changes its mind between taps, which a real
/// database cannot be asked to do deterministically.
class _ResultRepository extends PipRepositoryImpl {
  _ResultRepository({required super.db, this.result = PipBuyResult.bought});

  PipBuyResult result;

  /// Every item the bloc asked for, in order.
  final List<String> buyCalls = <String>[];

  @override
  Future<PipBuyResult> buyItem(String childId, String item) {
    buyCalls.add(item);
    return Future.value(result);
  }
}

/// A loaded bloc and every state it has emitted since the subscription.
class _Harness {
  _Harness(this.bloc, this.states);

  final PipBloc bloc;

  /// The WHOLE stream, from the load on. The view's `listenWhen` compares
  /// CONSECUTIVE states, so the load's `loading` -> `loaded` pair is what the
  /// first refusal is compared against; dropping it would make every toast
  /// count read 0. Those two states carry no `actionError`, so they add
  /// nothing to [_toasts].
  final List<PipState> states;

  Future<void> settle() => Future<void>.delayed(_settle);

  /// One tap, then the wait that lets the bloc and the stream finish. Fused
  /// so a test body never has two calls on the same receiver split by the
  /// `await` that makes them sequential.
  Future<void> tapAndSettle(PipEvent event) async {
    bloc.add(event);
    await settle();
  }
}

Future<_Harness> _loaded(PipRepositoryImpl repository) async {
  final bloc = PipBloc(repository: repository);
  final states = <PipState>[];
  final subscription = bloc.stream.listen(states.add);
  addTearDown(() async {
    await subscription.cancel();
    await bloc.close();
  });
  bloc.add(const PipLoadRequested());
  await Future<void>.delayed(_settle);
  expect(bloc.state.status, PipStatus.loaded, reason: 'the nest loaded');
  return _Harness(bloc, states);
}

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

  Future<void> setCoins(String childId, int coins) async {
    await (db.update(db.children)..where((c) => c.id.equals(childId))).write(
      ChildrenCompanion(coins: Value(coins)),
    );
  }

  /// The seeded price of [item] for [childId], read from the row.
  Future<int> priceOf(String item, [String childId = 'maya']) async {
    final row =
        await (db.select(db.pipWardrobe)
              ..where((w) => w.childId.equals(childId) & w.item.equals(item)))
            .getSingle();
    return row.priceCoins;
  }

  Future<PipNest?> nest() => repo.watchNest().first;

  Future<bool> owned(String item) async =>
      (await nest())!.items.firstWhere((i) => i.id == item).owned;

  Future<int> coins([String childId = 'maya']) async =>
      (await repo.watchProfile(childId).first)!.coins;

  group('PipBuyResult — the four outcomes, from the real database', () {
    test(
      'bought: charged exactly the ROW price, tile flips to owned',
      () async {
        final price = await priceOf('wellies');
        final before = await coins();

        expect(await repo.buyItem('maya', 'wellies'), PipBuyResult.bought);
        expect(await owned('wellies'), isTrue);
        expect(
          before - await coins(),
          price,
          reason:
              'the deduction is the seeded row price, read back — this file '
              'types no price at all',
        );
        // The rendered label follows the same row: the price while the tile is
        // locked, the owned word once it has been bought.
        expect(
          (await nest())!.items.firstWhere((i) => i.id == 'crown').detail,
          '${await priceOf('crown')} coins',
        );
        await repo.buyItem('maya', 'crown');
        expect(
          (await nest())!.items.firstWhere((i) => i.id == 'crown').detail,
          'Owned',
        );
      },
    );

    test('cannotAfford: nothing written, nothing charged', () async {
      await setCoins('maya', 1);
      expect(await repo.buyItem('maya', 'wellies'), PipBuyResult.cannotAfford);
      expect(await owned('wellies'), isFalse);
      expect(await coins(), 1);
    });

    test('alreadyOwned: an owned row is never charged again', () async {
      final before = await coins();
      // Scarf is owned in the seed at price 0 — the cheapest possible trap: a
      // second `bought` here would be invisible in the balance.
      expect(await repo.buyItem('maya', 'scarf'), PipBuyResult.alreadyOwned);
      expect(await coins(), before);
      expect(await owned('scarf'), isTrue);
    });

    test('unavailable: an unknown item id writes nothing', () async {
      final before = await coins();
      final rows = await db.select(db.pipWardrobe).get();

      expect(
        await repo.buyItem('maya', 'spacesuit'),
        PipBuyResult.unavailable,
        reason: 'no such wardrobe row',
      );
      expect(await coins(), before);
      expect(await db.select(db.pipWardrobe).get(), hasLength(rows.length));
    });

    test('unavailable: an unknown child writes nothing', () async {
      final before = await coins();
      final rows = await db.select(db.pipWardrobe).get();

      expect(
        await repo.buyItem('ghost', 'wellies'),
        PipBuyResult.unavailable,
        reason:
            'no such child row, so the conditional deduction changes nothing',
      );
      expect(await coins(), before);
      expect(await db.select(db.pipWardrobe).get(), hasLength(rows.length));
      expect(await owned('wellies'), isFalse);
    });

    test(
      'a same-item burst reports bought + alreadyOwned, charges once',
      () async {
        final price = await priceOf('wellies');
        final before = await coins();

        final results = await Future.wait(<Future<PipBuyResult>>[
          repo.buyItem('maya', 'wellies'),
          repo.buyItem('maya', 'wellies'),
        ]);

        // The loser of the race finds the tile owned (or its claim refused and
        // refunded) — either way it must NOT report a second `bought`, which is
        // what would let the bloc announce a phantom purchase.
        expect(results.toSet(), <PipBuyResult>{
          PipBuyResult.bought,
          PipBuyResult.alreadyOwned,
        });
        expect(await owned('wellies'), isTrue);
        expect(before - await coins(), price, reason: 'charged once');
      },
    );

    test(
      'a two-item burst on a between-prices balance: one bought, one refused',
      () async {
        final wellies = await priceOf('wellies');
        final crown = await priceOf('crown');
        expect(crown, greaterThan(0));
        expect(wellies + crown, greaterThan(crown), reason: 'the premise');
        // A balance that affords the dearer tile and not both: the only shape
        // where the DATABASE is what refuses.
        await setCoins('maya', crown);

        final results = await Future.wait(<Future<PipBuyResult>>[
          repo.buyItem('maya', 'wellies'),
          repo.buyItem('maya', 'crown'),
        ]);

        expect(results, contains(PipBuyResult.bought));
        expect(results, contains(PipBuyResult.cannotAfford));
        expect(await coins(), greaterThanOrEqualTo(0));
      },
    );
  });

  group('only cannotAfford is announced', () {
    final silent = <PipBuyResult, String>{
      PipBuyResult.bought: 'the purchase worked',
      PipBuyResult.alreadyOwned: 'the tile was already owned',
      PipBuyResult.unavailable: 'there is no such tile',
    };

    for (final entry in silent.entries) {
      final result = entry.key;
      final description = entry.value;
      test('$description: no toast, no error state', () async {
        final fake = _ResultRepository(db: db, result: result);
        final harness = await _loaded(fake);

        await harness.tapAndSettle(const PipWardrobeBuyRequested('wellies'));

        final states = harness.states;
        final toasts = _toasts(states);
        expect(fake.buyCalls, <String>['wellies'], reason: 'the bloc asked');
        expect(toasts, 0, reason: description);
        expect(
          states.where((s) => s.actionError != null),
          isEmpty,
          reason: description,
        );
      });
    }

    test('cannotAfford: the kind copy, announced exactly once', () async {
      final harness = await _loaded(
        _ResultRepository(db: db, result: PipBuyResult.cannotAfford),
      );

      harness.bloc.add(const PipWardrobeBuyRequested('crown'));
      await harness.settle();

      expect(harness.bloc.state.actionError, kPipNotEnoughCoins);
      expect(harness.bloc.state.actionNonce, 1);
      expect(_toasts(harness.states), 1, reason: 'one refusal, one toast');
    });
  });

  group('the carried outcome, as a sequence', () {
    test('a refusal survives the sibling purchase’s stream refresh', () async {
      // The real shape of K06-BUG-7: two taps in one burst, one tile's coins
      // spent by the sibling, so the second tap is refused by the DATABASE
      // after the first has already refreshed the nest.
      final wellies = await priceOf('wellies');
      final crown = await priceOf('crown');
      expect(wellies + crown, greaterThan(crown), reason: 'the premise');
      await setCoins('maya', crown);
      final harness = await _loaded(repo);

      harness.bloc
        ..add(const PipWardrobeBuyRequested('wellies'))
        ..add(const PipWardrobeBuyRequested('crown'));
      await Future<void>.delayed(const Duration(milliseconds: 400));

      final bought = <String>[
        for (final item in const <String>['wellies', 'crown'])
          if (await owned(item)) item,
      ];
      expect(bought, hasLength(1), reason: 'only one purchase fits');

      // The refusal is still the state the screen is left in: the successful
      // sibling's refresh must not wipe it.
      expect(
        harness.bloc.state.actionError,
        kPipNotEnoughCoins,
        reason: 'carried through the refresh',
      );
      expect(
        _toasts(harness.states),
        1,
        reason: 'announced once — not again when the refresh arrives',
      );
    });

    test('a carried outcome clears on the next successful attempt', () async {
      final fake = _ResultRepository(db: db, result: PipBuyResult.cannotAfford);
      final harness = await _loaded(fake);

      harness.bloc.add(const PipWardrobeBuyRequested('crown'));
      await harness.settle();
      expect(harness.bloc.state.actionError, kPipNotEnoughCoins);
      final toastsAfterRefusal = _toasts(harness.states);

      // Play is free and always succeeds, so it is the cleanest "next
      // attempt": `withActionStarted` forgets the outcome and nothing carries
      // it forward.
      harness.bloc.add(const PipCareRequested(PipCareKind.play));
      await harness.settle();

      expect(harness.bloc.state.actionError, isNull);
      expect(harness.bloc.state.actionNonce, 0);
      expect(
        _toasts(harness.states),
        toastsAfterRefusal,
        reason: 'and nothing new is announced afterwards',
      );
    });

    test(
      'two refusals in a row are still announced twice (nonce 1 → 0 → 1)',
      () async {
        final fake = _ResultRepository(
          db: db,
          result: PipBuyResult.cannotAfford,
        );
        final harness = await _loaded(fake);

        harness.bloc.add(const PipWardrobeBuyRequested('crown'));
        await harness.settle();
        harness.bloc.add(const PipWardrobeBuyRequested('crown'));
        await harness.settle();

        expect(
          harness.states.map((s) => s.actionNonce),
          // `loading`(0) -> `loaded`(0) -> `loaded`(0) is the load: K07 added a
          // second subscription (`watchEvolution`), so the one load now emits
          // one healthy state per stream, both at nonce 0. Then refusal,
          // reset, refusal: one bump per failed attempt, one reset between
          // them.
          <int>[0, 0, 0, 1, 0, 1],
          reason: 'reset per attempt, bump per failure',
        );
        expect(_toasts(harness.states), 2);
        expect(harness.bloc.state.actionError, kPipNotEnoughCoins);
      },
    );

    test('a successful purchase between two refusals does not swallow the '
        'second toast', () async {
      // The one sequence the carry-through change could plausibly break: the
      // success forgets the first outcome, so the second refusal must start
      // from a clean slate and still be announced.
      final fake = _ResultRepository(db: db, result: PipBuyResult.cannotAfford);
      final harness = await _loaded(fake);

      harness.bloc.add(const PipWardrobeBuyRequested('crown'));
      await harness.settle();

      fake.result = PipBuyResult.bought;
      harness.bloc.add(const PipWardrobeBuyRequested('wellies'));
      await harness.settle();
      expect(
        harness.bloc.state.actionError,
        isNull,
        reason: 'the success clears the pending outcome',
      );
      expect(_toasts(harness.states), 1, reason: 'the success says nothing');

      fake.result = PipBuyResult.cannotAfford;
      harness.bloc.add(const PipWardrobeBuyRequested('crown'));
      await harness.settle();

      expect(_toasts(harness.states), 2, reason: 'both refusals announced');
      expect(harness.bloc.state.actionNonce, 1);
    });
  });

  group('PipState carries the outcome and nothing else', () {
    test('copyWithLoaded carries actionError + nonce, drops errorMessage', () {
      const failed = PipState(
        status: PipStatus.loaded,
        errorMessage: 'stale load error',
        actionError: kPipNotEnoughCoins,
        actionNonce: 3,
      );

      final carried = failed.copyWithLoaded(null);

      expect(carried.status, PipStatus.loaded);
      expect(carried.nest, isNull, reason: 'a null nest is the no-child card');
      expect(carried.actionError, kPipNotEnoughCoins);
      expect(carried.actionNonce, 3);
      expect(
        carried.errorMessage,
        isNull,
        reason: 'a stale LOAD error must not come back on a healthy emission',
      );
    });

    test('a carried outcome is still forgotten by withActionStarted', () {
      const failed = PipState(
        status: PipStatus.loaded,
        actionError: kPipNotEnoughCoins,
        actionNonce: 4,
      );

      final started = failed.withActionStarted();

      expect(started.actionError, isNull);
      expect(started.actionNonce, 0);
      expect(started.status, PipStatus.loaded);
    });

    test('a carried outcome survives toLoading (the retry path keeps it)', () {
      const failed = PipState(
        status: PipStatus.loaded,
        actionError: kPipNotEnoughCoins,
        actionNonce: 1,
      );
      final loading = failed.toLoading();
      expect(loading.status, PipStatus.loading);
      expect(loading.actionError, kPipNotEnoughCoins);
      expect(loading.actionNonce, 1);
    });
  });
}
