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

import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';

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

      await disposeApp(tester);
    });
  });
}
