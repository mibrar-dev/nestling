import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// Seven-cell day-of-week picker. [onChanged] fires with the toggled index.
class NestDayPicker extends StatelessWidget {
  const new({
    required this.days,
    required this.selected,
    required this.onChanged,
    super.key,
    this.semanticLabel,
  }) : assert(days.length == 7, 'NestDayPicker requires exactly 7 labels.');

  final List<String> days;
  final Set<int> selected;
  final ValueChanged<int> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < days.length; i++) {
      if (i > 0) {
        children.add(const SizedBox(width: NestSpacing.gap6));
      }
      final index = i;
      children.add(
        Expanded(
          child: _DayCell(
            key: ValueKey(index),
            label: days[index],
            selected: selected.contains(index),
            semanticsLabel: 'Day ${days[index]}',
            onTap: () => onChanged(index),
          ),
        ),
      );
    }

    final row = Row(children: children);
    final groupLabel = semanticLabel;
    if (groupLabel == null) {
      return row;
    }
    return Semantics(container: true, label: groupLabel, child: row);
  }
}

class _DayCell extends StatelessWidget {
  const new({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.semanticsLabel,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    const cellRadius = BorderRadius.all(Radius.circular(NestSpacing.s3));

    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: NestDevice.tapParent),
        child: Material(
          color: Colors.transparent,
          borderRadius: cellRadius,
          child: InkWell(
            borderRadius: cellRadius,
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                color: selected ? tokens.heroBg : Colors.transparent,
                borderRadius: cellRadius,
                border: selected
                    ? null
                    : Border.all(color: tokens.line, width: 1.5),
              ),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: NestDevice.tapParent,
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: NestType.chipLabel(
                      color: selected ? tokens.onHero : tokens.ink2,
                    ).copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
