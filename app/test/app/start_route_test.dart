// Start-route contract (shared/start_route): a real cold start boots at `/`
// and the redirect sends it to the family's start screen — never the
// developer-tool gallery. The gallery / motion lab / pip lab are registered
// only when the router enables dev routes (debug/profile, or an explicit
// dart-define); a release-mode config has no such routes and deep links to
// them land on the start screen instead of the error page.
//
// Every assertion here is a ROUTER LOCATION (currentPath), never view text:
// screen agents replace placeholder views, but they must not change paths.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/app/router.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/features/design_system_gallery/design_system_gallery_routes.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/onboarding/onboarding_routes.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';
import 'package:nestling/features/paywall/paywall_routes.dart';
import 'package:nestling/features/today/today_routes.dart';

import '../test_scope.dart';

/// Every `GoRoute.path` in [routes], descending into shell branches.
List<String> _allPaths(List<RouteBase> routes) {
  final paths = <String>[];
  void collectAll(List<RouteBase> list) {
    for (final route in list) {
      if (route is GoRoute) {
        paths.add(route.path);
        collectAll(route.routes);
      } else if (route is StatefulShellRoute) {
        for (final branch in route.branches) {
          collectAll(branch.routes);
        }
      } else if (route is ShellRoute) {
        collectAll(route.routes);
      }
    }
  }

  collectAll(routes);
  return paths;
}

const List<String> _devPaths = <String>[
  DesignSystemGalleryRoutePaths.gallery,
  DesignSystemGalleryRoutePaths.motionLab,
  DesignSystemGalleryRoutePaths.pipLab,
];

Future<void> _enterKidMode() async {
  GetIt.instance<AppModeController>().selectMode(AppMode.kid);
  final session = GetIt.instance<AppSession>();
  await session.setAppMode('kid');
  await session.refresh();
}

Future<void> _expireTrial() async {
  final session = GetIt.instance<AppSession>();
  await session.setSubscription('expired');
  await session.refresh();
  expect(session.trialExpired, isTrue);
}

void main() {
  group('cold start at /', () {
    testWidgets('not onboarded boots to welcome', (tester) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.fresh(db);
      await GetIt.instance<AppSession>().refresh();

      await pumpAppRoute(tester, '/');
      expect(currentPath(tester), OnboardingRoutePaths.welcome);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('onboarded parent boots to Today', (tester) async {
      await setUpTestScope();

      await pumpAppRoute(tester, '/');
      expect(currentPath(tester), TodayRoutePaths.today);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('onboarded kid boots to Kid Home', (tester) async {
      await setUpTestScope();
      await _enterKidMode();

      await pumpAppRoute(tester, '/');
      expect(currentPath(tester), KidHomeRoutePaths.home);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('expired trial kid boots to the parental gate', (tester) async {
      await setUpTestScope();
      await _expireTrial();
      await _enterKidMode();

      // `/` first resolves to Kid Home (the start rule), then the
      // expired-trial guard funnels the kid to the gate — never the paywall,
      // and never a redirect loop.
      await pumpAppRoute(tester, '/');
      expect(currentPath(tester), ParentalGateRoutePaths.gate);
      expect(find.text('Page Not Found'), findsNothing);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('expired trial parent boots to the paywall', (tester) async {
      await setUpTestScope();
      await _expireTrial();

      // `/` first resolves to Today (the start rule), then the expired-trial
      // guard sends the parent to the paywall.
      await pumpAppRoute(tester, '/');
      expect(currentPath(tester), PaywallRoutePaths.paywall);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });

    testWidgets('not onboarded kid boots to the parental gate', (tester) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.fresh(db);
      await GetIt.instance<AppSession>().refresh();
      await _enterKidMode();

      // `/` first resolves to welcome (the start rule), then the kid-mode
      // gate stops the parent-only onboarding flow at the gate.
      await pumpAppRoute(tester, '/');
      expect(currentPath(tester), ParentalGateRoutePaths.gate);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });

  group('developer-tool routes', () {
    test('release-mode router registers no gallery routes', () async {
      await setUpTestScope();
      final router = buildAppRouter(
        GetIt.instance<AppModeController>(),
        session: GetIt.instance<AppSession>(),
        includeDevRoutes: false,
      );
      addTearDown(router.dispose);

      final paths = _allPaths(router.configuration.routes);
      for (final dev in _devPaths) {
        expect(paths, isNot(contains(dev)), reason: '$dev is dev-only');
      }
      // The product routes the start rule lands on still exist.
      expect(paths, contains(TodayRoutePaths.today));
      expect(paths, contains(KidHomeRoutePaths.home));
      expect(paths, contains(OnboardingRoutePaths.welcome));
    });

    test('debug router keeps the gallery routes', () async {
      await setUpTestScope();
      final router = buildAppRouter(
        GetIt.instance<AppModeController>(),
        session: GetIt.instance<AppSession>(),
      );
      addTearDown(router.dispose);

      // Tests run in debug, so the labs stay registered and the gallery
      // tests keep working.
      final paths = _allPaths(router.configuration.routes);
      for (final dev in _devPaths) {
        expect(paths, contains(dev));
      }
    });

    testWidgets('release deep link to the gallery lands on Today', (
      tester,
    ) async {
      // Seed.demo: onboarded parent with an active subscription.
      await setUpTestScope();
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      // An explicit route skips the cold-start splash, so the redirect underneath
      // is what this asserts: no such route in release → start screen.
      await tester.pumpWidget(
        const NestlingApp(
          initialRoute: DesignSystemGalleryRoutePaths.gallery,
          includeDevRoutes: false,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(currentPath(tester), TodayRoutePaths.today);
      expect(find.text('Page Not Found'), findsNothing);
      expect(tester.takeException(), isNull);
      await disposeApp(tester);
    });
  });
}
