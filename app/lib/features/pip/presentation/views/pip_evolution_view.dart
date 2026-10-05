// K07 · Pip evolves (`/pip-evolution`).
//
// Layout transcribes `design/html-source/screens/K07-evolution.html` row for
// row (measured against the light/dark PNGs, 390x844, CSS px):
//
//   status bar        47 (reserve only — the OS draws the glyphs)
//   .k7-top           56 px lock, right, `padding: 0 20px 2px`  -> 47..105
//   .scroll           `padding: 0 20px 32px`, `> * + *` = 16
//     .k7-stage       250          105..355
//     .k7-hero        `.kid-title` (balance) 371..405
//     .k7-sub         `.kid-body`           421..447
//     .k7-cheer       `.speech` (44 per line) 463..529
//     .k7-stats       three 110 px cards    545..629
//     .kcap           645..665
//   .kid-bar          3 + 12 + 64 + 4 + 34  721..844 (CTA at 736..800)
//   .home-indicator   inside the bar's surface (owner bottom-edge rule)
//
// Two deliberate, measured departures from the CSS — both to keep the painted
// geometry on the design's pixels:
//
//   1. No `KidScope` (`1_plan.md` §0): K07's `.screen.kid` overrides the kid
//      background with a lilac radial glow and its body has no `.meadow`
//      element. The glow and the SHARED dark stars painter live in
//      `presentation/widgets/pip_evolution_background.dart`.
//   2. `.kid-bar`'s bottom padding is 4 px (`s1`), not the CSS 10 px: the
//      shared `NestKidButton` reserves 6 px under its box for the `--sh-kid`
//      shadow, so 12/20/10 would make the bar 6 px taller than the design's
//      89 + 34 and lift every painted rect 6 px off (the K03 dock absorbed the
//      same 6 the same way). 3 + 12 + 64 + 6 + 4 + 34 = 123 lands the CTA's
//      top edge on the design's measured y = 736 exactly.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart' hide PipStage;
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';
import 'package:nestling/features/pip/domain/entities/pip_evolution.dart';
import 'package:nestling/features/pip/domain/entities/pip_profile.dart';
import 'package:nestling/features/pip/pip_routes.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_bloc.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_event.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_state.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_background.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_copy.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_sparks.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_stage.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_evolution_stats.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_look.dart';

/// `.k7-top { padding: 0 20px 2px }`.
const double _kTopRowBottomPadding = NestSpacing.gap2;

/// `.scroll { padding: 0 var(--pad-side) var(--s8) }` — 32 px bottom air.
const double _kScrollBottomPadding = NestSpacing.s8;

/// `.scroll > * + * { margin-top: var(--s4) }` — the column's own gap.
const double _kScrollGap = NestSpacing.s4;

/// `.kid-bar { padding: 12px 20px 10px }`, with the button's 6 px shadow room
/// absorbed into the bottom padding (see the header note).
const double _kBarTopPadding = NestSpacing.s3;
const double _kBarBottomPadding = NestSpacing.s1;

/// `.kcap` (`K07-evolution.html:14`) is exactly the shared `kidCaption`
/// (Nunito 700 15/20 on ink-2), so it needs no call-site override.
const int _kStatsStageCount = 4;

class PipEvolutionView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PipBloc, PipState>(
      builder: (context, state) {
        // This screen switches on ITS OWN stream's status, never the feature's
        // shared one: the nest stream (K06) shares this bloc, and `PipLoad`
        // subscribes nest-first, so on a cold open the nest answered while the
        // evolution was still in flight (`6_bugs.md` K07-BUG-1 — the old
        // sibling-stream branch painted "Oh no! Pip got lost." on 5 of 5 cold
        // opens). `evolutionStatus` is `loading` until the evolution stream
        // itself answers, `failure` only when IT failed, and a stream that
        // answered and then failed keeps its data on screen.
        switch (state.evolutionStatus) {
          case PipStatus.initial:
          case PipStatus.loading:
            return const _EvolutionLoading();
          case PipStatus.failure:
            // Keep the last-known child on the failure card when there is one
            // (mid-session error must not blank the screen). The nest profile is
            // a last-known-CHILD fallback only: this branch needs the evolution
            // stream's OWN failure to be reached, so a sibling emission can
            // never turn into a false error card (`2a_build_logic.md`
            // CONTRACT CHANGES §1).
            return _EvolutionFailure(
              profile: state.evolution?.profile ?? state.nest?.profile,
            );
          case PipStatus.loaded:
            final evolution = state.evolution;
            // Settled with no evolution is the healthy no-child emission, so
            // the picker hand-off is the right card — not a failure.
            if (evolution != null) return _EvolutionBody(evolution: evolution);
            return const _EvolutionNoChild();
        }
      },
    );
  }
}

