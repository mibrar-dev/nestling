import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nestling/core/design_system/components/nest_chip.dart';

/// Row of chips that keeps the full 44 px tap target without changing
/// the 32 px layout.
///
/// A plain `Wrap` (or `Row`) of [NestChip] is exactly 32 px high per run,
/// so Flutter hit testing — which stops at the first ancestor whose own
/// bounds do not contain the point — never forwards taps in the 6 px
/// above/below the first/last run to the chip's expanded hit box. This
/// widget lays out identically to [Wrap] but its render object also
/// forwards points up to [NestChip.hitSlop] outside its bounds (all four
/// sides) to its children, and taps landing within [NestChip.hitSlop] of
/// a chip (including the spacing gaps between two chips) go to the
/// nearest chip. Taps farther away fall through to whatever is behind.
///
/// Covers single rows too: a one-run [NestChipWrap] behaves like a `Row`
/// with wrapping disabled, so no separate `NestChipRow` is needed — use
/// this for every chip row.
class NestChipWrap extends MultiChildRenderObjectWidget {
  const new({
    super.key,
    this.spacing = 0.0,
    this.runSpacing = 0.0,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    super.children,
  });

  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAxisAlignment;

  @override
  RenderNestChipWrap createRenderObject(BuildContext context) {
    return RenderNestChipWrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderNestChipWrap renderObject,
  ) {
    renderObject
      ..spacing = spacing
      ..runSpacing = runSpacing
      ..alignment = alignment
      ..crossAxisAlignment = crossAxisAlignment
      ..textDirection = Directionality.maybeOf(context);
  }
}

/// Render object for [NestChipWrap]. Layout is exactly [RenderWrap]
/// (no overrides), so screens do not move. Only [hitTest] is widened.
class RenderNestChipWrap extends RenderWrap {
  RenderNestChipWrap({
    super.spacing,
    super.runSpacing,
    super.alignment,
    super.crossAxisAlignment,
    super.textDirection,
    super.direction = Axis.horizontal,
    super.runAlignment = WrapAlignment.start,
    super.verticalDirection = VerticalDirection.down,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    const slop = NestChip.hitSlop;
    if (position.dx < -slop ||
        position.dx > size.width + slop ||
        position.dy < -slop ||
        position.dy > size.height + slop) {
      return false;
    }
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    // Gap or outer-slop tap within [NestChip.hitSlop] of a chip: forward
    // to the nearest chip. Farther taps fall through (return false) so
    // whatever is behind handles them instead of creating a phantom target.
    RenderBox? nearest;
    var nearestDist = double.infinity;
    var child = firstChild;
    while (child != null) {
      final offset = (child.parentData! as WrapParentData).offset;
      final dx = position.dx < offset.dx
          ? offset.dx - position.dx
          : position.dx > offset.dx + child.size.width
          ? position.dx - (offset.dx + child.size.width)
          : 0.0;
      final dy = position.dy < offset.dy
          ? offset.dy - position.dy
          : position.dy > offset.dy + child.size.height
          ? position.dy - (offset.dy + child.size.height)
          : 0.0;
      final dist = dx * dx + dy * dy;
      if (dist < nearestDist) {
        nearestDist = dist;
        nearest = child;
      }
      child = childAfter(child);
    }
    // Squared Euclidean distance: gap middles sit 4 px from a chip edge
    // (16 <= 36) while a 20 px-away tap (400 > 36) falls through.
    if (nearestDist > slop * slop) return false;
    final target = nearest;
    if (target == null) return false;
    // Forward to the chip centre (always inside the stadium, unlike a
    // clamped edge point which can land outside the rounded ends and be
    // rejected by the InkWell's shape-aware hit test).
    final forwarded = Offset(target.size.width / 2, target.size.height / 2);
    if (target.hitTest(result, position: forwarded)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
