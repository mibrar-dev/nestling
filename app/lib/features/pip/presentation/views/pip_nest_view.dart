// K06 · Pip's nest (`/pip`).
//
// Layout transcribes `design/html-source/screens/K06-pip.html` row for row:
//   NestStatusBar (47, reserve only)
//   .k6-top        56 px back (transparent, r 18) + 56 px lock, padding 0 20 4
//   .scroll        padding 0 20, bottom home-h(34)+s6(24)=58, `.scroll > * + *`
//                  = s4 (16) — except `.k6-pet`, whose own `margin: 9px auto 0`
//                  wins, so the pet slot sits 9 px under the title
//   .k6-name       "Pip · Fledgling" (kid-title, `text-wrap: balance`)
//   .k6-pet        230 x 206 slot  (see core/design_system NestPetStage)
//   .k6-grow       growth card, 3 px ink border, lilac tint, sh-kid
//   .k6-care       Feed 5 / Play Free / Bath 3
//   .k6-sec        "Pip's wardrobe"
//   .k6-ward       4 tiles, 12 px gap
//   caption        "Nothing here is a chore — it is all just for fun."
//
// There is NO bottom bar: the kid meadow runs to the physical screen edge
// (owner bottom-edge rule) and the OS draws the home indicator.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// `PipStage` is hidden here so the pip feature's own wardrobe entity
// (the same name as the v1 artboard enum) is unambiguous.
import 'package:nestling/core/design_system/design_system.dart' hide PipStage;
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';
import 'package:nestling/features/pip/domain/entities/pip_nest.dart';
import 'package:nestling/features/pip/domain/entities/pip_stage.dart'
    show PipStage;
import 'package:nestling/features/pip/domain/pip_repository.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_bloc.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_event.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_state.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_coin_amount.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_free_pill.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_growth_card.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_look.dart';
import 'package:nestling/features/pip/presentation/widgets/pip_wardrobe_tile.dart';

/// `.k6-top { padding: 0 20px 4px }`.
const double _kTopRowBottomPadding = NestSpacing.s1;

/// `.k6-pet { margin: 9px auto 0 }` — the design overrides `.scroll > * + *`
/// (16) for the pet slot only.
const double _kPetTopMargin = NestSpacing.gap9;

/// `.k6-scroll { padding-bottom: calc(var(--home-h) + var(--s6)) }`
/// (SPACING_SPEC §1: K06/K08 use 58).
const double _kScrollBottomPadding = NestDevice.homeH + NestSpacing.s6;

class PipNestView extends StatelessWidget {
  const PipNestView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<PipBloc, PipState>(
      listenWhen: (previous, current) =>
          previous.actionNonce != current.actionNonce &&
          current.actionError != null,
      listener: (context, state) {
        final error = state.actionError;
        if (error == null) return;
        // An unaffordable buy says so kindly and specifically (1_plan.md §1f);
        // any other failed write falls back to the shared K03 phrasing.
        showNestToast(
          context,
          error == kPipNotEnoughCoins
              ? kPipNotEnoughCoins
              : 'Hmm, that did not work. Try again.',
        );
      },
      child: BlocBuilder<PipBloc, PipState>(
        builder: (context, state) {
          switch (state.status) {
            case PipStatus.initial:
            case PipStatus.loading:
              return const _PipLoading();
            case PipStatus.failure:
              return const _PipFailure();
            case PipStatus.loaded:
              final nest = state.nest;
              if (nest != null) return _PipNestBody(nest: nest);
              // K07 shares this bloc, so `loaded` can also arrive from the
              // OTHER stream: an evolution emission with no nest means the nest
              // stream is the one that failed while a child is known. Asking
              // "Who's playing?" there would send a real child to the picker,
              // so the failure card (with its retry) stands in.
              if (state.evolution != null) return const _PipFailure();
              return const _NoActiveChild();
          }
        },
      ),
    );
  }
}

