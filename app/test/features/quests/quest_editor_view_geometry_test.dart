// P09 · Quest editor — real-font design geometry.
//
// Every number below is measured off `design/screens/light/P09-quest-editor.png`
// (1170x2532, divided by 3) and cross-checked against the CSS in
// `design/html-source/screens/P09-quest-editor.html`. The tolerance is the
// owner's ±2 px UI-verdict rule; sizes that come from a fixed box (a 44 px
// tile, a 52-high field) are asserted outright so a collapsed pill or a
// border leaking outside its box fails here first.
//
// The faces are the bundled Inter/Nunito builds through `FontLoader`, the
// same trick `p10_bugs_test.dart` uses: without them the widget-test font
// gives every glyph the same advance, the assignee pills wrap to a second
// row and every text-bearing rect below them drifts ~56 px.
//
//   element            design x/y/w/h        app (light, this tree)
//   sheet              0 / 47 / 390 / 797     0 / 47 / 390 / 797
//   .sheet::before     175 / 59 / 40 / 5      175 / 59 / 40 / 5
//   .cancel (ink)      27 -> 78.7             26 -> 79.7 text box
//   .sheet-top .t      146.3 -> 236.3         145 -> 236.4 text box
//   .save              296 / 80 / 74 / 44     295.7 / 80 / 74.3 / 44
//   .field label       20 / 132               20 / 132
//   .field input       20 / 156 / 350 / 52    20 / 156 / 350 / 52
//   .lbl Icon          20 / 208               20 / 208
//   .ic x6             20 + i*61.2 / 232      20 + i*61.2 / 232
//   .lbl Who's it for? 20 / 276               20 / 276
//   .person x3         20 / 128 / 222, 300    20 / 128.5 / 224, 300
//   .card.inset        20 / 364 / 350 / 76    20 / 364 / 350 / 76
//   .stepper           178 / 380 / 176 / 44   178 / 380 / 176 / 44
//   .lbl Repeats       20 / 456               20 / 456
//   .segmented         20 / 480 / 350 / 52    20 / 480 / 350 / 52
//   .day x7            20 + i*51 / 540        20 + i*50.86 / 540
//   .card (approval)   20 / 600 / 350 / 72    20 / 600 / 350 / 72
//   .toggle track      303 / 620.5 / 51 / 31  303 / 620.5 / 51 / 31
//   .card (due)        20 / 684 / 350 / 88    20 / 684 / 350 / 88
//   bottom edge        paper at y=843         paper at y=843
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/presentation/views/quest_editor_view.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_editor_widgets.dart';
import 'package:nestling/features/quests/quests_routes.dart';

import '../../test_scope.dart';

/// Owner rule: an element is within ±2 px of the design or it is a failure.
const double _tolerance = 2;

Future<void> _loadBundledFonts() async {
  final inter = FontLoader('Inter')
    ..addFont(rootBundle.load('assets/fonts/Inter-Regular.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Medium.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Inter-Bold.ttf'));
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-Bold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'))
    ..addFont(rootBundle.load('assets/fonts/Nunito-Black.ttf'));
  await inter.load();
  await nunito.load();
}

Finder _tile(String key) => find.byKey(ValueKey<String>('quest-icon-$key'));

Finder _pill(String id) => find.byKey(ValueKey<String>('quest-assignee-$id'));

/// Asserts every edge of the found rect against the design rect [design].
void _expectRect(
  WidgetTester tester,
  String label,
  Finder finder,
  Rect design, {
  double tolerance = _tolerance,
}) {
  final actual = tester.getRect(finder);
  expect(actual.left, closeTo(design.left, tolerance), reason: '$label left');
  expect(actual.top, closeTo(design.top, tolerance), reason: '$label top');
  expect(
    actual.width,
    closeTo(design.width, tolerance),
    reason: '$label width',
  );
  expect(
    actual.height,
    closeTo(design.height, tolerance),
    reason: '$label height',
  );
}

void _expectCentreX(
  WidgetTester tester,
  String label,
  Finder finder,
  double designCentre, {
  double tolerance = _tolerance,
}) {
  final actual = tester.getRect(finder);
  expect(
    actual.center.dx,
    closeTo(designCentre, tolerance),
    reason: '$label centre x (design $designCentre, app ${actual.center.dx})',
  );
}

