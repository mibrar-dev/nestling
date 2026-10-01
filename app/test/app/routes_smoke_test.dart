// Smoke test: every one of the 30 screens (+ the dev gallery) pumps with
// Seed.demo in light and dark without throwing. Placeholder views only
// assert presence — screen agents add golden/content assertions per screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';

import '../test_scope.dart';

const List<String> screenRoutes = <String>[
  '/welcome',
  '/value-tour',
  '/create-account',
  '/privacy',
  '/add-children',
  '/pocket-money-setup',
  '/paywall',
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
  '/parental-gate',
  '/who-is-playing',
  '/kid-pin',
  '/kid-home',
  '/kid-home-done',
  '/quest-detail',
  '/quest-complete',
  '/pip',
  '/pip-evolution',
  '/reward-shop',
  '/my-jar',
  '/payout-day',
  '/badges',
  '/design-system',
];

Future<void> pumpRoute(
  WidgetTester tester,
  String route,
  ThemeMode theme,
) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('all routes pump', () {
    for (final theme in const [ThemeMode.light, ThemeMode.dark]) {
      final name = theme == ThemeMode.light ? 'light' : 'dark';
      testWidgets('Seed.demo in $name', (tester) async {
        await setUpTestScope();
        for (final route in screenRoutes) {
          await pumpRoute(tester, route, theme);
          expect(
            find.byType(Scaffold),
            findsWidgets,
            reason: '$route ($name) should render a Scaffold',
          );
          expect(
            find.text('Something went wrong'),
            findsNothing,
            reason: '$route ($name) should not fail to load',
          );
        }
      });
    }
  });
}
