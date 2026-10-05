// P08b shell contract: `/today-empty` renders inside the Today
// `StatefulShellBranch`, so the parent tab bar shows with Today selected,
// exactly like `/today`. Route assertions only (never view copy): the P08b
// screen agent owns the view.

import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../test_scope.dart';

void main() {
  group('today-empty tab shell', () {
    testWidgets('/today-empty shows the tab bar with Today selected', (
      tester,
    ) async {
      await setUpTestScope();

      await pumpAppRoute(tester, '/today-empty');

      expect(currentPath(tester), '/today-empty');
      final bar = tester.widget<NestTabBar>(find.byType(NestTabBar));
      expect(bar.currentIndex, 0);
      await disposeApp(tester);
    });

    testWidgets('/today still shows the tab bar with Today selected', (
      tester,
    ) async {
      await setUpTestScope();

      await pumpAppRoute(tester, '/today');

      expect(currentPath(tester), '/today');
      final bar = tester.widget<NestTabBar>(find.byType(NestTabBar));
      expect(bar.currentIndex, 0);
      await disposeApp(tester);
    });
  });
}