/// Screen chrome shared by the loading, failure and no-child states: the same
/// status-bar reserve and back / parental-gate pair as the loaded screen.
class _PipChrome extends StatelessWidget {
  const _PipChrome({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                NestSpacing.padSide,
                0,
                NestSpacing.padSide,
                _kTopRowBottomPadding,
              ),
              child: _PipTopRow(),
            ),
            Expanded(child: child),
            const NestHomeIndicator(),
          ],
        ),
      ),
    );
  }
}

class _PipLoading extends StatelessWidget {
  const _PipLoading();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return _PipChrome(
      child: Center(
        child: Semantics(
          label: 'Loading Pip',
          child: CircularProgressIndicator(color: tokens.leaf),
        ),
      ),
    );
  }
}

class _PipFailure extends StatelessWidget {
  const _PipFailure();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return _PipChrome(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: NestSpacing.s2,
            children: [
              // No child is known on this path, so the neutral look (the
              // orchestrator's rule for screens with no child yet).
              const PipAvatar(style: PipStyle.mochi, stage: 1, size: 140),
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

class _NoActiveChild extends StatelessWidget {
  const _NoActiveChild();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return _PipChrome(
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
    );
  }
}

/// `.k6-top`: transparent `.nav-back.lg` on the left, `.lock-btn.lg`
/// (parental gate) on the right, 20 px gutters and 4 px of air below.
class _PipTopRow extends StatelessWidget {
  const _PipTopRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        NestIconButton(
          key: const Key('k06-back'),
          icon: NestIcons.back,
          semanticLabel: 'Back',
          size: NestDevice.tapKid,
          iconSize: 26,
          backgroundColor: Colors.transparent,
          borderColor: Colors.transparent,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(KidHomeRoutePaths.home);
            }
          },
        ),
        const _GateLockButton(key: Key('k06-lock')),
      ],
    );
  }
}

/// `.lock-btn.lg` with the K03 one-gate-per-gesture tap guard.
class _GateLockButton extends StatefulWidget {
  const _GateLockButton({super.key});

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

class _PipNestBody extends StatelessWidget {
  const _PipNestBody({required this.nest});

  final PipNest nest;

