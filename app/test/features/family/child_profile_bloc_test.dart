import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/family/data/family_repository_impl.dart';
import 'package:nestling/features/family/domain/entities/child_profile.dart';
import 'package:nestling/features/family/domain/entities/family_child.dart';
import 'package:nestling/features/family/domain/entities/family_member.dart';
import 'package:nestling/features/family/domain/family_repository.dart';
import 'package:nestling/features/family/presentation/bloc/family_bloc.dart';
import 'package:nestling/features/family/presentation/bloc/family_event.dart';
import 'package:nestling/features/family/presentation/bloc/family_state.dart';

class _MockFamilyRepository extends Mock implements FamilyRepository;

/// `FamilyAddChildRequested.onSaved` needs a callback; the profile path does
/// not care which one, and a top-level tear-off is a compile-time constant.
void _noop() {}

const _maya = FamilyChild(
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
);

const _leo = FamilyChild(
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
);

const _kids = <FamilyChild>[_maya, _leo];

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

const _mayaProfile = ChildProfile(
  child: _maya,
  questsThisWeek: 4,
  dailyActive: 4,
  weeklyActive: 2,
  onceActive: 0,
  owedPence: 420,
);

Future<AppDatabase> _demoDb() async {
  final db = AppDatabase.memory();
  await Seed.demo(db);
  return db;
}

Future<void> _setActiveChild(AppDatabase db, String? childId) {
  return (db.update(db.appState)..where((a) => a.id.equals(1))).write(
    AppStateCompanion(activeChildId: Value<String?>(childId)),
  );
}

