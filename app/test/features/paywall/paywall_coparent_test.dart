// Shared batch 3 — the paywall co-parent name comes from the database.
//
// `paywall_view.dart` used to hard-code "Co-parent sharing, so James sees
// the same". The benefit line now reads the family's co-parent (the second
// parent member) through `PaywallRepository`: `Seed.demo` ships James, so
// the demo paywall names him; `fresh`/`empty` ship no co-parent, so the
// fallback ("... so everyone sees the same") renders. No mocks anywhere
// below — every assertion reads a real in-memory Drift database.

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/paywall/data/paywall_repository_impl.dart';

import '../../test_scope.dart';

Future<void> _inviteCoParent(AppDatabase db, String id, String name) {
  return db
      .into(db.members)
      .insert(
        MembersCompanion.insert(
          id: id,
          familyId: Seed.familyId,
          name: name,
          role: const Value('co-parent'),
          inviteStatus: const Value('invited'),
        ),
      );
}

void main() {
  group('PaywallRepository.readCoParentName (real Drift database)', () {
    test('demo seed reads the seeded co-parent James', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await Seed.demo(db);
      final repository = PaywallRepositoryImpl(db: db);

      expect(await repository.readCoParentName(), 'James');
    });

    test('fresh seed reads null (no co-parent)', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await Seed.fresh(db);
      final repository = PaywallRepositoryImpl(db: db);

      expect(await repository.readCoParentName(), isNull);
    });

    test('empty seed reads null (owner only)', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await Seed.empty(db);
      final repository = PaywallRepositoryImpl(db: db);

      expect(await repository.readCoParentName(), isNull);
    });

    test('an invited co-parent surfaces by name', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await Seed.fresh(db);
      final repository = PaywallRepositoryImpl(db: db);
      await _inviteCoParent(db, 'cp1', 'Aisha');

      expect(await repository.readCoParentName(), 'Aisha');
    });

    test('with two co-parents the first added wins', () async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      await Seed.fresh(db);
      final repository = PaywallRepositoryImpl(db: db);
      await _inviteCoParent(db, 'cp1', 'Aisha');
      await _inviteCoParent(db, 'cp2', 'Priya');

      expect(await repository.readCoParentName(), 'Aisha');
    });
  });

  group('paywall benefit 4 follows the database', () {
    testWidgets('demo paywall names the seeded co-parent', (tester) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.demo(db);
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/paywall');

      expect(currentPath(tester), '/paywall');
      expect(
        find.text('Co-parent sharing, so James sees the same'),
        findsOneWidget,
      );
      expect(
        find.text('Co-parent sharing, so everyone sees the same'),
        findsNothing,
      );

      await disposeApp(tester);
    });

    testWidgets('fresh paywall shows the no-co-parent fallback', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.fresh(db);
      await GetIt.instance<AppSession>().refresh();
      await pumpAppRoute(tester, '/paywall');

      expect(currentPath(tester), '/paywall');
      expect(
        find.text('Co-parent sharing, so everyone sees the same'),
        findsOneWidget,
      );
      expect(
        find.text('Co-parent sharing, so James sees the same'),
        findsNothing,
      );

      await disposeApp(tester);
    });
  });
}
