import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_entry.dart';
import 'package:nestling/features/kid_jar/domain/entities/jar_snapshot.dart';

/// Entry types the K09 list carries (`1_plan.md` §b — money IN only), mapped
/// to the design's glyphs: pocket money is the design's geometric coin-slot
/// mark (`NestIcons.jarPocketMoney`, `K09-jar.html:85`); a quest bonus shows
/// the quest's own KID glyph via `questIconFor` (ORCHESTRATOR_NOTES 18:47 —
/// [iconKey] is the repository's note → quest lookup, `''` when unknown and
/// the resolver's own fallback applies); a gift the present (`:95`).
String jarEntryGlyph(String type, String iconKey) => switch (type) {
  'quest_bonus' => questIconFor(iconKey, audience: NestAudience.kid),
  'gift' => NestIcons.gift,
  _ => NestIcons.jarPocketMoney,
};

/// `.k9-list` (`K09-jar.html:83-99`): the "What went in" card — every
/// money-IN row the repository returns, newest first, in the design's frame
/// (surface fill, 3 px ink border, `r-l` 24, `sh-kid`, corners clipped).
class JarHistoryCard extends StatelessWidget {
  const new({required this.items, super.key});

  /// Newest first (`1_plan.md` §b); the card renders all of them — DB wins
  /// over the design's three example rows.
  final List<JarEntry> items;

  /// `.k9-row` minimum height (`K09-jar.html:32`).
  static const double _rowMinHeight = 60;

  /// `.k9-ico` disc (`K09-jar.html:34`).
  static const double _discSize = 40;

  /// `.k9-row + .k9-row::before { left: 66px }` (`K09-jar.html:33`) — 14
  /// padding + 40 disc + 12 gap, measured from the row's own left edge (the
  /// card's border box is 3 px outside that).
  static const double _dividerInset = 66;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final kid = context.nestKid;
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: NestRadii.allL,
        border: Border.all(color: tokens.ink, width: kid.borderWidth),
        boxShadow: tokens.kidShadow,
      ),
      child: items.isEmpty
          ? const _JarEmptyRow()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (var i = 0; i < items.length; i++) ...<Widget>[
                  if (i > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: _dividerInset),
                      child: Container(
                        height: NestSpacing.gap2,
                        color: tokens.line,
                      ),
                    ),
                  _JarEntryRow(entry: items[i], position: i),
                ],
              ],
            ),
    );
  }
}

/// Nothing has gone in yet (`1_plan.md` §d). The design has no empty frame —
/// it is the same row, with the pocket-money glyph and no amount, so the card
/// keeps its height and the child's next line is clear.
class _JarEmptyRow extends StatelessWidget {
  const _JarEmptyRow();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: JarHistoryCard._rowMinHeight,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NestSpacing.gap14,
          vertical: NestSpacing.s2,
        ),
        child: Row(
          children: [
            Container(
              width: JarHistoryCard._discSize,
              height: JarHistoryCard._discSize,
              decoration: BoxDecoration(
                color: tokens.leafTint,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: NestIcon(
                  NestIcons.jarPocketMoney,
                  color: tokens.leafInk,
                ),
              ),
            ),
            const SizedBox(width: NestSpacing.s3),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    JarHistoryCopy.emptyTitle,
                    style: _JarEntryRow.titleStyle(tokens.ink),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    JarHistoryCopy.emptyMessage,
                    style: _JarEntryRow.subStyle(tokens.ink2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Copy the HTML has no source for (`1_plan.md` §d, kid voice).
abstract final class JarHistoryCopy {
  const new _();

  static const String emptyTitle = 'Nothing here yet';
  static const String emptyMessage = 'Finish a quest to fill your jar';
}

/// `.k9-row` (`K09-jar.html:32,84-98`): tint disc + glyph, title, sub and the
/// amount. Display-only — a ledger row is not a control, so it claims no tap
/// action (`1_plan.md` §e).
class _JarEntryRow extends StatelessWidget {
  const _JarEntryRow({required this.entry, required this.position});

  final JarEntry entry;

  /// Row index — the disc tint cycles leaf, lilac, peach as the design shows
  /// (`K09-jar.html:85,90,95`).
  final int position;

  /// `.k9-t` — Nunito 17/22 w800 (`K09-jar.html:36`).
  static TextStyle titleStyle(Color color) =>
      NestType.kidTitle(color: color)
          .copyWith(fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w800);

  /// `.k9-s` — Nunito 14/18 w700 ink-2 (`K09-jar.html:37`).
  static TextStyle subStyle(Color color) =>
      NestType.kidBody(color: color).copyWith(fontSize: 14, height: 18 / 14);

  /// `.k9-v` — Nunito 18/22 w900 leaf-ink, nowrap (`K09-jar.html:38`).
  static TextStyle valueStyle(Color color) =>
      NestType.kidBody(color: color)
          .copyWith(fontSize: 18, height: 22 / 18, fontWeight: FontWeight.w900);

  /// The disc's fill and glyph colour, cycling with the row's position.
  (Color background, Color foreground) _tint(BuildContext context) {
    final tokens = context.nest;
    return switch (position % 3) {
      0 => (tokens.leafTint, tokens.leafInk),
      1 => (tokens.lilacTint, tokens.ink),
      _ => (tokens.peachTint, tokens.ink),
    };
  }

  /// Entry type to glyph — see [jarEntryGlyph].
  String get _glyph => jarEntryGlyph(entry.type, entry.iconKey);

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final tint = _tint(context);
    return Container(
      constraints: const BoxConstraints(
        minHeight: JarHistoryCard._rowMinHeight,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: NestSpacing.gap14,
        vertical: NestSpacing.s2,
      ),
      child: Row(
        children: [
          Container(
            width: JarHistoryCard._discSize,
            height: JarHistoryCard._discSize,
            decoration: BoxDecoration(color: tint.$1, shape: BoxShape.circle),
            child: Center(child: NestIcon(_glyph, color: tint.$2)),
          ),
          const SizedBox(width: NestSpacing.s3),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: titleStyle(tokens.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry.detail,
                  style: subStyle(tokens.ink2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: NestSpacing.s2),
          // K09-BUG-9: the amount sits in a `Flexible` + `FittedBox(scaleDown)`
          // so a large history amount shrinks to fit instead of overflowing
          // the card at 320 px × 1.3 (the goal card's `Flexible` precedent;
          // K10's fund card uses the same `FittedBox` for its money strings).
          // Cells that already fit render at scale 1.0, pixel-identical.
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                formatJarAmount(entry.amountPence),
                style: valueStyle(tokens.leafInk),
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
