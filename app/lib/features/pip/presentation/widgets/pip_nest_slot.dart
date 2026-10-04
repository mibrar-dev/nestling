// K06's pet slot — the design's `.k6-pet`, transcribed.
//
// `design/html-source/screens/K06-pip.html`:
//   .k6-pet        { width:230px; height:206px; margin:9px auto 0 }
//   .k6-pet .nest  { left:50%; bottom:0; width:230px; height:206px }
//   .k6-pet .pip   { bottom:81px; width:134px; height:134px }
//
// `.nest` is an `<img>` of a square `viewBox="0 0 240 240"` SVG, so the
// browser fits the art UNIFORMLY into its 230 x 206 box (default
// `preserveAspectRatio: xMidYMid meet`): a 206 x 206 nest, 12 px of letterbox
// either side. Measured off `design/screens/light/K06-pip.png` (÷3), the nest's
// outermost painted row is logical y 277.7 and spans x 108.3 - 281.3, i.e.
// 173.0 wide — exactly `202 units x 206/240 = 173.4`, and its widest row sits
// 78 px above the slot's bottom edge, i.e. `52 + 26 = 78 units` of the 240-tall
// art. Painting the art 230 x 230 (`BoxFit.fill`) is 12 % too wide and 24 px
// too tall, and moves the rim ~12 px off the design (K06-BUG-4).
//
// WHY THIS IS SCREEN-LOCAL (see docs/screens/K06/SHARED_REQUEST.md): the
// shared `NestPetStage` explicit-size mode cannot express this slot.
// `PipNestFallback.explicitGeometry` pins its block to
// `_explicitSlotH = 236` and seats the pip at
// `rimTop * nestH + rimOverlap (44.2)` — both tuned to K03's 236 x 188 slot.
// For K06 that puts the nest 31 px too high and the pip 45 px too high. The
// owner rule ("keep the design's size and position for the Pip slot") wins, so
// the two shared ASSETS (`nest.svg`, `PipAvatar`) are composed here instead —
// no pixel values are invented, every number above is the design's own.
//
// K06's design has no `.pet-stage::before` glow (the glow is a `.pet-stage`
// rule and this screen's markup has no `.pet-stage`), so none is painted.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nestling/core/design_system/assets/nestling_assets.dart';

/// `.k6-pet { width: 230px; height: 206px }`.
const double kPipSlotWidth = 230;
const double kPipSlotHeight = 206;

/// `.k6-pet .nest { width: 230px; height: 206px; bottom: 0 }` — the design's
/// `<img>` box, which is exactly the slot's own box. `nest.svg` is square
/// (`viewBox 0 0 240 240`), so the box holds the art at a uniform 206/240
/// scale, centred (see the file header).
const double kPipNestArtWidth = kPipSlotWidth;
const double kPipNestArtHeight = kPipSlotHeight;

/// `.k6-pet .pip { width: 134px; height: 134px; bottom: 81px }`.
const double kPipSlotPipHeight = 134;
const double kPipSlotPipBottom = 81;

/// The child's own Pip in the nest, at the design's size and position.
class PipNestSlot extends StatelessWidget {
  const PipNestSlot({required this.pip, super.key, this.semanticLabel});

  /// The child's `PipAvatar` (`inNest: false` — the nest art is the shared
  /// `nest.svg`, exactly as the design stacks the two `<img>` elements).
  final Widget pip;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      child: SizedBox(
        width: kPipSlotWidth,
        height: kPipSlotHeight,
        // The pip overhangs the slot by 9 px (bottom 81 + height 134 > 206),
        // so the box must not clip (CSS `overflow` is visible).
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 0,
              width: kPipNestArtWidth,
              height: kPipNestArtHeight,
              child: SvgPicture.asset(
                NestlingIllustrations.nest,
                // `BoxFit.contain` (the default, and what the design's
                // `<img>` does): the browser fits the square art uniformly
                // into the 230 x 206 box, letterboxed 12 px each side.
                // `fill` would stretch it 12 % wider and 24 px taller than
                // the design PNG (K06-BUG-4).
                placeholderBuilder: (_) => const SizedBox.shrink(),
              ),
            ),
            Positioned(
              bottom: kPipSlotPipBottom,
              width: kPipSlotPipHeight,
              height: kPipSlotPipHeight,
              child: pip,
            ),
          ],
        ),
      ),
    );
  }
}
