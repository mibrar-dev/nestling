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
      child: IntrinsicHeight(
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
              ),
            ),
            Expanded(
              child: _StatCell(
                cellKey: const Key('k07-card-coins'),
                value: coinsGrown,
                label: evolutionStatCoinsLabel(),
                valueKey: const Key('k07-stat-coins'),
              ),
            ),
            Expanded(
              child: _StatCell(
                cellKey: const Key('k07-card-stage'),
                value: stage,
                label: evolutionStatStagesLabel(),
                valueKey: const Key('k07-stat-stage'),
              ),
            ),
          ],
        ),
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
  });

  /// Keys the painted CARD (its background/border rect), not just the number:
  /// a pill that collapses to text width must fail here.
  final Key cellKey;
  final int value;
  final String label;
  final Key valueKey;

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
      // At 320 px a cell is ~86 px wide and at text scale 1.3 the label wants
      // two lines: `scaleDown` shrinks the pair instead of overflowing, so a
      // number never drops its label (K07 §(a).6).
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '$value',
              key: valueKey,
              textAlign: TextAlign.center,
              maxLines: 1,
              // Nunito 900 30/34 — no shared token is 30 px, so the size/line
              // pair is set here at the call site (`K07-evolution.html:29`).
              style: NestType.kidTitle(color: tokens.ink).copyWith(
                fontSize: EvolutionStatsGeometry.numberSize,
                height:
                    EvolutionStatsGeometry.numberLineHeight /
                    EvolutionStatsGeometry.numberSize,
              ),
            ),
            const SizedBox(height: EvolutionStatsGeometry.labelTopMargin),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}
