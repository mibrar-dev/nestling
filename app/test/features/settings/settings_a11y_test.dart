// P16 Settings — accessibility contract (RULES.md §8 and the owner
// "ACCESSIBILITY ACTIONS" rule).
//
// Every control on /settings must be operable by VoiceOver/TalkBack: a node
// that announces itself, exposes SemanticsAction.tap, and whose activation
// changes the REAL state (a Drift write, a sheet, a route). A `find.text`
// test passes for a control that a screen reader can see but not press, so
// these tests walk the semantics tree, act on the node, and then read the
// database.
//
// Two labels are matched as SUBSTRINGS, never for equality: Flutter announces
// one node per gesture boundary, so a P16 row's node carries its title, its
// subtitle and its chevron together, and a toggle row carries the row title
// plus the switch's own `aria-label` from the design.
//
// KNOWN SHARED WART (not a P16 finding, identical on /today and P14 — see
// `rewards_a11y_test.dart`): a design-system control built as
// `Semantics(label:, onTap:) > InkWell` also exposes the inner InkWell (and
// `NestToggle`'s `GestureDetector`) as a SECOND node, which is either a
// duplicate of the row copy or carries no label at all. Those live in
// `core/design_system`, not here. The one test below that touches the subject
// pins its BLAST RADIUS — the only unlabelled tappable nodes allowed on this
// screen are the three switch tracks — so a new unlabelled control on P16
// still fails.

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/settings/presentation/widgets/settings_rows.dart';

import '../../test_scope.dart';
import 'p16_test_support.dart';

/// One row of [kP16Controls]: the section it sits in, the copy its semantics
/// node has to announce, and the `Text` used to scroll it on screen.
class P16Control {
  const P16Control(this.section, this.label, this.anchor);

  final String section;
  final String label;
  final String anchor;
}

/// Every control P16 renders on the loaded screen. The switch labels are the
/// design's own `aria-label`s, which differ from the row titles.
const List<P16Control> kP16Controls = <P16Control>[
  P16Control('Family', 'Sarah — you', 'Sarah — you'),
  P16Control('Family', 'James — co-parent', 'James — co-parent'),
  P16Control('Family', 'Invite co-parent', 'Invite co-parent'),
  P16Control('Children', 'Maya · 7–9', 'Maya · 7–9'),
  P16Control('Children', 'Leo · 4–6', 'Leo · 4–6'),
  P16Control('Children', 'Add child', 'Add child'),
  P16Control('Subscription', 'Manage subscription', 'Manage subscription'),
  P16Control('Time zone', 'London (GMT+1)', 'Time zone'),
  P16Control(
    'Notifications',
    'Approvals waiting notifications',
    'Approvals waiting',
  ),
  P16Control('Notifications', 'Payout day reminder', 'Payout day reminder'),
  P16Control('Notifications', 'Weekly family summary', 'Weekly family summary'),
  P16Control('Privacy', 'Download our data', 'Download our data'),
  P16Control('Privacy', 'Privacy Notice', 'Privacy Notice'),
  P16Control('Privacy', 'Delete family account', 'Delete family account'),
  P16Control('About', 'Help & feedback', 'Help & feedback'),
];

