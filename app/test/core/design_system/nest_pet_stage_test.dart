// Shared: NestPetStage explicit-size mode seats Pip IN the bowl and matches
// K03's design geometry (pet_stage_seat follow-up to pet_stage_explicit).
//
// K03's call (see the report): `nestWidth: 236, nestHeight: 188,
// fixedPipHeight: 152` — a 236×188 nest box painting the design's 198×86
// visible outline (`236 × 202/240` by `188 × 110/240`), PipAvatar feet ≈23 px
// below the rim (box ≈44 px below; feet 21.2 px above the box bottom), in a
// 236-tall block. These tests pin that contract at 320/390/430 with the K03
// parameters, the absolute K03 pins (nest 278, Pip 301, hearts 448) in a
// header+speech harness, plus the `.speech` bubble height and the
// Rive/reduced-motion fallback paths.
//
// Found no placeholder texts here: every assertion measures rects of the
// shared scene (never screen copy).
//
// pet-glow follow-up: the dark-mode glow is `--pet-glow` (tokens.css) — a
// 230×230 `PetStageGlow` radial fade (white@10% → transparent at 70%,
// centred on the stage x at 42% of the stage height), null (absent) in
// light — shared by the explicit + legacy Rive boxes and the SVG fallback.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';

import '../../design_system/test_harness.dart';

/// K03's design slot (see docs/screens/_shared/pet_stage_seat_REPORT.md).
const double _kNestWidth = 236;
const double _kNestHeight = 188;
const double _kPipHeight = 152;

/// v2 PipAvatar geometry in a 152-tall box (240-space s3_idle_1.svg):
/// tuft top 44.5 → head 28.2 below the box top; feet bottom 206.5 → feet
/// 21.2 above the box bottom (33.5/240 × 152). The design seats feet 23 px
/// below the rim (301 vs 278), so the box lands ≈44 px below it.
const double _pipTopPad = 44.5 / 240 * _kPipHeight;
const double _pipBottomPad = 33.5 / 240 * _kPipHeight;

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
  ThemeMode mode = ThemeMode.light,
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
    mode: mode,
  );
  expect(
    tester.takeException(),
    isNull,
    reason: 'overflow or build error at $size / slot $slotWidth',
  );
}

/// K03 harness: status (47) + header (78) + speech (62) put the pet slot top
/// at 187; the 236 block + 10.75 gap put hearts centre at ≈448, exactly like
/// `/kid-home` at 390×844 (real fonts for the 44 px bubble).
Future<void> _pumpK03Harness(
  WidgetTester tester, {
  bool riveEnabled = false,
  bool disableAnimations = false,
}) async {
  final pet = NestPetStage(
    riveEnabled: riveEnabled,
    nestWidth: _kNestWidth,
    nestHeight: _kNestHeight,
    fixedPipHeight: _kPipHeight,
    speech: "Let's do some quests!",
    pip: const PipAvatar(style: PipStyle.mochi, stage: 3, riveEnabled: false),
  );
  final column = Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 125),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: pet),
      const SizedBox(height: 10.75),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            NestHeart(filled: true),
            SizedBox(width: 8),
            NestHeart(filled: true),
            SizedBox(width: 8),
            NestHeart(filled: true),
            SizedBox(width: 8),
            NestHeart(filled: true),
            SizedBox(width: 8),
            NestHeart(filled: false),
          ],
        ),
      ),
    ],
  );
  final boxed = disableAnimations
      ? MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: column,
        )
      : column;
  await pumpNest(tester, boxed);
  expect(tester.takeException(), isNull, reason: 'overflow in K03 harness');
}

Future<void> _loadNunito() async {
  final nunito = FontLoader('Nunito')
    ..addFont(rootBundle.load('assets/fonts/Nunito-ExtraBold.ttf'));
  await nunito.load();
}

