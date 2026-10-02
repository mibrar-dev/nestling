import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/motion.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// Colourways for [NestKidButton].
enum NestKidButtonColor { leaf, coin, sky, peach, lilac, white }

/// Chunky kid-mode button with a press-down chunky-shadow animation.
///
/// Screen extensions (screen wins) are exposed as optional params so screens
/// never fork the widget: K06 `.k6-care` uses column axis, gap 3, min-h 88,
/// padding `8px 4px`, 17/20 label; K03 `.k3-dock` uses column axis, gap 4,
/// min-h 66, 17/20 label, padding `0 6px`; K08 `.k8-get` uses min-h 56,
/// radius 16, 17px label.
class NestKidButton extends StatefulWidget {
  const new({
    required this.label,
    super.key,
    this.onPressed,
    this.color = NestKidButtonColor.leaf,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.minHeight = 64,
    this.semanticLabel,
    this.axis = Axis.horizontal,
    this.gap = NestSpacing.s2,
    this.borderRadius = NestRadii.l,
    this.fontSize = 20,
    this.contentPadding,
    this.wrapLabel = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final NestKidButtonColor color;
  final Widget? icon;
  final bool loading;
  final bool fullWidth;
  final double minHeight;
  final String? semanticLabel;

  /// Layout axis for icon+label (K03/K06 dock buttons stack vertically).
  final Axis axis;

  /// Gap between icon and label (8 base; 4 K03 dock; 3 K06 care).
  final double gap;

  /// Corner radius (24 base; 16 for K08 `.k8-get`).
  final double borderRadius;

  /// Label size (20 base; 17 for dock/care/get extensions).
  final double fontSize;

  /// Inner padding override (base `0 24px`). K06 care uses `8px 4px`,
  /// K03 dock uses `0 6px`.
  final EdgeInsetsGeometry? contentPadding;

  /// Whether the label may wrap. Defaults to true (spec base). Pass false
  /// for narrow slots / large text scales (K03 dock "My jar" under fallback
  /// fonts): the label stays on one line and scales down instead of
  /// wrapping to two lines.
  final bool wrapLabel;

  @override
  State<NestKidButton> createState() => _NestKidButtonState();
}

class _NestKidButtonState extends State<NestKidButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final kid = context.nestKid;
    final enabled = widget.onPressed != null && !widget.loading;

    final Color background;
    final Color foreground;
    switch (widget.color) {
      case NestKidButtonColor.leaf:
        background = tokens.leaf;
        foreground = tokens.onLeaf;
      case NestKidButtonColor.coin:
        background = tokens.coin;
        foreground = tokens.onWarm;
      case NestKidButtonColor.sky:
        background = tokens.sky;
        foreground = tokens.onAccent;
      case NestKidButtonColor.peach:
        background = tokens.peach;
        foreground = tokens.onWarm;
      case NestKidButtonColor.lilac:
        background = tokens.lilacStrong;
        foreground = tokens.onAccent;
      case NestKidButtonColor.white:
        background = tokens.surface;
        foreground = tokens.ink;
    }

    final Widget? prefix;
    final iconWidget = widget.icon;
    if (widget.loading) {
      prefix = ExcludeSemantics(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: foreground),
        ),
      );
    } else if (iconWidget != null) {
      prefix = IconTheme(
        data: IconThemeData(size: 26, color: foreground),
        child: iconWidget,
      );
    } else {
      prefix = null;
    }

    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.label,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Padding(
          padding: const EdgeInsets.only(bottom: NestSpacing.gap6),
          child: SizedBox(
            width: widget.fullWidth ? double.infinity : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: kid.minTarget,
                minHeight: widget.minHeight,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: enabled
                    ? (_) => setState(() => _pressed = true)
                    : null,
                onTapUp: enabled
                    ? (_) => setState(() => _pressed = false)
                    : null,
                onTapCancel: enabled
                    ? () => setState(() => _pressed = false)
                    : null,
                onTap: enabled ? widget.onPressed : null,
                child: AnimatedContainer(
                  duration: NestMotion.resolve(context, NestMotion.fast),
                  transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
                  padding:
                      widget.contentPadding ??
                      const EdgeInsets.symmetric(horizontal: NestSpacing.s6),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                    border: Border.all(
                      color: tokens.ink,
                      width: kid.borderWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tokens.kidShadow.first.color,
                        offset: Offset(0, _pressed ? 2 : 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Flex(
                      direction: widget.axis,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (prefix != null) ...[
                          prefix,
                          SizedBox(
                            width: widget.axis == Axis.horizontal
                                ? widget.gap
                                : 0,
                            height: widget.axis == Axis.vertical
                                ? widget.gap
                                : 0,
                          ),
                        ],
                        Flexible(
                          // One announcement per button: the outer
                          // `Semantics(label:)` owns the label, so the inner
                          // text must not merge a second copy.
                          child: ExcludeSemantics(
                            child: _KidLabel(
                              button: widget,
                              foreground: foreground,
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

/// Kid-button label: wraps by default; with [NestKidButton.wrapLabel]
/// false it stays on one line and scales down (K03 dock at narrow
/// widths / large text scales).
class _KidLabel extends StatelessWidget {
  const new({required this.button, required this.foreground});

  final NestKidButton button;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      button.label,
      style: NestType.buttonKid(color: foreground).copyWith(
        fontSize: button.fontSize,
        height: (button.fontSize == 20 ? 26 : NestSpacing.s5) / button.fontSize,
      ),
      textAlign: TextAlign.center,
      softWrap: button.wrapLabel,
      maxLines: button.wrapLabel ? null : 1,
    );
    if (button.wrapLabel) {
      return label;
    }
    return FittedBox(fit: BoxFit.scaleDown, child: label);
  }
}
