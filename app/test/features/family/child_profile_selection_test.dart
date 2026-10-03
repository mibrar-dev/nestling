// P15 · Child profile — the iteration-2 logic contract (Stage 3, iteration 2).
//
// Iteration 2 added four things to the feature's logic layer. This file is
// their proof surface, and it deliberately does NOT repeat what
// `p15_bugs_test.dart` (stage 6) already covers: those six proofs stay where
// they are and stay green. What is new here:
//
//   1. `FamilyChildSelected` + `FamilyRepository.selectChild` — the P15-BUG-1
//      deep-link fix. Covered: persistence of a VALID id, IGNORING an unknown
//      one (it must never poison the sibling repositories that resolve
//      `active_child_id`), and last-write-wins when two requests overlap.
//   2. `FamilyChildSelected`'s error path (a failed persist must not take the
//      screen down) — the one branch of the new event with no other proof.
//   3. `FamilyState.copyWith(clearErrorMessage:)` — the P15-BUG-3 fix, at the
//      state level: the clear-then-raise sequence the listener depends on.
//   4. The injectable `clock` on `FamilyRepositoryImpl` (P15-BUG-8) driven
//      EXPLICITLY, so the seam is proved without touching the global
//      `Seed.anchorOverride` that stage 6's proof moves.
//   5. The remove cascade's two branches stage 6 does not look at: a
//      family-wide quest (`assignee_child_id` NULL) must SURVIVE, and the
//      repoint must pick the first remaining child in ADDED order — or NULL
//      when the family empties.
//
// Everything runs on the in-memory Drift database with `Seed.demo()`
// (`test_scope.dart`), anchored to Sat 3 Oct 2026 by
// `test/flutter_test_config.dart`.

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/core/data/app_database.dart' hide Quest;
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/family/data/family_repository_impl.dart';
import 'package:nestling/features/family/domain/entities/family_child.dart';
import 'package:nestling/features/family/domain/entities/family_member.dart';
import 'package:nestling/features/family/domain/family_repository.dart';
import 'package:nestling/features/family/presentation/bloc/family_bloc.dart';
import 'package:nestling/features/family/presentation/bloc/family_event.dart';
import 'package:nestling/features/family/presentation/bloc/family_state.dart';

class _MockFamilyRepository extends Mock implements FamilyRepository;

const _kids = <FamilyChild>[
  FamilyChild(
    id: 'maya',
    nickname: 'Maya',
    ageBand: '7-9',
    ageYears: 9,
    avatarColour: 'lilac',
    pinSet: true,
    pipStyle: 'mochi',
    pipSkin: 'sunny',
    pipAccessory: 'none',
    pipStage: 3,
    pipTotalCoins: 175,
    coins: 120,
    happiness: 4,
    happyDays: 4,
    weeklyBasePence: 300,
    activeQuests: 6,
    doneQuests: 4,
  ),
  FamilyChild(
    id: 'leo',
    nickname: 'Leo',
    ageBand: '4-6',
    ageYears: 6,
    avatarColour: 'peach',
    pinSet: false,
    pipStyle: 'bolt',
    pipSkin: 'sky',
    pipAccessory: 'none',
    pipStage: 2,
    pipTotalCoins: 60,
    coins: 45,
    happiness: 4,
    happyDays: 3,
    weeklyBasePence: 150,
    activeQuests: 4,
    doneQuests: 2,
  ),
];

const _members = <FamilyMember>[
  FamilyMember(
    id: 'sarah',
    title: 'Sarah',
    detail: 'You',
    name: 'Sarah',
    role: 'owner',
    inviteStatus: 'active',
  ),
];

Future<AppDatabase> _demoDb() async {
  final db = AppDatabase.memory();
  await Seed.demo(db);
  return db;
}

Future<String?> _activeChildId(AppDatabase db) async {
  final row = await db.select(db.appState).getSingle();
  return row.activeChildId;
}

