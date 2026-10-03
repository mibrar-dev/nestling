import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/motion/pip_rive.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';

/// Pip on the nest, composed like K03-kid-home.png.
///
/// Proportions follow the K03 render: nest width ≈ 0.62 × stage width, Pip
/// height ≈ 0.55 × nest width, Pip's feet buried just below the
/// back/front-rim split. The nest renders in two halves — back rim, then Pip,
/// then front rim — so the front rim overlaps Pip's feet. The Rive path
/// ([PipInNest], artboard `PipStage`) composes the same three layers in one
/// file; the SVG fallback stacks them here with the same split and feet
/// fractions, so the two paths can never drift apart.
/// [pipSize] caps the Pip height; in narrow
/// parents the whole stage scales down instead of overflowing.
///
/// Explicit-size mode: pass [nestWidth] (or [visibleNestWidth]) and
/// optionally [fixedPipHeight]/[nestHeight] to request the design's exact
/// slot — e.g. K03's 236-wide × 188-tall nest (which paints the design's
/// 198 × 86 visible outline) with its 152-tall PipAvatar (feet 23 px inside
/// the bowl) in a 236-tall block — without forking the
/// scene. The nest art fills its box, so the visible bowl outline is always
/// `nestWidth × PipNestFallback.visibleNestRatio` (≈0.84) by
/// `nestHeight × 110/240`: [nestWidth] sets
/// the BOX, [visibleNestWidth] sets the OUTLINE directly (they are mutually
/// exclusive). The scene lays out against the ACTUAL parent width: the nest
/// stays centred, decor never shifts it, and a request wider than the box
/// scales down uniformly instead of overflowing. The ground
/// shadow is a soft blurred ellipse directly under the nest, never a pill.
class NestPetStage extends StatelessWidget {
  const new({
    super.key,
    this.pipAsset,
    this.stage = PipStage.fledgling,
    this.mood = PipMood.idle,
    this.riveEnabled = true,
    this.pipSize = 200,
    this.nestWidth,
    this.fixedPipHeight,
    this.nestHeight,
    this.visibleNestWidth,
    this.speech,
    this.semanticLabel,
    this.pip,
  });

  /// The child's own Pip (v2 `PipAvatar`, inNest: false) to seat in the
  /// nest. When set, the v1 Rive rig is not used.
  final Widget? pip;

  /// Explicit pip art for the SVG fallback. Defaults to the stage's SVG.
  final String? pipAsset;

  /// Growth stage. Selects the Rive rig and the default fallback art.
  final PipStage stage;

  /// Current mood, driven into the Rive state machine.
  final PipMood mood;

  /// Set false to force the SVG fallback. See [PipRive.riveEnabled].
  final bool riveEnabled;

  final double pipSize;

  /// Explicit nest-box width (logical px). When set, the stage stops deriving
  /// its size from the parent width: the nest renders exactly [nestWidth]
  /// wide and Pip scales to the design ratio ([pipPerNestWidth]) unless
  /// [fixedPipHeight] overrides it. Null (default) keeps the legacy
  /// max-width-derived sizing capped by [pipSize]. Mutually exclusive with
  /// [visibleNestWidth].
  final double? nestWidth;

  /// Explicit nest-box height (logical px). The art fills the box, so the
  /// bowl outline is `nestWidth × visibleNestRatio` by
  /// `nestHeight × 110/240` (outer bowl 95…205/240); K03 passes 188 under
  /// its 236-wide box for the design's 198 × 86 outline in a 236-tall slot.
  /// Null (default) keeps the legacy square art (`nestH == nestW`).
  final double? nestHeight;

  /// Visible nest outline width (logical px), converted to the box via
  /// `PipNestFallback.visibleNestRatio`. Clearer than [nestWidth] when the
  /// design specs the outline (K03: 198 → a ≈236 box). Mutually exclusive
  /// with [nestWidth].
  final double? visibleNestWidth;

  /// Explicit Pip height (logical px). Implies explicit sizing like
  /// [nestWidth]; the nest derives as `fixedPipHeight / split` unless
  /// [nestWidth] is also set. Null (default) keeps legacy sizing.
  final double? fixedPipHeight;

