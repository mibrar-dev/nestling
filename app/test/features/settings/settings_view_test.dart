// P16 Settings — widget contract for the redesigned Family & settings
// screen (Stage 2b): char-exact copy, DB-driven rows, write-through
// toggles, the time-zone row and the one-time move banner.
//
// The full-app route wiring is covered by the router; these tests pump
// SettingsView directly with a bloc built around the in-memory database,
// exactly like the P14 view tests, so the move-banner device zone is a
// fake rather than the host timezone.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/family_zone_service.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/settings/domain/settings_repository.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_event.dart';
import 'package:nestling/features/settings/presentation/views/settings_view.dart';
import 'package:nestling/features/settings/presentation/widgets/p16_transient_guard.dart';
import 'package:nestling/features/settings/presentation/widgets/settings_rows.dart';

import '../../test_scope.dart';
import 'p16_test_support.dart' show p16PinnedNowUtc;

Future<void> _loadBundledFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
  await inter.load();
  await nunito.load();
}

SettingsBloc _blocWithDeviceZone(String? deviceZone) {
  return SettingsBloc(
    repository: GetIt.instance<SettingsRepository>(),
    zoneService: FamilyZoneService(
      GetIt.instance<AppDatabase>(),
      deviceZoneReader: deviceZone == null
          ? () async => throw Exception('no device zone')
          : () async => deviceZone,
    ),
  );
}

Future<void> _pumpView(WidgetTester tester, SettingsBloc bloc) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  P16TransientGuard.reset();
  await tester.pumpWidget(
    MaterialApp(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      home: BlocProvider<SettingsBloc>.value(
        value: bloc,
        child: const SettingsView(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 14 && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -260));
    await tester.pumpAndSettle();
  }
}

Future<List<Setting>> _settingRows() {
  final db = GetIt.instance<AppDatabase>();
  return (db.select(
    db.settings,
  )..where((s) => s.familyId.equals(Seed.familyId))).get();
}

Future<String> _familyZone() async {
  final db = GetIt.instance<AppDatabase>();
  final row = await (db.select(
    db.families,
  )..where((f) => f.id.equals(Seed.familyId))).getSingle();
  return row.timeZone;
}

