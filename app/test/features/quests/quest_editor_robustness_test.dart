// P09 · Quest editor — widths, text scaling, tap targets and edge taps.
//
// The design is a single 390x844 frame, but the screen has to hold together on
// the narrowest phone the app supports (320) and the widest (430), in both
// themes, and at the app's maximum text scale (1.3 — `NestlingApp` clamps
// 1.0..1.3, SPACING_SPEC §10). Nothing here asserts a pixel the design does
// not fix: the invariants are the owner's two layout rules.
//
//   ALIGNMENT — every row spans the same 20 -> width-20 column, and nothing
//               may overflow its surface.
//   BOTTOM    — the paper sheet runs to the physical bottom edge in every
//               width and theme (owner BOTTOM EDGE rule).
//   TAPS      — every interactive control keeps at least the 44 px parent-mode
//               minimum (SPACING_SPEC tap targets) and the whole box responds:
//               taps 5 px inside each vertical edge flip the real state.
//
// 320-wide day cells are narrower than 44 by construction — the plan (§5) says
// `NestDayPicker` uses `Expanded` cells there, because 7x44 + 6x6 gaps do not
// fit in 280 px. So the width assertion starts at 390 (the design's frame) and
// only the height is asserted at 320.

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_editor_widgets.dart';
import 'package:nestling/features/quests/quests_routes.dart';

import '../../test_scope.dart';

/// The parent-mode tap minimum (`--tap`). P09 is a parent screen, so the
/// kid-mode 56 px does not apply to any control on it.
const double _minTap = NestDevice.tapParent;

const List<String> _iconKeys = <String>[
  'bed',
  'dishwasher',
  'hoover',
  'book',
  'bin',
  'paw',
];

/// Every element that starts on the sheet's left gutter.
List<(String, Finder)> _leftGutterRows() => <(String, Finder)>[
  ('name input', find.byType(TextField)),
  ('icon tile 1', find.byKey(const ValueKey<String>('quest-icon-bed'))),
  ('person pill 1', find.byKey(const ValueKey<String>('quest-assignee-maya'))),
  ('reward card', find.byType(NestCard).at(0)),
  ('segmented', find.byType(NestSegmented<String>)),
  ('day row', find.byType(NestDayPicker)),
  ('approval card', find.byType(NestCard).at(1)),
  ('due card', find.byType(NestCard).at(2)),
];

/// Every element that fills the whole column, gutter to gutter.
List<(String, Finder)> _fullWidthRows() => <(String, Finder)>[
  ('name input', find.byType(TextField)),
  ('reward card', find.byType(NestCard).at(0)),
  ('segmented', find.byType(NestSegmented<String>)),
  ('day row', find.byType(NestDayPicker)),
  ('approval card', find.byType(NestCard).at(1)),
  ('due card', find.byType(NestCard).at(2)),
];

