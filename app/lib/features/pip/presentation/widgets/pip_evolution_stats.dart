// K07's `.k7-stats` — the three celebration cards.
//
//   .k7-stats { display: flex; gap: 10px }
//   .k7-stats > div { flex: 1; min-width: 0; background: var(--surface);
//                     border: 3px solid var(--ink); border-radius: var(--r-m);
//                     box-shadow: var(--sh-kid); padding: 12px 6px;
//                     text-align: center }
//   .k7-stats b    { display: block; font-weight: 900; font-size: 30px;
//                     line-height: 34px }            (HTML lines 29)
//   .k7-stats span { display: block; font-weight: 700; font-size: 14px;
//                     line-height: 18px; color: var(--ink-2);
//                     margin-top: 2px }              (HTML line 30)
//
// Measured on the light design PNG: card 1 x 20..130, card 2 x 140..250, card
// 3 x 260..370 (350 wide row, 10 px gaps) and the cards span y 545..629 —
// 3 + 12 + 34 + 2 + 18 + 12 + 3 = 84, the height the CSS above lays out.
//
// The numbers are DB-driven (lifetime quests done, lifetime coins grown, the
// child's stage): never literals.
import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_copy.dart';

/// `.k7-stats` metrics, in the design's CSS px.
abstract final class EvolutionStatsGeometry {
  const new _();

  /// `.k7-stats { gap: 10px }`.
  static const double gap = NestSpacing.gap10;

  /// `padding: 12px 6px`.
  static const EdgeInsets cellPadding = EdgeInsets.symmetric(
    vertical: NestSpacing.s3,
    horizontal: NestSpacing.gap6,
  );

  /// `.k7-stats b { font-size: 30px; line-height: 34px }`.
  static const double numberSize = 30;
  static const double numberLineHeight = 34;

  /// `.k7-stats span { font-size: 14px; line-height: 18px; margin-top: 2px }`.
  static const double labelSize = 14;
  static const double labelLineHeight = 18;
  static const double labelTopMargin = NestSpacing.gap2;
}

/// The three cards, announced as one sentence.
class PipEvolutionStats extends StatelessWidget {
  const new({
    required this.questsDone,
    required this.coinsGrown,
    required this.stage,
    super.key,
  });

  /// The DISTINCT lifetime quests done — the milestone this card is about, so
  /// a daily or weekly quest counts once however many times it was completed
  /// (`6_bugs.md` K07-BUG-3; `PipEvolution.questsFinishedCount`). The row count
  /// behind it backs the sub-line's "helped N times" instead.
  final int questsDone;

  /// Lifetime coins Pip grew.
  final int coinsGrown;

