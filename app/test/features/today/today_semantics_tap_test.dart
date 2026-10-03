// P08 Today — semantics tap actions for the two InkWell + excludeSemantics
// spots (semantics_tap_REPORT follow-up).
//
// Both controls wrap an `InkWell(onTap)` around
// `Semantics(button, excludeSemantics: true)`, which drops the tap action
// unless the Semantics node mirrors it with `onTap:`. Each test asserts
// `hasAction(SemanticsAction.tap)` and that `performAction(tap)` navigates
// to the same route as a real tap (asserted via `currentPath`, never via
// placeholder view text).

import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../test_scope.dart';

void main() {
  group('P08 Today semantics tap — profile avatar', () {
    testWidgets("has tap action on the Sarah's profile node", (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');
      final handle = tester.ensureSemantics();
      await tester.pump();

      final data = tester
          .getSemantics(find.bySemanticsLabel("Sarah's profile"))
          .getSemanticsData();
      expect(data.flagsCollection.isButton, isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('performAction(tap) goes to /settings like a real tap', (
      tester,
    ) async {
      // Real tap destination (already pinned by today_view_test, repeated
      // here so the equivalence is self-contained).
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');
      await tester.tap(find.bySemanticsLabel("Sarah's profile"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final realPath = currentPath(tester);
      expect(realPath, '/settings');
      await disposeApp(tester);

      // Semantics activation lands on the same route.
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');
      final handle = tester.ensureSemantics();
      await tester.pump();
      tester.semantics.performAction(
        find.semantics.byLabel("Sarah's profile"),
        SemanticsAction.tap,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(currentPath(tester), realPath);
      expect(currentPath(tester), '/settings');

      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P08 Today semantics tap — See all quests', () {
    testWidgets('has tap action on the See all quests node', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');
      final handle = tester.ensureSemantics();
      await tester.pump();

      final node = find.semantics.byLabel('See all quests').evaluate().single;
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('performAction(tap) goes to /quests like a real tap', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');
      await tester.tap(find.text('See all'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final realPath = currentPath(tester);
      expect(realPath, '/quests');
      await disposeApp(tester);

      await setUpTestScope();
      await pumpAppRoute(tester, '/today');
      final handle = tester.ensureSemantics();
      await tester.pump();
      tester.semantics.performAction(
        find.semantics.byLabel('See all quests'),
        SemanticsAction.tap,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(currentPath(tester), realPath);
      expect(currentPath(tester), '/quests');

      handle.dispose();
      await disposeApp(tester);
    });
  });
}