void main() {
  setUpAll(_loadBundledFonts);
  setUp(setUpTestScope);

  group('P09 quest editor — design rects measured off the PNG (light)', () {
    testWidgets('sheet, grabber and header sit on the design y', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      // The sheet starts straight under the 47 px status bar and its paper
      // fills the whole column.
      _expectRect(
        tester,
        'sheet',
        find.byKey(const ValueKey<String>('quest-editor-sheet')),
        const Rect.fromLTWH(0, 47, 390, 797),
      );

      // `.sheet::before` — 40x5 grabber, 4 px below the sheet's top edge
      // (the 8 px sheet padding) and 12 px above the header row.
      _expectRect(
        tester,
        'grabber',
        find.byKey(const ValueKey<String>('quest-editor-grabber')),
        const Rect.fromLTWH(175, 59, 40, 5),
      );

      // Header row 80 -> 124. `.save` is flush to the 370 gutter; the title is
      // centred in the space the two side buttons leave free (ink 146.3 ->
      // 236.3 on the PNG, which is the 145 -> 236.4 text box plus the ~1.3 px
      // side bearing); `.cancel` ink starts at 27 (a bare `<button>`, so its
      // glyphs sit 6 px inside the sheet gutter).
      _expectRect(
        tester,
        'save pill',
        find.byType(QuestSavePill),
        const Rect.fromLTWH(296, 80, 74, 44),
      );
      final cancel = tester.getRect(find.text('Cancel'));
      expect(cancel.left, closeTo(26, _tolerance), reason: 'cancel left');
      expect(cancel.top, 90);
      expect(cancel.height, 24);
      final title = tester.getRect(find.text('New quest'));
      expect(title.left, closeTo(145, _tolerance), reason: 'title left');
      expect(title.top, 90);
      expect(title.width, closeTo(91.3, _tolerance), reason: 'title width');
      expect(title.height, 24);
      await disposeApp(tester);
    });

    testWidgets('field, icon row and assignee pills are on the design rects', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      // `.field` — 13/18 label at 132, then the 52-high input at 156.
      _expectRect(
        tester,
        'field label',
        find.text('Quest name'),
        const Rect.fromLTWH(20, 132, 75.5, 18),
      );
      _expectRect(
        tester,
        'field input',
        find.byType(TextField),
        const Rect.fromLTWH(20, 156, 350, 52),
      );

      // `.lbl` "Icon" is stacked flush under the field (the design has no
      // margin between the two blocks), then the six 44 px tiles.
      _expectRect(
        tester,
        'icon label',
        find.text('Icon'),
        const Rect.fromLTWH(20, 208, 350, 18),
      );
      // `.icons` is `grid-template-columns: repeat(6, 44px)` with
      // `justify-content: space-between`, so the free 46 px splits into five
      // 17.2 px gaps.
      const tiles = <String>[
        'bed',
        'dishwasher',
        'hoover',
        'book',
        'bin',
        'paw',
      ];
      // `.icons role="radiogroup" aria-label="Quest icon"` — the six tiles
      // live under one announced group node.
      final group = find.bySemanticsLabel('Quest icon');
      expect(group, findsOneWidget);
      for (final name in tiles) {
        expect(
          find.descendant(of: group, matching: _tile(name)),
          findsOneWidget,
          reason: 'tile $name is inside the Quest icon group',
        );
      }
      for (var i = 0; i < tiles.length; i++) {
        _expectRect(
          tester,
          'icon tile ${tiles[i]}',
          _tile(tiles[i]),
          Rect.fromLTWH(20 + i * (44 + (350 - 6 * 44) / 5), 232, 44, 44),
        );
      }

      // `.lbl` "Who's it for?" then three 48-tall pills on one row with 8 px
      // gaps, starting on the 20 px gutter.
      _expectRect(
        tester,
        "who's it for label",
        find.text("Who's it for?"),
        const Rect.fromLTWH(20, 276, 350, 18),
      );
      const pillWidths = <String, double>{'maya': 100, 'leo': 86, 'anyone': 76};
      var expectedLeft = 20.0;
      for (final entry in pillWidths.entries) {
        _expectRect(
          tester,
          'pill ${entry.key}',
          _pill(entry.key),
          Rect.fromLTWH(expectedLeft, 300, entry.value, 48),
        );
        expectedLeft += entry.value + NestSpacing.s2;
      }
      await disposeApp(tester);
    });

    testWidgets('reward, repeats, approval and due blocks are on the rects', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      // `.card.inset` reward row: 44 (stepper) + 2x16 padding.
      _expectRect(
        tester,
        'reward card',
        find.byType(NestCard).at(0),
        const Rect.fromLTWH(20, 364, 350, 76),
      );
      _expectRect(
        tester,
        'reward title',
        find.text('Reward'),
        const Rect.fromLTWH(36, 382, 58, 22),
      );
      _expectRect(
        tester,
        'reward helper',
        find.text('= 15p at payout'),
        const Rect.fromLTWH(36, 404, 94, 18),
      );
      _expectRect(
        tester,
        'stepper',
        find.byType(NestStepper),
        const Rect.fromLTWH(178, 380, 176, 44),
      );

      // `.lbl` Repeats, then the 52-high segmented track (4 px padding around
      // the 44 px segment) and the 44-high day cells 8 px below it.
      _expectRect(
        tester,
        'repeats label',
        find.text('Repeats'),
        const Rect.fromLTWH(20, 456, 350, 18),
      );
      _expectRect(
        tester,
        'segmented',
        find.byType(NestSegmented<String>),
        const Rect.fromLTWH(20, 480, 350, 52),
      );
      // The three tabs share the track's inner 342 px in three 111.33 px
      // segments with 4 px gaps; the design centres Once / Daily / Weekly at
      // 79.7 / 195 / 310.3.
      _expectCentreX(tester, 'Once', find.text('Once'), 79.7);
      _expectCentreX(tester, 'Daily', find.text('Daily'), 195);
      _expectCentreX(tester, 'Weekly', find.text('Weekly'), 310.3);
      _expectRect(
        tester,
        'day row',
        find.byType(NestDayPicker),
        const Rect.fromLTWH(20, 540, 350, 44),
      );
      // `.dayrow` is `justify-content: space-between` (7 px effective gaps,
      // 44 px cells); `NestDayPicker` shares the width over `Expanded` cells
      // with 6 px gaps, so the cells are 44.86 wide and the last one still
      // lands on 370 — inside the ±2 px rule everywhere.
      for (var i = 0; i < 7; i++) {
        _expectRect(
          tester,
          'day $i',
          find.byKey(ValueKey<int>(i)),
          Rect.fromLTWH(20 + i * 51, 540, 44, 44),
        );
      }

      // `.card` approval: 16 + 16/22 + 13/18 + 16 = 72, with the 51x31 track
      // flush to the card's content edge (x 303 -> 354) and centred on the
      // card's 636 midpoint.
      _expectRect(
        tester,
        'approval card',
        find.byType(NestCard).at(1),
        const Rect.fromLTWH(20, 600, 350, 72),
      );
      _expectRect(
        tester,
        'approval title',
        find.text('Needs my approval'),
        const Rect.fromLTWH(36, 618, 148.7, 22),
      );
      _expectRect(
        tester,
        'approval sub',
        find.text('Coins land after your thumbs-up'),
        const Rect.fromLTWH(36, 640, 198.9, 18),
      );
      final toggleBox = tester.getRect(find.byType(NestToggle));
      expect(toggleBox.width, 59, reason: 'toggle hit box is 51 + 8');
      expect(toggleBox.height, NestDevice.tapParent);
      // `.toggle::before` overhangs the 51 px track by 4 px on each side, so
      // the hit box ends 4 px past the card's content edge (358) and
      // `NestToggle`'s track — centred inside that box and shifted back by
      // `toggleTrackOffset` — lands on the design's x 303 -> 354,
      // y 620.5 -> 651.5.
      expect(
        toggleBox.right,
        358,
        reason: 'hit box 4 px past the content edge',
      );
      expect(toggleBox.top, 614, reason: 'hit box 2 px above the design track');
      final track = Rect.fromLTWH(
        toggleBox.left + 4,
        toggleBox.top + 6.5,
        51,
        31,
      );
      expect(track.left, closeTo(303, _tolerance), reason: 'toggle track left');
      expect(
        track.right,
        closeTo(354, _tolerance),
        reason: 'toggle track right',
      );
      expect(track.top, closeTo(620.5, _tolerance), reason: 'toggle track top');
      expect(
        track.bottom,
        closeTo(651.5, _tolerance),
        reason: 'toggle track bottom',
      );

      // `.card` due by, 12 px below the approval card: 56 (`.due` min-height)
      // + 2x16 padding.
      _expectRect(
        tester,
        'due card',
        find.byType(NestCard).at(2),
        const Rect.fromLTWH(20, 684, 350, 88),
      );
      final dueLabel = tester.getRect(find.text('Due by'));
      expect(dueLabel.left, closeTo(36, _tolerance), reason: 'due label left');
      expect(dueLabel.center.dy, closeTo(728, _tolerance), reason: 'due row');
      final dueValue = tester.getRect(find.text('Before tea (5pm) ›'));
      expect(
        dueValue.right,
        closeTo(354, _tolerance),
        reason: 'due value flush to the content edge (PNG ink ends 353)',
      );
      await disposeApp(tester);
    });

    // Owner rule: the area below the last block down to the physical screen
    // edge is the sheet's own paper — never a `--surface-2` strip, never a
    // coloured band around the home indicator, in either theme.
    testWidgets('paper, not surface-2, covers the bottom edge', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      final sheet = tester.getRect(
        find.byKey(const ValueKey<String>('quest-editor-sheet')),
      );
      expect(sheet.bottom, NestDevice.height);
      final container = tester.widget<Container>(
        find.byKey(const ValueKey<String>('quest-editor-sheet')),
      );
      final decoration = container.decoration! as BoxDecoration;
      final tokens = tester.element(find.byType(QuestEditorView)).nest;
      expect(decoration.color, tokens.paper);
      // The backdrop behind the sheet is `--surface-2` and is only ever
      // visible above the sheet's rounded top corners.
      final backdrop = tester.getRect(find.byType(ColoredBox).first);
      expect(backdrop.top, NestDevice.statusH);
      await disposeApp(tester);
    });

    testWidgets('dark mode keeps every rect', (tester) async {
      await pumpAppRoute(
        tester,
        QuestsRoutePaths.editor,
        theme: ThemeMode.dark,
      );
      _expectRect(
        tester,
        'sheet',
        find.byKey(const ValueKey<String>('quest-editor-sheet')),
        const Rect.fromLTWH(0, 47, 390, 797),
      );
      _expectRect(
        tester,
        'save pill',
        find.byType(QuestSavePill),
        const Rect.fromLTWH(296, 80, 74, 44),
      );
      _expectRect(
        tester,
        'field input',
        find.byType(TextField),
        const Rect.fromLTWH(20, 156, 350, 52),
      );
      var pillLeft = 20.0;
      for (final entry in const <String, double>{
        'maya': 100,
        'leo': 86,
        'anyone': 76,
      }.entries) {
        _expectRect(
          tester,
          'pill ${entry.key}',
          _pill(entry.key),
          Rect.fromLTWH(pillLeft, 300, entry.value, 48),
        );
        pillLeft += entry.value + NestSpacing.s2;
      }
      _expectRect(
        tester,
        'reward card',
        find.byType(NestCard).at(0),
        const Rect.fromLTWH(20, 364, 350, 76),
      );
      _expectRect(
        tester,
        'approval card',
        find.byType(NestCard).at(1),
        const Rect.fromLTWH(20, 600, 350, 72),
      );
      _expectRect(
        tester,
        'due card',
        find.byType(NestCard).at(2),
        const Rect.fromLTWH(20, 684, 350, 88),
      );
      final sheet = tester.getRect(
        find.byKey(const ValueKey<String>('quest-editor-sheet')),
      );
      expect(sheet.bottom, NestDevice.height);
      await disposeApp(tester);
    });
  });
}