void main() {
  setUpAll(_loadNunito);

  group('NestPetStage explicit size centres the design slot', () {
    testWidgets('visible outline 198×86, centred on 195 at 390', (
      tester,
    ) async {
      await _pumpSlot(tester, 350, pip: const SizedBox(key: _pipProbeKey));
      final slot = tester.getRect(find.byType(PipNestFallback));
      expect(slot.left, closeTo(20, 0.5));
      expect(slot.right, closeTo(370, 0.5));

      final nest = tester.getRect(_nestPicture());
      expect(nest.width, closeTo(_kNestWidth, 0.5));
      expect(nest.height, closeTo(_kNestHeight, 0.5));
      expect(nest.center.dx, closeTo(195, 1));
      // The art fills its box: outline 202/240 wide by 110/240 tall.
      expect(nest.width * PipNestFallback.visibleNestRatio, closeTo(198, 2));
      expect(nest.height * 110 / 240, closeTo(86, 2));

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
      // Width/pip/rim/seat scale × (200/236); the 31.4/44.2 px explicit
      // constants stay absolute, so the height is the shared helper's value
      // (single source with the layout), not the linear one. The slot stays
      // 236 tall (fixed explicit block, no overflow) with a narrower nest.
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

    testWidgets('PipAvatar feet sit 23 px inside the bowl', (tester) async {
      await _pumpK03Harness(tester);
      final nest = tester.getRect(_nestPicture());
      final pip = tester.getRect(find.byType(PipAvatar));
      expect(pip.center.dx, closeTo(195, 1));
      final rimY = nest.top + PipNestFallback.nestRimTopFraction * nest.height;
      // Box ≈44 px below the rim; feet 21.2 above the box bottom ≈23 inside.
      expect(pip.bottom - rimY, closeTo(44.2, 2));
      expect(pip.bottom - _pipBottomPad - rimY, closeTo(23, 3));
    });

    testWidgets('v1 SVG pip seats its contact on the same feet line', (
      tester,
    ) async {
      await _pumpSlot(tester, 350);
      final slot = tester.getRect(find.byType(PipNestFallback));
      expect(slot.height, closeTo(236, 2));
      final nest = tester.getRect(_nestPicture());
      expect(nest.center.dx, closeTo(195, 1));
      final layers = find.descendant(
        of: find.byType(PipNestFallback),
        matching: find.byType(SvgPicture),
      );
      // Tree order: nest back, Pip, nest front. The v1 box seats its contact
      // (feet 213/240 fledgling) ≈23 px below the rim, inside the bowl like
      // the avatar; its box lands ≈40 px below (17.1 padding to contact).
      final pipBox = tester.getRect(layers.at(1));
      expect(pipBox.height, closeTo(_kPipHeight, 0.5));
      expect(pipBox.center.dx, closeTo(195, 1));
      final rimY = nest.top + PipNestFallback.nestRimTopFraction * nest.height;
      expect(pipBox.bottom - rimY, closeTo(40, 3));
      final contactFrac = PipNestFallback.contactInSvg(PipStage.fledgling);
      final contactY = pipBox.top + contactFrac * pipBox.height - rimY;
      expect(contactY, closeTo(23, 3));
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

  group('K03 harness pins the design rows (390×844, real fonts)', () {
    testWidgets('nest 278, Pip 301, hearts 448 (Rive-disabled)', (
      tester,
    ) async {
      await _pumpK03Harness(tester);
      final nest = tester.getRect(_nestPicture());
      expect(nest.width * PipNestFallback.visibleNestRatio, closeTo(198, 2));
      expect(nest.height * 110 / 240, closeTo(86, 2));
      expect(nest.center.dx, closeTo(195, 1));
      final rimY = nest.top + PipNestFallback.nestRimTopFraction * nest.height;
      // Outline 278→364 (86 tall).
      expect(rimY, closeTo(278, 2));
      expect(rimY + nest.height * 110 / 240, closeTo(364, 2));

      final pip = tester.getRect(find.byType(PipAvatar));
      expect(pip.center.dx, closeTo(195, 1));
      // Feet 301 (box − 21.2), head 199 (box + 28.2).
      expect(pip.bottom - _pipBottomPad, closeTo(301, 3));
      expect(pip.top + _pipTopPad, closeTo(199, 5));

      final row = tester.getRect(find.byType(Row).first);
      expect(row.center.dy, closeTo(448, 2));
    });

    testWidgets('nest 278, Pip 301, hearts 448 (Reduce Motion)', (
      tester,
    ) async {
      await _pumpK03Harness(tester, riveEnabled: true, disableAnimations: true);
      await tester.pump();
      expect(find.byType(PipNestFallback), findsOneWidget);
      final nest = tester.getRect(_nestPicture());
      final rimY = nest.top + PipNestFallback.nestRimTopFraction * nest.height;
      expect(rimY, closeTo(278, 2));
      expect(rimY + nest.height * 110 / 240, closeTo(364, 2));
      final pip = tester.getRect(find.byType(PipAvatar));
      expect(pip.center.dx, closeTo(195, 1));
      expect(pip.bottom - _pipBottomPad, closeTo(301, 3));
      expect(pip.top + _pipTopPad, closeTo(199, 5));
      final row = tester.getRect(find.byType(Row).first);
      expect(row.center.dy, closeTo(448, 2));
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
      // explicit report: the 35 was the inner-white height misread as body).
      expect(tester.getSize(body).height, closeTo(44, 2));
    });
  });

  group('pet glow matches --pet-glow (soft fade, not a solid disc)', () {
    Finder glows() => find.byKey(PetStageGlow.glowKey);

    /// Every glow box in the tree must be the 230×230 radial fade centred
    /// on its own stage: x = stage centre, y = 42% of the stage height
    /// (±2%). The stage geometry comes from the glow's own [PetStageGlow]
    /// params (exactly one ancestor per glow); its origin is the nearest
    /// width+height SizedBox's render box. The two coincide except inside a
    /// Rive box, where `Positioned.fill` stretches the fallback scene to
    /// the artboard box while the glow keeps its own 233-tall geometry —
    /// so the render rect (260) must NOT be used for the 42% computation.
    /// In the test env the Rive paths paint twice (box + the fallback the
    /// artboard degrades to); each is checked in its own geometry.
    void expectGlowsOnStage(WidgetTester tester) {
      final found = glows();
      expect(found, findsWidgets);
      for (var i = 0; i < tester.widgetList(found).length; i++) {
        final one = found.at(i);
        final glowAncestor = find.ancestor(
          of: one,
          matching: find.byType(PetStageGlow),
        );
        expect(glowAncestor, findsOneWidget);
        final params = tester.widget<PetStageGlow>(glowAncestor.first);
        final stages = find.ancestor(
          of: one,
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.width != null && w.height != null,
          ),
        );
        expect(stages, findsWidgets);
        // Order-proof: the inner stage renders smallest (or tied, with an
        // identical origin — `Positioned.fill` stretches it exactly).
        var originBox = tester.getRect(stages.first);
        for (var j = 1; j < tester.widgetList(stages).length; j++) {
          final rect = tester.getRect(stages.at(j));
          if (rect.width * rect.height < originBox.width * originBox.height) {
            originBox = rect;
          }
        }
        final origin = originBox.topLeft;
        final box = tester.getRect(one);
        expect(box.width, closeTo(PetStageGlow.size, 0.5));
        expect(box.height, closeTo(PetStageGlow.size, 0.5));
        final expectedCenter =
            origin +
            Offset(
              params.stageW / 2,
              PetStageGlow.centerYFraction * params.stageH,
            );
        expect(box.center.dx, closeTo(expectedCenter.dx, 1));
        expect(box.center.dy, closeTo(expectedCenter.dy, 0.02 * params.stageH));
        final deco =
            tester.widget<DecoratedBox>(found.at(i)).decoration
                as BoxDecoration;
        expect(deco.shape, BoxShape.circle);
        final gradient = deco.gradient;
        expect(gradient, isA<RadialGradient>());
        final radial = gradient! as RadialGradient;
        expect(radial.center, PetStageGlow.center);
        expect(radial.radius, closeTo(PetStageGlow.radius, 1e-9));
        expect(radial.stops, const [0, 0.7]);
        expect(radial.colors, hasLength(2));
        expect(radial.colors[0].a, closeTo(0.10, 0.02));
        expect(radial.colors[0], const Color(0x1AFFFFFF));
        expect(radial.colors[1], Colors.transparent);
      }
    }

    testWidgets('token: null in light, white@10% in dark', (tester) async {
      await _pumpSlot(tester, 350, pip: const SizedBox(key: _pipProbeKey));
      expect(tester.element(find.byType(NestPetStage)).nest.petGlow, isNull);
      await _pumpSlot(
        tester,
        350,
        pip: const SizedBox(key: _pipProbeKey),
        mode: ThemeMode.dark,
      );
      expect(
        tester.element(find.byType(NestPetStage)).nest.petGlow,
        const Color(0x1AFFFFFF),
      );
    });

    testWidgets('dark explicit SVG path: one 230×230 radial fade', (
      tester,
    ) async {
      await _pumpSlot(
        tester,
        350,
        mode: ThemeMode.dark,
        pip: const SizedBox(key: _pipProbeKey),
      );
      expect(glows(), findsOneWidget);
      expectGlowsOnStage(tester);
    });

    testWidgets('dark legacy SVG path: one 230×230 radial fade', (
      tester,
    ) async {
      await pumpNest(
        tester,
        const Center(
          child: SizedBox(width: 350, child: NestPetStage(riveEnabled: false)),
        ),
        mode: ThemeMode.dark,
      );
      expect(tester.takeException(), isNull);
      expect(glows(), findsOneWidget);
      expectGlowsOnStage(tester);
    });

    testWidgets('dark Rive boxes: every glow is the fade', (tester) async {
      // Explicit Rive box (K03 params). The Rive runtime is absent in tests,
      // so the inner PipInNest degrades to a second fallback scene — both
      // glows must still be the fade, on the same 236-tall slot.
      await _pumpSlot(tester, 350, mode: ThemeMode.dark, riveEnabled: true);
      await tester.pump();
      expect(find.byType(PipNestFallback), findsOneWidget);
      expectGlowsOnStage(tester);
      // Legacy Rive box. Same doubling in the test env (box + fallback).
      await pumpNest(
        tester,
        const Center(child: SizedBox(width: 350, child: NestPetStage())),
        mode: ThemeMode.dark,
      );
      expect(tester.takeException(), isNull);
      await tester.pump();
      expect(find.byType(PipNestFallback), findsOneWidget);
      expectGlowsOnStage(tester);
    });

    testWidgets('light: no glow in explicit or legacy paths', (tester) async {
      await _pumpSlot(tester, 350, pip: const SizedBox(key: _pipProbeKey));
      expect(glows(), findsNothing);
      await pumpNest(
        tester,
        const Center(
          child: SizedBox(width: 350, child: NestPetStage(riveEnabled: false)),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(glows(), findsNothing);
    });
  });
}
