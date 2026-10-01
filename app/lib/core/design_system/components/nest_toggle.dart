import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/motion.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';

/// Parent-mode switch (51x31 track, 27dp knob).
class NestToggle extends StatelessWidget {
  const new({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final changed = onChanged;
    final duration = NestMotion.resolve(context, NestMotion.fast);
    final curve = NestMotion.resolveCurve(context, NestMotion.fastCurve);

    return Semantics(
      label: semanticLabel,
      toggled: value,
      enabled: changed != null,
      child: Opacity(
        opacity: changed == null ? 0.45 : 1,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: changed == null ? null : () => changed(!value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 59,
              minHeight: NestDevice.tapParent,
            ),
            child: Center(
              child: AnimatedContainer(
                duration: duration,
                curve: curve,
                width: 51,
                height: 31,
                decoration: BoxDecoration(
                  color: value ? tokens.leaf : tokens.track,
                  borderRadius: BorderRadius.circular(NestRadii.pill),
                ),
                child: AnimatedAlign(
                  duration: duration,
                  curve: curve,
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Container(
                      width: 27,
                      height: 27,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tokens.knob,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            offset: const Offset(0, 2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
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
}
