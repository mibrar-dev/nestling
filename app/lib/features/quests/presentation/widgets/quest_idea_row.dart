import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';

/// P10 list row — `.trow`.
///
/// `.trow` is `flex; align-items:center; gap:12px; padding:12px;
/// border-radius:r-m; box-shadow:sh-1; min-width:0` on `--surface`, so it
/// is NOT [NestCard] (r-l 24). The 68 px row height in the design comes from
/// the 44 px `.addbtn` plus the 12 px padding, with the 40 px icon tile and
/// the 40 px text block centred inside it.
class QuestIdeaRow extends StatelessWidget {
  const QuestIdeaRow({
    required this.title,
    required this.meta,
    required this.iconAsset,
    required this.tint,
    super.key,
    this.onAdd,
    this.onTap,
    this.addSemanticLabel,
  });

  final String title;

  /// Second line (`.trow .mt`, 13/18 ink-2).
  final String meta;
  final String iconAsset;
  final NestTileTint tint;

  /// `.addbtn` — `+ Add` for Ideas rows; null on Active rows.
  final VoidCallback? onAdd;

  /// Whole-row tap (Active rows open the editor).
  final VoidCallback? onTap;

  /// `aria-label="Add {title}"`.
  final String? addSemanticLabel;

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

    final add = onAdd;
    final rowTap = onTap;

    // Ideas rows carry a `.addbtn`; Active rows are tappable as a whole.
    final body = Padding(
      padding: const EdgeInsets.all(NestSpacing.s3),
      child: Row(
        children: <Widget>[
          Container(
            width: NestSpacing.s10,
            height: NestSpacing.s10,
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: NestRadii.allM,
            ),
            alignment: Alignment.center,
            // 24 px is the NestIcon default; `.icon-tile` never overrides it.
            child: NestIcon(iconAsset, color: tileFg),
          ),
          const SizedBox(width: NestSpacing.s3),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              // `.trow .main { flex:1; min-width:0 }` with block-level
              // `.nm`/`.mt`: both lines start at the tile gap (card left +
              // 12 padding + 40 tile + 12 gap = +64), never centred.
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  // `.trow .nm`: Inter 16 w700, line-height 22 (not the type
                  // scale's 24), single line with an ellipsis.
                  style: NestType.bodyStrong(color: tokens.ink)
                      .copyWith(height: 22 / 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  meta,
                  // `.trow .mt`: Inter 13/18 ink-2.
                  style: NestType.caption(color: tokens.ink2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (add != null) ...<Widget>[
            const SizedBox(width: NestSpacing.s3),
            QuestAddButton(semanticLabel: addSemanticLabel, onTap: add),
          ],
        ],
      ),
    );

    final tap = (add == null) ? rowTap : null;
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: NestRadii.allM,
        boxShadow: tokens.cardShadow,
      ),
      child: tap == null
          ? body
          : Material(
              color: Colors.transparent,
              borderRadius: NestRadii.allM,
              child: InkWell(
                borderRadius: NestRadii.allM,
                onTap: tap,
                child: body,
              ),
            ),
    );

    if (tap == null) return card;
    // The `Semantics` wrapper MUST carry its own `onTap`: `excludeSemantics`
    // drops the whole subtree, so without it the node announces `isButton`
    // with no `SemanticsAction.tap` and VoiceOver/TalkBack cannot activate
    // the row (the InkWell's action is inside the excluded subtree).
    // The label keeps the meta line, so a screen-reader user hears the same
    // two lines a parent reads on screen.
    return Semantics(
      button: true,
      label: '$title. $meta',
      excludeSemantics: true,
      container: true,
      onTap: tap,
      child: card,
    );
  }
}

/// `.addbtn`: 44×44 min, `0 14px` padding, pill radius, 1.5 px leaf border,
/// leaf-tint fill, leaf-ink Inter 14 w700 label `+ Add`.
class QuestAddButton extends StatelessWidget {
  const QuestAddButton({required this.onTap, super.key, this.semanticLabel});

  static const String label = '+ Add';

  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      // `container: true` is load-bearing: without it the node's annotations
      // (label + tap) bubble up into the row and the control loses its own
      // addressable node — the row then reads as one button whose action is
      // "Add", and the row's own texts join the label (BUG-P10-9).
      container: true,
      // Required: `excludeSemantics` hides the InkWell's tap action, so the
      // node itself has to expose one (ACCESSIBILITY rule + P10 BUG-P10-9).
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        borderRadius: NestRadii.allPill,
        child: InkWell(
          borderRadius: NestRadii.allPill,
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(
              minWidth: NestDevice.tapParent,
              minHeight: NestDevice.tapParent,
            ),
            height: NestDevice.tapParent,
            padding: const EdgeInsets.symmetric(horizontal: NestSpacing.gap14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tokens.leafTint,
              borderRadius: NestRadii.allPill,
              border: Border.all(color: tokens.leaf, width: 1.5),
            ),
            child: Text(
              label,
              style: NestType.chipLabel(color: tokens.leafInk)
                  .copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              softWrap: false,
            ),
          ),
        ),
      ),
    );
  }
}
