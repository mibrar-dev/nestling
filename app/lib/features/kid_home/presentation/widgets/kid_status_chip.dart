import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// K03 status chip (`.kchip` in K03-kid-home.html).
///
/// Static (non-interactive) leaf-tint pill: h32, padding `0 12px`, r-pill,
/// Nunito 800 15/15. `NestChip` is parent-mode Inter 14, so K03 needs this
/// feature-private chip. Used for the section "X of Y done" chip and the
/// card meta chips ("Waiting for Mum", "Done").
// SHARED_REQUEST #7 landed: the label is now NestType.kidChipLabel.
class KidStatusChip extends StatelessWidget {
  const new({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Container(
      height: NestSpacing.s8,
      padding: const EdgeInsets.symmetric(horizontal: NestSpacing.s3),
      decoration: BoxDecoration(
        color: tokens.leafTint,
        borderRadius: NestRadii.allPill,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: NestType.kidChipLabel(color: tokens.leafInk),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
