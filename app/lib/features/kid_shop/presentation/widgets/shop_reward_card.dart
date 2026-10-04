import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nestling/core/design_system/assets/nestling_assets.dart'
    as nest_assets;
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_shop/domain/entities/shop_reward.dart';
import 'package:nestling/features/kid_shop/presentation/widgets/shop_reward_icons.dart';

/// `.k8-art`: 56 px circle, `coin-tint` fill, 32 px glyph (`K08-shop.html:23`).
const double _artSize = 56;
const double _artIconSize = 32;

/// `.k8-n`: Nunito 15/19 w800 (the `h3` family, overridden size/leading).
const double _nameFontSize = 15;
const double _nameLineHeight = 19;

/// `.k8-n { min-height: 40px }` — two 19 px lines are 38, so the box holds
/// one-line names on the same baseline as two-line ones (`K08-shop.html:24`).
const double _nameMinHeight = 40;

/// `.k8-p img { width: 20px; height: 20px }` (`K08-shop.html:26`) — the coin
/// image is what makes the price row 20 tall (the label is 16/1).
const double _coinSize = 20;

/// `.k8-note`: Nunito 14/18 w700 (`K08-shop.html:27`).
const double _noteFontSize = 14;
const double _noteLineHeight = 18;

/// `.k8-get` labels (`K08-shop.html:51,58,79`): the affordable action is
/// "Get it", the out-of-reach one is "Save up!" — never a shaming "you need".
const String _getItLabel = 'Get it';
const String _saveUpLabel = 'Save up!';

/// `.k8-note` text (`K08-shop.html:78`) for a price that is out of reach.
const String _moreToGoLabel = 'more to go';

/// `.k8-get`: min-height 56, radius 16, 17 px w900 (`K08-shop.html:29`,
/// SPACING_SPEC §10.7 line 134). 56 is `--tap-kid`; 16 is `--r-m`.
const double _getMinHeight = 56;
const double _getFontSize = 17;

/// One K08 reward card — `.k8-card` (`design/html-source/screens/K08-shop.html:22`):
/// `surface` fill, 3 px ink border, `--r-l` 24, `--sh-kid` 6 px, padding 10,
/// column with 6 px gaps, everything centred.
///
/// Geometry at 390 (verified against `design/screens/light/K08-shop.png` ÷3):
/// card box y 201…417 (216 tall), art circle 214…270, name 276…316, price
/// 322…342, button 348…404.
///
/// The bottom padding is `--s1`, not the CSS `padding: 10`: `NestKidButton`
/// carries its own 6 px shadow room INSIDE its widget box (SPACING_SPEC §10.7),
/// and the CSS puts the button's `--sh-kid` shadow inside the card's 10 px
/// bottom padding. Padding 10 + the 6 px room would make the card 222 tall
/// instead of 216; `10 − 6 = 4` keeps both the card height and the shadow band
/// exactly where the design draws them (shadow 404…410, white 410…414, border
/// 414…417).
class ShopRewardCard extends StatelessWidget {
  const ShopRewardCard({
    required this.item,
    required this.coins,
    required this.requesting,
    required this.onRequest,
    super.key,
  });

  /// The reward row (repository-owned entity; only the K08 fields are used —
  /// `detail` and `needsOk` belong to P14, not to this screen).
  final ShopReward item;

  /// The child's current coin balance, for the "N more to go" note.
  final int coins;

  /// True while this reward's `Get it` write is in flight: the button shows
  /// its spinner and ignores taps.
  final bool requesting;

  /// Dispatches `KidShopRewardRequested` for this reward.
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final kid = context.nestKid;
    final affordable = item.affordable;
    final shortBy = item.coinPrice - coins;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.gap10,
        NestSpacing.gap10,
        NestSpacing.gap10,
        NestSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: NestRadii.allL,
        border: Border.all(color: tokens.ink, width: kid.borderWidth),
        boxShadow: tokens.kidShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // `.k8-card` is `flex-direction: column` with `align-items: center`
        // and no `justify-content`, so a row-stretched card (grid default
        // `align-items: stretch`) keeps its content at the TOP and the spare
        // height lands below the button, exactly like the CSS. The column's
        // default cross axis is already `center`.
        spacing: NestSpacing.gap6,
        children: [
          _ShopArt(icon: shopRewardIcon(item.icon)),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: _nameMinHeight),
            child: Center(
              child: Text(
                item.title,
                style: NestType.h3(color: tokens.ink).copyWith(
                  fontSize: _nameFontSize,
                  height: _nameLineHeight / _nameFontSize,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _ShopPrice(price: item.coinPrice),
          // `.k8-note` only exists when the price is out of reach — the shop
          // never nags a child who is saving (DESIGN_SPEC §5 K08: "disabled
          // style + Save up! — not shaming").
          if (!affordable)
            Text(
              '$shortBy $_moreToGoLabel',
              style: NestType.kidCaption(color: tokens.ink2).copyWith(
                fontSize: _noteFontSize,
                height: _noteLineHeight / _noteFontSize,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          NestKidButton(
            label: affordable ? _getItLabel : _saveUpLabel,
            // `.k8-get.off` (bg `--surface-2`, fg `--ink-2`, full opacity) has
            // no `NestKidButton` colourway yet (SHARED_REQUEST, non-blocking):
            // until it lands the unaffordable card uses the white colourway
            // disabled (`onPressed: null`), per `1_plan.md` §g.
            color: affordable
                ? NestKidButtonColor.leaf
                : NestKidButtonColor.white,
            minHeight: _getMinHeight,
            borderRadius: NestRadii.m,
            fontSize: _getFontSize,
            semanticLabel: affordable
                ? 'Get ${item.title}'
                : 'Save up for ${item.title}',
            loading: affordable && requesting,
            onPressed: affordable ? onRequest : null,
          ),
        ],
      ),
    );
  }
}

/// `.k8-art` — the coin-tint disc with the reward glyph. Decorative: the
/// reward name and price below carry the meaning, so it is excluded from
/// semantics (no VoiceOver noise, no duplicated label).
class _ShopArt extends StatelessWidget {
  const _ShopArt({required this.icon});

  final String icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Container(
      width: _artSize,
      height: _artSize,
      decoration: BoxDecoration(color: tokens.coinTint, shape: BoxShape.circle),
      child: Center(
        child: ExcludeSemantics(
          child: NestIcon(icon, size: _artIconSize, color: tokens.coinInk),
        ),
      ),
    );
  }
}

/// `.k8-p` — the coin image plus the price in `--coin-ink`, 16/1 w900, never
/// wrapping (`white-space: nowrap`, SPACING_SPEC §10.11).
class _ShopPrice extends StatelessWidget {
  const _ShopPrice({required this.price});

  final int price;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: NestSpacing.s1,
      children: [
        ExcludeSemantics(
          child: SvgPicture.asset(
            nest_assets.NestlingIllustrations.coin,
            width: _coinSize,
            height: _coinSize,
            placeholderBuilder: (_) => const SizedBox.shrink(),
          ),
        ),
        Text(
          '$price',
          style: NestType.coinPill(color: tokens.coinInk)
              .copyWith(fontWeight: FontWeight.w900, height: 1),
          maxLines: 1,
          softWrap: false,
        ),
      ],
    );
  }
}
