import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

enum NestTileTint { neutral, leaf, coin, sky, lilac, peach }

class NestListRow extends StatelessWidget {
  const new({
    required this.title,
    super.key,
    this.subtitle,
    this.leadingAsset,
    this.tint = NestTileTint.neutral,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final String? leadingAsset;
  final NestTileTint tint;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// `.list-trail` overflow guard (logical px).
  ///
  /// The design's trail (`components.css:119`) is `flex-shrink: 0` with no
  /// width cap — trail content is always short (chevron, `Change ›`,
  /// coin pill). The cap only bounds a pathological trailing so it cannot
  /// push the text column to zero: the widest known trailing is `Change ›`
  /// at 70.7 px, so 120 leaves every real trailing untouched while keeping
  /// ≥ 68 px for the text column even on a 320-wide screen.
  static const double trailMaxWidth = 120;

  /// P02 pager-row small variant (screen wins): 36px tile, radius 12.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final (Color tileBg, Color tileFg) = switch (tint) {
      NestTileTint.neutral => (tokens.surface2, tokens.ink),
      NestTileTint.leaf => (tokens.leafTint, tokens.leafInk),
      NestTileTint.coin => (tokens.coinTint, tokens.coinInk),
      NestTileTint.sky => (tokens.skyTint, tokens.sky),
      NestTileTint.lilac => (tokens.lilacTint, tokens.lilac),
      NestTileTint.peach => (tokens.peachTint, tokens.aPeach),
    };
    final asset = leadingAsset;
    final caption = subtitle;
    final tail = trailing;
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: _RowSlopForwarder(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
            child: Row(
              spacing: NestSpacing.s3,
              children: [
                if (asset != null)
                  Container(
                    width: compact ? 36 : 40,
                    height: compact ? 36 : 40,
                    decoration: BoxDecoration(
                      color: tileBg,
                      // Owner QA: 40px tile uses radius 12 (SPACING_SPEC
                      // quotes r16 for the base tile; the renders show 12).
                      borderRadius: BorderRadius.circular(NestSpacing.s3),
                    ),
                    alignment: Alignment.center,
                    child: NestIcon(
                      asset,
                      size: compact ? 22 : 24,
                      color: tileFg,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: NestType.bodyStrong(color: tokens.ink).copyWith(
                          fontWeight: FontWeight.w600,
                          height: 22 / 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (caption != null)
                        Text(
                          caption,
                          style: NestType.caption(color: tokens.ink2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // `.list-trail { flex-shrink: 0 }` (components.css:119): the
                // trailing takes its intrinsic width at the right edge and
                // never joins the flex distribution. (`Flexible` gives the
                // trail an equal flex share, starving the text column to half
                // the free width and parking the chevron mid-row.) The
                // `Row(spacing: s3)` gap above is the design's 12px gap.
                // The cap is an overflow guard only: while the trailing fits,
                // the `Expanded` text column keeps the remainder; only a wider
                // trailing is clamped.
                //
                // Toggle rows (P16): the trailing lays out at the track's
                // 51×31 (never a 44-high box — that plus the row's 10 px
                // padding grows the row 56 → 64). The 44 px tap minimum
                // overhangs the row padding via hit slop ([_TrailingSlop] +
                // [_RowSlopForwarder], the same padding/overflow pattern as
                // `NestChip`/`NestToggle`), so the row stays 56.
                if (tail != null)
                  _TrailingSlop(maxWidth: trailMaxWidth, child: tail),
              ],
            ),
          ),
        ),
      ),
    );
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: content,
    );
    if (onTap != null) {
      final tap = onTap;
      final explicit = semanticLabel;
      // One control = one node: the label owns the announcement and the
      // subtree contributes no second copy. `excludeSemantics` drops the
      // inner InkWell's duplicate tap node (the shared wart pinned by P16
      // `settings_a11y_test.dart`); `onTap` mirrors the InkWell so the
      // surviving node stays operable. The subtitle is part of the
      // announcement today (outer + inner merge), so it is folded into the
      // label when the caller did not provide an explicit one.
      final String label;
      if (explicit != null) {
        label = explicit;
      } else if (caption != null && caption.isNotEmpty) {
        label = '$title, $caption';
      } else {
        label = title;
      }
      return Semantics(
        button: true,
        enabled: true,
        label: label,
        excludeSemantics: true,
        onTap: tap,
        child: row,
      );
    }
    // Static rows get their own container node so their text does not fold
    // into the next tappable row's announcement (P16 Family list → Invite).
    // Plain container only — no label, no tap — so the
    // ACCESSIBILITY-ACTIONS rule is untouched.
    return Semantics(container: true, child: row);
  }
}

/// Trailing wrapper that lays out at the child's intrinsic size (capped at
/// [maxWidth]) but accepts the toggle's 59×44 tap area.
///
/// Replaces the old `ConstrainedBox(maxWidth:)` (shared batch 6): a plain
/// constrained box bounds-checks at its laid-out size (51×31 for a toggle)
/// and clips the 6.5 px of vertical slop before the NestToggle hit slop
/// ever sees it. This box uses the same padding/overflow
/// hit-test pattern as `NestChip._ExpandedHitBox` — size = child size,
/// hits in the centred 59×44 box are forwarded clamped just inside — so a
/// `NestToggle` trailing keeps its full tap target without growing the row.
class _TrailingSlop extends SingleChildRenderObjectWidget {
  const _TrailingSlop({required super.child, required this.maxWidth});

