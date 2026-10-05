// Current family single source of truth (shared/family_session).
//
// Product code must not read `Seed.familyId`; every repository takes the
// shared [CurrentFamily] holder (resolved from the one `families` row).
// This file proves a second family's rows are never read: after inserting
// `fam2` + child + quest, every repository still returns only `fam1` data.
// It also proves the fresh-install path: after wiping the database the
// holder keeps its id and [CurrentFamily.ensureFamily] recreates the row so
// onboarding can write again without a restart.

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/current_family.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/family/data/family_repository_impl.dart';
import 'package:nestling/features/kid_home/data/kid_home_repository_impl.dart';
import 'package:nestling/features/quests/data/quests_repository_impl.dart';
import 'package:nestling/features/today/data/today_repository_impl.dart';

Future<void> _insertSecondFamily(AppDatabase db) async {
  await db.into(db.families).insert(FamiliesCompanion.insert(id: 'fam2'));
  await db
      .into(db.children)
      .insert(
        ChildrenCompanion.insert(id: 'zoe', familyId: 'fam2', nickname: 'Zoe'),
      );
  await db
      .into(db.quests)
      .insert(
        QuestsCompanion.insert(
          id: 'q-other',
          familyId: 'fam2',
          title: 'Other family quest',
          assigneeChildId: const Value('zoe'),
        ),
      );
  await db
      .into(db.questCompletions)
      .insert(
        QuestCompletionsCompanion.insert(
          questId: 'q-other',
          childId: 'zoe',
          familyId: 'fam2',
        ),
      );
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

  test("repositories never read a second family's rows", () async {
    final current = await CurrentFamily.resolve(db);
    expect(current.familyId, 'fam1');

    await _insertSecondFamily(db);
    // The holder still points at the first family (one family per device).
    await current.refresh();
    expect(current.familyId, 'fam1');

    final familyRepo = FamilyRepositoryImpl(db: db, currentFamily: current);
    final children = await familyRepo.watchChildren().first;
    expect(children.map((c) => c.id), containsAll(<String>['maya', 'leo']));
    expect(children.map((c) => c.id), isNot(contains('zoe')));

    final todayRepo = TodayRepositoryImpl(db: db, currentFamily: current);
    final items = await todayRepo.watchItems().first;
    expect(items.map((i) => i.childId), everyElement(isNot('zoe')));
    expect(items.where((i) => i.childId == 'maya'), hasLength(6));

    final questsRepo = QuestsRepositoryImpl(db: db, currentFamily: current);
    final quests = await questsRepo.watchItems().first;
    expect(quests.map((q) => q.id), isNot(contains('q-other')));
    expect(quests, hasLength(12));

    final kidRepo = KidHomeRepositoryImpl(db: db, currentFamily: current);
    final profiles = await kidRepo.watchProfiles().first;
    expect(profiles.map((p) => p.id), containsAll(<String>['maya', 'leo']));
    expect(profiles.map((p) => p.id), isNot(contains('zoe')));
  });

  test(
    'fresh install after deletion resolves again via ensureFamily',
    () async {
      final current = await CurrentFamily.resolve(db);
      expect(current.familyId, 'fam1');

      // P16 delete → fresh install: every table emptied.
      await db.clearAll();
      // No rows: refresh keeps the previous id so onboarding recreates it.
      await current.refresh();
      expect(current.familyId, 'fam1');

      await current.ensureFamily();
      final rows = await db.select(db.families).get();
      expect(rows.map((r) => r.id), contains('fam1'));

      // Onboarding writes land in the recreated family.
      final familyRepo = FamilyRepositoryImpl(db: db, currentFamily: current);
      await familyRepo.addChild(
        nickname: 'Maya',
        ageBand: '7-9',
        avatarColour: 'lilac',
      );
      final children = await familyRepo.watchChildren().first;
      expect(children, hasLength(1));
      expect(children.single.nickname, 'Maya');
    },
  );
}
