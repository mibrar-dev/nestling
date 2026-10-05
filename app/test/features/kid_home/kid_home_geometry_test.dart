// K03 · Kid home — design geometry at the design's real font metrics.
//
// The rest of `kid_home`'s suite runs on `flutter_test`'s default font, which
// is much wider than the bundled Nunito, so it can only assert relationships
// ("pet above hearts above section"). That is why this lives in its own file:
// loading the real faces here changes every text metric on the screen, and
// doing it in `kid_home_view_test.dart` would move the geometry of ~120
// passing tests. Same isolation `privacy_consent_geometry_test.dart` (P04)
// uses, for the same reason.
//
// What is pinned here is the pet slot and the rows below it, at 390×844, from
// `design/screens/light/K03-kid-home.png` ÷3 (measured; the same rows the
// orchestrator lists in ORCHESTRATOR_NOTES 07:40 / 10:14):
//
//   slot content box   x 20…370 (centre 195)      — 20 px gutters
//   nest visible outline x 96…294 (198 wide, centre 195)
//   nest rim / bowl bottom  y 278 / 385 (108 tall, re-measured shared/ds_cleanup)
//   Pip                centred on x 195, head ≈199, feet ≈301 (in the bowl)
//   hearts row         centre y 448
//   "Today's quests"   row centre y 494 (the 32 px chip is centred on it)
//   progress bar       y 527…542
//   first card top     y 559, every later card top +12, dock top y 720
//
// LANDS and PASSING (iteration 8). SHARED_REQUEST #13's shared fix
// (`shared/pet_stage_explicit`) composes the scene in the REAL parent box
// instead of a nominal `stageW = nestW / 0.62`, and `PipNestFallback` grew
// `nestHeight` / `visibleNestWidth`, so size and centring are no longer
// mutually exclusive. Iteration 10 adds `shared/pet_stage_seat`: K03 passes
// `nestWidth: 236, nestHeight: 188, fixedPipHeight: 152` — the box that paints
// the design's 198 × 86 visible outline (236 × `visibleNestRatio` 202/240 =
// 197.9 by 188 × 110/240 = 86.2) centred on the axis, with Pip's feet 23 px
// inside the bowl, in the design's 236 px block. Before the explicit fix the
// same pin read nest centre 229.7 (+34.7), hearts 494.0 (+46), first card
// 615.0 (+56), reproducing the device captures exactly, which is what makes
// the pin trustworthy.
//
// ITERATION 13: `shared/pet_bubble_gap` (main) added `NestPetStage.bubbleGap`
// and `shared/kid_meadow` moved the meadow into the shared background. K03 now
// passes the design's own `bubbleGap: 14` and its stage→hearts gap is the
// design's `--s4`, so the hero block's ROWS are exact: bubble 125…169, pet box
// 183…419, hearts 448.0, progress 527…542, card 1 at 559, dock 720.
// Re-measured shared/ds_cleanup (K03-BUG-16/17): the 236 × 236 nest paints
// the design's 198 × 108 bowl (rim 278, bottom 385, feet 301) flush in its
// slot — no bleed.
//
// Keep this file. Run it directly:
//   flutter test test/features/kid_home/kid_home_geometry_test.dart

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/presentation/widgets/kid_status_chip.dart';

import '../../test_scope.dart';

/// Loads the bundled faces so the metrics match a device run.
Future<void> loadBundledFonts() async {
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

/// The nest picture inside the shared fallback scene. Width-tolerant on
/// purpose so this pin survives a future box change here; the
/// `kid_home_view_test.dart` sibling finder pins the current 236 box.
final Finder _nestPicture = find
    .descendant(
      of: find.byType(PipNestFallback),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is SvgPicture && widget.width != null && widget.width! > 150,
      ),
    )
    .first;

/// v2 PipAvatar geometry in the design's 152-tall box (240-space
/// `mochi/s3_idle_1.svg`): tuft top 44.5 → head 28.2 below the box top; feet
/// bottom 206.5 → feet 21.2 above the box bottom. The design seats the feet
/// 23 px inside the bowl (301 vs the 278 rim), so these convert the avatar's
/// BOX rect into the two visible design rows.
const double _pipTopPad = 44.5 / 240 * 152;
const double _pipBottomPad = 33.5 / 240 * 152;

