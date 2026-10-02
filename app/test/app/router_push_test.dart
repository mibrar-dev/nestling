// Push/pop contract (P05 push no-op investigation, P08 §4 Today→P09/P11).
//
// Finding: `context.push` from top-level routes AND from shell-branch
// locations works — the pushed screen renders and `pop` returns. The earlier
// "silent no-op" was a probe artifact: the probe asserted
// `routerDelegate.currentConfiguration`, which does not include imperative
// (pushed) matches. `GoRouter.state.uri` (== what the Navigator renders) is
// the truthful accessor after a push, so these tests assert that.
//
// P08 reaches P09 (`/quest-editor`) and P11 (`/approvals`) with `push` so the
// OS back button returns to `/today`; P09/P11 must therefore return with
// `context.pop()` and must not assume they were `go`-navigated to.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../test_scope.dart';

/// The rendered location after imperative pushes. `currentPath` (which reads
/// `routerDelegate.currentConfiguration`) lags pushed routes by design, so
/// push tests read `GoRouter.state` instead.
String pushedPath(WidgetTester tester) {
  final context = tester.element(find.byType(Navigator).first);
  return GoRouter.of(context).state.uri.path;
}

Future<void> expectPushPop(
  WidgetTester tester,
  String from,
  String to, {
  required String showsFrom,
  required String showsTo,
}) async {
  await pumpAppRoute(tester, from);
  expect(pushedPath(tester), from);
  expect(find.text(showsFrom).evaluate().isNotEmpty, isTrue);

  final context = tester.element(find.byType(Navigator).first);
  // `push` completes on pop — never await it before popping.
  // ignore: unawaited_futures
  GoRouter.of(context).push(to);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  expect(pushedPath(tester), to, reason: 'push($to) from $from navigates');
  expect(find.text(showsTo).evaluate().isNotEmpty, isTrue);
  expect(find.text(showsFrom).evaluate().isEmpty, isTrue);

  GoRouter.of(context).pop();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  expect(pushedPath(tester), from, reason: 'pop returns to $from');
  expect(find.text(showsFrom).evaluate().isNotEmpty, isTrue);
}

void main() {
  group('push/pop contract', () {
    testWidgets('push P09 quest editor from /today, pop returns', (
      tester,
    ) async {
      await setUpTestScope();
      await expectPushPop(
        tester,
        '/today',
        '/quest-editor',
        showsFrom: "Today's quests",
        showsTo: 'P09 Quest editor',
      );
      await disposeApp(tester);
    });

    testWidgets('push P11 approvals from /today, pop returns', (tester) async {
      await setUpTestScope();
      await expectPushPop(
        tester,
        '/today',
        '/approvals',
        showsFrom: "Today's quests",
        showsTo: 'P11 Approvals',
      );
      await disposeApp(tester);
    });

    testWidgets('push /value-tour from /welcome, pop returns', (tester) async {
      await setUpTestScope();
      await expectPushPop(
        tester,
        '/welcome',
        '/value-tour',
        showsFrom: 'Chores that feel like a game.',
        showsTo: 'P02 Value tour',
      );
      await disposeApp(tester);
    });

    testWidgets('push between top-level onboarding routes, pop returns', (
      tester,
    ) async {
      await setUpTestScope();
      await expectPushPop(
        tester,
        '/add-children',
        '/pocket-money-setup',
        showsFrom: 'P05 Add children',
        showsTo: 'P06 Pocket money setup',
      );
      await disposeApp(tester);
    });
  });
}
