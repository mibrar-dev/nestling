import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// P10 filter chip — `.chipscroll .chip`.
///
/// The design lifts `.chip` from the 32 px design-system pill to
/// `min-height:44px` (`SPACING_SPEC` §9.5) because this row scrolls rather
/// than wraps, so the whole pill is already a 44 px tap target and
/// [NestChip]'s extra hit slop is neither needed nor wanted. Everything
/// else (radius, `0 14px` padding, surface-2 / leaf-tint fills, 1.5 px leaf
/// selected border, Inter 14 w600) is identical to [NestChip].
class QuestFilterChip extends StatelessWidget {
  const QuestFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final foreground = selected ? tokens.leafInk : tokens.ink;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      // Required: `excludeSemantics` drops the InkWell's tap action, so the
      // node itself has to expose one or assistive technology announces a
      // button it cannot activate (P10 BUG-P10-9).
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        borderRadius: NestRadii.allPill,
        child: InkWell(
          borderRadius: NestRadii.allPill,
          onTap: onTap,
          // The pill IS the tap target (44 high), so no hit slop is needed;
          // `shrinkWrap` keeps the InkWell from padding the decoration out.
          child: Container(
            height: NestDevice.tapParent,
            padding: const EdgeInsets.symmetric(horizontal: NestSpacing.gap14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? tokens.leafTint : tokens.surface2,
              borderRadius: NestRadii.allPill,
              border: Border.all(
                color: selected ? tokens.leaf : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: NestType.chipLabel(color: foreground),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
            ),
          ),
        ),
      ),
    );
  }
}
