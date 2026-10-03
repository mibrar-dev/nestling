// P09 · Quest editor — character-by-character copy audit.
//
// The COPY rule is character-exact: the design's typographic characters,
// compared with `design/html-source/screens/P09-quest-editor.html`. This file
// pins every string the screen owns, its code points, and — by set equality —
// that the screen invents no copy of its own.
//
// Known deviation (found by this file, recorded in `3_test.md` §Bugs as
// P09-BUG-1): the shared `NestStepper` draws its minus as U+002D, while both
// designs that show a stepper print U+2212 (`&minus;` in the HTML). It is a
// shared-component defect, not P09's code, and P06 already carries the same
// finding (P06-BUG-12) with a screen-local `P06WeeklyStepper`. The glyph is
// therefore excluded from [kOwnedCopy] below until the component is fixed;
// every other design string is asserted character for character.

import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/quests_routes.dart';

import '../../test_scope.dart';

/// Every string P09 renders that is NOT in the P09 design, with the plan
/// section that sanctions it (`1_plan.md` §0/§4 and 2b's deviation list).
const Set<String> kScreenLocalCopy = <String>{
  'Edit quest', // §3: the title for `?id=` mode
  'Delete quest', // §1-9 (DESIGN_SPEC: delete is not shown for a new quest)
  'Delete this quest?', // confirm modal — no P09 frame
  'Keep it',
  'Delete',
  'Quest not found', // §4
  'Back to quests', // §4
  'Something went wrong', // §4 (unreachable fallback)
  'Try again', // §4
  'Pick at least one day', // §2 validation caption
  'Before school (8:30am)', // due sheet rows — no P09 frame
  'Before tea (5pm)', // the sheet row carries no chevron
  'Before bed (7:30pm)',
  'Due by', // also the due SHEET's title (§1-8), the card's own label is the
  // design's
};

/// Copy the design fixes, verbatim from the HTML. Anything P09 shows must be
/// in here or in [kScreenLocalCopy] — that set equality is the audit.
const Set<String> kDesignCopy = <String>{
  'Cancel',
  'New quest',
  'Save',
  'Quest name',
  'Hoover the stairs',
  'Icon',
  kWhosItFor, // U+0027 — the HTML prints a straight apostrophe
  'Maya',
  'Leo',
  'Anyone',
  'Reward',
  '= 15p at payout',
  '15',
  'Repeats',
  'Once',
  'Daily',
  'Weekly',
  'Needs my approval',
  'Coins land after your thumbs-up', // U+002D, not an en dash
  'Due by',
  'Before tea (5pm) ›', // U+2039/U+203A single angle quotation mark
};

/// The single-character strings the design draws inside controls: the avatar
/// initials, the seven day letters (M T W T F S S) and the stepper's `+` and
/// `-`. The minus is the P09-BUG-1 deviation from the design's U+2212.
const List<String> kGlyphs = <String>[
  'M', // Maya's avatar initial
  'L', // Leo's avatar initial
  'M',
  'T',
  'W',
  'T',
  'F',
  'S',
  'S', // the design's .dayrow
  '+',
  '-', // .stepper buttons
];

/// Everything P09 is allowed to paint anywhere on the screen: the design's
/// copy, the sanctioned screen-local copy and the glyphs. Set equality against
/// this list is the "no invented copy" audit.
final Set<String> kOwnedCopy = <String>{
  ...kDesignCopy,
  ...kScreenLocalCopy,
  ...kGlyphs,
};

/// The design's group label: a STRAIGHT apostrophe (U+0027), which the HTML
/// prints literally. Spelled with an escape so the copy audit cannot be broken
/// by an editor's smart quotes.
const String kWhosItFor = "Who's it for?";

/// The design's `.ic` aria-labels, in design order, as the app announces them
/// (`QuestIconTile` prefixes the radiogroup name).
const List<String> _iconLabels = <String>[
  'Icon: Bed',
  'Icon: Dishes',
  'Icon: Hoover',
  'Icon: Book',
  'Icon: Bins',
  'Icon: Paw',
];

/// The design's stepper aria-labels.
const List<String> _stepperLabels = <String>[
  'Decrease reward',
  'Increase reward',
];

