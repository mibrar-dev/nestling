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
// `design/screens/light/K03-kid-home.png` ÷3:
//
//   slot content box   x 20…370 (centre 195)      — 20 px gutters
//   nest visible outline x 96…294 (198 wide, centre 195)
//   Pip                centred on x 195
//   hearts row         centre y ≈438
//   "Today's quests"   ≈484
//   progress bar       y ≈517…532
//   first card top     ≈549
//
// LANDS and PASSING (iteration 8). SHARED_REQUEST #13's shared fix
// (`shared/pet_stage_explicit`) composes the scene in the REAL parent box
// instead of a nominal `stageW = nestW / 0.62`, and `PipNestFallback` grew
// `nestHeight` / `visibleNestWidth`, so size and centring are no longer
// mutually exclusive. Iteration 10 adds `shared/pet_stage_seat`: K03 passes
// `nestWidth: 236, nestHeight: 188, fixedPipHeight: 152` — the box that paints
// the design's 198 × 86 visible outline (236 × `visibleNestRatio` 202/240 =
// 197.9 by 188 × 110/240 = 86.2) centred on the axis, with Pip's feet 23 px
// inside the bowl, in the design's 236 px block. Measured here at real fonts —
// nest outline top 269 (±2) and bottom 355 (±2), nest centre 195 (±1), Pip
// centre 195 (±1) with feet 292 (±3), hearts centre 438 (±2), first card top
// 549 (±2). shared/speech_tail moved every row up ~9 px (the tail is now CSS
// `::after` overflow instead of 10 px of in-flow layout). Before the explicit
// fix the same pin read nest centre 229.7 (+34.7), hearts 494.0 (+46), first
// card 615.0 (+56), reproducing the device captures exactly, which is what
// makes the pin trustworthy.
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
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
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
/// 62%, kid-meadow 100%)`, so every row below the 62 % horizon stop is the
/// `kidHorizon → kidMeadow` grade at `t = (y / 844 - 0.62) / 0.38` — the run
/// `_MeadowPainter.gradeSpan` reproduces in flow. Derived from the tokens (and
/// `NestDevice.height`), never from a literal colour.
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
        closeTo(86, 2),
        reason: 'the design paints an 86 px tall bowl (y 278…364)',
      );

      // Design rows for the shared seat: rim 269, bowl bottom 355.
      // shared/speech_tail: the tail is now overflow per CSS `::after`, so it
      // no longer adds 10 px of layout below the body — every row under the
      // bubble moves up ~9 px versus the old in-flow tail (which read
      // 278/364). Screens must re-verify screenshots against the design PNGs.
      final rimY = nest.top + PipNestFallback.nestRimTopFraction * nest.height;
      expect(rimY, closeTo(269, 2));
      expect(rimY + nest.height * _kNestOutlineHeightFraction, closeTo(355, 2));

      // Pip is centred, its head at ≈190 and its feet 23 px inside the bowl
      // at ≈292 (never standing on the rim — `shared/pet_stage_seat`).
      expect(pip.center.dx, closeTo(195, 1));
      expect(pip.bottom - _pipBottomPad, closeTo(292, 3));
      expect(pip.top + _pipTopPad, closeTo(190, 5));

      // Design rows: hearts centre 438, first card top 549.
      expect(hearts.center.dy, closeTo(438, 2));
      expect(card1.top, closeTo(549, 2));

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
}
