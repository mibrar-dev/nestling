// P16 Settings — bloc state machine for Family & settings.
//
// The bloc serves /settings from one subscription: settings + family zone +
// both roster streams + the one-shot move prompt. Every P16 control is
// write-through — the watched streams re-emit and the state follows —
// except the session-local "Not now" dismissal, which has no stream behind
// it and emits directly.

import 'package:bloc_test/bloc_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/family_zone_service.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/settings/data/settings_repository_impl.dart';
import 'package:nestling/features/settings/domain/entities/app_settings.dart';
import 'package:nestling/features/settings/domain/entities/settings_child_entry.dart';
import 'package:nestling/features/settings/domain/entities/settings_item.dart';
import 'package:nestling/features/settings/domain/entities/settings_member_entry.dart';
import 'package:nestling/features/settings/domain/settings_repository.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_event.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_session_store.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_state.dart';

import '../../test_scope.dart';

/// A loaded bloc whose device zone reads Dubai while the family zone is
/// London, so the move banner is up.
Future<SettingsBloc> _dubaiBloc() async {
  await setUpTestScope();
  final bloc = _bloc(
    zoneService: FamilyZoneService(
      GetIt.instance<AppDatabase>(),
      deviceZoneReader: () async => 'Asia/Dubai',
    ),
  )..add(const SettingsLoadRequested());
  await bloc.stream.firstWhere(
    (state) =>
        state.status == SettingsStatus.loaded && state.pendingZone != null,
  );
  return bloc;
}

/// A zone service with no readable device zone (the unit-test default: no
/// platform channel), so the move banner never appears unless a test opts
/// into a fake device zone.
FamilyZoneService _noDeviceService() {
  return FamilyZoneService(
    GetIt.instance<AppDatabase>(),
    deviceZoneReader: () async => throw Exception('no device zone'),
  );
}

SettingsBloc _bloc({FamilyZoneService? zoneService}) {
  return SettingsBloc(
    repository: GetIt.instance<SettingsRepository>(),
    zoneService: zoneService ?? _noDeviceService(),
  );
}

