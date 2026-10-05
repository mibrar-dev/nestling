// K05 Quest complete (`/quest-complete`, kid mode).
//
// The celebration: a static coin burst behind the child's own Pip, the hero
// line, the coin pill, the promise line, Pip's cheer bubble and the growth
// card, then one big "Yay! Back home" in a bottom bar whose surface runs to
// the physical screen edge (owner rule).
//
// Geometry is transcribed from
// `design/html-source/screens/K05-quest-complete.html` and measured against
// `design/screens/light/K05-quest-complete.png` ÷3 (every number in the
// comments below is that measurement):
//
//   y    0… 47  `.status-bar` (47, `NestDevice.statusH`; the OS draws glyphs)
//   y   47…105  `.k5-top` (56 px lock row, `padding: 0 20px 2px`)
//   y  105…339  `.k5-stage` (14 + 218 + 2); `.burst` is `position:absolute`,
//               `top:0`, 320×200 centred (x 35…355) — gold ink x 40.67…353,
//               y 108.67…299, exactly the SVG's circles inset by its 3 px
//               stroke. Pip art (ink/sunny) x 149…244.67, y 180…302.67
//               inside the 218 slot at x 86…304, y 119…337, rotated −8°.
//   y  343…387  `h1.kid-hero` (`.k5-hero { margin-top: 4px }` beats the
//               `.scroll > * + *` 16; ink y 348.33…385.33)
//   y  403…443  `.k5-mid` `.coin-pill.big` (tint x 121…268.67, y 403…442.67)
//   y  459…485  `.k5-sub` `.kid-body` (ink y 465…481.33)
//   y  501…545  `.k5-cheer` `.speech` (white 504…541.67, so 3 + 8 + 22 + 8
//               + 3 = 44; tail paints 9 px below as overflow)
//   y  561…695  `.k5-card` (3 + 14 + 48 + 10 + 20 + 6 + 16 + 14 + 3 = 134;
//               ink border x 20…369.67, content x 39…351)
//   y  721…810  `.kid-bar` (3 + 12 + 64 + 10), home indicator 810…844
//
// Copy is verbatim from the HTML (all ASCII on this screen).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/assets/nestling_assets.dart'
    as nest_assets;
// `hide PipMood`: the barrel exports the v1 `PipMood` from `pip_rive.dart`,
// which collides with the v2 one this screen uses (same shape as K04).
import 'package:nestling/core/design_system/design_system.dart' hide PipMood;
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_growth.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_bloc.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_event.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_state.dart';
import 'package:nestling/features/kid_home/presentation/widgets/kid_style_helpers.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';

/// `.burst`: the design's 320×200 coin-burst plate (`.k5-burst` is
/// `position:absolute; left:50%; top:0`, so it sits behind Pip and never
/// takes layout space — the stage is 14 + 218 + 2 = 234).
const double _kBurstWidth = 320;
const double _kBurstHeight = 200;

/// `.k5-pip`: the design's 218 px Pip slot, rotated −8° to read as a jump.
const double _kPipSlot = 218;

/// `.k5-pip` tilt. `−8°` in radians; the rotation is visual only, so it does
/// not change any measured rect (Transform paints, never lays out).
const double _kPipTilt = -8 * 3.141592653589793 / 180;

/// `.k5-pip { margin: 14px 0 2px }` — Pip's own top margin. Kept separate
/// from the card's `padding` even though both are 14: the two CSS
/// declarations are unrelated, so a future card-padding edit must not move
/// Pip.
const double _kPipMarginTop = NestSpacing.gap14;

/// `.k5-card-top img`: the growth card's 32 px Pip.
const double _kMiniPipSlot = 32;

/// `.k5-card`'s `padding: 14px 16px` (Flutter `Container` also insets by the
/// 3 px decoration border, which is exactly the CSS content box).
const double _kCardPadV = NestSpacing.gap14;
const double _kCardPadH = NestSpacing.s4;

/// `.k5-count { margin-top: 10px; margin-bottom: 6px }`.
const double _kCountGapTop = NestSpacing.gap10;
const double _kCountGapBottom = NestSpacing.gap6;

