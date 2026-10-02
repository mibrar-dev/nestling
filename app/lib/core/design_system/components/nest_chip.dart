import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// Selectable pill chip. Static (non-interactive) when [onSelected] is null.
class NestChip extends StatelessWidget {
  const new({
    required this.label,
    super.key,
    this.selected = false,
    this.onSelected,
    this.leading,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final foreground = selected ? tokens.leafInk : tokens.ink;
    final decoration = BoxDecoration(
      color: selected ? tokens.leafTint : tokens.surface2,
      borderRadius: NestRadii.allPill,
      border: Border.all(
        color: selected ? tokens.leaf : Colors.transparent,
        width: 1.5,
      ),
    );

    final leadingWidget = leading;
    final content = SizedBox(
      height: NestSpacing.s8,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingWidget != null) ...[
            IconTheme(
              data: IconThemeData(size: NestSpacing.s4, color: foreground),
              child: leadingWidget,
            ),
            const SizedBox(width: NestSpacing.gap6),
          ],
          Flexible(
            // The outer `Semantics(label:)` (interactive branch) owns the
            // announcement; the inner text never merges a second copy.
            child: ExcludeSemantics(
              child: Text(label, style: NestType.chipLabel(color: foreground)),
            ),
          ),
        ],
      ),
    );

    const visualPadding = EdgeInsets.symmetric(horizontal: NestSpacing.gap14);
    final callback = onSelected;
    if (callback == null) {
      return Container(
        padding: visualPadding,
        decoration: decoration,
        child: content,
      );
    }

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      // One node per chip: the label above owns the announcement and the
      // subtree below contributes no second copy.
      excludeSemantics: true,
      // Shrink-wrap (P05): the old `ConstrainedBox → Center` took
      // `constraints.biggest`, so inside a `Wrap` run every chip reported
      // the full run width and each chip broke onto its own line. Every box
      // below sizes to the pill, so the `Wrap` sees the intrinsic width
      // and lays chips out in one row.
      child: Material(
        color: Colors.transparent,
        borderRadius: NestRadii.allPill,
        child: InkWell(
          borderRadius: NestRadii.allPill,
          onTap: () => callback(!selected),
          child: ConstrainedBox(
            // SPACING_SPEC §6: the 32-high pill is below the 44 minimum, so
            // the tap box (not the pill) carries the minimum. The pill
            // measures 35 (32 content + the 1.5 border `Ink` reserves on
            // each side), so symmetric 4.5 padding centres it in exactly
            // 44; width keeps a 44 minimum (narrow pills left-align the
            // sub-pixel slack inside it).
            constraints: const BoxConstraints(minWidth: NestDevice.tapParent),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.5),
              child: Ink(
                padding: visualPadding,
                decoration: decoration,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
