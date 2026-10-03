import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart';
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_meta.dart';

/// One `.rw` reward card (P14 `design/html-source/screens/P14-rewards.html`).
///
/// Geometry measured off the light render (÷3, 1170×2532 → 390×844):
///
/// ```text
/// card   x 20 → 370 (350 wide)   y 167 → 289 (122 high)
/// tile   x 32 →  72 (40)         y 208 → 248 (centred in the 98 high column)
/// name   x 84                     15/21 w700, one line, ellipsis
/// pill   x 84, y 200 → 225 (25)   coin icon 15, padding 5/9, gap 6
/// okrow  x 84, y 233 → 277 (44)   label + gap 10 + 51×31 track (x 179)
/// edit   x 314 → 358 (44×44)     radius 12, 1 px line border, surface fill
/// ```
///
/// 122 = 12 + 21 (name) + 25 (pill) + 8 (`.okrow` margin-top) + 44
/// (`.okrow` min-height) + 12. The pill is 25, not 23: `.coin-pill` has
/// `line-height:1`, so the 15 px coin icon is the tallest flex child of the
/// 5 px-padded row.
class RewardCard extends StatelessWidget {
  const RewardCard({
    required this.reward,
    required this.onNeedsOkChanged,
    required this.onEdit,
    super.key,
  });

  final Reward reward;
  final ValueChanged<bool> onNeedsOkChanged;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final spec = rewardIconSpec(reward.icon);
    final (Color tileBg, Color tileFg) = switch (spec.tint) {
      NestTileTint.neutral => (tokens.surface2, tokens.ink),
      NestTileTint.leaf => (tokens.leafTint, tokens.leafInk),
      NestTileTint.coin => (tokens.coinTint, tokens.coinInk),
      NestTileTint.sky => (tokens.skyTint, tokens.sky),
      NestTileTint.lilac => (tokens.lilacTint, tokens.lilac),
      NestTileTint.peach => (tokens.peachTint, tokens.aPeach),
    };

    return Container(
      padding: const EdgeInsets.all(NestSpacing.s3),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: NestRadii.allM,
        boxShadow: tokens.cardShadow,
      ),
      child: Row(
        // `.rw { display:flex; align-items:center; gap:12px }`: the tile and
        // the edit button centre against the 98 px middle column.
        spacing: NestSpacing.s3,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tileBg,
              // Owner QA (see `NestListRow`): the 40 px tile renders with
              // radius 12 even though `tokens.css` quotes `--r-m`.
              borderRadius: BorderRadius.circular(NestSpacing.s3),
            ),
            alignment: Alignment.center,
            child: NestIcon(spec.asset, color: tileFg),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  reward.title,
                  style: NestType.bodySmallStrong(color: tokens.ink)
                      .copyWith(fontWeight: FontWeight.w700, height: 21 / 15),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
                NestCoinPill(
                  size: NestCoinPillSize.xSmall,
                  amount: '${reward.coinPrice}',
                  semanticLabel: '${reward.coinPrice} coins',
                ),
                const SizedBox(height: NestSpacing.s2),
                // `.okrow`: gap 10, `margin-top:8`, `min-height:44`.
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: NestDevice.tapParent,
                  ),
                  child: IntrinsicWidth(
                    // `.okrow { display:flex; align-items:center; gap:10px }`
                    // is a shrink-to-fit flex row: the label keeps its
                    // intrinsic width so the switch sits right after the gap
                    // (track x 179) instead of being pushed to the card's
                    // right edge. `IntrinsicWidth` + `Flexible(fit: loose)`
                    // reproduces `flex: 0 1 auto` — shrink-to-fit normally,
                    // capped at the column width when the card is narrow
                    // (320 px / 1.3 scale), where the label ellipsizes.
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: NestSpacing.gap10,
                      children: <Widget>[
                        // [Flexible] is loose by default (only [Expanded] is tight) — see
                        // above; the `fit:` argument is dropped as redundant.
                        Flexible(
                          child: Text(
                            RewardCopy.needsOkLabel,
                            style: NestType.fieldLabel(color: tokens.ink2),
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // `NestToggle` centres the 51×31 track inside a 59 px
                        // hit box — the Flutter equivalent of `.toggle::before
                        // { left:-4; right:-4 }`. Shifting the widget back by
                        // that 4 px keeps the visible track on the design's
                        // `gap:10` edge (track x 179) while the extra hit area
                        // still covers it.
                        Transform.translate(
                          offset: const Offset(-NestSpacing.s1, 0),
                          child: NestToggle(
                            value: reward.needsOk,
                            semanticLabel: rewardApprovalLabel(reward),
                            onChanged: onNeedsOkChanged,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _EditButton(label: rewardEditLabel(reward), onTap: onEdit),
        ],
      ),
    );
  }
}

/// `.editbtn`: exactly 44×44, radius 12, 1 px `--line` border, `--surface`
/// fill, 24 px `--ink-2` pencil. Not `NestIconButton` — that one is circular
/// and would paint the wrong background rect.
class _EditButton extends StatelessWidget {
  const _EditButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    const size = 44.0;
    return Semantics(
      button: true,
      enabled: true,
      label: label,
      onTap: onTap,
      child: Material(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(NestSpacing.s3),
        child: InkWell(
          borderRadius: BorderRadius.circular(NestSpacing.s3),
          onTap: onTap,
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(NestSpacing.s3),
              border: Border.all(color: tokens.line),
            ),
            child: Center(
              child: ExcludeSemantics(
                child: NestIcon(NestIcons.edit, color: tokens.ink2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
