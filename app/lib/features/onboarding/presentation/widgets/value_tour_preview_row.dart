import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// P02-only quest preview row at the design's `.pv-row` metrics.
///
/// `NestListRow` cannot express this row: its fixed vertical padding and
/// 56dp min-height make every compact row 60dp, but the design's pager card
/// is 400dp tall with 38dp rows (SPACING_SPEC §7, `P02-value-tour.html:29-33`).
/// This widget composes shared primitives (`NestIcon`, `NestCoinPill`,
/// `NestType`/token colours) at the design metrics instead of forking the
/// shared component. Retire it in favour of the shared compact-row variant
/// requested in `docs/screens/P02/SHARED_REQUEST.md` once that lands.
///
/// Metrics (HTML source, logical px): 36 tile, r12, icon 22; title 15/20
/// w600 single-line ellipsis; sub 13/18 ink2 single-line ellipsis; internal
/// gap 8; small coin pill; no vertical padding (row height = max(36, 20+18)
/// = 38). Non-interactive preview (no `onTap`, no button semantics).
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

  /// `.pv-sub` content (`'<child> · <repeat>'` from the seeded quest rows).
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
              Text(
                title,
                // `.pv-name` 15/20 w600 (bodySmallStrong is 15/22).
                style: NestType.bodySmallStrong(color: tokens.ink)
                    .copyWith(height: 20 / 15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
