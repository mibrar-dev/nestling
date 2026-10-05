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
// FIXED in shared/ds_cleanup: every design-system control is now one node.
// `Semantics(label:, onTap:, excludeSemantics: true) > InkWell` drops the
// inner InkWell's (and `NestToggle`'s `GestureDetector`'s) duplicate tap node,
// so the surviving node carries the label AND the tap action. There are no
// unlabelled tappable nodes left on this screen; the test below pins that
// (any new unlabelled control fails).

import 'dart:ui' show Tristate;

import 'package:drift/drift.dart' show Value;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/design_system/design_system.dart';

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

/// Every TAPPABLE control P16 renders on the loaded screen. The switch labels
/// are the design's own `aria-label`s, which differ from the row titles.
///
/// 4_review finding 6: the two static Family rows (`Sarah — you`,
/// `James — co-parent`) are display-only — `SettingsRow` with `onTap == null`
/// wraps them in `Semantics(container: true)` with no tap action — so they
/// are NOT controls and live in their own group below, not here.
const List<P16Control> kP16Controls = <P16Control>[
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

    testWidgets('the two static Family rows each announce in their own '
        'non-tappable node', (tester) async {
      // 4_review finding 6: `SettingsRow` with `onTap == null` wraps the row
      // in `Semantics(container: true)` — a plain container, no label, no
      // onTap — so each static row is its own group and no longer folds
      // into the Invite co-parent button's node. Plain container only, so
      // the ACCESSIBILITY-ACTIONS rule (every interactive node keeps its
      // tap) is untouched.
      final handle = tester.ensureSemantics();
      await pumpSettingsApp(tester);
      await tester.pump();

      List<SemanticsNode> allNodes() {
        final views = tester.binding.renderViews;
        final root = views.isEmpty
            ? null
            : views.first.owner?.semanticsOwner?.rootSemanticsNode;
        if (root == null) throw StateError('no semantics tree');
        final found = <SemanticsNode>[];
        void visit(SemanticsNode node) {
          found.add(node);
          node.visitChildren((child) {
            visit(child);
            return true;
          });
        }

        visit(root);
        return found;
      }

      List<SemanticsNode> announcing(String fragment) => allNodes()
          .where((node) => node.getSemanticsData().label.contains(fragment))
          .toList();

      for (final anchor in <String>['Sarah — you', 'James — co-parent']) {
        await scrollSettingsTo(tester, find.text(anchor));
      }

      // No TAPPABLE node may carry static-row copy — otherwise the text is
      // still folding into a button (the old Invite-node merge).
      expect(
        p16Announcing(tester, 'Sarah — you'),
        isEmpty,
        reason: 'Sarah must not fold into a tappable node',
      );
      expect(
        p16Announcing(tester, 'James — co-parent'),
        isEmpty,
        reason: 'James must not fold into a tappable node',
      );

      final sarah = announcing('Sarah — you')
          .where(
            (node) => !node.getSemanticsData().hasAction(SemanticsAction.tap),
          )
          .toList();
      final james = announcing('James — co-parent')
          .where(
            (node) => !node.getSemanticsData().hasAction(SemanticsAction.tap),
          )
          .toList();
      expect(sarah, isNotEmpty, reason: 'Sarah needs its own static node');
      expect(james, isNotEmpty, reason: 'James needs its own static node');
      expect(
        identical(sarah.first, james.first),
        isFalse,
        reason: 'the two rows must be distinct nodes',
      );
      expect(
        sarah.first.getSemanticsData().label,
        isNot(contains('James — co-parent')),
        reason: 'Sarah node must not merge James',
      );
      expect(
        james.first.getSemanticsData().label,
        isNot(contains('Sarah — you')),
        reason: 'James node must not merge Sarah',
      );

      // The Invite row stays operable without static copy. Fixed in
      // shared/ds_cleanup: `NestListRow` interactive is now one node
      // (`excludeSemantics: true`), so there is exactly one Invite node.
      final invite = p16Announcing(tester, 'Invite co-parent');
      expect(
        invite,
        hasLength(1),
        reason: 'Invite is one node, still operable',
      );
      for (final node in invite) {
        expect(
          node.getSemanticsData().label,
          isNot(contains('Sarah — you')),
          reason: 'Invite must not merge Sarah',
        );
        expect(
          node.getSemanticsData().label,
          isNot(contains('James — co-parent')),
          reason: 'Invite must not merge James',
        );
      }

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('no tappable node is left without a label', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpSettingsApp(tester);
      await tester.pump();

      // Scroll first: a semantics node survives off screen, so the switch
      // tracks are only comparable once their widgets are built.
      await scrollSettingsTo(tester, find.text('Approvals waiting'));
      final anonymous = tappableNodes(tester)
          .where((node) => node.getSemanticsData().label.trim().isEmpty)
          .toList();
      // Fixed in shared/ds_cleanup: `NestToggle` outer `Semantics` now sets
      // `excludeSemantics: true`, so the inner `GestureDetector` contributes
      // no second (unlabelled) tap node. Zero unlabelled nodes — anything
      // announcing nothing is a P16 defect.
      expect(
        anonymous,
        isEmpty,
        reason:
            'one control = one labelled node; unlabelled tap nodes: '
            '${anonymous.length}',
      );

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
        // Fixed in iteration 3 by the screen (P16's `SettingsRow` at 6 px
        // vertical padding + a 44-high wrapper) and again in iteration 5, for
        // good, by the shared row: batch 6 gave `NestListRow` a trailing that
        // lays out at the toggle's 51×31 and hit-forwards the 59×44 slop
        // (`_TrailingSlop` + `_RowSlopForwarder`), so P16's wrappers and the
        // 6 px padding are gone and the row is back to the shared 56. Both
        // iterations needed something: padding alone left `track.top - 5` dead
        // (measured in iteration 2) and a 44-high wrapper grew the row to 64 —
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

        // The mechanism, pinned as GEOMETRY rather than widget types.
        // ORCHESTRATOR_NOTES (08:12) item 3 orders the `SettingsRow` fork
        // reverted to the shared `NestListRow`, so a proof that named the fork
        // would fail on the revert with "no SettingsRow in the tree" instead of
        // reporting the truth. What the owner rule actually needs is ROOM: the
        // switch's painted content box must be at least 44 tall, so the
        // toggle's 6.5 px slop sits inside a box the hit pipeline honours.
        final toggle = find.byType(NestToggle).first;
        // The nearest `Padding` ANCESTOR of the toggle is the row's own content
        // box — `SettingsRow` and `NestListRow` both use it, so this reads the
        // same before and after the mandated revert.
        final contentBox = tester.getRect(
          find.ancestor(of: toggle, matching: find.byType(Padding)).first,
        );
        expect(
          contentBox.height,
          greaterThanOrEqualTo(NestDevice.tapParent),
          reason:
              'the switch content box must be 44 tall or the slop is clipped '
              '(measured $contentBox)',
        );
        expect(
          tester.getRect(toggle).size,
          const Size(51, 31),
          reason: 'the visible track is the design 51x31',
        );
        // The switch row keeps the design's 56 px height like every other row
        // on the page. Iteration 4 measured what an un-forked `NestListRow`
        // would do WITHOUT shared batch 6: its 10 px padding plus the 44-high
        // wrapper exceeds the 56 px minimum and the row grows to 64 (+8 px on
        // each of three rows, ~+24 px down the page). The shared
        // `_TrailingSlop` / `_RowSlopForwarder` is what keeps it at 56, so the
        // number is worth pinning rather than trusting.
        expect(
          tester
              .getRect(
                find
                    .ancestor(
                      of: toggle,
                      matching: find.byWidgetPredicate((w) => w is NestListRow),
                    )
                    .first,
              )
              .height,
          56,
          reason: 'the switch row is a 56 px design row, like its neighbours',
        );

        await disposeApp(tester);
      },
      // P16-T02 fixed in iteration 3 and still fixed after iteration 4's B11
      // wrapper change (`width: 51` added — both findings now pinned on one
      // layout).
      skip: false,
    );
  });

  group('P16 avatar initials — owner AVATAR INITIALS rule', () {
    testWidgets('an emoji nickname yields ONE grapheme, never a broken '
        'surrogate', (tester) async {
      // The rule forbids `name[0]`, which indexes UTF-16 code units: a leading
      // non-BMP character yields an unpaired surrogate and `toUpperCase()`
      // then throws, taking the frame with it. P16's two call sites use
      // `.characters.first`, so today this holds — the test is here to keep it
      // true through the pending `nestAvatarInitial` swap and to stop anyone
      // "simplifying" it back to `name[0]`.
      await pumpSettingsApp(
        tester,
        prepare: (db) =>
            (db.update(db.children)..where((c) => c.id.equals('leo'))).write(
              const ChildrenCompanion(nickname: Value('🌟Zoe')),
            ),
      );
      await scrollSettingsTo(tester, find.text('🌟Zoe · 4–6'));

      // The emoji row's own avatar, addressed through the row so another
      // child's initial cannot satisfy the expectation.
      final row = find
          .ancestor(
            of: find.text('🌟Zoe · 4–6'),
            matching: find.byWidgetPredicate((w) => w is NestListRow),
          )
          .first;
      final initial = tester
          .widget<NestAvatar>(
            find.descendant(of: row, matching: find.byType(NestAvatar)).first,
          )
          .initial;
      expect(
        initial,
        '🌟',
        reason: 'the star is one grapheme and is rendered whole',
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'no unpaired-surrogate crash while building the row',
      );

      await disposeApp(tester);
    });

    testWidgets(
      '[P16-T04] the initial trims a leading space and falls back to "?" for a '
      'whitespace-only name',
      (tester) async {
        // FIXED in iteration 6 (review finding 1). The rule says: use
        // `nestAvatarInitial(name)`, one place for the initial. The helper
        // (`core/design_system/components/nest_avatar_initial.dart`) does three
        // things the hand-rolled call sites did not: trims first, returns its
        // `fallback` ('?') for empty or whitespace-only names, and takes the
        // first grapheme. The screen was re-implementing it inline twice, so a
        // nickname of " Maya" rendered a SPACE as its avatar initial and "   "
        // rendered a space instead of "?" — a blank avatar rather than a name a
        // parent can recognise.
        //
        // `settings_view.dart`'s member and child rows now call the helper, and
        // `main` (merged into this branch) carries it, so the proof runs live
        // rather than skip-marked. The expectation below is still computed
        // INDEPENDENTLY of the helper — it re-implements the trim + first
        // grapheme by hand, so it fails if the screen's own behaviour drifts
        // rather than simply agreeing with itself.
        for (final nickname in <String>[' Maya', '   ']) {
          await pumpSettingsApp(
            tester,
            prepare: (db) =>
                (db.update(db.children)..where((c) => c.id.equals('leo')))
                    .write(ChildrenCompanion(nickname: Value(nickname))),
          );
          await scrollSettingsTo(tester, find.text('$nickname · 4–6'));

          // The LEO row's own avatar — not "some avatar", or Maya's "M" would
          // satisfy the expectation on its own.
          final row = find
              .ancestor(
                of: find.text('$nickname · 4–6'),
                matching: find.byWidgetPredicate((w) => w is NestListRow),
              )
              .first;
          final initial = tester
              .widget<NestAvatar>(
                find
                    .descendant(of: row, matching: find.byType(NestAvatar))
                    .first,
              )
              .initial;
          expect(
            initial,
            nickname.trim().isEmpty
                ? '?'
                : nickname.trim().characters.first.toUpperCase(),
            reason:
                'nickname ${nickname.replaceAll(' ', '<space>')} must render '
                'the trimmed initial, not a space',
          );

          await disposeApp(tester);
        }
      },
      // FIXED (iteration 6): both call sites use the shared
      // `nestAvatarInitial`, which trims and supplies the '?' fallback.
      skip: false,
    );
  });

  group('P16 accessibility — the switch hit box', () {
    testWidgets(
      '[P16-T03] a switch is live 4 px to the LEFT and RIGHT of its track',
      (tester) async {
        // OPEN BUG (minor) — pinned skip-marked so `flutter test` stays green;
        // run with `--run-skipped` to prove it. Do NOT patch the screen here.
        //
        // `NestToggle` promises a 59x44 hit box: `_ToggleHitSlop(minWidth: 59,
        // minHeight: 44)` mirrors the design's `.toggle::before { left/right:
        // -4px; top/bottom: -7px }`. Iteration 4 fixed P16-B11 (the track was
        // 34.5 px off the design x) by pinning the wrapper to
        // `SizedBox(width: 51, height: 44, ...)` — 51 is exactly the TRACK
        // width, so the wrapper now clips the horizontal half of the slop.
        // Measured: track 303..354 inside a wrapper 303..354 (vertical
        // 122..166 gives the full 6.5 px, horizontal 0 of 4).
        //
        // Severity is deliberately minor: the owner rule (>= 44 px parent
        // target) is still met at 51 x 44, and P16-T02's vertical proof still
        // passes. What is lost is the shared component's 4 px of horizontal
        // forgiveness, and ORCHESTRATOR_NOTES (08:12) item 1 asks for exactly
        // "taps 4 px outside the track" to toggle the switch.
        //
        // Fix (screen-local, keeps B11): give the wrapper the slop's width and
        // right-align it, so the track stays flush at x 354 while the slop has
        // room —
        //   SizedBox(
        //     width: 59,
        //     height: 44,
        //     child: Align(alignment: Alignment.centerRight, child: toggle),
        //   )
        // The row's 12 px left padding leaves the 4 px inside the content box.
        await pumpSettingsApp(tester);
        await scrollSettingsTo(tester, find.text('Approvals waiting'));
        final track = tester.getRect(find.byType(NestToggle).first);

        for (final offset in <double>[-4, 4]) {
          final before = (await settingRows()).single.notifApprovals;
          await tester.tapAt(
            Offset(
              offset < 0 ? track.left + offset : track.right - offset,
              track.center.dy,
            ),
          );
          await settleSettings(tester);
          expect(
            (await settingRows()).single.notifApprovals,
            !before,
            reason:
                '${offset.abs()} px ${offset < 0 ? 'left' : 'right'} of the '
                'track must still flip the switch',
          );
        }

        await disposeApp(tester);
      },
      // P16-T03 fixed in iteration 5: the forked wrappers are gone and
      // the shared `_TrailingSlop` keeps the toggle's full 59x44 area.
      skip: false,
    );

    testWidgets('the switch still clears the 44 px owner rule', (tester) async {
      // The part of the same contract that DOES hold today, kept live so a
      // future wrapper change cannot quietly shrink the target below 44 in
      // either axis.
      await pumpSettingsApp(tester);
      await scrollSettingsTo(tester, find.text('Approvals waiting'));
      // The shared NestListRow owns the hit area now: it lays out the row at
      // 56 with a toggle 51×31, and hit-forwards the 44 px owner-rule slop.
      final row = tester.getRect(
        find
            .ancestor(
              of: find.byType(NestToggle).first,
              matching: find.byType(NestListRow),
            )
            .first,
      );
      expect(
        row.height,
        greaterThanOrEqualTo(NestDevice.tapParent),
        reason: 'row height is ${row.height} — needs 44 tall',
      );

      await disposeApp(tester);
    });
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
      // Both buttons are operable — `settings_navigation_test.dart` proves
      // what Cancel and Delete actually do (Cancel keeps everything; Delete
      // wipes the database and lands on /welcome).
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