/// `.k5-hero { margin-top: 4px }` — the screen's own margin wins over the
/// `.scroll > * + *` 16 px rhythm (SPACING_SPEC §9).
const double _kHeroGap = NestSpacing.s1;

/// `.kid-bar { padding: 12px 20px 10px; gap: 10px }` measured against the PNG
/// (bar 721…810, painted button 736…800). `NestKidButton` reserves its own
/// 6 px shadow room under each painted button, so the CSS 10 px bottom air
/// hands 6 of those px back: bottom padding is `s1`, and the painted button
/// lands exactly on the design rect. Same reasoning as the K03 dock / K04 bar.
const double _kBarGap = NestSpacing.s1;

/// Coins this celebration is about (plan §b/§d).
///
/// 1. The `coins` K03/K04 pass in the celebration `extra` — the write that
///    just saved is the authority.
/// 2. The row the `extra`'s `questId` names, if it still resolves.
/// 3. On a direct launch (`shot.sh` opens `/quest-complete` with no `extra`,
///    and no other screen in the app pushes it without one): the child's first
///    quest that is actually done (`done_pending` / `approved`) in list order.
///    That is the database's own answer to "what was just finished", so the
///    seed renders the design's `+15 coins` (`q-dishwasher`) without any
///    hard-coded design number.
/// 4. Otherwise 0 — the celebration never blanks, it just has no reward to
///    quote.
int _coinsFor(Object? extra, List<KidQuest> items) {
  final map = extra is Map<Object?, Object?>
      ? extra
      : const <Object?, Object?>{};
  final questId = map['questId'];
  final coins = map['coins'];
  if (coins is int) return coins;
  if (questId is String) {
    for (final item in items) {
      if (item.questId == questId) return item.coins;
    }
  }
  for (final item in items) {
    if (item.status == 'done_pending' || item.status == 'approved') {
      return item.coins;
    }
  }
  return 0;
}

/// K05 view root: the load / failure channels, then the celebration.
class QuestCompleteView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KidHomeBloc, KidHomeState>(
      // This screen draws only the load channel, the active child and the
      // item list. Every other field of the shared `KidHomeState` (the K01
      // roster, the K02 PIN one-shots, the completion SnackBar channel) is
      // consumed by other routes, so an emission that only moves those must
      // not rebuild the 218 px Pip, the burst plate and the progress card
      // (review finding 9).
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.child != current.child ||
          previous.items != current.items,
      builder: (context, state) {
        switch (state.status) {
          case KidHomeStatus.initial:
          case KidHomeStatus.loading:
            return const _KidLoading();
          case KidHomeStatus.failure:
            return _KidFailure(child: state.child);
          case KidHomeStatus.loaded:
            final child = state.child;
            if (child == null) {
              return const _NoActiveChild();
            }
            return _QuestCompleteBody(
              child: child,
              coins: _coinsFor(GoRouterState.of(context).extra, state.items),
            );
        }
      },
    );
  }
}

