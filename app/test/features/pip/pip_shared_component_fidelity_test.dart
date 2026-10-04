// K06 · Pip's nest — the ITERATION-4 component switch changed nothing visible.
//
// `4_review.md` finding 1 (major) ruled that iteration 3 had adopted only 2 of
// the 5 things `shared/shared_batch7` + `ORCHESTRATOR_NOTES` 13:52 mandate.
// Iteration 4 did the rest, deleting three local widgets:
//
//   PipCareButton        → NestKidButton(trailing:)   (152 lines deleted)
//   PipNestSlot          → NestPetStage(…)             ( 98 lines deleted)
//   _DashedBorderPainter → NestDashedBorder
//
// A swap like that is exactly where a screen silently changes size: the shared
// kid button wraps its painted card in 6 px of shadow room, so its widget box
// is the design's 91 px card PLUS 6, and the view compensates with
// `SizedBox(height: s4 - gap6)`. If that arithmetic were off by one pixel,
// every band below the care row would drift — which a UI check sees as a heat
// blob and a reader explains away.
//
// So this file pins the switch from the DESIGN side, with the numbers read off
// `K06-pip.html` and the design PNG:
//   * the care row keeps the design's pitch — painted card 91 px at the design
//     y, and the wardrobe row still starts exactly one `s4` below it;
//   * the care row's internals are unchanged: 24 px lead icon, a 20 px label
//     line box, the 16 px `.k6-coin img`, the 19 px `.k6-free` pill;
//   * the pet slot keeps `nestWidth: 230`, `pipBottom: 81` and the 134 px Pip
//     (the Pip overhangs the slot by 9 px at the top, as the design's
//     `bottom: 81 + height: 134` inside a 206 px slot requires);
//   * the locked tile's dash is still 6/3 on the kid border token.
//
// Real fonts are loaded first: the placeholder glyphs are one em wide and would
// change every measured text box.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipStage;
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_free_pill.dart';

import '../../test_scope.dart';

const double _tol = 1.5;

// The design's `.k6-care .btn-kid` numbers (PNG ÷3, `K06-pip.html:30`):
/// `min-height: 88px; padding: 8px 4px; gap: 3px; font-size: 17px;
///  line-height: 20px` with a 24 px icon and a 3 px border.
const double _designCardHeight = 91;
const double _designLeadIcon = 24;
const double _designLabelLine = 20;
const double _designCoinIcon = 16;
const double _designFreePillHeight = 19;

/// `.k6-pet` / `.k6-pet .pip` (`K06-pip.html:21-23`).
const double _designSlotWidth = 230;
const double _designSlotHeight = 206;
const double _designPipSize = 134;
const double _designPipBottom = 81;

/// How far the Pip overhangs the TOP of the slot: its 134 px height inside the
/// 125 px left above `bottom: 81`.
const double _designPipOverhang =
    _designPipSize - (_designSlotHeight - _designPipBottom);

/// The shared kid button's shadow room (`NestKidButton`'s `Padding(bottom:
/// gap6)`), which the view absorbs so the visual pitch stays `s4`.
const double _shadowRoom = NestSpacing.gap6;

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

