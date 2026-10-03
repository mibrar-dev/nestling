import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';

class NestLockButton extends StatelessWidget {
  const new({
    required this.onPressed,
    super.key,
    this.large = true,
    this.semanticLabel = 'Grown-ups only',
    this.icon,
  });

  final VoidCallback onPressed;
  final bool large;
  final String semanticLabel;
  final String? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final edge = large ? NestDevice.tapKid : NestDevice.tapParent;
    final radius = large ? 18.0 : NestSpacing.s3;
    return Semantics(
      button: true,
      label: semanticLabel,
      onTap: onPressed,
      child: Material(
        color: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: tokens.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onPressed,
          child: SizedBox(
            width: edge,
            height: edge,
            child: Center(
              child: NestIcon(icon ?? NestIcons.lock, color: tokens.ink2),
            ),
          ),
        ),
      ),
    );
  }
}
