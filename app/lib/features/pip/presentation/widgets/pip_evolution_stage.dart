// K07's `.k7-stage` — the old Pip silhouette, the arrow, and the new Pip.
//
//   .k7-stage { position: relative; width: 100%; height: 250px }
//   .k7-old   { left: 2px;   bottom: 4px;  68x68;  opacity: .24;
//               filter: grayscale(1) }
//   .k7-arrow { left: 76px;  bottom: 24px; 30x30 svg; color: --lilac-strong }
//   .k7-new   { right: 6px;  bottom: 0;    240x240 }
//
// ORCHESTRATOR PIP RULE: both slots render the child's OWN Pip with
// [PipAvatar] from the database (`pip_style` / `pip_skin` / `pip_accessory`,
// e.g. Maya = Mochi/sunny). The v1 `pip-stage-*.svg` illustrations the HTML
// links are never used in product screens; only the design's SLOT geometry
// (sizes and positions) is kept.
import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/pip/domain/entities/pip_profile.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_copy.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_look.dart';

/// `.k7-*` slot geometry, in the design's CSS px.
abstract final class EvolutionStageGeometry {
  const new _();

  /// `.k7-stage { height: 250px }`.
  static const double slotHeight = 250;

  /// `.k7-old { width: 68px; height: 68px }`.
  static const double oldSize = 68;

  /// `.k7-old { left: 2px }`.
  static const double oldLeft = NestSpacing.gap2;

  /// `.k7-old { bottom: 4px }`.
  static const double oldBottom = NestSpacing.s1;

  /// `.k7-old { opacity: .24 }`.
  static const double oldOpacity = 0.24;

  /// `.k7-arrow { left: 76px }` — the 68 px old Pip plus an 8 px gap.
  static const double arrowLeft = oldSize + NestSpacing.s2;

  /// `.k7-arrow { bottom: 24px }`.
  static const double arrowBottom = NestSpacing.s6;

  /// The design's `arrowRight` svg is 30x30.
  static const double arrowSize = 30;

  /// `.k7-new { width: 240px; height: 240px }`.
  static const double newSize = 240;

  /// `.k7-new { right: 6px }`.
  static const double newRight = NestSpacing.gap6;

  /// The slot's own content width at the design's 390 px screen
  /// (`390 - 2 * var(--pad-side)`). The three pieces are fixed-size and
  /// left/right-anchored inside it, and at this width the arrow tucks exactly
  /// 2 px under the grown Pip — the design's own overlap.
  static const double designSlotWidth = 350;

  /// CSS `filter: grayscale(1)` — the standard luminance matrix, with the
  /// alpha row untouched so the element's own `opacity` still applies.
  static const List<double> grayscale = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ];
}

/// The stage slot for the active child: `oldStage → arrow → newStage`.
///
/// [profile] is the DB row, so the look and stage always belong to the child
/// who is playing. At stage 1 there is nothing to evolve FROM, so the single
/// 240 px Pip is centred and the arrow/old slot are dropped (the case is
/// unreachable in the demo seed, which starts at stage 2/3).
///
/// Narrower than the design's 350 px of slot content the three fixed-size
/// pieces no longer fit: the grown Pip is right-anchored, so it would slide
/// 72 px left over the arrow and 36 px over the "before" silhouette — the one
/// story the screen exists to tell becomes illegible at 320 px
/// (`6_bugs.md` K07-BUG-2). Below [EvolutionStageGeometry.designSlotWidth] the
/// whole slot is scaled down instead, which is exactly what a browser does to
/// a fixed-width SVG, and is a no-op (scale 1.0, byte-identical geometry) at
/// 390 px and above.
class PipEvolutionStage extends StatelessWidget {
  const new({required this.profile, super.key});

  final PipProfile profile;

  /// The stage this child has grown INTO (clamped to Pip's 1..4 artboards).
  int get stage => profile.stage.clamp(1, 4);

  /// The stage one step back — what Pip looked like before this growth.
  int get oldStage => stage > 1 ? stage - 1 : 1;

  PipAvatar _pip(int pipStage, double size) => PipAvatar(
    style: pipStyleOf(profile.style),
    skin: pipSkinOf(profile.skin),
    accessory: pipAccessoryOf(profile.accessory),
    stage: pipStage,
    size: size,
  );

  @override
  Widget build(BuildContext context) {
    final newPip = _newPip();
    return SizedBox(
      key: const Key('k07-stage'),
      height: EvolutionStageGeometry.slotHeight,
      width: double.infinity,
      child: stage == 1
          ? Center(child: newPip)
          : LayoutBuilder(
              builder: (context, constraints) {
                final slot = _slot(context, newPip);
                final width = constraints.maxWidth;
                if (!width.isFinite ||
                    width >= EvolutionStageGeometry.designSlotWidth) {
                  return slot;
                }
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.bottomRight,
                  child: SizedBox(
                    width: EvolutionStageGeometry.designSlotWidth,
                    child: slot,
                  ),
                );
              },
            ),
    );
  }

  /// `.k7-stage`'s three absolutely-positioned pieces. The `Stack` takes the
  /// whole slot, so the grown Pip is anchored to the available right edge
  /// exactly as `right: 6px` does in the CSS.
  Widget _slot(BuildContext context, Widget newPip) {
    return SizedBox(
      height: EvolutionStageGeometry.slotHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned(
            key: const Key('k07-old-pip'),
            left: EvolutionStageGeometry.oldLeft,
            bottom: EvolutionStageGeometry.oldBottom,
            width: EvolutionStageGeometry.oldSize,
            height: EvolutionStageGeometry.oldSize,
            child: ExcludeSemantics(
              // The design's `alt=""`: a decorative silhouette.
              child: Opacity(
                opacity: EvolutionStageGeometry.oldOpacity,
                child: ColorFiltered(
                  colorFilter: const ColorFilter.matrix(
                    EvolutionStageGeometry.grayscale,
                  ),
                  child: _pip(oldStage, EvolutionStageGeometry.oldSize),
                ),
              ),
            ),
          ),
          Positioned(
            key: const Key('k07-arrow'),
            left: EvolutionStageGeometry.arrowLeft,
            bottom: EvolutionStageGeometry.arrowBottom,
            child: ExcludeSemantics(
              child: NestIcon(
                NestIcons.arrowRight,
                size: EvolutionStageGeometry.arrowSize,
                color: context.nest.lilacStrong,
              ),
            ),
          ),
          Positioned(
            right: EvolutionStageGeometry.newRight,
            bottom: 0,
            width: EvolutionStageGeometry.newSize,
            height: EvolutionStageGeometry.newSize,
            child: newPip,
          ),
        ],
      ),
    );
  }

  /// The grown Pip, announced as an image ("Maya's Pip, a fledgling").
  Widget _newPip() => Semantics(
    key: const Key('k07-new-pip'),
    image: true,
    label: evolutionNewPipLabel(profile.nickname, stage),
    child: _pip(stage, EvolutionStageGeometry.newSize),
  );
}