/// The screen shell: the CSS background layers behind the chrome, then the
/// chrome itself (status reserve, lock row, scrolling content, bottom bar).
class _EvolutionShell extends StatelessWidget {
  const _EvolutionShell({required this.body, required this.bar});

  final Widget body;
  final Widget bar;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: <Widget>[
          const Positioned.fill(child: PipEvolutionGlow()),
          // `--kid-stars` is `none` in light, so the shared stars painter is
          // dark-only (same mounting as `KidScope`).
          if (tokens.isDark) const Positioned.fill(child: PipEvolutionStars()),
          // `.sparks { top: 92px; left: 50%; translateX(-50%) }`.
          const Positioned(
            top: EvolutionSparksGeometry.topFromScreen,
            left: 0,
            right: 0,
            child: Center(child: PipEvolutionSparks()),
          ),
          Positioned.fill(
            child: Column(
              children: <Widget>[
                const NestStatusBar(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    NestSpacing.padSide,
                    0,
                    NestSpacing.padSide,
                    _kTopRowBottomPadding,
                  ),
                  child: Row(
                    children: <Widget>[Spacer(), _EvolutionLockButton()],
                  ),
                ),
                Expanded(child: body),
                bar,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading: centred spinner on the glow, same chrome as the loaded screen.
class _EvolutionLoading extends StatelessWidget {
  const _EvolutionLoading();

  @override
  Widget build(BuildContext context) {
    return _EvolutionShell(
      bar: const _EvolutionBar(),
      body: Center(
        child: Semantics(
          // ASCII apostrophe, like the rest of this screen's copy (see
          // `pip_evolution_copy.dart`'s header) and the app-wide kid cards.
          label: "Loading Pip's big moment",
          child: CircularProgressIndicator(color: context.nest.leaf),
        ),
      ),
    );
  }
}

/// Failure: kind copy plus a real retry (K03's failure card pattern).
class _EvolutionFailure extends StatelessWidget {
  const _EvolutionFailure({required this.profile});

  /// The last-known child, when the failure arrived mid-session.
  final PipProfile? profile;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return _EvolutionShell(
      bar: const _EvolutionBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: NestSpacing.s2,
            children: <Widget>[
              // No child known -> the neutral look (orchestrator rule for
              // screens with no child yet); otherwise the last-known Pip.
              PipAvatar(
                style: profile == null
                    ? PipStyle.mochi
                    : pipStyleOf(profile!.style),
                skin: profile == null
                    ? PipSkin.sunny
                    : pipSkinOf(profile!.skin),
                accessory: profile == null
                    ? PipAccessory.none
                    : pipAccessoryOf(profile!.accessory),
                stage: (profile?.stage ?? 1).clamp(1, _kStatsStageCount),
                size: 140,
              ),
              Text(
                'Oh no! Pip got lost.',
                style: NestType.h2(color: tokens.ink),
                textAlign: TextAlign.center,
              ),
              Text(
                // ASCII apostrophe, as in K03's failure card.
                "Let's try again.",
                style: NestType.bodySmall(color: tokens.ink2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: NestSpacing.s1),
              NestKidButton(
                key: const Key('k07-retry'),
                label: 'Try again',
                color: NestKidButtonColor.white,
                fullWidth: false,
                onPressed: () =>
                    context.read<PipBloc>().add(const PipLoadRequested()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// No active child: the picker hand-off (K03's "Who's playing?" card).
class _EvolutionNoChild extends StatelessWidget {
  const _EvolutionNoChild();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return _EvolutionShell(
      bar: const _EvolutionBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: NestSpacing.s3,
          children: <Widget>[
            Text(
              "Who's playing?",
              style: NestType.h2(color: tokens.ink),
              textAlign: TextAlign.center,
            ),
            NestKidButton(
              key: const Key('k07-choose'),
              label: 'Choose',
              color: NestKidButtonColor.lilac,
              fullWidth: false,
              onPressed: () => context.go(KidHomeRoutePaths.picker),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.k7-top`'s lock: `.lock-btn.lg` with the one-gate-per-gesture tap guard.
class _EvolutionLockButton extends StatefulWidget {
  const _EvolutionLockButton();

  @override
  State<_EvolutionLockButton> createState() => _EvolutionLockButtonState();
}

class _EvolutionLockButtonState extends State<_EvolutionLockButton> {
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
    // The design's `aria-label` is `Grown-ups`, not the widget default.
    return NestLockButton(
      key: const Key('k07-lock'),
      semanticLabel: 'Grown-ups',
      onPressed: _open,
    );
  }
}

/// The loaded screen: `.scroll` over the glow, plus the `.kid-bar` CTA.
class _EvolutionBody extends StatelessWidget {
  const _EvolutionBody({required this.evolution});

  final PipEvolution evolution;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final profile = evolution.profile;
    final stage = profile.stage.clamp(1, _kStatsStageCount);

    return _EvolutionShell(
      bar: _EvolutionBar(stage: stage),
      body: SingleChildScrollView(
        key: const Key('k07-scroll'),
        padding: const EdgeInsets.fromLTRB(
          NestSpacing.padSide,
          0,
          NestSpacing.padSide,
          _kScrollBottomPadding,
        ),
        child: Column(
          spacing: _kScrollGap,
          children: <Widget>[
            PipEvolutionStage(
              key: const Key('k07-stage-slot'),
              profile: profile,
            ),
            // `.kid-title` sets `text-wrap: balance`, so the hero heading uses
            // NestBalancedText: same copy, style and line breaking as the
            // design, instead of a one-word orphan line. Deliberately NO
            // `maxLines`: `.k7-hero` adds only `overflow-wrap: anywhere` and
            // `text-align: center`, so in the browser the heading simply grows,
            // and `NestBalancedText`'s default overflow is `TextOverflow.clip`
            // — a cap would cut a 5th line MID-GLYPH at accessibility text
            // scales (iOS reaches 3.16x) with nothing to show for it
            // (6_bugs.md K07-BUG-7; `1_plan.md` §(a).3's maxLines 4 was a
            // planned value that the design does not actually specify).
            NestBalancedText(
              evolutionTitle(stage),
              key: const Key('k07-title'),
              style: NestType.kidTitle(color: tokens.ink),
            ),
            // `.k7-sub` is `.kid-body` with `text-align: center` and no clamp
            // either; this line carries the quest count, so an ellipsis here
            // would swallow the number that explains why Pip grew.
            Text(
              evolutionSub(evolution.questsDone),
              key: const Key('k07-sub'),
              style: NestType.kidBody(color: tokens.ink),
              textAlign: TextAlign.center,
            ),
            // `.k7-cheer { display:flex; justify-content:center }`; the shared
            // bubble already caps itself at 260 wide and owns padding, border,
            // radius and the 9 px tail.
            Center(
              child: NestSpeechBubble(
                key: const Key('k07-speech'),
                text: evolutionSpeech(stage),
              ),
            ),
            PipEvolutionStats(
              // The card counts DISTINCT quests — a re-completable daily or
              // weekly quest is one quest, however many times it was finished
              // (`6_bugs.md` K07-BUG-3) — while the sub-line above keeps the
              // honest per-completion row count it says "times" about.
              questsDone: evolution.questsFinishedCount,
              coinsGrown: profile.totalCoins,
              stage: stage,
            ),
            Text(
              evolutionCaption(),
              key: const Key('k07-caption'),
              style: NestType.kidCaption(color: tokens.ink2),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// `.kid-bar` + `.home-indicator`.
///
/// Owner bottom-edge rule: the bar's own surface runs to the physical screen
/// edge — the `SafeArea` inset sits INSIDE the surface box (the K03 dock's
/// pattern), so no glow strip ever shows under the bar or around the home
/// indicator, in either theme. The OS draws the home pill.
class _EvolutionBar extends StatelessWidget {
  const _EvolutionBar({this.stage});

  /// The grown stage, for the CTA label. Null on the loading / failure /
  /// no-child cards, which have no celebration button.
  final int? stage;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Container(
      key: const Key('k07-bar'),
      decoration: BoxDecoration(
        color: tokens.surface,
        // `.kid-bar { border-top: 3px solid var(--ink) }` belongs to the
        // celebration bar. On the loading / failure / no-child cards there is no
        // button under it, and a full-width 3 px rule with nothing on it reads
        // as a broken button row, so those states get the plain surface band —
        // the box stays (the bottom-edge rule needs the surface to the physical
        // edge). `4_review.md` finding 5.
        border: stage == null
            ? null
            : Border(
                top: BorderSide(
                  color: tokens.ink,
                  width: context.nestKid.borderWidth,
                ),
              ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NestSpacing.padSide,
                _kBarTopPadding,
                NestSpacing.padSide,
                _kBarBottomPadding,
              ),
              child: stage == null
                  ? const SizedBox(width: double.infinity)
                  : NestKidButton(
                      key: const Key('k07-cta'),
                      label: evolutionCta(stage!),
                      color: NestKidButtonColor.lilac,
                      onPressed: () => context.go(PipRoutePaths.nest),
                    ),
            ),
            const NestHomeIndicator(),
          ],
        ),
      ),
    );
  }
}
