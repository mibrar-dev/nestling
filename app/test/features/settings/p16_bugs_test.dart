// P16 · Family & settings — adversarial bug proofs (Stage 6).
//
// Iteration 1 found B01–B07; iteration 2 found B08/B09; iteration 3 found
// B10/B11. All but one are now fixed with live proofs: the iteration-3 build
// closed B08 (P16TransientGuard) and T02, the iteration-4 build closed B11
// (`width: 51` on the switch wrapper) and B10 (guard on the delete/invite
// rows). The single open finding is:
//   * [P16-B09] open (minor, shared) — IANA *link* ids (Europe/Amsterdam,
//     Asia/Calcutta, …) are treated as unknown by the bundled tz dataset;
//     fix belongs in core `family_time.dart` (SHARED_REQUEST §5), and no
//     feature-side hook exists.
// Open bugs carry `skip: true` so `flutter test` stays green;
// `flutter test test/features/settings/p16_bugs_test.dart --run-skipped`
// proves B09 fails (evidence in docs/screens/P16/6_bugs.md).
//
// The `verified clean` group holds the attacks that were run and held:
// deep-link guards (kid mode / onboarding / trial-expiry), back navigation,
// real-app loading with a real event loop, 0 children and 6 children with
// long names, coin extremes, 320 px + 1.3 text scale, toggle persistence
// across a restart, rapid double taps on rows/sheets, the accessibility tap
// contract, Europe/London BST offsets and dark-mode contrast. Every guard
// runs unskipped. (The guard's 300 ms window itself is pinned by the test
// stage's `p16_transient_guard_test.dart`.)

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/family_zone_service.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/settings/domain/settings_repository.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_event.dart';
import 'package:nestling/features/settings/presentation/views/settings_view.dart';
import 'package:nestling/features/settings/presentation/widgets/p16_transient_guard.dart';

import '../../test_scope.dart';
import 'p16_test_support.dart';

/// Widget tests do not load the bundled families automatically; the layout
/// proofs (320 × 1.3 overflow, semantics nodes) need the real metrics.
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

/// A bloc over the in-memory database whose device-zone read is a fake, so
/// the move banner and the picker's "Current location" row are deterministic
/// (the harness of `settings_view_test.dart`; `null` = unreadable).
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

Future<void> _pumpView(
  WidgetTester tester,
  SettingsBloc bloc, {
  Size size = const Size(390, 844),
  bool dark = false,
}) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? NestTheme.dark() : NestTheme.light(),
      darkTheme: NestTheme.dark(),
      home: BlocProvider<SettingsBloc>.value(
        value: bloc,
        child: const SettingsView(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  P16TransientGuard.reset();
}

/// A miniature router exposing `/settings` plus the four targets P16 pushes,
/// so navigation and sheet behaviour can be observed without the full shell.
Future<void> _pumpRouted(
  WidgetTester tester,
  SettingsBloc bloc, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = Size(size.width * 3, size.height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: '/settings',
    routes: <RouteBase>[
      GoRoute(
        path: '/settings',
        builder: (_, _) => BlocProvider<SettingsBloc>.value(
          value: bloc,
          child: const SettingsView(),
        ),
      ),
      for (final path in <String>[
        '/child-profile',
        '/add-children',
        '/paywall',
        '/privacy',
      ])
        GoRoute(
          path: path,
          builder: (_, _) => Scaffold(body: Text('PUSHED$path')),
        ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      theme: NestTheme.light(),
      darkTheme: NestTheme.dark(),
      routerConfig: router,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  P16TransientGuard.reset();
}

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 16 && finder.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView).first, const Offset(0, -260));
    await tester.pumpAndSettle();
  }
}

Future<Setting> _settingRow() {
  final db = GetIt.instance<AppDatabase>();
  return (db.select(
    db.settings,
  )..where((s) => s.familyId.equals(Seed.familyId))).getSingle();
}

