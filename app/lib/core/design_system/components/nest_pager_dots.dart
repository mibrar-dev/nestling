import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/motion.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';

class NestPagerDots extends StatelessWidget {
  const new({
    required this.count,
    required this.index,
    super.key,
    this.onDotTapped,
  });

  final int count;
  final int index;
  final ValueChanged<int>? onDotTapped;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final duration = NestMotion.resolve(context, NestMotion.fast);
    final curve = NestMotion.resolveCurve(context, NestMotion.fastCurve);
    final tapHandler = onDotTapped;
    return Semantics(
      label: 'Page ${index + 1} of $count',
      child: SizedBox(
        height: 18,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              Semantics(
                button: tapHandler != null,
                selected: i == index,
                label: tapHandler == null ? null : 'Go to page ${i + 1}',
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: tapHandler == null ? null : () => tapHandler(i),
                  child: Container(
                    // Half-gap 3 each side = 6px visual gap between dots.
                    padding: const EdgeInsets.symmetric(
                      horizontal: NestSpacing.gap3,
                    ),
                    child: Center(
                      child: AnimatedContainer(
                        duration: duration,
                        curve: curve,
                        width: i == index ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: NestRadii.allPill,
                          color: i == index ? tokens.leaf : tokens.line,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
