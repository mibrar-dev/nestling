// Family time-zone contract tests (owner-approved DATETIME_STORAGE rules).
//
// Covers: DST gap + ambiguous hour in Europe/London, London→Dubai move
// (history unchanged, day/week/payout follow Dubai, straddling period),
// device zone vs family zone, unknown zone fallback, write-zone resolution.

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/family_time.dart';
import 'package:nestling/core/data/family_zone_service.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/approvals/data/approvals_repository_impl.dart';
import 'package:nestling/features/kid_home/data/kid_home_repository_impl.dart';
import 'package:nestling/features/pocket_money/data/pocket_money_repository_impl.dart';
import 'package:nestling/features/quests/data/quests_repository_impl.dart';
import 'package:nestling/features/quests/domain/entities/quest.dart' as domain;
import 'package:nestling/features/settings/data/settings_repository_impl.dart';
import 'package:nestling/features/today/data/today_repository_impl.dart';
import 'package:nestling/features/today/domain/entities/today_item.dart';

const String london = 'Europe/London';
const String dubai = 'Asia/Dubai';

void main() {
  group('DST in Europe/London', () {
    test('spring-forward gap 2026-03-29: 01:30 UTC renders as 02:30 BST', () {
      // Clocks jump 01:00 UTC → 02:00 BST; 01:xx local does not exist.
      initFamilyTime();
      expect(toFamilyZone(DateTime.utc(2026, 3, 29, 0, 30), london).hour, 0);
      final after = toFamilyZone(DateTime.utc(2026, 3, 29, 1, 30), london);
      expect(after.hour, 2);
      expect(after.minute, 30);
    });

    test('spring-forward day still starts at London midnight (GMT)', () {
      expect(
        dayStartUtc(london, DateTime.utc(2026, 3, 29, 12)),
        DateTime.utc(2026, 3, 29),
      );
    });

    test('ambiguous hour 2026-10-25: same wall clock, different offsets', () {
      // Clocks fall back 02:00 BST → 01:00 GMT; 01:30 happens twice.
      final first = toFamilyZone(DateTime.utc(2026, 10, 25, 0, 30), london);
      final second = toFamilyZone(DateTime.utc(2026, 10, 25, 1, 30), london);
      expect(first.hour, 1);
      expect(first.minute, 30);
      expect(second.hour, 1);
      expect(second.minute, 30);
      expect(first.timeZoneOffset, const Duration(hours: 1));
      expect(second.timeZoneOffset, Duration.zero);
    });

    test('autumn-back day starts at 23:00 UTC the previous day (BST)', () {
      expect(
        dayStartUtc(london, DateTime.utc(2026, 10, 25, 12)),
        DateTime.utc(2026, 10, 24, 23),
      );
    });
  });

  group('London → Dubai move', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.memory();
      await Seed.demo(db);
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'history display is unchanged by the move (stored zone wins)',
      () async {
        final completions = await db.select(db.questCompletions).get();
        final first = completions.first;
        expect(first.createdAtTz, london);
        final before = formatDay(first.createdAt, first.createdAtTz);
        await Seed.movedToDubai(db);
        final afterMove = await db.select(db.questCompletions).get();
        expect(afterMove.first.createdAt, first.createdAt);
        expect(afterMove.first.createdAtTz, london);
        expect(formatDay(first.createdAt, first.createdAtTz), before);
        // With the new family zone, the stored zone is named explicitly.
        expect(
          formatDay(first.createdAt, first.createdAtTz, familyZoneId: dubai),
          '$before (London)',
        );
      },
    );

    test('day boundary follows Dubai after the move', () {
      // Sat 3 Oct 2026 20:30 UTC = 21:30 BST Saturday = 00:30 GST Sunday.
      final now = DateTime.utc(2026, 10, 3, 20, 30);
      // A completion at 19:00 UTC is Saturday in London but Sunday's
      // small hours make it stale in Dubai (Dubai day starts 20:00 UTC).
      final completed = DateTime.utc(2026, 10, 3, 19);
      expect(countsForCurrentPeriod('daily', completed, now, london), isTrue);
      expect(countsForCurrentPeriod('daily', completed, now, dubai), isFalse);
      // Weekly periods still overlap in this window.
      expect(countsForCurrentPeriod('weekly', completed, now, dubai), isTrue);
    });

    test('week boundary follows Dubai after the move', () {
      // Sunday 20:30 UTC: still Sunday in London, already Monday in Dubai —
      // the two zones are in different weeks.
      final now = DateTime.utc(2026, 10, 4, 20, 30);
      expect(toFamilyZone(now, london).weekday, 7);
      expect(toFamilyZone(now, dubai).weekday, 1);
      expect(
        weekStartUtc(dubai, now),
        // Mon 5 Oct 00:00 GST = Sun 4 Oct 20:00 UTC.
        DateTime.utc(2026, 10, 4, 20),
      );
      expect(
        weekStartUtc(london, now),
        // Mon 28 Sep 00:00 BST = Sun 27 Sep 23:00 UTC.
        DateTime.utc(2026, 9, 27, 23),
      );
      expect(weekStartUtc(dubai, now) != weekStartUtc(london, now), isTrue);
    });

    test('payout weekday is evaluated in the new family zone', () {
      // 20:30 UTC Saturday: still Saturday in London, already Sunday Dubai.
      final now = DateTime.utc(2026, 10, 3, 20, 30);
      expect(toFamilyZone(now, london).weekday, 6);
      expect(toFamilyZone(now, dubai).weekday, 7);
    });

    test('a period straddling the move expires under the new zone', () async {
      await Seed.movedToDubai(db);
      // 20:30 UTC Saturday: Dubai is already Sunday.
      final now = DateTime.utc(2026, 10, 3, 20, 30);
      final repo = TodayRepositoryImpl(db: db, clock: () => now);
      final quests = await db.select(db.quests).get();
      final completions = await db.select(db.questCompletions).get();
      final kids = await db.select(db.children).get();
      final londonRows = repo.rows(quests, completions, kids, now: now);
      final dubaiRows = repo.rows(
        quests,
        completions,
        kids,
        now: now,
        zoneId: dubai,
      );
      String statusOf(List<TodayItem> rows, String id) =>
          rows.firstWhere((r) => r.id == id).status;
      // Dishwasher was done Saturday morning London time: still current in
      // London, stale (to do again) in Dubai.
      expect(statusOf(londonRows, 'q-dishwasher:maya'), 'done_pending');
      expect(statusOf(dubaiRows, 'q-dishwasher:maya'), 'to_do');
    });
  });

  group('device zone vs family zone', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.memory();
      await Seed.demo(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('family "today" follows the family zone, not the device', () async {
      // Device sits in Dubai but the family never moved: periods still use
      // London. 20:30 UTC Saturday counts as Saturday (done), not Sunday.
      final now = DateTime.utc(2026, 10, 3, 20, 30);
      final repo = TodayRepositoryImpl(db: db, clock: () => now);
      final quests = await db.select(db.quests).get();
      final completions = await db.select(db.questCompletions).get();
      final kids = await db.select(db.children).get();
      final summaries = await repo.watchSummaries().first;
      expect(summaries.firstWhere((s) => s.childId == 'maya').done, 4);
      final rows = repo.rows(quests, completions, kids, now: now);
      expect(
        rows.firstWhere((r) => r.id == 'q-dishwasher:maya').status,
        'done_pending',
      );
    });

    test('pendingMove is null when the device matches the family', () async {
      final service = FamilyZoneService(
        db,
        deviceZoneReader: () async => london,
      );
      expect(await service.pendingMove(), isNull);
    });

    test(
      'pendingMove surfaces a different device zone without switching',
      () async {
        final service = FamilyZoneService(
          db,
          deviceZoneReader: () async => dubai,
        );
        expect(await service.pendingMove(), dubai);
        // Never switches silently: the stored zone is still London.
        expect(await service.familyZoneId(), london);
        await service.confirmPendingMove();
        expect(await service.familyZoneId(), dubai);
      },
    );
  });

  group('unknown zones fall back safely', () {
    test('normalizeZoneId never throws and ends at a known zone', () {
      expect(normalizeZoneId('Mars/Olympus'), london);
      expect(normalizeZoneId(null), london);
      expect(normalizeZoneId(''), london);
      expect(normalizeZoneId(dubai), dubai);
    });

    test('period + format helpers accept unknown zones', () {
      final now = DateTime.utc(2026, 10, 3, 9);
      expect(
        countsForCurrentPeriod(
          'daily',
          DateTime.utc(2026, 10, 3, 6),
          now,
          'Not/AZone',
        ),
        isTrue,
      );
      expect(formatDay(now, 'Not/AZone'), 'Sat 3 Oct');
      expect(formatTime(now, 'Not/AZone'), '10:00am');
    });

    test('resolveWriteZone prefers device, then family, then London', () {
      expect(resolveWriteZone(deviceZone: dubai, familyZone: london), dubai);
      expect(
        resolveWriteZone(deviceZone: 'Bogus/Zone', familyZone: dubai),
        dubai,
      );
      expect(resolveWriteZone(), london);
    });

    test('setFamilyTimeZone ignores unknown ids', () async {
      final db = AppDatabase.memory();
      await Seed.demo(db);
      final service = FamilyZoneService(db);
      await service.setFamilyTimeZone('Not/AZone');
      expect(await service.familyZoneId(), london);
      await db.close();
    });
  });

  group('seed + repository zone plumbing', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.memory();
      await Seed.demo(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('seed stamps London on every instant + the family row', () async {
      final family = await (db.select(
        db.families,
      )..where((f) => f.id.equals(Seed.familyId))).getSingle();
      expect(family.timeZone, london);
      for (final c in await db.select(db.questCompletions).get()) {
        expect(c.createdAtTz, london);
        expect(c.decidedAtTz, london);
      }
      for (final l in await db.select(db.ledgerEntries).get()) {
        expect(l.dateTz, london);
      }
      for (final e in await db.select(db.earnedBadges).get()) {
        expect(e.earnedAtTz, london);
      }
      final state = await (db.select(
        db.appState,
      )..where((a) => a.id.equals(1))).getSingle();
      expect(state.trialStartTz, london);
    });

    test('quests preserve the floating dueTimeLocal rule', () async {
      final repo = QuestsRepositoryImpl(db: db);
      await repo.createQuest(
        const domain.Quest(
          id: 'q-tea',
          title: 'Tidy before tea',
          detail: 'Daily · 10 coins',
          icon: 'plate',
          coins: 10,
          repeatRule: 'daily',
          days: '',
          dueLabel: 'Before tea',
          needsApproval: true,
          assigneeChildId: 'maya',
          active: true,
          dueTimeLocal: '17:00',
        ),
      );
      expect((await repo.getQuest('q-tea'))?.dueTimeLocal, '17:00');
      expect((await repo.getQuest('q-dishwasher'))?.dueTimeLocal, isNull);
    });

    test('kid_home completions are stamped with the family zone', () async {
      final repo = KidHomeRepositoryImpl(db: db);
      // completeQuest either flips the seeded to_do row in place (seed day ==
      // real London today) or inserts a fresh row (seed day is stale relative
      // to the real clock): identify the touched row by comparing the
      // before/after snapshots (new id, or changed createdAt/status), never
      // .single over the seeded rows. Deterministic on any real date.
      Future<QuestCompletion> completeAndFindFresh(
        String childId,
        String questId,
      ) async {
        final beforeById = <int, QuestCompletion>{
          for (final c
              in await (db.select(db.questCompletions)
                    ..where((c) => c.questId.equals(questId))
                    ..where((c) => c.childId.equals(childId)))
                  .get())
            c.id: c,
        };
        await repo.completeQuest(childId, questId);
        final rows =
            await (db.select(db.questCompletions)
                  ..where((c) => c.questId.equals(questId))
                  ..where((c) => c.childId.equals(childId)))
                .get();
        final touched = rows.where((c) {
          final before = beforeById[c.id];
          if (before == null) return true;
          return c.createdAt != before.createdAt || c.status != before.status;
        }).toList();
        expect(
          touched,
          hasLength(1),
          reason: 'completeQuest($childId, $questId) must touch one row',
        );
        return touched.single;
      }

      expect(
        (await completeAndFindFresh('maya', 'q-reading')).createdAtTz,
        london,
      );
      await Seed.movedToDubai(db);
      expect(
        (await completeAndFindFresh('leo', 'q-plants')).createdAtTz,
        dubai,
      );
    });

    test('approvals stamp decision + ledger zones', () async {
      final repo = ApprovalsRepositoryImpl(db: db);
      final pending = await repo.watchItems().first;
      final first = pending.first;
      await repo.approve(first.completionId);
      final row = await (db.select(
        db.questCompletions,
      )..where((c) => c.id.equals(first.completionId))).getSingle();
      expect(row.decidedAtTz, london);
      expect(row.decidedAt, isNotNull);
    });

    test('pocket_money payout note uses the family-zone day', () async {
      final repo = PocketMoneyRepositoryImpl(db: db);
      final before = await (db.select(
        db.ledgerEntries,
      )..where((l) => l.type.equals('payout'))).get();
      await repo.recordPayout(childId: 'maya', amountPence: 420);
      final after = await (db.select(
        db.ledgerEntries,
      )..where((l) => l.type.equals('payout'))).get();
      expect(after.length, before.length + 1);
      final fresh = after.firstWhere((l) => !before.any((b) => b.id == l.id));
      expect(fresh.dateTz, london);
      expect(fresh.note.startsWith('Paid · '), isTrue);
    });

    test('settings exposes the family zone + validates writes', () async {
      final repo = SettingsRepositoryImpl(db: db);
      expect(await repo.watchFamilyTimeZone().first, london);
      await repo.setFamilyTimeZone(dubai);
      expect(await repo.watchFamilyTimeZone().first, dubai);
      await repo.setFamilyTimeZone('Bogus/Zone');
      expect(await repo.watchFamilyTimeZone().first, dubai);
    });
  });
}
