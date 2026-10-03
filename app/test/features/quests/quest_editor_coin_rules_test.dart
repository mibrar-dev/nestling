// P09 · Quest editor — the coin rate and the coin range (iteration 2).
//
// Iteration 1's bug hunt found two money bugs the demo seed hides:
//
//   BUG-P09-1  the `= {n}p at payout` helper hard-coded 1p/coin instead of
//              reading `families.coinValuePencePerCoin`.
//   BUG-P09-4  a stored value outside 1..100 could not be walked back, and
//              opening such a row could not be repaired.
//
// Stage 6 filed BUG-P09-6 against the same rows on top of the iteration-2 fix
// (an out-of-range reward is shown at face value but silently clamped on
// save). This file therefore proves only what survives either answer to
// BUG-P09-6 — opening writes nothing, and the parent can walk the value back
// into range — and leaves the save-time decision to `p09_bugs_test.dart`.
//
// `Seed.demo()` sets the rate to 1, so the seeded screen looks right either
// way — the whole class is invisible until the family's row says otherwise.
// Every test here writes that row (or a corrupt quest row) straight into
// Drift, because the repository now REJECTS out-of-range coins on write by
// design (`QuestsRepositoryImpl._checkCoins`), which is exactly why the
// corrupt rows have to be planted below the data layer.
//
// DATA OVER MOCKS: the helper is a function of the database, not of the
// design, so the numbers below are the arithmetic of the seeded values.

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/quests/domain/quests_repository.dart';
import 'package:nestling/features/quests/quests_routes.dart';

import '../../test_scope.dart';

/// Plants a quest row directly in Drift, bypassing the repository's 1..100
/// coin contract so an out-of-range value can exist at all.
Future<void> _plantQuest(
  AppDatabase db, {
  required String id,
  int coins = 15,
  String title = 'Out of range quest',
}) => db
    .into(db.quests)
    .insert(
      QuestsCompanion.insert(
        id: id,
        familyId: Seed.familyId,
        title: title,
        icon: const Value('hoover'),
        coins: Value(coins),
        repeatRule: const Value('weekly'),
        days: const Value('6'),
        dueLabel: const Value('Before tea (5pm)'),
        dueTimeLocal: const Value('17:00'),
        needsApproval: const Value(true),
        assigneeChildId: const Value('maya'),
        active: const Value(true),
      ),
    );

/// Sets the family's coin value — the same column pocket_money reads.
Future<void> _setRate(AppDatabase db, int pencePerCoin) =>
    (db.update(db.families)..where((f) => f.id.equals(Seed.familyId))).write(
      FamiliesCompanion(coinValuePencePerCoin: Value(pencePerCoin)),
    );

/// The editor's stepper buttons (the component's own `ValueKey`s).
Finder _increase() => find.byKey(const ValueKey<String>('increase'));
Finder _decrease() => find.byKey(const ValueKey<String>('decrease'));

