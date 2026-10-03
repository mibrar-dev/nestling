import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// One option inside [NestSegmented].
class NestSegmentOption<T> {
  const new({required this.value, required this.label});

  final T value;
  final String label;
}

/// Pill segmented control: 52px track, 4px padding, 44px buttons.
///
/// `.segmented` is `padding:4px` around buttons whose `min-height:44px` beats
/// `height:40px` (components.css self-conflict — rendered height 44), so the
/// track is 4 + 44 + 4 = 52. The selected pill keeps r-pill and its sh-1
/// shadow, which paints fully visible (nothing in the tree clips it). In
/// dark mode the thumb drops the shadow for a 1px line-colour border
/// instead — shadows render invisible/dirty on dark.
class NestSegmented<T> extends StatelessWidget {
  const new({
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
    this.semanticLabel,
  });

  final List<NestSegmentOption<T>> options;
  final T value;
  final ValueChanged<T>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final changed = onChanged;

    final children = <Widget>[];
    for (var i = 0; i < options.length; i++) {
      if (i > 0) {
        children.add(const SizedBox(width: NestSpacing.s1));
      }
      final option = options[i];
      final isSelected = option.value == value;
      children.add(
        Expanded(
          child: SizedBox(
            height: NestDevice.tapParent,
            child: Semantics(
              button: true,
              selected: isSelected,
              enabled: changed != null,
              label: option.label,
              // One node per option: the label above owns the announcement
              // and the inner Text/InkWell contribute no second copy (same
              // as NestChip). `onTap` mirrors the InkWell below:
              // `excludeSemantics` drops every descendant action, so without
              // this the node says "button" but cannot be activated.
              excludeSemantics: true,
              onTap: changed == null ? null : () => changed(option.value),
              child: Material(
                color: Colors.transparent,
                borderRadius: NestRadii.allPill,
                child: InkWell(
                  borderRadius: NestRadii.allPill,
                  onTap: changed == null ? null : () => changed(option.value),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: isSelected ? tokens.surface : Colors.transparent,
                      borderRadius: NestRadii.allPill,
                      border: isSelected && tokens.isDark
                          ? Border.all(color: tokens.line)
                          : null,
                      boxShadow: isSelected && !tokens.isDark
                          ? tokens.cardShadow
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        option.label,
                        style: isSelected
                            ? NestType.chipLabel(color: tokens.ink)
                            : NestType.chipLabel(color: tokens.ink2)
                                  .copyWith(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        // `.segmented`: 4 px padding around 44 px buttons = 52 px track.
        height: NestDevice.tapParent + NestSpacing.s2,
        padding: const EdgeInsets.all(NestSpacing.s1),
        decoration: BoxDecoration(
          color: tokens.surface2,
          borderRadius: NestRadii.allPill,
        ),
        child: Row(children: children),
      ),
    );
  }
}
