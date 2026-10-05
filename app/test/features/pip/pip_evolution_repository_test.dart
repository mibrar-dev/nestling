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
import 'package:nestling/features/pip/domain/entities/pip_evolution.dart';

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

/// The production writes are status UPDATES, not inserts: P11 approves by
/// `status = 'approved' WHERE status = 'done_pending'` and denies with
/// `not_yet` (`approvals_repository_impl.dart:76-121`), and K05 re-does a
/// quest in its current period by flipping the newest `to_do`/`not_yet` row
/// to `done_pending` (`kid_home_repository_impl.dart:171-182`). [createdAt]
/// picks one row when a quest has several. Returns the rows changed, so a
/// test can prove exactly which row moved.
Future<int> _setStatus(
  AppDatabase db, {
  required String questId,
  required String childId,
  required String status,
  DateTime? createdAt,
}) {
  Expression<bool> row(QuestCompletions c) {
    return c.questId.equals(questId) &
        c.childId.equals(childId) &
        (createdAt == null
            ? const Constant(true)
            : c.createdAt.equals(createdAt));
  }

  return (db.update(
    db.questCompletions,
  )..where(row)).write(QuestCompletionsCompanion(status: Value(status)));
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

  // The two production writers on these numbers never INSERT a counted row:
  // K05 flips the newest `to_do`/`not_yet` row of the current period to
  // `done_pending`, and P11 then flips that row to `approved` (approve) or to
  // `not_yet` (decline). The existing suite above covers INSERTs, so these
  // pin the UPDATE paths — including the one that takes credit BACK.
  group('the production status updates', () {
    test('a re-done quest (to_do -> done_pending) counts +1', () async {
      expect((await repo.watchEvolution().first)!.questsDone, 4);
      final changed = await _setStatus(
        db,
        questId: 'q-reading',
        childId: 'maya',
        status: 'done_pending',
      );
      expect(changed, 1, reason: 'exactly the one `to_do` row moved');
      final after = (await repo.watchEvolution().first)!;
      expect(after.questsDone, 5);
      expect(after.questsFinishedCount, 5);
    });

    test(
      'approving it (done_pending -> approved) never double-counts',
      () async {
        // The exact write P11 makes (`status = 'approved' WHERE status =
        // 'done_pending'`). A `done_pending` row is already counted, so the
        // approval must move nothing — a screen that counted on transition
        // would jump from 4 to 5 and tell the child they helped twice.
        final changed = await _setStatus(
          db,
          questId: 'q-dishwasher',
          childId: 'maya',
          status: 'approved',
        );
        expect(changed, 1);
        final after = (await repo.watchEvolution().first)!;
        expect(after.questsDone, 4, reason: 'no double credit');
        expect(after.questsFinishedCount, 4);
      },
    );

    test(
      'declining it (done_pending -> not_yet) takes the credit back',
      () async {
        // The mirror, and the only path that makes the milestone go DOWN: the
        // count is derived live from the rows, never accumulated, so a
        // grown-up declining a completion cannot leave "Because you helped 4
        // times" standing on screen.
        final changed = await _setStatus(
          db,
          questId: 'q-table',
          childId: 'maya',
          status: 'not_yet',
        );
        expect(changed, 1);
        final after = (await repo.watchEvolution().first)!;
        expect(after.questsDone, 3);
        expect(after.questsFinishedCount, 3);
      },
    );

    test(
      'declining ONE of two rows for the same quest keeps it a quest done',
      () async {
        // q-bins re-completed (legal: a daily/weekly quest is repeatable) →
        // 5 helped times over 4 quests.
        await _addCompletion(
          db,
          questId: 'q-bins',
          childId: 'maya',
          status: 'approved',
        );
        expect((await repo.watchEvolution().first)!.questsDone, 5);

        final changed = await _setStatus(
          db,
          questId: 'q-bins',
          childId: 'maya',
          status: 'not_yet',
          createdAt: Seed.utc(10, 3, 8, 30),
        );
        expect(changed, 1, reason: 'only the newest row was declined');
        final after = (await repo.watchEvolution().first)!;
        // The other q-bins row is still `approved`, so the quest still counts
        // as done while the helped-times count drops: the two numbers move
        // independently and neither contradicts the other on screen.
        expect(after.questsDone, 4, reason: '"Because you helped 4 times"');
        expect(after.questsFinishedCount, 4, reason: '"4 quests done"');
      },
    );

    test('control: a status change between two uncounted values changes '
        'nothing', () async {
      // q-reading `to_do` -> `not_yet` (K05 cancelling a completion, and the
      // value P11's decline writes on a never-submitted row). The write is
      // live — the stream answers again — but both numbers hold, so the
      // celebration screen does not flicker.
      final emissions = <PipEvolution>[];
      final sub = repo.watchEvolution().listen((e) {
        if (e != null) emissions.add(e);
      });
      await _waitFor(() => emissions.isNotEmpty);
      expect(emissions.last.questsDone, 4);

      await _setStatus(
        db,
        questId: 'q-reading',
        childId: 'maya',
        status: 'not_yet',
      );
      await _waitFor(() => emissions.length >= 2);
      expect(emissions.last.questsDone, 4);
      expect(emissions.last.questsFinishedCount, 4);
      // `PipEvolution` is an Equatable value object, and every field is
      // unchanged, so the re-emission is `==` the first one — which is what
      // lets the bloc's state dedupe keep the celebration screen still
      // instead of rebuilding it on an unrelated table write.
      expect(emissions.last, emissions.first);
      await sub.cancel();
    });
  });
}