void main() {
  setUpAll(loadP16Fonts);

  group('P16 accessibility — labels and tap actions', () {
    testWidgets('every control announces itself and exposes a tap action', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpSettingsApp(tester);
      await tester.pump();

      for (final control in kP16Controls) {
        await scrollSettingsTo(tester, find.text(control.anchor));
        final nodes = p16Announcing(tester, control.label);
        expect(
          nodes,
          isNotEmpty,
          reason:
              '${control.section}: no tappable node announces "${control.label}"',
        );
        // `p16Announcing` only returns nodes that expose the tap action; spell
        // the contract out anyway so the failure reads as an action problem.
        for (final node in nodes) {
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            isTrue,
            reason: '${control.section}: "${control.label}" must be operable',
          );
          expect(
            node.getSemanticsData().label.trim(),
            isNotEmpty,
            reason:
                '${control.section}: "${control.label}" must announce a name',
          );
        }
      }

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('the only unlabelled tappable nodes are the three switch '
        'tracks', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSettingsApp(tester);
      await tester.pump();

      // Scroll first: a semantics node survives off screen, so the switch
      // tracks are only comparable once their widgets are built.
      await scrollSettingsTo(tester, find.text('Approvals waiting'));
      final anonymous = tappableNodes(tester)
          .where((node) => node.getSemanticsData().label.trim().isEmpty)
          .toList();
      expect(
        anonymous,
        hasLength(3),
        reason:
            'one per NestToggle (shared design-system wart); anything else '
            'announcing nothing is a P16 defect',
      );
      final toggles = find.byType(NestToggle);
      final built = toggles.evaluate().length;
      expect(built, anonymous.length, reason: 'one unlabelled node per switch');
      final tracks = <Rect>[
        for (var i = 0; i < built; i++) tester.getRect(toggles.at(i)),
      ];
      for (final node in anonymous) {
        expect(
          tracks,
          contains(p16NodeRect(tester, node)),
          reason: 'an unlabelled target must sit exactly on a NestToggle track',
        );
      }

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('tap targets are at least 44 px in parent mode', (
      tester,
    ) async {
      await pumpSettingsApp(tester);

      // Every row and the subcard link: the node's laid-out height, not its
      // label's. The switch rows are excluded here — their track is 31 px on
      // purpose, and the 44 px target is the hit slop the next test probes.
      // The list builds lazily, so each control is measured at its own scroll
      // stop (a control that is off screen has no semantics node to measure).
      for (final control in kP16Controls) {
        if (control.section == 'Notifications') continue;
        await scrollSettingsTo(tester, find.text(control.anchor));
        final nodes = p16Announcing(tester, control.label);
        expect(
          nodes,
          isNotEmpty,
          reason: '${control.section}: "${control.label}" must be operable',
        );
        final height = p16NodeRect(tester, nodes.last).height;
        expect(
          height,
          greaterThanOrEqualTo(NestDevice.tapParent),
          reason:
              '${control.section}: "${control.label}" is $height px high — '
              'needs 44',
        );
      }

      // The switches lay out at the design's 51x31 track whatever the width.
      final toggles = find.byType(NestToggle);
      expect(toggles, findsNWidgets(3));
      for (var i = 0; i < 3; i++) {
        expect(tester.getRect(toggles.at(i)).size, const Size(51, 31));
      }

      await disposeApp(tester);
    });

    testWidgets('Manage subscription is ONE labelled node with ONE tap action', (
      tester,
    ) async {
      // Iteration 2: the wrapper is `Semantics(excludeSemantics: true)` now
      // (review finding 8), which is only legal because it passes `onTap:`
      // itself — the owner ACCESSIBILITY rule. Assert both halves: the inner
      // InkWell must NOT leak a second node, and the surviving node must still
      // be operable and must actually navigate.
      final handle = tester.ensureSemantics();
      await pumpSettingsApp(tester);
      await tester.pump();
      await scrollSettingsTo(tester, find.text('Manage subscription'));

      final nodes = p16Announcing(tester, 'Manage subscription');
      expect(
        nodes,
        hasLength(1),
        reason:
            'one announcement per control — got ${nodes.map((node) => node.getSemanticsData().label).toList()}',
      );
      final data = nodes.single.getSemanticsData();
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      expect(data.label, 'Manage subscription');
      expect(
        p16NodeRect(tester, nodes.single).height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );

      await p16ActivateSemantics(tester, nodes.single);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        pushedPath(tester),
        '/paywall',
        reason: 'the excluded wrapper still navigates',
      );

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('a switch is live on its own track', (tester) async {
      await pumpSettingsApp(tester);
      await scrollSettingsTo(tester, find.text('Approvals waiting'));
      final toggle = find.byType(NestToggle).first;
      final track = tester.getRect(toggle);
      final before = (await settingRows()).single.notifApprovals;

      await tester.tapAt(track.center);
      await settleSettings(tester);
      expect(
        (await settingRows()).single.notifApprovals,
        !before,
        reason: 'the 51x31 track itself must flip the switch',
      );
      await tester.tapAt(track.center);
      await settleSettings(tester);
      expect(
        (await settingRows()).single.notifApprovals,
        before,
        reason: 'a second tap flips it back',
      );

      // The widget follows the stream, it does not keep local state.
      expect(tester.widget<NestToggle>(toggle).value, before);

      await disposeApp(tester);
    });

    testWidgets('every section label is announced as a heading', (
      tester,
    ) async {
      // Iteration 2: the labels render through the screen-local `_P16Sect`
      // rather than the shared `NestSectionLabel`, and the header flag is the
      // only thing that lets a screen-reader user skim the page by heading.
      // Address each label directly — a walk of the semantics tree misses
      // nodes that have not been through a semantics pass yet.
      final handle = tester.ensureSemantics();
      await pumpSettingsApp(tester);
      await tester.pump();

      for (final label in <String>[
        'FAMILY',
        'CHILDREN',
        'SUBSCRIPTION',
        'TIME ZONE',
        'NOTIFICATIONS',
        'PRIVACY',
        'ABOUT',
      ]) {
        await scrollSettingsTo(tester, find.text(label));
        expect(
          tester
              .getSemantics(find.text(label))
              .getSemanticsData()
              .flagsCollection
              .isHeader,
          isTrue,
          reason: '"$label" must announce a header',
        );
      }

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets(
      '[P16-T02] a switch is live 5 px above and 5 px below its track',
      (tester) async {
        // LIVE GUARD (was an open bug, iterations 1-2). `NestToggle` reaches
        // 6.5 px above/below its 31 px track via `_ToggleHitSlop`, but
        // `NestListRow`'s `EdgeInsets.fromLTRB(12, 10, 16, 10)` put the
        // switch inside a 36 px content box and a padded ancestor forwards no
        // hit outside its own box — measured live range was
        // `track.top - 2 … track.bottom + 2`, i.e. ≈36 px against the owner
        // rule's 44 px.
        //
        // Fixed in iteration 3 by the screen: the three switch rows use P16's
        // `SettingsRow` at 6 px vertical padding (content box 56 - 12 = 44)
        // AND wrap each `NestToggle` in `SizedBox(height: 44, Center(…))`.
        // Both halves are needed — padding alone left `track.top - 5` dead
        // (measured in iteration 2) — and dropping either re-opens the bug,
        // which is what this proof is for. 5 px is stricter than the 4 px the
        // orchestrator's note asks for.
        await pumpSettingsApp(tester);
        await scrollSettingsTo(tester, find.text('Approvals waiting'));
        final track = tester.getRect(find.byType(NestToggle).first);
        final before = (await settingRows()).single.notifApprovals;

        await tester.tapAt(Offset(track.center.dx, track.top - 5));
        await settleSettings(tester);
        expect(
          (await settingRows()).single.notifApprovals,
          !before,
          reason: '5 px above the 31 px track must still flip the switch',
        );

        await tester.tapAt(Offset(track.center.dx, track.bottom + 5));
        await settleSettings(tester);
        expect(
          (await settingRows()).single.notifApprovals,
          before,
          reason: '5 px below the track must flip it back',
        );

        // The mechanism, pinned so the next reader can see why the taps work:
        // the switch row is still a 56 px design row (same as every other row
        // on the page), it uses the 6 px vertical padding that makes the
        // content box 44, and each toggle keeps the design's 51x31 track.
        final toggle = find.byType(NestToggle).first;
        final row = find
            .ancestor(of: toggle, matching: find.byType(SettingsRow))
            .first;
        expect(
          tester.getRect(row).height,
          56,
          reason: 'the switch row keeps the design 56 px row height',
        );
        expect(
          tester.widget<SettingsRow>(row).padding,
          const EdgeInsets.fromLTRB(12, 6, 16, 6),
          reason: '6 px vertical padding is half of the 44 px fix',
        );
        expect(track.size, const Size(51, 31), reason: 'the design track');
        // …and the 44-high box the slop needs is really there.
        expect(
          tester.getRect(toggle).height,
          31,
          reason: 'NestToggle lays out at the track, not at the hit box',
        );
        final hitBox = tester.getRect(
          find.ancestor(of: toggle, matching: find.byType(SizedBox)).first,
        );
        expect(
          hitBox.height,
          44,
          reason: 'the 44-high wrapper is the other half of the fix',
        );

        await disposeApp(tester);
      },
      skip: false,
    );
  });

  group('P16 accessibility — activation drives the real state', () {
    testWidgets('semantics activation of a switch writes the settings row', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpSettingsApp(tester);
      await tester.pump();
      await scrollSettingsTo(tester, find.text('Approvals waiting'));

      final node = p16Announcing(
        tester,
        'Approvals waiting notifications',
      ).first;
      expect(
        node.getSemanticsData().flagsCollection.isToggled,
        isNot(Tristate.none),
      );
      expect(
        node.getSemanticsData().flagsCollection.isToggled,
        (await settingRows()).single.notifApprovals
            ? Tristate.isTrue
            : Tristate.isFalse,
        reason: 'the switch announces the DATABASE value, not a constant',
      );
      expect(
        node.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isTrue,
      );

      final before = (await settingRows()).single.notifApprovals;
      await p16ActivateSemantics(tester, node);
      await settleSettings(tester);

      expect(
        (await settingRows()).single.notifApprovals,
        !before,
        reason: 'the tap wrote the Drift row',
      );

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('semantics activation of a child row navigates', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpSettingsApp(tester);
      await tester.pump();

      await p16ActivateSemantics(
        tester,
        p16Announcing(tester, 'Maya · 7–9').first,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(pushedPath(tester), '/child-profile');

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('the move banner announces both actions and Switch stores the '
        'device zone', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSettingsApp(tester, deviceZone: 'Asia/Dubai');
      await tester.pump();

      final switchNode = p16Announcing(tester, 'Switch').first;
      final notNow = p16Announcing(tester, 'Not now').first;
      expect(
        p16NodeRect(tester, switchNode).height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );
      expect(
        p16NodeRect(tester, notNow).height,
        greaterThanOrEqualTo(NestDevice.tapParent),
      );

      await p16ActivateSemantics(tester, switchNode);
      await settleSettings(tester);

      expect(await familyZoneId(), 'Asia/Dubai');
      expect(find.byKey(const ValueKey('p16_move_banner')), findsNothing);

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('the picker rows announce their short label and activate', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpSettingsApp(tester);
      await tester.pump();
      await scrollSettingsTo(tester, find.text('Time zone'));
      await p16ActivateSemantics(
        tester,
        p16Announcing(tester, 'Time zone').first,
      );
      await tester.pumpAndSettle();

      final karachi = p16Announcing(tester, 'Karachi');
      expect(karachi, isNotEmpty, reason: 'the picker lists the curated zones');
      expect(
        karachi.map((node) => node.getSemanticsData().label),
        anyElement(contains('Asia/Karachi')),
        reason: 'raw IANA ids are allowed in the picker only',
      );

      await p16ActivateSemantics(tester, karachi.first);
      await settleSettings(tester);
      await tester.pumpAndSettle();

      expect(await familyZoneId(), 'Asia/Karachi');
      expect(find.byType(NestBottomSheet), findsNothing);

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('the delete confirm exposes both buttons before it acts', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpSettingsApp(tester);
      await tester.pump();
      await scrollSettingsTo(tester, find.text('Delete family account'));
      await p16ActivateSemantics(
        tester,
        p16Announcing(tester, 'Delete family account').first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Delete family account?'), findsOneWidget);
      // Both buttons are operable — `settings_navigation_test.dart` proves what
      // Cancel and Delete actually do (and currently pin the [P16-T01] bug).
      for (final label in const <String>['Cancel', 'Delete']) {
        final nodes = p16Announcing(tester, label);
        expect(nodes, isNotEmpty, reason: '"$label" must be operable');
        expect(
          p16NodeRect(tester, nodes.first).height,
          greaterThanOrEqualTo(NestDevice.tapParent),
          reason: '"$label" must be a 44 px target',
        );
      }

      handle.dispose();
      await disposeApp(tester);
    });
  });
}
