import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// Settings list row with a custom leading widget (avatar) or danger title.
///
/// `NestListRow` only ships a 40 px icon tile as its leading slot, so P16's
/// Family/Children avatars and its no-leading danger row use this mirror of
/// the shared row's exact metrics (same padding, min-height 56, title/body
/// styles, token values — never hard-coded).
class SettingsRow extends StatelessWidget {
  const new({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.titleColor,
    this.titleWeight,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.padding,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Color? titleColor;
  final FontWeight? titleWeight;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;

  /// Row content padding; defaults to `NestListRow`'s (12/10/16/10).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final lead = leading;
    final tail = trailing;
    final caption = subtitle;
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding ?? const EdgeInsets.fromLTRB(12, 10, 16, 10),
          child: Row(
            spacing: NestSpacing.s3,
            children: [
              ?lead,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style:
                          NestType.bodyStrong(color: titleColor ?? tokens.ink)
                              .copyWith(
                                fontWeight: titleWeight ?? FontWeight.w600,
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
              // `.list-trail` cap, mirroring shared main's fix (the
              // trail never joins the flex distribution).
              if (tail != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: tail,
                ),
            ],
          ),
        ),
      ),
    );
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: content,
    );
    final tap = onTap;
    if (tap != null) {
      return Semantics(
        button: true,
        enabled: true,
        label: semanticLabel ?? title,
        onTap: tap,
        child: row,
      );
    }
    return row;
  }
}

/// Chevron used as the trailing slot on link rows (`.list-trail`).
Widget settingsChevron(BuildContext context) =>
    Text('›', style: NestType.h3(color: context.nest.ink3));

/// Maps the stored avatar colour token to the avatar tint (mirrors the other
/// parent features' local mapping — the token enum is shared, the mapping is
/// per-feature display glue).
NestAvatarColor settingsAvatarColor(String raw) {
  return switch (raw) {
    'lilac' => NestAvatarColor.lilac,
    'peach' => NestAvatarColor.peach,
    'sky' => NestAvatarColor.sky,
    'leaf' => NestAvatarColor.leaf,
    'coin' => NestAvatarColor.coin,
    _ => NestAvatarColor.neutral,
  };
}
