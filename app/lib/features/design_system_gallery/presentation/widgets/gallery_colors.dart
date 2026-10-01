import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

String _hex(Color color) {
  final argb = color.toARGB32().toRadixString(16).padLeft(8, '0');
  return '#${argb.substring(2).toUpperCase()}';
}

class _Swatch {
  const new(this.name, this.color);

  final String name;
  final Color color;
}

/// Colour catalogue: every token swatch with name + hex for the current theme.
///
/// Mirrors section 1 of `design/html-source/design-system.html`. Toggle
/// light/dark in the gallery top bar to compare both ramps.
class GalleryColors extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final swatches = <_Swatch>[
      _Swatch('ink', tokens.ink),
      _Swatch('ink-2', tokens.ink2),
      _Swatch('ink-3', tokens.ink3),
      _Swatch('paper', tokens.paper),
      _Swatch('surface', tokens.surface),
      _Swatch('surface-2', tokens.surface2),
      _Swatch('line', tokens.line),
      _Swatch('leaf', tokens.leaf),
      _Swatch('leaf-ink', tokens.leafInk),
      _Swatch('leaf-tint', tokens.leafTint),
      _Swatch('coin', tokens.coin),
      _Swatch('coin-ink', tokens.coinInk),
      _Swatch('coin-tint', tokens.coinTint),
      _Swatch('sky', tokens.sky),
      _Swatch('sky-tint', tokens.skyTint),
      _Swatch('lilac', tokens.lilac),
      _Swatch('lilac-strong', tokens.lilacStrong),
      _Swatch('lilac-tint', tokens.lilacTint),
      _Swatch('peach', tokens.peach),
      _Swatch('peach-tint', tokens.peachTint),
      _Swatch('success', tokens.success),
      _Swatch('warning', tokens.warning),
      _Swatch('danger', tokens.danger),
      _Swatch('on-leaf', tokens.onLeaf),
      _Swatch('on-accent', tokens.onAccent),
      _Swatch('on-warm', tokens.onWarm),
      _Swatch('hero-bg', tokens.heroBg),
      _Swatch('on-hero', tokens.onHero),
      _Swatch('on-hero-2', tokens.onHero2),
      _Swatch('scrim', tokens.scrim),
      _Swatch('ground-shadow', tokens.groundShadow),
      _Swatch('track', tokens.track),
      _Swatch('a-lilac', tokens.aLilac),
      _Swatch('a-peach', tokens.aPeach),
      _Swatch('a-sky', tokens.aSky),
      _Swatch('kid-sky-top', tokens.kidSkyTop),
      _Swatch('kid-sky-bottom', tokens.kidSkyBottom),
      _Swatch('kid-meadow', tokens.kidMeadow),
      _Swatch('kid-horizon', tokens.kidHorizon),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = NestSpacing.s2;
        final cellW = (constraints.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: NestSpacing.s3,
          children: [
            for (final swatch in swatches)
              SizedBox(
                width: cellW,
                child: _SwatchTile(swatch: swatch),
              ),
          ],
        );
      },
    );
  }
}

class _SwatchTile extends StatelessWidget {
  const new({required this.swatch});

  final _Swatch swatch;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 64,
          decoration: BoxDecoration(
            color: swatch.color,
            borderRadius: BorderRadius.circular(NestSpacing.s3),
            border: Border.all(color: tokens.line),
          ),
        ),
        const SizedBox(height: NestSpacing.s1),
        Text(
          swatch.name,
          style: NestType.bodySmallStrong(color: tokens.ink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          _hex(swatch.color),
          style: NestType.caption(color: tokens.ink2),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
