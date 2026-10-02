import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// Selectable pill chip. Static (non-interactive) when [onSelected] is null.
///
/// The pill lays out at the design size (`.chip`: 32 high,
/// `SPACING_SPEC` §6) in both branches. The interactive branch keeps a
/// ≥44×44 tap area via [_ExpandedHitBox], which widens the hit test without
/// changing layout (`SPACING_SPEC` §10.6: "keep visual size", tap area
/// overlaid) — so chip rows stay 32 tall and a `Wrap` still sees the pill's
/// intrinsic width.
class NestChip extends StatelessWidget {
  const new({
    required this.label,
    super.key,
    this.selected = false,
    this.onSelected,
    this.leading,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final foreground = selected ? tokens.leafInk : tokens.ink;
    final decoration = BoxDecoration(
      color: selected ? tokens.leafTint : tokens.surface2,
      borderRadius: NestRadii.allPill,
      border: Border.all(
        color: selected ? tokens.leaf : Colors.transparent,
        width: 1.5,
      ),
    );

    final leadingWidget = leading;
    final content = SizedBox(
      height: NestSpacing.s8,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingWidget != null) ...[
            IconTheme(
              data: IconThemeData(size: NestSpacing.s4, color: foreground),
              child: leadingWidget,
            ),
            const SizedBox(width: NestSpacing.gap6),
          ],
          Flexible(
            // The outer `Semantics(label:)` (interactive branch) owns the
            // announcement; the inner text never merges a second copy.
            child: ExcludeSemantics(
              child: Text(
                label,
                style: NestType.chipLabel(color: foreground),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ),
        ],
      ),
    );

    const visualPadding = EdgeInsets.symmetric(horizontal: NestSpacing.gap14);
    // The decorated pill is exactly 32 high. `DecoratedBox` sizes to its
    // child and paints the 1.5 border inside the box — unlike `Container`,
    // which folds a `BoxDecoration` border into its size (that was the old
    // 35 px pill: 32 content + the border on each side). Every box below
    // shrink-wraps (no `Center`/`Align`: those take the full run width and
    // would force one chip per `Wrap` row).
    Widget pill() {
      return ConstrainedBox(
        // Narrow pills (e.g. `13+`) keep a 44 minimum width, matching the
        // day-chip minimum in `SPACING_SPEC` §6.
        constraints: const BoxConstraints(minWidth: NestDevice.tapParent),
        child: Padding(
          padding: visualPadding,
          child: DecoratedBox(decoration: decoration, child: content),
        ),
      );
    }

    final callback = onSelected;
    if (callback == null) {
      return pill();
    }

    // The expander is the outermost box: every render object above it
    // (parents) forwards hits anywhere inside its own box, while the
    // `Material`/`InkWell` below it bounds-check — so only the outermost
    // position can widen the area. Outside hits are forwarded with the
    // position clamped just inside, which those bounds checks then accept.
    return _ExpandedHitBox(
      minWidth: NestDevice.tapParent,
      minHeight: NestDevice.tapParent,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        // One node per chip: the label above owns the announcement and the
        // subtree below contributes no second copy.
        excludeSemantics: true,
        // Shrink-wrap (P05): every box below sizes to the pill, so the `Wrap`
        // sees the intrinsic width and lays chips out in one row.
        child: Material(
          color: Colors.transparent,
          borderRadius: NestRadii.allPill,
          child: InkWell(
            borderRadius: NestRadii.allPill,
            onTap: () => callback(!selected),
            child: pill(),
          ),
        ),
      ),
    );
  }
}

/// Hit-test expander that does not affect layout.
///
/// Sizes itself to its child (shrink-wrap, never `constraints.biggest`) and
/// accepts taps in a [minWidth]×[minHeight] box centred on the child. Hits
/// outside the child's own bounds are forwarded with the position clamped
/// just inside, so the child's own bounds check passes while the gesture
/// arena still tracks the real pointer location (ripples and tap-up slop
/// behave normally). Ancestors that are themselves tight (e.g. a 32-high
/// `Wrap` run) cannot forward hits outside their own box — same as the
/// platform hit-slop behaviour — but roomy parents forward the full area.
class _ExpandedHitBox extends SingleChildRenderObjectWidget {
  const _ExpandedHitBox({
    required this.minWidth,
    required this.minHeight,
    required super.child,
  });

  final double minWidth;
  final double minHeight;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderExpandedHitBox(minWidth: minWidth, minHeight: minHeight);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderExpandedHitBox renderObject,
  ) {
    renderObject
      ..minWidth = minWidth
      ..minHeight = minHeight;
  }
}

class _RenderExpandedHitBox extends RenderProxyBox {
  _RenderExpandedHitBox({required this._minWidth, required this._minHeight});

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
    // Clamp into the child's bounds so its own hit test passes; the
    // recogniser still sees the true pointer location. Inset by an epsilon:
    // `Size.contains` excludes the bottom/right edge, so forwarding the
    // exact edge (e.g. y == height) would be rejected.
    const edge = 0.01;
    final forwarded = Offset(
      position.dx.clamp(0, math.max(0, size.width - edge)).toDouble(),
      position.dy.clamp(0, math.max(0, size.height - edge)).toDouble(),
    );
    return child.hitTest(result, position: forwarded);
  }
}