/// WCAG relative luminance / contrast for the dark-mode guard.
double _relativeLuminance(Color c) {
  double lin(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
}

double _contrast(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  setUpAll(_loadBundledFonts);

  // -------------------------------------------------------------------------
  // Open bugs — skipped (id in the test name); `--run-skipped` proves the
  // failure. The comment above each `skip:` records the finding for the
  // iteration-2 build.
  // -------------------------------------------------------------------------

  testWidgets(
    '[P16-B01] the picker keeps the device zone after “Not now”',
    (tester) async {
      await setUpTestScope();
      // Dismiss the Dubai prompt in this visit, then open the picker.
      final bloc = _blocWithDeviceZone('Asia/Dubai')
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, bloc);
      await tester.tap(find.byKey(const ValueKey('p16_move_not_now')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('p16_move_banner')), findsNothing);

      await _scrollTo(tester, find.text('Time zone'));
      await tester.tap(find.text('Time zone').first);
      await tester.pumpAndSettle();
      final deviceRows = find
          .text('Asia/Dubai · Current location')
          .evaluate()
          .length;
      unawaited(bloc.close());
      await disposeApp(tester);

      expect(
        deviceRows,
        1,
        reason:
            'P16-B01: ORCHESTRATOR_NOTES requires the picker to list the '
            'device zone first “when known and ≠ family zone”. The picker '
            'derives it from state.pendingZone, which “Not now” nulls, so '
            'after one dismissal the device row and its “· Current location” '
            'marker disappear while the device zone still differs '
            '(deviceRows=$deviceRows).',
      );
    },
    // P16-B01 fixed in iteration 2 (2a deviceZoneId + 2b picker): the
    // picker orders by state.deviceZoneId, which survives a dismissal. Live
    // proof.
    skip: false,
  );

  testWidgets(
    '[P16-B02] “Not now” hides the move prompt for the whole session',
    (tester) async {
      await setUpTestScope();
      // First visit: dismiss the Dubai prompt.
      final blocA = _blocWithDeviceZone('Asia/Dubai')
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, blocA);
      await tester.tap(find.byKey(const ValueKey('p16_move_not_now')));
      await tester.pumpAndSettle();
      unawaited(blocA.close());
      await disposeApp(tester);

      // Same session, same DB: a fresh visit rebuilds the route's bloc.
      final blocB = _blocWithDeviceZone('Asia/Dubai')
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, blocB);
      final bannerShown = find
          .byKey(const ValueKey('p16_move_banner'))
          .evaluate()
          .length;
      unawaited(blocB.close());
      await disposeApp(tester);

      expect(
        bannerShown,
        0,
        reason:
            'P16-B02: ORCHESTRATOR_NOTES says the prompt shows exactly once '
            '“until confirmed or dismissed for the session”. dismissedZones '
            'lives in the route-scoped bloc and every /settings visit builds '
            'a new bloc, so the prompt returns in the same session '
            '(bannerShown=$bannerShown).',
      );
    },
    // P16-B02 fixed in iteration 2 (logic half): "Not now" dismissals live
    // in the session-scoped SettingsSessionStore, so a rebuilt bloc inherits
    // them and the prompt stays hidden for the session.
  );

  testWidgets(
    '[P16-B03] the zone picker scrolls instead of overflowing on 320×568 @1.3',
    (tester) async {
      await setUpTestScope();
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final bloc = _blocWithDeviceZone('Asia/Dubai')
        ..add(const SettingsLoadRequested());
      await _pumpRouted(tester, bloc, size: const Size(320, 568));
      await _scrollTo(tester, find.text('Time zone'));
      await tester.tap(find.text('Time zone').first);
      await tester.pumpAndSettle();

      final overflow = tester.takeException();
      unawaited(bloc.close());
      await disposeApp(tester);
      expect(
        overflow,
        isNull,
        reason:
            'P16-B03: the sheet Column is not scrollable, so on a 320×568 '
            'screen at 1.3 text scale the 7-row zone list overflows and eats '
            'the home-edge padding. Measured: $overflow',
      );
    },
    // P16-B03 fixed in iteration 2 (2b): the picker column is a
    // Flexible + SingleChildScrollView, so it scrolls when capped. Live
    // proof (320×568 @ 1.3, no overflow).
    skip: false,
  );

  test(
    '[P16-B04] feature code never calls DateTime.now()',
    () {
      const files = <String>[
        'lib/features/settings/presentation/views/settings_view.dart',
        'lib/features/settings/presentation/widgets/zone_picker_sheet.dart',
        'lib/features/settings/data/settings_repository_impl.dart',
      ];
      final offenders = <String>[];
      for (final file in files) {
        final source = File(file).readAsStringSync();
        final matches = RegExp(r'DateTime\.now\(\)').allMatches(source);
        for (final match in matches) {
          final line = source.substring(0, match.start).split('\n').length;
          offenders.add('$file:$line');
        }
      }
      expect(
        offenders,
        isEmpty,
        reason:
            'P16-B04: the CLOCK rule forbids DateTime.now() in app code — '
            'the zone offset label and write timestamps must come from the '
            'shared clock (appNowUtc()). Offenders: $offenders',
      );
    },
    // P16-B04 open (minor, matches 4_review finding 4) — 4 DateTime.now()
    // calls in feature code (settings_view.dart:115,
    // zone_picker_sheet.dart:85, settings_repository_impl.dart:114/125).
    // Fix after the main merge: swap them for appNowUtc()
    // (lib/core/data/app_clock.dart).
    // P16-B04 FIXED in iteration 2: views use appNowUtc(); the repo
    // writes appNowUtc(); no DateTime.now() remains in feature code.
    skip: false,
  );

  testWidgets(
    '[P16-B05] a single coin reads “1 coin”, not “1 coins”',
    (tester) async {
      await setUpTestScope();
      final db = GetIt.instance<AppDatabase>();
      await (db.update(db.children)..where((c) => c.id.equals('leo'))).write(
        const ChildrenCompanion(coins: Value(1)),
      );
      final bloc = _blocWithDeviceZone(null)
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, bloc);
      await _scrollTo(tester, find.text('Leo · 4–6'));
      final singular = find.text('Pip: Hatchling · 1 coin').evaluate().length;
      final plural = find.text('Pip: Hatchling · 1 coins').evaluate().length;
      unawaited(bloc.close());
      await disposeApp(tester);

      expect(
        singular,
        1,
        reason:
            'P16-B05: the row hard-codes the plural suffix '
            '("<coins> coins"), so a child with exactly 1 coin reads '
            '“1 coins”. singular=$singular plural=$plural',
      );
    },
    // P16-B05 fixed in iteration 2 (2b): `_ChildRow` singularises. Live
    // proof (Leo at 1 coin reads “1 coin”).
    skip: false,
  );

  testWidgets(
    '[P16-B06] the subscription card uses the design’s 16 px corner radius',
    (tester) async {
      await setUpTestScope();
      final bloc = _blocWithDeviceZone(null)
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, bloc);
      await _scrollTo(tester, find.text('Nestling Annual · £29.99/year'));

      final card = tester.widget<Container>(
        find
            .ancestor(
              of: find.text('Nestling Annual · £29.99/year'),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = card.decoration! as BoxDecoration;
      final radius = decoration.borderRadius;
      unawaited(bloc.close());
      await disposeApp(tester);

      expect(
        radius,
        NestRadii.allM,
        reason:
            'P16-B06: design/html-source/screens/P16-settings.html line 7 '
            'pins .subcard{border-radius:var(--r-m)} = 16 px, but the card '
            'renders with NestCard.standard’s r-l (24 px). All other cards on '
            'the screen use 16. Actual: $radius',
      );
    },
    // P16-B06 fixed in iteration 2 (2b): the subcard uses
    // `NestRadii.allM` + cardShadow. Live proof.
    skip: false,
  );

  testWidgets(
    '[P16-B07] Cancel closes the delete dialog, never the settings page',
    (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/settings');
      // Real event-loop time for the bloc's platform read (see the
      // `P16-clean` loading guard below).
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await _scrollTo(tester, find.text('Delete family account'));
      await tester.tap(find.text('Delete family account'));
      await tester.pumpAndSettle();
      expect(find.text('Delete family account?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('p16_delete_cancel')));
      await tester.pump();
      final failure = tester.takeException();
      await tester.pump(const Duration(milliseconds: 400));
      final dialogOpen = find
          .text('Delete family account?')
          .evaluate()
          .isNotEmpty;
      await disposeApp(tester);

      expect(
        failure,
        isNull,
        reason:
            'P16-B07: the dialog lives on the ROOT navigator (showDialog '
            'default) but Cancel pops via the outer SettingsView context, '
            'which resolves to the shell branch navigator. Popping /settings '
            'off its branch throws the GoRouter “no pages left” assertion '
            '(debug) and destroys the route tree; the dialog never closes. '
            'dialogOpen=$dialogOpen failure=$failure',
      );
    },
    // P16-B07 fixed in iteration 2 (UI half): both modal buttons pop with
    // `rootNavigator: true`, so Cancel/Delete close the dialog and the
    // settings page stays. Live proof.
    skip: false,
  );

  testWidgets(
    '[P16-B08] a double tap while the picker closes cannot open another screen',
    (tester) async {
      // The real app harness (same scroll positions as the staged probes).
      await pumpSettingsApp(tester);
      await scrollSettingsTo(tester, find.text('Time zone'));
      await tester.tap(find.text('Time zone').first);
      await tester.pumpAndSettle();

      // Tap the current-zone row, then tap the same spot again 60 ms later —
      // a normal impatient double tap.
      final row = find.text('London');
      await tester.tap(row);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(row, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final failure = tester.takeException();
      final path = pushedPath(tester);
      await disposeApp(tester);

      expect(
        path,
        '/settings',
        reason:
            'P16-B08: the closing sheet stops absorbing pointers before its '
            'exit animation ends, so a second tap at the same coordinates '
            'lands on the settings row underneath and navigates away '
            '(repro: the Privacy section is under the picker rows). '
            'path=$path failure=$failure',
      );
    },
    // P16-B08 fixed in iteration 3 (UI half): `P16TransientGuard` suppresses
    // row taps for 300 ms after a modal/sheet close, so the picker
    // fall-through no longer navigates. Live proof for this repro; the
    // unfenced rows are pinned separately as P16-B10.
    skip: false,
  );

  testWidgets(
    '[P16-B09] the picker shows the device zone for a linked IANA id',
    (tester) async {
      await setUpTestScope();
      // A real phone zone: tzdb lists Europe/Amsterdam as a link to
      // Europe/Brussels, not as a canonical location.
      final bloc = _blocWithDeviceZone('Europe/Amsterdam')
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, bloc);
      await _scrollTo(tester, find.text('Time zone'));
      await tester.tap(find.text('Time zone').first);
      await tester.pumpAndSettle();

      final deviceRow = find
          .text('Europe/Amsterdam · Current location')
          .evaluate()
          .length;
      unawaited(bloc.close());
      await disposeApp(tester);

      expect(
        deviceRow,
        1,
        reason:
            'P16-B09: the bundled `latest_10y` dataset has 341 locations and '
            'no IANA links, so `isKnownZoneId("Europe/Amsterdam")` is false, '
            '`FamilyZoneService.deviceZoneId()` returns null and a Dutch '
            'phone gets no move prompt and no “Current location” row. '
            'deviceRow=$deviceRow',
      );
    },
    // P16-B09 open (minor, shared) — linked IANA ids (Europe/Amsterdam,
    // Asia/Calcutta, US/Pacific, Europe/Kiev, Asia/Saigon, …) are rejected
    // by `isKnownZoneId`/`normalizeZoneId` (core `family_time.dart:37-78`),
    // so the device zone is unreadable on those phones. Fix belongs in the
    // shared layer: resolve backward links to their canonical zone (or ship
    // the dataset’s links); recorded in SHARED_REQUEST §5. Feature-side no
    // workaround exists — the raw id never reaches the bloc.
    skip: true,
  );

  testWidgets(
    '[P16-B10] a double tap on Cancel cannot re-open the delete dialog',
    (tester) async {
      await pumpSettingsApp(tester);
      await scrollSettingsTo(tester, find.text('Delete family account'));
      await tester.tap(find.text('Delete family account'));
      await tester.pumpAndSettle();

      // Impatient double tap on Cancel: the first closes the dialog, the
      // second falls through to the row underneath (Delete family account).
      final cancel = find.byKey(const ValueKey('p16_delete_cancel'));
      await tester.tap(cancel);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(cancel, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final dialog = find.text('Delete family account?').evaluate().length;
      await disposeApp(tester);
      expect(
        dialog,
        0,
        reason:
            'P16-B10: the B08 guard fences the picker/nav rows but NOT the '
            'delete row, so the Cancel double tap falls through to it and '
            're-opens the dialog (dialog=$dialog). The same hole lets a '
            'picker double tap on a row whose coordinates land on the '
            'delete row (repro: New York) open the dialog.',
      );
    },
    // P16-B10 fixed in iteration 4: the delete row's and the invite row's
    // onTap route through `P16TransientGuard.run` like every other row, so
    // the fall-through cannot reach them. Live proof (Cancel ×2 → no dialog;
    // picker New York ×2 → no dialog).
    skip: false,
  );

  testWidgets(
    '[P16-B11] the three switches sit on the row’s right edge',
    (tester) async {
      await pumpSettingsApp(tester);
      await scrollSettingsTo(tester, find.text('Weekly family summary'));

      final gaps = <double>[];
      final count = find.byType(NestToggle).evaluate().length;
      for (var i = 0; i < count; i++) {
        final finder = find.byType(NestToggle).at(i);
        final track = tester.getRect(finder);
        final row = tester.getRect(
          find.ancestor(of: finder, matching: find.byType(Padding)).first,
        );
        // The row's right content edge is its 16 px right padding inset;
        // the design puts the switch flush with it (iteration 2 matched).
        gaps.add((row.right - 16) - track.right);
      }
      await disposeApp(tester);
      expect(
        gaps,
        everyElement(lessThanOrEqualTo(2.0)),
        reason:
            'P16-B11: the T02 wrapper `SizedBox(height: 44, Center(...))` '
            'lets the Center expand into `NestListRow.trailMaxWidth` (120), '
            'centring the 51 px track 34.5 px left of the design position. '
            'Measured gaps to the right content edge: $gaps',
      );
    },
    // P16-B11 fixed in iteration 4: the wrapper is
    // `SizedBox(width: 51, height: 44, Center(...))`, so the track sits flush
    // with the row's 16 px right inset (gap 0.0 at 390 and 320) and the T02
    // slop is still live (±6). Live proof.
    skip: false,
  );

  // -------------------------------------------------------------------------
  // Verified clean — attacks that were run and held.
  // -------------------------------------------------------------------------

  group('verified clean', () {
    testWidgets(
      '[P16-clean] the real app reaches the loaded screen with a real event loop',
      (tester) async {
        // The bloc's load also waits on the device-zone read; under the fake
        // clock that platform round-trip needs real event-loop time
        // (`runAsync`), exactly as `p16_test_support.settleSettings` does.
        // With it, the real DI/router/service stack loads the screen — the
        // spinner is not a device-state dead end.
        await setUpTestScope();
        await pumpAppRoute(tester, '/settings');
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 250)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Family & settings'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await disposeApp(tester);
      },
    );

    testWidgets('[P16-clean] kid-mode deep link stops at the gate', (
      tester,
    ) async {
      await setUpTestScope();
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      final session = GetIt.instance<AppSession>();
      await session.setAppMode('kid');
      await session.refresh();

      await pumpAppRoute(tester, '/settings');
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentPath(tester), '/parental-gate');

      await disposeApp(tester);
    });

    testWidgets('[P16-clean] onboarding-incomplete deep link → /welcome', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.onboardingKids(db);
      await GetIt.instance<AppSession>().refresh();

      await pumpAppRoute(tester, '/settings');
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentPath(tester), '/welcome');

      await disposeApp(tester);
    });

    testWidgets('[P16-clean] aged-out trial deep link → /paywall', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();
      // 60 days elapsed on a 'trial' subscription: AppSession ages it out.
      await (db.update(db.appState)..where((a) => a.id.equals(1))).write(
        AppStateCompanion(
          trialStart: Value(
            DateTime.now().toUtc().subtract(const Duration(days: 60)),
          ),
        ),
      );
      await GetIt.instance<AppSession>().refresh();

      await pumpAppRoute(tester, '/settings');
      await tester.pump(const Duration(milliseconds: 400));
      expect(currentPath(tester), '/paywall');

      await disposeApp(tester);
    });

    testWidgets('[P16-clean] Back pops a pushed /settings', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');
      await tester.pump(const Duration(milliseconds: 300));
      unawaited(
        GoRouter.of(tester.element(find.byType(Navigator).first))
            .push('/settings'),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(pushedPath(tester), '/settings');

      final popped = await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 400));
      expect(popped, isTrue);
      expect(pushedPath(tester), '/today');

      await disposeApp(tester);
    });

    testWidgets('[P16-clean] Seed.empty: Sarah only, Add child, no James', (
      tester,
    ) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.empty(db);
      await GetIt.instance<AppSession>().refresh();
      final bloc = _blocWithDeviceZone(null)
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, bloc);

      expect(find.text('Sarah — you'), findsOneWidget);
      expect(find.text('James — co-parent'), findsNothing);
      expect(find.text('Add child'), findsOneWidget);
      expect(find.text('Nickname + age band only'), findsOneWidget);
      expect(tester.takeException(), isNull);

      unawaited(bloc.close());
      await disposeApp(tester);
    });

    testWidgets(
      '[P16-clean] 6 children, long names, 0/9999 coins at 320 px / 1.3',
      (tester) async {
        await setUpTestScope();
        final db = GetIt.instance<AppDatabase>();
        for (var i = 0; i < 4; i++) {
          await db
              .into(db.children)
              .insert(
                ChildrenCompanion.insert(
                  id: 'extra$i',
                  familyId: Seed.familyId,
                  nickname: i == 0 ? 'Maximilian-Alexander' : 'Child$i',
                  ageBand: const Value('7-9'),
                  pipStage: const Value(3),
                  coins: Value(switch (i) {
                    1 => 9999,
                    2 => 0,
                    _ => 120,
                  }),
                ),
              );
        }
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final bloc = _blocWithDeviceZone(null)
          ..add(const SettingsLoadRequested());
        await _pumpView(tester, bloc, size: const Size(320, 844), dark: true);

        var overflow = tester.takeException();
        await _scrollTo(tester, find.text('Maximilian-Alexander · 7–9'));
        expect(find.text('Maximilian-Alexander · 7–9'), findsOneWidget);
        await _scrollTo(tester, find.text('Pip: Fledgling · 9999 coins'));
        expect(find.text('Pip: Fledgling · 9999 coins'), findsOneWidget);
        await _scrollTo(tester, find.text('Pip: Fledgling · 0 coins'));
        expect(find.text('Pip: Fledgling · 0 coins'), findsOneWidget);
        // Scroll to the very bottom to make every section lay out.
        for (var i = 0; i < 20; i++) {
          await tester.drag(find.byType(ListView).first, const Offset(0, -260));
          await tester.pumpAndSettle();
          overflow = overflow ?? tester.takeException();
        }
        expect(overflow, isNull);

        unawaited(bloc.close());
        await disposeApp(tester);
      },
    );

    testWidgets('[P16-clean] toggles survive a restart (Drift persistence)', (
      tester,
    ) async {
      await setUpTestScope();
      final handle = tester.ensureSemantics();
      final blocA = _blocWithDeviceZone(null)
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, blocA);
      await _scrollTo(tester, find.text('Approvals waiting'));
      final before = (await _settingRow()).notifApprovals;
      tester.semantics.performAction(
        find.semantics.byLabel(RegExp('Approvals waiting notifications')),
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();
      expect((await _settingRow()).notifApprovals, !before);
      unawaited(blocA.close());
      await disposeApp(tester);

      // A restart = a fresh view and bloc over the same database.
      final blocB = _blocWithDeviceZone(null)
        ..add(const SettingsLoadRequested());
      await _pumpView(tester, blocB);
      await _scrollTo(tester, find.text('Approvals waiting'));
      expect(
        tester.widget<NestToggle>(find.byType(NestToggle).first).value,
        !before,
      );

      handle.dispose();
      unawaited(blocB.close());
      await disposeApp(tester);
    });

    testWidgets('[P16-clean] rapid double taps do not stack surfaces', (
      tester,
    ) async {
      await setUpTestScope();
      final bloc = _blocWithDeviceZone(null)
        ..add(const SettingsLoadRequested());
      await _pumpRouted(tester, bloc);

      // Two taps on the Time zone row in the same frame: one sheet.
      await _scrollTo(tester, find.text('Time zone'));
      final row = find.text('Time zone').first;
      await tester.tap(row);
      await tester.tap(row, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(NestBottomSheet), findsOneWidget);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      expect(find.byType(NestBottomSheet), findsNothing);

      // Two taps on the Maya row in the same frame: one pushed route.
      await _scrollTo(tester, find.text('Maya · 7–9'));
      final maya = find.text('Maya · 7–9');
      await tester.tap(maya);
      await tester.tap(maya, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('PUSHED/child-profile'), findsOneWidget);

      unawaited(bloc.close());
      await disposeApp(tester);
    });

    testWidgets(
      '[P16-clean] every control exposes a tap action; the toggle writes the DB',
      (tester) async {
        await setUpTestScope();
        final handle = tester.ensureSemantics();
        final bloc = _blocWithDeviceZone(null)
          ..add(const SettingsLoadRequested());
        await _pumpRouted(tester, bloc);

        const labels = <String>[
          'Invite co-parent',
          'Maya · 7–9',
          'Leo · 4–6',
          'Add child',
          'Manage subscription',
          'Time zone',
          'Approvals waiting notifications',
          'Payout day reminder',
          'Weekly family summary',
          'Download our data',
          'Privacy Notice',
          'Delete family account',
          'Help & feedback',
        ];
        for (final label in labels) {
          // Toggle labels are not Text widgets; scroll to their row title.
          final anchor = label == 'Approvals waiting notifications'
              ? 'Approvals waiting'
              : label;
          await _scrollTo(tester, find.text(anchor));
          await tester.pumpAndSettle();
          final tappable = find.semantics
              .byLabel(RegExp(RegExp.escape(label)))
              .evaluate()
              .where(
                (n) => n.getSemanticsData().hasAction(SemanticsAction.tap),
              );
          expect(
            tappable,
            isNotEmpty,
            reason: '"$label" must be activatable by VoiceOver/TalkBack',
          );
        }

        // performAction(tap) on the toggle flips the real DB row.
        final before = (await _settingRow()).notifApprovals;
        await _scrollTo(tester, find.text('Approvals waiting'));
        tester.semantics.performAction(
          find.semantics.byLabel(RegExp('Approvals waiting notifications')),
          SemanticsAction.tap,
        );
        await tester.pumpAndSettle();
        expect((await _settingRow()).notifApprovals, !before);

        // The Time zone row opens the picker (real behaviour, not just a flag).
        await _scrollTo(tester, find.text('Time zone'));
        await tester.tap(find.text('Time zone').first);
        await tester.pumpAndSettle();
        expect(find.byType(NestBottomSheet), findsOneWidget);
        expect(find.text('Asia/Dubai · Current location'), findsNothing);

        handle.dispose();
        unawaited(bloc.close());
        await disposeApp(tester);
      },
    );

    testWidgets(
      '[P16-clean] the picker leads with the device zone when it differs',
      (tester) async {
        await setUpTestScope();
        final bloc = _blocWithDeviceZone('Asia/Dubai')
          ..add(const SettingsLoadRequested());
        await _pumpRouted(tester, bloc);
        await _scrollTo(tester, find.text('Time zone'));
        await tester.tap(find.text('Time zone').first);
        await tester.pumpAndSettle();

        expect(find.text('Asia/Dubai · Current location'), findsOneWidget);
        // Raw IANA is allowed inside the picker only; the settings row itself
        // must not show it.
        expect(find.textContaining('Europe/London ·'), findsOneWidget);

        unawaited(bloc.close());
        await disposeApp(tester);
      },
    );

    test('[P16-clean] Europe/London BST boundary keeps the offsets right', () {
      // BST ends 25 Oct 2026 at 02:00 local = 01:00 UTC.
      expect(
        gmtOffsetLabel('Europe/London', DateTime.utc(2026, 10, 25, 0, 30)),
        'GMT+1',
      );
      expect(
        gmtOffsetLabel('Europe/London', DateTime.utc(2026, 10, 25, 1, 30)),
        'GMT+0',
      );
      expect(
        gmtOffsetLabel('America/New_York', DateTime.utc(2026, 10, 25, 12)),
        'GMT-4',
      );
      expect(
        gmtOffsetLabel('Asia/Karachi', DateTime.utc(2026, 10, 25, 12)),
        'GMT+5',
      );
      expect(
        gmtOffsetLabel('Australia/Sydney', DateTime.utc(2026, 10, 25, 12)),
        'GMT+11',
      );
    });

    test('[P16-clean] every P16 text pair clears 4.5:1 in light and dark', () {
      for (final (theme, scheme) in <(String, NestSchemeColors)>[
        ('light', NestColors.light),
        ('dark', NestColors.dark),
      ]) {
        final pairs = <(String, Color, Color)>[
          ('ink/paper', scheme.ink, scheme.paper),
          ('ink/surface', scheme.ink, scheme.surface),
          ('ink2/surface', scheme.ink2, scheme.surface),
          ('ink2/paper', scheme.ink2, scheme.paper),
          ('ink2/surface2', scheme.ink2, scheme.surface2),
          ('ink3/surface', scheme.ink3, scheme.surface),
          ('leaf/surface', scheme.leaf, scheme.surface),
          ('danger/surface', scheme.danger, scheme.surface),
          ('ink/leafTint', scheme.ink, scheme.leafTint),
          ('ink2/leafTint', scheme.ink2, scheme.leafTint),
          ('onLeaf/leaf', scheme.onLeaf, scheme.leaf),
        ];
        for (final (label, fg, bg) in pairs) {
          expect(
            _contrast(fg, bg),
            greaterThanOrEqualTo(4.5),
            reason: '$theme $label must clear WCAG AA for body text',
          );
        }
      }
    });
  });
}
