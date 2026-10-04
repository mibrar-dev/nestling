import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/kid_shop/domain/entities/shop_reward.dart';
import 'package:nestling/features/kid_shop/presentation/bloc/kid_shop_bloc.dart';
import 'package:nestling/features/kid_shop/presentation/bloc/kid_shop_event.dart';
import 'package:nestling/features/kid_shop/presentation/bloc/kid_shop_state.dart';
import 'package:nestling/features/kid_shop/presentation/widgets/shop_reward_card.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';

/// Screen copy, transcribed character-by-character from
/// `design/html-source/screens/K08-shop.html:41,44,51,58,78,89`. Nothing here
/// is invented except the empty-state line, which the HTML has no source for
/// (`1_plan.md` §d, kid voice).
/// The card's own labels live with the card (`shop_reward_card.dart`, which
/// also owns the "N more to go" format), so this class holds only the copy the
/// view itself renders.
abstract final class RewardShopCopy {
  const new _();

  static const String title = 'Reward shop';
  static const String intro = 'Spend your coins on things you actually want.';
  static const String back = 'Back';
  static const String grownUps = 'Grown-ups';
  static const String loading = 'Loading rewards';
  static const String emptyTitle = 'No rewards yet';
  static const String emptyMessage =
      'Ask a grown-up to add something coins can buy.';
  static const String loadError = 'Something went wrong';
  static const String tryAgain = 'Try again';

  /// `.kcap.k8-foot`: `You have 120 coins. Pip is helping you save!` — the
  /// balance comes from the child row, never from the design's number.
  static String footer(int coins) =>
      'You have $coins coins. Pip is helping you save!';
}

/// K08 Reward shop (`/reward-shop`): the child's coin balance, a two-column
/// grid of reward cards and a "save up" footer — over the shared kid sky +
/// meadow (`KidScope`, never a local hill).
///
/// Layout is the HTML's, not a guess: status bar 47, `.k8-top` 47…103 (56 px
/// back / lock boxes, 6 px below), `.k8-head` 109…149 (40 px `coin-pill.big`),
/// intro 165…185, grid rows at 201 / 433 / 665 with a 16 px gap and 167 px
/// columns at 390 wide, and a 58 px scroll tail (`--home-h` 34 + `--s6` 24).
class RewardShopView extends StatelessWidget {
  const RewardShopView({super.key});

  @override
  Widget build(BuildContext context) {
    // `noticeSeq` is the trigger (the notice text itself can repeat, so
    // comparing it would miss a second identical toast), then
    // `KidShopNoticeShown` clears it.
    return BlocListener<KidShopBloc, KidShopState>(
      listenWhen: (previous, current) =>
          previous.noticeSeq != current.noticeSeq && current.notice != null,
      listener: (context, state) {
        final notice = state.notice;
        if (notice == null) return;
        showNestToast(context, notice);
        context.read<KidShopBloc>().add(const KidShopNoticeShown());
      },
      child: const _ShopChrome(body: _ShopBody()),
    );
  }
}

/// Shared chrome for every K08 state: `KidScope` + transparent `Scaffold`,
/// the status-bar reserve, the `.k8-top` back/lock row and the home-indicator
/// reserve (transparent — the meadow runs to the physical edge, BOTTOM EDGE
/// owner rule: K08 has no bar of its own, so nothing paints below the list).
class _ShopChrome extends StatelessWidget {
  const _ShopChrome({required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            const _ShopTopRow(),
            Expanded(child: body),
            const NestHomeIndicator(),
          ],
        ),
      ),
    );
  }
}

/// `.nav-back.lg` chevron, 26 px (`K08-shop.html:38`). No token carries 26.
const double _backIconSize = 26;

/// `.k8-top` (`K08-shop.html:17-18,38`): `padding: 0 20px 6px`, back on the
/// left (transparent — the shape is invisible in the design), the parental-gate
/// lock pushed to the right edge. Both boxes are 56 (`--tap-kid`).
class _ShopTopRow extends StatelessWidget {
  const _ShopTopRow();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        0,
        NestSpacing.padSide,
        NestSpacing.gap6,
      ),
      child: Row(
        children: [
          NestIconButton(
            icon: NestIcons.back,
            semanticLabel: RewardShopCopy.back,
            size: NestDevice.tapKid,
            // `.nav-back.lg` chevron 26, stroke 2.5 (K08-shop.html:38) — the
            // shared default is 24 (44 px `.nav-back`), so the lg box needs
            // the design's own 26.
            iconSize: _backIconSize,
            // `.nav-back { background: transparent; border: 0 }` — the shared
            // button only hides its circle when both fills are transparent
            // (K02 precedent).
            backgroundColor: Colors.transparent,
            borderColor: Colors.transparent,
            foregroundColor: tokens.ink,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(KidHomeRoutePaths.home);
              }
            },
          ),
          const Spacer(),
          const _GateLockButton(),
        ],
      ),
    );
  }
}

/// Parental-gate lock with a tap guard: one `/parental-gate` push per gesture
/// burst, even on a fast double tap (K03 `_GateLockButton` precedent).
class _GateLockButton extends StatefulWidget {
  const _GateLockButton();

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
    return NestLockButton(
      semanticLabel: RewardShopCopy.grownUps,
      onPressed: _open,
    );
  }
}

