import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/family/family_routes.dart';
import 'package:nestling/features/paywall/paywall_routes.dart';
import 'package:nestling/features/pocket_money/domain/entities/pocket_money_setup.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_bloc.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_event.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_state.dart';
import 'package:nestling/features/pocket_money/presentation/widgets/p06_weekly_stepper.dart';

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
              buildWhen: (previous, state) =>
                  previous.setup != state.setup ||
                  previous.status != state.status ||
                  previous.errorMessage != state.errorMessage,
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
                    // A failed write keeps the loaded form visible with an
                    // inline error (P06-BUG-05); only a load failure (no
                    // usable setup at all) replaces the screen with _FailureBody.
                    final setup = state.setup;
                    if (setup == null) {
                      return _SetupScroll(
                        child: _FailureBody(errorMessage: state.errorMessage),
                      );
                    }
                    return _SetupScroll(
                      child: _LoadedBody(
                        setup: setup,
                        errorMessage: state.errorMessage,
                      ),
                    );
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
      child: NestBalancedText(
        'How does pocket money work in your house?',
        style: context.nestText.h1,
        textAlign: TextAlign.left,
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SetupTitle(),
        const SizedBox(height: NestSpacing.s4),
        SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(color: context.nest.leaf),
          ),
        ),
      ],
    );
  }
}

class _FailureBody extends StatelessWidget {
  const _FailureBody({required this.errorMessage});

