// P16 Settings — the modal-close tap guard (P16-B08, iteration 3).
//
// `P16TransientGuard` is new product code with no test of its own until this
// file. It is a process-wide `static DateTime?` plus a 300 ms window, which
// makes it the kind of helper with two failure modes that no existing test can
// see:
//
//   1. The window never expires — every row on /settings goes dead for the
//      rest of the session. Nothing else in the suite would notice, because
//      every other test opens the screen fresh.
//   2. The guard leaks into the NEXT test — it is static state, and a widget
//      test that closes a modal leaves 300 ms of suppression behind.
//      `p16_test_support.dart` clears it on every pump for that reason.
//
// Both are pinned here: the arithmetic through an injected clock (no widgets,
// so the boundaries are exact), and the same thing through real taps on the
// screen. The CLOCK rule is part of what is being proved — the guard reads
// `clock.now()`, never `DateTime.now()`, which is why `withClock` can move it.

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/settings/presentation/widgets/p16_transient_guard.dart';

import '../../test_scope.dart';
import 'p16_test_support.dart';

void main() {
  setUpAll(loadP16Fonts);

  group('P16TransientGuard — the window', () {
    test('is 300 ms and expires exactly', () {
      expect(P16TransientGuard.window, const Duration(milliseconds: 300));

      var now = DateTime.utc(2026, 10, 3, 8, 41);
      P16TransientGuard.reset();
      expect(
        P16TransientGuard.suppressing,
        isFalse,
        reason: 'nothing has closed yet',
      );

      withClock(Clock(() => now), () {
        P16TransientGuard.suppressShortly();
        expect(P16TransientGuard.suppressing, isTrue);

        now = now.add(const Duration(milliseconds: 299));
        expect(P16TransientGuard.suppressing, isTrue);

        now = now.add(const Duration(milliseconds: 1));
        expect(
          P16TransientGuard.suppressing,
          isTrue,
          reason: 'exactly at the window the guard still holds (inclusive)',
        );

        now = now.add(const Duration(milliseconds: 1));
        expect(
          P16TransientGuard.suppressing,
          isFalse,
          reason: 'one millisecond later the rows are live again',
        );
      });

      P16TransientGuard.reset();
    });

    test('run() swallows inside the window and passes outside it', () {
      var now = DateTime.utc(2026, 10, 3, 8, 41);
      var taps = 0;
      P16TransientGuard.reset();

      withClock(Clock(() => now), () {
        P16TransientGuard.run(() => taps++);
        expect(taps, 1, reason: 'an unarmed guard is a pass-through');

        P16TransientGuard.suppressShortly();
        P16TransientGuard.run(() => taps++);
        expect(taps, 1, reason: 'a fenced tap does nothing at all');

        now = now.add(
          P16TransientGuard.window + const Duration(milliseconds: 1),
        );
        P16TransientGuard.run(() => taps++);
        expect(taps, 2, reason: 'and it recovers on its own');
      });

      P16TransientGuard.reset();
    });

    test('reset() clears the window (the cross-test leak)', () {
      P16TransientGuard.suppressShortly();
      expect(P16TransientGuard.suppressing, isTrue);

      P16TransientGuard.reset();
      expect(P16TransientGuard.suppressing, isFalse);
    });
  });

  group('P16TransientGuard — on the real screen', () {
    testWidgets('closing the picker arms the guard', (tester) async {
      // The B08 mechanism, asserted directly: the sheet's close must fence the
      // rows underneath it. (`pumpAndSettle` here is only used to finish the
      // exit animation so the sheet leaves the tree; the guard's own window is
      // checked without depending on how long that animation takes.)
      await pumpSettingsApp(tester);
      await scrollSettingsTo(tester, find.text('Time zone'));

      await tester.tap(find.text('Time zone'));
      await tester.pumpAndSettle();
      expect(find.byType(NestBottomSheet), findsOneWidget);
      expect(P16TransientGuard.suppressing, isFalse);

      await tester.tap(find.text('Karachi'));
      // ONE frame only: `_ZoneRow.onTap` arms the guard synchronously before
      // popping, so the window is open here. Settling first would let the exit
      // animation push the fake clock past the 300 ms and expire it again —
      // which is the guard working, not a reason to assert after a settle.
      await tester.pump();
      expect(
        P16TransientGuard.suppressing,
        isTrue,
        reason: 'a closed sheet must arm the tap guard (P16-B08)',
      );

      await tester.pumpAndSettle();
      expect(await familyZoneId(), 'Asia/Karachi');
      expect(find.byType(NestBottomSheet), findsNothing);

      await disposeApp(tester);
    });

    testWidgets('a fenced row tap does nothing, and the row works again once '
        'the window passes', (tester) async {
      // Armed the same way the sheet arms it, so the assertion is about the
      // window and not about how long an exit animation happens to take.
      await pumpSettingsApp(tester);
      await scrollSettingsTo(tester, find.text('Download our data'));

      P16TransientGuard.suppressShortly();
      await tester.tap(find.text('Download our data'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        pushedPath(tester),
        '/settings',
        reason: 'a fenced tap must not navigate',
      );

      await tester.pump(P16TransientGuard.window);
      await tester.tap(find.text('Download our data'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        pushedPath(tester),
        '/privacy',
        reason: 'the guard must expire — a stuck guard kills every row',
      );

      await disposeApp(tester);
    });

    testWidgets('an unarmed screen navigates on the first tap', (tester) async {
      // The control case for the test above: no modal has closed, so nothing
      // is fenced and the row works immediately.
      await pumpSettingsApp(tester);
      await scrollSettingsTo(tester, find.text('Download our data'));

      await tester.tap(find.text('Download our data'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(pushedPath(tester), '/privacy');
      await disposeApp(tester);
    });

    testWidgets('the move banner stays operable right after a sheet closes', (
      tester,
    ) async {
      // The guard fences page ROWS only. The banner's Switch / Not now
      // dispatch straight to the bloc (ORCHESTRATOR_NOTES: "never switch
      // without the confirm tap") — fencing them would strand the prompt.
      await pumpSettingsApp(tester, deviceZone: 'Asia/Dubai');
      expect(find.byKey(const ValueKey('p16_move_banner')), findsOneWidget);

      await scrollSettingsTo(tester, find.text('Time zone'));
      await tester.tap(find.text('Time zone'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Karachi'));
      await tester.pumpAndSettle();

      // The banner sits ABOVE the picker row; walk back up to it.
      await scrollSettingsUpTo(
        tester,
        find.byKey(const ValueKey('p16_move_not_now')),
      );
      await tester.tap(find.byKey(const ValueKey('p16_move_not_now')));
      await settleSettings(tester);

      expect(
        find.byKey(const ValueKey('p16_move_banner')),
        findsNothing,
        reason: '"Not now" must work inside the guard window',
      );
      expect(
        await familyZoneId(),
        'Asia/Karachi',
        reason: 'the picker write stands; the dismissal writes nothing',
      );

      await disposeApp(tester);
    });
  });

  group('P16TransientGuard — what it must NOT fence (review finding 2)', () {
    // Review iteration 6 (major): every `NestToggle.onChanged` handler used to
    // wrap its write in `P16TransientGuard.run`. Notifications sits immediately
    // below the zone picker, so the natural sequence — open the picker, pick a
    // zone, flip a switch — put the user's very next tap inside the 300 ms
    // window and the switch did not move, with no feedback to explain it. The
    // three wrappers are gone; the guard is only on rows that open a route or a
    // dialog. A switch flip cannot re-fire itself, so the double-tap
    // fall-through the guard exists for (B08/B10) can never apply to one — the
    // same reasoning that already exempted the move banner's buttons above.
    //
    // Two proofs, because the two ways this could rot are different:
    //   1. the end-to-end sequence, which is the actual user path;
    //   2. the invariant with the guard armed deliberately — the same armed
    //      state must fence a ROW and still let a SWITCH through, which pins
    //      the boundary rather than one call site.

    testWidgets('the switch below the picker is live on the very next tap', (
      tester,
    ) async {
      await pumpSettingsApp(tester);
      // Both controls in view before the sheet opens, so nothing scrolls while
      // the guard window is open (`ensureVisible` would jump the scroll offset
      // without a frame, but the row has to be built first).
      await scrollSettingsTo(tester, find.text('Time zone'));
      final toggle = find.byType(NestToggle).first;
      await tester.ensureVisible(toggle);
      expect(toggle, findsOneWidget);

      await tester.tap(find.text('Time zone'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Karachi'));
      // ONE frame: `_ZoneRow.onTap` arms the guard synchronously before popping,
      // so the window is open here — this is the state the review called broken.
      await tester.pump();
      expect(
        P16TransientGuard.suppressing,
        isTrue,
        reason: 'the sheet really did close inside the window',
      );

      final before = (await settingRows()).single.notifApprovals;
      await tester.tap(toggle);
      await settleSettings(tester);

      expect(
        (await settingRows()).single.notifApprovals,
        !before,
        reason:
            'a switch flip inside the guard window must still reach the DB — '
            'the user cannot tell a fenced switch from a broken one',
      );
      expect(
        tester.widget<NestToggle>(find.byType(NestToggle).first).value,
        !before,
        reason: 'and the track must show the new state, not snap back',
      );

      await disposeApp(tester);
    });

    testWidgets('armed: a row tap is fenced and a switch flip is not', (
      tester,
    ) async {
      await pumpSettingsApp(tester);
      final toggle = find.byType(NestToggle).first;
      await scrollSettingsTo(tester, find.text('Download our data'));
      await tester.ensureVisible(toggle);
      final before = (await settingRows()).single.notifApprovals;

      // Armed exactly the way a closing sheet arms it.
      P16TransientGuard.suppressShortly();

      await tester.tap(find.text('Download our data'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        pushedPath(tester),
        '/settings',
        reason: 'the guard still fences a row that would navigate (B08)',
      );

      await tester.tap(toggle);
      await settleSettings(tester);
      expect(
        (await settingRows()).single.notifApprovals,
        !before,
        reason: 'the same armed window must NOT swallow a switch flip',
      );

      await disposeApp(tester);
    });
  });
}
