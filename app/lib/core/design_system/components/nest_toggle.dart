import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nestling/core/design_system/tokens/motion.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';

/// Parent-mode switch (51x31 track, 27dp knob).
///
/// The track IS the widget's laid-out box (51x31, `.toggle` in
/// `components.css`), so it aligns by ordinary layout. The 59x44 tap area
/// (`::before { left/right: -4px; top/bottom: -7px }`, `tapParent` 44 high)
/// overhangs it via [_ToggleHitSlop] — the same padding/overflow hit-test
/// pattern as `NestChip`'s hit slop — and never shifts the track.
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

    return _ToggleHitSlop(
      minWidth: 59,
      minHeight: NestDevice.tapParent,
      child: Semantics(
        label: semanticLabel,
        toggled: value,
        enabled: changed != null,
        onTap: changed == null ? null : () => changed(!value),
        child: Opacity(
          opacity: changed == null ? 0.45 : 1,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: changed == null ? null : () => changed(!value),
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
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
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
    );
  }
}

/// Hit-test expander that does not affect layout (same pattern as
/// `NestChip`'s `_ExpandedHitBox`).
///
/// Sizes itself to its child (the 51x31 track) and accepts taps in a
/// [minWidth]x[minHeight] box centred on it. Hits outside the child's own
/// bounds are forwarded clamped just inside, so the child's own bounds
/// check passes while the gesture arena still tracks the real pointer.
class _ToggleHitSlop extends SingleChildRenderObjectWidget {
  const _ToggleHitSlop({
    required this.minWidth,
    required this.minHeight,
    required super.child,
  });

  final double minWidth;
  final double minHeight;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderToggleHitSlop(minWidth: minWidth, minHeight: minHeight);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderToggleHitSlop renderObject,
  ) {
    renderObject
      ..minWidth = minWidth
      ..minHeight = minHeight;
  }
}

class _RenderToggleHitSlop extends RenderProxyBox {
  _RenderToggleHitSlop({required this._minWidth, required this._minHeight});

  double _minWidth;
  double get minWidth => _minWidth;
  set minWidth(double value) {
    if (value == _minWidth) return;
    _minWidth = value;
  }

  double _minHeight;
  double get minHeight => _minHeight;
  set minHeight(double value) {
    if (value == _minHeight) return;
    _minHeight = value;
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints.loosen(), parentUsesSize: true);
    size = child.size;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    final overhangX = math.max(0, (minWidth - size.width) / 2);
    final overhangY = math.max(0, (minHeight - size.height) / 2);
    if (position.dx < -overhangX ||
        position.dx > size.width + overhangX ||
        position.dy < -overhangY ||
        position.dy > size.height + overhangY) {
      return false;
    }
    const edge = 0.01;
    final forwarded = Offset(
      position.dx.clamp(0, math.max(0, size.width - edge)).toDouble(),
      position.dy.clamp(0, math.max(0, size.height - edge)).toDouble(),
    );
    return child.hitTest(result, position: forwarded);
  }
}
