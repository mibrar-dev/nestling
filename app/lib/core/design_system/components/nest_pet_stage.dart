import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
/// parents the whole stage scales down instead of overflowing. The ground
/// shadow is a soft blurred ellipse directly under the nest, never a pill.
class NestPetStage extends StatelessWidget {
  const new({
    super.key,
    this.pipAsset,
    this.stage = PipStage.fledgling,
    this.mood = PipMood.idle,
    this.riveEnabled = true,
    this.pipSize = 200,
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
              var pipH = maxW.isFinite ? maxW * 0.62 * 0.55 : pipSize;
              if (pipH > pipSize) {
                pipH = pipSize;
              }
              final nestW = pipH / 0.55;
              final stageW = nestW / 0.62;
              final custom = pip;
              if (custom != null) {
                return PipNestFallback(
                  stage: stage,
                  pip: custom,
                  pipH: pipH,
                  nestW: nestW,
                  stageW: stageW,
                );
              }
              return _PetScene(
                pipAsset: pipAsset ?? stage.fallbackAsset,
                stage: stage,
                mood: mood,
                riveEnabled: riveEnabled,
                pipH: pipH,
                nestW: nestW,
                stageW: stageW,
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
    required this.stageW,
  });

  final String pipAsset;
  final PipStage stage;
  final PipMood mood;
  final bool riveEnabled;
  final double pipH;
  final double nestW;
  final double stageW;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce || !riveEnabled) return _svgStage();
    // Rive path: the PipStage artboard (350x260) already composes ground
    // shadow + nest back + Pip + nest front rim in one file. The fallback
    // the artboard degrades to is the same scene ([PipNestFallback]), so
    // both paths share one geometry and can never drift apart.
    // The box matches the artboard aspect, so contain is an exact fit.
    const sceneW = 350.0;
    const sceneH = 260.0;
    final riveH = stageW * sceneH / sceneW;
    // Nest centre in scene space: x 75..275, bowl mid ~y 139.
    const nestCx = 175.0;
    const nestCy = 139.0;
    final glowD = stageW * 200 / sceneW * 1.04;
    return SizedBox(
      width: stageW,
      height: riveH,
      child: Stack(
        children: [
          if (tokens.isDark)
            Positioned(
              left: stageW * nestCx / sceneW - glowD / 2,
              top: riveH * nestCy / sceneH - glowD / 2,
              child: Container(
                width: glowD,
                height: glowD,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x1AFFFFFF),
                ),
              ),
            ),
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
      stageW: stageW,
    );
  }
}

/// Pip's speech bubble (K03): max 260 wide, r18, 3px ink border, tail.
class NestSpeechBubble extends StatelessWidget {
  const new({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Column(
      mainAxisSize: MainAxisSize.min,
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
            style: GoogleFonts.nunito(
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w800,
              color: tokens.ink,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        CustomPaint(
          painter: _TailPainter(
            inkColor: tokens.ink,
            fillColor: tokens.surface,
          ),
          size: const Size(18, 10),
        ),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  const new({required this.inkColor, required this.fillColor});

  final Color inkColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final inkPaint = Paint()..color = inkColor;
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(18, 0)
        ..lineTo(9, 10)
        ..close(),
      inkPaint,
    );
    final fillPaint = Paint()..color = fillColor;
    canvas.drawPath(
      Path()
        ..moveTo(3.5, 0)
        ..lineTo(14.5, 0)
        ..lineTo(9, 6.5)
        ..close(),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate is _TailPainter &&
      (oldDelegate.inkColor != inkColor || oldDelegate.fillColor != fillColor);
}
