import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/rewards/domain/entities/reward.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_bloc.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_event.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_state.dart';
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_card.dart';
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_editor_sheet.dart';
import 'package:nestling/features/rewards/presentation/widgets/p14_reward_meta.dart';

/// P14 · Rewards manager (`/rewards`, parent mode).
///
/// Layout follows `design/html-source/screens/P14-rewards.html`: compact nav
/// bar, the intro line, one `.rw` card per reward in database order
/// (`watchItems` is `coinPrice ASC`), then a full-width `+ New reward`.
///
/// The `Scaffold` paints `paper` top to bottom edge and this screen has no
/// bottom bar, tab bar or CTA panel — the page tint is its own surface, so
/// nothing coloured can show under the last child.
///
/// Every write goes through the BLoC and comes back on the `watchItems`
/// stream; the view never re-adds `RewardsLoadRequested` to refresh.
class RewardsView extends StatelessWidget {
  const RewardsView({super.key});

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
            title: RewardCopy.navTitle,
            onBack: () {
              if (context.canPop()) context.pop();
            },
          ),
          Expanded(
            child: BlocBuilder<RewardsBloc, RewardsState>(
              builder: (context, state) {
                switch (state.status) {
                  case RewardsStatus.initial:
                  case RewardsStatus.loading:
                    return const _RewardsLoading();
                  case RewardsStatus.failure:
                    return _RewardsScroll(
                      child: _RewardsFailure(message: state.errorMessage),
                    );
                  case RewardsStatus.loaded:
                    if (state.items.isEmpty) {
                      return const _RewardsScroll(child: _RewardsEmpty());
                    }
                    return _RewardsLoaded(items: state.items);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// `.scroll`: 20 px side gutters, no top padding, and P14's own 66 px bottom
/// (the screen-local override of the base 32). Children sit 16 px apart
/// (`.scroll > * + *`).
class _RewardsScroll extends StatelessWidget {
  const _RewardsScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        0,
        NestSpacing.padSide,
        66,
      ),
      children: <Widget>[
        child,
        const SizedBox(height: NestSpacing.s4),
      ],
    );
  }
}

class _RewardsLoaded extends StatelessWidget {
  const _RewardsLoaded({required this.items});

  final List<Reward> items;

  @override
  Widget build(BuildContext context) {
    return _RewardsScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            RewardCopy.intro,
            style: NestType.bodySmall(color: context.nest.ink2),
            maxLines: 4,
            softWrap: true,
          ),
          for (final reward in items) ...<Widget>[
            const SizedBox(height: NestSpacing.s4),
            RewardCard(
              key: ValueKey('p14_reward_${reward.id}'),
              reward: reward,
              onNeedsOkChanged: (value) => context.read<RewardsBloc>().add(
                RewardsNeedsOkChanged(id: reward.id, needsOk: value),
              ),
              onEdit: () => openRewardEditor(context, reward: reward),
            ),
          ],
          const SizedBox(height: NestSpacing.s4),
          NestButton(
            key: const ValueKey('p14_new_reward'),
            label: RewardCopy.newReward,
            variant: NestButtonVariant.secondary,
            onPressed: () => openRewardEditor(context),
          ),
        ],
      ),
    );
  }
}

class _RewardsLoading extends StatelessWidget {
  const _RewardsLoading();

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator(color: context.nest.leaf));
  }
}

class _RewardsEmpty extends StatelessWidget {
  const _RewardsEmpty();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Center(
      child: NestEmptyState(
        art: NestIcon(NestIcons.gift, size: 96, color: tokens.ink3),
        title: RewardCopy.emptyTitle,
        message: RewardCopy.emptyMessage,
        action: NestButton(
          key: const ValueKey('p14_empty_new_reward'),
          label: RewardCopy.newReward,
          variant: NestButtonVariant.secondary,
          onPressed: () => openRewardEditor(context),
        ),
      ),
    );
  }
}

class _RewardsFailure extends StatelessWidget {
  const _RewardsFailure({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            message ?? RewardCopy.loadError,
            style: NestType.body(color: tokens.ink2),
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: NestSpacing.s4),
          NestButton(
            key: const ValueKey('p14_try_again'),
            label: RewardCopy.tryAgain,
            variant: NestButtonVariant.secondary,
            onPressed: () =>
                context.read<RewardsBloc>().add(const RewardsLoadRequested()),
          ),
        ],
      ),
    );
  }
}

/// Opens the create/edit sheet for [reward] (blank when null).
///
/// There is no `/rewards/editor` route in the route table, so the editor is
/// an in-feature bottom sheet. It reports intent through callbacks and pops
/// itself; the stream re-emits after each write.
Future<void> openRewardEditor(BuildContext context, {Reward? reward}) {
  final bloc = context.read<RewardsBloc>();
  return showNestBottomSheet<void>(
    context,
    title: reward == null
        ? RewardCopy.newRewardLabel
        : RewardCopy.editRewardLabel,
    child: RewardEditorSheet(
      reward: reward,
      onSave: (edited) {
        final existing = reward;
        if (existing == null) {
          bloc.add(
            RewardsCreateRequested(
              title: edited.title,
              coinPrice: edited.coinPrice,
              needsOk: edited.needsOk,
              icon: edited.icon,
            ),
          );
        } else {
          bloc.add(RewardsUpdateRequested(reward: edited));
        }
      },
      onDelete: () => bloc.add(RewardsDeleteRequested(id: reward!.id)),
    ),
  );
}
