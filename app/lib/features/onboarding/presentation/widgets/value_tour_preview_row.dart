import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// P02-only quest preview row at the design's `.pv-row` metrics.
///
/// `NestListRow` cannot express this row: its fixed vertical padding and
/// 56dp min-height make every compact row 60dp, but the design's pager card
/// is 400dp tall with 38dp rows (SPACING_SPEC §7, `P02-value-tour.html:29-33`).
/// This widget composes shared primitives (`NestIcon`, `NestCoinPill`,
/// `NestType`/token colours) at the design metrics instead of forking the
/// shared component. It is the permanent P02 row (no shared compact-row
/// variant is planned — `SHARED_REQUEST.md` item 2 is withdrawn); the
/// `NestTileTint` → colours switch below deliberately mirrors `NestListRow`
/// because the mapping lives in shared code this feature may not edit.
///
/// Metrics (HTML source, logical px): 36 tile, r12, icon 22; title 15/20
/// w600 in a bounded fit-or-ellipsis slot (renders in full at 390dp);
/// sub 13/18 ink2 single-line ellipsis; internal gap 8; small coin pill; no
/// vertical padding (row height = max(36, title + 18)). Non-interactive
/// preview (no `onTap`, no button semantics).
class ValueTourPreviewRow extends StatelessWidget {
  const ValueTourPreviewRow({
    required this.title,
    required this.subtitle,
    required this.leadingAsset,
    required this.tint,
    required this.coins,
    super.key,
  });

  /// `.pv-name` content.
  final String title;

  /// `.pv-sub` content (`'<child> · <repeat>'`, the design's static copy per
  /// ORCHESTRATOR_NOTES 1).
  final String subtitle;

  /// Token icon asset for the 36dp tile.
  final String leadingAsset;

  /// Tile tint (same mapping as `NestListRow`).
  final NestTileTint tint;

  /// Coin amount for the trailing small pill.
  final String coins;

  /// `.pg-rows .icon-tile` 36px.
  static const double _tileD = 36;

  /// Tile icon size inside the 36px tile.
  static const double _tileIconD = 22;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final (Color tileBg, Color tileFg) = switch (tint) {
      NestTileTint.neutral => (tokens.surface2, tokens.ink),
      NestTileTint.leaf => (tokens.leafTint, tokens.leafInk),
      NestTileTint.coin => (tokens.coinTint, tokens.coinInk),
      NestTileTint.sky => (tokens.skyTint, tokens.sky),
      NestTileTint.lilac => (tokens.lilacTint, tokens.lilac),
      NestTileTint.peach => (tokens.peachTint, tokens.aPeach),
    };
    return Row(
      // `.pg-rows .pv-row` gap wins over the base `.pv-row` gap 10.
      spacing: NestSpacing.s2,
      children: <Widget>[
        Container(
          width: _tileD,
          height: _tileD,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tileBg,
            // Base tile quotes r16 but every render shows 12 (same
            // owner-QA note as `NestListRow`).
            borderRadius: BorderRadius.circular(NestSpacing.s3),
          ),
          child: NestIcon(leadingAsset, size: _tileIconD, color: tileFg),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ValueTourFitText(
                text: title,
                // `.pv-name` 15/20 w600 (bodySmallStrong is 15/22).
                style: NestType.bodySmallStrong(color: tokens.ink)
                    .copyWith(height: 20 / 15),
              ),
              Text(
                subtitle,
                style: NestType.caption(color: tokens.ink2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        NestCoinPill(amount: coins, size: NestCoinPillSize.small),
      ],
    );
  }
}

/// Single-line text that fits its slot without ever painting below
/// [minScale] of [style]'s size (ORCHESTRATOR_NOTES 3, P02-BUG-10).
///
/// Measures the single-line natural width with a [TextPainter] at the ambient
/// text scaler; while `slot / natural ≥ minScale` it paints in a
/// `FittedBox(scaleDown)` on one line, otherwise it renders at full size with
/// ellipsis. Scaling is only ever sub-perceptual — never a substitute for
/// layout (DESIGN_SPEC §0 rules 4/9): a starved slot keeps legible full-size
/// type (truncated) instead of shrinking to a few px. Wrapping is deliberately
/// not the fallback here: wrapped rows would overflow the spec-fixed 400dp
/// pager under the wide widget-test font, and card 2 has no room for a second
/// caption line at any width — the review sanctions ellipsis as the
/// full-size fallback.
class ValueTourFitText extends StatelessWidget {
  const ValueTourFitText({
    required this.text,
    required this.style,
    this.minScale = 0.92,
    super.key,
  });

  final String text;
  final TextStyle style;

  /// Minimum painted scale. Below it the text renders at full size with
  /// ellipsis instead of shrinking further.
  final double minScale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final slot = constraints.maxWidth;
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final natural = painter.width;
        painter.dispose();
        final fits = slot.isFinite && natural > 0 && slot / natural >= minScale;
        if (!fits) {
          return Text(
            text,
            style: style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          );
        }
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}
