// P15 · Child profile — Stage 6 bug proofs (iteration 1).
//
// Iteration 2 un-skipped all six: the logic fixes below make them pass. (The
// P11/P12 convention is that the build un-skips once the bug is fixed.)
//
//   P15-BUG-1  major  `/child-profile?childId=` is ignored — fixed by
//                      `FamilyChildSelected` + `FamilyRepository.selectChild`
//                      (route persists a valid id before the first load).
//                      (test stage P15-BUG-1, review finding 1)
//   P15-BUG-3  minor  a second identical `removeChild` failure produces the
//                      same `errorMessage` state, which Equatable suppresses,
//                      so no fresh toast is shown (same root as the test
//                      stage's P15-BUG-3: `FamilyState.copyWith` cannot clear
//                      `errorMessage`). Remove-path proof, complementary to
//                      its load-recovery proof.
//   P15-BUG-6  major  removing a child leaves every dependent row (pending
//                      approvals, completions, ledger, quests, wardrobe,
//                      badges, goals) in the database — P11 then shows the
//                      deleted child's approvals as "Child" rows.
//   P15-BUG-7  major  removing the active child leaves
//                      `app_state.active_child_id` pointing at the deleted
//                      row; kid/pip/jar/shop repositories read that stale id.
//                      (review finding 2)
//   P15-BUG-8  major  `watchProfile` evaluates periods against the wall
//                      clock, not the pinned seed anchor — the demo numbers
//                      (and the existing `child_profile_bloc_test`) only hold
//                      on the real 2026-10-03; the suite goes red on 10-04
//                      with no code change. (`TodayRepositoryImpl` already
//                      uses `Seed.anchorOverride ?? DateTime.now()`.)
//                      (review finding 3)
//
// Seeds are pinned to Sat 3 Oct 2026 by `test/flutter_test_config.dart`;
// widgets pump on & pump through `test_scope.dart` (`disposeApp` drains Drift).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/family/data/family_repository_impl.dart';
import 'package:nestling/features/family/domain/entities/child_profile.dart';
import 'package:nestling/features/family/domain/entities/family_child.dart';
import 'package:nestling/features/family/domain/entities/family_member.dart';
import 'package:nestling/features/family/domain/family_repository.dart';
import 'package:nestling/features/family/presentation/bloc/family_bloc.dart';
import 'package:nestling/features/family/presentation/bloc/family_event.dart';
import 'package:nestling/features/family/presentation/widgets/child_profile_body.dart';

import '../../test_scope.dart';

class _MockFamilyRepository extends Mock implements FamilyRepository;

/// Lets real-async Drift work (loads, writes, stream re-emits) complete in a
/// widget test — the same helper `child_profile_view_test.dart` uses.
Future<void> _flushDrift(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 150)),
  );
  await tester.pump();
}

ChildProfile _profile(WidgetTester tester) =>
    tester.widget<ChildProfileBody>(find.byType(ChildProfileBody)).profile;

