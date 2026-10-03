import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';

/// K03 status chip (`.kchip` in K03-kid-home.html).
///
/// Static (non-interactive) leaf-tint pill: h32, padding `0 12px`, r-pill,
/// Nunito 800 15/15. `NestChip` is parent-mode Inter 14, so K03 needs this
/// feature-private chip. Used for the section "X of Y done" chip and the
/// card meta chips ("Waiting for Mum", "Done").
// TODO(K03): move the label to NestType.kidChipLabel once the shared style
// lands (SHARED_REQUEST #7).
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
        style: GoogleFonts.nunito(
          fontSize: 15,
          height: 1,
          fontWeight: FontWeight.w800,
          color: tokens.leafInk,
        ),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
