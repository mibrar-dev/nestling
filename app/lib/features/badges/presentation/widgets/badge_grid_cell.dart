import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/badges/domain/entities/badge.dart' as domain;

/// `.k11-medal`: 60×60 badge art (`K11-badges.html:26-30`).
const double _medalSize = 60;

/// `.k11-n`: Nunito 15/19 w800, `min-height: 38px` (two lines), centred —
/// the box that keeps one-line and two-line names on the same rhythm
/// (`K11-badges.html:27`).
const double _nameFontSize = 15;
const double _nameLineHeight = 19;
const double _nameMinHeight = 38;

/// `.k11-s`: Nunito 14/18 w800 (`K11-badges.html:28`).
const double _subFontSize = 14;
const double _subLineHeight = 18;

/// `.k11-b { padding: 10px 4px }` (`K11-badges.html:23`).
const EdgeInsets _cellPadding = EdgeInsets.fromLTRB(
  NestSpacing.s1,
  NestSpacing.gap10,
  NestSpacing.s1,
  NestSpacing.gap10,
);

/// `.k11-b { gap: 4px }` (`K11-badges.html:23`).
const double _cellGap = NestSpacing.s1;

/// The design's badge art, keyed by the badge's stable id. The earned flag
/// never switches the art (the asset itself carries the todo styling), so a
/// legacy id that has no drawing falls back to the neutral ribbon glyph
/// rather than another badge's medal.
const Map<String, String> _artFor = <String, String>{
  'first-quest': NestlingIllustrations.badgeFirstQuest,
  'bed-maker-7': NestlingIllustrations.badgeBedMaker,
  'kind-helper': NestlingIllustrations.badgeKindHelper,
  'bookworm': NestlingIllustrations.badgeBookworm,
  'bins-out': NestlingIllustrations.badgeBinsOut,
  'biscuit-sitter': NestlingIllustrations.badgeBiscuitSitter,
  'tidy-hero': NestlingIllustrations.badgeTidyHero,
  'early-bird': NestlingIllustrations.badgeEarlyBird,
  'plant-waterer': NestlingIllustrations.badgePlantWaterer,
};

/// One K11 badge tile — `.k11-b` (`design/html-source/screens/K11-badges.html:23`):
/// `surface` fill, a 3 px ink border (solid + `--sh-kid` when earned, dashed
/// `ink-2` with no shadow when still to do), `--r-l` 24 radius, `padding:
/// 10px 4px`, column with 4 px gaps, everything centred.
///
/// Geometry at 390 (verified against `design/screens/light/K11-badges.png`
/// ÷3): column 108.67, cell box 193…343 (150 tall), medal 203…263, name box
/// 267…305, sub 309…327.
///
/// A badge tile is a static card: no detail route exists in the nav map, so
/// there is no tap, toast or sheet. The tile exposes ONE merged label —
/// `"<name>, Got it!"` / `"<name>, Keep going!"` — with the art and the two
/// texts excluded, so VoiceOver reads the tile once and not as three runs.
class BadgeGridCell extends StatelessWidget {
  const BadgeGridCell({required this.badge, super.key});

  /// The shelf row (repository-owned entity): `earned` drives the border and
  /// the sub colour, `detail` is the design's own copy (`Got it!` /
  /// `Keep going!`) — the view never remaps it.
  final domain.Badge badge;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final kid = context.nestKid;
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      spacing: _cellGap,
      children: [
        SizedBox.square(
          dimension: _medalSize,
          child: ExcludeSemantics(child: _art(context)),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _nameMinHeight),
          child: Center(
            child: Text(
              badge.title,
              style: NestType.kidCaption(color: tokens.ink).copyWith(
                fontSize: _nameFontSize,
                height: _nameLineHeight / _nameFontSize,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Text(
          badge.detail,
          style:
              NestType.kidCaption(
                color: badge.earned ? tokens.leafInk : tokens.ink2,
              ).copyWith(
                fontSize: _subFontSize,
                height: _subLineHeight / _subFontSize,
                fontWeight: FontWeight.w800,
              ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
    return Semantics(
      container: true,
      // One static label per tile. `excludeSemantics` drops the child text
      // and SVG runs so nothing is announced twice; the tile is not a
      // control, so it carries no tap action (`1_plan.md` §c).
      excludeSemantics: true,
      label: '${badge.title}, ${badge.detail}',
      child: badge.earned
          ? Container(
              padding: _cellPadding,
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: NestRadii.allL,
                border: Border.all(color: tokens.ink, width: kid.borderWidth),
                boxShadow: tokens.kidShadow,
              ),
              child: column,
            )
          : NestDashedBorder(
              color: tokens.ink2,
              child: Container(
                // CSS paints the dashed border INSIDE the element's border
                // box, so a still-to-do tile is the same 150 px tall as an
                // earned one. Flutter's dashed stroke is a painter with no
                // layout thickness, so the stroke's room is added to the
                // padding here — without it a dashed tile laid out 6 px short
                // (144) and pulled the whole week card 6 px up (677 instead of
                // 683).
                padding: EdgeInsets.symmetric(
                  horizontal: NestSpacing.s1 + kid.borderWidth,
                  vertical: NestSpacing.gap10 + kid.borderWidth,
                ),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: NestRadii.allL,
                ),
                child: column,
              ),
            ),
    );
  }

  /// The medal drawing: the design art for a known id, else the neutral
  /// ribbon glyph (never a wrong badge's art).
  Widget _art(BuildContext context) {
    final art = _artFor[badge.id];
    if (art == null) {
      return NestIcon(
        NestIcons.ribbon,
        size: _medalSize,
        color: context.nest.ink3,
      );
    }
    return SvgPicture.asset(art, width: _medalSize, height: _medalSize);
  }
}
