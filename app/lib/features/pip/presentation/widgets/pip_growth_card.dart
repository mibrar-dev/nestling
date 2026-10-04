// K06's growth card (`.k6-grow`): "Growing into a Songbird", the kid
// progress bar and the two coin captions.
//
// `.k6-grow { background: lilac-tint; border: 3px solid ink; border-radius:
// r-l; box-shadow: sh-kid; padding: 12px 14px }` with
// `.k6-grow-top { gap: 8px; margin-bottom: 10px }` (30 px next-stage Pip +
// Nunito 900 18/24 `strong`), `.progress.kid` (16 px, 2 px ink border) and
// `.k6-count { margin-top: 8px }` (`.kcap` 15/20 w700, space-between).
// The numbers come from the database: lifetime coins out of
// [PipProfile.evolveAtCoins], never the design's hard-coded 175.
import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/components/nest_progress.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';
import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/entities/pip_profile.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_look.dart';

/// `<img src="pip-stage-4.svg" width="30" height="30">` in `.k6-grow-top`.
const double kPipGrowthAvatarSize = 30;

/// `.k6-grow { padding: 12px 14px }`.
const EdgeInsets kPipGrowthCardPadding = EdgeInsets.symmetric(
  horizontal: NestSpacing.gap14,
  vertical: NestSpacing.s3,
);

class PipGrowthCard extends StatelessWidget {
  const PipGrowthCard({
    required this.nest,
    required this.nextStageAvatar,
    super.key,
  });

  final PipNest nest;

  /// The child's own Pip one stage further on (30 px, `inNest: false`).
  final Widget nextStageAvatar;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final kid = context.nestKid;
    final profile = nest.profile;
    final nextName = pipStageName((profile.stage + 1).clamp(1, 4));
    final pct = (nest.growthFraction * 100).round();

    return Container(
      padding: kPipGrowthCardPadding,
      decoration: BoxDecoration(
        color: tokens.lilacTint,
        borderRadius: NestRadii.allL,
        border: Border.all(color: tokens.ink, width: kid.borderWidth),
        boxShadow: [
          BoxShadow(
            color: tokens.kidShadow.first.color,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            spacing: NestSpacing.s2,
            children: [
              nextStageAvatar,
              Expanded(
                child: Text(
                  'Growing into a $nextName',
                  // `.k6-grow-top strong`: Nunito 900 18 px on a 24 px line.
                  style: NestType.h3(color: tokens.ink)
                      .copyWith(fontWeight: FontWeight.w900),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: NestSpacing.gap10),
          NestProgress(
            fraction: nest.growthFraction,
            kid: true,
            // `.progress.kid` `aria-label="Pip is 70% of the way to
            // Songbird"` — the design's own words, with the percentage taken
            // from the database instead of the design's hard-coded 70
            // (`4_review.md` #11: no "a", no spelled-out "percent").
            semanticLabel: 'Pip is $pct% of the way to $nextName',
          ),
          const SizedBox(height: NestSpacing.s2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // `.kcap` is Nunito 700 15 px on a 20 px line, `--ink-2`.
              // Flexible so a large text scale ellipsizes instead of
              // overflowing (SPACING_SPEC §10.1).
              Flexible(
                child: Text(
                  '${profile.totalCoins} coins',
                  style: NestType.kidCaption(color: tokens.ink2),
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  '${PipProfile.evolveAtCoins} to grow',
                  style: NestType.kidCaption(color: tokens.ink2),
                  maxLines: 1,
                  softWrap: false,
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
