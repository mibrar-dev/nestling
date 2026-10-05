import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

// The `SettingsRow` fork is deleted (shared/family_session): `NestListRow`
// now covers its two slots via `leading:` (32 px avatar) and
// `titleColor:`/`titleWeight:` (danger row) per SHARED_REQUEST.md §6, with
// the shared one-node semantics shape. Call sites use `NestListRow`
// everywhere. The helpers below remain (chevrons, hint style, avatar map).

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
