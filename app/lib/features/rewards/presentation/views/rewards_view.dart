import 'dart:async';

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
/// bar, the intro line, one `.rw` card per reward in the order the repository
/// streams them (creation order — never re-sorted here), then a full-width
/// `+ New reward`.
///
/// The `Scaffold` paints `paper` top to bottom edge and this screen has no
/// bottom bar, tab bar or CTA panel — the page tint is its own surface, so
/// nothing coloured can show under the last child (BOTTOM EDGE).
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
                    // A failed *action* write keeps the last loaded list in
                    // state; only a stream failure has nothing to show, and
                    // only then does `Try again` belong on screen.
                    if (state.items.isNotEmpty) {
                      return _RewardsLoaded(items: state.items);
                    }
                    return const _RewardsCenteredScroll(
                      child: _RewardsFailure(),
                    );
                  case RewardsStatus.loaded:
                    if (state.items.isEmpty) {
                      return const _RewardsCenteredScroll(
                        child: _RewardsEmpty(),
                      );
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

/// `.scroll` for the list: 20 px side gutters, no top padding, and P14's own
/// 66 px bottom (the screen-local override of the base 32). Children sit
/// 16 px apart (`.scroll > * + *`). The design has no gap after the last
/// child — the 66 px bottom pad already stands in for the home band, so
/// nothing is appended here (stage 4, finding 3).
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
      children: <Widget>[child],
    );
  }
}

/// `.scroll` for the empty and failure surfaces, which plan §4 centres in the
/// scroll area.
///
/// A `ListView` hands its child an unbounded main axis, so a bare `Center`
/// shrink-wraps and pins the surface under the nav bar (P14-B02: 181 px off
/// centre for the empty state). A `LayoutBuilder` +
/// `ConstrainedBox(minHeight:)` inside a `SingleChildScrollView` keeps the
/// 20 px gutters and the 66 px bottom pad and lets the surface centre in the
/// viewport while still scrolling when it is taller than the screen.
class _RewardsCenteredScroll extends StatelessWidget {
  const _RewardsCenteredScroll({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            NestSpacing.padSide,
            0,
            NestSpacing.padSide,
            66,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 66),
            child: Center(child: child),
          ),
        );
      },
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
              onNeedsOkChanged: (value) =>
                  _changeNeedsOk(context, reward.id, value),
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
    return NestEmptyState(
      art: NestIcon(NestIcons.gift, size: 96, color: tokens.ink3),
      title: RewardCopy.emptyTitle,
      message: RewardCopy.emptyMessage,
      action: NestButton(
        key: const ValueKey('p14_empty_new_reward'),
        label: RewardCopy.newReward,
        variant: NestButtonVariant.secondary,
        onPressed: () => openRewardEditor(context),
      ),
    );
  }
}

/// Full-screen failure surface — a stream failure only (see the `failure`
/// branch above).
///
/// The copy is static (`RewardCopy.loadError`), never the raw exception:
/// `state.errorMessage` stays on the state as the technical detail, matching
/// the reviewed `paywall_view.dart` precedent (stage 4, finding 2).
class _RewardsFailure extends StatelessWidget {
  const _RewardsFailure();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          RewardCopy.loadError,
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
    );
  }
}

