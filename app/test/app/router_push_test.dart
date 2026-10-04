// Push/pop contract (P05 push no-op investigation, P08 §4 Today→P09/P11).
//
// Finding: `context.push` from top-level routes AND from shell-branch
// locations works — the pushed screen renders and `pop` returns. The earlier
// "silent no-op" was a probe artifact: the probe asserted
// `routerDelegate.currentConfiguration.uri` (what `currentPath` reads), which
// by design does not include imperative (pushed) matches. `pushedPath`
// (`GoRouter.state.uri`, i.e. what the Navigator renders) is the truthful
// accessor after a push, so these tests assert that.
//
// Every assertion here is a ROUTER LOCATION, never a view string. The old
// version asserted placeholder titles (for example the P02 value-tour
// title), which only exist on the foundation's placeholder views
// (`AppBar(title: Text('<screen id> <name>'))`); it therefore broke on every
// screen branch that replaced its placeholder — P02 first. Routes are shared
// and stable, screen agents must not change them.
//
// P08 reaches P09 (`/quest-editor`) and P11 (`/approvals`) with `push` so the
// OS back button returns to `/today`; P09/P11 must therefore return with
// `context.pop()` and must not assume they were `go`-navigated to.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../test_scope.dart';

/// Pushes [to] from [from] and asserts the location contract: the app starts
/// at [from], `push` puts [to] on top, and `pop` returns to [from].
Future<void> expectPushPop(WidgetTester tester, String from, String to) async {
  await pumpAppRoute(tester, from);
  expect(currentPath(tester), from, reason: '$from mounts at its own path');

  final context = tester.element(find.byType(Navigator).first);
  // `push` completes on pop — never await it before popping.
  // ignore: unawaited_futures
  GoRouter.of(context).push(to);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));

  expect(
    pushedPath(tester),
    to,
    reason: 'push($to) from $from renders $to on top',
  );

  GoRouter.of(context).pop();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));

  expect(pushedPath(tester), from, reason: 'pop from $to returns to $from');
  expect(
    currentPath(tester),
    from,
    reason: 'pop leaves the declarative configuration at $from',
  );
}

void main() {
  group('push/pop contract', () {
    testWidgets('push P09 quest editor from /today, pop returns', (
      tester,
    ) async {
      await setUpTestScope();
      await expectPushPop(tester, '/today', '/quest-editor');
      await disposeApp(tester);
    });

    testWidgets('push P11 approvals from /today, pop returns', (tester) async {
      await setUpTestScope();
      await expectPushPop(tester, '/today', '/approvals');
      await disposeApp(tester);
    });

    testWidgets('push /value-tour from /welcome, pop returns', (tester) async {
      await setUpTestScope();
      await expectPushPop(tester, '/welcome', '/value-tour');
      await disposeApp(tester);
    });

    testWidgets('push between top-level onboarding routes, pop returns', (
      tester,
    ) async {
      await setUpTestScope();
      await expectPushPop(tester, '/add-children', '/pocket-money-setup');
      await disposeApp(tester);
    });

    testWidgets('push from a shell-branch route to a sibling branch', (
      tester,
    ) async {
      await setUpTestScope();
      await expectPushPop(tester, '/today', '/quests');
      await disposeApp(tester);
    });

    testWidgets('nested pushes pop back one level at a time', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');
      expect(currentPath(tester), '/today');

      final context = tester.element(find.byType(Navigator).first);
      // `push` completes on pop — never await it before popping.
      // ignore: unawaited_futures
      GoRouter.of(context).push('/quest-editor');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(pushedPath(tester), '/quest-editor');

      // Same here: the future only completes on the pop below.
      // ignore: unawaited_futures
      GoRouter.of(context).push('/approvals');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(pushedPath(tester), '/approvals');

      GoRouter.of(context).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(pushedPath(tester), '/quest-editor', reason: 'one pop, one level');

      GoRouter.of(context).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        pushedPath(tester),
        '/today',
        reason: 'second pop unwinds the stack',
      );
      expect(currentPath(tester), '/today');
      await disposeApp(tester);
    });

    testWidgets('the two location helpers agree when nothing is pushed', (
      tester,
    ) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');
      expect(pushedPath(tester), currentPath(tester));
      expect(pushedPath(tester), '/today');
      await disposeApp(tester);
    });
  });
}
