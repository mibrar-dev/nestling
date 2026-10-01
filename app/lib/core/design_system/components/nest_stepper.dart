import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// Minus/plus stepper around a tabular value label.
class NestStepper extends StatelessWidget {
  const new({
    required this.valueText,
    super.key,
    this.onDecrease,
    this.onIncrease,
    this.decreaseSemanticLabel = 'Decrease',
    this.increaseSemanticLabel = 'Increase',
  });

  final String valueText;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final String decreaseSemanticLabel;
  final String increaseSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepBtn(
          key: const ValueKey('decrease'),
          label: '-',
          semanticLabel: decreaseSemanticLabel,
          onPressed: onDecrease,
        ),
        const SizedBox(width: NestSpacing.s3),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 64),
          child: Text(
            valueText,
            style: NestType.money(color: tokens.ink)
                .copyWith(fontSize: 18, height: 24 / 18),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: NestSpacing.s3),
        _StepBtn(
          key: const ValueKey('increase'),
          label: '+',
          semanticLabel: increaseSemanticLabel,
          onPressed: onIncrease,
        ),
      ],
    );
  }
}

class _StepBtn extends StatelessWidget {
  const new({
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final tapped = onPressed;
    final enabled = tapped != null;

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: SizedBox(
          width: NestDevice.tapParent,
          height: NestDevice.tapParent,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: tapped,
              child: Ink(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tokens.surface,
                  border: Border.all(color: tokens.line),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: NestType.bodyStrong(color: tokens.ink)
                        .copyWith(fontSize: 20),
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
    );
  }
}
