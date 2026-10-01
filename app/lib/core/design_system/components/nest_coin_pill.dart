import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nestling/core/design_system/assets/nestling_assets.dart'
    as nest_assets;
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// Coin pill sizes: base 16px pill, the P02 pager-row small (14px), the P08
/// inline x-small (13px), plus the `.coin-pill.big` large from the spec.
enum NestCoinPillSize { small, standard, large, xSmall }

class NestCoinPill extends StatelessWidget {
  const new({
    required this.amount,
    super.key,
    this.size = NestCoinPillSize.standard,
    this.semanticLabel,
  });

  final String amount;
  final NestCoinPillSize size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final double fontSize;
    final EdgeInsetsGeometry padding;
    final double iconSize;
    switch (size) {
      case NestCoinPillSize.small:
        // P02 pager rows (screen wins): 14px, `7px 10px`, icon 18.
        fontSize = 14;
        padding = const EdgeInsets.symmetric(
          horizontal: NestSpacing.gap10,
          vertical: NestSpacing.gap7,
        );
        iconSize = 18;
      case NestCoinPillSize.xSmall:
        // P08 quest-row inline: 13px, `5px 9px`, icon 15.
        fontSize = 13;
        padding = const EdgeInsets.symmetric(
          horizontal: NestSpacing.gap9,
          vertical: NestSpacing.gap5,
        );
        iconSize = 15;
      case NestCoinPillSize.standard:
        fontSize = 16;
        padding = const EdgeInsets.symmetric(
          horizontal: NestSpacing.s3,
          vertical: NestSpacing.s2,
        );
        iconSize = 20;
      case NestCoinPillSize.large:
        fontSize = 20;
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
        iconSize = 20;
    }
    final style = NestType.coinPill(color: tokens.coinInk)
        .copyWith(fontSize: fontSize, height: 1);
    return Semantics(
      label: semanticLabel ?? '$amount coins',
      excludeSemantics: true,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: tokens.coinTint,
          borderRadius: NestRadii.allPill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: NestSpacing.gap6,
          children: [
            ExcludeSemantics(
              child: SvgPicture.asset(
                nest_assets.NestlingIllustrations.coin,
                width: iconSize,
                height: iconSize,
                placeholderBuilder: (_) => const SizedBox.shrink(),
              ),
            ),
            Flexible(
              child: Text(
                amount,
                style: style,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
