// K10 repository tests (DB-backed, Seed.demo): the latest-payout contract.
//
// `watchLatestPayout` emits the active child's payout celebration — the
// latest `payout` row rendered back with its companion `Jar → …` savings
// move, the live savings goal and the child's Pip look — or null when no
// payout was recorded yet. Follows `app_state.activeChildId` switches.
// Demo seed, Maya: paid 380, moved 550, goal "Lego Friends set" 1550/2499,
// Pip mochi/sunny/none/3. Leo: paid 190, no move, no goal.

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/kid_jar/data/kid_jar_repository_impl.dart';
import 'package:nestling/features/kid_jar/domain/entities/payout_celebration.dart';
import 'package:nestling/features/pocket_money/data/pocket_money_repository_impl.dart';

/// Collects the payout stream's emissions so a test can await the one a
/// write provokes. Bounded waits only, so a stream that never emits fails
/// fast instead of hanging.
class _PayoutEmissions {
  _PayoutEmissions(Stream<PayoutCelebration?> stream) {
    _sub = stream.listen(_events.add, onError: _errors.add);
  }

  late final StreamSubscription<PayoutCelebration?> _sub;
  final List<PayoutCelebration?> _events = <PayoutCelebration?>[];
  final List<Object> _errors = <Object>[];

  List<Object> get errors => List<Object>.unmodifiable(_errors);

