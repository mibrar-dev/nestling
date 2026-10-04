// K07 repository tests (DB-backed, Seed.demo): the evolution contract.
//
// `watchEvolution` emits the active child's profile plus their lifetime
// helped-times count (`done_pending` + `approved`, all time — the PERIODS
// ruling does NOT apply; `to_do` and `not_yet` never count). Maya emits
// `{stage 3, totalCoins 175, coins 120, questsDone 4}` (dishwasher + table
// pending, bins + hoover approved); Leo emits `{stage 2, totalCoins 60,
// questsDone 2}`.

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/pip/data/pip_repository_impl.dart';

Future<void> _setActiveChild(AppDatabase db, String? childId) async {
  await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
    AppStateCompanion(activeChildId: Value(childId)),
  );
}

Future<void> _addCompletion(
  AppDatabase db, {
  required String questId,
  required String childId,
  required String status,
}) async {
  await db
      .into(db.questCompletions)
      .insert(
        QuestCompletionsCompanion.insert(
          questId: questId,
          childId: childId,
          familyId: Seed.familyId,
          status: Value(status),
          coins: const Value(10),
          createdAt: Value(Seed.utc(10, 3, 8, 30)),
          createdAtTz: const Value('Europe/London'),
        ),
      );
}

/// Waits (real async) until [ready] holds, up to ~3 s. The per-test
/// `--timeout 120s` still bounds any hang.
Future<void> _waitFor(bool Function() ready) async {
  for (var i = 0; i < 300 && !ready(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(ready(), isTrue, reason: 'the evolution did not re-emit');
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

  group('watchEvolution', () {
    test('emits Maya profile with the seed truth', () async {
      final evolution = await repo.watchEvolution().first;
      expect(evolution, isNotNull);
      final profile = evolution!.profile;
      expect(profile.childId, 'maya');
      expect(profile.nickname, 'Maya');
      expect(profile.style, 'mochi');
      expect(profile.skin, 'sunny');
      expect(profile.accessory, 'none');
      expect(profile.stage, 3);
      expect(profile.totalCoins, 175);
      expect(profile.coins, 120);
      // Dishwasher + table pending, bins + hoover approved.
      expect(evolution.questsDone, 4);
    });

    test('follows the active child (maya -> leo)', () async {
      expect((await repo.watchEvolution().first)!.questsDone, 4);

      await _setActiveChild(db, 'leo');
      final leo = await repo.watchEvolution().first;
      expect(leo, isNotNull);
      expect(leo!.profile.childId, 'leo');
      expect(leo.profile.nickname, 'Leo');
      expect(leo.profile.style, 'bolt');
      expect(leo.profile.skin, 'sky');
      expect(leo.profile.stage, 2);
      expect(leo.profile.totalCoins, 60);
      // Bed pending, bag approved.
      expect(leo.questsDone, 2);
    });

    test('an approved completion re-emits with +1', () async {
      // One live subscription: the initial emission is observed BEFORE the
      // insert, so the re-emit cannot be mistaken for (or swallowed by) it.
      final emissions = <int>[];
      final sub = repo.watchEvolution().listen((e) {
        if (e != null) emissions.add(e.questsDone);
      });
      await _waitFor(() => emissions.isNotEmpty);
      expect(emissions.last, 4);

      await _addCompletion(
        db,
        questId: 'q-reading',
        childId: 'maya',
        status: 'approved',
      );
      await _waitFor(() => emissions.length >= 2);
      expect(emissions.last, 5);
      await sub.cancel();
    });

    test('a done_pending completion re-emits with +1', () async {
      final emissions = <int>[];
      final sub = repo.watchEvolution().listen((e) {
        if (e != null) emissions.add(e.questsDone);
      });
      await _waitFor(() => emissions.isNotEmpty);
      expect(emissions.last, 4);

      await _addCompletion(
        db,
        questId: 'q-tidy',
        childId: 'maya',
        status: 'done_pending',
      );
      await _waitFor(() => emissions.length >= 2);
      expect(emissions.last, 5);
      await sub.cancel();
    });

    test('to_do and not_yet rows never count', () async {
      await _addCompletion(
        db,
        questId: 'q-tidy',
        childId: 'maya',
        status: 'to_do',
      );
      await _addCompletion(
        db,
        questId: 'q-reading',
        childId: 'maya',
        status: 'not_yet',
      );
      expect((await repo.watchEvolution().first)!.questsDone, 4);
    });

    test('the milestone card counts DISTINCT quests, the sub-line counts rows '
        '(6_bugs.md K07-BUG-3)', () async {
      // Demo truth: 4 completion rows over 4 distinct quests.
      final first = (await repo.watchEvolution().first)!;
      expect(first.questsDone, 4);
      expect(first.questsFinished, 4);
      expect(first.questsFinishedCount, 4);

      // A second `approved` row for q-bins — legal in the schema and routine in
      // the product, because a daily/weekly quest is re-completable.
      await _addCompletion(
        db,
        questId: 'q-bins',
        childId: 'maya',
        status: 'approved',
      );
      final second = (await repo.watchEvolution().first)!;
      expect(second.questsDone, 5, reason: '"Because you helped 5 times"');
      expect(
        second.questsFinishedCount,
        4,
        reason: '"4 quests done" — the milestone is about quests, not rows',
      );
    });

    test('null active child emits null', () async {
      await _setActiveChild(db, null);
      expect(await repo.watchEvolution().first, isNull);
    });

    test('unknown active child id emits null', () async {
      await _setActiveChild(db, 'nope');
      expect(await repo.watchEvolution().first, isNull);
    });

    test('another child’s completions do not leak in', () async {
      await _addCompletion(
        db,
        questId: 'q-biscuit',
        childId: 'leo',
        status: 'approved',
      );
      expect((await repo.watchEvolution().first)!.questsDone, 4);
    });
  });
}
