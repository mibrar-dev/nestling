// P15 · Child profile body (`/child-profile`, parent mode).
//
// The design (`design/html-source/screens/P15-child-profile.html`) is one
// `.scroll` column of five blocks separated by `.scroll > * + *` (16 px):
//
//   ```
//   47  NestStatusBar                     (.status-bar, sibling of .scroll)
//   47…211  hero card                     (164 = 20 + 64 + 10 + 30 + 20 + 20)
//   227…309  three stat tiles             (82  = 12 + 26 + 2×16 + 12)
//   325…441  Pip card                     (116 = 16 + 84 + 16)
//   457…637  list of three rows           (180 = 3 × 60)
//   653…733  danger card                  (80  = 16 + 48 + 16, clipped by the
//                                               scroll viewport at 727)
//   ```
//
// Every measurement above is `design/screens/light/P15-child-profile.png ÷ 3`
// and is pinned by `child_profile_view_test.dart`. Sizes come from the
// design-system tokens (`.hero`'s 20/16 padding is `s5`/`s4`; the stat
// tiles' 12/6 is `s3`/`gap6`; the 10 px grid gap is `gap10`); nothing here
// hard-codes a colour.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
// Not in the barrel: the v2 Pip widget (PIP ruling — never the v1
// `pip_stage_*.svg` illustrations in product screens).
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/family/domain/entities/child_profile.dart';
import 'package:nestling/features/family/domain/entities/family_child.dart';
import 'package:nestling/features/family/presentation/bloc/family_bloc.dart';
import 'package:nestling/features/family/presentation/bloc/family_event.dart';
import 'package:nestling/features/family/presentation/widgets/child_display.dart';
import 'package:nestling/features/family/presentation/widgets/child_profile_copy.dart';
import 'package:nestling/features/family/presentation/widgets/child_profile_row.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/pip/domain/entities/pip_profile.dart';
import 'package:nestling/features/pocket_money/pocket_money_routes.dart';
import 'package:nestling/features/quests/quests_routes.dart';

/// `.scroll { padding: 0 20px var(--s8) }` — 20 px gutters, 32 px tail.
const EdgeInsets _scrollPadding = EdgeInsets.fromLTRB(
  NestSpacing.padSide,
  0,
  NestSpacing.padSide,
  NestSpacing.s8,
);

/// Scrolled body of P15: the 47 px status-bar reserve (a flex-shrink:0
/// sibling of `.scroll` in the design, so it is pinned here too), then the
/// hero, stats, Pip card, list and danger card.
class ChildProfileBody extends StatelessWidget {
  const ChildProfileBody({required this.profile, super.key});

  final ChildProfile profile;

  @override
  Widget build(BuildContext context) {
    final child = profile.child;
    return Column(
      children: <Widget>[
        const NestStatusBar(),
        Expanded(
          child: ListView(
            padding: _scrollPadding,
            children: <Widget>[
              _HeroCard(child: child),
              const SizedBox(height: NestSpacing.s4),
              _StatsRow(profile: profile),
              const SizedBox(height: NestSpacing.s4),
              _PipCard(child: child),
              const SizedBox(height: NestSpacing.s4),
              _ProfileList(profile: profile),
              const SizedBox(height: NestSpacing.s4),
              _DangerCard(child: child),
            ],
          ),
        ),
      ],
    );
  }
}

