// P09 · Quest editor — the approval toggle's 44 px tap area at REAL metrics.
//
// Iteration 3's test-stage report recorded a blind spot (P09-TEST-5): the
// toggle's taps were proven in a suite whose widget-test font wraps
// `Coins land after your thumbs-up` onto two lines, so the approval row was
// ~76 high there instead of the design's 40 — and a 59×44 hit slop cannot be
// clipped by a taller row, so the proof was font-dependent and could not see
// BUG-P09-10 (the slop being cut by the row's own bounds).
//
// This file loads the same bundled Inter/Nunito faces
// `quest_editor_view_geometry_test.dart` uses, so the row is the design's
// 16/22 + 13/18 = 40 high and the slop has to survive it.
//
// Iteration 6 rebuilt the shape to centre the track by layout (P09-TEST-9)
// while keeping BUG-P09-10's slop, and the code comment at that call site
// records why it is delicate: `RenderBox.hitTest` rejects any position outside
// a box's own size, so EVERY box between the card and the track must contain
// the 59×44 area. A tight `Positioned.fill` + `Padding` region lost the 2 px
// right tap; a tight vertical inset lost both 5 px taps. So the slop proofs
// run on every surface the app supports, not just the design frame — at 320 dp
// and at scale 1.3 the card is much taller and the centring maths is different,
// which is exactly where that class of regression hides.

import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/quests/quests_routes.dart';

import '../../test_scope.dart';

/// `.toggle` from `components.css`: a 51×31 track with a `::before` hit area
/// 4 px wider on each side and 7 px taller above and below (59×44, the
/// parent tap minimum).
const double _trackWidth = 51;
const double _trackHeight = 31;
const double _hitWidth = 59;
const double _hitHeight = NestDevice.tapParent;

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

/// Resizes the surface and settles a frame.
Future<void> _resize(
  WidgetTester tester,
  double width, [
  double scale = 1,
]) async {
  tester.view.physicalSize = Size(width * 3, 844 * 3);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  setUpAll(_loadBundledFonts);
  setUp(setUpTestScope);

  /// Taps [offset] from the track's centre and returns the value afterwards.
  Future<bool> toggleAt(WidgetTester tester, Offset offset) async {
    final before = tester.widget<NestToggle>(find.byType(NestToggle)).value;
    final track = tester.getRect(find.byType(NestToggle));
    await tester.tapAt(
      Offset(track.center.dx + offset.dx, track.center.dy + offset.dy),
    );
    await tester.pump();
    return tester.widget<NestToggle>(find.byType(NestToggle)).value != before;
  }

  testWidgets("the approval card is the design's 72 at real metrics", (
    tester,
  ) async {
    await pumpAppRoute(tester, QuestsRoutePaths.editor);

    // The premise of this file, asserted so a font regression cannot quietly
    // turn the proofs below into tautologies: with the real faces the card is
    // the design's 72 and its text block really is 16/22 + 13/18 = 40.
    expect(tester.getRect(find.byType(NestCard).at(1)).height, 72);
    expect(
      tester.getRect(find.text('Coins land after your thumbs-up')).height,
      18,
      reason: 'the sub-line is one line at real metrics, not two',
    );
    await disposeApp(tester);
  });

  for (final (width, scale) in const <(double, double)>[
    (390, 1),
    (320, 1),
    (390, 1.3),
    (320, 1.3),
  ]) {
    testWidgets(
      'at $width wide, scale $scale: a tap 5 px above/below and 2 px aside lands',
      (tester) async {
        await pumpAppRoute(tester, QuestsRoutePaths.editor);
        await _resize(tester, width, scale);

        // Exactly the offsets BUG-P09-10 reported: outside the track, inside the
        // `::before` box.
        expect(await toggleAt(tester, const Offset(0, -5)), isTrue);
        expect(await toggleAt(tester, const Offset(0, 5)), isTrue);
        expect(await toggleAt(tester, const Offset(2, 0)), isTrue);
        expect(await toggleAt(tester, const Offset(-2, 0)), isTrue);
        await disposeApp(tester);
      },
    );
  }

  testWidgets('the whole 59×44 slop around the 51×31 track is tappable', (
    tester,
  ) async {
    await pumpAppRoute(tester, QuestsRoutePaths.editor);
    final track = tester.getRect(find.byType(NestToggle));
    expect(track.width, _trackWidth);
    expect(track.height, _trackHeight);

    const slopX = (_hitWidth - _trackWidth) / 2; // 4
    const slopY = (_hitHeight - _trackHeight) / 2; // 6.5
    for (final offset in const <Offset>[
      Offset.zero,
      Offset(0, -slopY),
      Offset(0, slopY),
      Offset(-slopX, 0),
      Offset(slopX, 0),
      // The corners, where a clipped box would fail first.
      Offset(-slopX, -slopY),
      Offset(slopX, slopY),
    ]) {
      expect(
        await toggleAt(tester, offset),
        isTrue,
        reason: 'the slop at ($offset) must reach the toggle',
      );
    }
    await disposeApp(tester);
  });

  testWidgets('the track itself still paints on the design rect', (
    tester,
  ) async {
    // The switch is `Positioned(top: 20.5, right: s4)` inside the card now;
    // these are the design's numbers (303 / 620.5 / 51 / 31), asserted again
    // here so this file stands alone if the geometry suite is re-measured.
    await pumpAppRoute(tester, QuestsRoutePaths.editor);
    final track = tester.getRect(find.byType(NestToggle));
    expect(track.left, closeTo(303, 2));
    expect(track.top, closeTo(620.5, 2));
    expect(track.width, closeTo(_trackWidth, 2));
    expect(track.height, closeTo(_trackHeight, 2));
    expect(track.right, closeTo(354, 2));
    expect(track.bottom, closeTo(651.5, 2));
    await disposeApp(tester);
  });
}
