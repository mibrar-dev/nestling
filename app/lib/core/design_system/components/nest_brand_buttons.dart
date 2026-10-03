import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

/// Sign in with Apple button.
///
/// The [leading] slot takes the caller-provided platform glyph. Production
/// builds should prefer the official Apple SDK button where required by
/// platform guidelines.
class NestAppleButton extends StatelessWidget {
  const new({
    required this.label,
    super.key,
    this.onPressed,
    this.leading,
    this.loading = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool loading;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return _BrandButton(
      key: key,
      label: label,
      onPressed: onPressed,
      background: tokens.appleBg,
      foreground: tokens.appleInk,
      leading: leading,
      loading: loading,
      semanticLabel: semanticLabel,
    );
  }
}

/// Sign in with Google button.
///
/// The [leading] slot takes the caller-provided platform glyph. Production
/// builds should prefer the official Google SDK button where required by
/// platform guidelines.
class NestGoogleButton extends StatelessWidget {
  const new({
    required this.label,
    super.key,
    this.onPressed,
    this.leading,
    this.loading = false,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool loading;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return _BrandButton(
      key: key,
      label: label,
      onPressed: onPressed,
      background: tokens.googleBg,
      foreground: tokens.googleInk,
      border: Border.all(color: tokens.googleLine),
      shadows: tokens.cardShadow,
      leading: leading,
      loading: loading,
      semanticLabel: semanticLabel,
    );
  }
}

class _BrandButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
    required this.loading,
    required this.semanticLabel,
    super.key,
    this.border,
    this.shadows,
    this.leading,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final BoxBorder? border;
  final List<BoxShadow>? shadows;
  final Widget? leading;
  final bool loading;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final disabled = onPressed == null || loading;

    final Widget? prefix;
    final leadingWidget = leading;
    if (loading) {
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

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      enabled: !disabled,
      onTap: disabled ? null : onPressed,
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: SizedBox(
          width: double.infinity,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: NestDevice.tapParent,
              minHeight: 52,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: NestRadii.allPill,
              child: InkWell(
                onTap: disabled ? null : onPressed,
                borderRadius: NestRadii.allPill,
                focusColor: tokens.leaf.withValues(alpha: 0.12),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NestSpacing.s6,
                  ),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: NestRadii.allPill,
                    border: border,
                    boxShadow: shadows,
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
                          // One announcement per button (P03 §2): the outer
                          // `Semantics(label:)` owns the label, so the inner
                          // text must not merge a second copy.
                          child: ExcludeSemantics(
                            child: Text(
                              label,
                              style: NestType.buttonLabel(color: foreground),
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
