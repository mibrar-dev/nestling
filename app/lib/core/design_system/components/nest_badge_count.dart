import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

class NestBadgeCount extends StatelessWidget {
  const new({required this.count, super.key, this.semanticLabel});

  final int count;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Semantics(
      label: semanticLabel ?? '$count new',
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: NestSpacing.gap6),
          decoration: BoxDecoration(
            color: tokens.leaf,
            borderRadius: NestRadii.allPill,
          ),
          alignment: Alignment.center,
          child: Text(
            '$count',
            style: NestType.chipSmall(color: tokens.onLeaf),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}
