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
        switch (state.status) {
          case PipStatus.initial:
          case PipStatus.loading:
            return const _EvolutionLoading();
          case PipStatus.failure:
            // Keep the last-known child on the failure card when there is one
            // (mid-session error must not blank the screen).
            return _EvolutionFailure(
              profile: state.evolution?.profile ?? state.nest?.profile,
            );
          case PipStatus.loaded:
            final evolution = state.evolution;
            if (evolution != null) return _EvolutionBody(evolution: evolution);
            // The nest stream (K06) shares this bloc, so `loaded` can arrive
            // from it while THIS screen's stream failed. A child is known then,
            // and "Who's playing?" would send a real child to the picker — the
            // failure card (with the nest's last-known Pip + its retry) stands
            // in instead, exactly as on the `failure` path above.
            final nest = state.nest;
            if (nest != null) return _EvolutionFailure(profile: nest.profile);
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
          label: 'Loading Pip’s big moment',
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
            // NestBalancedText: same copy, style and maxLines, with the
            // design's break instead of a one-word orphan line.
            NestBalancedText(
              evolutionTitle(stage),
              key: const Key('k07-title'),
              style: NestType.kidTitle(color: tokens.ink),
              maxLines: 4,
            ),
            Text(
              evolutionSub(evolution.questsDone),
              key: const Key('k07-sub'),
              style: NestType.kidBody(color: tokens.ink),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
              questsDone: evolution.questsDone,
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
        border: Border(
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