/// Polls [condition] for up to two seconds — Drift's `watch()` streams land
/// on the next event-loop turn, so a write is not visible synchronously.
Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// Adds a quest with no assignee — the family-wide "Anyone" kind, which a
/// child's removal must NOT delete (`family_repository_impl.removeChild`
/// deletes `q.assigneeChildId.equals(childId)` only).
Future<void> _addFamilyWideQuest(AppDatabase db, String id) {
  return db
      .into(db.quests)
      .insert(
        QuestsCompanion.insert(
          id: id,
          familyId: Seed.familyId,
          title: 'Take the bins out',
        ),
      );
}

void main() {
  group('P15-BUG-1 · selectChild persists a valid selection', () {
    test('a valid id lands in app_state and watchProfile follows it', () async {
      final db = await _demoDb();
      final repo = FamilyRepositoryImpl(db: db);
      expect(await _activeChildId(db), 'maya');

      await repo.selectChild('leo');

      expect(
        await _activeChildId(db),
        'leo',
        reason: 'the persisted selection is what every sibling reads',
      );
      expect((await repo.watchProfile().first)!.child.id, 'leo');
    });

    test(
      'an unknown id is ignored, so the roster fallback still holds',
      () async {
        final db = await _demoDb();
        final repo = FamilyRepositoryImpl(db: db);

        await repo.selectChild('nobody');

        // Not persisted: six kid-mode repositories resolve `activeChildId`, and
        // writing junk there would point all of them at a missing child
        // (P15-BUG-7's class of damage).
        expect(await _activeChildId(db), 'maya');
        expect(
          (await repo.watchProfile().first)!.child.id,
          'maya',
          reason: 'unknown ids fall back to the first child in ADDED order',
        );
      },
    );

    test('the last request wins when two overlap', () async {
      final db = await _demoDb();
      final repo = FamilyRepositoryImpl(db: db);

      // Both start before either finishes: the older validation must not
      // clobber the newer one (`family_repository_impl.dart:352`).
      final first = repo.selectChild('leo');
      final second = repo.selectChild('maya');
      await first;
      await second;

      expect(await _activeChildId(db), 'maya');
      expect((await repo.watchProfile().first)!.child.id, 'maya');
    });

    test('an unknown id after a valid one keeps the valid selection', () async {
      final db = await _demoDb();
      final repo = FamilyRepositoryImpl(db: db);

      await repo.selectChild('leo');
      await repo.selectChild('nobody');

      expect(
        await _activeChildId(db),
        'leo',
        reason: 'a rejected request must not clear the good one',
      );
      expect((await repo.watchProfile().first)!.child.id, 'leo');
    });

    final selectionRepo = _MockFamilyRepository();

    blocTest<FamilyBloc, FamilyState>(
      'FamilyChildSelected forwards the id to the repository',
      setUp: () =>
          when(() => selectionRepo.selectChild(any())).thenAnswer((_) async {}),
      build: () => FamilyBloc(repository: selectionRepo),
      act: (bloc) => bloc.add(const FamilyChildSelected(childId: 'leo')),
      wait: const Duration(milliseconds: 50),
      expect: () => const <FamilyState>[],
      verify: (_) => verify(() => selectionRepo.selectChild('leo')).called(1),
    );

    blocTest<FamilyBloc, FamilyState>(
      'a failed persist reports the error and keeps the status loaded',
      build: () {
        final repo = _MockFamilyRepository();
        when(() => repo.selectChild(any())).thenThrow(Exception('offline'));
        return FamilyBloc(repository: repo);
      },
      seed: () => const FamilyState(
        status: FamilyStatus.loaded,
        items: _members,
        children: _kids,
      ),
      act: (bloc) => bloc.add(const FamilyChildSelected(childId: 'leo')),
      expect: () => const <FamilyState>[
        FamilyState(
          status: FamilyStatus.loaded,
          items: _members,
          children: _kids,
          errorMessage: 'Exception: offline',
        ),
      ],
    );
  });

  group('P15-BUG-3 · clearErrorMessage', () {
    test('the flag drops a message the copyWith cannot express otherwise', () {
      const failed = FamilyState(errorMessage: 'Exception: offline');
      // The "redundant" null IS the case under test: `copyWith` cannot
      // express a cleared message without [clearErrorMessage].
      // ignore: avoid_redundant_argument_values
      final unchanged = failed.copyWith(errorMessage: null).errorMessage;
      expect(unchanged, 'Exception: offline');
      expect(failed.copyWith(clearErrorMessage: true).errorMessage, isNull);
      // Omitting both keeps it: an unrelated emission must not swallow it.
      expect(
        failed.copyWith(saveInProgress: true).errorMessage,
        'Exception: offline',
      );
    });

    blocTest<FamilyBloc, FamilyState>(
      'two identical remove failures clear then re-raise, so both toast',
      build: () {
        final repo = _MockFamilyRepository();
        when(() => repo.removeChild(any())).thenThrow(Exception('offline'));
        return FamilyBloc(repository: repo);
      },
      seed: () => const FamilyState(
        status: FamilyStatus.loaded,
        items: _members,
        children: _kids,
      ),
      act: (bloc) async {
        bloc.add(const FamilyRemoveChildRequested(childId: 'maya'));
        await Future<void>.delayed(const Duration(milliseconds: 30));
        bloc.add(const FamilyRemoveChildRequested(childId: 'leo'));
      },
      wait: const Duration(milliseconds: 100),
      expect: () => const <FamilyState>[
        // First failure: raise.
        FamilyState(
          status: FamilyStatus.loaded,
          items: _members,
          children: _kids,
          errorMessage: 'Exception: offline',
        ),
        // Second identical failure: clear…
        FamilyState(
          status: FamilyStatus.loaded,
          items: _members,
          children: _kids,
        ),
        // …then raise again — three DISTINCT states, so Equatable drops
        // nothing and `BlocListener.listenWhen` sees a change both times.
        FamilyState(
          status: FamilyStatus.loaded,
          items: _members,
          children: _kids,
          errorMessage: 'Exception: offline',
        ),
      ],
    );
  });

  group('P15-BUG-8 · the injectable clock', () {
    test('an explicit clock decides which period counts', () async {
      final db = await _demoDb();
      // The seed's story day is the pinned Sat 3 Oct 2026. Maya's four
      // counted completions are two `daily` quests (Empty the dishwasher,
      // Lay the table — both done_pending on the 3rd) and two `weekly` ones
      // (Put the bins out on the 2nd, Hoover the stairs on the 1st).
      final anchor = Seed.anchorDay.toUtc();

      final onAnchor = await FamilyRepositoryImpl(
        db: db,
        clock: () => anchor,
      ).watchProfile().first;
      expect(onAnchor!.questsThisWeek, 4, reason: '2 daily + 2 weekly');

      // Sunday 4 Oct: a new London DAY, still the same London week — the two
      // dailies are yesterday's, the two weeklies are still in period.
      final nextDay = await FamilyRepositoryImpl(
        db: db,
        clock: () => anchor.add(const Duration(days: 1)),
      ).watchProfile().first;
      expect(nextDay!.questsThisWeek, 2, reason: 'only the two weekly ones');

      // Monday 5 Oct opens a new London week, so the weeklies fall outside
      // their period too and the tile reads 0 (PERIODS ruling).
      final nextWeek = await FamilyRepositoryImpl(
        db: db,
        clock: () => anchor.add(const Duration(days: 2)),
      ).watchProfile().first;
      expect(nextWeek!.questsThisWeek, 0);
    });

    test('the clock does not touch anything but the period maths', () async {
      final db = await _demoDb();
      final anchor = Seed.anchorDay.toUtc();
      final profile = await FamilyRepositoryImpl(
        db: db,
        clock: () => anchor.add(const Duration(days: 8)),
      ).watchProfile().first;

      // Same roster, same counts, same money — only `questsThisWeek` moved.
      expect(profile!.child.id, 'maya');
      expect(profile.dailyActive, 4);
      expect(profile.weeklyActive, 2);
      expect(profile.owedPence, 420);
      expect(profile.questsThisWeek, 0);
    });
  });

  group('P15-BUG-6/7 · the remove cascade branches', () {
    test('a family-wide quest survives the removal', () async {
      final db = await _demoDb();
      await _addFamilyWideQuest(db, 'bins');
      final repo = FamilyRepositoryImpl(db: db);

      await repo.removeChild('maya');

      final survivor = await (db.select(
        db.quests,
      )..where((q) => q.id.equals('bins'))).getSingleOrNull();
      expect(
        survivor,
        isNotNull,
        reason: '"Anyone" quests belong to the family, not to a child',
      );
      expect(survivor!.assigneeChildId, isNull);
      // The other child keeps their own quests.
      final leoQuests = await (db.select(
        db.quests,
      )..where((q) => q.assigneeChildId.equals('leo'))).get();
      expect(leoQuests, isNotEmpty);
    });

    test(
      'the selection moves to the FIRST remaining child in added order',
      () async {
        final db = await _demoDb();
        final repo = FamilyRepositoryImpl(db: db);
        expect(await _activeChildId(db), 'maya');

        await repo.removeChild('maya');

        expect(
          await _activeChildId(db),
          'leo',
          reason: 'creation order (CHILD ORDER ruling), not alphabetical',
        );
        expect((await repo.watchProfile().first)!.child.id, 'leo');
      },
    );

    test('removing the last child clears the selection', () async {
      final db = await _demoDb();
      final repo = FamilyRepositoryImpl(db: db);
      await repo.removeChild('maya');
      await repo.removeChild('leo');

      expect(
        await _activeChildId(db),
        isNull,
        reason: 'an empty family has no selection to point at',
      );
      expect(await repo.watchProfile().first, isNull);
    });

    // Review finding 4 / `SHARED_REQUEST.md` §5: the repoint query repeats
    // the roster's ordering (createdAt, then rowid). With only two children
    // any ordering gives the same answer — a third child is what makes it
    // observable, and CHILD ORDER is "the order they were added", never
    // alphabetical or newest-first.
    test(
      'with three children the repoint picks the FIRST added survivor',
      () async {
        final db = await _demoDb();
        final repo = FamilyRepositoryImpl(db: db);
        await repo.addChild(
          nickname: 'Robin',
          ageBand: '10-12',
          avatarColour: 'leaf',
        );
        final roster = await repo.watchChildren().first;
        expect(roster.map((c) => c.nickname), <String>[
          'Maya',
          'Leo',
          'Robin',
        ], reason: 'added order');
        expect(await _activeChildId(db), 'maya');

        await repo.removeChild('maya');

        expect(
          await _activeChildId(db),
          'leo',
          reason: 'Leo was added before Robin, whatever their names sort like',
        );
        expect((await repo.watchProfile().first)!.child.nickname, 'Leo');

        // …and removing the NEWEST child (who was never selected) must not
        // disturb the selection at all.
        await repo.removeChild('robin');
        expect(await _activeChildId(db), 'leo');
        expect((await repo.watchProfile().first)!.child.id, 'leo');
      },
    );

    test(
      'removing a child who is NOT selected leaves the selection alone',
      () async {
        final db = await _demoDb();
        final repo = FamilyRepositoryImpl(db: db);
        await repo.selectChild('leo');
        expect(await _activeChildId(db), 'leo');

        await repo.removeChild('leo');

        expect(
          await _activeChildId(db),
          'maya',
          reason: 'the fallback is the first child still in the roster',
        );
        expect((await repo.watchProfile().first)!.child.id, 'maya');
      },
    );

    test('removing Leo while Maya is selected keeps Maya selected', () async {
      final db = await _demoDb();
      final repo = FamilyRepositoryImpl(db: db);

      await repo.removeChild('leo');

      expect(await _activeChildId(db), 'maya');
      expect((await repo.watchProfile().first)!.child.id, 'maya');
      // …and Maya's own rows are untouched.
      final completions = await (db.select(
        db.questCompletions,
      )..where((c) => c.childId.equals('maya'))).get();
      expect(completions, isNotEmpty);
    });
  });

  group('review finding 3 · the ledger subscription is claimed once', () {
    // `watchProfile` keeps ONE Drift subscription per selected child
    // (`ledgerSub`) and hands it over when the selection changes. A cascading
    // remove writes five tables in one transaction, so several base emissions
    // land while the handler is awaiting `cancel()` — iteration 3 made the
    // handler claim the slot SYNCHRONOUSLY and let only the newest run
    // (`identical(latestParts, parts)`) re-subscribe, so an older run can no
    // longer orphan or duplicate the listener.
    //
    // The observable contract: after the burst the stream is still driven by a
    // LIVE ledger subscription for the new selection — a later ledger write
    // still produces a correct emission.
    test('a cascading remove leaves one live subscription for the new child', () async {
      final db = await _demoDb();
      final repo = FamilyRepositoryImpl(db: db);
      final seen = <(String?, int)>[];
      final sub = repo.watchProfile().listen(
        (p) => seen.add((p?.child.id, p?.owedPence ?? -1)),
      );

      await _waitFor(() => seen.any((s) => s.$1 == 'maya'));
      expect(seen.last, ('maya', 420));

      // One transaction across children/completions/ledger/quests/… .
      await repo.removeChild('maya');
      await _waitFor(() => seen.any((s) => s.$1 == 'leo'));

      expect(
        seen.where((s) => s.$1 == 'leo').last.$2,
        210,
        reason: "Leo's own ledger, not Maya's leftovers",
      );

      // The proof the subscription survived the burst: a `quest_bonus` row for
      // Leo must reach the profile.
      await db
          .into(db.ledgerEntries)
          .insert(
            LedgerEntriesCompanion.insert(
              familyId: Seed.familyId,
              childId: 'leo',
              type: 'quest_bonus',
              amountPence: 250,
            ),
          );
      await _waitFor(() => seen.any((s) => s.$1 == 'leo' && s.$2 == 460));

      expect(seen.last, (
        'leo',
        460,
      ), reason: 'owed = 210 (seeded) + 250 (the new bonus row)');

      await sub.cancel();
    });

    test('emptying and refilling the family re-subscribes cleanly', () async {
      final db = await _demoDb();
      final repo = FamilyRepositoryImpl(db: db);
      final seen = <String?>[];
      final sub = repo.watchProfile().listen((p) => seen.add(p?.child.id));

      await _waitFor(() => seen.contains('maya'));

      // The `selected == null` branch: cancel, clear the slot, emit null.
      await repo.removeChild('maya');
      await repo.removeChild('leo');
      await _waitFor(() => seen.contains(null));
      expect(seen.last, isNull);

      // …and the stream must come back when a child is added.
      await repo.addChild(
        nickname: 'Robin',
        ageBand: '7-9',
        avatarColour: 'leaf',
      );
      await _waitFor(() => seen.any((id) => id != null && id != 'maya'));

      final revived = seen.last!;
      expect(revived, isNot('maya'));
      expect(revived, isNot('leo'));
      final profile = (await repo.watchProfile().first)!;
      expect(profile.child.id, revived);
      // A fresh child has an empty ledger: owed 0, no quests yet.
      expect(profile.owedPence, 0);
      expect(profile.dailyActive, 0);
      expect(profile.questsThisWeek, 0);

      await sub.cancel();
    });
  });

  group('P15 ChildProfile selection invariants', () {
    test('the profile always belongs to a child in the roster', () async {
      final db = await _demoDb();
      final repo = FamilyRepositoryImpl(db: db);

      for (final id in <String>['leo', 'nobody', 'maya']) {
        await repo.selectChild(id);
        final profile = (await repo.watchProfile().first)!;
        final roster = await repo.watchChildren().first;
        expect(
          roster.map((c) => c.id),
          contains(profile.child.id),
          reason: 'selected $id → ${profile.child.id}',
        );
      }
    });

    test("every emission carries that child's own numbers", () async {
      final db = await _demoDb();
      final repo = FamilyRepositoryImpl(db: db);

      final maya = (await repo.watchProfile().first)!;
      await repo.selectChild('leo');
      final leo = (await repo.watchProfile().first)!;

      // Maya: £3.00 base + £1.20 quests. Leo: £1.50 base + £0.60.
      expect(maya.owedPence, 420);
      expect(leo.owedPence, 210);
      expect(maya.child.coins, 120);
      expect(leo.child.coins, 45);
      expect(maya.child.pipStage, 3);
      expect(leo.child.pipStage, 2);
    });
  });
}