/// The name field's value. `EditableText` paints its own text (no `Text`
/// widget), so the design's `value="Hoover the stairs"` is read from the
/// controller instead of the visible-copy list.
String _fieldValue(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

/// Every visible `Text` in the tree, in document order.
List<String> _visibleText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((text) => text.data ?? text.textSpan?.toPlainText() ?? '')
    .where((data) => data.isNotEmpty)
    .toList();

void main() {
  setUp(setUpTestScope);

  group('P09 copy — the design frame', () {
    testWidgets('every design string is on screen, character for character', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      final shown = _visibleText(tester).toSet();
      for (final string in <String>{...kDesignCopy, ...kGlyphs}) {
        if (string == 'Hoover the stairs') {
          // The field's pre-fill lives on the controller.
          expect(_fieldValue(tester), string, reason: 'the name field default');
          continue;
        }
        expect(shown, contains(string), reason: '"$string" is missing');
      }

      // The exact code points the design uses (a straight apostrophe, a plain
      // hyphen, U+203A). A "smart-quote" refactor of the source strings would
      // fail here, not in a screen-reader session.
      expect(
        find.text(
          'Who'
          "'"
          's it for?',
        ),
        findsOneWidget,
      );
      expect(find.text('Coins land after your thumbs-up'), findsOneWidget);
      expect(
        find.textContaining('’'),
        findsNothing,
        reason: 'the design writes a straight apostrophe, not U+2019',
      );
      expect(
        find.textContaining('–'),
        findsNothing,
        reason: 'the design writes U+002D hyphens, not en dashes',
      );
      final due = tester.widget<Text>(find.text('Before tea (5pm) ›'));
      expect(due.textSpan!.toPlainText(), 'Before tea (5pm) ›');
      expect(
        due.textSpan!.toPlainText().codeUnits.last,
        0x203A,
        reason: 'U+203A SINGLE RIGHT-POINTING ANGLE QUOTATION MARK',
      );
      await disposeApp(tester);
    });

    testWidgets('the screen invents no copy beyond the design', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);

      final unexpected = _visibleText(tester)
          .where((string) => !kOwnedCopy.contains(string))
          .toSet();
      expect(unexpected, isEmpty, reason: 'unlisted copy on screen');
      await disposeApp(tester);
    });

    testWidgets('the day row reads M T W T F S S in design order', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      final picker = tester.widget<NestDayPicker>(find.byType(NestDayPicker));
      expect(picker.days, <String>['M', 'T', 'W', 'T', 'F', 'S', 'S']);
      // …and the row paints them in that order, Saturday selected (index 5).
      expect(picker.selected, <int>{5});
      final letters = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(NestDayPicker),
              matching: find.byType(Text),
            ),
          )
          .map((text) => text.data)
          .toList();
      expect(letters, <String>['M', 'T', 'W', 'T', 'F', 'S', 'S']);
      await disposeApp(tester);
    });

    testWidgets('the reward helper tracks the stepper', (tester) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      expect(find.text('= 15p at payout'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('increase')));
      await tester.pump();
      expect(find.text('= 16p at payout'), findsOneWidget);
      expect(find.text('16'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('decrease')));
      await tester.pump();
      expect(find.text('= 15p at payout'), findsOneWidget);
      await disposeApp(tester);
    });
  });

  group('P09 copy — accessibility labels', () {
    testWidgets('the icon tiles announce the design aria-labels', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      for (final label in _iconLabels) {
        expect(
          find.semantics.byPredicate((node) => node.label == label),
          findsOneWidget,
          reason: '$label must be announced once',
        );
      }
      handle.dispose();
      await disposeApp(tester);
    });

    testWidgets('the stepper announces `Decrease reward` / `Increase reward`', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      for (final label in _stepperLabels) {
        expect(
          find.semantics.byPredicate((node) => node.label == label),
          findsOneWidget,
          reason: '$label must be announced once',
        );
      }
      // The switch carries the same wording the design's checkbox aria-label
      // uses, so the card's title and its control are distinguishable.
      final toggle = tester.getSemantics(find.byType(NestToggle));
      expect(toggle.label, 'Needs my approval');
      expect(
        toggle.getSemanticsData().flagsCollection.isToggled,
        Tristate.isTrue,
      );
      handle.dispose();
      await disposeApp(tester);
    });
  });

  group('P09 copy — edit mode', () {
    setUp(setUpTestScope);

    testWidgets('`?id=` swaps the title and adds the delete affordance', (
      tester,
    ) async {
      await pumpAppRoute(tester, '${QuestsRoutePaths.editor}?id=q-hoover');
      final shown = _visibleText(tester).toSet();
      expect(shown, contains('Edit quest'));
      expect(shown, contains('Delete quest'));
      expect(shown, isNot(contains('New quest')));
      // The row's own copy replaces the new-quest defaults.
      expect(shown, contains('= 20p at payout'));
      expect(shown, isNot(contains('= 15p at payout')));
      expect(_fieldValue(tester), 'Hoover the stairs');
      await disposeApp(tester);
    });

    testWidgets('the due sheet titles itself `Due by`, like the card', (
      tester,
    ) async {
      await pumpAppRoute(tester, QuestsRoutePaths.editor);
      await tester.tap(find.text('Due by'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Due by'), findsNWidgets(2));
      final unexpected = _visibleText(tester)
          .where((string) => !kOwnedCopy.contains(string))
          .toSet();
      expect(unexpected, isEmpty);
      await disposeApp(tester);
    });
  });
}