void main() {
  setUpAll(_loadBundledFonts);

  group('P16 settings view', () {
    testWidgets('renders the design copy char-exactly, DB values live', (
      tester,
    ) async {
      await setUpTestScope();
      final bloc = _blocWithDeviceZone(null)
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, bloc);

      // Exact glyphs: em dash —, middle dot ·, ampersand &.
      expect(find.text('Family & settings'), findsOneWidget);
      expect(find.text('Sarah — you'), findsOneWidget);
      // The owner subtitle is `members.email` read from the database (DATA
      // OVER MOCKS, ORCHESTRATOR_NOTES 08:12 item 2 / shared batch 6 item 4)
      // — the seed's value here, and the view follows it when it changes.
      expect(find.text('sarah@example.co.uk'), findsOneWidget);
      expect(find.text('James — co-parent'), findsOneWidget);
      expect(find.text('Invited · awaiting reply'), findsOneWidget);
      expect(find.text('Invite co-parent'), findsOneWidget);
      expect(find.text('Share the load'), findsOneWidget);
      // En dash – in age bands; coins/stage names from the DB (Maya first).
      expect(find.text('Maya · 7–9'), findsOneWidget);
      expect(find.text('Pip: Fledgling · 120 coins'), findsOneWidget);
      expect(find.text('Leo · 4–6'), findsOneWidget);
      expect(find.text('Pip: Hatchling · 45 coins'), findsOneWidget);
      expect(find.text('Add child'), findsOneWidget);
      expect(find.text('Nickname + age band only'), findsOneWidget);
      expect(find.text('Nestling Annual · £29.99/year'), findsOneWidget);
      expect(
        find.text('Renews 18 Oct 2027 · Covers the whole family'),
        findsOneWidget,
      );
      expect(find.text('Manage subscription'), findsOneWidget);

      // Below the fold: scroll section by section (the ListView only
      // builds the visible window).
      await _scrollTo(tester, find.text('Approvals waiting'));
      expect(find.text('Approvals waiting'), findsOneWidget);
      expect(find.text('Payout day reminder'), findsOneWidget);
      expect(find.text('Friday before Saturday payout'), findsOneWidget);
      expect(find.text('Weekly family summary'), findsOneWidget);

      await _scrollTo(tester, find.text('Delete family account'));
      expect(find.text('Download our data'), findsOneWidget);
      expect(find.text('Privacy Notice'), findsOneWidget);
      expect(find.text('Delete family account'), findsOneWidget);
      expect(
        find.textContaining('Kid mode needs parent gate — '),
        findsOneWidget,
      );
      // Lock hint reflects kidGateEnabled from the DB (On). It renders as
      // one rich-text paragraph, so match its plain text directly.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.textSpan?.toPlainText() == 'Kid mode needs parent gate — On',
        ),
        findsOneWidget,
      );

      await _scrollTo(tester, find.text('Version 1.0.0'));
      expect(find.text('Help & feedback'), findsOneWidget);
      expect(find.text('Version 1.0.0'), findsOneWidget);
      expect(find.text('Made in the UK · No ads, ever'), findsOneWidget);

      unawaited(bloc.close());
      await disposeApp(tester);
    });

    testWidgets('time-zone row shows the short label and GMT offset', (
      tester,
    ) async {
      await setUpTestScope();
      final bloc = _blocWithDeviceZone(null)
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, bloc);

      // Pinned, never the wall clock: tests run at Sat 3 Oct 2026 09:41
      // Europe/London (= 08:41Z, BST) per `test/flutter_test_config.dart`,
      // and app code must read the clock through `clock.now()`/`appNowUtc()`
      // rather than `DateTime.now()` (CLOCK rule).
      final expected =
          'London (${gmtOffsetLabel('Europe/London', p16PinnedNowUtc)})';
      await _scrollTo(tester, find.text(expected));
      expect(find.text('Time zone'), findsWidgets);
      expect(find.text(expected), findsOneWidget);

      unawaited(bloc.close());
      await disposeApp(tester);
    });

    testWidgets('toggle has a tap action and writes through to the DB', (
      tester,
    ) async {
      await setUpTestScope();
      final handle = tester.ensureSemantics();
      final bloc = _blocWithDeviceZone(null)
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, bloc);

      final before = (await _settingRows()).single.notifApprovals;
      await _scrollTo(tester, find.text('Approvals waiting'));
      // The toggle's semantics node merges with the row title text, so
      // the merged data label carries both lines; match by substring.
      final toggle = find.semantics.byLabel(
        RegExp('Approvals waiting notifications'),
      );
      expect(toggle.evaluate(), hasLength(1));
      final data = toggle.evaluate().first.getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      tester.semantics.performAction(toggle, SemanticsAction.tap);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect((await _settingRows()).single.notifApprovals, !before);

      handle.dispose();
      unawaited(bloc.close());
      await disposeApp(tester);
    });

    testWidgets('move banner shows the device zone, Switch stores it', (
      tester,
    ) async {
      await setUpTestScope();
      final bloc = _blocWithDeviceZone('Asia/Dubai')
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, bloc);

      expect(
        find.textContaining('Looks like you’re in Dubai now.'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('p16_move_switch')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(await _familyZone(), 'Asia/Dubai');
      expect(find.byKey(const ValueKey('p16_move_banner')), findsNothing);

      unawaited(bloc.close());
      await disposeApp(tester);
    });

    testWidgets('move banner Not now hides it and keeps the DB zone', (
      tester,
    ) async {
      await setUpTestScope();
      final bloc = _blocWithDeviceZone('Asia/Dubai')
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, bloc);

      await tester.tap(find.byKey(const ValueKey('p16_move_not_now')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const ValueKey('p16_move_banner')), findsNothing);
      expect(await _familyZone(), 'Europe/London');

      unawaited(bloc.close());
      await disposeApp(tester);
    });

    testWidgets('picker lists the device zone first with its IANA hint', (
      tester,
    ) async {
      await setUpTestScope();
      final bloc = _blocWithDeviceZone('Asia/Dubai')
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, bloc);

      await _scrollTo(tester, find.text('Time zone'));
      await tester.tap(find.text('Time zone').first);
      await tester.pumpAndSettle();

      // Device row leads the sheet: IANA id + "Current location" (raw ids
      // are allowed only inside the picker).
      expect(find.text('Asia/Dubai · Current location'), findsOneWidget);
      expect(
        find.text(
          'Europe/London · ${gmtOffsetLabel('Europe/London', p16PinnedNowUtc)}',
        ),
        findsOneWidget,
      );

      unawaited(bloc.close());
      await disposeApp(tester);
    });

    testWidgets('picking a zone in the sheet writes it to the DB', (
      tester,
    ) async {
      await setUpTestScope();
      final bloc = _blocWithDeviceZone('Asia/Dubai')
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, bloc);

      await _scrollTo(tester, find.text('Time zone'));
      await tester.tap(find.text('Time zone').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dubai').first);
      await tester.pumpAndSettle();

      expect(await _familyZone(), 'Asia/Dubai');

      unawaited(bloc.close());
      await disposeApp(tester);
    });

    testWidgets('delete row opens the confirm modal; Cancel keeps data', (
      tester,
    ) async {
      await setUpTestScope();
      final bloc = _blocWithDeviceZone(null)
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, bloc);

      await _scrollTo(tester, find.text('Delete family account'));
      await tester.tap(find.text('Delete family account'));
      await tester.pumpAndSettle();

      expect(find.text('Delete family account?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('p16_delete_cancel')));
      await tester.pumpAndSettle();
      expect(find.text('Delete family account?'), findsNothing);

      unawaited(bloc.close());
      await disposeApp(tester);
    });

    // Review finding 2 (iteration 6): every switch used to be routed through
    // `P16TransientGuard.run`, so opening the Time zone sheet, picking a zone
    // and then immediately flipping "Approvals waiting" (the section directly
    // below the dismissed sheet) was swallowed by the 300 ms window — a dead
    // tap with no feedback. The guard exists for the double-tap fall-through
    // onto rows that OPEN a modal or route; a switch flip cannot re-fire
    // itself, so it needs no fence. The guard itself still stands for the
    // rows (proven in p16_transient_guard_test.dart).
    testWidgets('[review 2] all three switches still flip while the guard is '
        'armed', (tester) async {
      await setUpTestScope();
      final bloc = _blocWithDeviceZone(null)
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, bloc);

      // One guard window per switch: pumping between taps would expire the
      // first one and the second tap would prove nothing.
      for (final entry in <(String, bool Function(Setting))>[
        ('Approvals waiting', (s) => s.notifApprovals),
        ('Payout day reminder', (s) => s.notifPayout),
        ('Weekly family summary', (s) => s.notifSummary),
      ]) {
        await _scrollTo(tester, find.text(entry.$1));
        final before = entry.$2((await _settingRows()).single);

        P16TransientGuard.reset();
        P16TransientGuard.suppressShortly();
        expect(
          P16TransientGuard.suppressing,
          isTrue,
          reason: 'the guard must really be armed, or this proves nothing',
        );

        final track = tester.getRect(
          find
              .descendant(
                of: find.ancestor(
                  of: find.text(entry.$1),
                  matching: find.byWidgetPredicate(
                    (w) => w is SettingsRow || w is NestListRow,
                  ),
                ),
                matching: find.byType(NestToggle),
              )
              .first,
        );
        await tester.tapAt(track.center);
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          entry.$2((await _settingRows()).single),
          !before,
          reason:
              '"${entry.$1}" must flip inside the guard window — it cannot '
              're-fire itself, so the fence is never the thing protecting it',
        );
        expect(
          P16TransientGuard.suppressing,
          isTrue,
          reason: 'the flip must have happened BEFORE the window expired',
        );
      }

      P16TransientGuard.reset();
      unawaited(bloc.close());
      await disposeApp(tester);
    });

    // Review finding 3 (iteration 6): the subscription card is not tappable as
    // a card, so `NestCard` renders its plain `Container` branch — a bare
    // Container carries no Material, which left the nested `InkWell` resolving
    // its ink to the Scaffold's Material BEHIND the card's opaque surface, so
    // "Manage subscription" painted no ripple at all.
    testWidgets('[review 3] "Manage subscription" paints its ripple on the '
        'card, not behind it', (tester) async {
      await setUpTestScope();
      final bloc = _blocWithDeviceZone(null)
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, bloc);

      final card = find
          .ancestor(
            of: find.text('Nestling Annual · £29.99/year'),
            matching: find.byType(NestCard),
          )
          .first;
      final linkRow = find
          .descendant(of: card, matching: find.byType(InkWell))
          .first;

      // A Material strictly between the InkWell and the card is what gives the
      // ripple a surface to paint on. Ancestors alone would be satisfied by the
      // Scaffold's Material — which is exactly the defect being pinned.
      final between = find
          .descendant(of: card, matching: find.byType(Material))
          .evaluate()
          .map((e) => e.widget)
          .where(
            find
                .ancestor(of: linkRow, matching: find.byType(Material))
                .evaluate()
                .map((e) => e.widget)
                .toSet()
                .contains,
          );
      expect(
        between,
        isNotEmpty,
        reason:
            'the link row needs its own ink surface inside the card; the '
            'non-tappable `NestCard` branch ships none',
      );

      unawaited(bloc.close());
      await disposeApp(tester);
    });
  });
}
