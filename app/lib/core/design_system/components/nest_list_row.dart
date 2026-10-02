import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

enum NestTileTint { neutral, leaf, coin, sky, lilac, peach }

class NestListRow extends StatelessWidget {
  const new({
    required this.title,
    super.key,
    this.subtitle,
    this.leadingAsset,
    this.tint = NestTileTint.neutral,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final String? leadingAsset;
  final NestTileTint tint;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// P02 pager-row small variant (screen wins): 36px tile, radius 12.
  final bool compact;

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
    final asset = leadingAsset;
    final caption = subtitle;
    final tail = trailing;
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
          child: Row(
            spacing: NestSpacing.s3,
            children: [
              if (asset != null)
                Container(
                  width: compact ? 36 : 40,
                  height: compact ? 36 : 40,
                  decoration: BoxDecoration(
                    color: tileBg,
                    // Owner QA: 40px tile uses radius 12 (SPACING_SPEC
                    // quotes r16 for the base tile; the renders show 12).
                    borderRadius: BorderRadius.circular(NestSpacing.s3),
                  ),
                  alignment: Alignment.center,
                  child: NestIcon(
                    asset,
                    size: compact ? 22 : 24,
                    color: tileFg,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: NestType.bodyStrong(
                        color: tokens.ink,
                      ).copyWith(fontWeight: FontWeight.w600, height: 22 / 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (caption != null)
                      Text(
                        caption,
                        style: NestType.caption(color: tokens.ink2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (tail != null) Flexible(child: tail),
            ],
          ),
        ),
      ),
    );
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: content,
    );
    if (onTap != null) {
      return Semantics(button: true, label: semanticLabel ?? title, child: row);
    }
    return row;
  }
}

class NestList extends StatelessWidget {
  const new({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: NestRadii.allM,
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Separators are absolutely-positioned 1px overlays (P04): the
          // design draws `.list-row + .list-row::before` over the row
          // boundary, so N × 56px rows stay N × 56. A real `Divider(height:
          // 1)` widget adds 1px of layout height per divider and drifts
          // every later row. The overlay keeps the 72px indent + line token
          // and contributes zero height.
          for (var i = 0; i < children.length; i++)
            if (i == 0)
              children[i]
            else
              Stack(
                children: [
                  children[i],
                  Positioned(
                    top: 0,
                    left: 72,
                    right: 0,
                    child: Container(height: 1, color: tokens.line),
                  ),
                ],
              ),
        ],
      ),
    );
  }
}
