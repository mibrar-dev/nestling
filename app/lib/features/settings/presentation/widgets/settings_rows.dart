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
    // 4_review finding 6: a static row gets its own container node so its
    // text does not fold into the next tappable row's announcement. Plain
    // container only — no label, no excludeSemantics, no onTap — so the
    // owner's ACCESSIBILITY-ACTIONS rule is untouched.
    return Semantics(container: true, child: row);
  }
}

/// Chevron used as the trailing slot on list rows (`.list-trail`).
///
/// `.list-trail` (`components.css:119`) sets only
/// `color: var(--ink-3); font-weight: 600`, inheriting Inter from `body`
/// (16 px), so the trail is Inter 16 w600 — not the Nunito 18 w800
/// `NestType.h3` this used to be (4_review finding 3). P09 already uses the
/// closer `NestType.bodySmallStrong` for its `›`.
Widget settingsChevron(BuildContext context) => Text(
  '›',
  style: NestType.body(color: context.nest.ink3)
      .copyWith(fontWeight: FontWeight.w600),
);

/// Chevron inside the subscription `.linkrow` (`P16-settings.html:9`,
/// `font-weight: 600; font-size: 15px`): Inter 15 w600.
Widget settingsChevronSmall(BuildContext context) =>
    Text('›', style: NestType.bodySmallStrong(color: context.nest.ink3));

/// `.lockhint { font-size:14px; line-height:20px }` regular copy
/// (`P16-settings.html:10`) — used by the lock-hint row and the move banner.
///
/// Review finding 4: both sites used to reach this by taking the shared
/// `NestType.chipLabel` (Inter 14/20 **w600**) and cancelling the weight, so a
/// future chip-label change (weight, tracking) would silently move hint text.
/// The literal now lives in exactly one documented function instead of two
/// call sites; **SHARED_REQUEST.md §9** asks the orchestrator for a proper
/// `NestType.hint` (14/20 w400) so even this one goes away. Metrics are
/// unchanged: `chipLabel` and this style have the same 14/20 line box.
TextStyle settingsHintStyle(BuildContext context) =>
    NestType.body(color: context.nest.ink)
        .copyWith(fontSize: 14, height: 20 / 14);

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
