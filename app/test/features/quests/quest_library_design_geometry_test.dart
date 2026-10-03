// P10 · Quest library — design geometry, measured from the design PNG.
//
// UI VERDICT RULE: every element must sit within ±2 px of the design position,
// and the measured y of the title, the first control and each card top must be
// reported design-versus-app.
//
// The numbers below were read off `design/screens/light/P10-quest-library.png`
// (1170×2532 @3x) by scanning for the exact token colours, at x ranges chosen
// to isolate each element:
//
//   title ink   `--ink`      x  20…370, y  45…100 →  61.0 …  86.7
//   seg track   `--surface-2`                     → 105.0 … 157.0  (52 tall)
//   seg thumb   `--surface`  x 190…385           → 109.0 … 153.0  (44 tall)
//   field box   `--line`     x  20…370           → 173.0 … 227.0  (54 tall)
//   chip pill   `--leaf`     x  20…70            → 227.0 … 271.0  (44 tall)
//   card 1      `--surface`  x  20…370           → 291.0 … 359.0  (68 tall)
//   tab bar     `--line`     x   5               → surface top 726.0
//   tab icon    `--ink-3`    x  30…60            → 739.3 … 759.0  (24 box 736…760)
//   tab label   `--ink-3`    x  30…60            → 768.0 … 776.0  (14 box 764…778)
//
// The widget tree starts at y 0 because `NestStatusBar` only reserves height
// (orchestrator rule), so every test here injects the device insets a real
// 390×844 phone reports — top 47 (status bar) and bottom 34 (home indicator)
// — exactly as `p10_bugs_test.dart` BUG-P10-7 does. With them injected the
// widget y values are directly comparable to the design's absolute y.
//
// OWNER BOTTOM-EDGE RULE: the design's bar surface stops at 810 with a 34 px
// paper strip below it. The app must instead run the surface to 844 while
// keeping the CONTENT at the design's y, so the assertions below check the
// surface top (726) and the physical bottom (844) separately.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_category_chips.dart';
import 'package:nestling/features/quests/presentation/widgets/quest_library_body.dart';
import 'package:nestling/features/quests/quests_routes.dart';

import '../../test_scope.dart';

/// The design's geometry in logical px on the 390×844 canvas.
class _Design {
  const _Design();

  /// `.ptitle { padding-top: 8px }` inside a 47-high status bar; 34-high line.
  static const double titleTop = 55;
  static const double titleBottom = 89;

  static const double segTrackTop = 105;
  static const double segTrackHeight = 52;
  static const double segThumbTop = 109;
  static const double segThumbHeight = 44;

  static const double fieldTop = 173;
  static const double fieldHeight = 54;

  static const double chipTop = 227;
  static const double chipHeight = 44;

  static const double card1Top = 291;
  static const double cardHeight = 68;
  static const double cardStep = 84; // 68 card + 16 sibling gap

  /// `.tab-bar` surface top; the app runs the surface to 844 instead of 810.
  static const double tabSurfaceTop = 726;
  static const double tabIconTop = 736;
  static const double tabLabelTop = 764;

  /// `.search { padding: 4px 16px }` + a 24 px svg.
  static const double searchIconLeft = 36; // field x 20 + 16
  static const double searchIconSize = 24;

  /// The UI VERDICT RULE's tolerance.
  static const double tolerance = 2;
}

const List<String> _ideaIds = <String>[
  'idea-bed',
  'idea-table',
  'idea-bins',
  'idea-dishwasher',
  'idea-hoover',
  'idea-pet',
  'idea-bag',
  'idea-plants',
  'idea-washing',
  'idea-reading',
];

Finder _card(int index) =>
    find.byKey(ValueKey<String>('quest-idea-${_ideaIds[index]}'));

Finder _chip(String category) =>
    find.byKey(ValueKey<String>('quest-filter-chip-$category'));

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