  /// Passed down from the builder (review #5): a nested
  /// `context.watch<PocketMoneyBloc>()` here re-subscribed and rebuilt the
  /// failure screen on every state emission, including ledger-only ones the
  /// outer `buildWhen` deliberately filters out.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SetupTitle(),
        const SizedBox(height: NestSpacing.s4),
        Center(
          child: Text(
            errorMessage ?? 'Something went wrong',
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
  const _LoadedBody({required this.setup, this.errorMessage});

  final PocketMoneySetup setup;

  /// Non-null while the last write failed: the form stays put and the
  /// message rides along inline instead of blanking the screen.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _SetupTitle(),
        const SizedBox(height: NestSpacing.s4),
        if (errorMessage != null) ...<Widget>[
          Text(
            errorMessage!,
            style: NestType.caption(color: tokens.danger),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: NestSpacing.s2),
        ],
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
      // review #6: the HTML source is a `role="radiogroup"` of
      // `role="radio"` buttons with `aria-checked`, so the choice also
      // announces as checked and as part of a mutually exclusive group
      // ("radio, 3 of 3, selected") instead of a plain button.
      checked: selected,
      inMutuallyExclusiveGroup: true,
      label: '$title, $sub',
      // review #2: `excludeSemantics` also drops the GestureDetector's tap
      // action, which left a control announced as a button that could not be
      // activated (WCAG 4.1.2 / 2.1.1). Re-declaring onTap restores
      // `SemanticsAction.tap` without adding a second node.
      onTap: onTap,
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
                        style: context.nestText.bodyStrong.copyWith(
                          height: 22 / 16,
                        ),
                        softWrap: true,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: NestSpacing.gap2),
                      Text(
                        sub,
                        style: NestType.bodySmall(color: tokens.ink2)
                            .copyWith(height: 20 / 15),
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

  /// The design draws the selected centre as a `border: 4px solid
  /// leaf-tint`-inside-`inset 0 0 0 4px` disc inside the 22px ring
  /// (`components.css`), i.e. a 14px leaf centre; a 10px dot is the closest
  /// token-free read. A named constant (not `NestSpacing.gap10`) says "a
  /// size" instead of "a 10px gap" (review #8).
  static const double _dotDiameter = 10;

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
              width: _dotDiameter,
              height: _dotDiameter,
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
            child: Text(
              'Payout day',
              style: NestType.fieldLabel(color: tokens.ink2),
            ),
          ),
          const SizedBox(height: NestSpacing.gap6),
          // The chip row keeps the card's 16 px inner inset through the
          // cell-width formula in _DayRow (not a tight Padding/SizedBox
          // wrapper — those swallow the ±6 px NestChipWrap hit-slop taps).
          _DayRow(payoutDay: setup.payoutDay),
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

/// 7 single-select day cells (Mon = 1 … Sun = 7). Each cell paints the
/// `.chip.day` pill (full-cell width, 32 high, 13px centred label, no
/// horizontal padding). Cells share the row's inner width, so the pill
/// strip runs exactly between the card's 16 px insets at every width.
/// `NestChipWrap` only widens hit-testing: the row stays 32 px high while
/// taps landing up to 6 px above/below the pills (or in the 6 px gaps)
/// reach the nearest cell.
class _DayRow extends StatelessWidget {
  const _DayRow({required this.payoutDay});

  final int payoutDay;

  @override
  Widget build(BuildContext context) {
    // Width math from the viewport: the card is edge-to-edge inside the
    // scroll view's 20px gutters, and NestChipWrap is a direct child of
    // the card's Column so its ±6px hitSlop is reachable (a LayoutBuilder/
    // Semantics/SizedBox between them re-clamps routable hit positions).
    const gaps = 6 * NestSpacing.gap6; // 6 inter-cell gaps
    final cardSpan =
        MediaQuery.sizeOf(context).width -
        2 * NestSpacing.padSide -
        2 * NestSpacing.s4;
    // At 390/320 the pills render ~40/30 px wide; the 13 px labels still
    // just fit, ellipsis is the backstop.
    final cellWidth = (cardSpan - gaps) / 7;
    return NestChipWrap(
      spacing: NestSpacing.gap6,
      alignment: WrapAlignment.center,
      children: <Widget>[
        for (var i = 0; i < PocketMoneySetupView.dayLabels.length; i++)
          _DayCell(
            cellKey: ValueKey<String>('p06_day_${i + 1}'),
            label: PocketMoneySetupView.dayLabels[i],
            cellWidth: cellWidth,
            selected: payoutDay == i + 1,
            onTap: () => context.read<PocketMoneyBloc>().add(
              PocketMoneyPayoutDayChanged(i + 1),
            ),
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.cellKey,
    required this.label,
    required this.cellWidth,
    required this.selected,
    required this.onTap,
  });

  final ValueKey<String> cellKey;
  final String label;
  final double cellWidth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: cellKey,
      button: true,
      selected: selected,
      // review #4: the HTML groups the strip with
      // `role="group" aria-label="Payout day"`. Iteration 5 dropped that
      // wrapper (it re-clamped NestChipWrap's hit slop) and left the cells
      // announcing as bare "Mon", "Tue", … — so the section name rides in
      // each cell's label instead, with no extra widget in the chain.
      label: 'Payout day: $label',
      // review #2: same dropped-tap-action fix as _PocketOptionCard.
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: cellWidth,
          // The pill height; the ≥44 dp target is NestChipWrap's hitSlop,
          // not a taller cell box (which would centre pills 6 dp low).
          height: NestSpacing.s8,
          child: _DayPill(label: label, selected: selected),
        ),
      ),
    );
  }
}

