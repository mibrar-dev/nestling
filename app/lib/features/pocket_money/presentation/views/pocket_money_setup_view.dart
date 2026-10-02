import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/family/family_routes.dart';
import 'package:nestling/features/paywall/paywall_routes.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_bloc.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_event.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_state.dart';

/// P06 Pocket money setup — parent-mode onboarding step at
/// `/pocket-money-setup` (P05 → P06 → P07).
///
/// Write-through: every tap persists to Drift immediately and the
/// `watchSetup` stream re-emits. `Continue` is navigation-only.
class PocketMoneySetupView extends StatelessWidget {
  const PocketMoneySetupView({super.key});

  /// Stepper granularity (±£0.50 — the design is silent, 50p reproduces the
  /// £3.00/£1.50 seeds and matches UK coin granularity).
  static const int stepPence = 50;

  static const List<String> dayLabels = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Scaffold(
      backgroundColor: tokens.paper,
      body: Column(
        children: <Widget>[
          const NestStatusBar(),
          NestNavBar(
            compact: true,
            onBack: () => context.go(FamilyRoutePaths.addChildren),
          ),
          Expanded(
            child: BlocBuilder<PocketMoneyBloc, PocketMoneyState>(
              builder: (context, state) {
                switch (state.status) {
                  case PocketMoneyStatus.initial:
                  case PocketMoneyStatus.loading:
                    final setup = state.setup;
                    if (setup == null) {
                      return const _SetupScroll(child: _LoadingBody());
                    }
                    return _SetupScroll(child: _LoadedBody(setup: setup));
                  case PocketMoneyStatus.failure:
                    return const _SetupScroll(child: _FailureBody());
                  case PocketMoneyStatus.loaded:
                    final setup = state.setup;
                    if (setup == null) {
                      return const _SetupScroll(child: _LoadingBody());
                    }
                    return _SetupScroll(child: _LoadedBody(setup: setup));
                }
              },
            ),
          ),
          NestBottomCta(
            dense: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Nestling never holds or moves money. '
                  'You pay your way; we keep score.',
                  style: NestType.caption(color: tokens.ink2),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: NestSpacing.s2),
                NestButton(
                  key: const ValueKey('p06_continue'),
                  label: 'Continue',
                  onPressed: () => context.go(PaywallRoutePaths.paywall),
                ),
              ],
            ),
          ),
          const NestHomeIndicator(),
        ],
      ),
    );
  }
}

/// Scroll container shared by every state (20px side gutters, 32px bottom).
class _SetupScroll extends StatelessWidget {
  const _SetupScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        0,
        NestSpacing.padSide,
        NestSpacing.s8,
      ),
      child: child,
    );
  }
}

/// Screen H1 (lives inside the scroll per the HTML, not the nav-bar slot).
class _SetupTitle extends StatelessWidget {
  const _SetupTitle();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        'How does pocket money work in your house?',
        style: context.nestText.h1,
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SetupTitle(),
        SizedBox(height: NestSpacing.s4),
        SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

class _FailureBody extends StatelessWidget {
  const _FailureBody();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PocketMoneyBloc>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SetupTitle(),
        const SizedBox(height: NestSpacing.s4),
        Center(
          child: Text(
            state.errorMessage ?? 'Something went wrong',
            style: NestType.body(color: context.nest.ink2),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: NestSpacing.s4),
        NestButton(
          key: const ValueKey('p06_retry'),
          label: 'Retry',
          variant: NestButtonVariant.secondary,
          onPressed: () => context.read<PocketMoneyBloc>().add(
            const PocketMoneyLoadRequested(),
          ),
        ),
      ],
    );
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.setup});

  final PocketMoneySetup setup;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _SetupTitle(),
        const SizedBox(height: NestSpacing.s4),
        _ModeOptions(mode: setup.mode),
        const SizedBox(height: NestSpacing.s4),
        _SettingsCard(setup: setup),
      ],
    );
  }
}