/// Loaded / loading / empty / failure body. Chrome stays put in every state so
/// a child can always get back or reach a grown-up.
class _ShopBody extends StatelessWidget {
  const _ShopBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<KidShopBloc, KidShopState>(
      builder: (context, state) {
        switch (state.status) {
          case KidShopStatus.initial:
          case KidShopStatus.loading:
            return const _ShopLoading();
          case KidShopStatus.failure:
            return const _ShopFailure();
          case KidShopStatus.loaded:
            if (state.items.isEmpty) return const _ShopEmpty();
            return _ShopList(state: state);
        }
      },
    );
  }
}

/// Initial load and guarded reload: chrome + the kid spinner.
class _ShopLoading extends StatelessWidget {
  const _ShopLoading();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Center(
      child: Semantics(
        label: RewardShopCopy.loading,
        child: CircularProgressIndicator(color: tokens.leaf),
      ),
    );
  }
}

/// Loaded but the family has no rewards (wiped, or a fresh family). A child
/// cannot add one, so there is no action — just the P14 copy and a kid-voice
/// line pointing at a grown-up (`1_plan.md` §d).
class _ShopEmpty extends StatelessWidget {
  const _ShopEmpty();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
        child: NestEmptyState(
          art: NestIcon(NestIcons.gift, size: 96, color: tokens.ink3),
          title: RewardShopCopy.emptyTitle,
          message: RewardShopCopy.emptyMessage,
        ),
      ),
    );
  }
}

/// Stream failure: chrome + the same gift art, the P14 error line and a
/// `Try again` that re-requests the load (the bloc released its subscription
/// on the error, so the guard lets the event through).
class _ShopFailure extends StatelessWidget {
  const _ShopFailure();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
        child: NestEmptyState(
          art: NestIcon(NestIcons.gift, size: 96, color: tokens.ink3),
          title: RewardShopCopy.loadError,
          action: NestKidButton(
            label: RewardShopCopy.tryAgain,
            color: NestKidButtonColor.white,
            fullWidth: false,
            onPressed: () =>
                context.read<KidShopBloc>().add(const KidShopLoadRequested()),
          ),
        ),
      ),
    );
  }
}

/// `.scroll.k8-scroll` (`K08-shop.html:39-90`): header row, intro line, the
/// two-column reward grid and the footer, separated by `.scroll > * + *`
/// (16). Bottom padding is `--home-h + --s6` (34 + 24 = 58) so the last row
/// clears the home indicator.
class _ShopList extends StatelessWidget {
  const _ShopList({required this.state});

  final KidShopState state;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final coins = state.coins;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        0,
        NestSpacing.padSide,
        NestDevice.homeH + NestSpacing.s6,
      ),
      children: [
        Row(
          spacing: NestSpacing.gap10,
          children: [
            // `.kid-title` is one of the balanced headings (`text-wrap:
            // balance`, components.css:36) — `NestBalancedText` keeps the
            // copy and the rect but breaks the lines the way the design does.
            Expanded(
              child: NestBalancedText(
                RewardShopCopy.title,
                style: NestType.kidTitle(color: tokens.ink),
                textAlign: TextAlign.start,
                maxLines: 2,
              ),
            ),
            NestCoinPill(
              amount: '$coins',
              size: NestCoinPillSize.large,
              semanticLabel: '$coins coins',
            ),
          ],
        ),
        const SizedBox(height: NestSpacing.s4),
        Text(
          RewardShopCopy.intro,
          style: NestType.kidCaption(color: tokens.ink2),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: NestSpacing.s4),
        _ShopGrid(state: state),
        const SizedBox(height: NestSpacing.s4),
        Text(
          RewardShopCopy.footer(coins),
          style: NestType.kidCaption(color: tokens.ink2),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// `.k8-grid` (`K08-shop.html:21`): two equal columns, 16 px gap.
///
/// Chunked into pairs with `IntrinsicHeight` + `stretch` so both cards of a
/// row share the row height — the CSS grid's `align-items: stretch`, which is
/// what keeps the shorter card of the last row (no "N more to go" note) as
/// tall as the café card next to it. Column width comes from the slot, never a
/// fixed 167 (SPACING_SPEC §10.2: `(W − 40 − gap) / 2`, 132 px at 320 wide).
class _ShopGrid extends StatelessWidget {
  const _ShopGrid({required this.state});

  final KidShopState state;

  @override
  Widget build(BuildContext context) {
    final items = state.items;
    final bloc = context.read<KidShopBloc>();
    final cards = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final left = _cardFor(items[i], bloc);
      final right = i + 1 < items.length
          ? _cardFor(items[i + 1], bloc)
          : const Spacer();
      cards.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: left),
              const SizedBox(width: NestSpacing.s4),
              Expanded(child: right),
            ],
          ),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: NestSpacing.s4,
      children: cards,
    );
  }

  Widget _cardFor(ShopReward item, KidShopBloc bloc) {
    return ShopRewardCard(
      item: item,
      coins: state.coins,
      requesting: state.requestingIds.contains(item.id),
      onRequest: () => bloc.add(KidShopRewardRequested(item.id)),
    );
  }
}
