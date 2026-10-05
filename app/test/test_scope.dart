// Shared widget-test scope for foundation tests.
//
// Opens an in-memory Drift database, registers it (plus every feature) in
// GetIt and optionally seeds `Seed.demo()`. Call in `setUp`; call
// `GetIt.instance.reset()` in the NEXT `setUp` before reusing.
//
// Databases are deliberately NOT closed: [AppSession] keeps a live watch
// subscription, and closing its database would surface stream errors after
// the test ends. In-memory databases die with the test process.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/app/di.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/current_family.dart';
import 'package:nestling/core/data/seed.dart';

Future<AppDatabase> setUpTestScope({bool seedDemo = true}) async {
  await GetIt.instance.reset();
  final db = AppDatabase.memory();
  await configureDependencies(database: db);
  if (seedDemo) {
    await Seed.demo(db);
    await GetIt.instance<AppSession>().refresh();
    // The DI singleton resolved before the seed (empty table → fallback);
    // re-point it at the seeded row so repositories read the same id the
    // product code uses at startup.
    await GetIt.instance<CurrentFamily>().refresh();
  }
  return db;
}

/// Pumps the full app at [route] on a 390x844 surface.
Future<void> pumpAppRoute(
  WidgetTester tester,
  String route, {
  ThemeMode theme = ThemeMode.light,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Disposes the pumped app and drains Drift's deferred stream-close.
///
/// Drift's `QueryStream` schedules a zero-duration timer when its last
/// listener cancels (during bloc disposal). Without this drain the test
/// framework fails teardown with "A Timer is still pending". Every
/// widget test that pumps the app must end with this.
Future<void> disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(Container());
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

/// The router's current path. Screen-agnostic, so redirect tests keep
/// passing when a placeholder view is replaced by the real screen.
String currentPath(WidgetTester tester) {
  final context = tester.element(find.byType(Navigator).first);
  return GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
}

/// The location of the top-most rendered route — [currentPath] plus any
/// imperatively pushed route (`GoRouter.push`).
///
/// `RouteMatchList.uri` deliberately excludes `ImperativeRouteMatch`s (see
/// go_router `match.dart`), so after a `push` [currentPath] still reports the
/// declarative location it pushed from. `GoRouter.state` is built from the
/// full match list and therefore reflects what the Navigator actually renders.
///
/// Assertions on a pushed screen MUST use this helper and never the view's
/// title text: screen agents replace placeholder views, but they must not
/// change the route path.
String pushedPath(WidgetTester tester) {
  final context = tester.element(find.byType(Navigator).first);
  return GoRouter.of(context).state.uri.path;
}
