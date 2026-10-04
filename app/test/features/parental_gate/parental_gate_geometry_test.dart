// P17 parental-gate geometry tests.
//
// Two groups:
//
// 1. STRUCTURAL FACTS — the plan's token-level promises that hold whatever the
//    clock says: modal 342 wide at x24 with radius 32, lock tile 52 r16,
//    digit boxes 56×64 with a 12 gap, eleven 72×72 keys, cancel ≥ 56, and the
//    scrim barrier painted over the whole kid backdrop from (0,0) to the
//    physical edge. Light + dark.
//
// 2. DESIGN PINS — `ORCHESTRATOR_NOTES.md` (02:08) items 2–6: every element's
//    measured position at 390×844 / light / textScale 1.0, against the
//    design PNG (÷3). The bundled Inter/Nunito faces are loaded with
//    `FontLoader` (the P04 / `nest_balanced_text_test` pattern) so text-driven
//    line boxes match a device run — this harness reproduces the 5_ui
//    simulator measurements to within 1 px.
//
// Tolerance is the UI VERDICT RULE's ±2 px. Deltas are collected and reported
// together so one run lists every drifted band instead of stopping at the
// first.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/parental_gate/domain/parental_gate_repository.dart';

import '../../test_scope.dart';

/// The design's frame, measured from `design/screens/{light,dark}/
/// P17-parental-gate.png` (1170×2532 ÷ 3). Values are the CSS truth in
/// `P17-parental-gate.html` + `components.css`:
///
///   modal 66…778 (pad-top 24 · lock 52 · +12 h2/28 · +8 body-s/22 · +4 h3/24
///   · +16 digits 64 · +16 keypad(8 pad + 4×72 + 3×10) · +12 cancel 56
///   · +10 caption/18 · pad-bottom 20 = 712) at x24…366 (24 gutters).
const double designModalTop = 66;
const double designModalBottom = 778;
const double designTitleCentre = 168; // h2 line box 154…182
const double designInstructionCentre = 201; // body-s line box 190…212
const double designQuestionCentre = 228; // h3 line box 216…240
const double designDigitsCentre = 288; // 56×64 boxes 256…320
const List<double> designKeyRowCentres = <double>[380, 462, 544, 626];
const double designCancelCentre = 702; // ghost button 674…730
const double designCaptionCentre = 749; // caption line box 740…758
const double designBackdropHeaderTop = 55; // `.kb-top` under the 47 status bar

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

/// The rect a render object actually paints at, transform included (the
/// keypad's `FittedBox` scales it, the layout box stays 72).
Rect paintedRect(RenderBox box) =>
    MatrixUtils.transformRect(box.getTransformTo(null), Offset.zero & box.size);

List<RenderBox> _renderBoxes(WidgetTester tester, Finder finder) {
  final boxes = <RenderBox>[];
  for (final element in finder.evaluate()) {
    final ro = element.renderObject;
    if (ro is RenderBox && ro.hasSize) boxes.add(ro);
  }
  return boxes;
}

/// Containers whose painted box is exactly [w]×[h], left to right.
List<Rect> _boxesOfSize(WidgetTester tester, double w, double h) {
  final rects = <Rect>[];
  for (final element in find.byType(Container).evaluate()) {
    final ro = element.renderObject;
    if (ro is! RenderBox || !ro.hasSize) continue;
    final rect = paintedRect(ro);
    if ((rect.width - w).abs() < 0.75 && (rect.height - h).abs() < 0.75) {
      rects.add(rect);
    }
  }
  rects.sort((a, b) => a.left.compareTo(b.left));
  return rects;
}

Finder _keyInks() =>
    find.byWidgetPredicate((w) => w is Ink && w.width == 72 && w.height == 72);

/// `Positioned.fill(child: ExcludeSemantics(child: backdrop))` — the dimmed
/// kid screen behind the card.
bool _isBackdrop(Widget child) =>
    child is Positioned && child.child is ExcludeSemantics;

/// `Positioned.fill(child: ColoredBox(color: scrim))` — the design's
/// `.scrim { position: absolute; inset: 0 }` barrier.
bool _isScrim(Widget child) {
  if (child is! Positioned || child.child is! ColoredBox) return false;
  const zero = 0.0;
  return child.left == zero &&
      child.top == zero &&
      child.right == zero &&
      child.bottom == zero;
}

double _lineCentre(WidgetTester tester, String copy) =>
    tester.getRect(find.text(copy)).center.dy;

