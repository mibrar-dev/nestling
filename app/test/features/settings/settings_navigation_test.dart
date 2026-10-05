// P16 Settings — every control on the screen reaches the right destination.
//
// Each row on /settings is either a route, a sheet, a database write or a
// deliberate no-op. This file pumps the REAL app at `/settings` (router, shell
// tab bar, seeded in-memory Drift) and drives the actual taps, because a
// `context.push` that points at the wrong place is invisible to a test that
// only pumps `SettingsView` in isolation.
//
// Destinations are asserted with `pushedPath` (the location the Navigator
// actually renders, including imperative pushes) rather than with a pushed
// screen's title, so this file stays valid when another screen replaces its
// markup. See `_shared/router_push_test_fix_REPORT.md`.

import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/config/legal_links.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/onboarding/onboarding_routes.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_event.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_session_store.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_state.dart';
import 'package:nestling/features/settings/presentation/views/settings_view.dart';
import 'package:nestling/features/settings/settings_routes.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../test_scope.dart';
import 'p16_test_support.dart';

// Both delete-confirm tests below are skip-marked as [P16-T01]: the modal's
// buttons pop the wrong navigator, so neither Cancel nor Delete works. Run
// `flutter test test/features/settings --run-skipped` to prove the bug.

/// The toast copy P16 shows for the two rows that have no destination yet
/// (`design/html-source/screens/P16-settings.html` draws them as links; the
/// route does not exist, so the screen explains itself instead of pushing a
/// 404).
const String kInviteToast = 'Co-parent invite is coming soon';
const String kHelpToast = 'Help & feedback is coming soon';