void main() {
  // -- P15-BUG-1 ---------------------------------------------------------
  // `?childId=` is the only selector P05 (`kid_card_grid.dart:130`) and P08
  // (`today_loaded_body.dart:557`) send; the route ignores it and
  // `watchProfile` always resolves `app_state.active_child_id` (which the
  // demo seed pins to 'maya').

  group('P15-BUG-1 — the childId query parameter is ignored', () {
    testWidgets('P15-BUG-1a: /child-profile?childId=leo must show Leo', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile?childId=leo');
      await _flushDrift(tester);
      await tester.pumpAndSettle();

      expect(
        _profile(tester).child.id,
        'leo',
        reason: 'P15-BUG-1: the deep link must select the child in the URL',
      );
      expect(find.text('Remove Leo from family'), findsOneWidget);

      await disposeApp(tester);
    }); // P15-BUG-1 fixed (iteration 2): the deep link selects Leo

    testWidgets("P15-BUG-1b: P05's Edit Leo pencil must open Leo's profile", (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/add-children');

      await tester.tap(find.byKey(const Key('editChild-leo')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await _flushDrift(tester);
      await tester.pumpAndSettle();

      expect(
        _profile(tester).child.id,
        'leo',
        reason: 'P15-BUG-1: Edit Leo lands on /child-profile?childId=leo',
      );

      await disposeApp(tester);
    }); // P15-BUG-1 fixed (iteration 2): Edit Leo opens Leo's profile
  });

  // -- P15-BUG-6 ---------------------------------------------------------
  // The confirm modal promises "They will lose their quests, coins and Pip.
  // This cannot be undone." (child_profile_copy.dart), but removeChild deletes
  // only the `children` row. Maya's two pending approvals then surface on P11
  // as "Child · …" rows (approvals_repository_impl.dart:44,51 fall back to
  // 'Child' when the child row is gone).

  testWidgets('P15-BUG-6: removing a child deletes their dependent rows', (
    tester,
  ) async {
    final db = await setUpTestScope();
    final repo = FamilyRepositoryImpl(db: db);

    await repo.removeChild('maya');

    final completions = await (db.select(
      db.questCompletions,
    )..where((c) => c.childId.equals('maya'))).get();
    final ledger = await (db.select(
      db.ledgerEntries,
    )..where((c) => c.childId.equals('maya'))).get();
    final goals = await (db.select(
      db.savingsGoals,
    )..where((c) => c.childId.equals('maya'))).get();
    final redemptions = await (db.select(
      db.rewardRedemptions,
    )..where((c) => c.childId.equals('maya'))).get();
    final badges = await (db.select(
      db.earnedBadges,
    )..where((c) => c.childId.equals('maya'))).get();
    final wardrobe = await (db.select(
      db.pipWardrobe,
    )..where((c) => c.childId.equals('maya'))).get();
    final quests = await (db.select(
      db.quests,
    )..where((q) => q.assigneeChildId.equals('maya'))).get();

    expect(
      completions,
      isEmpty,
      reason: 'P15-BUG-6: quest completions still exist',
    );
    expect(ledger, isEmpty, reason: 'P15-BUG-6: ledger entries still exist');
    expect(goals, isEmpty, reason: 'P15-BUG-6: savings goals still exist');
    expect(
      redemptions,
      isEmpty,
      reason: 'P15-BUG-6: reward redemptions still exist',
    );
    expect(badges, isEmpty, reason: 'P15-BUG-6: earned badges still exist');
    expect(wardrobe, isEmpty, reason: 'P15-BUG-6: Pip wardrobe still exists');
    expect(
      quests,
      isEmpty,
      reason: 'P15-BUG-6: quests are still assigned to a deleted child',
    );
  }); // P15-BUG-6 fixed (iteration 2): removeChild cascades

  // -- P15-BUG-7 ---------------------------------------------------------
  // After the remove, `active_child_id` still names the deleted row. The
  // family fallback masks it on this screen, but every kid-mode repository
  // reads `activeChildId ?? 'maya'` (pip, kid_shop, kid_jar, badges), so
  // downstream screens keep resolving the deleted child.

  testWidgets(
    'P15-BUG-7: the confirm-remove clears the stale active_child_id',
    (tester) async {
      final db = await setUpTestScope();
      await pumpAppRoute(tester, '/child-profile');

      await tester.tap(find.byKey(const Key('p15-remove')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NestButton, 'Remove'));
      await tester.pumpAndSettle();
      await _flushDrift(tester);
      await tester.pumpAndSettle();

      // Selection falls through to Leo (CHILD ORDER) ...
      expect(_profile(tester).child.id, 'leo');
      // ... but the persisted selection must move off the deleted child too.
      final state = await db.select(db.appState).getSingle();
      expect(
        state.activeChildId,
        isNot('maya'),
        reason:
            'P15-BUG-7: active_child_id still points at the deleted child '
            '(kid-mode repositories resolve it)',
      );

      await disposeApp(tester);
    },
  ); // P15-BUG-7 fixed (iteration 2): active_child_id moves off Maya

  // -- P15-BUG-8 ---------------------------------------------------------
  // `watchProfile` takes `DateTime.now()` (family_repository_impl.dart:102),
  // so a test that pins the seed to a day other than the machine's real date
  // loses the "done today" completions — exactly what happens to the whole
  // P15 suite on any real date after 2026-10-03. The established fix pattern
  // is `TodayRepositoryImpl`'s injectable clock
  // (`Seed.anchorOverride ?? DateTime.now().toUtc()`).

  test('P15-BUG-8: demo numbers must follow the pinned seed anchor', () async {
    Seed.anchorOverride = DateTime.utc(2020);
    addTearDown(() => Seed.anchorOverride = DateTime.utc(2026, 10, 3));

    final db = AppDatabase.memory();
    await Seed.demo(db);
    final repo = FamilyRepositoryImpl(db: db);

    final profile = await repo.watchProfile().first;

    // The seed's story day IS 2020-01-01 now; its "done today" daily
    // completions (q-dishwasher, q-table) must count for that day.
    expect(
      profile!.questsThisWeek,
      4,
      reason:
          'P15-BUG-8: period math used the wall clock, not the pinned '
          'seed anchor (got ${profile.questsThisWeek})',
    );
  }); // P15-BUG-8 fixed (iteration 2): injectable clock follows the anchor

  // -- P15-BUG-3 ---------------------------------------------------------

  test('P15-BUG-3: a repeated remove failure raises a fresh toast', () async {
    final repo = _MockFamilyRepository();
    when(repo.watchItems)
        .thenAnswer((_) => Stream.value(const <FamilyMember>[]));
    when(repo.watchChildren)
        .thenAnswer((_) => Stream.value(const <FamilyChild>[]));
    when(repo.watchProfile).thenAnswer((_) => Stream.value(null));
    when(() => repo.removeChild(any())).thenThrow(Exception('offline'));

    final bloc = FamilyBloc(repository: repo)..add(const FamilyLoadRequested());
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final seen = <String>[];
    final sub = bloc.stream.listen((s) {
      if (s.errorMessage != null) seen.add(s.errorMessage!);
    });
    bloc
      ..add(const FamilyRemoveChildRequested(childId: 'a'))
      ..add(const FamilyRemoveChildRequested(childId: 'b'));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await sub.cancel();

    expect(
      seen.length,
      2,
      reason:
          'P15-BUG-3: the second identical failure was suppressed as a '
          'duplicate state (got ${seen.length} message)',
    );
    await bloc.close();
  }); // P15-BUG-3 fixed (iteration 2): clear-then-raise re-emits
}
