// Shared: NestPetStage explicit-size mode centres the nest in the REAL box
// and matches K03's design geometry (SHARED_REQUEST #13/#15).
//
// K03's call (see the report): `nestWidth: 236, nestHeight: 156,
// fixedPipHeight: 152` — a 236-wide nest box painting the design's 198 px
// visible outline (`236 × 202/240`), seated ≈20 px deep on the rim, in a
// 236-tall block. These tests pin that contract at 320/390/430 with the
// K03 parameters, plus the `.speech` bubble height and the Rive/reduced
// motion fallback paths.
//
// Found no placeholder texts here: every assertion measures rects of the
// shared scene (never screen copy).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';

import '../../design_system/test_harness.dart';

/// K03's design slot (see docs/screens/_shared/pet_stage_explicit_REPORT.md).
const double _kNestWidth = 236;
const double _kNestHeight = 156;
const double _kPipHeight = 152;

const ValueKey<String> _pipProbeKey = ValueKey('petStageExplicitPipProbe');

/// The nest picture inside the shared scene (both halves render the same
/// box; the first is the back half at the nest top).
Finder _nestPicture() => find
    .descendant(
      of: find.byType(PipNestFallback),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is SvgPicture && widget.width != null && widget.width! > 150,
      ),
    )
    .first;

/// Pumps the explicit scene in a [slotWidth]-wide box centred on a [surface].
Future<void> _pumpSlot(
  WidgetTester tester,
  double slotWidth, {
  Size? surface,
  Widget? pip,
  bool riveEnabled = false,
  bool disableAnimations = false,
  String? speech,
}) async {
  final size = surface ?? const Size(390, 844);
  final scene = NestPetStage(
    riveEnabled: riveEnabled,
    nestWidth: _kNestWidth,
    nestHeight: _kNestHeight,
    fixedPipHeight: _kPipHeight,
    speech: speech,
    pip: pip,
  );
  final boxed = Center(
    child: SizedBox(width: slotWidth, child: scene),
  );
  await pumpNest(
    tester,
    disableAnimations
        ? MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: boxed,
          )
        : boxed,
    surface: size,
  );
  expect(
    tester.takeException(),
    isNull,
    reason: 'overflow or build error at $size / slot $slotWidth',
  );
}

Future<void> _loadNunito() async {
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'));
  await nunito.load();
}

