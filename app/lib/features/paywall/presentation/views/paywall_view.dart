import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_bloc.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_event.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_state.dart';
import 'package:nestling/features/pocket_money/pocket_money_routes.dart';
import 'package:nestling/features/today/today_routes.dart';

/// P07 Paywall — parent-mode trial screen at `/paywall`, the last step of
/// the P01→P07 onboarding flow.
///
/// Static spec copy (`1_plan.md` §d) renders regardless of the bloc's `items`
/// — an empty plan list is never an empty state and the trial CTA is never
/// blocked by it. The bloc drives only loading / failure / action states.
class PaywallView extends StatelessWidget {
  const PaywallView({super.key});

  void _onBack(BuildContext context) {
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(PocketMoneyRoutePaths.setup);
    }
  }

  /// ORCHESTRATOR_NOTES 1 (mandatory): the trial handoff writes through the
  /// session before navigating, so a restart lands on Today, not `/welcome`
  /// (P01 BUG-4). `AppSession` lives in GetIt, not in the widget tree
  /// (`app.dart` provides only the two controllers), so it is read from
  /// GetIt — `context.read<AppSession>()` would throw.
  Future<void> _onActionSuccess(
    BuildContext context,
    PaywallRequest request,
  ) async {
    final session = GetIt.instance<AppSession>();
    if (request == PaywallRequest.restore) {
      // A restoring user already paid: `active`, never downgraded to trial.
      await session.setSubscription('active');
    } else {
      await session.startTrialNow();
    }
    await session.completeOnboarding();
    if (!context.mounted) return;
    context.go(TodayRoutePaths.today);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PaywallBloc, PaywallState>(
      listenWhen: (previous, current) => previous.action != current.action,
      listener: (context, state) {
        switch (state.action) {
          case PaywallAction.idle:
          case PaywallAction.working:
            break;
          case PaywallAction.success:
            unawaited(_onActionSuccess(context, state.request));
          case PaywallAction.failure:
            showNestToast(
              context,
              state.errorMessage ?? 'Something went wrong',
            );
        }
      },
      child: Scaffold(
        backgroundColor: context.nest.paper,
        body: Column(
          children: <Widget>[
            const NestStatusBar(),
            _PaywallNav(onBack: () => _onBack(context)),
            const Expanded(child: _PaywallScroll()),
            const _PaywallCta(),
          ],
        ),
      ),
    );
  }
}

/// Compact nav (`.nav-bar.compact` + `.nav-back.close`): 44×44 close button
/// on a surface-2 radius-12 tile, an expanded fill and a 44-wide balance
/// spacer. `NestNavBar`'s back slot is transparent, so the tile is local.
class _PaywallNav extends StatelessWidget {
  const _PaywallNav({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Semantics(
      label: 'Subscription',
      header: true,
      container: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            NestSpacing.s3,
            NestSpacing.s1,
            NestSpacing.s3,
            NestSpacing.s3,
          ),
          child: Row(
            children: <Widget>[
              Semantics(
                button: true,
                label: 'Close and go back',
                onTap: onBack,
                child: Material(
                  color: tokens.surface2,
                  borderRadius: BorderRadius.circular(NestSpacing.s3),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(NestSpacing.s3),
                    onTap: onBack,
                    child: SizedBox(
                      width: NestDevice.tapParent,
                      height: NestDevice.tapParent,
                      child: Center(
                        child: NestIcon(NestIcons.close, color: tokens.ink),
                      ),
                    ),
                  ),
                ),
              ),
              const Expanded(child: SizedBox.shrink()),
              const SizedBox(width: NestDevice.tapParent),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scroll body: progress while loading, a retry error on failure, the static
/// spec column once loaded (even with zero plans — `1_plan.md` §d).
class _PaywallScroll extends StatelessWidget {
  const _PaywallScroll();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaywallBloc, PaywallState>(
      builder: (context, state) {
        switch (state.status) {
          case PaywallStatus.initial:
          case PaywallStatus.loading:
            return Center(
              child: CircularProgressIndicator(color: context.nest.leaf),
            );
          case PaywallStatus.failure:
            return const _PaywallLoadError();
          case PaywallStatus.loaded:
            return const _PaywallBody();
        }
      },
    );
  }
}

class _PaywallLoadError extends StatelessWidget {
  const _PaywallLoadError();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: NestSpacing.s3,
          children: <Widget>[
            NestIcon(NestIcons.shieldCheck, color: tokens.ink3),
            Text(
              // Static design copy (`1_plan.md` §d); the technical message
              // stays in `state.errorMessage` for action-failure toasts.
              'Something went wrong',
              style: NestType.body(color: tokens.ink2),
              textAlign: TextAlign.center,
            ),
            NestButton(
              label: 'Retry',
              variant: NestButtonVariant.secondary,
              onPressed: () =>
                  context.read<PaywallBloc>().add(const PaywallLoadRequested()),
            ),
          ],
        ),
      ),
    );
  }
}

