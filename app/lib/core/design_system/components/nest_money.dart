import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

String formatPounds(double amount) => '£${amount.toStringAsFixed(2)}';

class NestMoney extends StatelessWidget {
  const new({required this.amount, super.key, this.style, this.semanticLabel});

  final double amount;
  final TextStyle? style;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final text = formatPounds(amount);
    return Semantics(
      label: semanticLabel ?? text,
      excludeSemantics: true,
      child: Text(
        text,
        style: style ?? NestType.money(color: context.nest.ink),
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
