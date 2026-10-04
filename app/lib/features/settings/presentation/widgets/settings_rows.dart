import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// Settings list row for the two slots the shared `NestListRow` cannot
/// render yet (SHARED_REQUEST.md §6):
///
///  * a custom `leading` widget — P16's Family/Children rows use a 32 px
///    `NestAvatar` where the design's `.list-row` carries `<span class="avatar
///    s32">` (`P16-settings.html:18-27`), while `NestListRow` only builds a
///    40 px icon tile from `leadingAsset`;
///  * a danger title — `.dangerlink { color:var(--danger); font-weight:700 }`
///    (`P16-settings.html:40`).
///
/// Everything else is the shared row's exact metrics (padding 12/10/16/10,
/// min-height 56, title `bodyStrong` w600 height 22/16, `caption` subtitle,
/// 12 px gaps, token values — never hard-coded). When §6 lands this widget
/// disappears and the call sites pass `leading:`/`titleColor:` instead.
///
/// The toggle rows, the link rows and the zone-picker rows already use the
/// shared `NestListRow` (shared batch 6): the 51×44 wrappers that grew those
/// rows 56 → 64 and clipped `NestToggle`'s horizontal hit slop are gone.
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
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Color? titleColor;
  final FontWeight? titleWeight;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;

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
          padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
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
              // `.list-trail { flex-shrink: 0 }` cap, mirroring the shared
              // row: the trail never joins the flex distribution.
              if (tail != null)
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: NestListRow.trailMaxWidth,
                  ),
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