void main() {
  setUpAll(loadBundledFonts);

  setUp(() async {
    await setUpTestScope();
  });

  Future<void> pump(WidgetTester tester) async {
    await pumpAppRoute(tester, '/pip');
    expect(tester.takeException(), isNull);
  }

  /// The PAINTED card inside a keyed care button (the design-visible rect).
  Rect card(WidgetTester tester, String id) => tester.getRect(
    find
        .descendant(
          of: find.byKey(Key(id)),
          matching: find.byType(AnimatedContainer),
        )
        .first,
  );

  group('the care row kept the design pitch', () {
    testWidgets('painted card 91 px; the box is that card + the shadow room', (
      tester,
    ) async {
      await pump(tester);

      for (final id in const <String>['k06-feed', 'k06-play', 'k06-bath']) {
        final painted = card(tester, id);
        final box = tester.getRect(find.byKey(Key(id)));

        expect(
          painted.height,
          closeTo(_designCardHeight, _tol),
          reason: '$id painted card',
        );
        expect(
          box.height,
          closeTo(_designCardHeight + _shadowRoom, _tol),
          reason: '$id widget box = the card + the shared 6 px shadow room',
        );
        expect(
          painted.top,
          closeTo(box.top, 0.01),
          reason: '$id: the room is BELOW the card, never above it',
        );
        expect(
          painted.left,
          closeTo(box.left, _tol),
          reason: '$id: no horizontal room',
        );
      }
      await disposeApp(tester);
    });

    testWidgets('the wardrobe row still starts one s4 below the painted card', (
      tester,
    ) async {
      // The 6 px the shared button adds is absorbed by the view, so this is
      // the proof that the compensation is exact and not 1 px optimistic.
      await pump(tester);

      final lowest = <double>[
        for (final id in const <String>['k06-feed', 'k06-play', 'k06-bath'])
          card(tester, id).bottom,
      ].reduce((a, b) => a > b ? a : b);
      final section = tester.getRect(find.byKey(const Key('k06-section')));

      expect(
        section.top,
        closeTo(lowest + NestSpacing.s4, _tol),
        reason: 'the s4 after the care row is measured from the PAINTED card',
      );
      await disposeApp(tester);
    });

    testWidgets('the care internals are the design sizes', (tester) async {
      await pump(tester);

      // 24 px lead icon, 16 px `.k6-coin img`, 20 px label line box.
      for (final id in const <String>['k06-feed', 'k06-bath']) {
        final icons = find.descendant(
          of: find.byKey(Key(id)),
          matching: find.byType(SvgPicture),
        );
        final sizes = icons
            .evaluate()
            .map((e) => tester.getSize(find.byWidget(e.widget)))
            .toList();
        expect(
          sizes.first.width,
          closeTo(_designLeadIcon, 0.01),
          reason: '$id lead icon',
        );
        expect(
          sizes.last.width,
          closeTo(_designCoinIcon, 0.01),
          reason: '$id coin trailing',
        );
      }
      for (final label in const <String>['Feed', 'Play', 'Bath']) {
        expect(
          tester.getRect(find.text(label)).height,
          closeTo(_designLabelLine, 0.01),
          reason: '$label line box',
        );
      }

      // `.k6-free { font-size: 13px; padding: 3px 8px }` → 13 + 6 = 19 tall.
      final pill = tester.getRect(find.byType(PipFreePill));
      expect(pill.height, closeTo(_designFreePillHeight, 0.01));
      // …and it sits inside Play's card, not below it.
      final play = card(tester, 'k06-play');
      expect(pill.top, greaterThanOrEqualTo(play.top));
      expect(pill.bottom, lessThanOrEqualTo(play.bottom + 0.01));
      await disposeApp(tester);
    });
  });

  group('the pet slot kept the design geometry', () {
    testWidgets('230 x 206 slot, 134 px Pip at bottom 81, 9 px overhang', (
      tester,
    ) async {
      await pump(tester);

      final slot = tester.getRect(find.byKey(const Key('k06-pet')));
      expect(slot.width, closeTo(_designSlotWidth, _tol));
      expect(slot.height, closeTo(_designSlotHeight, _tol));

      final pip = tester.getRect(
        find.descendant(
          of: find.byKey(const Key('k06-pet')),
          matching: find.byType(PipAvatar),
        ),
      );
      expect(pip.width, closeTo(_designPipSize, _tol));
      expect(pip.height, closeTo(_designPipSize, _tol));
      expect(
        slot.bottom - pip.bottom,
        closeTo(_designPipBottom, _tol),
        reason: '`bottom: 81px` in .k6-pet .pip',
      );
      // `bottom: 81 + height: 134 = 215` inside a 206 px slot, so the Pip
      // overhangs the TOP by 9 px and the slot must not clip it.
      expect(
        slot.top - pip.top,
        closeTo(_designPipOverhang, _tol),
        reason: 'the 9 px overhang above the slot',
      );
      await disposeApp(tester);
    });

    testWidgets('the nest art is the slot box, contained', (tester) async {
      await pump(tester);

      final art = find
          .descendant(
            of: find.byKey(const Key('k06-pet')),
            matching: find.byType(SvgPicture),
          )
          .first;
      final slot = tester.getRect(find.byKey(const Key('k06-pet')));
      final box = tester.getRect(art);

      expect(
        tester.widget<SvgPicture>(art).fit,
        BoxFit.contain,
        reason: 'the browser fits a square SVG uniformly into its img box',
      );
      expect(box.width, closeTo(_designSlotWidth, _tol));
      expect(box.height, closeTo(_designSlotHeight, _tol));
      expect(box.bottom, closeTo(slot.bottom, _tol), reason: '`bottom: 0`');
      expect(box.left, closeTo(slot.center.dx - _designSlotWidth / 2, _tol));
      await disposeApp(tester);
    });
  });

  group('the pet slot is wired with the design arguments', () {
    testWidgets('glow and ground shadow off, contain, bottom 81, 134 px Pip', (
      tester,
    ) async {
      // Every measurement above would still pass if the shared widget were
      // wired with its DEFAULT glow: a glow paints outside every rect. These
      // are the arguments `K06-pip.html` and the design PNG require, and
      // `.k6-pet` has no `.pet-stage::before` glow rule at all.
      await pump(tester);

      final stage = tester.widget<NestPetStage>(find.byType(NestPetStage));
      expect(stage.showGlow, isFalse, reason: 'K06 paints no glow');
      expect(stage.showGroundShadow, isFalse, reason: 'and no ground shadow');
      expect(stage.nestFit, BoxFit.contain, reason: "the browser's <img>");
      expect(stage.nestWidth, closeTo(_designSlotWidth, 0.01));
      expect(stage.nestHeight, closeTo(_designSlotHeight, 0.01));
      expect(stage.slotHeight, closeTo(_designSlotHeight, 0.01));
      expect(stage.fixedPipHeight, closeTo(_designPipSize, 0.01));
      expect(stage.pipBottom, closeTo(_designPipBottom, 0.01));
      await disposeApp(tester);
    });
  });

  group('the shared dashed border kept the design dash', () {
    testWidgets('dash 6 / gap 3, stroke deferred to the kid border token', (
      tester,
    ) async {
      // Measured off the design PNG (dash 670→675, gap 676→678 on a 3 px
      // stroke) by the builder that first drew it; the shared widget ships the
      // same metric as its defaults, and K06 must not override it.
      await pump(tester);

      for (final id in const <String>['wellies', 'crown']) {
        final border = tester.widget<NestDashedBorder>(
          find
              .descendant(
                of: find.byKey(Key('k06-ward-$id')),
                matching: find.byType(NestDashedBorder),
              )
              .first,
        );
        expect(border.dashLength, closeTo(6, 0.01), reason: '$id dash');
        expect(border.dashGap, closeTo(3, 0.01), reason: '$id gap');
        expect(
          border.strokeWidth,
          isNull,
          reason:
              '$id follows NestKidTheme.borderWidth (3 px), never a literal',
        );
      }

      // An owned tile has no dashed layer at all.
      expect(
        find.descendant(
          of: find.byKey(const Key('k06-ward-scarf')),
          matching: find.byType(NestDashedBorder),
        ),
        findsNothing,
      );
      await disposeApp(tester);
    });
  });
}
