// K06's "Free" pill (`.k6-free` in
// `design/html-source/screens/K06-pip.html`).
//
// `font-size:13px; font-weight:800; line-height:1; color:ink; background:
// surface; border-radius:999px; padding:3px 8px` — the design's way of
// saying the Play button costs nothing.
import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

class PipFreePill extends StatelessWidget {
  const PipFreePill({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: NestSpacing.s2,
          vertical: NestSpacing.gap3,
        ),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: NestRadii.allPill,
        ),
        child: Text(
          'Free',
          style: NestType.buttonKid(color: tokens.ink)
              .copyWith(fontSize: 13, fontWeight: FontWeight.w800, height: 1),
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }
}