/// The bowl's painted outline height as a fraction of the nest box height
/// (`nest.svg` 240-space: outer bowl 150 ± 52 plus its 3 px stroke = 110).
const double _kNestOutlineHeightFraction = 110 / 240;

/// RepaintBoundary the meadow colour probe reads painted pixels through
/// (FIXES_10 #1). Same pattern as the P06 bottom-edge probe
/// (`test/features/pocket_money/pocket_money_setup_view_test.dart`).
const Key _pixelProbe = ValueKey<String>('k03_meadow_probe');

/// `pumpAppRoute` for `/kid-home` inside [_pixelProbe], so the PAINTED screen
/// surface can be sampled at absolute logical coordinates.
Future<void> _pumpForPixels(
  WidgetTester tester, {
  required ThemeMode theme,
  double bottomInset = 0,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  if (bottomInset > 0) {
    // The design's dock top (y 719) is measured on a device with the OS
    // home-indicator inset, so the lower content rows are read with it too.
    tester.view.padding = FakeViewPadding(bottom: bottomInset * 3);
    tester.view.viewPadding = FakeViewPadding(bottom: bottomInset * 3);
  }
  addTearDown(tester.view.reset);
  GetIt.instance<ThemeModeController>().selectMode(theme);
  await tester.pumpWidget(
    const RepaintBoundary(
      key: _pixelProbe,
      child: NestlingApp(initialRoute: '/kid-home'),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

/// Painted RGBA bytes at logical (x, y) of the app surface.
Future<List<int>> _pixelAt(WidgetTester tester, double x, double y) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_pixelProbe),
  );
  late List<int> pixel;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final rgba = (await image.toByteData())!;
    final offset = (y.round() * image.width + x.round()) * 4;
    pixel = <int>[
      rgba.getUint8(offset),
      rgba.getUint8(offset + 1),
      rgba.getUint8(offset + 2),
      rgba.getUint8(offset + 3),
    ];
  });
  return pixel;
}

/// The KID screen gradient's colour at absolute row [y].
///
/// `design/html-source/components.css` l.25 paints the KID screen as
/// `linear-gradient(180deg, kid-sky-top 0%, kid-sky-bottom 62%, kid-horizon
/// 62%, kid-meadow 100%)`, and since `shared/kid_meadow` that is literally
/// what `KidScope` paints, so the expected row is `kidHorizon → kidMeadow` at
/// `t = (y / 844 - 0.62) / 0.38`. K03 has no local band any more (the whole
/// feature-local meadow painter is gone — `ORCHESTRATOR_NOTES` 02:45), which is
/// what makes this a proof that the SHARED background is on screen.
Color _designMeadowAt(NestTokens tokens, double y) {
  const horizonStop = 0.62;
  final t = ((y / NestDevice.height) - horizonStop) / (1 - horizonStop);
  return Color.lerp(tokens.kidHorizon, tokens.kidMeadow, t.clamp(0.0, 1.0))!;
}

/// The dock's painted surface: a top-only 3 px ink border (design
/// `.k3-dock`), which distinguishes it from the quest cards.
final Finder _dockSurface = find.byWidgetPredicate((widget) {
  if (widget is! Container) {
    return false;
  }
  final decoration = widget.decoration;
  if (decoration is! BoxDecoration) {
    return false;
  }
  final border = decoration.border;
  return border is Border && border.top.width == 3 && border.left.width == 0;
});

/// The PAINTED quest-card surface of card [index] (the all-side ink border
/// inside the shared card's 6 px shadow reserve) — the rect the design's
/// `.quest-card` rows are measured against.
Finder _paintedCard(int index) => find
    .descendant(
      of: find.byType(NestKidQuestCard).at(index),
      matching: find.byWidgetPredicate((widget) {
        if (widget is! Container) {
          return false;
        }
        final box = widget.decoration;
        if (box is! BoxDecoration) {
          return false;
        }
        final border = box.border;
        return border is Border &&
            border.top.width > 0 &&
            border.left.width == border.top.width;
      }),
    )
    .first;

