// Router redirect contract: onboarding, trial expiry and the kid-mode
// parental gate, all driven by AppSession.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';

import '../test_scope.dart';

Future<void> pumpRoute(WidgetTester tester, String route) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('router redirects', () {
    testWidgets('fresh install opens the welcome screen', (tester) async {
      final db = await setUpTestScope(seedDemo: false);
      await Seed.fresh(db);
      await GetIt.instance<AppSession>().refresh();

      await pumpRoute(tester, '/today');
      expect(find.text('P01 Welcome'), findsOneWidget);
    });

    testWidgets('onboarded parent lands on Today', (tester) async {
      await setUpTestScope();

      await pumpRoute(tester, '/today');
      expect(find.text('P08 Today'), findsOneWidget);
    });

    testWidgets('expired trial redirects to the paywall', (tester) async {
      await setUpTestScope();
      final session = GetIt.instance<AppSession>();
      await session.setSubscription('expired');
      await session.refresh();

      await pumpRoute(tester, '/today');
      expect(find.text('P07 Paywall'), findsOneWidget);
    });

    testWidgets('paywall itself is reachable when expired', (tester) async {
      await setUpTestScope();
      final session = GetIt.instance<AppSession>();
      await session.setSubscription('expired');
      await session.refresh();

      await pumpRoute(tester, '/paywall');
      expect(find.text('P07 Paywall'), findsOneWidget);
    });

    testWidgets('kid mode sends parent screens to the gate', (tester) async {
      await setUpTestScope();
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      final session = GetIt.instance<AppSession>();
      await session.setAppMode('kid');
      await session.refresh();

      await pumpRoute(tester, '/today');
      expect(find.text('P17 Parental gate'), findsOneWidget);
    });

    testWidgets('kid mode keeps kid screens open', (tester) async {
      await setUpTestScope();
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      final session = GetIt.instance<AppSession>();
      await session.setAppMode('kid');
      await session.refresh();

      await pumpRoute(tester, '/kid-home');
      expect(find.text('P17 Parental gate'), findsNothing);
    });
  });
}
