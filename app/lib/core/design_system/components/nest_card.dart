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
    this.radius,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final NestCardVariant variant;
  final EdgeInsetsGeometry? padding;

  /// Corner radius override (logical px). Null keeps the default 24
  /// (`NestRadii.allL`) for every variant. P16's `.subcard` needs 16
  /// (`--r-m`, `P16-settings.html:7`, `padding:14px 16px`): pass
  /// `radius: NestRadii.m` with
  /// `padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16)`.
  final double? radius;
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
    final effectiveRadius = radius == null
        ? NestRadii.allL
        : BorderRadius.circular(radius!);
    final decoration = switch (variant) {
      NestCardVariant.standard => BoxDecoration(
        color: tokens.surface,
        borderRadius: effectiveRadius,
        boxShadow: tokens.cardShadow,
      ),
      NestCardVariant.inset => BoxDecoration(
        color: tokens.surface2,
        borderRadius: effectiveRadius,
      ),
      NestCardVariant.hero => BoxDecoration(
        color: tokens.heroBg,
        borderRadius: effectiveRadius,
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
        enabled: true,
        label: semanticLabel,
        // The explicit label already carries the announcement (P08 §2):
        // excluding the subtree keeps one node per card instead of
        // `label + every descendant text`. Only when a label is set —
        // without one the children must stay reachable. `onTap` mirrors
        // the InkWell: `excludeSemantics` drops the descendant action.
        excludeSemantics: semanticLabel != null,
        onTap: tap,
        child: Material(
          color: Colors.transparent,
          borderRadius: effectiveRadius,
          child: InkWell(
            borderRadius: effectiveRadius,
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