  /// Pip height per unit of nest width in explicit-size mode: K03's design
  /// slot is a ≈152-tall Pip on a 260-wide nest (`SPACING_SPEC` §7).
  static const double pipPerNestWidth = 152 / 260;

  final String? speech;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final bubbleText = speech;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (bubbleText != null)
          Padding(
            padding: const EdgeInsets.only(bottom: NestSpacing.s2),
            child: NestSpeechBubble(text: bubbleText),
          ),
        Semantics(
          label: semanticLabel ?? bubbleText ?? 'Pip the mascot',
          image: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              final double pipH;
              final double nestW;
              final double nestH;
              final double stageW;
              final bool explicit;
              if (nestWidth != null ||
                  fixedPipHeight != null ||
                  nestHeight != null ||
                  visibleNestWidth != null) {
                // Explicit-size mode (K03): the design's slot, laid out
                // against the ACTUAL box. The nest is always centred in what
                // the widget gets; a request wider than the box scales the
                // whole scene down uniformly instead of overflowing (the
                // guard the legacy path already had).
                assert(
                  nestWidth == null || visibleNestWidth == null,
                  'Pass nestWidth or visibleNestWidth, not both.',
                );
                final reqNestW = visibleNestWidth != null
                    ? visibleNestWidth! / PipNestFallback.visibleNestRatio
                    : (nestWidth ??
                          (fixedPipHeight != null
                              ? fixedPipHeight! / PipNestFallback.split
                              : nestHeight!));
                final reqPipH = fixedPipHeight ?? reqNestW * pipPerNestWidth;
                final reqNestH = nestHeight ?? reqNestW;
                final need = math.max(reqNestW, reqPipH);
                final slotW = maxW.isFinite ? maxW : need;
                final s = slotW < need ? slotW / need : 1.0;
                nestW = reqNestW * s;
                nestH = reqNestH * s;
                pipH = reqPipH * s;
                stageW = slotW;
                explicit = true;
              } else {
                var derived = maxW.isFinite ? maxW * 0.62 * 0.55 : pipSize;
                if (derived > pipSize) {
                  derived = pipSize;
                }
                pipH = derived;
                nestW = pipH / 0.55;
                nestH = nestW;
                stageW = nestW / 0.62;
                explicit = false;
              }
              final custom = pip;
              if (custom != null) {
                return PipNestFallback(
                  stage: stage,
                  pip: custom,
                  pipH: pipH,
                  nestW: nestW,
                  nestH: nestH,
                  stageW: stageW,
                  explicitLayout: explicit,
                );
              }
              return _PetScene(
                pipAsset: pipAsset ?? stage.fallbackAsset,
                stage: stage,
                mood: mood,
                riveEnabled: riveEnabled,
                pipH: pipH,
                nestW: nestW,
                nestH: nestH,
                stageW: stageW,
                explicitLayout: explicit,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PetScene extends StatelessWidget {
  const new({
    required this.pipAsset,
    required this.stage,
    required this.mood,
    required this.riveEnabled,
    required this.pipH,
    required this.nestW,
    required this.nestH,
    required this.stageW,
    this.explicitLayout = false,
  });

  final String pipAsset;
  final PipStage stage;
  final PipMood mood;
  final bool riveEnabled;
  final double pipH;
  final double nestW;
  final double nestH;
  final double stageW;
  final bool explicitLayout;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce || !riveEnabled) return _svgStage();
    if (explicitLayout) {
      // Rive path, explicit slot: the box matches the fallback scene
      // ([PipNestFallback.explicitGeometry]) so both paths occupy the same
      // slot; the fixed-aspect artboard letterboxes inside it. The fallback
      // the artboard degrades to is the same scene, so the two can never
      // drift apart.
      final g = PipNestFallback.explicitGeometry(
        nestH: nestH,
        pipH: pipH,
        contactFrac: PipNestFallback.contactInSvg(stage),
      );
      return SizedBox(
        width: stageW,
        height: g.stageH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            PetStageGlow(stageW: stageW, stageH: g.stageH),
            Positioned.fill(
              child: PipInNest(
                stage: stage,
                mood: mood,
                pipAsset: pipAsset,
                pipH: pipH,
                nestW: nestW,
                nestH: nestH,
                stageW: stageW,
                explicitLayout: true,
              ),
            ),
          ],
        ),
      );
    }
    // Rive path: the PipStage artboard (350x260) already composes ground
    // shadow + nest back + Pip + nest front rim in one file. The fallback
    // the artboard degrades to is the same scene ([PipNestFallback]), so
    // both paths share one geometry and can never drift apart.
    // The box matches the artboard aspect, so contain is an exact fit.
    const sceneW = 350.0;
    const sceneH = 260.0;
    final riveH = stageW * sceneH / sceneW;
    return SizedBox(
      width: stageW,
      height: riveH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PetStageGlow(stageW: stageW, stageH: riveH),
          Positioned.fill(
            child: PipInNest(
              stage: stage,
              mood: mood,
              pipAsset: pipAsset,
              pipH: pipH,
              nestW: nestW,
              stageW: stageW,
            ),
          ),
        ],
      ),
    );
  }

  /// Static fallback: nest top-half clip, pip svg, nest bottom-half clip.
  /// Same split (0.55) and feet (0.40) fractions as the Rive scene.
  Widget _svgStage() {
    return PipNestFallback(
      stage: stage,
      pipAsset: pipAsset,
      pipH: pipH,
      nestW: nestW,
      nestH: nestH,
      stageW: stageW,
      explicitLayout: explicitLayout,
    );
  }
}