  @override
  Widget build(BuildContext context) {
    final profile = nest.profile;
    final stage = profile.stage.clamp(1, 4);
    final pipLook = _PipLook(
      style: pipStyleOf(profile.style),
      skin: pipSkinOf(profile.skin),
      accessory: pipAccessoryOf(profile.accessory),
    );

    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                NestSpacing.padSide,
                0,
                NestSpacing.padSide,
                _kTopRowBottomPadding,
              ),
              child: _PipTopRow(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  NestSpacing.padSide,
                  0,
                  NestSpacing.padSide,
                  _kScrollBottomPadding,
                ),
                children: [
                  // `.k6-name` is `.kid-title`, which sets
                  // `text-wrap: balance` — NestBalancedText keeps the same
                  // copy, style and maxLines with the design's break.
                  NestBalancedText(
                    'Pip · ${pipStageName(stage)}',
                    key: const Key('k06-title'),
                    style: NestType.kidTitle(color: context.nest.ink),
                    maxLines: 2,
                  ),
                  const SizedBox(height: _kPetTopMargin),
                  Center(
                    child: SizedBox(
                      width: 230,
                      height: 206,
                      child: NestPetStage(
                        key: const Key('k06-pet'),
                        pip: PipAvatar(
                          style: pipLook.style,
                          skin: pipLook.skin,
                          accessory: pipLook.accessory,
                          stage: stage,
                        ),
                        nestWidth: 230,
                        nestHeight: 206,
                        fixedPipHeight: 134,
                        slotHeight: 206,
                        pipBottom: 81,
                        nestFit: BoxFit.contain,
                        showGlow: false,
                        showGroundShadow: false,
                        semanticLabel:
                            'Pip the ${pipStageName(stage)}, stage $stage of 4',
                      ),
                    ),
                  ),
                  const SizedBox(height: NestSpacing.s4),
                  PipGrowthCard(
                    key: const Key('k06-grow'),
                    nest: nest,
                    // `.k6-grow-top img`: the same child, one stage on, at
                    // the design's 30 px slot.
                    nextStageAvatar: PipAvatar(
                      style: pipLook.style,
                      skin: pipLook.skin,
                      accessory: pipLook.accessory,
                      stage: stage + 1 > 4 ? 4 : stage + 1,
                      size: kPipGrowthAvatarSize,
                    ),
                  ),
                  const SizedBox(height: NestSpacing.s4),
                  _CareRow(nest: nest),
                  if (nest.items.isNotEmpty) ...[
                    // Each shared NestKidButton carries an internal
                    // `Padding(bottom: gap6)` (required for its pressed /
                    // shadowed paint), so the row's painted box is 91 px
                    // followed by 6 translucent px. Absorbing that 6 here
                    // keeps the visual pitch after the row exactly s4 (16),
                    // matching the design's 91 row height.
                    const SizedBox(height: NestSpacing.s4 - NestSpacing.gap6),
                    Text(
                      // HTML line 71: `<div class="k6-sec">Pip's wardrobe
                      // </div>` — a LITERAL ASCII apostrophe (0x27), verified
                      // with `hexdump` (50 69 70 27 73). Not `&rsquo;`: the
                      // orchestrator COPY rule makes the source byte the
                      // oracle (K06-BUG-3, K01's BUG-A precedent).
                      "Pip's wardrobe",
                      key: const Key('k06-section'),
                      // `.k6-sec`: Nunito 900 20 px on a 26 px line. The
                      // closest shared scale is `kidName` (22/26), so the
                      // size/line pair is set here at the call site.
                      style: NestType.kidName(color: context.nest.ink)
                          .copyWith(fontSize: 20, height: 26 / 20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: NestSpacing.s4),
                    PipWardrobeStrip(
                      items: nest.items,
                      onTap: (item, {required owned}) =>
                          _onWardrobeTap(context, item, owned: owned),
                    ),
                  ],
                  const SizedBox(height: NestSpacing.s4),
                  Text(
                    // HTML: `Nothing here is a chore &mdash; it is all just
                    // for fun.` (em dash U+2014).
                    'Nothing here is a chore — it is all just for fun.',
                    key: const Key('k06-caption'),
                    style: NestType.kidCaption(color: context.nest.ink2),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const NestHomeIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Copy for the two wardrobe items that have no Pip accessory node.
///
/// PLAN-vs-DESIGN NOTE: `1_plan.md` §1f says an owned Wellies/Crown tap
/// should "toast only, no DB write" (the logic builder's CONTRACT CHANGES
/// offer the same, and deliberately emit nothing so the view owns it), but the
/// K06 design defines NO copy for this case and the orchestrator's COPY rule
/// requires the design's characters exactly. This string is the ONE piece of
/// copy on the screen that is not in the design — factual, kind and
/// shame-free — and is flagged here for the orchestrator to ratify or
/// replace.
const String kPipNotWearable = 'That one is not something Pip can wear.';

/// Which wardrobe ids have a Pip accessory node to equip (see the bloc:
/// `scarf` -> scarf, `sunhat` -> cap; the rest are a silent no-op).
bool _isEquippable(String item) => item == 'scarf' || item == 'sunhat';

void _onWardrobeTap(
  BuildContext context,
  PipStage item, {
  required bool owned,
}) {
  if (!owned) {
    context.read<PipBloc>().add(PipWardrobeBuyRequested(item.id));
    return;
  }
  if (_isEquippable(item.id)) {
    context.read<PipBloc>().add(PipWardrobeEquipRequested(item.id));
    return;
  }
  // Owned but not wearable: say so instead of a dead tap.
  showNestToast(context, kPipNotWearable);
}

/// The child's Pip look, resolved once for the whole screen.
class _PipLook {
  const _PipLook({
    required this.style,
    required this.skin,
    required this.accessory,
  });

  final PipStyle style;
  final PipSkin skin;
  final PipAccessory accessory;
}

/// `.k6-care`: three `.btn-kid` columns, 12 px apart. Feed and Bath are
/// disabled (no coins -> no write); Play is always free.
class _CareRow extends StatelessWidget {
  const _CareRow({required this.nest});

  final PipNest nest;

  @override
  Widget build(BuildContext context) {
    final coins = nest.profile.coins;
    // The care costs come from the abstract repository, so the prices the
    // buttons draw are the numbers the write charges (4_review.md #3) — the
    // view no longer names the Drift impl.
    final canFeed = coins >= PipRepository.feedCostCoins;
    final canBathe = coins >= PipRepository.bathCostCoins;

    // `.k6-care` is a flex row, so `align-items: stretch` gives all three
    // `.btn-kid` columns ONE height — the tallest. A plain `Row` inside the
    // unbounded `ListView` cannot stretch, so at text scale 1.3 Play's 19 px
    // `.k6-free` pill grew to 101 px while Feed and Bath stayed at 96
    // (K06-BUG-5). `IntrinsicHeight` supplies the row's tight height;
    // `stretch` then hands
    // it to every column. At the design's scale 1.0 nothing changes: the
    // tallest intrinsic height is Play's 91 px, which is exactly the design.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: NestSpacing.s3,
        children: [
          Expanded(
            child: NestKidButton(
              key: const Key('k06-feed'),
              label: 'Feed',
              color: NestKidButtonColor.peach,
              semanticLabel:
                  'Feed Pip, costs ${PipRepository.feedCostCoins} coins',
              icon: NestIcon(NestIcons.kidFeed, color: context.nest.onWarm),
              axis: Axis.vertical,
              gap: NestSpacing.gap3,
              minHeight: 88,
              fontSize: 17,
              wrapLabel: false,
              contentPadding: const EdgeInsets.symmetric(
                vertical: NestSpacing.s2,
                horizontal: NestSpacing.s1,
              ),
              trailing: PipCoinAmount(
                amount: '${PipRepository.feedCostCoins}',
                color: context.nest.onWarm,
              ),
              onPressed: canFeed
                  ? () => context.read<PipBloc>().add(
                      const PipCareRequested(PipCareKind.feed),
                    )
                  : null,
            ),
          ),
          Expanded(
            child: NestKidButton(
              key: const Key('k06-play'),
              label: 'Play',
              color: NestKidButtonColor.sky,
              semanticLabel: 'Play with Pip, free',
              icon: NestIcon(NestIcons.kidPlay, color: context.nest.onAccent),
              axis: Axis.vertical,
              gap: NestSpacing.gap3,
              minHeight: 88,
              fontSize: 17,
              wrapLabel: false,
              contentPadding: const EdgeInsets.symmetric(
                vertical: NestSpacing.s2,
                horizontal: NestSpacing.s1,
              ),
              trailing: const PipFreePill(),
              onPressed: () => context.read<PipBloc>().add(
                const PipCareRequested(PipCareKind.play),
              ),
            ),
          ),
          Expanded(
            child: NestKidButton(
              key: const Key('k06-bath'),
              label: 'Bath',
              color: NestKidButtonColor.white,
              semanticLabel:
                  'Bathe Pip, costs ${PipRepository.bathCostCoins} coins',
              icon: NestIcon(NestIcons.bubbles, color: context.nest.ink),
              axis: Axis.vertical,
              gap: NestSpacing.gap3,
              minHeight: 88,
              fontSize: 17,
              wrapLabel: false,
              contentPadding: const EdgeInsets.symmetric(
                vertical: NestSpacing.s2,
                horizontal: NestSpacing.s1,
              ),
              trailing: PipCoinAmount(
                amount: '${PipRepository.bathCostCoins}',
                color: context.nest.ink,
              ),
              onPressed: canBathe
                  ? () => context.read<PipBloc>().add(
                      const PipCareRequested(PipCareKind.bathe),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
