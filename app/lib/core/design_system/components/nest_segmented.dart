import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// One option inside [NestSegmented].
class NestSegmentOption<T> {
  const new({required this.value, required this.label});

  final T value;
  final String label;
}

/// Pill segmented control: 52px track, 4px padding, 44px buttons.
///
/// `.segmented` is `padding:4px` around buttons whose `min-height:44px` beats
/// `height:40px` (components.css self-conflict — rendered height 44), so the
/// track is 4 + 44 + 4 = 52. The selected pill keeps r-pill and its sh-1
/// shadow, which paints fully visible (nothing in the tree clips it). In
/// dark mode the thumb drops the shadow for a 1px line-colour border
/// instead — shadows render invisible/dirty on dark.
///
/// Narrow widths (P12-BUG-04): when the track cannot fit every option at
/// 44 px (`contentWidth < options * 44 + gaps`), the control switches to a
/// horizontally scrollable track where every segment keeps a fixed 44 px
/// width (so the tap target never shrinks) and the selected segment is
/// scrolled into view. At 390 dp every roster used in the app still fits,
/// so the layout is byte-for-byte the old `Expanded` row.
class NestSegmented<T> extends StatefulWidget {
  const new({
    required this.options,
    required this.value,
    required this.onChanged,
    super.key,
    this.semanticLabel,
  });

  final List<NestSegmentOption<T>> options;
  final T value;
  final ValueChanged<T>? onChanged;
  final String? semanticLabel;

  @override
  State<NestSegmented<T>> createState() => _NestSegmentedState<T>();
}

class _NestSegmentedState<T> extends State<NestSegmented<T>> {
  late final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Scrolls the horizontal track just enough to make the selected segment
  /// fully visible (minimal scroll, no-op when already visible). Only the
  /// horizontal controller moves — never an ancestor vertical scroller —
  /// so the track never leaves the viewport it was laid out in.
  void _revealSelected() {
    if (!_scroll.hasClients) return;
    final index = widget.options.indexWhere((o) => o.value == widget.value);
    if (index < 0) return;
    const seg = NestDevice.tapParent;
    const gap = NestSpacing.s1;
    final start = index * (seg + gap);
    final end = start + seg;
    final viewport = _scroll.position.viewportDimension;
    final offset = _scroll.offset;
    double? target;
    if (start < offset - 0.01) {
      target = start;
    } else if (end > offset + viewport + 0.01) {
      target = end - viewport;
    }
    if (target != null) {
      final max = _scroll.position.maxScrollExtent;
      _scroll.jumpTo(target.clamp(0, math.max(0, max)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: Container(
        // `.segmented`: 4 px padding around 44 px buttons = 52 px track.
        height: NestDevice.tapParent + NestSpacing.s2,
        padding: const EdgeInsets.all(NestSpacing.s1),
        decoration: BoxDecoration(
          color: tokens.surface2,
          borderRadius: NestRadii.allPill,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final n = widget.options.length;
            // Viewport inside the 4 px track padding. Unbounded parents
            // (intrinsic probes) keep the old Expanded row.
            final viewport = constraints.maxWidth;
            final needed =
                n * NestDevice.tapParent +
                (n > 0 ? (n - 1) * NestSpacing.s1 : 0);
            final fits =
                !constraints.hasBoundedWidth || viewport + 0.01 >= needed;
            if (fits) {
              return Row(children: _expandedChildren(context, tokens));
            }
            // Narrow: fixed 44 px segments in a scrollable row. Scheduled
            // after layout so the selected segment is visible without
            // moving anything at 390 dp (which never takes this branch).
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _revealSelected(),
            );
            return SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              child: Row(children: _scrollableChildren(context, tokens)),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _expandedChildren(BuildContext context, NestTokens tokens) {
    final changed = widget.onChanged;
    final children = <Widget>[];
    for (var i = 0; i < widget.options.length; i++) {
      if (i > 0) {
        children.add(const SizedBox(width: NestSpacing.s1));
      }
      final option = widget.options[i];
      final isSelected = option.value == widget.value;
      children.add(
        Expanded(
          child: SizedBox(
            height: NestDevice.tapParent,
            child: _optionSemantics(
              option: option,
              isSelected: isSelected,
              enabled: changed != null,
              tokens: tokens,
              onTap: changed == null ? null : () => changed(option.value),
            ),
          ),
        ),
      );
    }
    return children;
  }

  List<Widget> _scrollableChildren(BuildContext context, NestTokens tokens) {
    final changed = widget.onChanged;
    final children = <Widget>[];
    for (var i = 0; i < widget.options.length; i++) {
      if (i > 0) {
        children.add(const SizedBox(width: NestSpacing.s1));
      }
      final option = widget.options[i];
      final isSelected = option.value == widget.value;
      children.add(
        SizedBox(
          width: NestDevice.tapParent,
          height: NestDevice.tapParent,
          child: _optionSemantics(
            option: option,
            isSelected: isSelected,
            enabled: changed != null,
            tokens: tokens,
            onTap: changed == null ? null : () => changed(option.value),
          ),
        ),
      );
    }
    return children;
  }

  Widget _optionSemantics({
    required NestSegmentOption<T> option,
    required bool isSelected,
    required bool enabled,
    required NestTokens tokens,
    required VoidCallback? onTap,
  }) {
    // One node per option: the label above owns the announcement
    // and the inner Text/InkWell contribute no second copy (same
    // as NestChip). `onTap` mirrors the InkWell below:
    // `excludeSemantics` drops every descendant action, so without
    // this the node says "button" but cannot be activated.
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: enabled,
      label: option.label,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        borderRadius: NestRadii.allPill,
        child: InkWell(
          borderRadius: NestRadii.allPill,
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              color: isSelected ? tokens.surface : Colors.transparent,
              borderRadius: NestRadii.allPill,
              border: isSelected && tokens.isDark
                  ? Border.all(color: tokens.line)
                  : null,
              boxShadow: isSelected && !tokens.isDark
                  ? tokens.cardShadow
                  : null,
            ),
            child: Center(
              child: Text(
                option.label,
                style: isSelected
                    ? NestType.chipLabel(color: tokens.ink)
                    : NestType.chipLabel(color: tokens.ink2)
                          .copyWith(fontWeight: FontWeight.w500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
