// P14 Rewards manager — accessibility contract (RULES.md §8, owner
// "ACCESSIBILITY ACTIONS" rule).
//
// Every control on the screen must be operable by VoiceOver/TalkBack:
// a labelled node with SemanticsAction.tap, a tap target of at least 44 px
// (parent mode), and `performAction(tap)` that drives the REAL behaviour —
// the Drift row for a switch, the editor sheet for an edit button. A node
// wrapped in `Semantics(excludeSemantics: true)` without `onTap:` would pass a
// `find.text` test and still be inoperable; these tests assert the action and
// then the effect, not the presence of a widget.
//
// KNOWN SHARED WART (not asserted here, filed as SHARED_REQUEST): every
// design-system control built as `Semantics(label:, onTap:) > InkWell` also
// exposes the inner InkWell as a SECOND, unnamed node. See `3_test.md`
// §"Findings" — it is pre-existing on /today and lives in core/, not in P14.

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_editor_sheet.dart';

import '../../test_scope.dart';
import 'p14_test_support.dart';

/// Nodes carrying [label] that can actually be activated.
List<SemanticsNode> actionableNodes(WidgetTester tester, String label) => find
    .semantics
    .byLabel(label)
    .evaluate()
    .where((node) => node.getSemanticsData().hasAction(SemanticsAction.tap))
    .toList();

