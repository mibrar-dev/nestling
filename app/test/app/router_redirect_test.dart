// Router redirect contract: onboarding, trial expiry and the kid-mode
// parental gate, all driven by AppSession.

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';

import '../test_scope.dart';

void main() {
  group('router redirects', () {
    testWidgets('fresh install opens the welcome screen', (tester) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.fresh(db);
      await GetIt.instance<AppSession>().refresh();

      await pumpAppRoute(tester, '/today');
      expect(currentPath(tester), '/welcome');
      await disposeApp(tester);
    });

    testWidgets('onboarded parent lands on Today', (tester) async {
      await setUpTestScope();

      await pumpAppRoute(tester, '/today');
      expect(currentPath(tester), '/today');
      await disposeApp(tester);
    });

    testWidgets('expired trial redirects to the paywall', (tester) async {
      await setUpTestScope();
      final session = GetIt.instance<AppSession>();
      await session.setSubscription('expired');
      await session.refresh();

      await pumpAppRoute(tester, '/today');
      expect(currentPath(tester), '/paywall');
      await disposeApp(tester);
    });

    testWidgets('paywall itself is reachable when expired', (tester) async {
      await setUpTestScope();
      final session = GetIt.instance<AppSession>();
      await session.setSubscription('expired');
      await session.refresh();

      await pumpAppRoute(tester, '/paywall');
      expect(currentPath(tester), '/paywall');
      await disposeApp(tester);
    });

    testWidgets('kid mode sends parent screens to the gate', (tester) async {
      await setUpTestScope();
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      final session = GetIt.instance<AppSession>();
      await session.setAppMode('kid');
      await session.refresh();

      await pumpAppRoute(tester, '/today');
      expect(currentPath(tester), '/parental-gate');
      await disposeApp(tester);
    });

    testWidgets('kid mode keeps kid screens open', (tester) async {
      await setUpTestScope();
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      final session = GetIt.instance<AppSession>();
      await session.setAppMode('kid');
      await session.refresh();

      await pumpAppRoute(tester, '/kid-home');
      expect(currentPath(tester), '/kid-home');
      await disposeApp(tester);
    });
    testWidgets('kid mode cannot open the onboarding flow', (tester) async {
      await setUpTestScope();
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      final session = GetIt.instance<AppSession>();
      await session.setAppMode('kid');
      await session.refresh();

      await pumpAppRoute(tester, '/welcome');
      expect(currentPath(tester), '/parental-gate');
      await disposeApp(tester);
    });
    for (final route in const <String>[
      '/today',
      '/today-empty',
      '/quest-editor',
      '/quests',
      '/approvals',
      '/money',
      '/payout',
      '/rewards',
      '/child-profile',
      '/settings',
      '/welcome',
      '/value-tour',
      '/create-account',
      '/privacy',
      '/add-children',
      '/pocket-money-setup',
      '/paywall',
    ]) {
      testWidgets('kid mode gates parent route $route', (tester) async {
        await setUpTestScope();
        GetIt.instance<AppModeController>().selectMode(AppMode.kid);
        final session = GetIt.instance<AppSession>();
        await session.setAppMode('kid');
        await session.refresh();

        await pumpAppRoute(tester, route);
        expect(currentPath(tester), '/parental-gate');
        await disposeApp(tester);
      });
    }
  });

  // Kid trial gate (shared/kid_trial_gate): with an expired trial in kid
  // mode the router used to send everything to /paywall, which is
  // parent-only in kid mode and bounced to /parental-gate, which hit the
  // trial branch again — GoException "redirect loop" and go_router's error
  // page. Kids now funnel to the gate (exempt from the trial branch);
  // passing it flips to parent mode, where the trial branch fires.
  group('kid trial gate (shared/kid_trial_gate)', () {
    Future<void> expireTrialAndEnterKidMode() async {
      final session = GetIt.instance<AppSession>();
      await session.setSubscription('expired');
      await session.refresh();
      expect(session.trialExpired, isTrue);
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await session.setAppMode('kid');
      await session.refresh();
    }

    for (final route in const <String>[
      '/kid-home',
      '/who-is-playing',
      '/pip',
      '/paywall',
      '/today',
    ]) {
      testWidgets('kid mode + expired trial sends $route to the gate', (
        tester,
      ) async {
        await setUpTestScope();
        await expireTrialAndEnterKidMode();

        await pumpAppRoute(tester, route);

        // Route assertions only (never gate copy): P17 replaces the
        // scaffold title, but the path is stable. Before the fix this
        // landed on go_router's error page ('Page Not Found' +
        // 'GoException: redirect loop detected
        // /paywall => /parental-gate => /paywall').
        expect(currentPath(tester), '/parental-gate');
        expect(find.text('Page Not Found'), findsNothing);
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      });
    }

    testWidgets(
      'passing the gate with an expired trial lands the parent on the '
      'paywall',
      (tester) async {
        await setUpTestScope();
        await expireTrialAndEnterKidMode();

        await pumpAppRoute(tester, '/kid-home');
        expect(currentPath(tester), '/parental-gate');

        // What the real P17 gate does on a correct answer: flip to parent
        // mode. The trial branch then fires for the parent.
        GetIt.instance<AppModeController>().selectMode(AppMode.parent);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(currentPath(tester), '/paywall');
        expect(tester.takeException(), isNull);
        await disposeApp(tester);
      },
    );

    testWidgets('kid mode + active trial keeps kid screens open', (
      tester,
    ) async {
      await setUpTestScope();
      final session = GetIt.instance<AppSession>();
      expect(session.trialExpired, isFalse);
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await session.setAppMode('kid');
      await session.refresh();

      await pumpAppRoute(tester, '/kid-home');
      expect(currentPath(tester), '/kid-home');
      await disposeApp(tester);
    });

    testWidgets('parent mode + expired trial still goes to the paywall', (
      tester,
    ) async {
      await setUpTestScope();
      final session = GetIt.instance<AppSession>();
      await session.setSubscription('expired');
      await session.refresh();
      expect(session.trialExpired, isTrue);

      await pumpAppRoute(tester, '/kid-home');
      expect(currentPath(tester), '/paywall');
      await disposeApp(tester);
    });
  });
}