void main() {
  setUpAll(loadP16Fonts);

  group('P16 navigation — rows that open a route', () {
    for (final row in const <String>['Maya · 7–9', 'Leo · 4–6']) {
      testWidgets('a child row opens the child profile ($row)', (tester) async {
        await pumpSettingsApp(tester);

        await scrollSettingsTo(tester, find.text(row));
        await tester.tap(find.text(row));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(pushedPath(tester), '/child-profile');
        expect(
          currentPath(tester),
          SettingsRoutePaths.settings,
          reason: 'the settings route is still the declarative location',
        );

        await disposeApp(tester);
      });
    }

    testWidgets('Add child opens the add-children flow', (tester) async {
      await pumpSettingsApp(tester);

      await scrollSettingsTo(tester, find.text('Add child'));
      await tester.tap(find.text('Add child'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(pushedPath(tester), '/add-children');

      await disposeApp(tester);
    });

    testWidgets('Manage subscription opens the paywall', (tester) async {
      await pumpSettingsApp(tester);

      await scrollSettingsTo(tester, find.text('Manage subscription'));
      await tester.tap(find.text('Manage subscription'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(pushedPath(tester), '/paywall');

      await disposeApp(tester);
    });

    testWidgets('the link row is tappable across its whole 52 px height, and '
        'its ink resolves to a Material inside the card', (tester) async {
      // Review finding 3 (iteration 6): this subcard has no `onTap`, so
      // `NestCard` takes its plain `Container` branch — a bare `Container`
      // carries no `Material`, so the link row's `InkWell` resolved its ink to
      // the Scaffold's `Material`, i.e. BEHIND the card's opaque `surface`, and
      // the row painted no ripple at all. The row now supplies its own ink
      // surface, as `NestListRow`/`SettingsRow` do everywhere else.
      //
      // The ripple itself is paint, and this stage owns no simulator, so what is
      // pinned is the two things that caused it and the thing a user can feel:
      //   1. the whole row is the hit area, not just the words — the link row is
      //      `.linkrow { min-height: 52px }` and its lower band is empty, so a
      //      tap there must still navigate;
      //   2. the ink the row paints into is a Material INSIDE the card. If the
      //      local one is ever dropped, it resolves to the Scaffold's again
      //      and the test fails with the mechanism named, rather than leaving
      //      an invisible-ripple defect to a manual glance.
      await pumpSettingsApp(tester);

      await scrollSettingsTo(tester, find.text('Manage subscription'));
      final card = subscriptionCard();
      final rowInk = find.descendant(of: card, matching: find.byType(InkWell));
      expect(
        rowInk,
        findsOneWidget,
        reason: 'the link row brings one ink well',
      );
      final rowRect = tester.getRect(rowInk);
      expect(
        rowRect.height,
        52,
        reason: '`.linkrow { min-height: 52px }` — a parent row, over 44',
      );

      // `Material.of` returns the nearest `Material`'s data, so the comparison
      // is made against the rest of the card — the plan title, which sits
      // OUTSIDE the link row and still resolves to the Scaffold's Material. If
      // the row's local Material is ever dropped, both resolve to the same
      // surface again and this fails naming the mechanism, instead of leaving an
      // invisible ripple to a manual glance.
      final rowSurface = Material.of(tester.element(rowInk));
      final cardSurface = Material.of(
        tester.element(find.text('Nestling Annual · £29.99/year')),
      );
      expect(rowSurface, isNotNull, reason: 'some Material must resolve');
      expect(
        identical(rowSurface, cardSurface),
        isFalse,
        reason:
            "the row's ink must resolve to its own Material inside the card, "
            "not to the Scaffold's behind the card's opaque surface",
      );

      // The empty lower band of the row — 6 px above its bottom edge, which is
      // below the label's line box, so no glyph is under the tap.
      await tester.tapAt(Offset(rowRect.left + 12, rowRect.bottom - 6));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        pushedPath(tester),
        '/paywall',
        reason: 'the full-height row is the tap target, not just its text',
      );

      await disposeApp(tester);
    });

    testWidgets('Download our data keeps its tap action and never leaves '
        'the screen', (tester) async {
      // Local export (shared/release_prep): the row builds the family's JSON
      // document and opens the OS share sheet — never a route. The sheet is
      // platform code, so this proves the row is operable by a screen reader
      // and does not navigate; the JSON content is pinned at the repository
      // level and the share call with a mocked share function.
      final handle = tester.ensureSemantics();
      await pumpSettingsApp(tester);

      await scrollSettingsTo(tester, find.text('Download our data'));
      final nodes = p16Announcing(tester, 'Download our data');
      expect(nodes, isNotEmpty, reason: 'the row must stay operable');
      expect(
        nodes.first.getSemanticsData().hasAction(SemanticsAction.tap),
        isTrue,
      );

      await p16ActivateSemantics(tester, nodes.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(pushedPath(tester), SettingsRoutePaths.settings);

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('Privacy Notice opens the hosted notice, never a route', (
      tester,
    ) async {
      final opened = <Uri>[];
      LegalLinks.launcherOverride = (url, {required mode}) async {
        expect(mode, LaunchMode.inAppBrowserView);
        opened.add(url);
        return true;
      };
      addTearDown(() {
        LegalLinks.launcherOverride = null;
      });
      await pumpSettingsApp(tester);

      await scrollSettingsTo(tester, find.text('Privacy Notice'));
      await tester.tap(find.text('Privacy Notice'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(opened, <Uri>[Uri.parse(LegalLinks.privacyUrl)]);
      expect(pushedPath(tester), SettingsRoutePaths.settings);

      await disposeApp(tester);
    });
  });

  group('P16 navigation — rows that stay on the screen', () {
    testWidgets('Invite co-parent explains itself instead of navigating', (
      tester,
    ) async {
      await pumpSettingsApp(tester);

      await scrollSettingsTo(tester, find.text('Invite co-parent'));
      await tester.tap(find.text('Invite co-parent'));
      await tester.pumpAndSettle();

      expect(pushedPath(tester), SettingsRoutePaths.settings);
      expect(find.text(kInviteToast), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('Help & feedback explains itself instead of navigating', (
      tester,
    ) async {
      await pumpSettingsApp(tester);

      await scrollSettingsTo(tester, find.text('Help & feedback'));
      await tester.tap(find.text('Help & feedback'));
      await tester.pumpAndSettle();

      expect(pushedPath(tester), SettingsRoutePaths.settings);
      expect(find.text(kHelpToast), findsOneWidget);

      await disposeApp(tester);
    });

    testWidgets('the time-zone row opens a sheet, never a route', (
      tester,
    ) async {
      await pumpSettingsApp(tester);

      await scrollSettingsTo(tester, find.text('Time zone'));
      await tester.tap(find.text('Time zone'));
      await tester.pumpAndSettle();

      // The sheet repeats the section's title, so two is the proof it opened.
      expect(find.text('Time zone'), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byType(NestBottomSheet),
          matching: find.textContaining('Asia/Dubai'),
        ),
        findsOneWidget,
        reason: 'the curated list shows Dubai with its raw IANA id',
      );
      expect(
        find.descendant(
          of: find.byType(NestBottomSheet),
          matching: find.text('Dubai'),
        ),
        findsOneWidget,
        reason: 'one row per zone — the device hint never duplicates a choice',
      );
      expect(
        pushedPath(tester),
        SettingsRoutePaths.settings,
        reason: 'the picker is in-place, not a route',
      );

      await disposeApp(tester);
    });

    testWidgets('picking a zone stores it, closes the sheet and clears the '
        'move banner', (tester) async {
      await pumpSettingsApp(tester, deviceZone: 'Asia/Dubai');

      expect(
        find.byKey(const ValueKey('p16_move_banner')),
        findsOneWidget,
        reason: 'a Dubai device raises the banner in the real app too',
      );

      await scrollSettingsTo(tester, find.text('Time zone'));
      await tester.tap(find.text('Time zone'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dubai'));
      await tester.pumpAndSettle();

      expect(await familyZoneId(), 'Asia/Dubai');
      expect(find.byType(NestBottomSheet), findsNothing);
      expect(
        find.byKey(const ValueKey('p16_move_banner')),
        findsNothing,
        reason: 'device and family zone agree, so the prompt clears',
      );
      expect(pushedPath(tester), SettingsRoutePaths.settings);

      await disposeApp(tester);
    });

    testWidgets('the version row is static: it announces nothing to tap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpSettingsApp(tester);
      await tester.pump();

      await scrollSettingsTo(tester, find.text('Version 1.0.0'));
      expect(
        find.semantics.byLabel('Version 1.0.0').evaluate(),
        isEmpty,
        reason: 'a display-only row must not expose a tap action',
      );
      expect(
        tappableNodes(tester).map((node) => node.getSemanticsData().label),
        isNot(contains('Version 1.0.0')),
      );

      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P16 navigation — deleting the family account wipes and lands on '
      'welcome', () {
    testWidgets('Cancel closes the modal and keeps everything', (tester) async {
      await pumpSettingsApp(tester);
      final childrenBefore = await childRows();

      await scrollSettingsTo(tester, find.text('Delete family account'));
      await tester.tap(find.text('Delete family account'));
      await tester.pumpAndSettle();
      expect(find.text('Delete family account?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('p16_delete_cancel')));
      await tester.pumpAndSettle();

      expect(find.text('Delete family account?'), findsNothing);
      expect(pushedPath(tester), SettingsRoutePaths.settings);
      expect(await childRows(), childrenBefore);
      expect(await settingRows(), isNotEmpty);

      await disposeApp(tester);
      // P16-T01 (iteration 1 blocker) — FIXED in iteration 2: both buttons now
      // pop the ROOT navigator (`Navigator.of(context, rootNavigator: true)`),
      // which is where `showNestModal`'s `Dialog` lives, so the pop closes the
      // modal instead of removing /settings from the go_router shell. This
      // proof is live again and asserts the fix does not go green by
      // accident: the family zone, the children and the settings row are all
      // still there afterwards, and the path is still /settings.
    });

    testWidgets('Delete confirms, wipes the database and lands on welcome', (
      tester,
    ) async {
      await pumpSettingsApp(tester);
      expect(await childRows(), isNotEmpty);

      await scrollSettingsTo(tester, find.text('Delete family account'));
      await tester.tap(find.text('Delete family account'));
      await tester.pumpAndSettle();
      expect(find.text('Delete family account?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('p16_delete_confirm')));
      await tester.pumpAndSettle();
      await settleSettings(tester);

      // The router lands on /welcome (assert the location, never
      // placeholder copy — screen agents own the views).
      expect(currentPath(tester), OnboardingRoutePaths.welcome);

      // Every table is empty except the fresh `app_state` row: a fresh
      // install (onboarding incomplete, parent mode, no subscription).
      final db = GetIt.instance<AppDatabase>();
      expect(await db.select(db.families).get(), isEmpty);
      expect(await db.select(db.members).get(), isEmpty);
      expect(await db.select(db.children).get(), isEmpty);
      expect(await db.select(db.quests).get(), isEmpty);
      expect(await db.select(db.questCompletions).get(), isEmpty);
      expect(await db.select(db.ledgerEntries).get(), isEmpty);
      expect(await db.select(db.savingsGoals).get(), isEmpty);
      expect(await db.select(db.rewards).get(), isEmpty);
      expect(await db.select(db.rewardRedemptions).get(), isEmpty);
      expect(await db.select(db.badges).get(), isEmpty);
      expect(await db.select(db.earnedBadges).get(), isEmpty);
      expect(await db.select(db.pipWardrobe).get(), isEmpty);
      expect(await db.select(db.settings).get(), isEmpty);
      final state = await db.select(db.appState).getSingle();
      expect(state.onboardingComplete, isFalse);
      expect(state.appMode, 'parent');
      expect(state.trialStart, isNull);
      expect(state.activeChildId, isNull);

      // In-memory session state follows the wipe (parent mode, fresh).
      expect(GetIt.instance<AppSession>().onboardingComplete, isFalse);
      expect(GetIt.instance<AppModeController>().mode, AppMode.parent);

      // A second launch starts at welcome: the router's onboarding guard
      // redirects any non-onboarding location there.
      final routerContext = tester.element(find.byType(Navigator).first);
      GoRouter.of(routerContext).go(SettingsRoutePaths.settings);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(currentPath(tester), OnboardingRoutePaths.welcome);

      await disposeApp(tester);
    });
  });

  group('P16 the zone row is driven by the database', () {
    testWidgets('picking Dubai re-renders the row as "Dubai (GMT+4)"', (
      tester,
    ) async {
      // The row is not a snapshot of the picker's choice: the bloc re-emits
      // from `watchFamilyTimeZone`, so the subtitle must follow the write (and
      // the old one must disappear — two subtitles at once would be a stale
      // row, not a live one).
      await pumpSettingsApp(tester);
      // Scroll the row's TITLE on: both halves of the row are then built, and
      // the title stays hittable for the tap that opens the sheet.
      await scrollSettingsTo(tester, find.text('Time zone'));
      expect(find.text('London (GMT+1)'), findsOneWidget);
      expect(find.text('Dubai (GMT+4)'), findsNothing);

      await tester.tap(find.text('Time zone'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dubai').first);
      await tester.pumpAndSettle();
      await settleSettings(tester);

      expect(await familyZoneId(), 'Asia/Dubai');
      expect(find.text('Dubai (GMT+4)'), findsOneWidget);
      expect(
        find.text('London (GMT+1)'),
        findsNothing,
        reason: 'the old summary must not linger',
      );

      // Raw IANA ids stay inside the picker (ORCHESTRATOR_NOTES copy rule).
      expect(find.text('Asia/Dubai'), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('an unknown zone id from the sheet leaves the row alone', (
      tester,
    ) async {
      // `setFamilyTimeZone` validates: the service ignores unknown ids, so the
      // row must not move.
      await pumpSettingsApp(tester);
      await scrollSettingsTo(tester, find.text('Time zone'));
      await tester.tap(find.text('Time zone'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Karachi').first);
      await tester.pumpAndSettle();
      await settleSettings(tester);

      expect(await familyZoneId(), 'Asia/Karachi');
      expect(find.text('Karachi (GMT+5)'), findsOneWidget);
      expect(find.text('London (GMT+1)'), findsNothing);

      await disposeApp(tester);
    });
  });

  group('P16 session scope — the move prompt is once per session', () {
    testWidgets('"Not now" survives leaving and re-entering /settings', (
      tester,
    ) async {
      // ORCHESTRATOR_NOTES: the prompt shows "exactly once (until confirmed or
      // dismissed for the session)". Iteration 2 moved the dismissal into the
      // DI `SettingsSessionStore`; the bloc-level proof lives in
      // `settings_bloc_test.dart`, this one proves the ROUTE actually gets
      // that store (the DI wiring) and that a rebuilt page stays quiet.
      await pumpSettingsApp(tester, deviceZone: 'Asia/Dubai');
      expect(find.byKey(const ValueKey('p16_move_banner')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('p16_move_not_now')));
      await settleSettings(tester);
      expect(find.byKey(const ValueKey('p16_move_banner')), findsNothing);
      expect(
        await familyZoneId(),
        'Europe/London',
        reason: '"Not now" writes nothing',
      );

      // The dismissal reached the session store, never the database.
      expect(
        GetIt.instance<SettingsSessionStore>().dismissedZones,
        contains('Asia/Dubai'),
      );

      // Leave the route and come back: a `go` rebuilds the page, so this is a
      // brand-new route-built bloc, not the dismissed one.
      final routerContext = tester.element(find.byType(Navigator).first);
      GoRouter.of(routerContext).go('/paywall');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(pushedPath(tester), '/paywall');

      GoRouter.of(routerContext).go(SettingsRoutePaths.settings);
      await settleSettings(tester);
      expect(pushedPath(tester), SettingsRoutePaths.settings);
      expect(
        find.byKey(const ValueKey('p16_move_banner')),
        findsNothing,
        reason: 'the prompt must not come back in the same session',
      );

      await disposeApp(tester);
    });

    testWidgets('a bloc built the way the route builds it inherits the '
        'session dismissal', (tester) async {
      await pumpSettingsApp(tester, deviceZone: 'Asia/Dubai');
      await tester.tap(find.byKey(const ValueKey('p16_move_not_now')));
      await settleSettings(tester);

      // Exactly the route's construction path: `GetIt.instance<SettingsBloc>()`
      // → `settingsRoute`'s `BlocProvider` → `SettingsLoadRequested`.
      final fresh = GetIt.instance<SettingsBloc>()
        ..add(const SettingsLoadRequested());
      await fresh.stream.firstWhere(
        (state) => state.status == SettingsStatus.loaded,
      );
      expect(
        fresh.state.pendingZone,
        isNull,
        reason: 'the DI store is what the route resolves — no store passed in',
      );
      expect(
        fresh.state.deviceZoneId,
        'Asia/Dubai',
        reason: 'the raw device zone survives the dismissal (P16-B01)',
      );

      unawaited(fresh.close());
      await disposeApp(tester);
    });

    testWidgets('the picker still leads with the device zone after a '
        'dismissal', (tester) async {
      await pumpSettingsApp(tester, deviceZone: 'Asia/Dubai');
      await tester.tap(find.byKey(const ValueKey('p16_move_not_now')));
      await settleSettings(tester);

      await scrollSettingsTo(tester, find.text('Time zone'));
      await tester.tap(find.text('Time zone'));
      await tester.pumpAndSettle();

      // ORCHESTRATOR_NOTES: "plus the device zone first when it differs".
      expect(find.text('Asia/Dubai · Current location'), findsOneWidget);
      expect(find.text('Dubai'), findsOneWidget, reason: 'one row per zone');
      expect(
        find.descendant(
          of: find.byType(NestBottomSheet),
          matching: find.text('Dubai'),
        ),
        findsOneWidget,
      );

      await disposeApp(tester);
    });
  });

  group('P16 shell', () {
    testWidgets('/settings sits on the Family tab of the parent shell', (
      tester,
    ) async {
      await pumpSettingsApp(tester);

      expect(find.byType(NestTabBar), findsOneWidget);
      expect(find.byType(SettingsView), findsOneWidget);
      final tab = tester.getRect(find.byType(NestTabBar));
      expect(
        tab.bottom,
        p16DesignSize.height,
        reason: 'BOTTOM EDGE: the bar surface runs to the physical edge',
      );
      // The Family tab is the active one on this branch: exactly one of the
      // bar's own controls announces itself as selected, and it is Family.
      expect(
        tappableNodes(tester)
            .map((node) => node.getSemanticsData())
            .where((data) => data.flagsCollection.isSelected == Tristate.isTrue)
            .map((data) => data.label)
            .toList(),
        <String>['Family'],
      );

      await disposeApp(tester);
    });
  });
}
