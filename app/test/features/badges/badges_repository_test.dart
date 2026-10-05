// K11 repository tests (DB-backed, Seed.demo): the badges-stream contract.
//
// `watchActiveBadges` emits the resolved child (demo seed: Maya, 9 badges
// in DB insertion order, 4 earned) plus the stored happy-week count, and
// follows `app_state.activeChildId` switches. Detail copy is design copy:
// earned → `Got it!`, todo → `Keep going!`. Child resolution never falls
// back to a hard-coded id (K11-BUG-2): the persisted `activeChildId` when
// it names a real child, else the first child in creation order, else the
// empty shelf (no children).

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/badges/data/badges_repository_impl.dart';
import 'package:nestling/features/badges/domain/entities/badges_data.dart';

/// Badge ids in DB insertion order (the K11 grid order, never sorted): the
/// seed inserts them in the order below.
const List<String> _insertionOrder = <String>[
  'first-quest',
  'bed-maker-7',
  'kind-helper',
  'bookworm',
  'bins-out',
  'biscuit-sitter',
  'tidy-hero',
  'early-bird',
  'plant-waterer',
];

/// Maya's earned set in the demo seed.
const Set<String> _mayaEarned = <String>{
  'first-quest',
  'bed-maker-7',
  'kind-helper',
  'bookworm',
};

/// Collects the badges stream's emissions so a test can await the one a
/// write provokes. Never waits more than [next]'s bounded retry loop, so a
/// stream that never emits fails fast instead of hanging.
class _BadgesEmissions {
  _BadgesEmissions(Stream<BadgesData> stream) {
    _sub = stream.listen(_events.add, onError: _errors.add);
  }

  late final StreamSubscription<BadgesData> _sub;
  final List<BadgesData> _events = <BadgesData>[];
  final List<Object> _errors = <Object>[];

  List<Object> get errors => List<Object>.unmodifiable(_errors);

