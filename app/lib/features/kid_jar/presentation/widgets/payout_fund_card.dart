import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_jar/domain/entities/payout_celebration.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_amounts.dart';

/// K10's `.k10-fund` (`K10:83-88`) — the live savings-goal card: `coinTint`
/// fill, 3 px ink border, `r-l` 24, `sh-kid`, 14/16 padding, then the h2,
/// the amounts row, the kid progress bar and the two captions. Same palette
/// semantics as `JarGoalCard`, but a feature-private widget — K09's card
/// geometry must not shift, and the K10 rhythm is its own.
class PayoutFundCard extends StatelessWidget {
  const new({required this.payout, super.key});

  final PayoutCelebration payout;

  /// `.k10-fund h2` — `.kid-title` at 20/26 w900 (`K10:26`).
  static TextStyle _titleStyle(Color color) =>
      NestType.kidTitle(color: color).copyWith(fontSize: 20, height: 26 / 20);

  /// `.k10-amts b` — Nunito 17 w900; the browser's `normal` line box is
  /// 23 px there (JarGoalCard precedent, `K09-jar.html:30`).
  static TextStyle _amountStyle(Color color) =>
      NestType.kidTitle(color: color)
          .copyWith(fontSize: 17, height: 23 / 17, fontWeight: FontWeight.w900);

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final target = payout.goalTargetPence;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: NestSpacing.s4,
        vertical: NestSpacing.gap14,
      ),
      decoration: BoxDecoration(
        color: tokens.coinTint,
        borderRadius: NestRadii.allL,
        border: Border.all(
          color: tokens.ink,
          width: context.nestKid.borderWidth,
        ),
        boxShadow: tokens.kidShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            payout.goalTitle,
            style: _titleStyle(tokens.ink),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          // `.k10-amts { margin: 10px 0 6px }`. Each amount sits in a
          // `FittedBox(scaleDown)` so a money string is never ellipsized:
          // at the narrowest cell (320 px / 1.3×) the seeded `£9.49 to go`
          // needs ~4 px more than the `spaceBetween` row offers (K10-BUG-3),
          // and the box shrinks it to fit instead of cutting it mid-word.
          // Cells that already fit render at scale 1.0, pixel-identical.
          const SizedBox(height: NestSpacing.gap10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    jarPounds(payout.goalSavedPence),
                    style: _amountStyle(tokens.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: NestSpacing.s2),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${jarPounds(payout.goalRemainingPence)} to go',
                    style: _amountStyle(tokens.ink),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpacing.gap6),
          NestProgress(
            fraction: payout.goalFraction,
            kid: true,
            semanticLabel:
                '${payout.goalPercent}% of the ${payout.goalTitle} saved',
          ),
          // Second `.k10-amts`, overridden to `margin: 8px 0 0` (`K10:87`).
          const SizedBox(height: NestSpacing.s2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'of ${jarPounds(target)}',
                  style: NestType.kidCaption(color: tokens.ink2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: NestSpacing.s2),
              Flexible(
                child: Text(
                  '${payout.goalPercent}% there!',
                  style: NestType.kidCaption(color: tokens.ink2),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
