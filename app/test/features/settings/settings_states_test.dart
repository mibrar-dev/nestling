// P16 Settings — the screen's non-loaded states and the empty family.
//
// `/settings` serves four states from one `SettingsBloc` subscription:
// loading, failure (with a "Try again" that re-subscribes), loaded and — for a
// family with no children yet — a loaded roster that is only the "Add child"
// row. Each one is asserted here, in the real app wherever the route can
// reach the state, and on the bare view where only a hand-driven bloc can
// (the route resolves loading/failure before the first frame lands).

import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/family_zone_service.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/settings/domain/entities/app_settings.dart';
import 'package:nestling/features/settings/domain/entities/settings_child_entry.dart';
import 'package:nestling/features/settings/domain/entities/settings_item.dart';
import 'package:nestling/features/settings/domain/entities/settings_member_entry.dart';
import 'package:nestling/features/settings/domain/settings_repository.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_event.dart';
import 'package:nestling/features/settings/presentation/views/settings_view.dart';

import '../../test_scope.dart';
import 'p16_test_support.dart';

void main() {
  setUpAll(loadP16Fonts);

  group('P16 loading state', () {
    testWidgets('shows a spinner and no rows until the load lands', (
      tester,
    ) async {
      await setUpTestScope();
      final bloc = settingsBlocWithDeviceZone();

      await pumpSettingsSurface(tester, bloc);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Family & settings'), findsNothing);
      expect(find.text('Sarah — you'), findsNothing);

      bloc.add(const SettingsLoadRequested());
      await settleSettings(tester);

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Family & settings'), findsOneWidget);
      expect(find.text('Sarah — you'), findsOneWidget);

      // `unawaited`: closing a bloc whose `emit.forEach` still holds Drift
      // subscriptions needs real async, which the widget test's fake clock
      // never delivers — awaiting it deadlocks. Same as the P16 view test.
      unawaited(bloc.close());
      await disposeApp(tester);
    });
  });

  group('P16 failure state', () {
    testWidgets('offers "Try again" and recovers on the second stream', (
      tester,
    ) async {
      await setUpTestScope();
      final bloc = SettingsBloc(
        repository: _FailsOnceRepository(GetIt.instance<SettingsRepository>()),
        zoneService: FamilyZoneService(
          GetIt.instance<AppDatabase>(),
          deviceZoneReader: () async => throw Exception('no device zone'),
        ),
      );

      await pumpSettingsSurface(tester, bloc);
      bloc.add(const SettingsLoadRequested());
      await settleSettings(tester);

      expect(
        find.text('Something went wrong loading settings.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('p16_retry')), findsOneWidget);
      expect(find.text('Family & settings'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('p16_retry')));
      await settleSettings(tester);

      expect(find.text('Something went wrong loading settings.'), findsNothing);
      expect(find.text('Maya · 7–9'), findsOneWidget);

      unawaited(bloc.close());
      await disposeApp(tester);
    });
  });

  group('P16 empty family (Seed.empty)', () {
    testWidgets('keeps the parent, drops the children, keeps Add child', (
      tester,
    ) async {
      await pumpSettingsApp(tester, seedDemo: false, prepare: Seed.empty);

      // Family: the owner row and the invite row survive an empty roster.
      expect(find.text('Sarah — you'), findsOneWidget);
      expect(find.text('Invite co-parent'), findsOneWidget);
      expect(find.text('James — co-parent'), findsNothing);

      // Children: nothing but the call to action — no empty-state chrome and
      // no rows for children that do not exist.
      expect(find.text('Add child'), findsOneWidget);
      expect(find.text('Maya · 7–9'), findsNothing);
      expect(find.text('Leo · 4–6'), findsNothing);

      // Every other section still renders from the seeded settings row.
      expect(find.text('Nestling Annual · £29.99/year'), findsOneWidget);
      await scrollSettingsTo(tester, find.text('Approvals waiting'));
      expect(find.text('Approvals waiting'), findsOneWidget);
      await scrollSettingsTo(tester, find.text('Version 1.0.0'));
      expect(find.text('Version 1.0.0'), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('the lock hint reflects the DB kid-gate value', (tester) async {
      await pumpSettingsApp(tester, seedDemo: false, prepare: Seed.empty);
      await scrollSettingsTo(
        tester,
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.textSpan?.toPlainText() == 'Kid mode needs parent gate — On',
        ),
      );

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.textSpan?.toPlainText() == 'Kid mode needs parent gate — On',
        ),
        findsOneWidget,
        reason: 'the seeded family has the parent gate on',
      );

      await disposeApp(tester);
    });
  });

  group('P16 DATA OVER MOCKS — the parent e-mail', () {
    // ORCHESTRATOR_NOTES (08:12, "LAST pass") item 2: the parent's e-mail must
    // come from the database, and states "the seed holds that value". It does
    // not: no table in the schema has an e-mail column, which the integrator
    // measured and recorded in SHARED_REQUEST.md §4. The ruling's own fallback
    // ("if the DB lacks a field, write SHARED_REQUEST.md") is what applies, so
    // the two tests below record the situation instead of asserting a
    // DB-driven value that cannot exist yet.
    testWidgets('TRIPWIRE: `members` still has no e-mail column', (
      tester,
    ) async {
      final database = GetIt.instance<AppDatabase>();
      final columns = await database
          .customSelect('PRAGMA table_info(members)')
          .get();
      final names = columns.map((row) => row.read<String>('name')).toList();

      expect(
        names,
        isNot(contains('email')),
        reason:
            'the members table now HAS an email column, so '
            'ORCHESTRATOR_NOTES (08:12) item 2 is satisfiable: replace the '
            'hard-coded `sarah@example.co.uk` in settings_view.dart with a '
            'repository read (members.email for the owner row) and update the '
            'four tests that assert the literal. Until then this tripwire is '
            'the only thing standing between the ruling and silence.',
      );
      // The rest of the owner row IS database-driven, and stays that way
      // (`role` is what decides "— you" vs "— co-parent"). SQL column names
      // are snake_case; the drift column names are camelCase.
      expect(
        names,
        containsAll(<String>[
          'id',
          'family_id',
          'name',
          'role',
          'invite_status',
        ]),
      );

      await disposeApp(tester);
    });

    testWidgets('the owner row shows the seeded name with the literal e-mail', (
      tester,
    ) async {
      // The other half of the ruling: the NAME must come from the database
      // (DATA OVER MOCKS), so change the seed and the row follows. The
      // subtitle beside it is the documented exception.
      await pumpSettingsApp(
        tester,
        prepare: (db) =>
            (db.update(db.members)..where((m) => m.id.equals('sarah'))).write(
              const MembersCompanion(name: Value('Sam')),
            ),
      );

      expect(find.text('Sam — you'), findsOneWidget);
      expect(
        find.text('sarah@example.co.uk'),
        findsOneWidget,
        reason:
            'documented placeholder copy (SHARED_REQUEST.md §4): no column '
            'holds an e-mail, so this cannot be DB-driven yet',
      );

      await disposeApp(tester);
    });
  });

  group('P16 coin pluralisation is data-driven', () {
    // Iteration 2 (P16-B05): `_ChildRow` pluralises. The bug proof pins the
    // singular; this pins the whole rule from the DATABASE, so 0 and 2 cannot
    // regress silently and the copy stays "N coins" for the seeded balances.
    for (final coins in <int>[0, 1, 2, 120]) {
      testWidgets('a child with $coins coin(s) reads the right noun', (
        tester,
      ) async {
        await pumpSettingsApp(
          tester,
          prepare: (db) =>
              (db.update(db.children)..where((c) => c.id.equals('leo'))).write(
                ChildrenCompanion(coins: Value(coins)),
              ),
        );

        await scrollSettingsTo(tester, find.text('Leo · 4–6'));
        expect(
          find.text(
            'Pip: Hatchling · ${coins == 1 ? '1 coin' : '$coins coins'}',
          ),
          findsOneWidget,
          reason: 'the roster reads the stored balance ($coins)',
        );

        await disposeApp(tester);
      });
    }

    testWidgets('the seeded balances keep the design copy', (tester) async {
      await pumpSettingsApp(tester);

      // DATA OVER MOCKS: the demo seed is 120 / 45 (RULES §4).
      expect(find.text('Pip: Fledgling · 120 coins'), findsOneWidget);
      await scrollSettingsTo(tester, find.text('Leo · 4–6'));
      expect(find.text('Pip: Hatchling · 45 coins'), findsOneWidget);

      await disposeApp(tester);
    });
  });

  group('P16 dark mode', () {
    testWidgets('renders every section on the dark paper', (tester) async {
      await pumpSettingsApp(tester, theme: ThemeMode.dark);
      final dark = p16Tokens(ThemeMode.dark);

      final scaffold = tester.widget<Scaffold>(
        find
            .descendant(
              of: find.byType(SettingsView),
              matching: find.byType(Scaffold),
            )
            .first,
      );
      expect(scaffold.backgroundColor, dark.paper);
      expect(find.text('Family & settings'), findsOneWidget);
      expect(find.text('Sarah — you'), findsOneWidget);
      expect(find.text('Invite co-parent'), findsOneWidget);

      // Cards are `surface`, never the page tint, in dark too.
      final lists = find.byType(NestList);
      expect(lists, findsWidgets);
      final decoration =
          tester
                  .widget<Container>(
                    find
                        .descendant(
                          of: lists.first,
                          matching: find.byType(Container),
                        )
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expect(decoration.color, dark.surface);

      await scrollSettingsTo(tester, find.text('Maya · 7–9'));
      expect(find.text('Maya · 7–9'), findsOneWidget);
      await scrollSettingsTo(tester, find.text('Version 1.0.0'));
      expect(find.text('Made in the UK · No ads, ever'), findsOneWidget);

      expect(tester.takeException(), isNull, reason: 'no dark-mode overflow');
      await disposeApp(tester);
    });

    testWidgets('the tab bar keeps its own surface to the physical edge', (
      tester,
    ) async {
      for (final theme in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
        await pumpSettingsApp(tester, theme: theme);
        expect(
          tester.getRect(find.byType(NestTabBar)).bottom,
          p16DesignSize.height,
          reason: 'BOTTOM EDGE ($theme): no coloured strip below the bar',
        );
        await disposeApp(tester);
      }
    });
  });
}

/// Fails the first `watchRoster` subscription, then delegates to the real
/// repository — the failure/retry shape without breaking the database.
class _FailsOnceRepository implements SettingsRepository {
  _FailsOnceRepository(this._inner);

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
