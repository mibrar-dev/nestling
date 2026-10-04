// K06's pet slot — the design's `.k6-pet`, transcribed.
//
// `design/html-source/screens/K06-pip.html`:
//   .k6-pet        { width:230px; height:206px; margin:9px auto 0 }
//   .k6-pet .nest  { bottom:0; width:230px }   (nest.svg is square, so the
//                                               <img> box is 230 x 230 and
//                                               bleeds 24 px above the slot)
//   .k6-pet .pip   { bottom:81px; width:134px; height:134px }
//
// WHY THIS IS SCREEN-LOCAL (see docs/screens/K06/SHARED_REQUEST.md): the
// shared `NestPetStage` explicit-size mode cannot express this slot.
// `PipNestFallback.explicitGeometry` pins its block to
// `_explicitSlotH = 236` and seats the pip at
// `rimTop * nestH + rimOverlap (44.2)` — both tuned to K03's 236 x 188 slot.
// For K06 that puts the nest 31 px too high and the pip 45 px too high, and
// no (nestWidth, nestHeight, pipHeight) triple fixes it: keeping the nest
// square (230, as the design's <img> is) forces the pip box to 120 tall
// instead of 134. The owner rule ("keep the design's size and position for
// the Pip slot") wins, so the two shared ASSETS (`nest.svg`, `PipAvatar`) are
// composed here instead — no pixel values are invented, every number above
// is the design's own.
//
// K06's design has no `.pet-stage::before` glow (the glow is a `.pet-stage`
// rule and this screen's markup has no `.pet-stage`), so none is painted.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nestling/core/design_system/assets/nestling_assets.dart';

/// `.k6-pet { width: 230px; height: 206px }`.
const double kPipSlotWidth = 230;
const double kPipSlotHeight = 206;

/// `.k6-pet .nest { width: 230px; bottom: 0 }` — `nest.svg` is square, so
/// the design's <img> box is 230 x 230 and paints 24 px above the slot.
const double kPipNestArtSize = 230;

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
        // The nest art is 24 px taller than the slot and the pip overhangs
        // it too, so the box must not clip (CSS `overflow` is visible).
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 0,
              width: kPipNestArtSize,
              height: kPipNestArtSize,
              child: SvgPicture.asset(
                NestlingIllustrations.nest,
                // The design's <img> stretches the art into its box.
                fit: BoxFit.fill,
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