/// The P06 `.chip.day`: the shared `NestChip` has no 13px/padding-0 day
/// variant, so this renders it from tokens directly (TODO(P06): retire it
/// when `NestChip` grows a day mode — see SHARED_REQUEST.md). Unselected:
/// surface-2 pill, ink label; selected: leafTint pill, leaf border, leafInk
/// label. No horizontal padding, 32 high, fills the grid cell.
class _DayPill extends StatelessWidget {
  const _DayPill({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return SizedBox(
      width: double.infinity,
      height: NestSpacing.s8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? tokens.leafTint : tokens.surface2,
          borderRadius: NestRadii.allPill,
          border: Border.all(
            color: selected ? tokens.leaf : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: NestType.fieldLabel(
              color: selected ? tokens.leafInk : tokens.ink,
            ),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// One per-child weekly-base row in insertion order: 32px avatar + name +
/// stepper ([P06WeeklyStepper], whose `−`/`+` are the design's glyphs).
/// The stepper buttons carry the HTML aria-labels verbatim.
///
/// Narrow screens reflow to two lines (name line, then the stepper
/// right-aligned): the fixed 44px stepper buttons plus a wide value string
/// cannot share one 248px line with the avatar and the name at large text
/// scales, and the stepper cannot shrink its buttons.
class _WeeklyBaseRow extends StatelessWidget {
  const _WeeklyBaseRow({required this.child});

  final PocketMoneySetupChild child;

  /// Below this row width the single line cannot fit avatar + name + the
  /// 44px stepper at text scale 1.3 (248px at 320dp does not fit; 318px at
  /// 390dp does), so the row wraps instead of overflowing.
  static const double _wrapWidth = 300;

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
    final initial = nestAvatarInitial(child.nickname);
    final avatar = NestAvatar(
      initial: initial,
      size: NestAvatarSize.s32,
      color: _avatarColor(child.avatarColour),
    );
    final name = Expanded(
      child: Text(
        child.nickname,
        style: NestType.body(color: context.nest.ink)
            .copyWith(fontWeight: FontWeight.w600, height: 22 / 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
    final stepper = _BaseStepper(child: child);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: NestDevice.tapParent),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= _wrapWidth) {
            return Row(
              key: ValueKey<String>('p06_base_row_${child.id}'),
              children: <Widget>[
                avatar,
                const SizedBox(width: NestSpacing.s3),
                name,
                stepper,
              ],
            );
          }
          return Column(
            key: ValueKey<String>('p06_base_row_${child.id}'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  avatar,
                  const SizedBox(width: NestSpacing.s3),
                  name,
                ],
              ),
              const SizedBox(height: NestSpacing.s2),
              Align(alignment: Alignment.centerRight, child: stepper),
            ],
          );
        },
      ),
    );
  }
}

/// The weekly-base stepper with the HTML aria-labels verbatim and the
/// design's `&minus;`/`+` glyph pair. Split out so the row can place one
/// instance in either the single-line or the wrapped layout (only one branch
/// builds at a time).
class _BaseStepper extends StatelessWidget {
  const _BaseStepper({required this.child});

  final PocketMoneySetupChild child;

  @override
  Widget build(BuildContext context) {
    return P06WeeklyStepper(
      valueText: '£${(child.weeklyBasePence / 100).toStringAsFixed(2)}',
      onDecrease: () => context.read<PocketMoneyBloc>().add(
        PocketMoneyWeeklyBaseStepped(child.id, -PocketMoneySetupView.stepPence),
      ),
      onIncrease: () => context.read<PocketMoneyBloc>().add(
        PocketMoneyWeeklyBaseStepped(child.id, PocketMoneySetupView.stepPence),
      ),
      decreaseSemanticLabel: 'Less weekly pocket money for ${child.nickname}',
      increaseSemanticLabel: 'More weekly pocket money for ${child.nickname}',
    );
  }
}

/// Display-only coin-value row: 40px coin-tint tile + label + trailing value.
///
/// The value is a *tight* `Expanded` with `TextAlign.end`, so it ends on the
/// card's content edge — the same edge as the `+` buttons and the Sun pill
/// (ORCHESTRATOR_NOTES 09:30); a loose `Flexible` sized it to its intrinsic
/// width and left it 33 px short of that edge. `Expanded` + `softWrap: false`
/// also keeps it the one text allowed to ellipsize when the row runs out of
/// room (`1_plan.md` §5: "must ellipsis, never push the tile").
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
            width: NestSpacing.s10,
            height: NestSpacing.s10,
            decoration: BoxDecoration(
              color: tokens.coinTint,
              borderRadius: BorderRadius.circular(NestRadii.m),
            ),
            alignment: Alignment.center,
            child: ExcludeSemantics(
              child: SvgPicture.asset(
                NestlingIllustrations.coin,
                width: NestSpacing.s6,
                height: NestSpacing.s6,
              ),
            ),
          ),
          const SizedBox(width: NestSpacing.s3),
          Expanded(
            child: Text(
              'Coin value',
              style: NestType.body(color: tokens.ink)
                  .copyWith(fontWeight: FontWeight.w600, height: 22 / 16),
              // Two lines, never truncated: the row's *name* must print in
              // full at 320 dp × 1.3, where the label's share of the row is
              // narrower than the scaled string (P06-BUG-13). Above 320 dp it
              // stays one line, exactly as the design draws it.
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              '10 coins = ${10 * coinValuePencePerCoin}p',
              style: NestType.bodySmall(color: tokens.ink2),
              textAlign: TextAlign.end,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