void main() {
  setUpAll(loadBundledFonts);

  group('P14 accessibility — labels and tap actions', () {
    testWidgets('every control is one labelled node with a tap action', (
      tester,
    ) async {
      await pumpRewardsApp(tester);
      final handle = tester.ensureSemantics();
      await tester.pump();

      final labels = <String>[
        'Back',
        ...demoApprovalLabels.values,
        ...demoEditLabels.values,
        '+ New reward',
      ];
      for (final label in labels) {
        final nodes = find.semantics.byLabel(label).evaluate();
        expect(
          nodes.where((node) => node.getSemanticsData().label == label),
          hasLength(1),
          reason: '"$label" must be announced by exactly one node',
        );
        final data = nodes.single.getSemanticsData();
        expect(
          data.hasAction(SemanticsAction.tap),
          isTrue,
          reason: '"$label" must expose SemanticsAction.tap',
        );
        expect(data.label.trim(), isNotEmpty);
      }

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('each switch announces its on state, off state and disabled', (
      tester,
    ) async {
      await pumpRewardsApp(tester);
      final handle = tester.ensureSemantics();
      await tester.pump();

      // Every switch announces a toggle state, an enabled state, and its own
      // row's value — the seed's `needsOk`, never a constant
      // (ORCHESTRATOR_NOTES 12:27).
      for (final entry in demoApprovalLabels.entries) {
        final data = tester
            .getSemantics(find.bySemanticsLabel(entry.value))
            .getSemanticsData();
        expect(
          data.flagsCollection.isToggled,
          isNot(Tristate.none),
          reason: '"${entry.value}" must carry a toggle state',
        );
        expect(
          data.flagsCollection.isToggled,
          (await rewardNeedsOk(entry.key)) ? Tristate.isTrue : Tristate.isFalse,
          reason: '"${entry.value}" must announce ${entry.key}.needsOk',
        );
        expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      }

      // Flip the first switch: the node keeps a state and reports the new one.
      const first = 'r-screen';
      final was = await rewardNeedsOk(first);
      tester.semantics.performAction(
        find.semantics.byLabel('Needs approval for screen time'),
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();

      expect(await rewardNeedsOk(first), !was, reason: 'the DB row flipped');
      final flipped = tester
          .getSemantics(find.bySemanticsLabel('Needs approval for screen time'))
          .getSemanticsData();
      expect(flipped.flagsCollection.isToggled, isNot(Tristate.none));
      expect(
        flipped.flagsCollection.isToggled,
        was ? Tristate.isFalse : Tristate.isTrue,
        reason: 'after the flip the switch reports the new value',
      );

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('tap targets are at least 44 px in parent mode', (
      tester,
    ) async {
      await pumpRewardsApp(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();

      final rects = <String, Rect>{
        'nav back': tester.getRect(find.bySemanticsLabel('Back')),
        'new reward': tester.getRect(
          find.byKey(const ValueKey('p14_new_reward')),
        ),
        for (final label in demoEditLabels.values)
          'edit "$label"': tester.getRect(find.bySemanticsLabel(label)),
      };
      for (final entry in rects.entries) {
        expect(
          entry.value.width,
          greaterThanOrEqualTo(NestDevice.tapParent),
          reason: '${entry.key} is ${entry.value.size} — needs 44 px wide',
        );
        expect(
          entry.value.height,
          greaterThanOrEqualTo(NestDevice.tapParent),
          reason: '${entry.key} is ${entry.value.size} — needs 44 px high',
        );
      }

      // The switch hit box is 44 tall even though the drawn track is 31.
      final toggles = find.byType(NestToggle);
      expect(toggles, findsNWidgets(6));
      for (var i = 0; i < 6; i++) {
        final box = tester.getRect(toggles.at(i));
        expect(box.height, NestDevice.tapParent, reason: 'switch $i');
        expect(box.width, greaterThanOrEqualTo(51));
      }

      await disposeApp(tester);
    });

    testWidgets('the switch is live 5 px above, on and 5 px below its track', (
      tester,
    ) async {
      await pumpRewardsApp(tester);
      final toggle = find.byType(NestToggle).first;
      final track = visibleTrackRect(tester, toggle);
      const id = 'r-screen';
      final start = await rewardNeedsOk(id);

      // 5 px above the top edge of the 31 px track (the 44 px box leaves 6.5
      // px of slack on each side).
      await tester.tapAt(Offset(track.center.dx, track.top - 5));
      await tester.pumpAndSettle();
      expect(await rewardNeedsOk(id), !start);

      // Dead on the track.
      await tester.tapAt(track.center);
      await tester.pumpAndSettle();
      expect(await rewardNeedsOk(id), start);

      // 5 px below the bottom edge.
      await tester.tapAt(Offset(track.center.dx, track.bottom + 5));
      await tester.pumpAndSettle();
      expect(await rewardNeedsOk(id), !start);

      // The widget reflects the write it just made — it re-renders from the
      // stream, it does not keep local state.
      expect(
        tester.widget<NestToggle>(toggle).value,
        !start,
        reason: 'the card must follow the stream',
      );

      await disposeApp(tester);
    });

    testWidgets('semantics activation of a switch writes the row', (
      tester,
    ) async {
      await pumpRewardsApp(tester);
      final handle = tester.ensureSemantics();
      await tester.pump();

      tester.semantics.performAction(
        find.semantics.byLabel('Needs approval for screen time'),
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();

      expect(await rewardNeedsOk('r-screen'), isFalse);

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('semantics activation of Back pops to the previous route', (
      tester,
    ) async {
      // The one control on P14 that NAVIGATES. `/rewards` is a top-level route
      // pushed from a parent tab, so Back must return to wherever it came from
      // — assert the location, never view text (test_scope's guidance).
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');
      final handle = tester.ensureSemantics();

      final context = tester.element(find.byType(Navigator).first);
      // The push future completes on the pop below — never await it here.
      // ignore: unawaited_futures
      GoRouter.of(context).push('/rewards');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(pushedPath(tester), '/rewards');

      final backNode = actionableNodes(tester, 'Back');
      expect(backNode, hasLength(1), reason: 'Back must be operable');

      // Semantics activation lands on the same route as a real tap.
      tester.semantics.performAction(
        find.semantics.byLabel('Back'),
        SemanticsAction.tap,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        pushedPath(tester),
        '/today',
        reason: 'Back from /rewards returns to the route it was pushed from',
      );
      expect(currentPath(tester), '/today');

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('a real Back tap also returns to /today', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/today');
      final context = tester.element(find.byType(Navigator).first);
      // The push future completes on the pop below — never await it here.
      // ignore: unawaited_futures
      GoRouter.of(context).push('/rewards');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(pushedPath(tester), '/today');
      expect(currentPath(tester), '/today');

      await disposeApp(tester);
    });

    testWidgets('semantics activation of edit opens the prefilled sheet', (
      tester,
    ) async {
      await pumpRewardsApp(tester);
      final handle = tester.ensureSemantics();
      await tester.pump();

      tester.semantics.performAction(
        find.semantics.byLabel('Edit Pick Friday film'),
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();

      expect(find.byType(RewardEditorSheet), findsOneWidget);
      expect(
        find.widgetWithText(NestTextField, 'Pick Friday film'),
        findsOneWidget,
      );
      expect(find.text('80 coins'), findsOneWidget);

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('semantics activation of + New reward opens a blank sheet', (
      tester,
    ) async {
      await pumpRewardsApp(tester);
      final handle = tester.ensureSemantics();
      await tester.pump();

      await tester.ensureVisible(find.byKey(const ValueKey('p14_new_reward')));
      await tester.pumpAndSettle();
      tester.semantics.performAction(
        find.semantics.byLabel('+ New reward'),
        SemanticsAction.tap,
      );
      await tester.pumpAndSettle();

      expect(find.byType(RewardEditorSheet), findsOneWidget);
      expect(find.text('New reward'), findsOneWidget);
      // Blank: defaults only, no reward name prefilled.
      expect(find.text('Edit reward'), findsNothing);
      expect(
        tester
            .widget<NestTextField>(find.byKey(const ValueKey('p14_name_field')))
            .controller!
            .text,
        isEmpty,
      );

      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P14 accessibility — the editor sheet', () {
    testWidgets('every sheet control is labelled with a tap action', (
      tester,
    ) async {
      await pumpRewardsApp(tester);
      await tester.tap(find.bySemanticsLabel('Edit Baking together'));
      await tester.pumpAndSettle();

      final handle = tester.ensureSemantics();
      await tester.pump();

      for (final label in <String>[
        'Close',
        'Decrease price',
        'Increase price',
        'Needs my OK',
        'Save',
        'Cancel',
        'Delete',
      ]) {
        expect(
          actionableNodes(tester, label),
          hasLength(1),
          reason: '"$label" must be one activatable node',
        );
      }

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('sheet controls are at least 44 px and Save is 52', (
      tester,
    ) async {
      await pumpRewardsApp(tester);
      await tester.tap(find.bySemanticsLabel('Edit Baking together'));
      await tester.pumpAndSettle();

      // `'Needs my OK'` is both the visible row label and the switch's
      // semantic label, so the switch is addressed by type here.
      final rects = <String, Rect>{
        'Close': tester.getRect(find.bySemanticsLabel('Close')),
        'Decrease price': tester.getRect(
          find.bySemanticsLabel('Decrease price'),
        ),
        'Increase price': tester.getRect(
          find.bySemanticsLabel('Increase price'),
        ),
        'Needs my OK switch': tester.getRect(find.byType(NestToggle).last),
        'Save': tester.getRect(find.byKey(const ValueKey('p14_save'))),
        'Cancel': tester.getRect(find.byKey(const ValueKey('p14_cancel'))),
        'Delete': tester.getRect(find.byKey(const ValueKey('p14_delete'))),
      };
      for (final entry in rects.entries) {
        expect(
          entry.value.width,
          greaterThanOrEqualTo(NestDevice.tapParent),
          reason: '${entry.key} width ${entry.value.size}',
        );
        expect(
          entry.value.height,
          greaterThanOrEqualTo(NestDevice.tapParent),
          reason: '${entry.key} height ${entry.value.size}',
        );
      }
      expect(tester.getRect(find.byKey(const ValueKey('p14_save'))).height, 52);
      expect(
        tester.getRect(find.byKey(const ValueKey('p14_cancel'))).height,
        52,
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('p14_delete'))).height,
        52,
      );
      expect(
        tester.getRect(find.bySemanticsLabel('Close')).size,
        const Size(44, 44),
      );

      await disposeApp(tester);
    });

    testWidgets('a disabled Save announces disabled and has no tap action', (
      tester,
    ) async {
      await pumpRewardsApp(tester);
      await tester.tap(find.bySemanticsLabel('Edit Baking together'));
      await tester.pumpAndSettle();

      final handle = tester.ensureSemantics();
      await tester.pump();

      // Clear the prefilled name: nothing to save.
      await tester.enterText(
        find.byKey(const ValueKey('p14_name_field')),
        '   ',
      );
      await tester.pumpAndSettle();

      final data = tester
          .getSemantics(find.bySemanticsLabel('Save'))
          .getSemanticsData();
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      expect(
        data.hasAction(SemanticsAction.tap),
        isFalse,
        reason: 'a disabled control must not advertise a tap',
      );
      // Whitespace is not a name: tapping the disabled Save does nothing.
      await tester.tap(find.byKey(const ValueKey('p14_save')));
      await tester.pumpAndSettle();
      expect(find.byType(RewardEditorSheet), findsOneWidget);
      expect(
        (await rewardRow('r-baking')).title,
        'Baking together',
        reason: 'a disabled Save must not write',
      );

      handle.dispose();
      await disposeApp(tester);
    });
  });
}
