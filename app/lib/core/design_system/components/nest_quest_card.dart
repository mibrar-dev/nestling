import 'package:flutter/material.dart';
import 'package:nestling/core/design_system/components/nest_coin_pill.dart';
import 'package:nestling/core/design_system/components/nest_icon.dart';
import 'package:nestling/core/design_system/tokens/nest_tokens.dart';
import 'package:nestling/core/design_system/tokens/radii.dart';
import 'package:nestling/core/design_system/tokens/spacing.dart';
import 'package:nestling/core/design_system/tokens/typography.dart';

class NestQuestCard extends StatelessWidget {
  const new({
    required this.title,
    super.key,
    this.meta,
    this.metaChips = const <Widget>[],
    this.leading,
    this.trailing,
    this.done,
    this.onToggled,
    this.onTap,
    this.maxLines = 1,
    this.semanticLabel,
  });

  final String title;
  final String? meta;

  /// Extra chips rendered after [meta] in the meta row (e.g. P08 status).
  final List<Widget> metaChips;
  final Widget? leading;
  final Widget? trailing;
  final bool? done;
  final ValueChanged<bool>? onToggled;
  final VoidCallback? onTap;
  final int maxLines;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final metaText = meta;
    final leadingWidget = leading;
    final trailingWidget = trailing;
    final checkState = done;
    final card = Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: NestRadii.allM,
        boxShadow: tokens.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: NestRadii.allM,
        child: InkWell(
          borderRadius: NestRadii.allM,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(NestSpacing.s3),
            child: Row(
              spacing: NestSpacing.s3,
              children: [
                ?leadingWidget,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: NestType.bodyStrong(color: tokens.ink)
                            .copyWith(height: 22 / 16),
                        maxLines: maxLines,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (metaText != null || metaChips.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: NestSpacing.gap2),
                          child: Wrap(
                            spacing: NestSpacing.gap6,
                            // `.quest-meta { gap: 6px }` both axes (P08 §7);
                            // was `s1` (4) — invisible at 390px, visible when
                            // the meta wraps at 320px / 1.3x text.
                            runSpacing: NestSpacing.gap6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (metaText != null)
                                Text(
                                  metaText,
                                  style: NestType.caption(color: tokens.ink2),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ...metaChips,
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                ?trailingWidget,
                if (checkState != null)
                  _ParentCheck(done: checkState, onToggled: onToggled),
              ],
            ),
          ),
        ),
      ),
    );
    if (onTap != null) {
      final tap = onTap;
      return Semantics(
        button: true,
        enabled: true,
        label: semanticLabel ?? title,
        // One node per card (P08 §2): the label already announces
        // title + meta, so descendants must not merge a second copy —
        // unless the card carries a working check (`done != null`), whose
        // own `Mark done`/`Done` node must stay reachable (shared
        // display/overflow tests pin it). `onTap` mirrors the InkWell:
        // `excludeSemantics` drops the descendant tap action.
        excludeSemantics: checkState == null,
        onTap: tap,
        child: card,
      );
    }
    return card;
  }
}

class NestKidQuestCard extends StatelessWidget {
  const new({
    required this.title,
    super.key,
    this.icon,
    this.tileBackground,
    this.tileIconColor,
    this.coinAmount,
    this.metaChip,
    this.done = false,
    this.onToggled,
    this.onTap,
    this.semanticLabel,
  });

  final String title;
  final Widget? icon;

  /// Icon-tile background override. Defaults to `surface2`; K03 passes the
  /// per-quest tint (`skyTint` dishwasher, `lilacTint` reading,
  /// `peachTint` tidy) from `design/html-source/screens/K03-kid-home.html`.
  final Color? tileBackground;

  /// Icon-tile glyph colour for the default `questCard` glyph (custom
  /// [icon] widgets carry their own colour). Defaults to the theme ink,
  /// matching the K03 design (ink icons on tinted tiles).
  final Color? tileIconColor;
  final String? coinAmount;