/// `.hero` — standard card (surface, r-l, sh-1) with the screen's own
/// `padding: 20px 16px`, holding the avatar, the name and the age line.
/// Centred column, like the design's `text-align: center`.
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.child});

  final FamilyChild child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final nickname = child.nickname;
    return NestCard(
      key: const Key('p15-hero'),
      // `.hero { padding: 20px 16px }` — the screen wins over the standard
      // 16 px card padding, so it is passed explicitly.
      padding: const EdgeInsets.symmetric(
        vertical: NestSpacing.s5,
        horizontal: NestSpacing.s4,
      ),
      child: Column(
        children: <Widget>[
          NestAvatar(
            initial: nickname.isEmpty ? '?' : nickname[0].toUpperCase(),
            size: NestAvatarSize.s64,
            color: avatarColourFor(child.avatarColour),
            // No semantic label: the initial is the first letter of the name
            // printed directly beneath it, so labelling the avatar would
            // announce "Maya, M" (P05's kid cards omit it for the same
            // reason).
          ),
          // `.hero h1 { margin-top: 10px }`.
          const SizedBox(height: NestSpacing.gap10),
          // Every other screen flags its title as a heading for
          // VoiceOver/TalkBack (`add_children_view.dart:196`,
          // `today_loaded_body.dart:375`, `money_ledger_view.dart:207`), so
          // the child's name — the largest text on the route — does too.
          Semantics(
            header: true,
            child: Text(
              nickname,
              // `.hero h1` overrides `.h1`: Nunito 900 at 24/30, not 28/34.
              style: NestType.h1(color: tokens.ink)
                  .copyWith(fontSize: 24, height: 30 / 24),
              textAlign: TextAlign.center,
              // No `nowrap` in the design: `components.css:43` gives bare `h1`
              // `overflow-wrap: anywhere`, so a long nickname wraps and the
              // hero grows rather than truncating (review finding 6). The cap
              // of three lines keeps an extreme name + 1.3 text scale from
              // swallowing the stats band below.
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            profileAgeLine(child),
            style: NestType.body(color: tokens.ink2)
                .copyWith(fontSize: 14, height: 20 / 14),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// `.stats` — three equal `1fr` tiles, `gap: 10`.
///
/// The tiles are a CSS grid, so all three are as tall as the tallest (the
/// "Quests this week" label wraps to two lines → 82 px). `IntrinsicHeight`
/// plus a stretching row reproduces that without a fixed height.
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});

  final ChildProfile profile;

  @override
  Widget build(BuildContext context) {
    final child = profile.child;
    final tiles = <({Key key, String value, String label})>[
      (
        key: const Key('p15-stat-quests'),
        value: '${profile.questsThisWeek}',
        label: 'Quests this week',
      ),
      (
        key: const Key('p15-stat-coins'),
        value: '${child.coins}',
        label: 'Coins',
      ),
      (
        key: const Key('p15-stat-days'),
        value: '${child.happyDays}',
        label: 'Happy days',
      ),
    ];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var i = 0; i < tiles.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: NestSpacing.gap10),
            Expanded(
              child: _StatTile(
                key: tiles[i].key,
                value: tiles[i].value,
                label: tiles[i].label,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// `.stat` — surface tile, radius `r-m` (16, NOT the card's `r-l`), sh-1,
/// `padding: 12px 6px`, centred. Not a `NestCard`: the design's `.stat`
/// radius is 16 and it carries no interactive behaviour.
class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label, super.key});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: NestSpacing.s3,
        horizontal: NestSpacing.gap6,
      ),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: NestRadii.allM,
        boxShadow: tokens.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            // `.stat .v` — Nunito 900 22/26, tabular figures (`.num`).
            style: NestType.kidName(color: tokens.ink).copyWith(
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            // `.stat .l` — Inter 600 12/16 ink-2, wraps to two lines.
            style: NestType.caption(color: tokens.ink2).copyWith(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// `.card > .piprow` — the child's OWN Pip (`PipAvatar`, PIP ruling) in the
/// design's 84 px slot, beside the heading, the evolves caption, the base
/// 8 px growth bar and the `175 of 250 · 70%` caption.
class _PipCard extends StatelessWidget {
  const _PipCard({required this.child});

  final FamilyChild child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final totalCoins = child.pipTotalCoins;
    return NestCard(
      key: const Key('p15-pip'),
      child: Row(
        spacing: NestSpacing.s3,
        children: <Widget>[
          Semantics(
            image: true,
            label: profilePipSemanticLabel(child),
            child: ExcludeSemantics(
              child: PipAvatar(
                style: _pipStyle(child.pipStyle),
                stage: child.pipStage.clamp(1, 4),
                skin: _pipSkin(child.pipSkin),
                accessory: _pipAccessory(child.pipAccessory),
                // `.piprow img { width: 84px; height: 84px }` — off the 4 pt
                // grid and not a token (review finding 7); `SHARED_REQUEST.md`
                // §3 asks for a named slot token. The design value stands
                // meanwhile, exactly like the 48 px button literal below.
                size: 84,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  profilePipTitle(child),
                  // Screen-local `.piprow` head: Nunito 800 17/24.
                  style: NestType.h3(color: tokens.ink)
                      .copyWith(fontSize: 17, height: 24 / 17),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  profileEvolvesCaption(PipProfile.evolveAtCoins),
                  style: NestType.caption(color: tokens.ink2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: NestSpacing.s2),
                NestProgress(
                  fraction: pipGrowthFraction(
                    totalCoins,
                    PipProfile.evolveAtCoins,
                  ),
                  semanticLabel: 'Pip evolution progress',
                ),
                const SizedBox(height: NestSpacing.s1),
                Text(
                  profileGrowthCaption(totalCoins, PipProfile.evolveAtCoins),
                  style: NestType.caption(color: tokens.ink2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

PipStyle _pipStyle(String raw) => switch (raw) {
  'bolt' => PipStyle.bolt,
  'storybook' => PipStyle.storybook,
  _ => PipStyle.mochi,
};

PipSkin _pipSkin(String raw) => switch (raw) {
  'berry' => PipSkin.berry,
  'sky' => PipSkin.sky,
  'mint' => PipSkin.mint,
  _ => PipSkin.sunny,
};

PipAccessory _pipAccessory(String raw) => switch (raw) {
  'bow' => PipAccessory.bow,
  'cap' => PipAccessory.cap,
  'scarf' => PipAccessory.scarf,
  'glasses' => PipAccessory.glasses,
  _ => PipAccessory.none,
};

/// `.list` — one surface card, radius `r-m`, three `ProfileRow`s with the
/// design's overlay dividers (72 px indent) built into `NestList`.
class _ProfileList extends StatelessWidget {
  const _ProfileList({required this.profile});

  final ChildProfile profile;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final child = profile.child;
    return NestList(
      children: <Widget>[
        ProfileRow(
          key: const Key('p15-row-pin'),
          title: 'Kid PIN',
          subtitle: profilePinSubtitle(child),
          tint: NestTileTint.sky,
          leading: (fg) => NestIcon(NestIcons.lock, color: fg),
          // `.list-trail` — Inter 600 ink-3, vertically centred.
          trailing: Text(
            profilePinTrailing(),
            style: NestType.body(color: tokens.ink3)
                .copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            softWrap: false,
          ),
          onTap: () => context.push(KidHomeRoutePaths.pin),
        ),
        ProfileRow(
          key: const Key('p15-row-quests'),
          title: 'Quests',
          subtitle: profileQuestsSubtitle(
            daily: profile.dailyActive,
            weekly: profile.weeklyActive,
            once: profile.onceActive,
          ),
          tint: NestTileTint.leaf,
          // The design draws `circle r9` + `check` in one 24×24 tile, and
          // `ic_quests.svg` IS that glyph (same `circle cx12 cy12 r9` + the
          // same `m8.5 12.5 11 15 4.5-5.5` tick, 24 viewBox) — so the shared
          // asset is an exact match, where a bare `NestIcons.check` read as a
          // plain tick (5_ui deviation 2). `SHARED_REQUEST.md` §2a is
          // therefore satisfied by an existing icon, no new asset needed.
          leading: (fg) => NestIcon(NestIcons.quests, color: fg),
          trailing: _chevron(tokens.ink3),
          onTap: () => context.go(QuestsRoutePaths.library),
        ),
        ProfileRow(
          key: const Key('p15-row-money'),
          title: 'Pocket money',
          subtitle: profileMoneySubtitle(
            child.weeklyBasePence,
            profile.owedPence,
          ),
          tint: NestTileTint.coin,
          // The design's tile holds the COLOURED `assets/illustrations/coin.svg`
          // (`<img src="../assets/coin.svg" width="24" height="24">`), not a
          // tintable line icon — `NestIcon(poundCoin)` drew a `£` in a circle
          // and lost the gold coin (5_ui deviation 3). Illustrations keep their
          // own colours, so this one is a bare `SvgPicture`; the 24 px square
          // is the same box `NestIcon` uses (and what lets the row's own
          // semantics node absorb the icon — the design marks it `alt=""`).
          leading: (_) => SizedBox.square(
            dimension: 24,
            child: SvgPicture.asset(
              NestlingIllustrations.coin,
              width: 24,
              height: 24,
            ),
          ),
          trailing: _chevron(tokens.ink3),
          onTap: () => context.go(PocketMoneyRoutePaths.ledger),
        ),
      ],
    );
  }

  static Widget _chevron(Color color) => Text(
    kProfileChevron,
    style: NestType.body(color: color).copyWith(fontWeight: FontWeight.w600),
    maxLines: 1,
    softWrap: false,
  );
}

/// `.card > button.danger` — full-width danger ghost, 48 high, Inter 700 15.
/// The design has no confirmation dialog, so the tap opens the P15 modal
/// (`1_plan.md` §(c)) and only a confirmed `Remove` removes the child.
class _DangerCard extends StatelessWidget {
  const _DangerCard({required this.child});

  final FamilyChild child;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      key: const Key('p15-danger'),
      child: NestButton(
        key: const Key('p15-remove'),
        label: profileRemoveLabel(child.nickname),
        variant: NestButtonVariant.dangerGhost,
        // `.danger { font-weight: 700; font-size: 15px; min-height: 48px }`.
        // 48 is off the 4 pt scale (`s8` is 32, `s10` is 40); P05/P11/P12
        // buttons carry the same literal, so the design value stands.
        fontSize: 15,
        minHeight: 48,
        onPressed: () => _confirmRemove(context, child),
      ),
    );
  }
}

/// `Remove Maya?` confirm dialog: ghost `Cancel` then danger `Remove`.
///
/// The bloc is read BEFORE the dialog opens — the dialog is a sibling route
/// on the app Navigator, so its own context sits above the route's
/// `BlocProvider` and could not resolve `FamilyBloc`.
Future<void> _confirmRemove(BuildContext context, FamilyChild child) async {
  final bloc = context.read<FamilyBloc>();
  final tokens = context.nest;
  await showNestModal<void>(
    context,
    title: profileRemoveTitle(child.nickname),
    child: Builder(
      builder: (dialogContext) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            profileRemoveBody,
            style: NestType.bodySmall(color: tokens.ink),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: NestSpacing.s5),
          NestButton(
            label: 'Cancel',
            variant: NestButtonVariant.ghost,
            // Same 48 px control height as the row that opened the dialog
            // (both ≥ the 44 px parent tap target).
            minHeight: 48,
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          const SizedBox(height: NestSpacing.s2),
          NestButton(
            label: 'Remove',
            variant: NestButtonVariant.dangerGhost,
            minHeight: 48,
            onPressed: () {
              bloc.add(FamilyRemoveChildRequested(childId: child.id));
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    ),
  );
}
