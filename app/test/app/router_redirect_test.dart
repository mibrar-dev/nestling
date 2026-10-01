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
  });
}