/// The three money-style option cards (radiogroup). Feature-private buttons
/// built from tokens only — 60px min height, 8/13 padding, 12 gap, r-m 16,
/// 2px line border, card shadow; selected = leaf border on leaf tint.
class _ModeOptions extends StatelessWidget {
  const _ModeOptions({required this.mode});

  final String mode;

  static const List<({String value, String title, String sub, String key})>
  _options = <({String value, String title, String sub, String key})>[
    (
      value: 'weekly',
      title: 'Weekly amount',
      sub: 'A set amount every week',
      key: 'p06_option_weekly',
    ),
    (
      value: 'per_quest',
      title: 'Earn per quest',
      sub: 'Coins turn into pence at payout',
      key: 'p06_option_per_quest',
    ),
    (
      value: 'both',
      title: 'Both',
      sub: 'Weekly base + bonus for extra quests',
      key: 'p06_option_both',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Pocket money style',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: NestSpacing.s2,
        children: <Widget>[
          for (final option in _options)
            _PocketOptionCard(
              cardKey: ValueKey<String>(option.key),
              title: option.title,
              sub: option.sub,
              selected: option.value == mode,
              onTap: () => context.read<PocketMoneyBloc>().add(
                PocketMoneyModeChanged(option.value),
              ),
            ),
        ],
      ),
    );
  }
}

class _PocketOptionCard extends StatelessWidget {
  const _PocketOptionCard({
    required this.cardKey,
    required this.title,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  final ValueKey<String> cardKey;
  final String title;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Semantics(
      key: cardKey,
      button: true,
      selected: selected,
      label: '$title, $sub',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: NestSpacing.s2,
              horizontal: 13,
            ),
            decoration: BoxDecoration(
              color: selected ? tokens.leafTint : tokens.surface,
              borderRadius: BorderRadius.circular(NestRadii.m),
              border: Border.all(
                color: selected ? tokens.leaf : tokens.line,
                width: 2,
              ),
              boxShadow: tokens.cardShadow,
            ),
            child: Row(
              children: <Widget>[
                ExcludeSemantics(child: _RadioDot(selected: selected)),
                const SizedBox(width: NestSpacing.s3),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: context.nestText.bodyStrong,
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        sub,
                        style: NestType.bodySmall(color: tokens.ink2),
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 22px radio: unselected = ink-3 ring on surface; selected = leaf ring on
/// leaf tint with a centred 10px leaf dot.
class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? tokens.leafTint : tokens.surface,
        border: Border.all(
          color: selected ? tokens.leaf : tokens.ink3,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.leaf,
              ),
            )
          : null,
    );
  }
}

/// Payout day + weekly base + coin value. A standard [NestCard] with zero
/// padding and manual inner insets so the dividers run full-bleed
/// (card CSS `padding: 16 16 12`, divider `margin: 8 -16`).
class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.setup});

  final PocketMoneySetup setup;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return NestCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NestSpacing.s4,
              NestSpacing.s4,
              NestSpacing.s4,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Payout day',
                  style: NestType.fieldLabel(color: tokens.ink2),
                ),
                const SizedBox(height: NestSpacing.gap6),
                _DayRow(payoutDay: setup.payoutDay),
              ],
            ),
          ),
          Container(
            height: 1,
            color: tokens.line,
            margin: const EdgeInsets.symmetric(vertical: NestSpacing.s2),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NestSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Weekly base',
                  style: NestType.fieldLabel(color: tokens.ink2),
                ),
                const SizedBox(height: NestSpacing.gap2),
                if (setup.children.isEmpty)
                  Text(
                    'Add children to set weekly amounts.',
                    style: NestType.caption(color: tokens.ink2),
                  )
                else
                  for (final child in setup.children)
                    _WeeklyBaseRow(child: child),
              ],
            ),
          ),
          Container(
            height: 1,
            color: tokens.line,
            margin: const EdgeInsets.symmetric(vertical: NestSpacing.s2),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              NestSpacing.s4,
              0,
              NestSpacing.s4,
              NestSpacing.s3,
            ),
            child: _CoinValueRow(
              coinValuePencePerCoin: setup.coinValuePencePerCoin,
            ),
          ),
        ],
      ),
    );
  }
}

