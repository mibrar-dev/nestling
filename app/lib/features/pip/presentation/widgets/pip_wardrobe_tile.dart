// K06's wardrobe strip (`.k6-ward` + `.k6-item` in
// `design/html-source/screens/K06-pip.html`).
//
// `.k6-ward { display:flex; gap:12px }` with `> * { flex:1; min-width:0 }`,
// so the four tiles are (350 − 3 × 12) / 4 = 78.5 wide at the design width
// and shrink with the screen — never a fixed 78.5 (SPACING_SPEC §10.2).
//
// `.k6-item { background:surface; border:3px solid ink; border-radius:r-l;
// box-shadow:sh-kid; padding:8px 4px; column; center; gap:4px }`, holding
// a 52 px art circle (`lilac-tint` fill, 30 px icon), a 14/18 w800 name and
// either "Owned" in `--leaf-ink` or a coin price. A locked tile swaps to
// `--surface-2` with a DASHED `--ink-2` border and no shadow.
//
// The dashed border is screen-local: Flutter has no dashed BorderSide and the
// design system ships no dashed-border widget (see
// docs/screens/K06/SHARED_REQUEST.md). Dash metrics are measured off the
// design PNG: 6 px dash / 3 px gap on a 3 px stroke, painted as a
// `CustomPaint.foregroundPainter` so the stroke lands ON the fill, exactly
// where CSS puts a dashed `border` (a background painter is hidden under the
// opaque tile fill — K06-BUG-6).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';
import 'package:nestling/features/pip/domain/entities/pip_stage.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_coin_amount.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_look.dart';

/// `.k6-item-art { width: 52px; height: 52px; border-radius: 999px }`.
const double kPipWardrobeArtSize = 52;

/// `<svg width="30" height="30">` inside the art circle.
const double kPipWardrobeIconSize = 30;

/// `.k6-ward { gap: 12px }`.
const double kPipWardrobeGap = NestSpacing.s3;

/// Painted height of every wardrobe tile: 3 px border + 8 px padding + 52 px
/// art circle + 4 + 18 name + 4 + 16 price row + 8 px padding + 3 px border.
///
/// `.k6-ward` is a flex row with the default `align-items: stretch`, so the
/// design's owned tiles (a 14 px text price) stretch to the locked ones'
/// 16 px coin row and all four edges line up. Flutter rows do not stretch
/// with an unbounded height, so the tile pins the same minimum.
const double kPipWardrobeTileHeight = 116;

/// Dashed `border-style: dashed` on a 3 px stroke, measured off the design
/// PNG (dash 670→675, gap 676→678 on a straight edge: 6 / 3).
const double _kDashLength = 6;
const double _kDashGap = 3;

/// One wardrobe tile: the whole tile is the button.
class PipWardrobeTile extends StatelessWidget {
  const PipWardrobeTile({
    required this.item,
    required this.onPressed,
    super.key,
  });

  final PipStage item;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final kid = context.nestKid;
    final owned = item.owned;
    final nameColor = owned ? tokens.ink : tokens.ink2;
    final artFill = owned ? tokens.lilacTint : tokens.surface;

    return Semantics(
      button: true,
      label: owned
          ? '${item.title}, Owned'
          : '${item.title}, ${item.priceCoins} coins',
      onTap: onPressed,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: CustomPaint(
          // A locked tile drops `--sh-kid`, so it needs no room below it.
          //
          // FOREGROUND, not `painter`: the tile's own `surface-2` fill is
          // opaque edge to edge, so a background stroke is completely covered
          // and the locked slot reads as a flat beige card with no border
          // (K06-BUG-6 = the UI stage's D1 = ORCHESTRATOR_NOTES item 1).
          // Painting on top of the fill is what CSS `border-style: dashed`
          // does — the stroke sits inside the border box, over the
          // background — and it is also over the art circle's white fill,
          // which never reaches the outer 3 px.
          foregroundPainter: owned
              ? null
              : _DashedBorderPainter(
                  color: tokens.ink2,
                  width: kid.borderWidth,
                  dashLength: _kDashLength,
                  dashGap: _kDashGap,
                ),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: kPipWardrobeTileHeight,
            ),
            // The dashed lock paints the same 3 px band a solid border
            // occupies, so a locked tile reserves it too and both tiles
            // keep identical content insets (the art circles line up).
            padding: EdgeInsets.all(owned ? 0 : kid.borderWidth),
            decoration: BoxDecoration(
              color: owned ? tokens.surface : tokens.surface2,
              borderRadius: NestRadii.allL,
              border: owned
                  ? Border.all(color: tokens.ink, width: kid.borderWidth)
                  : null,
              boxShadow: owned
                  ? [
                      BoxShadow(
                        color: tokens.kidShadow.first.color,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              // `.k6-item { padding: 8px 4px }`, measured from the inner
              // edge of the 3 px border.
              padding: const EdgeInsets.symmetric(
                vertical: NestSpacing.s2,
                horizontal: NestSpacing.s1,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: NestSpacing.s1,
                children: [
                  Container(
                    width: kPipWardrobeArtSize,
                    height: kPipWardrobeArtSize,
                    decoration: BoxDecoration(
                      color: artFill,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(NestRadii.pill),
                      ),
                    ),
                    child: Center(
                      child: NestIcon(
                        pipWardrobeIcon(item.id),
                        size: kPipWardrobeIconSize,
                        color: nameColor,
                      ),
                    ),
                  ),
                  Text(
                    item.title,
                    // `.k6-item-n`: Nunito 800 14 px on an 18 px line.
                    style: NestType.kidBody(color: nameColor).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 18 / 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (owned)
                    // `.k6-item-p.on { color: var(--leaf-ink) }`.
                    Text(
                      'Owned',
                      style: NestType.buttonKid(color: tokens.leafInk).copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                      maxLines: 1,
                      softWrap: false,
                    )
                  else
                    PipCoinAmount(
                      amount: '${item.priceCoins}',
                      color: nameColor,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The four wardrobe tiles in design order (the repository already sorts them:
/// Scarf, Sun hat, Wellies, Crown — never alphabetical).
class PipWardrobeStrip extends StatelessWidget {
  const PipWardrobeStrip({required this.items, required this.onTap, super.key});

  final List<PipStage> items;

  /// Owned tiles equip, locked tiles buy.
  final void Function(PipStage item, {required bool owned}) onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: kPipWardrobeGap,
      children: [
        for (final item in items)
          Expanded(
            child: PipWardrobeTile(
              key: Key('k06-ward-${item.id}'),
              item: item,
              onPressed: () => onTap(item, owned: item.owned),
            ),
          ),
      ],
    );
  }
}

/// Screen-local dashed border: a 3 px dashed stroke walked along the tile's
/// `--r-l` rounded rectangle. Flutter has no dashed `BorderSide`, and the
/// design system has no dashed-border component.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.width,
    required this.dashLength,
    required this.dashGap,
  });

  final Color color;
  final double width;
  final double dashLength;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = rect.deflate(width / 2);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          outer,
          Radius.circular(math.max(0, NestRadii.l - width / 2)),
        ),
      );
    final metrics = path.computeMetrics();
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.width != width ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.dashGap != dashGap;
}
