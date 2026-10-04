// P15 · `.list-row` — the design's list row, composed on this screen.
//
// Why this file exists (do NOT read it as a re-implementation of the design
// system — it is a CSS transcription, and it is meant to be deleted):
//
// `NestListRow` (`core/design_system/components/nest_list_row.dart`, which
// RULES §1 forbids this screen from editing) lays the row out as
//
//     [tile 40, gap 12, Expanded(main), gap 12, Flexible(trail)]
//
// Flutter hands BOTH flex children an equal share of the free space, so the
// trailing reserves half the row however narrow its text is and `.list-main`
// gets only the rest of half. At 390 that gave the title/sub column 129 px
// where the design gives ≈187 px, and all three P15 subtitles were
// ellipsised (BUG P15-BUG-5, ORCHESTRATOR_NOTES item 1, `SHARED_REQUEST.md`
// §1). The design's CSS is the opposite
// (`design/html-source/components.css:116-119`):
//
//     .list-main  { flex: 1; min-width: 0 }
//     .list-trail { flex-shrink: 0 }
//
// This widget reproduces that: the trail takes its intrinsic width, the main
// column takes the remainder. Everything else is shared, unchanged —
// `NestList` (the card + its 72 px-indent dividers), `NestTileTint`,
// `NestIcon`, `NestType`, `NestSpacing`, `Material`/`InkWell` and the
// `Semantics(button:, onTap:)` contract `NestListRow` publishes. No colour or
// spacing literal of its own.
//
// The second reason it exists: the design's Pocket-money tile holds the
// COLOURED `assets/illustrations/coin.svg`, which `NestIcon` would tint with
// `BlendMode.srcIn` (`SHARED_REQUEST.md` §2). [leading] is a builder, so the
// caller decides the glyph and the row still owns the tile's tint colours.
//
// When the shared one-line fix and the `leadingWidget` escape hatch land on
// `main`, delete this file and go back to `NestListRow`.

import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// `.list-row` — one tappable row: 40 px icon tile, an `Expanded` title/sub
/// column and a shrink-wrapped trailing control.
///
/// [leading] receives the tile's foreground colour (from [tint]) and returns
/// the 24 px glyph; leave it null for a text-only row.
class ProfileRow extends StatelessWidget {
  const ProfileRow({
    required this.title,
    required this.onTap,
    super.key,
    this.subtitle,
    this.leading,
    this.tint = NestTileTint.neutral,
    this.trailing,
    this.semanticLabel,
  });

  /// `.list-title` — Inter 600 16/22 ink.
  final String title;

  /// `.list-sub` — Inter 400 13/18 ink-2.
  final String? subtitle;

  /// `.icon-tile` contents (24 px), tinted by [tint].
  final Widget Function(Color tileForeground)? leading;

  final NestTileTint tint;

  /// `.list-trail` — takes its intrinsic width only.
  final Widget? trailing;

  final VoidCallback onTap;

  final String? semanticLabel;

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
    final glyph = leading;
    final caption = subtitle;
    final trail = trailing;

    // `.list-row { min-height: 56px; padding: 10px 16px 10px 12px; gap: 12px }`.
    // 56 has no token; the CSS grid-row meter matches `NestSpacing.tapKid`
    // but that constant is the kid-mode floor, so the CSS value stands with
    // its comment rather than borrowing a parent-inappropriate name.
    final content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            NestSpacing.s3,
            NestSpacing.gap10,
            NestSpacing.s4,
            NestSpacing.gap10,
          ),
          child: Row(
            spacing: NestSpacing.s3,
            children: <Widget>[
              if (glyph != null)
                Container(
                  width: NestSpacing.s10,
                  height: NestSpacing.s10,
                  decoration: BoxDecoration(
                    color: tileBg,
                    // Owner QA: the 40 px tile uses radius 12
                    // (SPACING_SPEC quotes r16; the renders show 12).
                    borderRadius: BorderRadius.circular(NestSpacing.s3),
                  ),
                  alignment: Alignment.center,
                  child: glyph(tileFg),
                ),
              // `.list-main { flex: 1; min-width: 0 }`.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      title,
                      style: NestType.bodyStrong(
                        color: tokens.ink,
                      ).copyWith(fontWeight: FontWeight.w600, height: 22 / 16),
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
              // `.list-trail { flex-shrink: 0 }` — NOT in the flex
              // distribution, so `Change ›` keeps its 70.7 px and the subtitle
              // column takes the remaining ≈187 px (P15-BUG-5).
              ?trail,
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: true,
      label: semanticLabel ?? title,
      onTap: onTap,
      child: ConstrainedBox(
        // `min-height: 56px` in `.list-row` — off the 4 pt scale, so the
        // design value stands with this comment (review-finding-7 noted 56
        // has no token).
        constraints: const BoxConstraints(minHeight: 56),
        child: content,
      ),
    );
  }
}