  final double maxWidth;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderTrailingSlop(maxWidth: maxWidth);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderTrailingSlop renderObject,
  ) {
    renderObject.maxWidth = maxWidth;
  }
}

class _RenderTrailingSlop extends RenderProxyBox {
  _RenderTrailingSlop({required this._maxWidth});

  double _maxWidth;
  double get maxWidth => _maxWidth;
  set maxWidth(double value) {
    if (value == _maxWidth) return;
    _maxWidth = value;
    markNeedsLayout();
  }

  // The toggle's overlaid tap area (`NestToggle` 59×44, `.toggle::before`
  // −4/−7). The wrapper lays out at the child's size and only widens the
  // hit test; chevron/text trailings have no gesture so the extra area is
  // harmless for them.
  static const double _minWidth = 59;
  static const double _minHeight = 44;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    final capped = constraints.copyWith(
      maxWidth: math.min(constraints.maxWidth, _maxWidth),
    );
    child.layout(capped.loosen(), parentUsesSize: true);
    size = child.size;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    final overhangX = math.max(0, (_minWidth - size.width) / 2);
    final overhangY = math.max(0, (_minHeight - size.height) / 2);
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

/// Forwarder around the row's padded content that lets the trailing's hit
/// slop overhang the row padding.
///
/// Flutter hit testing stops at the first ancestor whose own bounds do not
/// contain the point: a tap 5 px above the 51×31 track is inside the row's
/// 10 px padding but outside the inner `Row` (31–40 high), so the `Row`
/// rejects it before the trailing slop or NestToggle ever see it. This box
/// sizes itself exactly like its child (layout identical) but, when the
/// normal path fails, retries the trailing directly — bypassing the `Row`'s
/// bounds check. Only a trailing slop render is retried, so rows
/// without a trailing behave exactly as before.
class _RowSlopForwarder extends SingleChildRenderObjectWidget {
  const _RowSlopForwarder({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderRowSlopForwarder();
  }
}

class _RenderRowSlopForwarder extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    if (child.hitTest(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    // Normal path failed (tap in the row padding but outside the inner
    // Row): retry the trailing slop box directly.
    final padding = child;
    if (padding is RenderShiftedBox) {
      final row = padding.child;
      if (row is RenderFlex) {
        RenderBox? trailing;
        final last = row.lastChild;
        // `RenderFlex.lastChild` is typed via the container mixin; guard
        // the cast so a future SDK shape cannot throw in hit test.
        if (last is RenderBox) trailing = last;
        final target = trailing;
        if (target is _RenderTrailingSlop) {
          final rowOffset = (row.parentData! as BoxParentData).offset;
          final trailingOffset =
              (target.parentData! as FlexParentData).offset + rowOffset;
          final relative = position - trailingOffset;
          if (target.hitTest(result, position: relative)) {
            result.add(BoxHitTestEntry(this, position));
            return true;
          }
        }
      }
    }
    return false;
  }
}

class NestList extends StatelessWidget {
  const new({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: NestRadii.allM,
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Separators are absolutely-positioned 1px overlays (P04): the
          // design draws `.list-row + .list-row::before` over the row
          // boundary, so N × 56px rows stay N × 56. A real `Divider(height:
          // 1)` widget adds 1px of layout height per divider and drifts
          // every later row. The overlay keeps the 72px indent + line token
          // and contributes zero height.
          for (var i = 0; i < children.length; i++)
            if (i == 0)
              children[i]
            else
              Stack(
                children: [
                  children[i],
                  Positioned(
                    top: 0,
                    left: 72,
                    right: 0,
                    child: Container(height: 1, color: tokens.line),
                  ),
                ],
              ),
        ],
      ),
    );
  }
}