void main() {
  setUpAll(_loadBundledFonts);

  setUp(() async {
    await setUpTestScope();
  });

  group('structural facts', () {
    for (final (String themeName, ThemeMode theme)
        in const <(String, ThemeMode)>[
          ('light', ThemeMode.light),
          ('dark', ThemeMode.dark),
        ]) {
      testWidgets('modal frame and children match the spec — $themeName', (
        tester,
      ) async {
        // Never pin the day: the box count is the answer's digit count.
        // Drift needs the real event loop, hence runAsync.
        final challenge = (await tester.runAsync(
          () => GetIt.instance<ParentalGateRepository>().getItems(),
        ))!.single;
        final boxes = challenge.answer.toString().length;

        GetIt.instance<AppModeController>().selectMode(AppMode.kid);
        await pumpAppRoute(tester, '/parental-gate', theme: theme);

        // Modal: x 24, width 390 − 2×24 = 342.
        final modal = tester.getRect(find.byType(NestModal));
        expect(modal.left, moreOrLessEquals(24, epsilon: 0.5));
        expect(modal.width, moreOrLessEquals(342, epsilon: 0.5));
        final modalDecoration =
            tester
                    .widgetList<Container>(
                      find.byWidgetPredicate(
                        (w) =>
                            w is Container &&
                            w.decoration is BoxDecoration &&
                            (w.decoration! as BoxDecoration).borderRadius ==
                                NestRadii.allXl,
                      ),
                    )
                    .first
                    .decoration!
                as BoxDecoration;
        expect(modalDecoration.borderRadius, NestRadii.allXl);

        // Lock tile 52×52 radius 16.
        expect(_boxesOfSize(tester, 52, 52), hasLength(1));

        // Digit boxes: one 56×64 per answer digit, 12 gap, centred.
        final digitBoxes = _boxesOfSize(tester, 56, 64);
        expect(digitBoxes, hasLength(boxes));
        for (var i = 1; i < digitBoxes.length; i++) {
          expect(
            digitBoxes[i].left - digitBoxes[i - 1].right,
            moreOrLessEquals(NestSpacing.s3, epsilon: 0.5),
          );
        }
        expect(
          (digitBoxes.first.left + digitBoxes.last.right) / 2,
          moreOrLessEquals(195, epsilon: 0.5),
          reason: 'the digits row stays centred in the 342 card',
        );

        // Keys 72×72 (Ink), 11 of them (10 digits + delete; blank is not inked).
        final keys = _keyInks();
        expect(keys, findsNWidgets(11));
        expect(
          tester.getSize(keys.first).width,
          moreOrLessEquals(72, epsilon: 0.5),
        );

        // Cancel ghost stays at the 56 kid minimum and spans the card's content.
        final cancel = find.ancestor(
          of: find.text('Back to Pip'),
          matching: find.byType(NestButton),
        );
        final cancelRect = tester.getRect(cancel);
        expect(cancelRect.height, greaterThanOrEqualTo(NestDevice.tapKid));
        expect(cancelRect.width, moreOrLessEquals(342 - 2 * 20, epsilon: 0.5));

        await disposeApp(tester);
      });
    }

    testWidgets('the scrim barrier covers (0,0) to the physical edge', (
      tester,
    ) async {
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');

      final barriers = <Rect>[];
      for (final box in _renderBoxes(tester, find.byType(ColoredBox))) {
        barriers.add(paintedRect(box));
      }
      expect(
        barriers.any(
          (r) => r.left == 0 && r.top == 0 && r.right == 390 && r.bottom == 844,
        ),
        isTrue,
        reason:
            'the scrim must run full-bleed from (0,0) to the physical edge — '
            'no bright strip at the top, none below the card (BOTTOM EDGE rule)',
      );
      await disposeApp(tester);
    });

    testWidgets('the barrier is painted above the kid backdrop', (
      tester,
    ) async {
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');

      // The gate layer is the Stack that holds both the dimmed backdrop and
      // the scrim; the scrim must come after it (later child = on top).
      Stack? gateStack;
      int? backdropIndex;
      int? scrimIndex;
      for (final element in find.byType(Stack).evaluate()) {
        final stack = element.widget as Stack;
        // Both layers are wrapped in `Positioned.fill`, so look through it.
        final backdrop = stack.children.indexWhere(_isBackdrop);
        var scrim = -1;
        for (var i = 0; i < stack.children.length; i++) {
          if (_isScrim(stack.children[i])) scrim = i;
        }
        if (backdrop >= 0 && scrim >= 0) {
          gateStack = stack;
          backdropIndex = backdrop;
          scrimIndex = scrim;
          break;
        }
      }
      expect(gateStack, isNotNull, reason: 'the gate Stack must be found');
      expect(
        scrimIndex,
        greaterThan(backdropIndex!),
        reason: 'the scrim must dim the backdrop (HTML: .scrim after .kid-bg)',
      );
      await disposeApp(tester);
    });
  });

  group('ORCHESTRATOR_NOTES design pins (390×844, light, textScale 1.0)', () {
    testWidgets('every band sits within ±2 px of the design PNG', (
      tester,
    ) async {
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
      await pumpAppRoute(tester, '/parental-gate');

      final drifts = <String>[];
      void check(String what, double actual, double expected) {
        final delta = actual - expected;
        if (delta.abs() > 2) {
          drifts.add(
            '$what: app ${actual.toStringAsFixed(1)} vs design '
            '${expected.toStringAsFixed(1)} (Δ${delta.toStringAsFixed(1)})',
          );
        }
      }

      // 2. Card frame.
      final modal = tester.getRect(find.byType(NestModal));
      check('card top', modal.top, designModalTop);
      check('card bottom', modal.bottom, designModalBottom);
      check('card height', modal.height, designModalBottom - designModalTop);
      check('card left', modal.left, 24);
      check('card width', modal.width, 342);

      // 3. Title / instruction / question line centres.
      check(
        'title "Grown-ups only" centre',
        _lineCentre(tester, 'Grown-ups only'),
        designTitleCentre,
      );
      check(
        'instruction centre',
        _lineCentre(tester, 'Type the answer in numbers:'),
        designInstructionCentre,
      );
      // The question is DB-driven, so find it by its "times" wording rather
      // than by the design's example.
      check(
        'question centre',
        tester.getRect(find.textContaining('times')).center.dy,
        designQuestionCentre,
      );

      // 4. Answer boxes.
      final digits = _boxesOfSize(tester, 56, 64);
      expect(digits, isNotEmpty);
      check('answer boxes centre', digits.first.center.dy, designDigitsCentre);

      // 5. Keypad row centres.
      final rows = <double>[];
      for (final box in _renderBoxes(tester, _keyInks())) {
        rows.add(paintedRect(box).center.dy);
      }
      final rowCentres = (rows.toSet().toList()..sort());
      expect(rowCentres, hasLength(designKeyRowCentres.length));
      for (var i = 0; i < rowCentres.length; i++) {
        check(
          'keypad row ${i + 1} centre',
          rowCentres[i],
          designKeyRowCentres[i],
        );
      }

      // 6. Cancel button centre + caption centre.
      final cancel = tester.getRect(
        find.ancestor(
          of: find.text('Back to Pip'),
          matching: find.byType(NestButton),
        ),
      );
      check('"Back to Pip" centre', cancel.center.dy, designCancelCentre);
      check(
        'caption centre',
        _lineCentre(tester, 'This keeps settings and purchases safe.'),
        designCaptionCentre,
      );

      // ORCHESTRATOR_NOTES item 1 / 5_ui deviation 2: the dimmed kid header
      // starts below the 47 px status-bar reserve, not under the OS clock.
      check(
        'dimmed backdrop header top',
        tester.getRect(find.text('Hi Maya!')).top,
        designBackdropHeaderTop,
      );

      expect(
        drifts,
        isEmpty,
        reason:
            'P17 geometry drifts from the design PNG (UI VERDICT RULE ±2 px):\n'
            '  ${drifts.join('\n  ')}\n'
            '5_ui + ORCHESTRATOR_NOTES: anchor the card at the design top (66) '
            'instead of centring it, reserve the status-bar height above the '
            'kid backdrop, and restore the HTML keypad gaps.',
      );
      await disposeApp(tester);
    });

    testWidgets('the keypad follows the HTML grid gap (pitch 82)', (
      tester,
    ) async {
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');

      final rows = <double>[];
      for (final box in _renderBoxes(tester, _keyInks())) {
        rows.add(paintedRect(box).center.dy);
      }
      final rowCentres = (rows.toSet().toList()..sort());
      final pitches = <double>[
        for (var i = 1; i < rowCentres.length; i++)
          rowCentres[i] - rowCentres[i - 1],
      ];
      for (final pitch in pitches) {
        expect(
          pitch,
          moreOrLessEquals(82, epsilon: 0.5),
          reason: '.keypad gap 10 + key 72 ⇒ row pitch 82',
        );
      }

      // `.keypad { grid-template-columns: repeat(3, 1fr); gap: 10 }` inside the
      // 302-wide card content resolves to a 88 px column pitch at 390 (keys
      // 71…143 / 159…231 / 247…319).
      final columns = <double>[];
      for (final box in _renderBoxes(tester, _keyInks())) {
        columns.add(paintedRect(box).left);
      }
      columns.sort();
      final lefts = columns.toSet().toList()..sort();
      expect(
        lefts[1] - lefts[0],
        moreOrLessEquals(88, epsilon: 0.5),
        reason: 'HTML 1fr columns resolve to a 88 px pitch inside the card',
      );
      await disposeApp(tester);
    });
  });
}
