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
//   hearts row         centre y ≈448
//   "Today's quests"   ≈494
//   progress bar       y ≈527…542
//   first card top     ≈559
//
// PARKED, not passing. `NestPetStage`'s explicit-size mode composes the scene
// in `stageW = nestW / 0.62`, i.e. the nest box may occupy only 62 % of the
// stage (≈19 % margin each side). Inside the 350 px content box that caps the
// nest box at 217 → a ≈182 px visible outline, 16 px under the design's 198.
// Producing a 198 px outline needs a ≈236 box, whose scene is 381 px wide —
// 31 px wider than the content box, so it overflows and the internal
// `Positioned`s (computed against the nominal width) land the nest +34.7 px
// right of the axis and clip it at 320. Size and centring are therefore
// mutually exclusive until the shared stage ratio is fixed; that fix lives in
// `core/` and is filed as SHARED_REQUEST #13.
//
// Keep this file. Un-skip the proof when #13 lands:
//   flutter test --run-skipped --plain-name "the pet slot matches the design"
// Current (skipped) behaviour, measured here at real fonts — these reproduce
// the device captures exactly, which is what makes the pin trustworthy:
// slot 20…370 centre 195 ✓ · nest box 99.7…359.7 centre 229.7 (+34.7) ·
// hearts centre 494.0 (+46 vs design 448) · first card top 615.0 (+56 vs 559).

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
/// purpose: the shared fix will move the box off 260, and this pin must
/// survive that (the 260-specific finder in `kid_home_view_test.dart` is for
/// the current geometry).
final Finder _nestPicture = find
    .descendant(
      of: find.byType(PipNestFallback),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is SvgPicture && widget.width != null && widget.width! > 150,
      ),
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
      expect(
        nest.center.dx,
        closeTo(195, 1),
        reason:
            '.k3-pet centres the nest; box is '
            '${nest.left.toStringAsFixed(1)}…${nest.right.toStringAsFixed(1)}',
      );
      expect(
        nest.width,
        closeTo(236, 2),
        reason: "the box that paints the design's 198 px visible outline",
      );
      expect(pip.center.dx, closeTo(195, 1));

      // Design rows: hearts centre 448, first card top 559.
      expect(hearts.center.dy, closeTo(448, 2));
      expect(card1.top, closeTo(559, 2));

      await disposeApp(tester);
    }, skip: true);
  });
}