  /// The child's stage, 1..4.
  final int stage;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('k07-stats'),
      excludeSemantics: true,
      label: evolutionStatsLabel(
        questsDone: questsDone,
        coinsGrown: coinsGrown,
        stage: stage,
      ),
      // `.k7-stats` is a CSS flex row with NO `align-items`, i.e. the default
      // `stretch`: all three `.k7-stats > div` boxes are the height of the
      // tallest, so their top and bottom edges line up (`5_ui.md` measures all
      // three at y 545..629 on the light PNG). `CrossAxisAlignment.stretch`
      // is the same instruction; `IntrinsicHeight` is required alongside it
      // because the row lives inside a `SingleChildScrollView`, whose cross
      // axis is unbounded (a bare `stretch` throws "forces an infinite
      // height"). Deliberately NOT a fixed card height: the cards must still
      // GROW at large text scales and on a 320 px phone, where the labels
      // wrap (6_bugs.md K07-BUG-6).
      child: LayoutBuilder(
        builder: (context, constraints) {
          // K07-BUG-10: one shared scale for all three numbers. A per-cell
          // `FittedBox(scaleDown)` scaled each card by its own content width
          // (K07-BUG-8: three different type sizes, drifting tops), and the
          // unscaled `softWrap: false` clipped mid-digit when a number
          // exceeded its card (9999 at 320 px / 1.3). Measure the widest
          // number once and shrink ALL three by the same factor, so they stay
          // equal size with no clipping. At every reachable width the factor
          // is 1.0 — geometry at 390 / 1.0 is unchanged.
          final tokens = context.nest;
          final scaler = MediaQuery.textScalerOf(context);
          final numberStyle = NestType.kidTitle(color: tokens.ink).copyWith(
            fontSize: EvolutionStatsGeometry.numberSize,
            height:
                EvolutionStatsGeometry.numberLineHeight /
                EvolutionStatsGeometry.numberSize,
          );
          double widest = 0;
          for (final value in <int>[questsDone, coinsGrown, stage]) {
            final painter = TextPainter(
              text: TextSpan(text: '$value', style: numberStyle),
              textDirection: Directionality.of(context),
              textScaler: scaler,
              maxLines: 1,
            )..layout();
            if (painter.width > widest) widest = painter.width;
          }
          // Card content width: a third of the row minus the two 10 px gaps,
          // minus the 3 px ink border on each side and the cell's 6 px
          // horizontal padding on each side.
          final rowWidth = constraints.maxWidth;
          final border = context.nestKid.borderWidth;
          final cardWidth = (rowWidth - 2 * EvolutionStatsGeometry.gap) / 3;
          final contentWidth =
              cardWidth -
              2 * border -
              EvolutionStatsGeometry.cellPadding.horizontal;
          final scale = widest <= 0
              ? 1.0
              : (contentWidth / widest).clamp(0.0, 1.0);
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: EvolutionStatsGeometry.gap,
              children: <Widget>[
                Expanded(
                  child: _StatCell(
                    cellKey: const Key('k07-card-quests'),
                    value: questsDone,
                    label: evolutionStatQuestsLabel(),
                    valueKey: const Key('k07-stat-quests'),
                    scale: scale,
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    cellKey: const Key('k07-card-coins'),
                    value: coinsGrown,
                    label: evolutionStatCoinsLabel(),
                    valueKey: const Key('k07-stat-coins'),
                    scale: scale,
                  ),
                ),
                Expanded(
                  child: _StatCell(
                    cellKey: const Key('k07-card-stage'),
                    value: stage,
                    label: evolutionStatStagesLabel(),
                    valueKey: const Key('k07-stat-stage'),
                    scale: scale,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// One `.k7-stats > div`.
class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.cellKey,
    required this.value,
    required this.label,
    required this.valueKey,
    this.scale = 1.0,
  });

  /// Keys the painted CARD (its background/border rect), not just the number:
  /// a pill that collapses to text width must fail here.
  final Key cellKey;
  final int value;
  final String label;
  final Key valueKey;

  /// K07-BUG-10: the ONE shared scale for all three numbers (1.0 when every
  /// number fits). Applied as a uniform `fontSize`, so the three numbers
  /// stay equal size with no clipping and one top edge.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Container(
      key: cellKey,
      padding: EvolutionStatsGeometry.cellPadding,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: NestRadii.allM,
        border: Border.all(
          color: tokens.ink,
          width: context.nestKid.borderWidth,
        ),
        // `--sh-kid` (the chunky 6 px kid edge), same as `NestKidButton`'s.
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: tokens.kidShadow.first.color,
            offset: const Offset(0, NestSpacing.gap6),
          ),
        ],
      ),
      // CSS never scales an item's type because its neighbours are narrower:
      // `.k7-stats > div { flex: 1; min-width: 0 }` fixes the card at a third
      // of the row (110 px at 390) and `.k7-stats b`/`span` set ONE `font-size`
      // for all three cards — a browser that runs out of room WRAPS, it never
      // shrinks one card's text. A per-cell `FittedBox(fit: scaleDown)` did
      // exactly that: each cell shrank by its own content's width, so the three
      // numbers painted at three different sizes (39.37 / 39.51 / 43.40 at the
      // design width and text scale 1.3, and 29.52 / 29.63 / 32.54 at 320 px
      // with no accessibility setting at all) and their tops drifted 2.4–3.16
      // px — an owner ALIGNMENT failure (6_bugs.md K07-BUG-8). The cells now
      // both stretch to one height (above) and share one 30 px number, with the
      // label wrapping at 2 lines inside the fixed card if it must.
      //
      // `maxLines: 1` + `softWrap: false` on the NUMBER because `.k7-stats b {
      // display: block }` is a single line in CSS. The LABEL has no cap at all:
      // a browser wraps `.k7-stats span` freely inside the card, so `maxLines`
      // is gone and the card is the thing that grows.
      child: Column(
        // CSS block flow: `.k7-stats b`/`span` start at the top of the
        // padding box (the `Column` default), so the three numbers share one
        // top edge no matter how many lines any one label wraps to. `center`
        // would re-splay them at an intermediate width where only some labels
        // wrap.
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$value',
            key: valueKey,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            // Nunito 900 30/34 — no shared token is 30 px, so the size/line
            // pair is set here at the call site (`K07-evolution.html:29`).
            // K07-BUG-10: `scale` is the row's ONE shared factor (1.0 when
            // everything fits, so 390 / 1.0 is pixel-identical).
            style: NestType.kidTitle(color: tokens.ink).copyWith(
              fontSize: EvolutionStatsGeometry.numberSize * scale,
              height:
                  EvolutionStatsGeometry.numberLineHeight /
                  EvolutionStatsGeometry.numberSize,
            ),
          ),
          const SizedBox(height: EvolutionStatsGeometry.labelTopMargin),
          Text(
            label,
            textAlign: TextAlign.center,
            // No `maxLines`: the design clamps nothing and the row's
            // `IntrinsicHeight` grows the cards to fit the tallest wrapped
            // label (ORCHESTRATOR_NOTES 03:03).
            // Nunito 700 14/18 on ink-2 (`K07-evolution.html:30`).
            style: NestType.kidCaption(color: tokens.ink2).copyWith(
              fontSize: EvolutionStatsGeometry.labelSize,
              height:
                  EvolutionStatsGeometry.labelLineHeight /
                  EvolutionStatsGeometry.labelSize,
            ),
          ),
        ],
      ),
    );
  }
}