/// The scroll column in document order with the design's exact gaps.
class _PaywallBody extends StatelessWidget {
  const _PaywallBody();

  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView + Column, not a ListView: the sliver delegate
    // wraps every child in an `IndexedSemantics` that steals descendant
    // semantics labels in widget tests (`bySemanticsLabel(pip)` resolved to
    // the 350px-wide hero slot instead of the 120px Pip), and it builds
    // lazily, so below-the-fold copy is not findable without scrolling.
    // This screen is short static content (P01/P02 precedent): everything
    // lays out eagerly and every label stays on its own node.
    return const SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        0,
        NestSpacing.padSide,
        NestSpacing.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: NestSpacing.s1),
            child: _PaywallHero(),
          ),
          SizedBox(height: 26),
          _PaywallTitle(),
          SizedBox(height: 18),
          _BenefitList(),
          SizedBox(height: NestSpacing.s6),
          _PlanCard(),
          SizedBox(height: 48),
          _TimelineCard(),
          SizedBox(height: NestSpacing.padSide),
          _FamilyNote(),
        ],
      ),
    );
  }
}

/// 350×148 hero (HTML `.pay-hero`): lilac-tint circle, twig nest, Pip
/// (Mochi/sunny/stage 4 per the P01–P07 orchestrator rule, in the nest) and
/// three coins. Scales down (never up) below 390dp — the same LayoutBuilder
/// pattern as P01's scene.
class _PaywallHero extends StatelessWidget {
  const _PaywallHero();

