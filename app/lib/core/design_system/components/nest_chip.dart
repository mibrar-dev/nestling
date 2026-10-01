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
            child: Text(label, style: NestType.chipLabel(color: foreground)),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: NestDevice.tapParent,
          minHeight: NestDevice.tapParent,
        ),
        child: Center(
          child: Material(
            color: Colors.transparent,
            borderRadius: NestRadii.allPill,
            child: InkWell(
              borderRadius: NestRadii.allPill,
              onTap: () => callback(!selected),
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