  Future<BadgesData> next() async {
    for (var i = 0; i < 30; i++) {
      if (_events.isNotEmpty) return _events.removeAt(0);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    throw StateError('no badges emission arrived within 300 ms');
  }

  /// Gives a stray emission every chance to show up, then reports the queue.
  Future<List<BadgesData>> settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List<BadgesData>.of(_events);
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

  Future<void> clearActiveChild() {
    return (db.update(db.appState)..where((a) => a.id.equals(1))).write(
      const AppStateCompanion(activeChildId: Value<String?>(null)),
    );
  }

  Future<void> setHappyDays(String childId, int days) {
    return (db.update(db.children)..where((c) => c.id.equals(childId))).write(
      ChildrenCompanion(happyDays: Value(days)),
    );
  }

  Future<void> earn(String badgeId, String childId) {
    return db
        .into(db.earnedBadges)
        .insert(
          EarnedBadgesCompanion.insert(
            badgeId: badgeId,
            childId: childId,
            familyId: Seed.familyId,
          ),
        );
  }

  group('BadgesRepository watchShelf (K11)', () {
    test('Maya shelf is 9 rows in insertion order, 4 earned', () async {
      final repo = BadgesRepositoryImpl(db: db);
      final shelf = await repo.watchShelf('maya').first;

      expect(
        shelf.map((b) => b.id).toList(),
        _insertionOrder,
        reason: 'DB insertion order, never sorted',
      );
      expect(
        shelf.where((b) => b.earned).map((b) => b.id).toSet(),
        _mayaEarned,
      );
      expect(shelf.where((b) => !b.earned), hasLength(5));
    });

    test('earned detail is Got it!, todo is Keep going!', () async {
      final repo = BadgesRepositoryImpl(db: db);
      final shelf = await repo.watchShelf('maya').first;

      expect(
        <String, String>{for (final b in shelf) b.id: b.detail},
        <String, String>{
          'first-quest': 'Got it!',
          'bed-maker-7': 'Got it!',
          'kind-helper': 'Got it!',
          'bookworm': 'Got it!',
          'bins-out': 'Keep going!',
          'biscuit-sitter': 'Keep going!',
          'tidy-hero': 'Keep going!',
          'early-bird': 'Keep going!',
          'plant-waterer': 'Keep going!',
        },
      );
    });

    test('Leo shelf is the same 9 rows with 1 earned', () async {
      final repo = BadgesRepositoryImpl(db: db);
      final shelf = await repo.watchShelf('leo').first;

      expect(shelf.map((b) => b.id).toList(), _insertionOrder);
      expect(shelf.where((b) => b.earned).map((b) => b.id).toList(), <String>[
        'first-quest',
      ]);
    });

    test('titles come from the seed in insertion order', () async {
      final repo = BadgesRepositoryImpl(db: db);
      final shelf = await repo.watchShelf('maya').first;

      expect(shelf.map((b) => b.title).toList(), <String>[
        'First quest',
        'Bed maker ×7',
        'Kind helper',
        'Bookworm',
        'Bins out',
        'Biscuit sitter',
        'Tidy hero',
        'Early bird',
        'Plant waterer',
      ]);
    });
  });

  group('BadgesRepository watchHappyDays (K11)', () {
    test('Maya has 4 happy days, Leo has 3', () async {
      final repo = BadgesRepositoryImpl(db: db);
      expect(await repo.watchHappyDays('maya').first, 4);
      expect(await repo.watchHappyDays('leo').first, 3);
    });

    test('unknown child reads 0 happy days', () async {
      final repo = BadgesRepositoryImpl(db: db);
      expect(await repo.watchHappyDays('nobody').first, 0);
    });

    test(
      'a happy-days write above 7 is reported verbatim, not clamped',
      () async {
        // The column carries no upper bound, so the repository must not invent
        // one: the 0…7 framing belongs to the screen (dots + why-line), and a
        // silent clamp here would let the two disagree unnoticed.
        final repo = BadgesRepositoryImpl(db: db);
        await setHappyDays('maya', 9);

        expect(await repo.watchHappyDays('maya').first, 9);
      },
    );
  });

  group('BadgesRepository watchActiveBadges (K11)', () {
    test('emits Maya with her shelf and 4 happy days', () async {
      final repo = BadgesRepositoryImpl(db: db);
      final data = await repo.watchActiveBadges().first;

      expect(data.childId, 'maya');
      expect(data.happyDays, 4);
      expect(data.items.map((b) => b.id).toList(), _insertionOrder);
      expect(
        data.items.where((b) => b.earned).map((b) => b.id).toSet(),
        _mayaEarned,
      );
    });

    test('follows the active child switch (Leo, 1 earned, 3 days)', () async {
      final repo = BadgesRepositoryImpl(db: db);
      await setActiveChild('leo');

      final data = await repo.watchActiveBadges().first;

      expect(data.childId, 'leo');
      expect(data.happyDays, 3);
      expect(data.items.map((b) => b.id).toList(), _insertionOrder);
      expect(
        data.items.where((b) => b.earned).map((b) => b.id).toList(),
        <String>['first-quest'],
      );
    });

    test('legacy watchItems still serves the active shelf', () async {
      final repo = BadgesRepositoryImpl(db: db);
      final items = await repo.watchItems().first;

      expect(items.map((b) => b.id).toList(), _insertionOrder);
      expect(items.where((b) => b.earned), hasLength(4));
      expect(items.firstWhere((b) => b.id == 'first-quest').detail, 'Got it!');
      expect(items.firstWhere((b) => b.id == 'bins-out').detail, 'Keep going!');
    });

    test('legacy watchItems follows the same resolution', () async {
      final repo = BadgesRepositoryImpl(db: db);
      await clearActiveChild();

      // The demo family's first child in creation order is Maya — served
      // through the legacy path with no hard-coded id behind it.
      final items = await repo.watchItems().first;

      expect(items.map((b) => b.id).toList(), _insertionOrder);
      expect(items.where((b) => b.earned), hasLength(4));
    });
  });

  // K11-BUG-2: the persisted `activeChildId` when it names a real child,
  // else the first child in creation order, else the empty shelf — never a
  // hard-coded id.
  group('BadgesRepository child resolution (K11-BUG-2)', () {
    test('null activeChildId resolves the first child (Maya)', () async {
      final repo = BadgesRepositoryImpl(db: db);
      await clearActiveChild();

      final data = await repo.watchActiveBadges().first;

      expect(data.childId, 'maya');
      expect(data.happyDays, 4);
      expect(data.items.map((b) => b.id).toList(), _insertionOrder);
      expect(
        data.items.where((b) => b.earned).map((b) => b.id).toSet(),
        _mayaEarned,
      );
    });

    test('an activeChildId naming no child falls back to Maya', () async {
      final repo = BadgesRepositoryImpl(db: db);
      await setActiveChild('nobody');

      final data = await repo.watchActiveBadges().first;

      expect(data.childId, 'maya');
      expect(data.happyDays, 4);
      expect(data.items.where((b) => b.earned), hasLength(4));
    });

    test('a Zoe-only family with null active resolves Zoe', () async {
      // Mirrors the stage-6 repro at repository level: a family whose only
      // child is Zoe (one earned badge, happyDays 2), deep-linked with no
      // active child, must show Zoe's shelf — not a hard-coded fallback.
      await db.delete(db.earnedBadges).go();
      await db.delete(db.children).go();
      await db
          .into(db.children)
          .insert(
            ChildrenCompanion.insert(
              id: 'zoe',
              familyId: Seed.familyId,
              nickname: 'Zoe',
              happyDays: const Value(2),
            ),
          );
      await db
          .into(db.earnedBadges)
          .insert(
            EarnedBadgesCompanion.insert(
              badgeId: 'bookworm',
              childId: 'zoe',
              familyId: Seed.familyId,
            ),
          );
      await clearActiveChild();
      final repo = BadgesRepositoryImpl(db: db);

      final data = await repo.watchActiveBadges().first;

      expect(data.childId, 'zoe');
      expect(data.happyDays, 2);
      expect(data.items.map((b) => b.id).toList(), _insertionOrder);
      expect(
        data.items.where((b) => b.earned).map((b) => b.id).toList(),
        <String>['bookworm'],
      );
    });

    test('no children at all emits the empty shelf', () async {
      await db.delete(db.earnedBadges).go();
      await db.delete(db.children).go();
      await clearActiveChild();
      final repo = BadgesRepositoryImpl(db: db);

      final data = await repo.watchActiveBadges().first;

      expect(data.childId, isEmpty, reason: 'no child to resolve');
      expect(data.items, isEmpty, reason: 'the view shows its empty state');
      expect(data.happyDays, 0);
    });
  });

  // The live (post-first-emission) switches are what the feature-local
  // `switchMap` exists for: `asyncExpand` would stall here forever, because
  // Drift watch streams never close. Each of these mutates the database
  // AFTER the subscription is live.
  group('BadgesRepository live re-emission (K11)', () {
    late BadgesRepositoryImpl repo;
    late _BadgesEmissions badges;

    setUp(() {
      repo = BadgesRepositoryImpl(db: db);
      badges = _BadgesEmissions(repo.watchActiveBadges());
    });

    tearDown(() => badges.cancel());

    test('follows an active-child switch after the first emission', () async {
      expect((await badges.next()).childId, 'maya');

      await setActiveChild('leo');

      final second = await badges.next();
      expect(second.childId, 'leo');
      expect(second.happyDays, 3);
      expect(second.items.map((b) => b.id).toList(), _insertionOrder);
      expect(
        second.items.where((b) => b.earned).map((b) => b.id).toList(),
        <String>['first-quest'],
      );
    });

    test('a newly earned badge flips its cell in place', () async {
      final first = await badges.next();
      expect(first.items.firstWhere((b) => b.id == 'bins-out').earned, isFalse);

      await earn('bins-out', 'maya');

      final next = await badges.next();
      expect(next.childId, 'maya');
      expect(next.happyDays, 4);
      expect(next.items.firstWhere((b) => b.id == 'bins-out').earned, isTrue);
      expect(
        next.items.firstWhere((b) => b.id == 'bins-out').detail,
        'Got it!',
      );
      expect(next.items.map((b) => b.id).toList(), _insertionOrder);
    });

    test('a happy-days change re-emits with the shelf untouched', () async {
      expect((await badges.next()).happyDays, 4);

      await setHappyDays('maya', 5);

      final next = await badges.next();
      expect(next.childId, 'maya');
      expect(next.happyDays, 5);
      expect(next.items.map((b) => b.id).toList(), _insertionOrder);
      expect(
        next.items.where((b) => b.earned).map((b) => b.id).toSet(),
        _mayaEarned,
      );
    });

    test(
      'a write to the switched-away child produces no stale emission',
      () async {
        await badges.next();
        await setActiveChild('leo');
        expect((await badges.next()).childId, 'leo');
        // Drain the switch burst before the write under test.
        await badges.settle();

        await setHappyDays('maya', 0);

        expect(
          (await badges.settle()).where((data) => data.childId != 'leo'),
          isEmpty,
          reason: 'the stream is bound to the active child only',
        );
        expect(badges.errors, isEmpty);
      },
    );
  });

  group('BadgesRepository on an empty family (K11)', () {
    test('Seed.empty has no badges and no active child', () async {
      await Seed.empty(db);
      final repo = BadgesRepositoryImpl(db: db);

      final data = await repo.watchActiveBadges().first;

      expect(data.childId, isEmpty, reason: 'no child to resolve');
      expect(data.items, isEmpty, reason: 'nothing earned yet');
      expect(data.happyDays, 0, reason: 'no child row, so no count');
    });
  });
}
