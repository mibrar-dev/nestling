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

/// The design's earned badge art, keyed by the badge's stable id. Each id
/// renders its own medal in both states (the asset itself carries the
/// styling), so a legacy id that has no drawing falls back to the neutral
/// ribbon glyph rather than another badge's medal.
const Map<String, String> _earnedArtFor = <String, String>{
  'first-quest': NestlingIllustrations.badgeFirstQuest,
  'bed-maker-7': NestlingIllustrations.badgeBedMaker,
  'kind-helper': NestlingIllustrations.badgeKindHelper,
  'bookworm': NestlingIllustrations.badgeBookworm,
};

/// The inner glyph markup for each of the design's five still-to-do medals,
/// transcribed from `design/html-source/screens/K11-badges.html:80-123`
/// (bin, paw, basket, sun, watering-can). The ribbon + disc + dashed ring
/// are shared (see [lockedMedalSvg]); only the glyph differs per id.
const Map<String, String> _lockedGlyphFor = <String, String>{
  'bins-out': '<path fill="none" stroke="#6E6A8A" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.6" d="M21 28h22m-17 0v-4a2 2 0 0 1 2-2h8a2 2 0 0 1 2 2v4m-15 0v22a3 3 0 0 0 3 3h12a3 3 0 0 0 3-3V28m-12 7v11m6-11v11"/>',
  'biscuit-sitter': '<g fill="none" stroke="#6E6A8A" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.6"><circle cx="32" cy="42" r="6"/><circle cx="24" cy="33" r="3.4"/><circle cx="31" cy="29" r="3.4"/><circle cx="39" cy="33" r="3.4"/></g>',
  'tidy-hero': '<path fill="none" stroke="#6E6A8A" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.6" d="M41 33H23l1.6 8.5a2.4 2.4 0 0 0 2.4 1.9h10a2.4 2.4 0 0 0 2.4-1.9Zm-14 0v-3a5 5 0 0 1 10 0v3"/>',
  'early-bird': '<g fill="none" stroke="#6E6A8A" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.6"><circle cx="32" cy="38" r="7"/><path d="M32 24v5m0 18v5M20 38h-4m32 0h-4m-20.6-8.6-2.8-2.8m22.8 22.8-2.8-2.8m0-17.2 2.8-2.8M20.6 49.4l2.8-2.8"/></g>',
  'plant-waterer': '<g fill="none" stroke="#6E6A8A" stroke-linecap="round" stroke-linejoin="round" stroke-width="2.6"><path d="M25 30h14l3 20a3 3 0 0 1-3 3.4H25a3 3 0 0 1-3-3.4Z"/><path d="M29 30v-6a4 4 0 0 1 8 0v6M25 40h14"/></g>',
};

/// The locked (still-to-do) medal drawing for one of the five design ids.
///
/// Medal interiors are illustration art, not UI chrome: like the shared
/// `NestlingIllustrations.badge*` files they keep fixed colours in both
/// themes (measured on `design/screens/light|dark/K11-badges.png`: disc
/// `#F3EEE5`, ring `#1E1B3A`, ribbon fill `#6E6A8A` + stroke `#1E1B3A` at
/// 40 %, glyph `#6E6A8A` — identical in light and dark).
///
/// Two corrections versus the shared `badge_*` asset files
/// (`ORCHESTRATOR_NOTES.md` 06:55, mandatory):
///
/// 1. The dashed ring is INK (`#1E1B3A`): the HTML's locked `<circle>`
///    carries two `stroke` attributes and HTML parsing keeps the FIRST
///    duplicate, so the design PNG paints the ring in ink, 3 px,
///    `dasharray 5 4` (sampled `(30, 27, 58)` on both design PNGs). The
///    shared files paint it `#6E6A8A` (too light).
/// 2. The ribbon `<path>` carries `opacity=".4"` on the WHOLE element, so
///    its fill AND its 3 px ink stroke draw at 40 % together (sampled
///    `(165, 164, 176)` over white in light, `(31, 28, 51)` over the dark
///    surface in dark — both exactly ink at 40 % over the tile). The
///    opacity sits on a wrapping `<g>`, never on the `<path>` itself:
///    the browser composites the element as one group layer, while a
///    per-paint opacity would composite fill and stroke separately and
///    darken the stroke's inner band (`ORCHESTRATOR_NOTES.md` 07:33).
///    No opacity stays on the path — fill-only or otherwise.
String lockedMedalSvg(String id) {
  final glyph = _lockedGlyphFor[id] ?? '';
  const header =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><g opacity=".4"><path fill="#6E6A8A" stroke="#1E1B3A" stroke-linejoin="round" stroke-width="3" d="M22 5h20l-5 21H27Z"/></g><circle cx="32" cy="39" r="20" fill="#F3EEE5" stroke="#1E1B3A" stroke-dasharray="5 4" stroke-width="3"/>';
  const footer = '</svg>';
  return '$header$glyph$footer';
}

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
  /// ribbon glyph (never a wrong badge's art). The five still-to-do ids
  /// render the local [lockedMedalSvg] (ink dashed ring + whole-element
  /// ribbon opacity, both themes); the four earned ids render their shared
  /// coloured asset. Each id keeps its own medal in both earned and locked
  /// states.
  Widget _art(BuildContext context) {
    if (_lockedGlyphFor.containsKey(badge.id)) {
      return SvgPicture.string(
        lockedMedalSvg(badge.id),
        width: _medalSize,
        height: _medalSize,
      );
    }
    final art = _earnedArtFor[badge.id];
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
