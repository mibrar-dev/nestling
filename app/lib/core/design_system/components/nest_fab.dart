import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

class NestFab extends StatelessWidget {
  const new({
    required this.label,
    required this.icon,
    required this.onPressed,
    super.key,
    this.semanticLabel,
  });

  final String label;
  final String icon;
  final VoidCallback onPressed;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: Material(
        color: Colors.transparent,
        borderRadius: NestRadii.allPill,
        child: InkWell(
          borderRadius: NestRadii.allPill,
          onTap: onPressed,
          child: Ink(
            decoration: BoxDecoration(
              color: tokens.leaf,
              borderRadius: NestRadii.allPill,
              boxShadow: tokens.raisedShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: NestSpacing.s5),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: NestDevice.tapParent + NestSpacing.s2,
                  minWidth: NestDevice.tapParent + NestSpacing.s2,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    NestIcon(icon, size: 22, color: tokens.onLeaf),
                    const SizedBox(width: NestSpacing.s2),
                    Flexible(
                      child: Text(
                        label,
                        style: NestType.buttonLabel(color: tokens.onLeaf),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
