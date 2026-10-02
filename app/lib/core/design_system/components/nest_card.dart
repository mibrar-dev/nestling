import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

enum NestCardVariant { standard, inset, hero }

class NestCard extends StatelessWidget {
  const new({
    required this.child,
    super.key,
    this.variant = NestCardVariant.standard,
    this.padding,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final NestCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final effectivePadding =
        padding ??
        (variant == NestCardVariant.hero
            ? const EdgeInsets.all(NestSpacing.padSide)
            : const EdgeInsets.all(NestSpacing.s4));
    final decoration = switch (variant) {
      NestCardVariant.standard => BoxDecoration(
        color: tokens.surface,
        borderRadius: NestRadii.allL,
        boxShadow: tokens.cardShadow,
      ),
      NestCardVariant.inset => BoxDecoration(
        color: tokens.surface2,
        borderRadius: NestRadii.allL,
      ),
      NestCardVariant.hero => BoxDecoration(
        color: tokens.heroBg,
        borderRadius: NestRadii.allL,
        boxShadow: tokens.raisedShadow,
      ),
    };
    final themed = variant == NestCardVariant.hero
        ? DefaultTextStyle(
            style: NestType.body(color: tokens.onHero),
            child: IconTheme(
              data: IconThemeData(color: tokens.onHero),
              child: child,
            ),
          )
        : child;
    final tap = onTap;
    if (tap != null) {
      return Semantics(
        button: true,
        label: semanticLabel,
        // The explicit label already carries the announcement (P08 §2):
        // excluding the subtree keeps one node per card instead of
        // `label + every descendant text`. Only when a label is set —
        // without one the children must stay reachable.
        excludeSemantics: semanticLabel != null,
        child: Material(
          color: Colors.transparent,
          borderRadius: NestRadii.allL,
          child: InkWell(
            borderRadius: NestRadii.allL,
            onTap: tap,
            child: Ink(
              padding: effectivePadding,
              decoration: decoration,
              child: themed,
            ),
          ),
        ),
      );
    }
    final label = semanticLabel;
    final plain = Container(
      padding: effectivePadding,
      decoration: decoration,
      child: themed,
    );
    if (label == null) {
      return plain;
    }
    return Semantics(
      label: label,
      container: true,
      excludeSemantics: true,
      child: plain,
    );
  }
}