class _KidLoading extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            // The same top row as the loaded screen, so nothing jumps when
            // the celebration arrives.
            const _TopBar(),
            Expanded(
              child: Center(
                child: Semantics(
                  label: 'Loading your celebration',
                  child: CircularProgressIndicator(color: tokens.leaf),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KidFailure extends StatelessWidget {
  const new({this.child});

  /// The last known child, when the stream failed after a load: the error
  /// card shows their own Pip, never a stranger's.
  final KidChild? child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final known = child;
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            const _TopBar(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NestSpacing.padSide,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: NestSpacing.s2,
                    children: [
                      if (known != null)
                        PipAvatar(
                          style: pipStyleOf(known.pipStyle),
                          stage: known.pipStage.clamp(1, 4),
                          skin: pipSkinOf(known.pipSkin),
                          accessory: pipAccessoryOf(known.pipAccessory),
                          size: 140,
                        )
                      else
                        const PipAvatar(
                          style: PipStyle.mochi,
                          stage: 1,
                          size: 140,
                        ),
                      Text(
                        'Oh no! Pip got lost.',
                        style: NestType.h2(color: tokens.ink),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        "Let's try again.",
                        style: NestType.bodySmall(color: tokens.ink2),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: NestSpacing.s1),
                      NestKidButton(
                        label: 'Try again',
                        color: NestKidButtonColor.white,
                        fullWidth: false,
                        onPressed: () => context.read<KidHomeBloc>().add(
                          const KidHomeLoadRequested(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoActiveChild extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            const _TopBar(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: NestSpacing.s3,
                  children: [
                    Text(
                      "Who's playing?",
                      style: NestType.h2(color: tokens.ink),
                      textAlign: TextAlign.center,
                    ),
                    NestKidButton(
                      label: 'Choose',
                      color: NestKidButtonColor.lilac,
                      fullWidth: false,
                      onPressed: () => context.go(KidHomeRoutePaths.picker),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.k5-top`: the parental gate on the right only (there is no back arrow on
/// this screen — the design leaves with the CTA). 56 px, `padding: 0 20px
/// 2px`, so the lock sits at x 314…370, y 47…103 (PNG y 47…102.67).
class _TopBar extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        0,
        NestSpacing.padSide,
        NestSpacing.gap2,
      ),
      child: Row(children: [Spacer(), _GateLockButton()]),
    );
  }
}

/// The loaded celebration: the design's `.scroll` between the top row and the
/// `.kid-bar`.
class _QuestCompleteBody extends StatelessWidget {
  const new({required this.child, required this.coins});

  final KidChild child;

  /// Coins this quest paid. From the celebration `extra` K03/K04 push, else the
  /// named quest row, else 0 (a deep link with no extra still celebrates — the
  /// title and the growth card never depend on a quest).
  final int coins;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            const _TopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  NestSpacing.padSide,
                  0,
                  NestSpacing.padSide,
                  NestSpacing.s8,
                ),
                children: [
                  // `.k5-stage`: the burst is `position:absolute` behind Pip,
                  // so the stage is exactly Pip's margin box.
                  SizedBox(
                    height: _kPipSlot + _kPipMarginTop + NestSpacing.gap2,
                    child: Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        // PIP RULE: never the v1 `pip_stage_*.svg`. This is
                        // the design's static coin burst plate (the same SVG
                        // the HTML inlines), decorative and non-interactive.
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: IgnorePointer(
                            child: ExcludeSemantics(
                              // `scaleDown` so the plate never overflows a
                              // narrow screen (320 px cell) — the design's
                              // 320-wide plate stays centred either way.
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: SizedBox(
                                  width: _kBurstWidth,
                                  height: _kBurstHeight,
                                  child: SvgPicture.asset(
                                    nest_assets
                                        .NestlingIllustrations
                                        .coinsBurst,
                                    placeholderBuilder: (_) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          // `.k5-pip { margin: 14px 0 2px }`.
                          padding: const EdgeInsets.only(
                            top: _kPipMarginTop,
                            bottom: NestSpacing.gap2,
                          ),
                          child: Transform.rotate(
                            angle: _kPipTilt,
                            child: Semantics(
                              image: true,
                              label:
                                  'Pip the ${pipStageName(child.pipStage)}, '
                                  'stage ${child.pipStage.clamp(1, 4)} of 4, '
                                  'doing a happy dance',
                              excludeSemantics: true,
                              child: PipAvatar(
                                style: pipStyleOf(child.pipStyle),
                                stage: child.pipStage.clamp(1, 4),
                                skin: pipSkinOf(child.pipSkin),
                                accessory: pipAccessoryOf(child.pipAccessory),
                                mood: PipMood.happy,
                                size: _kPipSlot,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // `.k5-hero { margin-top: 4px }` — the screen wins over the
                  // `.scroll > * + *` 16 px rhythm.
                  const SizedBox(height: _kHeroGap),
                  // `.kid-hero` is `text-wrap: balance`, so the heading breaks
                  // like the design instead of orphaning a word. The design's
                  // h1 has no line cap; 3 lines keep a double-barrelled UK
                  // nickname whole (K05-BUG-4) while "Brilliant, Maya!" stays
                  // the design's single 44 px line.
                  NestBalancedText(
                    'Brilliant, ${child.nickname}!',
                    style: NestType.kidHero(color: tokens.ink),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: NestSpacing.s4),
                  Center(
                    child: NestCoinPill(
                      // The quest editor's floor is 1 coin (K05-BUG-1): a
                      // one-coin quest reads "+1 coin", never "+1 coins".
                      amount: '+$coins ${coins == 1 ? 'coin' : 'coins'}',
                      size: NestCoinPillSize.large,
                      semanticLabel:
                          '$coins ${coins == 1 ? 'coin' : 'coins'} earned',
                    ),
                  ),
                  const SizedBox(height: NestSpacing.s4),
                  Text(
                    'Mum will give it a thumbs-up soon.',
                    style: NestType.kidBody(color: tokens.ink),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    softWrap: true,
                  ),
                  const SizedBox(height: NestSpacing.s4),
                  // `.k5-cheer { display:flex; justify-content:center }` —
                  // the bubble alone on this screen (no cheer Pip beside it,
                  // unlike K04).
                  const Center(child: NestSpeechBubble(text: _kCheerLine)),
                  const SizedBox(height: NestSpacing.s4),
                  _GrowthCard(child: child),
                ],
              ),
            ),
            // Bottom edge (owner rule): the bar's own surface runs to the
            // physical screen edge — the `SafeArea` inset sits INSIDE the
            // surface box, so no meadow/sky strip shows under it. The button
            // stays above the inset; the OS draws the home pill.
            Container(
              decoration: BoxDecoration(
                color: tokens.surface,
                border: Border(top: BorderSide(color: tokens.ink, width: 3)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        NestSpacing.padSide,
                        NestSpacing.s3,
                        NestSpacing.padSide,
                        _kBarGap,
                      ),
                      child: NestKidButton(
                        label: 'Yay! Back home',
                        onPressed: () => context.go(KidHomeRoutePaths.home),
                      ),
                    ),
                    const NestHomeIndicator(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.k5-cheer`'s line — the design's speech bubble copy.
const String _kCheerLine = 'Pip is doing a happy dance!';

/// `.k5-card`: the growth card — lilac tint, 3 px ink border, r24, kid shadow,
/// `padding: 14px 16px`. The headline is 18/24 w900 (`.k5-card-top strong`
/// bumps `.h3`'s weight to 900), the count row `.kcap` 15/20 w700 ink-2, and
/// `.progress.kid` 16 tall with a 2 px ink border.
class _GrowthCard extends StatelessWidget {
  const new({required this.child});

  final KidChild child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final kid = context.nestKid;
    final total = child.pipTotalCoins;
    final headline = kidPipGrowthCopy(total);
    final count = kidPipGrowthCount(total);
    // Clamp like K06's growth card: a Pip already at the last stage has no
    // stage 5, so it names the stage Pip is (a Songbird stays a Songbird).
    final nextName = pipStageName((child.pipStage + 1).clamp(1, 4));
    final next = 'Next: $nextName';
    final fraction = kidPipGrowthFraction(total);
    // Floor, never round, while the bar is short of the threshold: 249/250
    // must not announce "100%" next to "1 more coin to grow" (K05-BUG-2).
    final percent = fraction >= 1 ? 100 : (fraction * 100).floor();
    // K05-BUG-6: `NestProgress` derives its semantics VALUE as
    // `(fraction * 100).round()`, so passing the true fraction (0.996 for
    // 249/250) announces "100 percent" beside the floored "99%" label.
    // `core/design_system` is owned by another agent, so K05 passes the
    // floored figure (`percent / 100`) to BOTH the bar and the label: the
    // value then rounds back to the same percent, seed values are unchanged
    // (175 → 0.7), and the bar shortens by <2 px only for non-seed totals.
    final displayFraction = percent / 100.0;
    // The card's THREE text lines are one announcement (plan §e), so they
    // collapse into a single labelled node. `NestProgress` sits OUTSIDE that
    // node and keeps its own `role=img` label (the design's `aria-label`) as
    // a separate node, so nothing is announced twice — which is also why the
    // card label stops at "Next …" (the progress node carries the figure).
    final cardText = Semantics(
      container: true,
      label: '$headline. $count. Next $nextName.',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // `.k5-card-top { display:flex; align-items:center; gap:8px }`.
          Row(
            spacing: NestSpacing.s2,
            children: [
              // Decorative: the card's own label carries the same words.
              PipAvatar(
                style: pipStyleOf(child.pipStyle),
                stage: child.pipStage.clamp(1, 4),
                skin: pipSkinOf(child.pipSkin),
                accessory: pipAccessoryOf(child.pipAccessory),
                size: _kMiniPipSlot,
              ),
              Flexible(
                child: Text(
                  headline,
                  // `.k5-card-top strong`: 18/24, weight 900 (the token
                  // scale's `h3` at w900 — no tracking, per the design).
                  style: NestType.h3(color: tokens.ink)
                      .copyWith(fontWeight: FontWeight.w900),
                  softWrap: true,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: _kCountGapTop),
          // `.k5-count { display:flex; justify-content:space-between }` — the
          // design's one line whenever both labels fit (390/1.0: count from
          // x 39, "Next: …" pinned right at 351). At the supported 320 px /
          // 1.3× size one line gives each label 117 px while the text needs
          // ~150, so the labels stack instead of ellipsising (K05-BUG-3);
          // the decision measures the labels with the live text scaler.
          LayoutBuilder(
            builder: (context, constraints) {
              final style = NestType.kidCaption(color: tokens.ink2);
              final scaler = MediaQuery.textScalerOf(context);
              double labelWidth(String text) {
                final painter = TextPainter(
                  text: TextSpan(text: text, style: style),
                  textDirection: Directionality.of(context),
                  textScaler: scaler,
                  maxLines: 1,
                )..layout();
                return painter.width;
              }

              final countW = labelWidth(count);
              final nextW = labelWidth(next);
              final oneLine =
                  countW + NestSpacing.s2 + nextW <= constraints.maxWidth;
              if (oneLine) {
                // K05-BUG-5: the one-line `Row` must give each label the room
                // it measured — equal `Flexible` gave each only
                // `(maxWidth - gap) / 2`, so an asymmetric pair (a 4-digit
                // count with the short `Next:` label) ellipsised even though
                // the pair fits. Flex proportional to the measured widths
                // keeps one line with no ellipsis; seed values stay one line
                // at the same painted positions (left/right aligned).
                final countFlex = countW.round().clamp(1, 1000000);
                final nextFlex = nextW.round().clamp(1, 1000000);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: NestSpacing.s2,
                  children: [
                    Expanded(
                      flex: countFlex,
                      child: Text(
                        count,
                        style: style,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: nextFlex,
                      child: Text(
                        next,
                        style: style,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: style,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    next,
                    style: style,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _kCardPadH,
        vertical: _kCardPadV,
      ),
      decoration: BoxDecoration(
        color: tokens.lilacTint,
        borderRadius: NestRadii.allL,
        border: Border.all(color: tokens.ink, width: kid.borderWidth),
        boxShadow: tokens.kidShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          cardText,
          const SizedBox(height: _kCountGapBottom),
          NestProgress(
            fraction: displayFraction,
            kid: true,
            semanticLabel: 'Pip is $percent% of the way to $nextName',
          ),
        ],
      ),
    );
  }
}

/// Parental-gate lock with a tap guard (K03-BUG-9 pattern): one gate route per
/// gesture burst, even on a fast double tap.
class _GateLockButton extends StatefulWidget {
  const new();

  @override
  State<_GateLockButton> createState() => _GateLockButtonState();
}

class _GateLockButtonState extends State<_GateLockButton> {
  bool _busy = false;

  Future<void> _open() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context.push(ParentalGateRoutePaths.gate);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return NestLockButton(semanticLabel: 'Grown-ups', onPressed: _open);
  }
}