  static const double _frameW = 350;
  static const double _frameH = 148;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = (constraints.maxWidth / _frameW).clamp(0.0, 1.0);
        return SizedBox(
          width: _frameW * scale,
          height: _frameH * scale,
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.topLeft,
            child: OverflowBox(
              minWidth: _frameW,
              maxWidth: _frameW,
              minHeight: _frameH,
              maxHeight: _frameH,
              alignment: Alignment.topLeft,
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  Positioned(
                    left: 90,
                    top: -5,
                    width: 170,
                    height: 170,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tokens.lilacTint,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 100,
                    top: 41,
                    width: 150,
                    height: 150,
                    child: ExcludeSemantics(
                      child: SvgPicture.asset(
                        NestlingIllustrations.nest,
                        width: 150,
                        height: 150,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 115,
                    top: 20,
                    width: 120,
                    height: 120,
                    child: Semantics(
                      label: 'Pip the songbird, fully grown, sitting in a twig nest',
                      image: true,
                      child: const PipAvatar(
                        style: PipStyle.mochi,
                        stage: 4,
                        inNest: true,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    top: 30,
                    width: 30,
                    height: 30,
                    child: Transform.rotate(
                      angle: -14 * math.pi / 180,
                      child: const _HeroCoin(size: 30),
                    ),
                  ),
                  // Right 6 → left 350 − 6 − 26 = 318.
                  Positioned(
                    left: 318,
                    top: 70,
                    width: 26,
                    height: 26,
                    child: Transform.rotate(
                      angle: 12 * math.pi / 180,
                      child: const _HeroCoin(size: 26),
                    ),
                  ),
                  Positioned(
                    left: 30,
                    top: 128,
                    width: 24,
                    height: 24,
                    child: Transform.rotate(
                      angle: 20 * math.pi / 180,
                      child: const _HeroCoin(size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Decorative floating coin with the `--sh-1` card shadow.
class _HeroCoin extends StatelessWidget {
  const _HeroCoin({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: context.nest.cardShadow,
        ),
        child: SvgPicture.asset(
          NestlingIllustrations.coin,
          width: size,
          height: size,
        ),
      ),
    );
  }
}

class _PaywallTitle extends StatelessWidget {
  const _PaywallTitle();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        'Try Nestling free for 14 days',
        style: NestType.h1(color: context.nest.ink),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// The four `.benefit` rows: 24px leaf-tint tick + Inter 15/24 text.
/// (Closest token `bodySmall` is 15/22, so the 15/24 line box is explicit.)
class _BenefitList extends StatelessWidget {
  const _BenefitList();

  static const List<String> _benefits = <String>[
    'Unlimited children & quests',
    'Pip’s full evolution & seasonal outfits',
    'Pocket money ledger & payout day',
    'Co-parent sharing, so James sees the same',
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Column(
      spacing: NestSpacing.gap10,
      children: <Widget>[
        for (final benefit in _benefits)
          Semantics(
            label: benefit,
            container: true,
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: NestSpacing.gap10,
              children: <Widget>[
                Transform.translate(
                  offset: const Offset(0, -1),
                  child: ExcludeSemantics(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: tokens.leafTint,
                      ),
                      alignment: Alignment.center,
                      child: NestIcon(
                        NestIcons.check,
                        size: 16,
                        color: tokens.leafInk,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    benefit,
                    style: NestType.bodySmall(color: tokens.ink)
                        .copyWith(height: 24 / 15),
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// The single annual plan: standard `NestCard` geometry with a local 2px leaf
/// border, a selected radio and the title/sub/tag column. One plan means
/// pre-selected; tapping is a no-op with `selected: true` announced.
class _PlanCard extends StatelessWidget {
  const _PlanCard();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Semantics(
      label: 'Annual — £29.99/year, Just £2.50 a month, billed yearly',
      selected: true,
      excludeSemantics: true,
      child: NestCard(
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: tokens.leaf, width: 2),
            borderRadius: NestRadii.allL,
          ),
          padding: const EdgeInsets.all(NestSpacing.s4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: NestSpacing.s3,
            children: <Widget>[
              ExcludeSemantics(
                child: Padding(
                  padding: const EdgeInsets.only(top: NestSpacing.gap10),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: tokens.leaf,
                      border: Border.all(
                        color: tokens.leafTint,
                        width: NestSpacing.s1,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: NestSpacing.gap2,
                  children: <Widget>[
                    Text(
                      'Annual — £29.99/year',
                      style: NestType.h3(color: tokens.ink),
                    ),
                    Text(
                      'Just £2.50 a month, billed yearly',
                      style: NestType.bodySmall(color: tokens.ink2)
                          .copyWith(height: 20 / 15),
                      softWrap: true,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: NestSpacing.s1),
                      child: Text(
                        'One price, the whole family',
                        style: NestType.fieldLabel(color: tokens.leafInk),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The `What happens next` card: three steps with 24px dots and 2px
/// connectors.
class _TimelineCard extends StatelessWidget {
  const _TimelineCard();

  static const List<(String, String)> _steps = <(String, String)>[
    ('Today', 'Full access, straight away'),
    ('Day 12', 'We’ll remind you by email'),
    ('Day 14', '£29.99 billed — cancel any time'),
  ];

  @override
  Widget build(BuildContext context) {
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'What happens next',
            style: NestType.h3(color: context.nest.ink),
          ),
          const SizedBox(height: NestSpacing.s3),
          for (var i = 0; i < _steps.length; i++)
            _TimelineItem(
              title: _steps[i].$1,
              sub: _steps[i].$2,
              isLast: i == _steps.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.title,
    required this.sub,
    required this.isLast,
  });

  final String title;
  final String sub;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    // NOTE (P07-BUG probe): `1_plan.md` §e asked for ordered semantics via
    // `Semantics(indexInParent:)` here, but that property does not exist and
    // its `IndexedSemantics` replacement hijacks the hero Pip's semantics
    // label in widget tests (`bySemanticsLabel(pip)` resolves to the timeline
    // element). The timeline order is covered by document-order layout
    // instead, so no semantics wrapper is used here at all.
    return Stack(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(left: 36, bottom: isLast ? 0 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: NestSpacing.gap2,
            children: <Widget>[
              Text(
                title,
                style: NestType.bodySmallStrong(color: tokens.ink)
                    .copyWith(height: 20 / 15, fontWeight: FontWeight.w700),
              ),
              Text(
                sub,
                style: NestType.bodySmall(color: tokens.ink2)
                    .copyWith(height: 20 / 15),
                softWrap: true,
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          top: 2,
          child: ExcludeSemantics(
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.leafTint,
                border: Border.all(color: tokens.leaf, width: 2),
              ),
            ),
          ),
        ),
        if (!isLast)
          Positioned(
            left: 11,
            top: 26,
            bottom: 0,
            width: 2,
            child: ExcludeSemantics(child: Container(color: tokens.line)),
          ),
      ],
    );
  }
}

class _FamilyNote extends StatelessWidget {
  const _FamilyNote();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: NestSpacing.s2,
      children: <Widget>[
        ExcludeSemantics(
          child: NestIcon(NestIcons.person, size: 20, color: tokens.ink2),
        ),
        Flexible(
          child: Text(
            'One subscription covers the whole family.',
            style: NestType.bodySmallStrong(color: tokens.ink2),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Bottom bar: CTA → caption → legal row, all inside `NestBottomCta` so the
/// surface runs to the physical edge (owner rule). `NestBottomCta` renders
/// its own `caption` last with no slot after it (P07-BUG-3), so the bar
/// content is composed locally with `caption: null` — same `DecoratedBox` +
/// `SafeArea` guarantee, `NestType.caption` for the caption text.
class _PaywallCta extends StatelessWidget {
  const _PaywallCta();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaywallBloc, PaywallState>(
      builder: (context, state) {
        final working = state.action == PaywallAction.working;
        return NestBottomCta(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: NestSpacing.s2,
            children: <Widget>[
              NestButton(
                key: const ValueKey('p07_start_trial'),
                label: 'Start free trial',
                loading: working && state.request == PaywallRequest.trial,
                onPressed: working
                    ? null
                    : () => context.read<PaywallBloc>().add(
                        const PaywallTrialStarted(),
                      ),
              ),
              Text(
                '£29.99/year after the 14-day trial. Cancel anytime in Settings.',
                style: NestType.caption(color: context.nest.ink2),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              _LegalRow(disabled: working),
            ],
          ),
        );
      },
    );
  }
}

class _LegalRow extends StatelessWidget {
  const _LegalRow({required this.disabled});

  final bool disabled;

  void _restore(BuildContext context) {
    if (disabled) return;
    context.read<PaywallBloc>().add(const PaywallRestoreRequested());
  }

  void _placeholder(BuildContext context, String message) {
    // TODO(P07): link to the real legal route when the orchestrator adds one.
    // No onboarding route exists for the legal pages, so the screen answers
    // in place and stays on `/paywall`.
    showNestToast(context, message);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: NestSpacing.gap2,
      runSpacing: NestSpacing.s2,
      children: <Widget>[
        _LegalLink(
          label: 'Restore purchases',
          onTap: disabled ? null : () => _restore(context),
        ),
        Text('·', style: NestType.caption(color: context.nest.ink3)),
        _LegalLink(
          label: 'Terms',
          onTap: () =>
              _placeholder(context, 'Terms are available in the full app.'),
        ),
        Text('·', style: NestType.caption(color: context.nest.ink3)),
        _LegalLink(
          label: 'Privacy',
          onTap: () => _placeholder(
            context,
            'The Privacy Notice is available in the full app.',
          ),
        ),
      ],
    );
  }
}

/// One sky underlined legal link: a single semantics node carrying the label,
/// the button flag and the tap action, on a 44×44 minimum target.
class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final tap = onTap;
    return Semantics(
      button: true,
      label: label,
      onTap: tap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: NestDevice.tapParent,
          minHeight: NestDevice.tapParent,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: tap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Center(
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    style: NestType.fieldLabel(color: tokens.sky)
                        .copyWith(decoration: TextDecoration.underline),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