void main() {
  group('SettingsState', () {
    test('starts initial with London defaults', () {
      const state = SettingsState();
      expect(state.status, SettingsStatus.initial);
      expect(state.settings, isNull);
      expect(state.familyRoster, isEmpty);
      expect(state.memberRows, isEmpty);
      expect(state.familyZoneId, 'Europe/London');
      expect(state.deviceZoneId, isNull);
      expect(state.pendingZone, isNull);
      expect(state.dismissedZones, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('copyWith clears the pending zone only on request', () {
      const dismissed = SettingsState(pendingZone: 'Asia/Dubai');
      expect(dismissed.copyWith().pendingZone, 'Asia/Dubai');
      final cleared = dismissed.copyWith(
        dismissedZones: const <String>{'Asia/Dubai'},
        clearPendingZone: true,
      );
      expect(cleared.pendingZone, isNull);
      expect(cleared.dismissedZones, const <String>{'Asia/Dubai'});
    });
  });

  group('SettingsEvent', () {
    test('carries its fields in props', () {
      expect(
        const SettingsNotificationsChanged(approvals: false).props,
        <Object?>[false, null, null],
      );
      expect(const SettingsTimeZonePicked('Asia/Dubai').props, <Object?>[
        'Asia/Dubai',
      ]);
      expect(const SettingsMoveDismissed('Asia/Dubai').props, <Object?>[
        'Asia/Dubai',
      ]);
      expect(const SettingsLoadRequested().props, isEmpty);
      expect(const SettingsMoveConfirmed().props, isEmpty);
    });
  });

  group('SettingsBloc — P16 load', () {
    blocTest<SettingsBloc, SettingsState>(
      'load emits settings, roster, members and the London zone',
      setUp: setUpTestScope,
      build: _bloc,
      act: (bloc) => bloc.add(const SettingsLoadRequested()),
      expect: () => <Matcher>[
        isA<SettingsState>().having(
          (state) => state.status,
          'status',
          SettingsStatus.loading,
        ),
        isA<SettingsState>()
            .having((state) => state.status, 'status', SettingsStatus.loaded)
            .having(
              (state) => state.settings!.notifApprovals,
              'approvals',
              isTrue,
            )
            .having(
              (state) => state.settings!.kidGateEnabled,
              'kid gate',
              isTrue,
            )
            .having(
              (state) => state.familyRoster.map((row) => row.id).toList(),
              'roster order',
              <String>['maya', 'leo'],
            )
            .having(
              (state) => state.familyRoster.first.pipStageName,
              'maya stage',
              'Fledgling',
            )
            .having((state) => state.familyRoster.last.coins, 'leo coins', 45)
            .having(
              (state) => state.memberRows.map((row) => row.id).toList(),
              'member order',
              <String>['sarah', 'james'],
            )
            .having((state) => state.familyZoneId, 'zone', 'Europe/London')
            .having((state) => state.pendingZone, 'pending', isNull),
      ],
    );
  });

  group('SettingsBloc — P16 writes round-trip through the database', () {
    blocTest<SettingsBloc, SettingsState>(
      'a toggle flips the DB value and the stream re-emits',
      setUp: setUpTestScope,
      build: _bloc,
      act: (bloc) async {
        bloc.add(const SettingsLoadRequested());
        await bloc.stream.firstWhere(
          (state) => state.status == SettingsStatus.loaded,
        );
        bloc.add(const SettingsNotificationsChanged(approvals: false));
      },
      expect: () => <Matcher>[
        isA<SettingsState>().having(
          (state) => state.status,
          'status',
          SettingsStatus.loading,
        ),
        isA<SettingsState>()
            .having((state) => state.status, 'status', SettingsStatus.loaded)
            .having(
              (state) => state.settings!.notifApprovals,
              'before',
              isTrue,
            ),
        isA<SettingsState>()
            .having((state) => state.status, 'status', SettingsStatus.loaded)
            .having(
              (state) => state.settings!.notifApprovals,
              'after',
              isFalse,
            ),
      ],
      verify: (_) async {
        final repository = GetIt.instance<SettingsRepository>();
        final settings = await repository.watchSettings().first;
        expect(settings.notifApprovals, isFalse);
        expect(settings.notifPayout, isTrue);
        expect(settings.notifSummary, isTrue);
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'a picked zone is stored and mirrored into settings',
      setUp: setUpTestScope,
      build: _bloc,
      act: (bloc) async {
        bloc.add(const SettingsLoadRequested());
        await bloc.stream.firstWhere(
          (state) => state.status == SettingsStatus.loaded,
        );
        bloc.add(const SettingsTimeZonePicked('Asia/Dubai'));
      },
      expect: () => <Matcher>[
        isA<SettingsState>().having(
          (state) => state.status,
          'status',
          SettingsStatus.loading,
        ),
        isA<SettingsState>()
            .having((state) => state.status, 'status', SettingsStatus.loaded)
            .having((state) => state.familyZoneId, 'before', 'Europe/London'),
        isA<SettingsState>()
            .having((state) => state.status, 'status', SettingsStatus.loaded)
            .having((state) => state.familyZoneId, 'after', 'Asia/Dubai'),
      ],
      verify: (_) async {
        final db = GetIt.instance<AppDatabase>();
        final row = await (db.select(
          db.settings,
        )..where((s) => s.familyId.equals(Seed.familyId))).getSingle();
        expect(row.timeZone, 'Asia/Dubai');
      },
    );

    blocTest<SettingsBloc, SettingsState>(
      'an unknown zone id is ignored: no state change, no write',
      setUp: setUpTestScope,
      build: _bloc,
      act: (bloc) async {
        bloc.add(const SettingsLoadRequested());
        await bloc.stream.firstWhere(
          (state) => state.status == SettingsStatus.loaded,
        );
        bloc.add(const SettingsTimeZonePicked('Bogus/Zone'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      },
      expect: () => <Matcher>[
        isA<SettingsState>().having(
          (state) => state.status,
          'status',
          SettingsStatus.loading,
        ),
        isA<SettingsState>()
            .having((state) => state.status, 'status', SettingsStatus.loaded)
            .having((state) => state.familyZoneId, 'zone', 'Europe/London'),
      ],
      verify: (_) async {
        final repository = GetIt.instance<SettingsRepository>();
        expect(await repository.watchFamilyTimeZone().first, 'Europe/London');
      },
    );
  });

  group('SettingsBloc — move banner', () {
    test('a Dubai device zone raises the banner once', () async {
      final bloc = await _dubaiBloc();

      expect(bloc.state.pendingZone, 'Asia/Dubai');
      expect(bloc.state.deviceZoneId, 'Asia/Dubai');
      expect(bloc.state.familyZoneId, 'Europe/London');

      await bloc.close();
    });

    test(
      'Switch confirms the move: the zone stores, the banner clears',
      () async {
        final bloc = await _dubaiBloc();

        bloc.add(const SettingsMoveConfirmed());
        final cleared = await bloc.stream.firstWhere(
          (state) =>
              state.status == SettingsStatus.loaded &&
              state.pendingZone == null &&
              state.familyZoneId == 'Asia/Dubai',
        );
        expect(cleared.dismissedZones, isEmpty);

        final repository = GetIt.instance<SettingsRepository>();
        expect(await repository.watchFamilyTimeZone().first, 'Asia/Dubai');

        await bloc.close();
      },
    );

    test('Not now dismisses for the session without touching the DB', () async {
      final bloc = await _dubaiBloc();

      bloc.add(const SettingsMoveDismissed('Asia/Dubai'));
      final dismissed = await bloc.stream.firstWhere(
        (state) => state.dismissedZones.contains('Asia/Dubai'),
      );
      expect(dismissed.pendingZone, isNull);
      expect(
        dismissed.deviceZoneId,
        'Asia/Dubai',
        reason:
            'the device zone survives dismissal: the picker orders by '
            'deviceZoneId, not by the banner-only pendingZone (P16-B01)',
      );

      // The family zone is untouched …
      final repository = GetIt.instance<SettingsRepository>();
      expect(await repository.watchFamilyTimeZone().first, 'Europe/London');

      // … and moving away and back never re-prompts for that zone.
      bloc.add(const SettingsTimeZonePicked('Asia/Dubai'));
      await bloc.stream.firstWhere(
        (state) => state.familyZoneId == 'Asia/Dubai',
      );
      bloc.add(const SettingsTimeZonePicked('Europe/London'));
      final back = await bloc.stream.firstWhere(
        (state) => state.familyZoneId == 'Europe/London',
      );
      expect(back.pendingZone, isNull);
      expect(back.dismissedZones, const <String>{'Asia/Dubai'});

      await bloc.close();
    });
  });

  group('SettingsBloc — session dismissals (P16-B02)', () {
    test('a dismissal survives a rebuilt bloc via the session store', () async {
      await setUpTestScope();
      final db = GetIt.instance<AppDatabase>();
      final zoneService = FamilyZoneService(
        db,
        deviceZoneReader: () async => 'Asia/Dubai',
      );
      final store = SettingsSessionStore();
      SettingsBloc makeBloc() => SettingsBloc(
        repository: SettingsRepositoryImpl(db: db),
        zoneService: zoneService,
        sessionStore: store,
      );

      // First visit: the banner is up, then dismissed.
      final blocA = makeBloc()..add(const SettingsLoadRequested());
      await blocA.stream.firstWhere(
        (state) =>
            state.status == SettingsStatus.loaded && state.pendingZone != null,
      );
      blocA.add(const SettingsMoveDismissed('Asia/Dubai'));
      await blocA.stream.firstWhere(
        (state) => state.dismissedZones.contains('Asia/Dubai'),
      );
      await blocA.close();

      // Same session, rebuilt bloc: the prompt stays hidden, the device
      // zone stays known for the picker.
      final blocB = makeBloc()..add(const SettingsLoadRequested());
      final loadedB = await blocB.stream.firstWhere(
        (state) => state.status == SettingsStatus.loaded,
      );
      expect(loadedB.pendingZone, isNull);
      expect(loadedB.deviceZoneId, 'Asia/Dubai');
      expect(loadedB.dismissedZones, const <String>{'Asia/Dubai'});
      expect(loadedB.familyZoneId, 'Europe/London');

      await blocB.close();
    });

    test(
      'a bloc without a store falls back to the session singleton',
      () async {
        await setUpTestScope();
        final store = GetIt.instance<SettingsSessionStore>();
        store.dismissedZones.add('Asia/Dubai');

        final bloc = _bloc(
          zoneService: FamilyZoneService(
            GetIt.instance<AppDatabase>(),
            deviceZoneReader: () async => 'Asia/Dubai',
          ),
        )..add(const SettingsLoadRequested());
        final loaded = await bloc.stream.firstWhere(
          (state) => state.status == SettingsStatus.loaded,
        );
        expect(loaded.pendingZone, isNull);
        expect(loaded.deviceZoneId, 'Asia/Dubai');

        await bloc.close();
      },
    );
  });

  group('SettingsBloc — stream failure and retry', () {
    blocTest<SettingsBloc, SettingsState>(
      'a dead roster stream fails, and retry resubscribes to recovery',
      setUp: setUpTestScope,
      build: () => SettingsBloc(
        repository: _RosterFlakyRepository(
          GetIt.instance<SettingsRepository>(),
        ),
        zoneService: _noDeviceService(),
      ),
      act: (bloc) async {
        bloc.add(const SettingsLoadRequested());
        await bloc.stream.firstWhere(
          (state) => state.status == SettingsStatus.failure,
        );
        bloc.add(const SettingsLoadRequested());
      },
      expect: () => <Matcher>[
        isA<SettingsState>().having(
          (state) => state.status,
          'status',
          SettingsStatus.loading,
        ),
        isA<SettingsState>()
            .having((state) => state.status, 'status', SettingsStatus.failure)
            .having(
              (state) => state.errorMessage,
              'error',
              contains('roster is down'),
            ),
        isA<SettingsState>().having(
          (state) => state.status,
          'status',
          SettingsStatus.loading,
        ),
        isA<SettingsState>()
            .having((state) => state.status, 'status', SettingsStatus.loaded)
            .having(
              (state) => state.familyRoster.map((row) => row.id).toList(),
              'roster',
              <String>['maya', 'leo'],
            ),
      ],
    );
  });

  group('gmtOffsetLabel', () {
    test('Dubai is GMT+4 year-round', () {
      expect(
        gmtOffsetLabel('Asia/Dubai', DateTime.utc(2026, 10, 3, 12)),
        'GMT+4',
      );
      expect(
        gmtOffsetLabel('Asia/Dubai', DateTime.utc(2026, 1, 15, 12)),
        'GMT+4',
      );
    });

    test('London follows BST: +1 in October, +0 in January', () {
      expect(
        gmtOffsetLabel('Europe/London', DateTime.utc(2026, 10, 3, 12)),
        'GMT+1',
      );
      expect(
        gmtOffsetLabel('Europe/London', DateTime.utc(2026, 1, 15, 12)),
        'GMT+0',
      );
    });

    test('other curated zones render their offsets', () {
      expect(
        gmtOffsetLabel('Asia/Karachi', DateTime.utc(2026, 10, 3, 12)),
        'GMT+5',
      );
      expect(
        gmtOffsetLabel('America/New_York', DateTime.utc(2026, 1, 15, 12)),
        'GMT-5',
      );
    });

    test('half-hour zones render a zero-padded minute', () {
      expect(
        gmtOffsetLabel('Asia/Kolkata', DateTime.utc(2026, 10, 3, 12)),
        'GMT+5:30',
      );
      // Newfoundland is on ADT (-2:30) in October and NST (-3:30) in winter —
      // the label follows the zone, not a stored offset.
      expect(
        gmtOffsetLabel('America/St_Johns', DateTime.utc(2026, 10, 3, 12)),
        'GMT-2:30',
      );
      expect(
        gmtOffsetLabel('America/St_Johns', DateTime.utc(2026, 1, 15, 12)),
        'GMT-3:30',
      );
    });

    test('an unknown zone falls back to London instead of throwing', () {
      expect(
        gmtOffsetLabel('Bogus/Zone', DateTime.utc(2026, 10, 3, 12)),
        gmtOffsetLabel('Europe/London', DateTime.utc(2026, 10, 3, 12)),
      );
    });
  });

  group('SettingsBloc — every remaining event path', () {
    test('all three toggles in one event flip together', () async {
      final bloc = await _loadedBloc();

      bloc.add(
        const SettingsNotificationsChanged(
          approvals: false,
          payout: false,
          summary: false,
        ),
      );
      final flipped = await bloc.stream.firstWhere(
        (state) =>
            state.status == SettingsStatus.loaded &&
            !state.settings!.notifApprovals &&
            !state.settings!.notifPayout &&
            !state.settings!.notifSummary,
      );

      final row = await GetIt.instance<SettingsRepository>()
          .watchSettings()
          .first;
      expect(row.notifApprovals, isFalse);
      expect(row.notifPayout, isFalse);
      expect(row.notifSummary, isFalse);
      expect(flipped.settings!.subscriptionStatus, isNotNull);

      await bloc.close();
    });

    test('an event with no fields writes nothing and emits nothing', () async {
      final bloc = await _loadedBloc();
      final before = bloc.state;

      bloc.add(const SettingsNotificationsChanged());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state, before, reason: 'an empty event is a no-op');
      final settings = await GetIt.instance<SettingsRepository>()
          .watchSettings()
          .first;
      expect(settings.notifApprovals, isTrue);
      expect(settings.notifPayout, isTrue);
      expect(settings.notifSummary, isTrue);

      await bloc.close();
    });

    test('the payout and summary switches round-trip on their own', () async {
      final bloc = await _loadedBloc();

      bloc.add(const SettingsNotificationsChanged(payout: false));
      await bloc.stream.firstWhere(
        (state) =>
            state.status == SettingsStatus.loaded &&
            !state.settings!.notifPayout,
      );
      bloc.add(const SettingsNotificationsChanged(summary: false));
      await bloc.stream.firstWhere(
        (state) =>
            state.status == SettingsStatus.loaded &&
            !state.settings!.notifSummary,
      );

      final settings = await GetIt.instance<SettingsRepository>()
          .watchSettings()
          .first;
      expect(settings.notifApprovals, isTrue);
      expect(settings.notifPayout, isFalse);
      expect(settings.notifSummary, isFalse);

      await bloc.close();
    });

    test('re-picking the zone already stored changes nothing', () async {
      final bloc = await _loadedBloc();
      final before = bloc.state;

      bloc.add(const SettingsTimeZonePicked('Europe/London'));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state, before, reason: 'an identical zone emits nothing new');
      expect(await _storedZone(), 'Europe/London');

      await bloc.close();
    });

    test('confirming a move with no readable device zone is a no-op', () async {
      // The default harness has no device zone, so there is nothing to confirm
      // and nothing may change (no throw, no write, no banner).
      final bloc = await _loadedBloc();

      bloc.add(const SettingsMoveConfirmed());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.pendingZone, isNull);
      expect(bloc.state.errorMessage, isNull);
      expect(await _storedZone(), 'Europe/London');

      await bloc.close();
    });

    test(
      'dismissing a zone that is not the pending one keeps the prompt',
      () async {
        final bloc = await _dubaiBloc();

        bloc.add(const SettingsMoveDismissed('Australia/Sydney'));
        final after = await bloc.stream.first;
        expect(
          after.pendingZone,
          'Asia/Dubai',
          reason: 'only the dismissed zone stops being offered',
        );
        expect(after.dismissedZones, const <String>{'Australia/Sydney'});

        await bloc.close();
      },
    );

    test('a dismissal before the load lands is kept, not lost', () async {
      await setUpTestScope();
      final bloc = _bloc(
        zoneService: FamilyZoneService(
          GetIt.instance<AppDatabase>(),
          deviceZoneReader: () async => 'Asia/Dubai',
        ),
      );

      // Both events before the load's first emission: the dismissal must
      // survive the state the load then builds.
      const <SettingsEvent>[
        SettingsMoveDismissed('Asia/Dubai'),
        SettingsLoadRequested(),
      ].forEach(bloc.add);
      final loaded = await bloc.stream.firstWhere(
        (state) => state.status == SettingsStatus.loaded,
      );

      expect(loaded.dismissedZones, const <String>{'Asia/Dubai'});
      expect(
        loaded.pendingZone,
        isNull,
        reason: 'the banner never appears for a dismissed zone',
      );

      await bloc.close();
    });

    test(
      'a child added while the screen is open joins the roster last',
      () async {
        final bloc = await _loadedBloc();

        final database = GetIt.instance<AppDatabase>();
        await database
            .into(database.children)
            .insert(
              ChildrenCompanion.insert(
                id: 'noor',
                familyId: Seed.familyId,
                nickname: 'Noor',
                createdAt: Value(DateTime.utc(2026, 10, 3, 9)),
              ),
            );

        final grown = await bloc.stream.firstWhere(
          (state) => state.familyRoster.length == 3,
        );
        // CHILD ORDER: creation order, never alphabetical — 'noor' is last
        // because it was added last, even though N sorts before M nowhere.
        expect(grown.familyRoster.map((row) => row.id).toList(), <String>[
          'maya',
          'leo',
          'noor',
        ]);
        expect(grown.familyRoster.last.nickname, 'Noor');
        expect(
          grown.familyRoster.last.pipStageName,
          'Egg',
          reason: 'a new child starts at stage 1',
        );

        await bloc.close();
      },
    );

    test('a member invite that is accepted re-renders as active', () async {
      final bloc = await _loadedBloc();
      expect(
        bloc.state.memberRows.last.inviteStatus,
        'invited',
        reason: 'James starts as an unanswered invite',
      );

      final db = GetIt.instance<AppDatabase>();
      await (db.update(db.members)..where((m) => m.id.equals('james'))).write(
        const MembersCompanion(inviteStatus: Value('active')),
      );

      final accepted = await bloc.stream.firstWhere(
        (state) =>
            state.memberRows.isNotEmpty &&
            state.memberRows.last.inviteStatus == 'active',
      );
      expect(accepted.memberRows.map((row) => row.id).toList(), <String>[
        'sarah',
        'james',
      ]);

      await bloc.close();
    });
  });
}

/// A loaded bloc on the default (unreadable device zone) harness.
Future<SettingsBloc> _loadedBloc() async {
  await setUpTestScope();
  final bloc = _bloc()..add(const SettingsLoadRequested());
  await bloc.stream.firstWhere(
    (state) => state.status == SettingsStatus.loaded,
  );
  return bloc;
}

/// The stored family zone, read straight from the table.
Future<String> _storedZone() async {
  final db = GetIt.instance<AppDatabase>();
  final row = await (db.select(
    db.families,
  )..where((f) => f.id.equals(Seed.familyId))).getSingle();
  return row.timeZone;
}

/// Fails the first `watchRoster` subscription, then delegates to the real
/// repository — the failure/retry shape without a broken database.
class _RosterFlakyRepository implements SettingsRepository {
  _RosterFlakyRepository(this._inner);

  final SettingsRepository _inner;
  int watches = 0;

  @override
  Stream<List<SettingsChildEntry>> watchRoster() {
    watches++;
    if (watches == 1) {
      return Stream<List<SettingsChildEntry>>.error(
        Exception('roster is down'),
      );
    }
    return _inner.watchRoster();
  }

  @override
  Future<List<SettingsItem>> getItems() => _inner.getItems();

  @override
  Stream<List<SettingsItem>> watchItems() => _inner.watchItems();

  @override
  Stream<AppSettings> watchSettings() => _inner.watchSettings();

  @override
  Stream<List<SettingsMemberEntry>> watchMembers() => _inner.watchMembers();

  @override
  Future<void> setPocketMoneyMode(String mode) =>
      _inner.setPocketMoneyMode(mode);

  @override
  Future<void> setPayoutDay(int day) => _inner.setPayoutDay(day);

  @override
  Future<void> setNotifications({
    bool? approvals,
    bool? payout,
    bool? summary,
  }) => _inner.setNotifications(
    approvals: approvals,
    payout: payout,
    summary: summary,
  );

  @override
  Future<void> setCrashConsent({required bool consent}) =>
      _inner.setCrashConsent(consent: consent);

  @override
  Future<void> setKidGateEnabled({required bool enabled}) =>
      _inner.setKidGateEnabled(enabled: enabled);

  @override
  Future<void> setFamilyTimeZone(String zoneId) =>
      _inner.setFamilyTimeZone(zoneId);

  @override
  Stream<String> watchFamilyTimeZone() => _inner.watchFamilyTimeZone();
}