/// Polls [condition] for up to two seconds — Drift's `watch()` streams land
/// on the next event-loop turn, so a write is not visible synchronously.
Future<void> _waitFor(bool Function() condition) async {
  for (var i = 0; i < 200 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

/// Appends one Maya completion on a quest with the given repeat rule, dated
/// [at]. Used to prove the PERIODS ruling from the orchestrator: a quest
/// counts only for its own current period.
Future<void> _completeQuest(
  AppDatabase db, {
  required String repeat,
  required DateTime at,
  String status = 'approved',
}) async {
  final questId =
      await (db.select(db.quests)
            ..where(
              (q) =>
                  q.assigneeChildId.equals('maya') &
                  q.repeatRule.equals(repeat) &
                  q.active.equals(true),
            )
            ..limit(1))
          .map((q) => q.id)
          .getSingle();
  await db
      .into(db.questCompletions)
      .insert(
        QuestCompletionsCompanion.insert(
          questId: questId,
          childId: 'maya',
          familyId: Seed.familyId,
          status: Value(status),
          createdAt: Value(at),
        ),
      );
}

void main() {
  group('ChildProfile entity', () {
    test('equality covers every field', () {
      expect(
        _mayaProfile,
        const ChildProfile(
          child: _maya,
          questsThisWeek: 4,
          dailyActive: 4,
          weeklyActive: 2,
          onceActive: 0,
          owedPence: 420,
        ),
      );
      expect(
        _mayaProfile,
        isNot(
          const ChildProfile(
            child: _maya,
            questsThisWeek: 3,
            dailyActive: 4,
            weeklyActive: 2,
            onceActive: 0,
            owedPence: 420,
          ),
        ),
      );
    });
  });

  group('FamilyRepository.watchProfile (real database, demo seed)', () {
    test('selects the activeChildId child with the demo numbers', () async {
      final db = await _demoDb();
      final repo = FamilyRepositoryImpl(db: db);

      final profile = await repo.watchProfile().first;

      expect(profile, isNotNull);
      expect(profile!.child.id, 'maya');
      expect(profile.child.nickname, 'Maya');
      // 6 active quests: 4 daily, 2 weekly, 0 one-off.
      expect(profile.dailyActive, 4);
      expect(profile.weeklyActive, 2);
      expect(profile.onceActive, 0);
      // done_pending + approved completions in the current London period.
      expect(profile.questsThisWeek, 4);
      // £3.00 base + £1.20 quests, matching the P12 ledger math.
      expect(profile.owedPence, 420);
    });

    test('falls back to the first-created child when unset', () async {
      final db = await _demoDb();
      await _setActiveChild(db, null);
      final repo = FamilyRepositoryImpl(db: db);

      final profile = await repo.watchProfile().first;

      // Creation order (CHILD ORDER ruling): Maya before Leo.
      expect(profile?.child.id, 'maya');
    });

    test('falls back to the first-created child when unknown', () async {
      final db = await _demoDb();
      await _setActiveChild(db, 'nope');
      final repo = FamilyRepositoryImpl(db: db);

      final profile = await repo.watchProfile().first;

      expect(profile?.child.id, 'maya');
    });

    test('follows activeChildId switches (leo)', () async {
      final db = await _demoDb();
      await _setActiveChild(db, 'leo');
      final repo = FamilyRepositoryImpl(db: db);

      final profile = await repo.watchProfile().first;

      expect(profile?.child.id, 'leo');
      expect(profile?.owedPence, 210);
    });

    test('is null when there are no children', () async {
      final db = AppDatabase.memory();
      await Seed.fresh(db);
      final repo = FamilyRepositoryImpl(db: db);

      expect(await repo.watchProfile().first, isNull);
    });

    test('follows an activeChildId switch mid-stream', () async {
      final db = await _demoDb();
      final repo = FamilyRepositoryImpl(db: db);
      final seen = <String?>[];
      final sub = repo.watchProfile().listen((p) => seen.add(p?.child.id));

      await _waitFor(() => seen.contains('maya'));
      await _setActiveChild(db, 'leo');
      await _waitFor(() => seen.contains('leo'));

      // Maya (active) → Leo without re-subscribing: the selection follows
      // `app_state` and the ledger subscription switches with it.
      expect(seen, <String?>['maya', 'leo']);

      await sub.cancel();
    });

    test('questsThisWeek follows the PERIODS ruling', () async {
      final db = await _demoDb();
      final repo = FamilyRepositoryImpl(db: db);
      expect((await repo.watchProfile().first)!.questsThisWeek, 4);

      // An in-period approval counts…
      await _completeQuest(db, repeat: 'daily', at: DateTime.now().toUtc());
      expect((await repo.watchProfile().first)!.questsThisWeek, 5);

      // …a completion from an earlier period does not (daily → the current
      // Europe/London day, weekly → the current London week).
      await _completeQuest(
        db,
        repeat: 'daily',
        at: DateTime.now().toUtc().subtract(const Duration(days: 3)),
      );
      expect((await repo.watchProfile().first)!.questsThisWeek, 5);
    });

    test('rejected completions never count', () async {
      final db = await _demoDb();
      final repo = FamilyRepositoryImpl(db: db);
      final before = (await repo.watchProfile().first)!.questsThisWeek;

      await _completeQuest(
        db,
        repeat: 'daily',
        at: DateTime.now().toUtc(),
        status: 'not_yet',
      );

      expect((await repo.watchProfile().first)!.questsThisWeek, before);
    });
  });

  group('FamilyBloc profile (mock repository)', () {
    blocTest<FamilyBloc, FamilyState>(
      'load emits members, children and the profile together',
      build: () {
        final repo = _MockFamilyRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
        when(repo.watchChildren).thenAnswer((_) => Stream.value(_kids));
        when(repo.watchProfile).thenAnswer((_) => Stream.value(_mayaProfile));
        return FamilyBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const FamilyLoadRequested()),
      expect: () => const <FamilyState>[
        FamilyState(status: FamilyStatus.loading),
        FamilyState(
          status: FamilyStatus.loaded,
          items: _members,
          children: _kids,
          profile: _mayaProfile,
        ),
      ],
    );

    blocTest<FamilyBloc, FamilyState>(
      'a later profile emission replaces the previous one',
      build: () {
        final repo = _MockFamilyRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
        when(repo.watchChildren).thenAnswer((_) => Stream.value(_kids));
        when(repo.watchProfile).thenAnswer(
          (_) => Stream.fromIterable(const <ChildProfile?>[_mayaProfile, null]),
        );
        return FamilyBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const FamilyLoadRequested()),
      expect: () => const <FamilyState>[
        FamilyState(status: FamilyStatus.loading),
        FamilyState(
          status: FamilyStatus.loaded,
          items: _members,
          children: _kids,
          profile: _mayaProfile,
        ),
        FamilyState(
          status: FamilyStatus.loaded,
          items: _members,
          children: _kids,
        ),
      ],
    );

    test('remove calls removeChild with the child id', () async {
      final repo = _MockFamilyRepository();
      when(() => repo.removeChild(any())).thenAnswer((_) async {});
      final bloc = FamilyBloc(repository: repo)
        ..add(const FamilyRemoveChildRequested(childId: 'maya'));
      // A successful remove emits nothing itself: the watch streams re-emit.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      verify(() => repo.removeChild('maya')).called(1);
      await bloc.close();
    });

    blocTest<FamilyBloc, FamilyState>(
      'remove failure keeps loaded status with a message',
      build: () {
        final repo = _MockFamilyRepository();
        when(() => repo.removeChild(any())).thenThrow(Exception('offline'));
        return FamilyBloc(repository: repo);
      },
      seed: () => const FamilyState(
        status: FamilyStatus.loaded,
        items: _members,
        children: _kids,
        profile: _mayaProfile,
      ),
      act: (bloc) => bloc.add(const FamilyRemoveChildRequested(childId: 'x')),
      expect: () => const <FamilyState>[
        FamilyState(
          status: FamilyStatus.loaded,
          items: _members,
          children: _kids,
          profile: _mayaProfile,
          errorMessage: 'Exception: offline',
        ),
      ],
    );

    // P15's own stream, not the P05 roster: `watchProfile` is a separate
    // combine branch (`family_bloc.dart:33-37`), so it can fail on its own.
    blocTest<FamilyBloc, FamilyState>(
      'an error on the profile stream alone is still a failure',
      build: () {
        final repo = _MockFamilyRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
        when(repo.watchChildren).thenAnswer((_) => Stream.value(_kids));
        when(repo.watchProfile).thenAnswer(
          (_) => Stream<ChildProfile?>.error(Exception('profile offline')),
        );
        return FamilyBloc(repository: repo);
      },
      act: (bloc) => bloc.add(const FamilyLoadRequested()),
      expect: () => [
        const FamilyState(status: FamilyStatus.loading),
        predicate<FamilyState>(
          (s) =>
              s.status == FamilyStatus.failure &&
              (s.errorMessage ?? '').contains('profile offline'),
        ),
      ],
    );

    blocTest<FamilyBloc, FamilyState>(
      'a second load after a failure recovers (Try again)',
      build: () {
        final repo = _MockFamilyRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
        when(repo.watchChildren).thenAnswer((_) => Stream.value(_kids));
        var attempts = 0;
        when(repo.watchProfile).thenAnswer((_) {
          attempts++;
          return attempts == 1
              ? Stream<ChildProfile?>.error(Exception('offline'))
              : Stream<ChildProfile?>.value(_mayaProfile);
        });
        return FamilyBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const FamilyLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const FamilyLoadRequested());
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        predicate<FamilyState>((s) => s.status == FamilyStatus.loading),
        predicate<FamilyState>(
          (s) =>
              s.status == FamilyStatus.failure &&
              (s.errorMessage ?? '').contains('offline'),
        ),
        predicate<FamilyState>((s) => s.status == FamilyStatus.loading),
        // The retry really recovers: loaded, with the profile back. The
        // stale `errorMessage` it drags along is BUG P15-BUG-3, asserted
        // separately so this test proves recovery, not message hygiene.
        predicate<FamilyState>(
          (s) => s.status == FamilyStatus.loaded && s.profile == _mayaProfile,
        ),
      ],
    );

    // ── BUG P15-BUG-3 (failing repro — do not "fix" the test) ──────────────
    // P12 hit exactly this and fixed it: its `copyWith` has a
    // `clearErrorMessage` flag because "copyWith cannot express null
    // otherwise", and the load path passes it on EVERY emission
    // (`pocket_money_state.dart:48-58`, `pocket_money_bloc.dart:81-86`,
    // "P06-BUG-06"). `FamilyState.copyWith` has no such flag
    // (`family_state.dart:71-95`: `errorMessage ?? this.errorMessage`) and
    // `_onLoadRequested.onData` never clears it, so a recovered `loaded`
    // state still carries the dead failure message. Consequence in the view:
    // `ChildProfileView`'s listener only toasts when `errorMessage` CHANGES
    // (`child_profile_view.dart:41-44`), so the same failure happening a
    // second time is silent.
    blocTest<FamilyBloc, FamilyState>(
      'BUG P15-BUG-3: a recovered load drops the dead failure message',
      build: () {
        final repo = _MockFamilyRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
        when(repo.watchChildren).thenAnswer((_) => Stream.value(_kids));
        var attempts = 0;
        when(repo.watchProfile).thenAnswer((_) {
          attempts++;
          return attempts == 1
              ? Stream<ChildProfile?>.error(Exception('offline'))
              : Stream<ChildProfile?>.value(_mayaProfile);
        });
        return FamilyBloc(repository: repo);
      },
      act: (bloc) async {
        bloc.add(const FamilyLoadRequested());
        await Future<void>.delayed(const Duration(milliseconds: 50));
        bloc.add(const FamilyLoadRequested());
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<FamilyState>(),
        isA<FamilyState>(),
        isA<FamilyState>(),
        const FamilyState(
          status: FamilyStatus.loaded,
          items: _members,
          children: _kids,
          profile: _mayaProfile,
        ),
      ],
    );

    // P05 and P15 share ONE bloc (`ARCHITECTURE`), so the P05 form events run
    // against the P15 profile. They must not disturb it.
    blocTest<FamilyBloc, FamilyState>(
      'draft edits and a save leave the loaded profile untouched',
      build: () {
        final repo = _MockFamilyRepository();
        when(repo.watchItems).thenAnswer((_) => Stream.value(_members));
        when(repo.watchChildren).thenAnswer((_) => Stream.value(_kids));
        when(repo.watchProfile).thenAnswer((_) => Stream.value(_mayaProfile));
        when(
          () => repo.addChild(
            nickname: any(named: 'nickname'),
            ageBand: any(named: 'ageBand'),
            avatarColour: any(named: 'avatarColour'),
          ),
        ).thenAnswer((_) async {});
        return FamilyBloc(repository: repo);
      },
      seed: () => const FamilyState(
        status: FamilyStatus.loaded,
        items: _members,
        children: _kids,
        profile: _mayaProfile,
      ),
      act: (bloc) async {
        bloc.add(const FamilyDraftChanged(nickname: 'Ollie'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const FamilyAddChildRequested(onSaved: _noop));
      },
      wait: const Duration(milliseconds: 60),
      expect: () => const <FamilyState>[
        FamilyState(
          status: FamilyStatus.loaded,
          items: _members,
          children: _kids,
          profile: _mayaProfile,
          draftNickname: 'Ollie',
        ),
        FamilyState(
          status: FamilyStatus.loaded,
          items: _members,
          children: _kids,
          profile: _mayaProfile,
          draftNickname: 'Ollie',
          saveInProgress: true,
        ),
        // The draft clears itself after a save, but the P15 profile — which
        // only the load stream owns — is carried through untouched.
        FamilyState(
          status: FamilyStatus.loaded,
          items: _members,
          children: _kids,
          profile: _mayaProfile,
          lastSavedNickname: 'Ollie',
        ),
      ],
    );
  });

  group('FamilyBloc remove against the real repository', () {
    test('removing maya re-emits leo as the selected profile', () async {
      final db = await _demoDb();
      final bloc = FamilyBloc(repository: FamilyRepositoryImpl(db: db))
        ..add(const FamilyLoadRequested());

      await bloc.stream.firstWhere(
        (s) => s.status == FamilyStatus.loaded && s.profile?.child.id == 'maya',
      );
      bloc.add(const FamilyRemoveChildRequested(childId: 'maya'));
      await bloc.stream.firstWhere(
        (s) => s.status == FamilyStatus.loaded && s.profile?.child.id == 'leo',
      );

      expect(bloc.state.children.map((c) => c.id), <String>['leo']);
      expect(bloc.state.profile?.child.id, 'leo');
      final rows = await db.select(db.children).get();
      expect(rows.map((r) => r.id), <String>['leo']);

      await bloc.close();
    });

    test('removing the last child clears the profile', () async {
      final db = await _demoDb();
      final repo = FamilyRepositoryImpl(db: db);
      final bloc = FamilyBloc(repository: repo)
        ..add(const FamilyLoadRequested());

      await bloc.stream.firstWhere(
        (s) => s.status == FamilyStatus.loaded && s.profile?.child.id == 'maya',
      );
      bloc.add(const FamilyRemoveChildRequested(childId: 'maya'));
      await bloc.stream.firstWhere(
        (s) => s.status == FamilyStatus.loaded && s.profile?.child.id == 'leo',
      );
      bloc.add(const FamilyRemoveChildRequested(childId: 'leo'));
      await bloc.stream.firstWhere(
        (s) => s.status == FamilyStatus.loaded && s.profile == null,
      );

      expect(bloc.state.children, isEmpty);
      expect(bloc.state.profile, isNull);

      await bloc.close();
    });
  });

  group('FamilyState profile', () {
    test('draft edits keep the profile; explicit null clears it', () {
      const profiled = FamilyState(profile: _mayaProfile);
      expect(profiled.copyWith().profile, _mayaProfile);
      expect(profiled.copyWith(draftNickname: 'Ollie').profile, _mayaProfile);
      expect(profiled.copyWith(profile: null).profile, isNull);
    });

    test('defaults to no profile', () {
      expect(const FamilyState().profile, isNull);
    });
  });
}