  /// Custom meta content (e.g. the K03 "Waiting for Mum" chip), rendered
  /// in place of the [coinAmount] pill.
  final Widget? metaChip;
  final bool done;
  final ValueChanged<bool>? onToggled;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final reward = coinAmount;
    final card = Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.all(NestSpacing.s3),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: NestRadii.allL,
          border: Border.all(
            color: tokens.ink,
            width: context.nestKid.borderWidth,
          ),
          boxShadow: tokens.kidShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: NestRadii.allL,
          child: InkWell(
            borderRadius: NestRadii.allL,
            onTap: onTap,
            child: Row(
              spacing: NestSpacing.s3,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: tileBackground ?? tokens.surface2,
                    borderRadius: NestRadii.allM,
                  ),
                  alignment: Alignment.center,
                  child:
                      icon ??
                      NestIcon(
                        NestIcons.questCard,
                        size: 28,
                        color: tileIconColor ?? tokens.ink,
                      ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        // K03: Nunito 800 17/22, wrapping to 2 lines —
                        // kid titles are never cut to a single ellipsis.
                        style: NestType.h3(color: tokens.ink)
                            .copyWith(fontSize: 17, height: 22 / 17),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (reward != null || metaChip != null)
                        Padding(
                          padding: const EdgeInsets.only(top: NestSpacing.s1),
                          child: metaChip ?? NestCoinPill(amount: reward!),
                        ),
                    ],
                  ),
                ),
                _QuestCheck(done: done, onToggled: onToggled),
              ],
            ),
          ),
        ),
      ),
    );
    if (onTap != null) {
      final tap = onTap;
      return Semantics(
        button: true,
        enabled: true,
        label: semanticLabel ?? title,
        // One node per card (P08 §2) — unless the check is functional
        // (`onToggled != null`), whose own node must stay reachable.
        // A display-only check (`onToggled == null`) is noise next to the
        // explicit label, so it is excluded with the rest. `onTap`
        // mirrors the InkWell: `excludeSemantics` drops the tap action.
        excludeSemantics: onToggled == null,
        onTap: tap,
        child: card,
      );
    }
    return card;
  }
}

/// Parent quest check: 28px visual ring (2px line-colour border when empty,
/// filled leaf + 16px tick when done) with a 44px hit area via padding.
///
/// Only the kid card uses the big 56 check. The card height stays
/// content-driven; the row vertically centres the check.
class _ParentCheck extends StatelessWidget {
  const new({required this.done, this.onToggled});

  final bool done;
  final ValueChanged<bool>? onToggled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final toggled = onToggled;
    return Semantics(
      button: true,
      selected: done,
      enabled: toggled != null,
      label: done ? 'Done' : 'Mark done',
      // One control = one node: the outer label owns the announcement and
      // the inner InkWell contributes no second tap node.
      excludeSemantics: true,
      onTap: toggled == null ? null : () => toggled(!done),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: toggled == null ? null : () => toggled(!done),
        child: Padding(
          padding: const EdgeInsets.all(NestSpacing.s2),
          child: SizedBox.square(
            dimension: NestDevice.checkRing,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? tokens.leaf : Colors.transparent,
                border: Border.all(
                  color: done ? tokens.leaf : tokens.line,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: done
                  ? NestIcon(
                      NestIcons.check,
                      size: NestSpacing.s4,
                      color: tokens.onLeaf,
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestCheck extends StatelessWidget {
  const new({required this.done, this.onToggled});

  final bool done;
  final ValueChanged<bool>? onToggled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final toggled = onToggled;
    final face = SizedBox(
      width: NestDevice.tapKid,
      height: NestDevice.tapKid,
      child: Material(
        color: done ? tokens.leaf : tokens.surface,
        shape: CircleBorder(
          side: BorderSide(
            color: done ? tokens.leaf : tokens.ink,
            width: context.nestKid.borderWidth,
          ),
        ),
        child: Center(
          child: done
              ? NestIcon(NestIcons.check, size: 28, color: tokens.onLeaf)
              : null,
        ),
      ),
    );
    final tappable = toggled == null
        ? face
        : Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => toggled(!done),
              child: face,
            ),
          );
    return Semantics(
      button: true,
      selected: done,
      enabled: toggled != null,
      label: done ? 'Done' : 'Mark done',
      // One control = one node: the outer label owns the announcement and
      // the inner InkWell contributes no second tap node.
      excludeSemantics: true,
      onTap: toggled == null ? null : () => toggled(!done),
      child: tappable,
    );
  }
}
