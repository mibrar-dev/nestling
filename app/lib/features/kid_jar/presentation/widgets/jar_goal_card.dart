import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_jar/presentation/widgets/jar_amounts.dart';

/// `.k9-goal` (`K09-jar.html:70-81`): the savings-goal card — coin art, the
/// goal's name, what is saved, the kid progress bar and the two captions.
///
/// Geometry is the design's, not a guess: 3 px ink border, 14/16 padding,
/// `r-l` 24, `sh-kid`, then 34 (art row) + 12 + 23 + 6 + 16 + 8 + 20 — 153
/// tall, from `y 465` to `618` in the rendered screen.
class JarGoalCard extends StatelessWidget {
  const new({
    required this.title,
    required this.savedPence,
    required this.targetPence,
    super.key,
  });

  /// The child's goal, e.g. `Lego Friends set` (`K09-jar.html:73`).
  final String title;

  /// `£15.50` (`:76`).
  final int savedPence;

  /// `£24.99` (`:80`). Zero hides the card (`1_plan.md` §d).
  final int targetPence;

  /// `62` — the saved share, rounded (`K09-jar.html:79-80`).
  int get percent => (fraction * 100).round();

  /// Saved share of the goal, clamped to the progress bar's range.
  double get fraction =>
      targetPence <= 0 ? 0 : (savedPence / targetPence).clamp(0.0, 1.0);

  /// `£9.49 to go` — what is still missing (`K09-jar.html:77`).
  int get remainingPence => targetPence - savedPence;

  /// `.k9-goal-top img` — 34 px, the shared gold coin illustration with its
  /// own colours (`K09-jar.html:27,72`).
  static const double _artSize = 34;

  /// `.k9-amts b` — Nunito 17 w900, and the browser's `normal` line box
  /// measures 23 px at that size (`K09-jar.html:30`).
  static TextStyle _amountStyle(Color color) =>
      NestType.kidTitle(color: color)
          .copyWith(fontSize: 17, height: 23 / 17, fontWeight: FontWeight.w900);

  /// `.k9-goal h2` — `.kid-title` at 20/26 w900 (`K09-jar.html:25`).
  static TextStyle _titleStyle(Color color) =>
      NestType.kidTitle(color: color).copyWith(fontSize: 20, height: 26 / 20);

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final kid = context.nestKid;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: NestSpacing.s4,
        vertical: NestSpacing.gap14,
      ),
      decoration: BoxDecoration(
        color: tokens.coinTint,
        borderRadius: NestRadii.allL,
        border: Border.all(color: tokens.ink, width: kid.borderWidth),
        boxShadow: tokens.kidShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox.square(
                dimension: _artSize,
                child: SvgPicture.asset(NestlingIllustrations.coin),
              ),
              const SizedBox(width: NestSpacing.gap10),
              Expanded(
                child: Text(
                  title,
                  style: _titleStyle(tokens.ink),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpacing.s3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Text(
                  jarPounds(savedPence),
                  style: _amountStyle(tokens.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: NestSpacing.s2),
              // Both sides flex, so at 320 wide / 1.3x the pair shrinks
              // instead of overflowing (`1_plan.md` §e).
              Flexible(
                child: Text(
                  '${jarPounds(remainingPence)} to go',
                  style: _amountStyle(tokens.ink),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpacing.gap6),
          NestProgress(
            fraction: fraction,
            kid: true,
            semanticLabel: '$percent% of the $title saved',
          ),
          const SizedBox(height: NestSpacing.s2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'of ${jarPounds(targetPence)}',
                  style: NestType.kidCaption(color: tokens.ink2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: NestSpacing.s2),
              Flexible(
                child: Text(
                  '$percent% there!',
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
