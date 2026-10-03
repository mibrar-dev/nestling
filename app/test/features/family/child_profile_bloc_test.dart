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