/// 7 single-select day cells (Mon = 1 … Sun = 7). Each cell is an [Expanded]
/// 44-tall tap target; the pill itself is a static [NestChip] scaled down to
/// fit (see SHARED_REQUEST — the 14px chip + 28px padding cannot fit 7-across
/// at full size, so visuals shrink while the tap box stays 44 tall).
class _DayRow extends StatelessWidget {
  const _DayRow({required this.payoutDay});

  final int payoutDay;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Payout day',
      child: Row(
        spacing: NestSpacing.gap6,
        children: <Widget>[
          for (var i = 0; i < PocketMoneySetupView.dayLabels.length; i++)
            Expanded(
              child: _DayCell(
                cellKey: ValueKey<String>('p06_day_${i + 1}'),
                label: PocketMoneySetupView.dayLabels[i],
                selected: payoutDay == i + 1,
                onTap: () => context.read<PocketMoneyBloc>().add(
                  PocketMoneyPayoutDayChanged(i + 1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.cellKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final ValueKey<String> cellKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: cellKey,
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: NestDevice.tapParent,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: NestChip(label: label, selected: selected),
            ),
          ),
        ),
      ),
    );
  }
}

/// One per-child weekly-base row in insertion order: 32px avatar + name +
/// stepper. The stepper buttons carry the HTML aria-labels verbatim.
class _WeeklyBaseRow extends StatelessWidget {
  const _WeeklyBaseRow({required this.child});

  final PocketMoneySetupChild child;

  static NestAvatarColor _avatarColor(String avatarColour) {
    return switch (avatarColour) {
      'lilac' => NestAvatarColor.lilac,
      'peach' => NestAvatarColor.peach,
      'sky' => NestAvatarColor.sky,
      'leaf' => NestAvatarColor.leaf,
      'coin' => NestAvatarColor.coin,
      _ => NestAvatarColor.neutral,
    };
  }

  @override
  Widget build(BuildContext context) {
    final initial = child.nickname.isEmpty
        ? '?'
        : child.nickname.characters.first.toUpperCase();
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: NestDevice.tapParent),
      child: Row(
        key: ValueKey<String>('p06_base_row_${child.id}'),
        children: <Widget>[
          NestAvatar(
            initial: initial,
            size: NestAvatarSize.s32,
            color: _avatarColor(child.avatarColour),
          ),
          const SizedBox(width: NestSpacing.s3),
          Expanded(
            child: Text(
              child.nickname,
              style: context.nestText.bodyStrong,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          NestStepper(
            valueText: '£${(child.weeklyBasePence / 100).toStringAsFixed(2)}',
            onDecrease: () => context.read<PocketMoneyBloc>().add(
              PocketMoneyWeeklyBaseStepped(
                child.id,
                -PocketMoneySetupView.stepPence,
              ),
            ),
            onIncrease: () => context.read<PocketMoneyBloc>().add(
              PocketMoneyWeeklyBaseStepped(
                child.id,
                PocketMoneySetupView.stepPence,
              ),
            ),
            decreaseSemanticLabel:
                'Less weekly pocket money for ${child.nickname}',
            increaseSemanticLabel:
                'More weekly pocket money for ${child.nickname}',
          ),
        ],
      ),
    );
  }
}

/// Display-only coin-value row: 40px coin-tint tile + label + trailing value.
class _CoinValueRow extends StatelessWidget {
  const _CoinValueRow({required this.coinValuePencePerCoin});

  final int coinValuePencePerCoin;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: NestDevice.tapParent),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tokens.coinTint,
              borderRadius: BorderRadius.circular(NestRadii.m),
            ),
            alignment: Alignment.center,
            child: ExcludeSemantics(
              child: NestIcon(NestIcons.poundCoin, color: tokens.coinInk),
            ),
          ),
          const SizedBox(width: NestSpacing.s3),
          Expanded(
            child: Text(
              'Coin value',
              style: context.nestText.bodyStrong,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              '10 coins = ${10 * coinValuePencePerCoin}p',
              style: NestType.bodySmall(color: tokens.ink2),
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