/// Pip's speech bubble (K03): max 260 wide, r18, 3px ink border, tail.
///
/// Matches `.speech` in `design/html-source/components.css` exactly:
/// `padding: 8px 14px`, Nunito 800 16 px with the browser-default
/// line-height (`normal`, ≈22 px in Nunito — so ≈44 px tall with border),
/// 3 px ink border, radius 18, tail `::after` (9 px triangle). Every screen
/// that shows a bubble (K03, K03b, K04, K05, K07, K10) uses the same
/// `.speech`, so there is a single default and no size parameter.
class NestSpeechBubble extends StatelessWidget {
  const new({required this.text, super.key});

  final String text;

  /// `.speech::after` geometry (`components.css:192`): the tail is a solid
  /// ink triangle this wide at its base and this tall, centred under the
  /// bubble with its top edge flush with the bubble's outer bottom edge.
  /// It is overflow (painted outside the layout box, as in CSS), so the
  /// bubble's laid-out height is the body alone.
  static const double tailWidth = 18;
  static const double tailHeight = 9;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(
            horizontal: NestSpacing.gap14,
            vertical: NestSpacing.s2,
          ),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: tokens.ink,
              width: context.nestKid.borderWidth,
            ),
          ),
          child: Text(
            text,
            // `.speech` sets no line-height, so the browser uses `normal`
            // (the font's natural height, ≈22 px in Nunito): omitting
            // `height` is Flutter's equivalent. A fixed 24/16 rendered the
            // bubble 46 px tall instead of the design's ≈44.
            style: TextStyle(
              fontFamily: 'Nunito',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              // `.speech` sets no letter-spacing: browser default 0.
              letterSpacing: 0,
              color: tokens.ink,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // `.speech::after`: `bottom:-9px` — the tail hangs 9 px below the
        // bubble as overflow. Positioned children do not size the Stack, so
        // the laid-out height stays the body alone and nothing below moves.
        Positioned(
          bottom: -tailHeight,
          left: 0,
          right: 0,
          child: Center(
            child: CustomPaint(
              painter: _TailPainter(inkColor: tokens.ink),
              size: const Size(tailWidth, tailHeight),
            ),
          ),
        ),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  const new({required this.inkColor});

  final Color inkColor;

  @override
  void paint(Canvas canvas, Size size) {
    final inkPaint = Paint()..color = inkColor;
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(NestSpeechBubble.tailWidth, 0)
        ..lineTo(NestSpeechBubble.tailWidth / 2, NestSpeechBubble.tailHeight)
        ..close(),
      inkPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is _TailPainter && oldDelegate.inkColor != inkColor;
}
