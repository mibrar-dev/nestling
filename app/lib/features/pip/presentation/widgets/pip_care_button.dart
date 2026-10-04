// K06's care button — `.k6-care .btn-kid` from
// `design/html-source/screens/K06-pip.html`, with the design's THIRD row
// (the coin price / "Free" pill).
//
// Why not the shared `NestKidButton`: its layout is icon + label only, and
// K06 stacks icon (24) / label (17/20) / trailing (`.k6-coin` 16 or
// `.k6-free` pill) in a column. Everything else is the shared kid button
// recipe, reproduced here exactly: 3 px `ink` border, `--r-l` (24) radius,
// `--sh-kid` (0 6 px) shadow, `translateY(4px)` press, disabled `opacity
// .45` with no tap action, and the same Semantics contract
// (button + label + enabled + onTap).
// See docs/screens/K06/SHARED_REQUEST.md for the shared `trailing` slot.
import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/motion.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// Painted height of a care button, measured off the design PNG (the button
/// border box runs y 502 – 593 there).
///
/// `.k6-care .btn-kid` sets `min-height: 88px; padding: 8px 4px; gap: 3px;
/// font-size: 17px; line-height: 20px`, and the tallest of the three
/// columns is the Play one: 24 px icon + 3 + 20 label + 3 + the 19 px
/// `.k6-free` pill (3 + 13 + 3) = 69, plus 16 px padding and 6 px border =
/// 91, which beats the 88 px floor. Pinning 91 keeps the section heading,
/// wardrobe strip and caption on the design's measured y instead of letting
/// the pill's own metrics decide.
const double kPipCareButtonHeight = 91;

/// Icon size inside a care button (`<svg width="24" height="24">`).
const double kPipCareIconSize = 24;

/// `.k6-care .btn-kid` label: 17 px on a 20 px line box.
const double kPipCareLabelSize = 17;

class PipCareButton extends StatefulWidget {
  const PipCareButton({
    required this.label,
    required this.color,
    required this.foreground,
    required this.trailing,
    required this.semanticLabel,
    super.key,
    this.icon,
    this.onPressed,
  });

  /// Button label ("Feed", "Play", "Bath").
  final String label;

  /// `.btn-kid.peach | .sky | .white` background.
  final Color color;

  /// Label + icon colour (`--on-warm` / `--on-accent` / `ink`).
  final Color foreground;

  /// Third row: the coin price row or the "Free" pill.
  final Widget trailing;

  /// What VoiceOver/TalkBack announces (the design only labels the buttons
  /// visually, e.g. "Feed Pip, costs 5 coins").
  final String semanticLabel;

  /// 24 px line icon (`feedBowl`, `ball`, `bubbles`).
  final Widget? icon;

  /// Null disables the control: `opacity .45`, no tap action.
  final VoidCallback? onPressed;

  @override
  State<PipCareButton> createState() => _PipCareButtonState();
}

class _PipCareButtonState extends State<PipCareButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final kid = context.nestKid;
    final enabled = widget.onPressed != null;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      enabled: enabled,
      // The wrapper owns the label, so the inner rows stay excluded: one
      // announcement per control, and the tap action lives on THIS node.
      excludeSemantics: true,
      onTap: enabled ? widget.onPressed : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: NestMotion.resolve(context, NestMotion.fast),
            transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
            padding: const EdgeInsets.symmetric(
              vertical: NestSpacing.s2,
              horizontal: NestSpacing.s1,
            ),
            constraints: const BoxConstraints(
              minHeight: kPipCareButtonHeight,
              minWidth: kPipCareButtonHeight,
            ),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: NestRadii.allL,
              border: Border.all(color: tokens.ink, width: kid.borderWidth),
              boxShadow: [
                BoxShadow(
                  color: tokens.kidShadow.first.color,
                  offset: Offset(0, _pressed ? 2 : 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              spacing: NestSpacing.gap3,
              children: [
                if (widget.icon != null) widget.icon!,
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.label,
                      style: NestType.buttonKid(color: widget.foreground)
                          .copyWith(
                            fontSize: kPipCareLabelSize,
                            height: NestSpacing.s5 / kPipCareLabelSize,
                          ),
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                ),
                widget.trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