  Future<PayoutCelebration?> next() async {
    for (var i = 0; i < 30; i++) {
      if (_events.isNotEmpty) return _events.removeAt(0);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw StateError('no payout emission arrived within 300 ms');
  }

  Future<void> cancel() => _sub.cancel();
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.memory();
    await Seed.demo(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> setActiveChild(String childId) {
    return (db.update(db.appState)..where((a) => a.id.equals(1))).write(
      AppStateCompanion(activeChildId: Value(childId)),
    );
  }

  group('KidJarRepository watchLatestPayout (K10, Maya)', () {
    test(
      'emits the demo celebration: paid 380, moved 550, Lego goal',
      () async {
        final repo = KidJarRepositoryImpl(db: db);
        final celebration = await repo.watchLatestPayout().first;

        expect(celebration, isNotNull);
        expect(celebration!.childId, 'maya');
        expect(celebration.nickname, 'Maya');
        expect(
          celebration.paidPence,
          380,
          reason: 'abs() of the 26 Sep payout row (−380)',
        );
        expect(
          celebration.movedPence,
          550,
          reason: 'the 30 Sep `Jar → Lego fund` companion move',
        );
        expect(celebration.goalTitle, 'Lego Friends set');
        expect(celebration.goalSavedPence, 1550);
        expect(celebration.goalTargetPence, 2499);
        expect(celebration.pipStyle, 'mochi');
        expect(celebration.pipSkin, 'sunny');
        expect(celebration.pipAccessory, 'none');
        expect(celebration.pipStage, 3);
      },
    );

    test('goal maths read 62% with £9.49 to go on the demo seed', () async {
      final repo = KidJarRepositoryImpl(db: db);
      final celebration = await repo.watchLatestPayout().first;

      expect(celebration!.goalPercent, 62);
      expect(celebration.goalRemainingPence, 949);
      expect(celebration.goalFraction, closeTo(1550 / 2499, 0.0001));
    });

    test('a recordPayout becomes the new celebration with its move', () async {
      final money = PocketMoneyRepositoryImpl(db: db);
      await money.recordPayout(
        childId: 'maya',
        amountPence: 420,
        savingsMovePence: 100,
        goalId: 'goal-lego',
      );

      final repo = KidJarRepositoryImpl(db: db);
      final celebration = await repo.watchLatestPayout().first;

      // The payout and its companion share one instant (`recordPayout`
      // stamps both rows with the same `now`): the move at the exact payout
      // instant counts as the event, never before it.
      expect(celebration!.paidPence, 420);
      expect(celebration.movedPence, 100);
      expect(celebration.goalSavedPence, 1650);
      expect(celebration.goalPercent, 66);
      expect(celebration.goalRemainingPence, 849);
    });

    test('a recordPayout without a move hides note 2', () async {
      final money = PocketMoneyRepositoryImpl(db: db);
      await money.recordPayout(childId: 'maya', amountPence: 200);

      final repo = KidJarRepositoryImpl(db: db);
      final celebration = await repo.watchLatestPayout().first;

      // The older `Jar → Lego fund` move is BEFORE this payout's instant, so
      // it is not its companion: a later payout without a move reads null.
      expect(celebration!.paidPence, 200);
      expect(celebration.movedPence, isNull);
    });
  });

  group('KidJarRepository watchLatestPayout (K10, Leo)', () {
    test('Leo is paid 190 with no move and no goal', () async {
      await setActiveChild('leo');
      final repo = KidJarRepositoryImpl(db: db);
      final celebration = await repo.watchLatestPayout().first;

      expect(celebration, isNotNull);
      expect(celebration!.childId, 'leo');
      expect(celebration.nickname, 'Leo');
      expect(
        celebration.paidPence,
        190,
        reason: 'abs() of the 26 Sep payout row (−190)',
      );
      expect(
        celebration.movedPence,
        isNull,
        reason: 'Leo has no `Jar → …` move, so note 2 is hidden',
      );
      expect(celebration.goalTitle, 'Savings goal');
      expect(celebration.goalSavedPence, 0);
      expect(celebration.goalTargetPence, 0);
      expect(celebration.goalPercent, 0);
      expect(celebration.goalRemainingPence, 0);
      expect(celebration.goalFraction, 0);
      expect(celebration.pipStyle, 'bolt');
      expect(celebration.pipSkin, 'sky');
      expect(celebration.pipAccessory, 'none');
      expect(celebration.pipStage, 2);
    });
  });

  group('KidJarRepository watchLatestPayout with no payout yet (K10)', () {
    test('a child with no payout row emits null', () async {
      await db
          .into(db.children)
          .insert(
            ChildrenCompanion.insert(
              id: 'nova',
              familyId: Seed.familyId,
              nickname: 'Nova',
            ),
          );
      await setActiveChild('nova');
      final repo = KidJarRepositoryImpl(db: db);

      expect(await repo.watchLatestPayout().first, isNull);
    });

    test('Seed.empty has no children: no celebration', () async {
      await Seed.empty(db);
      final repo = KidJarRepositoryImpl(db: db);

      // No active child falls back to 'maya', which has no row either.
      expect(await repo.watchLatestPayout().first, isNull);
    });
  });

  group('KidJarRepository watchLatestPayout live re-emission (K10)', () {
    late KidJarRepositoryImpl repo;
    late _PayoutEmissions payouts;

    setUp(() {
      repo = KidJarRepositoryImpl(db: db);
      payouts = _PayoutEmissions(repo.watchLatestPayout());
    });

    tearDown(() => payouts.cancel());

    test('follows an active-child switch after the first emission', () async {
      expect((await payouts.next())?.childId, 'maya');

      await setActiveChild('leo');

      final second = await payouts.next();
      expect(second?.childId, 'leo');
      expect(second?.paidPence, 190);
      expect(second?.movedPence, isNull);
      expect(payouts.errors, isEmpty);
    });

    test('a new payout replaces the celebration without a reload', () async {
      expect((await payouts.next())?.paidPence, 380);

      final money = PocketMoneyRepositoryImpl(db: db);
      await money.recordPayout(
        childId: 'maya',
        amountPence: 420,
        savingsMovePence: 100,
        goalId: 'goal-lego',
      );

      // `recordPayout` writes two tables (ledger + goal) in one transaction,
      // and the combined stream re-emits per source: the first post-write
      // emission can carry the new ledger rows with the old goal figure.
      // Drain until the emission that has seen both sources.
      PayoutCelebration? settled;
      for (var i = 0; i < 10; i++) {
        final next = await payouts.next();
        if (next?.paidPence == 420 && next?.goalSavedPence == 1650) {
          settled = next;
          break;
        }
      }
      expect(settled?.paidPence, 420);
      expect(settled?.movedPence, 100);
      expect(settled?.goalSavedPence, 1650);
      expect(payouts.errors, isEmpty);
    });
  });

  group('PayoutCelebration value semantics', () {
    PayoutCelebration maya() => const PayoutCelebration(
      childId: 'maya',
      nickname: 'Maya',
      paidPence: 380,
      movedPence: 550,
      goalTitle: 'Lego Friends set',
      goalSavedPence: 1550,
      goalTargetPence: 2499,
      pipStyle: 'mochi',
      pipSkin: 'sunny',
      pipAccessory: 'none',
      pipStage: 3,
    );

    test('equal celebrations compare equal', () {
      expect(maya(), maya());
      expect(
        maya(),
        isNot(
          const PayoutCelebration(
            childId: 'maya',
            nickname: 'Maya',
            paidPence: 420,
            movedPence: 550,
            goalTitle: 'Lego Friends set',
            goalSavedPence: 1550,
            goalTargetPence: 2499,
            pipStyle: 'mochi',
            pipSkin: 'sunny',
            pipAccessory: 'none',
            pipStage: 3,
          ),
        ),
      );
    });

    test('a null move is a distinct celebration (note 2 hidden)', () {
      expect(maya().movedPence, isNotNull);
      expect(
        const PayoutCelebration(
          childId: 'leo',
          nickname: 'Leo',
          paidPence: 190,
          movedPence: null,
          goalTitle: 'Savings goal',
          goalSavedPence: 0,
          goalTargetPence: 0,
          pipStyle: 'bolt',
          pipSkin: 'sky',
          pipAccessory: 'none',
          pipStage: 2,
        ),
        isNot(maya()),
      );
    });

    test('goal helpers clamp an overshoot instead of rendering past full', () {
      const over = PayoutCelebration(
        childId: 'maya',
        nickname: 'Maya',
        paidPence: 380,
        movedPence: null,
        goalTitle: 'Lego Friends set',
        goalSavedPence: 3000,
        goalTargetPence: 2499,
        pipStyle: 'mochi',
        pipSkin: 'sunny',
        pipAccessory: 'none',
        pipStage: 3,
      );

      expect(over.goalFraction, 1);
      expect(over.goalRemainingPence, 0);
    });
  });
}