/// Feature-local opener for the reward editor sheet.
///
/// Composes the shared `NestBottomSheet` exactly like `showNestBottomSheet`
/// does (same grabber, radius, `paper` fill, scrim, safe area), with one
/// difference: the modal's height cap follows the keyboard.
///
/// `showNestBottomSheet` caps the sheet at 92 % of the screen
/// (`constraints: maxHeight: size.height * 0.92`) and never reads
/// `MediaQuery.viewInsets`. On iOS the keyboard is reported as an inset only —
/// it floats over the Flutter view — so with the name field focused the
/// sheet's own `Save`, `Cancel` and `Delete` sat behind the keyboard with no
/// scroll escape (P14-B01). Allowing the sheet to be as tall as the screen
/// *plus* the keyboard band turns the inset into trailing space
/// ([RewardEditorSheet] pads the form by it), which lifts the form above the
/// keyboard; with no keyboard the cap is unchanged, so the resting layout is
/// byte-identical to the design.
///
/// The fix belongs in the shared `showNestBottomSheet` for every screen —
/// filed in `docs/screens/P14/SHARED_REQUEST.md`; this is the feature-local
/// version so `/rewards` is not blocked on it.
Future<void> showRewardEditorSheet(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  final tokens = context.nest;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: tokens.scrim,
    // Deliberately no `constraints` cap (unlike `showNestBottomSheet`'s
    // `maxHeight: size.height * 0.92`, which is read once when the sheet
    // opens and so cannot know about a keyboard that appears later):
    // unbounded is what lets the sheet grow by the keyboard band and ride its
    // top off-screen instead of leaving Save/Cancel/Delete behind the
    // keyboard. `RewardEditorSheet` applies the resting 92 % cap itself, so
    // the sheet without a keyboard is exactly the shared helper's size.
    builder: (sheetContext) => NestBottomSheet(
      title: title,
      onClose: () => Navigator.of(sheetContext).pop(),
      child: child,
    ),
  );
}

/// Opens the create/edit sheet for [reward] (blank when null).
///
/// There is no `/rewards/editor` route in the route table, so the editor is
/// an in-feature bottom sheet. It reports intent through callbacks and pops
/// itself; the stream re-emits after each write.
Future<void> openRewardEditor(BuildContext context, {Reward? reward}) {
  final bloc = context.read<RewardsBloc>();
  final existing = reward;
  return showRewardEditorSheet(
    context,
    title: existing == null
        ? RewardCopy.newRewardLabel
        : RewardCopy.editRewardLabel,
    child: RewardEditorSheet(
      reward: existing,
      onSave: (edited) => saveReward(bloc, edited, existing: existing),
      onDelete: existing == null
          ? () async {}
          : () => deleteReward(bloc, existing.id),
    ),
  );
}

/// One row's `Needs my OK` flip (P14 `.okrow`).
///
/// The toggle always renders the database value — the `watchItems` stream
/// re-emits it after the write — so a failed flip simply snaps back. The
/// `result` channel (2a contract) exists for the one thing the UI cannot show
/// on its own: a toast, so the parent is not left tapping a switch that
/// silently does nothing.
Future<void> _changeNeedsOk(
  BuildContext context,
  String id,
  bool needsOk,
) async {
  final bloc = context.read<RewardsBloc>();
  final result = Completer<void>();
  bloc.add(RewardsNeedsOkChanged(id: id, needsOk: needsOk, result: result));
  try {
    await result.future;
  } on Object {
    if (!context.mounted) return;
    showNestToast(context, RewardCopy.actionFailed);
  }
}

/// Adds the sheet's Save event and completes with the write's outcome, so the
/// sheet can stay open with an inline danger caption instead of closing on a
/// blind `bloc.add` (plan §4, P14-B03).
///
/// The channel is the one declared in `2a_build_logic.md`: the bloc completes
/// it when the write lands and completes it with the error when the write
/// throws — and, since writes no longer emit `failure`, the loaded list behind
/// the sheet is never replaced by a full-screen error.
Future<void> saveReward(RewardsBloc bloc, Reward edited, {Reward? existing}) {
  final result = Completer<void>();
  if (existing == null) {
    bloc.add(
      RewardsCreateRequested(
        title: edited.title,
        coinPrice: edited.coinPrice,
        needsOk: edited.needsOk,
        icon: edited.icon,
        result: result,
      ),
    );
  } else {
    bloc.add(RewardsUpdateRequested(reward: edited, result: result));
  }
  return result.future;
}

/// The sheet's confirmed Delete, on the same `result` channel as
/// [saveReward] so a failed delete keeps the sheet (and the reward) intact.
Future<void> deleteReward(RewardsBloc bloc, String id) {
  final result = Completer<void>();
  bloc.add(RewardsDeleteRequested(id: id, result: result));
  return result.future;
}
