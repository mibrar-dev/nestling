import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';

class NestProgress extends StatelessWidget {
  const new({
    required this.fraction,
    super.key,
    this.kid = false,
    this.semanticLabel,
  });

  final double fraction;
  final bool kid;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final f = fraction.clamp(0.0, 1.0);
    final barHeight = kid ? NestSpacing.s4 : NestSpacing.s2;
    final track = Container(
      width: double.infinity,
      height: barHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: kid ? tokens.surface : tokens.surface2,
        borderRadius: NestRadii.allPill,
        border: kid ? Border.all(color: tokens.ink, width: 2) : null,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: f,
        child: Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: tokens.leaf,
            borderRadius: NestRadii.allPill,
          ),
        ),
      ),
    );
    final bar = kid
        ? Stack(
            children: [
              track,
              Positioned(
                top: NestSpacing.gap2,
                left: NestSpacing.s1,
                right: NestSpacing.s1,
                height: NestSpacing.s1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: NestRadii.allPill,
                  ),
                ),
              ),
            ],
          )
        : track;
    return Semantics(
      label: semanticLabel ?? 'Progress',
      value: '${(f * 100).round()} percent',
      excludeSemantics: true,
      child: SizedBox(width: double.infinity, height: barHeight, child: bar),
    );
  }
}
