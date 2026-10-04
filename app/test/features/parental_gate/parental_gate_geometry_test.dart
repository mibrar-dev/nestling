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
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/parental_gate/domain/entities/parental_gate_challenge.dart';
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
const double designBackdropHeaderTop =
    55; // `.kb-top` row top: 47 status bar + 8
/// The greeting's TEXT top, not the row's: `.kb-top { align-items: center }`
/// centres the h1 line box (28/34) and the 36 px coin pill inside the 44 px
/// avatar row ⇒ 55 + (44 − 34)/2 = 60. (`3_test` §3.1 measured the app at 55
/// there because the row used `CrossAxisAlignment.start`; the row top stays 55
/// either way — only the items' alignment changes.)
const double designBackdropGreetingTop = 60;
const double designKeypadSlotTop = 336; // digits 320 + `.keypad` margin-top 16

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
    /// Collects every band that misses the design by more than ±2 px so one
    /// run reports the whole list instead of stopping at the first.
    List<String> driftCollector() {
      final drifts = <String>[];
      return drifts;
    }

    void check(
      List<String> drifts,
      String what,
      double actual,
      double expected,
    ) {
      final delta = actual - expected;
      if (delta.abs() > 2) {
        drifts.add(
          '$what: app ${actual.toStringAsFixed(1)} vs design '
          '${expected.toStringAsFixed(1)} (Δ${delta.toStringAsFixed(1)})',
        );
      }
    }

    testWidgets('the card anchor and every band above the keypad match', (
      tester,
    ) async {
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
      await pumpAppRoute(tester, '/parental-gate');

      final drifts = driftCollector();
      // 2. Card frame — the design anchors the card at y 66 (it is NOT
      // vertically centred; centring only coincided while the card was the
      // design's height).
      final modal = tester.getRect(find.byType(NestModal));
      check(drifts, 'card top', modal.top, designModalTop);
      check(drifts, 'card left', modal.left, 24);
      check(drifts, 'card width', modal.width, 342);

      // The lock tile starts the CSS chain: pad-top 24 → 90.
      final lock = _boxesOfSize(tester, 52, 52).single;
      check(drifts, 'lock tile top', lock.top, 90);
      check(drifts, 'lock tile bottom', lock.bottom, 142);

      // 3. Title / instruction / question line centres, i.e. the CSS rhythm
      // 52 → +12 → h2/28 → +8 → body-s/22 → +4 → h3/24.
      final lockBottom = lock.bottom;
      check(
        drifts,
        'title "Grown-ups only" centre',
        _lineCentre(tester, 'Grown-ups only'),
        designTitleCentre,
      );
      check(
        drifts,
        'title gap below the lock tile',
        _lineCentre(tester, 'Grown-ups only') - (lockBottom + 28 / 2),
        12,
      );
      check(
        drifts,
        'instruction centre',
        _lineCentre(tester, 'Type the answer in numbers:'),
        designInstructionCentre,
      );
      // The question is DB-driven, so find it by its "times" wording rather
      // than by the design's example.
      final question = tester.getRect(find.textContaining('times'));
      check(
        drifts,
        'question centre',
        question.center.dy,
        designQuestionCentre,
      );
      check(
        drifts,
        'question gap below the instruction',
        question.top -
            (_lineCentre(tester, 'Type the answer in numbers:') + 11),
        4,
      );

      // 4. Answer boxes: 256…320 (`.digits { margin-top: 16 }` after the h3
      // line box), 56 wide, 12 gap, centred in the 342 card.
      final digits = _boxesOfSize(tester, 56, 64);
      expect(digits, isNotEmpty);
      check(
        drifts,
        'answer boxes centre',
        digits.first.center.dy,
        designDigitsCentre,
      );
      check(drifts, 'answer boxes left', digits.first.left, 133);
      check(
        drifts,
        'answer boxes gap',
        digits[1].left - digits.first.right,
        NestSpacing.s3,
      );

      // 5a. Keypad row 1 — the first row is still P17's to place
      // (`.gate .keypad { margin-top: 16 }` + the grid's 8 px pad-top).
      final rowCentres = _keyRowCentres(tester);
      expect(rowCentres, hasLength(designKeyRowCentres.length));
      check(
        drifts,
        'keypad row 1 centre',
        rowCentres.first,
        designKeyRowCentres.first,
      );
      check(
        drifts,
        'keypad slot top',
        tester.getRect(find.byType(NestKeypad)).top,
        designKeypadSlotTop,
      );

      // ORCHESTRATOR_NOTES item 1 / 5_ui deviation 2: the dimmed kid header
      // starts below the 47 px status-bar reserve, not under the OS clock.
      expect(find.byType(NestStatusBar), findsOneWidget);
      // `.kb-top` is a 44 px row at design y 55; `align-items: center` puts the
      // 34 px greeting line box at 60 and the 36 px pill at 59.
      check(
        drifts,
        'dimmed backdrop header row top',
        tester.getRect(find.byType(NestAvatar)).top,
        designBackdropHeaderTop,
      );
      check(
        drifts,
        'dimmed backdrop greeting top',
        tester.getRect(find.text('Hi Maya!')).top,
        designBackdropGreetingTop,
      );

      expect(
        drifts,
        isEmpty,
        reason:
            'P17 geometry drifts from the design PNG (UI VERDICT RULE ±2 px):\n'
            '  ${drifts.join('\n  ')}',
      );
      await disposeApp(tester);
    });

    testWidgets('the bands below the keypad match the design', (tester) async {
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
      await pumpAppRoute(tester, '/parental-gate');

      final drifts = driftCollector();
      final modal = tester.getRect(find.byType(NestModal));
      check(drifts, 'card bottom', modal.bottom, designModalBottom);
      check(
        drifts,
        'card height',
        modal.height,
        designModalBottom - designModalTop,
      );

      // 5b. Keypad rows 2–4. Row 1 already lands on the design; every later
      // row drifts by the shared component's row gap.
      final rowCentres = _keyRowCentres(tester);
      expect(rowCentres, hasLength(designKeyRowCentres.length));
      for (var i = 1; i < rowCentres.length; i++) {
        check(
          drifts,
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
      check(
        drifts,
        '"Back to Pip" centre',
        cancel.center.dy,
        designCancelCentre,
      );
      check(
        drifts,
        'caption centre',
        _lineCentre(tester, 'This keeps settings and purchases safe.'),
        designCaptionCentre,
      );

      expect(
        drifts,
        isEmpty,
        reason:
            'Everything below the keypad is off by the shared component, not '
            'by P17: the shared NestKeypad '
            '(app/lib/core/design_system/components/nest_keypad.dart) '
            'hard-codes a 16 px row gap and 8 px padding '
            'all round where the CSS grid is `gap: 10; padding: 8 24 0`, so '
            "it renders 352 tall against the design's 326 (+26) and each "
            'row lands +6 low. No call-site change can move row 2 (it is '
            'already 6 px low inside the component). Blocked on core — see '
            'docs/screens/P17/SHARED_REQUEST.md #3 and the TODO(P17) at the '
            'NestKeypad call site.\n'
            'Measured drifts:\n  ${drifts.join('\n  ')}',
      );
      await disposeApp(tester);
    });

    testWidgets('the keypad follows the HTML grid gap (pitch 82)', (
      tester,
    ) async {
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      await pumpAppRoute(tester, '/parental-gate');

      final pitches = <double>[
        for (var i = 1; i < _keyRowCentres(tester).length; i++)
          _keyRowCentres(tester)[i] - _keyRowCentres(tester)[i - 1],
      ];
      expect(pitches, hasLength(3));
      for (final pitch in pitches) {
        expect(
          pitch,
          moreOrLessEquals(82, epsilon: 0.5),
          reason:
              '.keypad gap 10 + key 72 ⇒ row pitch 82. Shared NestKeypad uses '
              '16 (SHARED_REQUEST #3).',
        );
      }

      // `.keypad { grid-template-columns: repeat(3, 1fr); gap: 10 }` inside the
      // 302-wide card content resolves to a 88 px column pitch at 390 (keys
      // 71…143 / 159…231 / 247…319).
      final lefts = <double>{
        for (final box in _renderBoxes(tester, _keyInks()))
          paintedRect(box).left,
      }.toList()..sort();
      expect(lefts, hasLength(3));
      expect(
        lefts[1] - lefts[0],
        moreOrLessEquals(88, epsilon: 0.5),
        reason: 'HTML 1fr columns resolve to a 88 px pitch inside the card',
      );
      await disposeApp(tester);
    });

    testWidgets('the keypad is never laid out under unbounded width', (
      tester,
    ) async {
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
      await pumpAppRoute(tester, '/parental-gate');

      // Merge-readiness guard for the shared keypad. The merged
      // `shared/keypad_grid` NestKeypad reproduces CSS `repeat(3, 1fr)` with
      // `Expanded` cells (ORCHESTRATOR_NOTES 07:13). `FittedBox` hands its
      // child UNBOUNDED constraints, so a keypad wrapped in one must be given
      // an explicit width or the gate throws
      // "RenderFlex children have non-zero flex but incoming width
      // constraints are unbounded" on its first frame — verified with a
      // minimal Expanded-grid probe.
      //
      // Fix at the call site: at the design width the CSS `.keypad` is a
      // block-level grid, so render `NestKeypad(kid: true)` directly in the
      // 302 px card content (no FittedBox); for narrower cards wrap a
      // WIDTH-BOUNDED instance, e.g.
      // `FittedBox(fit: BoxFit.scaleDown, child: SizedBox(width: 280,
      // child: NestKeypad(fit: NestKeypadFit.shrinkWrap)))` — 232/280 keeps the
      // painted key at 59.7 px, above the 56 px kid minimum.
      final fitted = find.ancestor(
        of: find.byType(NestKeypad),
        matching: find.byType(FittedBox),
      );
      if (fitted.evaluate().isNotEmpty) {
        final child = tester.widget<FittedBox>(fitted.first).child;
        expect(
          child,
          isA<SizedBox>().having((box) => box.width, 'width', isNotNull),
          reason:
              'a FittedBox passes unbounded width to its child; an Expanded '
              'keypad grid needs an explicit width or it throws a layout '
              'assertion once shared/keypad_grid lands',
        );
      }
      // Whatever the wrapper, the painted geometry must still be the design's.
      expect(_keyRowCentres(tester), hasLength(4));
      await disposeApp(tester);
    });

    testWidgets('the backdrop row centres its items like `.kb-top`', (
      tester,
    ) async {
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
      await pumpAppRoute(tester, '/parental-gate');

      // `.kb-top { display:flex; align-items:center; gap:12px; padding-top:8px }`
      // under the 47 px status bar ⇒ the row is y 55…99 (the 44 px avatar sets
      // the cross size) and the greeting (h1 28/34) and the coin pill (36) are
      // centred inside it.
      final avatar = tester.getRect(find.byType(NestAvatar));
      expect(avatar.top, moreOrLessEquals(55, epsilon: 0.5));
      expect(avatar.height, moreOrLessEquals(44, epsilon: 0.5));

      final greeting = tester.getRect(find.text('Hi Maya!'));
      final pill = tester.getRect(find.byType(NestCoinPill));
      expect(
        greeting.center.dy,
        moreOrLessEquals(avatar.center.dy, epsilon: 1),
        reason:
            'CSS align-items: centre — the greeting is 5 px high in the app '
            '(55…89 instead of 60…94) because the row uses '
            'CrossAxisAlignment.start. One-line fix: drop that argument (the '
            'default is centre). Dimmed scenery, so cosmetic, but it is a '
            'measurable CSS-truth deviation in the only backdrop pixels the '
            'card does not cover.',
      );
      expect(
        pill.center.dy,
        moreOrLessEquals(avatar.center.dy, epsilon: 1),
        reason: 'the coin pill is centred in the same 44 px row',
      );
      // `.kb-top { gap: 12px }` between the avatar and the greeting.
      expect(greeting.left - avatar.right, moreOrLessEquals(12, epsilon: 0.5));
      await disposeApp(tester);
    });

    testWidgets("the dimmed backdrop shows the child's own Pip in the slot", (
      tester,
    ) async {
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
      await pumpAppRoute(tester, '/parental-gate');

      // PIP rule: the DB look (Maya = Mochi · sunny · stage 3), never the v1
      // pip_stage_*.svg. The card covers the slot on screen, so this is the
      // only place the rule can be checked.
      final pip = tester.widget<PipAvatar>(find.byType(PipAvatar));
      expect(pip.style, PipStyle.mochi);
      expect(pip.skin, PipSkin.sunny);
      expect(pip.stage, 3);
      expect(pip.accessory, PipAccessory.none);
      expect(pip.size, 200);

      // `.kb-pet { margin-top: 26px }` after the 44 px header row ⇒ y 125…325,
      // centred in the 390 canvas.
      final slot = tester.getRect(find.byType(PipAvatar));
      expect(slot.top, moreOrLessEquals(125, epsilon: 0.5));
      expect(slot.height, moreOrLessEquals(200, epsilon: 0.5));
      expect(slot.center.dx, moreOrLessEquals(195, epsilon: 0.5));

      // Exactly one Pip in the scene, and it is the DS component (a v1
      // `pip_stage_*.svg` would leave `find.byType(PipAvatar)` empty).
      expect(find.byType(PipAvatar), findsOneWidget);
      await disposeApp(tester);
    });

    testWidgets('the loading placeholders keep the loaded card height', (
      tester,
    ) async {
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
      await pumpAppRoute(tester, '/parental-gate');
      final loaded = tester.getRect(find.byType(NestModal));
      await disposeApp(tester);

      // Same screen, a stream that never emits: the frame must not jump.
      await setUpTestScope();
      await GetIt.instance.unregister<ParentalGateRepository>();
      GetIt.instance.registerSingleton<ParentalGateRepository>(
        _HangingRepository(),
      );
      GetIt.instance<AppModeController>().selectMode(AppMode.kid);
      GetIt.instance<ThemeModeController>().selectMode(ThemeMode.light);
      await pumpAppRoute(tester, '/parental-gate');
      final loading = tester.getRect(find.byType(NestModal));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        (loaded.height - loading.height).abs(),
        lessThanOrEqualTo(6),
        reason:
            'the loading placeholders stand in for the instruction + question '
            'lines, so the card may differ by at most the missing 4 px gap',
      );
      expect(loading.top, moreOrLessEquals(loaded.top, epsilon: 0.5));
      await disposeApp(tester);
    });
  });
}

/// Painted centre-y of each keypad row, top to bottom.
List<double> _keyRowCentres(WidgetTester tester) => <double>{
  for (final box in _renderBoxes(tester, _keyInks()))
    paintedRect(box).center.dy,
}.toList()..sort();

/// Emits nothing, so the gate stays in its loading state.
class _HangingRepository extends ParentalGateRepository {
  @override
  Future<List<ParentalGateChallenge>> getItems() async =>
      const <ParentalGateChallenge>[];

  @override
  Stream<List<ParentalGateChallenge>> watchItems() =>
      const Stream<List<ParentalGateChallenge>>.empty();

  @override
  Stream<bool> watchGateEnabled() => Stream<bool>.value(true);

  @override
  Future<void> setGateEnabled({required bool enabled}) async {}

  @override
  ParentalGateChallenge challengeFor(DateTime utc) =>
      const ParentalGateChallenge(
        id: 'hanging',
        title: 'Grown-ups only',
        detail: 'This keeps settings and purchases safe.',
        a: 7,
        b: 6,
      );
}