void main() {
  setUpAll(_loadNunito);

  group('NestPetStage explicit size centres the design slot', () {
    testWidgets('visible outline 198 wide, centred on 195 at 390', (
      tester,
    ) async {
      await _pumpSlot(tester, 350, pip: const SizedBox(key: _pipProbeKey));
      final slot = tester.getRect(find.byType(PipNestFallback));
      expect(slot.left, closeTo(20, 0.5));
      expect(slot.right, closeTo(370, 0.5));

      final nest = tester.getRect(_nestPicture());
      expect(nest.width, closeTo(_kNestWidth, 0.5));
      expect(nest.center.dx, closeTo(195, 1));
      // The art fills its box, so the visible bowl outline is always
      // `nestW × visibleNestRatio` — the box the test just measured.
      final visible = nest.width * PipNestFallback.visibleNestRatio;
      expect(visible, closeTo(198, 2));

      final pip = tester.getRect(find.byKey(_pipProbeKey));
      expect(pip.center.dx, closeTo(195, 1));
    });

    testWidgets('stays centred with no overflow at 320 and 430', (
      tester,
    ) async {
      for (final entry in const [(320.0, 280.0), (430.0, 390.0)]) {
        final screenW = entry.$1;
        final slotW = entry.$2;
        await _pumpSlot(
          tester,
          slotW,
          surface: Size(screenW, 844),
          pip: const SizedBox(key: _pipProbeKey),
        );
        final slot = tester.getRect(find.byType(PipNestFallback));
        expect(slot.center.dx, closeTo(screenW / 2, 1));
        final nest = tester.getRect(_nestPicture());
        expect(nest.center.dx, closeTo(slot.center.dx, 1));
        expect(nest.left, greaterThanOrEqualTo(slot.left - 0.5));
        expect(nest.right, lessThanOrEqualTo(slot.right + 0.5));
        final pip = tester.getRect(find.byKey(_pipProbeKey));
        expect(pip.center.dx, closeTo(slot.center.dx, 1));
        expect(pip.left, greaterThanOrEqualTo(slot.left - 0.5));
        expect(pip.right, lessThanOrEqualTo(slot.right + 0.5));
      }
    });

    testWidgets('scales the whole scene down in a narrow slot', (tester) async {
      await _pumpSlot(tester, 200, pip: const SizedBox(key: _pipProbeKey));
      final slot = tester.getRect(find.byType(PipNestFallback));
      expect(slot.width, closeTo(200, 0.5));
      expect(slot.center.dx, closeTo(195, 1));
      // Uniform scale: nest/pip/rim/seat all × (200/236); only the 6/10 px
      // breathing constants stay absolute, so the height is the shared
      // helper's value (single source with the layout), not the linear one.
      final nest = tester.getRect(_nestPicture());
      expect(nest.width, closeTo(200, 0.5));
      expect(nest.center.dx, closeTo(slot.center.dx, 1));
      const s = 200 / _kNestWidth;
      final g = PipNestFallback.explicitGeometry(
        nestH: _kNestHeight * s,
        pipH: _kPipHeight * s,
        contactFrac: PipNestFallback.contactInSvg(PipStage.fledgling),
      );
      expect(slot.height, closeTo(g.stageH, 0.5));
      expect(nest.left, greaterThanOrEqualTo(slot.left - 0.5));
      expect(nest.right, lessThanOrEqualTo(slot.right + 0.5));
    });

    testWidgets('block height is the design 236 slot', (tester) async {
      await _pumpSlot(tester, 350, pip: const SizedBox(key: _pipProbeKey));
      final slot = tester.getRect(find.byType(PipNestFallback));
      expect(slot.height, closeTo(236, 2));
    });

    testWidgets('custom pip bottom overlaps the rim by 20', (tester) async {
      await _pumpSlot(tester, 350, pip: const SizedBox(key: _pipProbeKey));
      final nest = tester.getRect(_nestPicture());
      final pip = tester.getRect(find.byKey(_pipProbeKey));
      final rimY = nest.top + PipNestFallback.nestRimTopFraction * nest.height;
      expect(pip.bottom - rimY, closeTo(20, 1));
    });

    testWidgets('v1 SVG pip seats on the same rim line', (tester) async {
      await _pumpSlot(tester, 350);
      final slot = tester.getRect(find.byType(PipNestFallback));
      expect(slot.height, closeTo(236, 2));
      final nest = tester.getRect(_nestPicture());
      expect(nest.center.dx, closeTo(195, 1));
      final layers = find.descendant(
        of: find.byType(PipNestFallback),
        matching: find.byType(SvgPicture),
      );
      // Tree order: nest back, Pip, nest front. The v1 box seats by visible
      // contact (feet at svg-y 213/240 for the default fledgling stage, on
      // the contact line ≈1 px below the rim); its bottom — the baked-shadow
      // tip the front rim would bite — lands with the custom-pip bottom.
      final pipBox = tester.getRect(layers.at(1));
      expect(pipBox.height, closeTo(_kPipHeight, 0.5));
      expect(pipBox.center.dx, closeTo(195, 1));
      final rimY = nest.top + PipNestFallback.nestRimTopFraction * nest.height;
      expect(pipBox.bottom - rimY, closeTo(20, 3));
    });

    testWidgets('visibleNestWidth: 198 gives the same box', (tester) async {
      await pumpNest(
        tester,
        const Center(
          child: SizedBox(
            width: 350,
            child: NestPetStage(
              visibleNestWidth: 198,
              nestHeight: _kNestHeight,
              fixedPipHeight: _kPipHeight,
              riveEnabled: false,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final nest = tester.getRect(_nestPicture());
      expect(nest.width, closeTo(198 / PipNestFallback.visibleNestRatio, 1));
      expect(nest.center.dx, closeTo(195, 1));
    });

    testWidgets('Rive and reduced-motion paths share one geometry', (
      tester,
    ) async {
      Future<Rect> slotFor({required bool reduce}) async {
        await _pumpSlot(
          tester,
          350,
          riveEnabled: true,
          disableAnimations: reduce,
        );
        // The Rive runtime is absent in tests, so even the live path
        // degrades to the fallback scene — with the same explicit geometry.
        await tester.pump();
        expect(find.byType(PipNestFallback), findsOneWidget);
        return tester.getRect(find.byType(PipNestFallback));
      }

      final still = await slotFor(reduce: true);
      final live = await slotFor(reduce: false);
      expect(still.height, closeTo(236, 2));
      expect(live.height, closeTo(236, 2));
      expect(still, live);
    });
  });

  group('NestSpeechBubble matches .speech', () {
    testWidgets('body height is the design 44 at real fonts', (tester) async {
      await pumpNest(
        tester,
        const NestPetStage(
          speech: "Let's do some quests!",
          nestWidth: _kNestWidth,
          nestHeight: _kNestHeight,
          fixedPipHeight: _kPipHeight,
          riveEnabled: false,
        ),
      );
      expect(tester.takeException(), isNull);
      final body = find.ancestor(
        of: find.text("Let's do some quests!"),
        matching: find.byType(Container),
      );
      expect(body, findsOneWidget);
      // `.speech`: 8 px padding + ≈22 px natural Nunito line + 8 px padding
      // + 2 × 3 px border ≈ 44 — the design PNG measures 44, not 35 (see the
      // report: the 35 was the inner-white height misread as the body).
      expect(tester.getSize(body).height, closeTo(44, 2));
    });
  });
}
