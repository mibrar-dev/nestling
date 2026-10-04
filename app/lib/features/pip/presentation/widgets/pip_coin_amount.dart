// K06's inline coin price row (`.k6-coin` / `.k6-item-p` in
// `design/html-source/screens/K06-pip.html`).
//
// `display:inline-flex; align-items:center; gap:4px; font-size:14px;
// font-weight:800; line-height:1` with a 16 px `assets/illustrations/coin.svg`.
// The coin is a COLOURED illustration, so it is a bare `SvgPicture` (the
// same call `family`'s child profile uses) rather than a tinted `NestIcon`.
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nestling/core/design_system/assets/nestling_assets.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// `assets/illustrations/coin.svg` at the design's 16 px.
const double kPipCoinIconSize = 16;

/// Coin + amount, used by the care buttons and the locked wardrobe tiles.
///
/// The whole row is decorative for screen readers: the control that owns it
/// announces "Feed Pip, costs 5 coins" / "Wellies, 40 coins" instead, so the
/// row is excluded to avoid a second, coin-only announcement.
class PipCoinAmount extends StatelessWidget {
  const PipCoinAmount({
    required this.amount,
    required this.color,
    super.key,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w800,
  });

  /// Digits only — the coin art carries the "coins" meaning.
  final String amount;

  /// Text colour (the design inherits it from the control: `ink` on the care
  /// buttons, `ink-2` inside a locked `.k6-item`).
  final Color color;

  /// `.k6-coin` sets `font-size:14`; kept a parameter so nothing forks it.
  final double fontSize;

  /// Weight of the digits. The care row's `.k6-coin` is w800; the locked
  /// tiles' `.k6-item-p` carries the design's w900 (4_review #5).
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: NestSpacing.s1,
        children: [
          SizedBox.square(
            dimension: kPipCoinIconSize,
            child: SvgPicture.asset(
              NestlingIllustrations.coin,
              width: kPipCoinIconSize,
              height: kPipCoinIconSize,
              placeholderBuilder: (_) => const SizedBox.shrink(),
            ),
          ),
          // Flexible so a large text scale ellipsizes the digits instead
          // of overflowing the narrow wardrobe tiles.
          Flexible(
            child: Text(
              amount,
              style: NestType.buttonKid(
                color: color,
              ).copyWith(fontSize: fontSize, fontWeight: fontWeight, height: 1),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
