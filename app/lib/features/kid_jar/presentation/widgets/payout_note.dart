import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// K10's `.k10-note` — a payout receipt row (`K10:75-78`, `K10:79-82`):
/// surface fill, 3 px ink border, `r-m` 16, `sh-kid`, 10/12 padding, a
/// 40 px icon disc on the left, and the title/subtitle stack on the right.
/// The text block flexes so 320 px / 1.3× wraps instead of overflowing.
class PayoutNote extends StatelessWidget {
  const new({
    required this.disc,
    required this.title,
    required this.subtitle,
    super.key,
  });

  /// The 40 px circle (leafTint or lilacTint) with its glyph.
  final Widget disc;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    // One spoken sentence: the title and subtitle merge into a single label.
    return Semantics(
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: NestSpacing.s3,
          vertical: NestSpacing.gap10,
        ),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: NestRadii.allM,
          border: Border.all(
            color: tokens.ink,
            width: context.nestKid.borderWidth,
          ),
          boxShadow: tokens.kidShadow,
        ),
        child: Row(
          children: [
            disc,
            const SizedBox(width: NestSpacing.gap10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // `.k10-t` — Nunito 17/22 w800. The design sets no
                  // line clamp here (`K10-payout-day.html` has no max-lines),
                  // so the title wraps freely and the card grows with
                  // content (K10-BUG-3: a 2-line cap ellipsized the seeded
                  // goal name at 320 px / 1.3×).
                  Text(
                    title,
                    style: NestType.kidTitle(color: tokens.ink).copyWith(
                      fontSize: 17,
                      height: 22 / 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  // `.k10-s` — Nunito 14/18 w700.
                  Text(
                    subtitle,
                    style: NestType.kidBody(color: tokens.ink2).copyWith(
                      fontSize: 14,
                      height: 18 / 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