/// Resizes the surface and settles a frame.
Future<void> _resize(
  WidgetTester tester,
  double width, [
  double scale = 1,
]) async {
  tester.view.physicalSize = Size(width * 3, NestDevice.height * 3);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  group('P09 robustness — surface widths', () {
    setUp(setUpTestScope);

    for (final width in <double>[320, 390, 430]) {
      for (final theme in <(String, ThemeMode)>[
        ('light', ThemeMode.light),
        ('dark', ThemeMode.dark),
      ]) {
        testWidgets('$width wide, ${theme.$1}: no overflow, one column', (
          tester,
        ) async {
          await pumpAppRoute(tester, QuestsRoutePaths.editor, theme: theme.$2);
          await _resize(tester, width);

          expect(tester.takeException(), isNull);
          expect(find.text('New quest'), findsOneWidget);
          expect(find.text('Maya'), findsOneWidget);
          expect(find.text('Leo'), findsOneWidget);

          // ALIGNMENT: one column, 20 px on both sides, on every row.
          final right = width - NestSpacing.padSide;
          for (final (name, finder) in _leftGutterRows()) {
            expect(
              tester.getRect(finder).left,
              NestSpacing.padSide,
              reason: '$name left @$width',
            );
          }
          for (final (name, finder) in _fullWidthRows()) {
            final rect = tester.getRect(finder);
            expect(
              rect.left,
              NestSpacing.padSide,
              reason: '$name left @$width',
            );
            expect(rect.right, right, reason: '$name right @$width');
          }
          // The icon row is `space-between`: first tile on the gutter, last
          // tile flush to the other one — as long as the six still fit on one
          // row (at 320 they wrap, and the row test below covers that).
          final firstTile = tester.getRect(
            find.byKey(const ValueKey<String>('quest-icon-bed')),
          );
          final lastTile = tester.getRect(
            find.byKey(const ValueKey<String>('quest-icon-paw')),
          );
          if (firstTile.top == lastTile.top) {
            expect(lastTile.right, right);
          }

          // The header sits on the same two edges (its own padding is inside
          // the column): Cancel's box on the gutter, Save flush right.
          expect(
            tester.getRect(find.byType(QuestCancelButton)).left,
            NestSpacing.padSide,
          );
          expect(tester.getRect(find.byType(QuestSavePill)).right, right);
          expect(tester.getRect(find.byType(QuestSavePill)).height, _minTap);

          // The sheet is full-bleed and covers the last pixel of the screen.
          final sheet = tester.getRect(
            find.byKey(const ValueKey<String>('quest-editor-sheet')),
          );
          expect(sheet.left, 0);
          expect(sheet.width, width);
          expect(
            tester.getRect(find.byType(SingleChildScrollView)).bottom,
            NestDevice.height,
          );
          expect(sheet.bottom, greaterThanOrEqualTo(NestDevice.height));

          await disposeApp(tester);
        });
      }
    }

    testWidgets('a 320-wide surface wraps the icon tiles instead of clipping', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await _resize(tester, 320);

      // 6x44 + 5x8 = 304 does not fit in 280, so the row wraps to two lines —
      // design order preserved, every tile still a full 44.
      final rows = <double>{};
      for (final key in _iconKeys) {
        final tile = tester.getRect(
          find.byKey(ValueKey<String>('quest-icon-$key')),
        );
        expect(tile.width, 44, reason: '$key width');
        expect(tile.height, 44, reason: '$key height');
        expect(tile.left, greaterThanOrEqualTo(NestSpacing.padSide));
        expect(tile.right, lessThanOrEqualTo(320 - NestSpacing.padSide));
        rows.add(tile.top);
      }
      expect(rows, hasLength(2), reason: 'the six tiles wrap onto two rows');
      await disposeApp(tester);
    });
  });

  group('P09 robustness — text scale', () {
    setUp(setUpTestScope);

    for (final scale in <double>[1, 1.3]) {
      for (final theme in <(String, ThemeMode)>[
        ('light', ThemeMode.light),
        ('dark', ThemeMode.dark),
      ]) {
        testWidgets('scale $scale, ${theme.$1}: nothing overflows or clips', (
          tester,
        ) async {
          await pumpAppRoute(tester, QuestsRoutePaths.editor, theme: theme.$2);
          await _resize(tester, 390, scale);

          expect(tester.takeException(), isNull);
          // The copy survives at the top of its scale (an ellipsis is allowed
          // on the single-line rows; clipping is not).
          expect(find.text('New quest'), findsOneWidget);
          expect(find.text('Quest name'), findsOneWidget);
          expect(find.text("Who's it for?"), findsOneWidget);
          expect(find.text('Needs my approval'), findsOneWidget);
          expect(find.text('Coins land after your thumbs-up'), findsOneWidget);
          expect(find.text('Before tea (5pm) ›'), findsOneWidget);
          // The reward helper stays on one line.
          final helper = tester.getRect(find.text('= 15p at payout'));
          expect(helper.height, lessThanOrEqualTo(24));
          await disposeApp(tester);
        });
      }
    }

    testWidgets('scale 1.3 on a 320-wide surface still holds', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await _resize(tester, 320, 1.3);
      expect(tester.takeException(), isNull);
      expect(find.text('New quest'), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('a long quest title keeps the field on one line', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.enterText(
        find.byType(TextField).first,
        'Hoover, wipe and reorganise the entire stairwell, twice over',
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<QuestSavePill>(find.byType(QuestSavePill)).onPressed,
        isNotNull,
      );
      expect(tester.getRect(find.byType(TextField)).height, 52);
      await disposeApp(tester);
    });
  });

  group('P09 robustness — approval toggle placement', () {
    setUp(setUpTestScope);

    // BUG-P09-10's fix made the switch a `Positioned(top: 20.5, right: s4)`
    // sibling of the padded row, so its 59x44 tap area escapes the row's
    // bounds. 20.5 is the design frame's *centred* offset (16 padding + the
    // (40 - 31) / 2 the 40-high text block leaves), so these invariants must
    // hold on every surface the app supports, not only the design's.
    for (final (width, scale) in const <(double, double)>[
      (320, 1),
      (390, 1),
      (430, 1),
      (390, 1.3),
      (320, 1.3),
    ]) {
      testWidgets(
        '$width wide at scale $scale: inside the card, never over text',
        (tester) async {
          await pumpAppRoute(tester, QuestsRoutePaths.editor);
          await _resize(tester, width, scale);
          expect(tester.takeException(), isNull);

          final card = tester.getRect(find.byType(NestCard).at(1));
          final track = tester.getRect(find.byType(NestToggle));
          final title = tester.getRect(find.text('Needs my approval'));
          final sub = tester.getRect(
            find.text('Coins land after your thumbs-up'),
          );

          // Inside the card's 16 px content box on both sides (ALIGNMENT).
          expect(
            track.left,
            greaterThanOrEqualTo(card.left + NestSpacing.s4 - 0.01),
            reason: 'the track must not leave the left gutter @$width/$scale',
          );
          expect(
            track.right,
            closeTo(card.right - NestSpacing.s4, 0.01),
            reason: 'flush to the content edge, like the design @$width/$scale',
          );
          expect(track.top, greaterThanOrEqualTo(card.top));

          // Never over the text: the switch is the card's right column.
          expect(
            track.overlaps(sub),
            isFalse,
            reason: 'the track must not cover the sub-line @$width/$scale',
          );
          expect(
            title.right,
            lessThanOrEqualTo(track.left + 0.01),
            reason:
                'title and switch share one row without overlapping @$width/$scale',
          );
          await disposeApp(tester);
        },
      );
    }
  });

  group('P09 robustness — tap targets', () {
    setUp(setUpTestScope);

    testWidgets('every control keeps the 44 px parent minimum', (tester) async {
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-hoover');
      await tester.scrollUntilVisible(
        find.text('Delete quest'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      final controls = <String, Finder>{
        'Cancel': find.byType(QuestCancelButton),
        'Save': find.byType(QuestSavePill),
        'stepper −': find.byKey(const ValueKey<String>('decrease')),
        'stepper +': find.byKey(const ValueKey<String>('increase')),
        'due card': find.byType(NestCard).at(2),
        'delete button': find.widgetWithText(NestButton, 'Delete quest'),
        for (final key in _iconKeys)
          'icon $key': find.byKey(ValueKey<String>('quest-icon-$key')),
        for (final id in <String>['maya', 'leo', 'anyone'])
          'person $id': find.byKey(ValueKey<String>('quest-assignee-$id')),
        for (var i = 0; i < 7; i++) 'day $i': find.byKey(ValueKey<int>(i)),
      };

      for (final entry in controls.entries) {
        final rect = tester.getRect(entry.value);
        expect(
          rect.height,
          greaterThanOrEqualTo(_minTap),
          reason: '${entry.key} is ${rect.height} high',
        );
      }

      // Controls the design draws at least 44 wide keep that width too.
      final squareControls = <String, Finder>{
        'Cancel': find.byType(QuestCancelButton),
        'Save': find.byType(QuestSavePill),
        'stepper −': find.byKey(const ValueKey<String>('decrease')),
        'stepper +': find.byKey(const ValueKey<String>('increase')),
        'approval toggle': find.byType(NestToggle),
        for (final key in _iconKeys)
          'icon $key': find.byKey(ValueKey<String>('quest-icon-$key')),
        for (var i = 0; i < 7; i++) 'day $i': find.byKey(ValueKey<int>(i)),
      };
      for (final entry in squareControls.entries) {
        final rect = tester.getRect(entry.value);
        expect(
          rect.width,
          greaterThanOrEqualTo(_minTap),
          reason: '${entry.key} is ${rect.width} wide',
        );
      }

      // The toggle's 44 px tap minimum is NOT its box: `shared_batch5` made
      // the 51x31 track the laid-out box and moved the 59x44 tap area into
      // `_ToggleHitSlop`, exactly as `.toggle::before` does in the CSS. So the
      // track may be 31 high while the tappable area is still 59x44 — the
      // edge taps in the next test prove where it is.
      final track = tester.getRect(find.byType(NestToggle));
      expect(track.width, 51, reason: '.toggle is a 51x31 track');
      expect(track.height, 31);

      // The design's own minimums, pinned outright.
      expect(tester.getRect(find.byType(QuestSavePill)).height, 44);
      expect(
        tester
            .getRect(find.byKey(const ValueKey<String>('quest-icon-bed')))
            .height,
        44,
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey<String>('quest-assignee-maya')))
            .height,
        48,
        reason: '.person is 48 tall in the design',
      );
      expect(
        tester.getRect(find.byType(NestStepper)).height,
        44,
        reason: 'the stepper buttons are the 44 minimum',
      );
      expect(
        tester.getRect(find.byType(NestSegmented<String>)).height,
        52,
        reason: '.segmented is 4 + 44 + 4',
      );
      await disposeApp(tester);
    });

    testWidgets('day cells stay 44 high and 44 wide at the design width', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      for (var i = 0; i < 7; i++) {
        final rect = tester.getRect(find.byKey(ValueKey<int>(i)));
        expect(rect.height, 44, reason: 'day $i height');
        expect(rect.width, greaterThanOrEqualTo(44), reason: 'day $i width');
      }
      await disposeApp(tester);
    });

    testWidgets('the reward stepper clamps to 1..100 and disables the ends', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      final increase = find.byKey(const ValueKey<String>('increase'));
      final decrease = find.byKey(const ValueKey<String>('decrease'));

      for (var i = 0; i < 100; i++) {
        await tester.tap(increase, warnIfMissed: false);
        await tester.pump();
      }
      expect(find.text('100'), findsOneWidget);
      expect(find.text('= 100p at payout'), findsOneWidget);
      // At the ceiling the `+` control reports itself disabled: no tap action
      // and `enabled: false`, while `−` stays live.
      final top = tester.getSemantics(increase);
      expect(top.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      expect(
        top.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );
      expect(
        tester
            .getSemantics(decrease)
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isTrue,
      );

      for (var i = 0; i < 120; i++) {
        await tester.tap(decrease, warnIfMissed: false);
        await tester.pump();
      }
      expect(find.text('1'), findsOneWidget);
      expect(find.text('= 1p at payout'), findsOneWidget);
      final bottom = tester.getSemantics(decrease);
      expect(bottom.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
      expect(
        bottom.getSemanticsData().flagsCollection.isEnabled,
        Tristate.isFalse,
      );

      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('taps 5 px inside each edge still flip the real state', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      Set<int> days() =>
          tester.widget<NestDayPicker>(find.byType(NestDayPicker)).selected;

      bool personSelected(String id) => tester
          .widget<QuestPersonPill>(
            find.byKey(ValueKey<String>('quest-assignee-$id')),
          )
          .selected;

      // Day cells: the full 44 is live, top edge and bottom edge included.
      for (final index in <int>[0, 5]) {
        final rect = tester.getRect(find.byKey(ValueKey<int>(index)));
        for (final dy in <double>[5, rect.height - 5]) {
          final before = days().contains(index);
          await tester.tapAt(Offset(rect.center.dx, rect.top + dy));
          await tester.pump();
          expect(
            days().contains(index),
            isNot(before),
            reason: 'day $index toggles $dy px from its top edge',
          );
        }
      }

      // Person pills: 48 tall and the whole box answers. They are
      // single-select (a tap on the chosen pill is a no-op, not a deselect),
      // so each tap moves the selection to that pill and clears the others.
      for (final (id, dy) in const <(String, double)>[
        ('leo', 5),
        ('anyone', 43),
        ('maya', 5),
        ('leo', 43),
      ]) {
        final rect = tester.getRect(
          find.byKey(ValueKey<String>('quest-assignee-$id')),
        );
        await tester.tapAt(Offset(rect.center.dx, rect.top + dy));
        await tester.pump();
        expect(
          personSelected(id),
          isTrue,
          reason: 'person $id is selected by a tap $dy px inside its box',
        );
        for (final other in <String>['maya', 'leo', 'anyone']) {
          if (other != id) {
            expect(
              personSelected(other),
              isFalse,
              reason: '$other is cleared when $id is chosen',
            );
          }
        }
      }

      // Icon tiles: the same, including the horizontal extremes.
      final tile = tester.getRect(
        find.byKey(const ValueKey<String>('quest-icon-book')),
      );
      await tester.tapAt(Offset(tile.left + 5, tile.center.dy));
      await tester.pump();
      expect(
        tester
            .widget<QuestIconTile>(
              find.byKey(const ValueKey<String>('quest-icon-book')),
            )
            .selected,
        isTrue,
      );

      // Segmented options: 5 px inside the track's own edge is still inside
      // the button (4 px track padding + 44 px button = 52).
      final segmentTrack = tester.getRect(find.byType(NestSegmented<String>));
      for (final (label, value) in const <(String, String)>[
        ('Once', 'once'),
        ('Weekly', 'weekly'),
      ]) {
        final option = tester.getRect(find.text(label));
        for (final dy in <double>[
          segmentTrack.top + 6,
          segmentTrack.bottom - 6,
        ]) {
          await tester.tapAt(Offset(option.center.dx, dy));
          await tester.pump();
          expect(
            tester
                .widget<NestSegmented<String>>(
                  find.byType(NestSegmented<String>),
                )
                .value,
            value,
            reason: '$label is tappable at y=$dy',
          );
        }
      }

      // The toggle's 44-high TAP AREA answers, not just its painted 31-high
      // track: (44 - 31) / 2 = 6.5 px of slop above and below, 4 px either
      // side. Asserted relative to the track, so the screen's pending removal
      // of `QuestEditorMetrics.toggleTrackOffset` cannot move this test.
      final track = tester.getRect(find.byType(NestToggle));
      const slopY = (44 - 31) / 2;
      const slopX = (59 - 51) / 2;
      for (final offset in <(double, double)>[
        (0, -slopY),
        (0, slopY),
        (-slopX, 0),
        (slopX, 0),
        (0, 0),
      ]) {
        final before = tester.widget<NestToggle>(find.byType(NestToggle)).value;
        await tester.tapAt(
          Offset(track.center.dx + offset.$1, track.center.dy + offset.$2),
        );
        await tester.pump();
        expect(
          tester.widget<NestToggle>(find.byType(NestToggle)).value,
          isNot(before),
          reason: 'the toggle flips at slop (${offset.$1}, ${offset.$2})',
        );
      }

      await disposeApp(tester);
    });
  });
}
