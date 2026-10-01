import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';

/// Circular icon button. [icon] is an asset path rendered via [NestIcon].
///
/// [size] is the exact hit area and must be at least 44dp.
class NestIconButton extends StatelessWidget {
  const new({
    required this.icon,
    required this.semanticLabel,
    super.key,
    this.onPressed,
    this.size = NestDevice.tapParent,
    this.iconSize = NestSpacing.s6,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  final String icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final enabled = onPressed != null;
    final background = backgroundColor ?? tokens.surface;
    final foreground = foregroundColor ?? tokens.ink;
    final border = borderColor ?? tokens.line;

    return SizedBox.square(
      dimension: size,
      child: Semantics(
        button: true,
        label: semanticLabel,
        enabled: enabled,
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Ink(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: background,
                  border: Border.all(color: border),
                  // No shadow on transparent fills: it would read as a
                  // halo (e.g. nav actions) rather than elevation.
                  boxShadow: enabled && background != Colors.transparent
                      ? tokens.cardShadow
                      : null,
                ),
                child: Center(
                  child: NestIcon(icon, size: iconSize, color: foreground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
