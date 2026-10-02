import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/motion.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// Visual variants for [NestButton].
enum NestButtonVariant { primary, secondary, ghost, dangerGhost }

/// Parent-mode pill button (52dp, full-width by default).
///
/// Labels are dynamic: they wrap instead of ellipsizing, and auto-width
/// buttons size to their intrinsic content (min width 88, 20px sides).
/// Pressed: `translateY(1px)` + shadow while pressed (spec §2). Focused
/// (keyboard): 3px leaf outline outside the pill. Disabled: `opacity .45`,
/// no shadow, `onPressed:null`.
///
/// Contextual overrides (screen wins) are exposed without new widget types:
/// pass [fontSize] 15 + [horizontalPadding] 18 for the P08 banner button,
/// [fontSize] 15 + [horizontalPadding] 12 + [minHeight] 48 for P11 approval
/// rows / P12 row buttons.
class NestButton extends StatefulWidget {
  const new({
    required this.label,
    super.key,
    this.onPressed,
    this.variant = NestButtonVariant.primary,
    this.leading,
    this.loading = false,
    this.fullWidth = true,
    this.minHeight = 52,
    this.semanticLabel,
    this.fontSize,
    this.horizontalPadding = NestSpacing.s5,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onPressed;
  final NestButtonVariant variant;
  final Widget? leading;
  final bool loading;
  final bool fullWidth;
  final double minHeight;
  final String? semanticLabel;

  /// Contextual font-size override (base 16). Pass 15 for P08/P11/P12 rows.
  final double? fontSize;

  /// Contextual horizontal padding override (base 20 = `s5`).
  final double horizontalPadding;

  final FocusNode? focusNode;

  @override
  State<NestButton> createState() => _NestButtonState();
}

class _NestButtonState extends State<NestButton> {
  bool _pressed = false;
  bool _focused = false;
  FocusNode? _ownedNode;

  FocusNode get _node => widget.focusNode ?? _ownedNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _ownedNode = FocusNode();
    }
    _node.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(covariant NestButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocus);
      _ownedNode?.dispose();
      _ownedNode = widget.focusNode == null ? FocusNode() : null;
      _node.addListener(_onFocus);
    }
  }

  void _onFocus() => setState(() => _focused = _node.hasFocus);

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _ownedNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final disabled = widget.onPressed == null || widget.loading;

    final Color background;
    final Color foreground;
    final BoxBorder? border;
    final List<BoxShadow>? shadows;
    switch (widget.variant) {
      case NestButtonVariant.primary:
        background = tokens.leaf;
        foreground = tokens.onLeaf;
        border = null;
        shadows = null;
      case NestButtonVariant.secondary:
        background = tokens.surface;
        foreground = tokens.ink;
        border = Border.all(color: tokens.line);
        shadows = tokens.cardShadow;
      case NestButtonVariant.ghost:
        background = Colors.transparent;
        foreground = tokens.ink;
        border = null;
        shadows = null;
      case NestButtonVariant.dangerGhost:
        background = Colors.transparent;
        foreground = tokens.danger;
        border = null;
        shadows = null;
    }

    final Widget? prefix;
    final leadingWidget = widget.leading;
    if (widget.loading) {
      prefix = ExcludeSemantics(
        child: SizedBox.square(
          dimension: NestSpacing.s5,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: foreground),
        ),
      );
    } else if (leadingWidget != null) {
      prefix = IconTheme(
        data: IconThemeData(size: 20, color: foreground),
        child: leadingWidget,
      );
    } else {
      prefix = null;
    }

    final labelStyle = NestType.buttonLabel(color: foreground).copyWith(
      fontSize: widget.fontSize,
      height: widget.fontSize == null ? 24 / 16 : null,
    );

    final tap = widget.onPressed;
    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.label,
      enabled: !disabled,
      focused: _focused,
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: SizedBox(
          width: widget.fullWidth ? double.infinity : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: NestDevice.tapParent * 2,
              minHeight: widget.minHeight,
            ),
            child: Focus(
              focusNode: _node,
              canRequestFocus: !disabled,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: disabled
                    ? null
                    : (_) => setState(() => _pressed = true),
                onTapUp: disabled
                    ? null
                    : (_) => setState(() => _pressed = false),
                onTapCancel: disabled
                    ? null
                    : () => setState(() => _pressed = false),
                onTap: disabled ? null : tap,
                child: AnimatedContainer(
                  duration: NestMotion.resolve(context, NestMotion.fast),
                  transform: Matrix4.translationValues(
                    0,
                    _pressed && !disabled ? 1 : 0,
                    0,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.horizontalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: NestRadii.allPill,
                    border: border,
                    boxShadow: <BoxShadow>[
                      if (!disabled && shadows != null) ...shadows,
                      if (!disabled && _pressed) ...tokens.cardShadow,
                      if (_focused)
                        BoxShadow(
                          color: tokens.leaf,
                          spreadRadius: NestSpacing.gap3,
                        ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (prefix != null) ...[
                          prefix,
                          const SizedBox(width: NestSpacing.s2),
                        ],
                        Flexible(
                          // One announcement per button (P03 §4): the outer
                          // `Semantics(label:)` owns the label, so the inner
                          // text must not merge a second copy.
                          child: ExcludeSemantics(
                            child: Text(
                              widget.label,
                              style: labelStyle,
                              textAlign: TextAlign.center,
                            ),
                          ),
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
