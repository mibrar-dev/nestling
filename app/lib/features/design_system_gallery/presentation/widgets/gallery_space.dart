import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// Space, radii and shadow catalogue.
///
/// Mirrors section 3 of `design/html-source/design-system.html`.
class GallerySpace extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    const spaces = <double>[
      NestSpacing.s1,
      NestSpacing.s2,
      NestSpacing.s3,
      NestSpacing.s4,
      NestSpacing.s5,
      NestSpacing.s6,
      NestSpacing.s8,
      NestSpacing.s10,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final space in spaces)
              Container(
                width: space,
                height: NestSpacing.s6,
                margin: const EdgeInsets.only(right: NestSpacing.s2),
                decoration: BoxDecoration(
                  color: tokens.leafTint,
                  border: Border.all(color: tokens.leaf),
                ),
              ),
          ],
        ),
        const SizedBox(height: NestSpacing.s1),
        Text(
          's1 4 · s2 8 · s3 12 · s4 16 · s5 20 · s6 24 · s8 32 · s10 40',
          style: NestType.caption(color: tokens.ink2),
        ),
        const SizedBox(height: NestSpacing.s4),
        const Wrap(
          spacing: NestSpacing.s3,
          runSpacing: NestSpacing.s3,
          children: [
            _RadiusDemo(label: 'r-s 10', radius: NestRadii.allS),
            _RadiusDemo(label: 'r-m 16', radius: NestRadii.allM),
            _RadiusDemo(label: 'r-l 24', radius: NestRadii.allL),
            _RadiusDemo(label: 'r-xl 32', radius: NestRadii.allXl),
            _RadiusDemo(label: 'pill 999', radius: NestRadii.allPill),
          ],
        ),
        const SizedBox(height: NestSpacing.s4),
        Wrap(
          spacing: NestSpacing.s3,
          runSpacing: NestSpacing.s3,
          children: [
            _ShadowDemo(label: 'sh-1', shadows: tokens.cardShadow),
            _ShadowDemo(label: 'sh-2', shadows: tokens.raisedShadow),
            _ShadowDemo(
              label: 'sh-kid',
              shadows: tokens.kidShadow,
              border: Border.all(color: tokens.ink, width: 2),
            ),
          ],
        ),
      ],
    );
  }
}

class _RadiusDemo extends StatelessWidget {
  const new({required this.label, required this.radius});

  final String label;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Container(
      width: 96,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.surface2,
        borderRadius: radius,
        border: Border.all(color: tokens.line),
      ),
      child: Text(
        label,
        style: NestType.chipSmall(color: tokens.ink),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _ShadowDemo extends StatelessWidget {
  const new({required this.label, required this.shadows, this.border});

  final String label;
  final List<BoxShadow> shadows;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Container(
      width: 150,
      height: 80,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: NestRadii.allM,
        border: border,
        boxShadow: shadows,
      ),
      child: Text(
        label,
        style: NestType.bodySmallStrong(color: tokens.ink),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