void main() {
  group(
    'P09 coin rate — the helper follows families.coinValuePencePerCoin',
    () {
      testWidgets('5p per coin prints "= 75p at payout" for 15 coins', (
        tester,
      ) async {
        final db = await setUpTestScope();
        await _setRate(db, 5);
        await pumpAppRoute(tester, QuestsRoutePaths.editor);

        // 15 coins x 5p. The design says "= 15p" only because the seed's rate
        // is 1 (DATA OVER MOCKS).
        expect(find.text('= 75p at payout'), findsOneWidget);
        expect(find.text('= 15p at payout'), findsNothing);
        await disposeApp(tester);
      });

      testWidgets('a rate change while the editor is open updates the helper', (
        tester,
      ) async {
        final db = await setUpTestScope();
        await pumpAppRoute(tester, QuestsRoutePaths.editor);
        expect(find.text('= 15p at payout'), findsOneWidget);

        // The helper is a live read (`watchCoinValuePencePerCoin`), not a value
        // latched when the sheet was built.
        await tester.runAsync(() => _setRate(db, 4));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('= 60p at payout'), findsOneWidget);
        await disposeApp(tester);
      });

      testWidgets('the rate never scales the coin count itself', (
        tester,
      ) async {
        final db = await setUpTestScope();
        await _setRate(db, 4);
        await pumpAppRoute(tester, QuestsRoutePaths.editor);

        expect(find.text('15'), findsOneWidget, reason: 'the stepper is coins');
        expect(find.text('= 60p at payout'), findsOneWidget);
        await disposeApp(tester);
      });

      testWidgets('the rate multiplies after the stepper moves the count', (
        tester,
      ) async {
        final db = await setUpTestScope();
        await _setRate(db, 2);
        await pumpAppRoute(tester, QuestsRoutePaths.editor);
        expect(find.text('= 30p at payout'), findsOneWidget);

        await tester.tap(_increase());
        await tester.pump();
        expect(find.text('16'), findsOneWidget);
        expect(find.text('= 32p at payout'), findsOneWidget);
        await disposeApp(tester);
      });

      testWidgets('the saved quest stores coins, not pence', (tester) async {
        final db = await setUpTestScope();
        await _setRate(db, 5);
        await pumpAppRoute(tester, QuestsRoutePaths.editor);
        await tester.enterText(find.byType(TextField).first, 'Rate check');
        await tester.pump();
        await tester.tap(find.text('Save'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        final saved = await tester.runAsync(
          () => GetIt.instance<QuestsRepository>().getItems(),
        );
        final created = saved!.firstWhere(
          (quest) => quest.title == 'Rate check',
        );
        expect(
          created.coins,
          15,
          reason: '75p is a display of 15 coins, not 75',
        );
        await disposeApp(tester);
      });
    },
  );

  group('P09 coin range — a stored value outside 1..100 (BUG-P09-4)', () {
    testWidgets('a 9999-coin quest opens showing 9999 and writes nothing', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await _plantQuest(db, id: 'q-huge', coins: 9999);
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-huge');

      // Shown as stored: OPENING the editor must never rewrite the row, and
      // the stepper still has to reach the design's range from here.
      expect(find.text('9999'), findsOneWidget);
      expect(find.text('100'), findsNothing);
      expect(find.text('= 9999p at payout'), findsOneWidget);
      final untouched = await tester.runAsync(
        () => GetIt.instance<QuestsRepository>().getQuest('q-huge'),
      );
      expect(untouched?.coins, 9999, reason: 'no write happened on open');
      await disposeApp(tester);
    });

    testWidgets('`−` walks a 9999-coin quest back one coin at a time', (
      tester,
    ) async {
      final db = await setUpTestScope();
      await _plantQuest(db, id: 'q-huge', coins: 9999);
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-huge');

      await tester.tap(_decrease());
      await tester.pump();
      expect(find.text('9998'), findsOneWidget);
      expect(find.text('= 9998p at payout'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('a 0-coin quest shows 0, keeps `+` live and climbs to 1', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final db = await setUpTestScope();
      await _plantQuest(db, id: 'q-zero', coins: 0);
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-zero');

      expect(find.text('0'), findsOneWidget);
      expect(find.text('= 0p at payout'), findsOneWidget);
      // The floor is the stored 0, so `−` is inert — for the finger (no InkWell
      // handler) and for VoiceOver (no tap action) — while `+` climbs out.
      expect(
        tester
            .widget<InkWell>(
              find.descendant(of: _decrease(), matching: find.byType(InkWell)),
            )
            .onTap,
        isNull,
      );
      expect(
        tester
            .getSemantics(_decrease())
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
      expect(
        tester
            .getSemantics(_increase())
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );

      await tester.tap(_increase());
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(find.text('= 1p at payout'), findsOneWidget);
      handle.dispose();
      await disposeApp(tester);
    });

    // NOT asserted here: what an out-of-range row does when it is SAVED
    // (store what was shown, or block the save with a visible reason — the
    // screen currently clamps silently). That question is BUG-P09-6 and its
    // proof lives in `p09_bugs_test.dart`; pinning either side of it here
    // would break the moment the fix lands.

    testWidgets('an in-range quest is never rewritten by opening it', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-hoover');

      expect(find.text('20'), findsOneWidget);
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      final stored = await tester.runAsync(
        () => GetIt.instance<QuestsRepository>().getQuest('q-hoover'),
      );
      expect(stored?.coins, 20);
      expect(stored?.title, 'Hoover the stairs');
      await disposeApp(tester);
    });
  });
}
