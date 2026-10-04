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

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/settings/presentation/views/settings_view.dart';
import 'package:nestling/features/settings/settings_routes.dart';

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
const String kDeleteToast = 'Family account deletion is not available yet';

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

    for (final row in const <String>['Download our data', 'Privacy Notice']) {
      testWidgets('the privacy row opens the privacy screen ($row)', (
        tester,
      ) async {
        await pumpSettingsApp(tester);

        await scrollSettingsTo(tester, find.text(row));
        await tester.tap(find.text(row));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(pushedPath(tester), '/privacy');

        await disposeApp(tester);
      });
    }
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

  group('P16 navigation — deleting the family account is a confirm, not a '
      'wipe', () {
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
      // P16-T01 open (blocker for the destructive action). `showNestModal`
      // pushes its `Dialog` on the ROOT navigator (`useRootNavigator: true`),
      // but `settings_view.dart:338` calls `Navigator.of(context).pop(false)`
      // with the VIEW's context, whose nearest navigator is the go_router
      // shell's. The pop therefore removes /settings from the shell instead of
      // the dialog: go_router asserts `currentConfiguration.isNotEmpty`
      // ("You have popped the last page off of the stack") and the modal never
      // dismisses. Same for the Delete button at settings_view.dart:346.
      //
      // The existing `settings_view_test.dart` cannot see this: it pumps
      // `SettingsView` as a `MaterialApp` home, where the view's nearest
      // navigator IS the root navigator the dialog uses, so the pop lands on
      // the right route. Only the real app at /settings exposes it.
      //
      // Fix: dismiss through the dialog's own context — wrap the buttons in a
      // `Builder` and pop that context's navigator, or
      // `Navigator.of(context, rootNavigator: true).pop(...)`.
      // Evidence: docs/screens/P16/3_test.md §Bugs.
    });

    testWidgets(
      '[P16-T01] Delete confirms, toasts and never touches the database',
      (tester) async {
        await pumpSettingsApp(tester);
        final childrenBefore = await childRows();
        final zoneBefore = await familyZoneId();

        await scrollSettingsTo(tester, find.text('Delete family account'));
        await tester.tap(find.text('Delete family account'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('p16_delete_confirm')));
        await tester.pumpAndSettle();

        expect(find.text(kDeleteToast), findsOneWidget);
        expect(pushedPath(tester), SettingsRoutePaths.settings);
        expect(
          await childRows(),
          childrenBefore,
          reason: 'the account-deletion flow does not exist yet (TODO(P16))',
        );
        expect(await familyZoneId(), zoneBefore);
        expect(await settingRows(), isNotEmpty);

        await disposeApp(tester);
      },
      skip: false,
    );
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