/// The bubble's painted body (`.speech`): the 18-radius bordered box, without
/// the tail that hangs below it.
final Finder _speechBody = find.descendant(
  of: find.byType(NestSpeechBubble),
  matching: find.byWidgetPredicate((widget) {
    if (widget is! Container) {
      return false;
    }
    final box = widget.decoration;
    return box is BoxDecoration &&
        box.borderRadius == BorderRadius.circular(18);
  }),
);

void main() {
  setUpAll(loadBundledFonts);

  group('K03 — design geometry at 390×844 (real Inter/Nunito)', () {
    testWidgets('the pet slot matches the design geometry', (tester) async {
      await setUpTestScope();
      await pumpAppRoute(tester, '/kid-home');

      final slot = tester.getRect(find.byType(PipNestFallback));
      final nest = tester.getRect(_nestPicture);
      final pip = tester.getRect(find.byType(PipAvatar));
      final hearts = tester.getRect(find.byType(NestHeart).first);
      final card1 = tester.getRect(find.byType(NestKidQuestCard).first);

      // The stage never exceeds the content box: no overflow, no clip.
      expect(slot.left, closeTo(20, 0.5));
      expect(slot.right, closeTo(370, 0.5));

      // Design: visible nest outline x 96…294 → 198 wide, centred on x 195.
      // Pinned on the PAINTED outline (box × the shared ratios), not on the
      // box, so a drift in `visibleNestRatio` shows up here instead of
      // passing silently (review finding 4).
      expect(
        nest.center.dx,
        closeTo(195, 1),
        reason:
            '.k3-pet centres the nest; box is '
            '${nest.left.toStringAsFixed(1)}…${nest.right.toStringAsFixed(1)}',
      );
      expect(nest.width * PipNestFallback.visibleNestRatio, closeTo(198, 2));
      expect(
        nest.height * _kNestOutlineHeightFraction,
        closeTo(108, 2),
        reason: 'the design paints a 108 px tall bowl (y 278…386)',
      );

      // Design rows for the shared seat: rim 278, bowl bottom 385.
      // Re-measured shared/ds_cleanup from the design PNG (K03-BUG-16/17):
      // the 236 × 236 nest sits flush (no bleed), so the rim lands at
      // 183 + 93.4 = 276.4 and the feet at 299.4 — within the UI ±2 px of
      // the design's 278 / 301 / 385.
      final rimY = nest.top + PipNestFallback.nestRimTopFraction * nest.height;
      expect(rimY, closeTo(278, 2), reason: 'the design paints the rim at 278');
      expect(
        rimY + nest.height * _kNestOutlineHeightFraction,
        closeTo(385, 2),
        reason: 'the design paints the bowl bottom at 385',
      );

      // Pip is centred, its head at ≈199 and its feet 23 px inside the bowl
      // at ≈301 (never standing on the rim — `shared/pet_stage_seat`). The
      // v2 `PipAvatar` head sits ~2 px above the design's v1 art, so the head
      // pin allows 3 px while the rim/feet stay at the UI ±2 px.
      expect(pip.center.dx, closeTo(195, 1));
      expect(
        pip.bottom - _pipBottomPad,
        closeTo(301, 2),
        reason: 'the design seats the feet at 301',
      );
      expect(pip.top + _pipTopPad, closeTo(199, 3));

      // ORCHESTRATOR_NOTES 15:02 targets, now exact (±0.5): the design's
      // `.speech` is 125…169 (44 tall) and `.k3-pet`'s 236-tall box follows
      // its 14 px margin at 183…419. These two are what `bubbleGap: 14` and
      // `_kStageToHearts = NestSpacing.s4` bought, and they are what a
      // regression in either would break.
      final bubble = tester.getRect(find.byType(NestSpeechBubble));
      expect(bubble.top, closeTo(125, 0.5));
      expect(bubble.bottom, closeTo(169, 0.5));
      expect(slot.top, closeTo(183, 0.5), reason: '.k3-pet box top');
      expect(slot.bottom, closeTo(419, 0.5), reason: '.k3-pet box bottom');

      // Design rows: hearts centre 448, first card top 559.
      expect(hearts.center.dy, closeTo(448, 2));
      expect(card1.top, closeTo(559, 2));

      // UI VERDICT RULE corroboration: the progress bar's bordered box is
      // the design's y 527…542 (ORCHESTRATOR_NOTES exact geometry).
      final progress = tester.getRect(find.byType(NestProgress));
      expect(progress.top, closeTo(527, 2));
      expect(progress.bottom, closeTo(542, 2));

      await disposeApp(tester);
    });

    // UI VERDICT RULE: "a UI check may only PASS when every element is within
    // ±2 px of the design position … A uniform vertical shift of the whole
    // screen is a FAIL, even if each element looks the same. Report the
    // measured y of the screen title, the first control and each card top."
    //
    // The pet-slot test above already pins the hero block, the hearts row
    // (448) and the progress bar (527…542). This one closes the rest of the
    // column — the section row, EVERY card top, the peek above the dock and
    // the dock's own top — so a shift anywhere in the column is caught by a
    // named row instead of by eye. Absolute targets come from
    // ORCHESTRATOR_NOTES' exact geometry (07:40): hearts 448, title 494,
    // progress 527…542, first card 559, dock top ≈720, card 2 peeking above
    // the dock. The OS bottom inset is emulated (34 px) because the design's
    // dock top is measured on a device with it.
    testWidgets('every row below the nest lands within 2 px of the design', (
      tester,
    ) async {
      await setUpTestScope();
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      tester.view.padding = const FakeViewPadding(bottom: 34 * 3);
      tester.view.viewPadding = const FakeViewPadding(bottom: 34 * 3);
      addTearDown(tester.view.reset);
      await pumpAppRoute(tester, '/kid-home');

      // The section row: the design's title baseline row is 494, read the same
      // way the orchestrator read the hearts row (its vertical centre — the
      // 32 px chip is centred on the title, so the row centre is font-proof).
      final chip = tester.getRect(find.byType(KidStatusChip).first);
      expect(
        chip.center.dy,
        closeTo(494, 2),
        reason: "the 'Today\u2019s quests' row is the design's y 494",
      );
      expect(chip.height, closeTo(32, 0.5), reason: '.kchip is 32 px tall');

      // Card 1 at the design's y 559, then EVERY card top: the design shows
      // card 2 peeking above the dock and the rest scroll, so the painted
      // tops must keep the design's `.k3-quests { gap: 12px }` rhythm from
      // card 1 down rather than drifting.
      final cards = find.byType(NestKidQuestCard).evaluate().length;
      expect(cards, 6);
      final tops = <double>[
        for (var i = 0; i < cards; i++) tester.getRect(_paintedCard(i)).top,
      ];
      expect(tops.first, closeTo(559, 2), reason: 'first card top');
      for (var i = 1; i < tops.length; i++) {
        final previous = tester.getRect(_paintedCard(i - 1));
        expect(
          tops[i] - previous.bottom,
          closeTo(12, 0.5),
          reason: 'painted gap between card $i and card ${i + 1}',
        );
      }

      // The dock owns the OS inset: its top is the design's y ≈720.
      final dock = tester.getRect(_dockSurface);
      expect(dock.top, closeTo(720, 2), reason: '.k3-dock top on the device');
      expect(dock.bottom, closeTo(NestDevice.height, 0.5));

      // Card 2 peeks above the dock, as the design shows: its top is above the
      // bar and its bottom below it, so the list is never fully hidden.
      final card2 = tester.getRect(_paintedCard(1));
      expect(
        card2.top,
        lessThan(dock.top),
        reason: 'card 2 starts above the dock',
      );
      expect(
        card2.bottom,
        greaterThan(dock.top),
        reason: 'card 2 must peek above the dock',
      );

      await disposeApp(tester);
    });
  });

  // `shared/speech_tail` (main b1137f3) turned the bubble's tail from a
  // 10.25 px IN-FLOW box into a CSS `.speech::after` overflow: the bubble now
  // lays out 10.25 px shorter, which lifted the pet block and every row below
  // it, and K03 took it back with `_kStageToHearts = 21`. That compensation is
  // only correct while the tail stays out of flow, so the contract is pinned
  // here — on the bytes, because "is the tail painted" is a pixel fact.
  //
  // `.speech::after`: `bottom: -9px; left: 50%; border: 9px solid transparent;
  // border-top-color: ink; border-bottom: 0` → an 18 px wide, 9 px tall ink
  // triangle hanging below the body. 5_ui iteration 9 measured the app's tail
  // 10 px too tall; the row count below is what catches that again.
  testWidgets('the speech tail is an out-of-flow 9 px ink triangle', (
    tester,
  ) async {
    await setUpTestScope();
    await _pumpForPixels(tester, theme: ThemeMode.light);
    final tokens = Theme.of(tester.element(find.byType(NestSpeechBubble)))
        .extension<NestTokens>()!;
    final bubble = tester.getRect(find.byType(NestSpeechBubble));
    final body = tester.getRect(_speechBody);

    // The tail must NOT be in flow: it adds zero height to the bubble, or
    // `_kStageToHearts` compensates for a gap that is no longer there and every
    // row below the nest moves.
    expect(
      bubble.height - body.height,
      closeTo(0, 0.5),
      reason: 'the tail overflows the body instead of sizing it',
    );

    // The tail is painted, in ink, below the body's bottom border.
    final centreX = body.center.dx;
    final ink = tokens.ink;
    bool isInk(List<int> px) =>
        (px[0] - ink.r * 255).abs() <= 2 &&
        (px[1] - ink.g * 255).abs() <= 2 &&
        (px[2] - ink.b * 255).abs() <= 2;
    var run = 0;
    for (var y = body.bottom + 1; y <= body.bottom + 12; y++) {
      if (isInk(await _pixelAt(tester, centreX, y))) {
        run++;
      }
    }
    expect(
      run,
      inInclusiveRange(4, 9),
      reason:
          'the tail column is ink for $run px below the body; '
          '`.speech::after` is 9 px (5_ui iteration 9 measured +10 px)',
    );

    await disposeApp(tester);
  });

  // FIXES_10 #1 (ORCHESTRATOR_NOTES 10:52, dark meadow, "4th time"): the lower
  // content area behind the progress bar and the quest cards must paint the
  // design's `kid-horizon → kid-meadow` grade — NOT flat navy. Pinned here at
  // the two absolute rows the orchestrator named, (10, 600) and (10, 700), in
  // BOTH themes (light was already right; the pin keeps it there).
  //
  // The numbers are read from the design PNGs with PIL (÷3 for logical px):
  //   dark  (10,600) rgb(35,56,81)   (10,700) rgb(33,63,72)
  //   light (10,600) rgb(223,243,214) (10,700) rgb(210,238,198)
  // which is exactly the CSS lerp of the two tokens at those rows (t ≈ 0.24 and
  // t ≈ 0.55 of the 62 %→100 % run) — NOT a flat `--kid-meadow` #1E4A3A, which
  // is what the bottom of the run looks like (row 844, below the dock). A
  // literal #1E4A3A at row 600 would sit 17-31 levels off the design in
  // red/green, so the assertion is the token grade at the design's row and the
  // design's own RGB goes in the reason.
  group('K03 — lower meadow colour at the design rows (FIXES_10 #1)', () {
    const themes = <(String, ThemeMode)>[
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ];
    const designRows = <(double, String)>[
      (600, 'light rgb(223,243,214) · dark rgb(35,56,81)'),
      (700, 'light rgb(210,238,198) · dark rgb(33,63,72)'),
    ];
    for (final (themeName, theme) in themes) {
      for (final (y, designRgb) in designRows) {
        testWidgets(
          '$themeName: (10, $y) is the graded meadow, not flat navy',
          (tester) async {
            await setUpTestScope();
            await _pumpForPixels(tester, theme: theme);
            final tokens = Theme.of(tester.element(find.byType(NestProgress)))
                .extension<NestTokens>()!;
            final sampled = await _pixelAt(tester, 10, y);
            final expected = _designMeadowAt(tokens, y);
            final got = 'rgb(${sampled[0]},${sampled[1]},${sampled[2]})';
            final why = 'design $designRgb = the CSS grade at row $y';
            expect(sampled[3], 255, reason: 'the meadow at (10, $y) is opaque');
            // ±2/255: the design PNG's own row is within 1 level of the token
            // grade (8-bit rounding of the CSS lerp), plus Skia rounding.
            for (final (channel, value, byte) in <(String, double, int)>[
              ('red', expected.r, sampled[0]),
              ('green', expected.g, sampled[1]),
              ('blue', expected.b, sampled[2]),
            ]) {
              expect(
                byte,
                closeTo(value * 255, 2),
                reason:
                    '$channel at (10, $y) must follow the '
                    'kid-horizon→kid-meadow grade; got $got ($why)',
              );
            }
            final horizonG = (tokens.kidHorizon.g * 255).round();
            final horizonB = (tokens.kidHorizon.b * 255).round();
            // The regression this pins: flat navy. Below the 62 % horizon stop
            // green must RISE and blue must FALL away from `kidHorizon`, so a
            // band that stopped grading (or graded over its own in-flow height)
            // fails here even though the band's top tone is unchanged.
            // The regression this pins: flat navy / a band that stopped grading
            // (or graded over its own in-flow height instead of the design's
            // 321 px run). Below the 62 % horizon stop the row must have moved
            // OFF `kidHorizon` in the direction `kidMeadow` lies, by more than
            // 2/255 — a tone check that holds in both themes, where the grade
            // rises (dark: navy → teal) or falls (light: pale → green).
            int moved(int from, int to, int at) {
              final direction = to > from ? 1 : -1;
              return direction * (at - from);
            }

            final meadowG = (tokens.kidMeadow.g * 255).round();
            final meadowB = (tokens.kidMeadow.b * 255).round();
            expect(
              moved(horizonG, meadowG, sampled[1]),
              greaterThan(2),
              reason:
                  'a flat horizon row keeps kid-horizon green ($horizonG) '
                  'instead of grading toward kid-meadow green ($meadowG); '
                  'got $got',
            );
            expect(
              moved(horizonB, meadowB, sampled[2]),
              greaterThan(2),
              reason:
                  'the grade must also move blue off kid-horizon blue '
                  '($horizonB) toward kid-meadow blue ($meadowB); got $got',
            );
            await disposeApp(tester);
          },
        );
      }
    }
  });

  // ITERATION 13 (`shared/kid_meadow`, ORCHESTRATOR_NOTES 02:45): K03's
  // feature-local in-flow meadow band is GONE. The design paints the lower
  // content area as the SCREEN background (`components.css` l.25), so
  // `KidScope` owns it and nothing in the feature paints a hill or a grade.
  //
  // Two properties follow from "it is the background", and NEITHER is provable
  // from the widget tree (the structural pins in `kid_home_view_test.dart`
  // pass on a band that merely has a different class name):
  //
  //  1. the grade must reach EVERY row of the run. A band that compresses the
  //     design's 321 px run into its own in-flow height stops grading and ends
  //     flat `kid-meadow` — which is exactly the dark-mode "flat navy" bug the
  //     orchestrator called out four times (FIXES_8…_10, ORCHESTRATOR_NOTES
  //     10:52).
  //  2. it must not MOVE when the quest list scrolls. An in-flow band scrolls
  //     away from under the cards; the design's meadow is the screen's, so
  //     row 700 reads the same before and after a scroll to the end. This is
  //     what catches the band coming back under any name.
  //
  // Both are measured on the painted bytes, in BOTH themes, at the design's
  // absolute rows — the numbers below were read from
  // `design/screens/{light,dark}/K03-kid-home.png` ÷3 with PIL at x = 10 (the
  // 20 px gutter, so no card, chip or the dock's ink border is in the sample):
  //
  //   y 522  light rgb(242,250,255) · dark rgb( 44, 53,114)  = kid-sky-bottom
  //   y 523  light rgb(234,247,226) · dark rgb( 37, 51, 89)  = kid-horizon  (hard stop)
  //   y 600  light rgb(224,244,214) · dark rgb( 36, 57, 82)
  //   y 700  light rgb(211,239,199) · dark rgb( 33, 64, 72)
  //   y 718  light rgb(208,238,196) · dark rgb( 33, 65, 71)  = still the run
  //
  // Row 719 is the dock's own 3 px ink border and 722+ its surface, so the run
  // stops at 718. The design's last rows (810…843) are the hill-front tint
  // below a dock that ENDS at 809 — the green strip the owner rejected
  // (ORCHESTRATOR_NOTES "OWNER FEEDBACK"), so that band is deliberately NOT
  // pinned; the bottom-edge group proves the dock surface runs to 844 instead.
  group('K03 — the meadow is the shared screen background (shared/kid_meadow)', () {
    const themes = <(String, ThemeMode)>[
      ('light', ThemeMode.light),
      ('dark', ThemeMode.dark),
    ];
    for (final (themeName, theme) in themes) {
      // Every row of the design's run, so "the grade reaches the whole lower
      // screen" is a measured fact rather than a comment about the painter.
      const runRows = <double>[523, 530, 560, 600, 650, 690, 710, 718];
      const designRgb = <int, String>{
        523: 'rgb(234,247,226) · rgb(37,51,89)',
        530: 'rgb(233,247,225) · rgb(37,52,89)',
        560: 'rgb(229,246,221) · rgb(37,54,86)',
        600: 'rgb(224,244,214) · rgb(36,57,82)',
        650: 'rgb(217,241,207) · rgb(35,60,77)',
        690: 'rgb(212,240,200) · rgb(34,63,73)',
        710: 'rgb(209,239,197) · rgb(33,65,71)',
        718: 'rgb(208,238,196) · rgb(33,65,71)',
      };

      testWidgets(
        '$themeName: the 62% hard stop and the whole run to the dock are painted',
        (tester) async {
          await setUpTestScope();
          await _pumpForPixels(tester, theme: theme, bottomInset: 34);
          final tokens = Theme.of(tester.element(find.byType(NestProgress)))
              .extension<NestTokens>()!;

          // The horizon stop is HARD: the row above 62 % is still sky-bottom,
          // row 523 is `kid-horizon` exactly. A band that eased into the
          // meadow (or started its run somewhere else) breaks this pair.
          final sky = await _pixelAt(tester, 10, 522);
          for (final (channel, value, byte) in <(String, double, int)>[
            ('red', tokens.kidSkyBottom.r, sky[0]),
            ('green', tokens.kidSkyBottom.g, sky[1]),
            ('blue', tokens.kidSkyBottom.b, sky[2]),
          ]) {
            expect(
              byte,
              closeTo(value * 255, 2),
              reason: 'row 522 is still kid-sky-bottom ($channel)',
            );
          }

          for (final y in runRows) {
            final sampled = await _pixelAt(tester, 10, y);
            final expected = _designMeadowAt(tokens, y);
            final got = 'rgb(${sampled[0]},${sampled[1]},${sampled[2]})';
            expect(sampled[3], 255, reason: 'the meadow at (10, $y) is opaque');
            for (final (channel, value, byte) in <(String, double, int)>[
              ('red', expected.r, sampled[0]),
              ('green', expected.g, sampled[1]),
              ('blue', expected.b, sampled[2]),
            ]) {
              expect(
                byte,
                closeTo(value * 255, 2),
                reason:
                    '$channel at (10, $y) must follow the shared '
                    'kid-horizon→kid-meadow grade; got $got '
                    '(design ${designRgb[y.round()]})',
              );
            }
          }

          // The shared hills must stay BEHIND the dock, exactly as the HTML puts
          // them (`.meadow`: bottom 0, 136 tall → crest at x 10 ≈ y 764, under
          // the dock that starts at 719). If the hills were raised, made taller
          // or pulled up in flow, their flat `kid-meadow` / hill-front tint
          // would land in the 708…718 window the design paints as the run.
          //
          // Green and blue are the discriminating channels: the run sits
          // 6…23 levels off flat `kid-meadow` across these rows and both
          // themes, with blue the sturdier of the two (≥12 everywhere; light's
          // green only 6…7). So the assertion is "at least one channel is well
          // clear of the flat tone" — a leaked hill scores 0 on both. Red is
          // not used: dark's run and dark's meadow share a red level (33 vs 30
          // at row 700), which would be a false alarm rather than a signal.
          for (final y in <double>[700, 710, 718]) {
            final sampled = await _pixelAt(tester, 10, y);
            final flat = _designMeadowAt(
              tokens,
              NestDevice.height, // fully graded = kid-meadow
            );
            final offGreen = (sampled[1] - flat.g * 255).abs().round();
            final offBlue = (sampled[2] - flat.b * 255).abs().round();
            expect(
              <int>[offGreen, offBlue].reduce((a, b) => a > b ? a : b),
              greaterThan(8),
              reason:
                  'row $y is the graded run in the design, not the flat hill '
                  'tone: off kid-meadow by green $offGreen / blue $offBlue — '
                  'the shared hill has leaked above the dock',
            );
          }

          await disposeApp(tester);
        },
      );

      // The design's meadow is the SCREEN's, so scrolling the quest list must
      // not move it. An in-flow band does move: after a scroll to the end its
      // own run would be gone from under the cards and the row would fall back
      // to a flat tone or to whatever is behind the list.
      testWidgets('$themeName: scrolling the quests does not move the meadow', (
        tester,
      ) async {
        await setUpTestScope();
        await _pumpForPixels(tester, theme: theme, bottomInset: 34);
        final tokens = Theme.of(tester.element(find.byType(NestProgress)))
            .extension<NestTokens>()!;

        const before = <double>[600, 700];
        final start = <double, List<int>>{
          for (final y in before) y: await _pixelAt(tester, 10, y),
        };
        // Control for the frame of reference: the progress bar IS in the
        // scrolling content, so it must end up `offset` px higher. Without this
        // the "the meadow did not move" rows could be passing simply because
        // the sample rows track the content instead of the screen.
        final progressBefore = tester.getTopLeft(find.byType(NestProgress)).dy;

        // The list must actually scroll for this to mean anything: the design
        // shows 6 cards and only 1.5 fit above the dock.
        final list = find.byType(Scrollable).first;
        expect(
          tester.state<ScrollableState>(list).position.maxScrollExtent,
          greaterThan(200),
          reason: 'the quest list has to overflow for the scroll to be a test',
        );
        for (var i = 0; i < 12; i++) {
          await tester.drag(list, const Offset(0, -300));
          await tester.pump();
        }
        // Each drag past the end of the list leaves the content in an
        // overscroll bounce (~15 px of drag per 300 px of gesture) that a
        // single `pump` samples mid-flight — the position is already clamped
        // at `maxScrollExtent` while the bar keeps travelling. Settle the
        // spring before measuring anything. Safe here (unlike the loading
        // states, where an endless spinner would never settle) because the
        // loaded screen is already on the widget tree with its 6 cards.
        await tester.pumpAndSettle(const Duration(milliseconds: 50));
        // Read the position AFTER the drags and the settle: the lazily-built
        // card column can rebuild the scroll view mid-drag, and a reference
        // captured before it would go stale.
        final position = tester.state<ScrollableState>(list).position;
        expect(
          position.pixels,
          closeTo(position.maxScrollExtent, 1),
          reason: 'scrolled to the end of the list',
        );
        expect(
          position.pixels,
          greaterThan(200),
          reason:
              'the content must really have moved, or "the meadow did not '
              'move" would be vacuous (design: 6 cards, ~1.5 visible)',
        );

        // The control: the progress bar travelled the full scroll offset, so
        // the sample rows below really do watch the SCREEN, not the content.
        expect(
          tester.getTopLeft(find.byType(NestProgress)).dy,
          closeTo(progressBefore - position.pixels, 2),
          reason:
              'the progress bar is in the scroll view, so it moves by exactly '
              'the scroll offset (${progressBefore.toStringAsFixed(1)} - '
              '${position.pixels.toStringAsFixed(1)})',
        );

        for (final y in before) {
          final now = await _pixelAt(tester, 10, y);
          final expected = _designMeadowAt(tokens, y);
          for (final (channel, value, byte, was)
              in <(String, double, int, int)>[
                ('red', expected.r, now[0], start[y]![0]),
                ('green', expected.g, now[1], start[y]![1]),
                ('blue', expected.b, now[2], start[y]![2]),
              ]) {
            expect(
              byte,
              closeTo(value * 255, 2),
              reason:
                  '$channel at (10, $y) after scrolling to the end must still '
                  'be the shared grade — an in-flow meadow band scrolls away '
                  'with the cards; got rgb(${now[0]},${now[1]},${now[2]})',
            );
            expect(
              byte,
              closeTo(was, 1),
              reason:
                  'the background at row $y did not move when the content '
                  'scrolled ($channel: $was → $byte)',
            );
          }
        }

        await disposeApp(tester);
      });
    }
  });
}