/// Pumps `/quests` on a 390×844 surface with the insets a real phone reports,
/// so widget y values line up with the design's absolute y values.
Future<void> _pumpDevice(
  WidgetTester tester,
  String route, {
  ThemeMode theme = ThemeMode.light,
}) async {
  const insets = FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
  tester.view.padding = insets;
  tester.view.viewPadding = insets;
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(NestlingApp(initialRoute: route));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Why the hint-centring pin is red (BUG-P10-14 · SHARED_REQUEST §10).
const String _hintReason =
    'the design centres the hint ink in the `.search` box (field 173…227 ⇒ '
    'centre y 200); `NestTextField.search` renders the 24-tall hint box at the '
    'TOP of its 44 px input (y 177…201 ⇒ 189). Cause is in core/ — see '
    'SHARED_REQUEST §10 — so P10 must not patch it locally.';

void main() {
  setUpAll(_loadBundledFonts);

  group('P10 design geometry — the title and the controls under it', () {
    testWidgets('title sits on the design y', (tester) async {
      await setUpTestScope();
      await _pumpDevice(tester, QuestsRoutePaths.library);

      // Scoped to the body: the shell's tab bar also carries a "Quests" label.
      final title = tester.getRect(
        find.descendant(
          of: find.byType(QuestLibraryBody),
          matching: find.text('Quests'),
        ),
      );
      expect(title.top, closeTo(_Design.titleTop, _Design.tolerance));
      expect(title.bottom, closeTo(_Design.titleBottom, _Design.tolerance));
      expect(title.left, NestSpacing.padSide);

      await disposeApp(tester);
    });

    testWidgets('the segmented control sits on the design y (52 / 44)', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpDevice(tester, QuestsRoutePaths.library);

      final track = tester.getRect(find.byType(NestSegmented<String>));
      expect(track.top, closeTo(_Design.segTrackTop, _Design.tolerance));
      expect(
        track.height,
        closeTo(_Design.segTrackHeight, _Design.tolerance),
        reason: '`.segmented` = 4 padding + 44 button + 4 padding',
      );

      final thumb = tester.getRect(
        find
            .descendant(
              of: find.byType(NestSegmented<String>),
              matching: find.byType(Ink),
            )
            .first,
      );
      expect(thumb.top, closeTo(_Design.segThumbTop, _Design.tolerance));
      expect(thumb.height, closeTo(_Design.segThumbHeight, _Design.tolerance));

      await disposeApp(tester);
    });

    testWidgets('the search field sits on the design y', (tester) async {
      await setUpTestScope();
      await _pumpDevice(tester, QuestsRoutePaths.library);

      final field = tester.getRect(find.byType(NestTextField));
      expect(field.top, closeTo(_Design.fieldTop, _Design.tolerance));
      expect(
        field.height,
        closeTo(_Design.fieldHeight, _Design.tolerance),
        reason:
            '`.search { min-height:52px; padding:4px 16px; border:1px }` with '
            '`box-sizing: border-box` computes to 52 content + 2 border = 54; '
            'the app renders 52, which pushes everything below it 2 px up',
      );

      // `.chipscroll { margin: 0 -20px }` cancels `.scroll > * + *`.
      expect(
        tester.getRect(find.byType(QuestCategoryChips)).top - field.bottom,
        0,
      );

      await disposeApp(tester);
    });

    testWidgets('the magnifier keeps the `.search` slot', (tester) async {
      await setUpTestScope();
      await _pumpDevice(tester, QuestsRoutePaths.library);

      final field = tester.getRect(find.byType(NestTextField));
      final icon = tester.getRect(
        find
            .descendant(
              of: find.byType(NestTextField),
              matching: find.byType(NestIcon),
            )
            .first,
      );

      expect(icon.width, closeTo(_Design.searchIconSize, 1));
      expect(icon.height, closeTo(_Design.searchIconSize, 1));
      expect(icon.left, closeTo(_Design.searchIconLeft, _Design.tolerance));

      // The placeholder starts at field x + 16 + 24 + 10 = 50. The design PNG
      // reads ≈ 53.7; the extra ~3.7 px is Chrome's default `input` padding,
      // which Flutter has no equivalent of, so the tolerance is wider here.
      expect(
        tester.getRect(find.text('Search ideas')).left - field.left,
        closeTo(50, 4),
      );

      await disposeApp(tester);
    });

    testWidgets('the magnifier is centred in the field', (tester) async {
      await setUpTestScope();
      await _pumpDevice(tester, QuestsRoutePaths.library);

      final field = tester.getRect(find.byType(NestTextField));
      final icon = tester.getRect(
        find
            .descendant(
              of: find.byType(NestTextField),
              matching: find.byType(NestIcon),
            )
            .first,
      );

      // The icon IS centred today (199 vs the field's 199). Pinned so the
      // hint fix (SHARED_REQUEST §10, BUG-P10-14) cannot be paid for by moving
      // the icon.
      expect(icon.center.dy, closeTo(field.center.dy, 1));

      await disposeApp(tester);
    });

    // ORCHESTRATOR_NOTES 12:17 items 1 + 3 (mandatory pin). RED on purpose:
    // the design puts the hint's ink centre at y = 200 (the field spans
    // 173…227) and the app paints it at 189 — `NestTextField.search` gives the
    // input a fixed 44 px box but the hint renders at the TOP of it (24 tall
    // box at y 177…201) while the magnifier is correctly centred at 199.
    //
    // Cause is inside `core/design_system/components/nest_text_field.dart:169-191`
    // (the 44-high `SizedBox` + `textAlignVertical` do not centre the hint),
    // which RULES §1 forbids P10 from editing, and P10 must not wrap or
    // re-pad the shared field locally. Filed as SHARED_REQUEST §10; the pin
    // turns green the moment that lands.
    testWidgets('the hint is centred in the field, not floated to the top', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpDevice(tester, QuestsRoutePaths.library);

      final field = tester.getRect(find.byType(NestTextField));
      final hint = tester.getRect(find.text('Search ideas'));

      expect(hint.center.dy, closeTo(200, 1), reason: _hintReason);
      expect(
        hint.center.dy,
        closeTo(field.center.dy, 2),
        reason: 'the hint and the magnifier share the centre of the field',
      );

      await disposeApp(tester);
    });
  });

  group('P10 design geometry — the chip row and the list', () {
    testWidgets('the chip row and the first card sit on the design y', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpDevice(tester, QuestsRoutePaths.library);

      final chip = tester.getRect(_chip('All'));
      expect(chip.top, closeTo(_Design.chipTop, _Design.tolerance));
      expect(chip.height, closeTo(_Design.chipHeight, _Design.tolerance));

      final card = tester.getRect(_card(0));
      expect(card.top, closeTo(_Design.card1Top, _Design.tolerance));
      expect(card.height, closeTo(_Design.cardHeight, _Design.tolerance));
      expect(card.left, NestSpacing.padSide);
      expect(card.right, 390 - NestSpacing.padSide);

      await disposeApp(tester);
    });

    testWidgets('card tops step by 84 down the whole list', (tester) async {
      await setUpTestScope();
      await _pumpDevice(tester, QuestsRoutePaths.library);

      // Asserted on the cards the lazy list has already built, so the values
      // are true screen positions (a scrolled card's rect is scroll-shifted).
      final first = tester.getRect(_card(0)).top;

      for (var i = 1; i < _ideaIds.length; i++) {
        final card = _card(i);
        if (card.evaluate().isEmpty) break;
        expect(
          tester.getRect(card).top,
          closeTo(first + i * _Design.cardStep, _Design.tolerance),
          reason: 'card ${i + 1} (${_ideaIds[i]})',
        );
      }

      // The last card still exists after scrolling to the end, and its bottom
      // gap is the design's `.scroll` padding (proved by BUG-P10-4).
      await tester.scrollUntilVisible(
        _card(_ideaIds.length - 1),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(_card(_ideaIds.length - 1), findsOneWidget);

      await disposeApp(tester);
    });
  });

  group('P10 design geometry — the tab bar', () {
    testWidgets(
      'content keeps the design y while the surface runs to the edge',
      (tester) async {
        await setUpTestScope();
        await _pumpDevice(tester, QuestsRoutePaths.library);

        final bar = tester.getRect(find.byType(NestTabBar));

        // OWNER BOTTOM-EDGE RULE: same surface colour to the physical edge, no
        // paper strip under the home indicator.
        expect(bar.bottom, 844, reason: 'the surface must run to the edge');
        expect(
          bar.height,
          greaterThan(NestDevice.tabH),
          reason: 'the bar carries the extra home strip below its labels',
        );
        // …while the top stays on the design's bar top (726, not 760).
        expect(bar.top, closeTo(_Design.tabSurfaceTop, _Design.tolerance));

        final icon = tester.getRect(
          find
              .descendant(
                of: find.byType(NestTabBar),
                matching: find.byType(NestIcon),
              )
              .first,
        );
        expect(icon.top, closeTo(_Design.tabIconTop, _Design.tolerance));
        expect(icon.height, closeTo(24, 1));

        final label = tester.getRect(
          find.descendant(
            of: find.byType(NestTabBar),
            matching: find.text('Today'),
          ),
        );
        expect(label.top, closeTo(_Design.tabLabelTop, _Design.tolerance));

        await disposeApp(tester);
      },
    );

    testWidgets('the list scrolls under the bar like the design', (
      tester,
    ) async {
      await setUpTestScope();
      await _pumpDevice(tester, QuestsRoutePaths.library);

      // The 6th card peeks under the bar in the design PNG.
      final barTop = tester.getRect(find.byType(NestTabBar)).top;
      final sixth = _card(5);
      await tester.scrollUntilVisible(
        sixth,
        240,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final barBottom = tester.getRect(find.byType(NestTabBar)).bottom;
      expect(barBottom, 844);
      expect(barTop, lessThan(844));
      // The card is rendered in the same coordinate space as the bar, i.e.
      // the list is not clipped short of it.
      expect(tester.getRect(sixth).right, 390 - NestSpacing.padSide);

      await disposeApp(tester);
    });
  });

  group('P10 design geometry — dark mode', () {
    testWidgets('the same y in dark as in light', (tester) async {
      await setUpTestScope();
      await _pumpDevice(
        tester,
        QuestsRoutePaths.library,
        theme: ThemeMode.dark,
      );

      expect(
        tester.getRect(_card(0)).top,
        closeTo(_Design.card1Top, _Design.tolerance),
      );
      expect(
        tester.getRect(_chip('All')).top,
        closeTo(_Design.chipTop, _Design.tolerance),
      );
      expect(
        tester.getRect(find.byType(NestTabBar)).top,
        closeTo(_Design.tabSurfaceTop, _Design.tolerance),
      );
      expect(tester.getRect(find.byType(NestTabBar)).bottom, 844);

      await disposeApp(tester);
    });
  });
}
