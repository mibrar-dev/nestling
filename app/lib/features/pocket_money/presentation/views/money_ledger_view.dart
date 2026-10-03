import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/family/family_routes.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_child.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_ledger_data.dart';
import 'package:nestling/features/pocket_money/domain/entities/owed_summary.dart';
import 'package:nestling/features/pocket_money/domain/entities/savings_goal_data.dart';
import 'package:nestling/features/pocket_money/domain/next_payout.dart';
import 'package:nestling/features/pocket_money/pocket_money_routes.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_bloc.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_event.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_state.dart';
import 'package:nestling/features/pocket_money/presentation/widgets/money_edit_sheet.dart';
import 'package:nestling/features/pocket_money/presentation/widgets/money_history_row.dart';
import 'package:nestling/features/pocket_money/presentation/widgets/money_pounds.dart';

/// P12 · Money (ledger), route `/money` — parent mode.
///
/// Chrome (status-bar height reserve, tab bar, home indicator) comes from
/// `ParentShell`; this view renders the scroll body only: title, child
/// segment, the "is owed" hero, the savings-goal card, the history card, the
/// two row buttons and the footer caption. Every colour comes from
/// `context.nest`, so dark mode needs no branch here (the hero card paints
/// `heroBg`, never `ink`).
class MoneyLedgerView extends StatelessWidget {
  const MoneyLedgerView({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Scaffold(
      backgroundColor: tokens.paper,
      body: BlocListener<PocketMoneyBloc, PocketMoneyState>(
        // A write failure keeps `status: loaded` and only sets
        // `errorMessage` (the body stays on screen), so surface it as a
        // toast. A load failure keeps `status: failure` and renders the
        // inline `_FailureBody` instead.
        listenWhen: (previous, current) =>
            current.status == PocketMoneyStatus.loaded &&
            previous.errorMessage != current.errorMessage &&
            current.errorMessage != null,
        listener: (context, state) =>
            showNestToast(context, state.errorMessage!),
        child: BlocBuilder<PocketMoneyBloc, PocketMoneyState>(
          builder: (context, state) {
            switch (state.status) {
              case PocketMoneyStatus.initial:
              case PocketMoneyStatus.loading:
                return Center(
                  child: CircularProgressIndicator(color: tokens.leaf),
                );
              case PocketMoneyStatus.failure:
                return _FailureBody(message: state.errorMessage);
              case PocketMoneyStatus.loaded:
                final data = state.data;
                if (data == null || data.children.isEmpty) {
                  return const _EmptyBody();
                }
                return _LoadedBody(state: state, data: data);
            }
          },
        ),
      ),
    );
  }
}

/// The page title, shared by the loaded and empty bodies.
class _PageTitle extends StatelessWidget {
  const _PageTitle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: NestSpacing.s2),
      child: Semantics(
        header: true,
        child: Text(
          'Pocket money',
          style: NestType.h1(color: context.nest.ink),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// `.scroll` side/bottom padding — 20 px gutters everywhere (owner
/// alignment rule), 32 px below the last child so nothing sits under the
/// shell tab bar.
const EdgeInsets _scrollPadding = EdgeInsets.fromLTRB(
  NestSpacing.padSide,
  0,
  NestSpacing.padSide,
  NestSpacing.s8,
);

/// Loaded body for the selected child: hero, goal, history, row buttons.
class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.state, required this.data});

  final PocketMoneyState state;
  final MoneyLedgerData data;

  /// `.goal img` — the 56×56 coin illustration (design CSS).
  static const double _goalArt = 56;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final bloc = context.read<PocketMoneyBloc>();
    final child =
        data.childById(state.selectedChildId ?? '') ?? data.children.first;
    final owed =
        data.owedFor(child.id) ??
        OwedSummary(
          childId: child.id,
          totalPence: 0,
          basePence: 0,
          questsPence: 0,
        );
    final entries = data.entriesFor(child.id);
    final goal = data.goalFor(child.id);
    final name = child.nickname;
    final nextPayout = payoutLabel(
      payoutWeekday: data.payoutDay,
      nowUtc: DateTime.now().toUtc(),
      zoneId: data.zoneId,
    );

    return ListView(
      padding: _scrollPadding,
      children: <Widget>[
        const NestStatusBar(),
        const SizedBox(height: NestSpacing.s4),
        const _PageTitle(),
        const SizedBox(height: NestSpacing.s4),
        // Creation order (Maya, then Leo), never alphabetical.
        NestSegmented<String>(
          options: <NestSegmentOption<String>>[
            for (final option in data.children)
              NestSegmentOption<String>(
                value: option.id,
                label: option.nickname,
              ),
          ],
          value: child.id,
          semanticLabel: 'Child',
          onChanged: (childId) => bloc.add(PocketMoneyChildSelected(childId)),
        ),
        const SizedBox(height: NestSpacing.s4),
        NestCard(
          variant: NestCardVariant.hero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                '$name is owed',
                style: NestType.chipLabel(color: tokens.onHero2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                moneyPounds(owed.totalPence),
                // `.hero .amt` letter-spacing `-.01em` at 40 px = −0.4. Every
                // other NestType style keeps tracking at 0.
                style: NestType.kidHero(color: tokens.onHero)
                    .copyWith(letterSpacing: -0.4),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: NestSpacing.s1),
              Text(
                'Weekly base ${moneyPounds(owed.basePence)}'
                ' + quests ${moneyPounds(owed.questsPence)}'
                ' $kMoneyDot Next payout $nextPayout',
                style: NestType.chipLabel(color: tokens.onHero2)
                    .copyWith(fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: NestSpacing.gap14),
              NestButton(
                label: 'Payout time',
                semanticLabel: 'Payout time for $name',
                onPressed: () => context.push(PocketMoneyRoutePaths.payout),
              ),
            ],
          ),
        ),
        if (goal != null) ...<Widget>[
          const SizedBox(height: NestSpacing.s4),
          _GoalCard(goal: goal),
        ],
        const SizedBox(height: NestSpacing.s4),
        NestCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'History',
                style: NestType.h3(color: tokens.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: NestSpacing.s1),
              if (entries.isEmpty)
                Text(
                  'No history yet',
                  style: NestType.caption(color: tokens.ink2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else
                for (final entry in entries)
                  MoneyHistoryRow(entry: entry, familyZoneId: data.zoneId),
            ],
          ),
        ),
        const SizedBox(height: NestSpacing.s4),
        Row(
          children: <Widget>[
            Expanded(
              child: NestButton(
                label: 'Add money',
                variant: NestButtonVariant.secondary,
                // `.rowbtns .btn`: min-height 48, font 15.
                minHeight: NestDevice.tapParent + NestSpacing.s1,
                fontSize: 15,
                horizontalPadding: NestSpacing.s3,
                onPressed: () => _openSheet(
                  context,
                  bloc,
                  child,
                  MoneyEditSheetMode.addMoney,
                ),
              ),
            ),
            const SizedBox(width: NestSpacing.gap10),
            Expanded(
              child: NestButton(
                label: 'Record spending',
                variant: NestButtonVariant.secondary,
                minHeight: NestDevice.tapParent + NestSpacing.s1,
                fontSize: 15,
                horizontalPadding: NestSpacing.s3,
                onPressed: () => _openSheet(
                  context,
                  bloc,
                  child,
                  MoneyEditSheetMode.recordSpending,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: NestSpacing.s4),
        Text(
          'Nestling keeps track $kMoneyEmDash the real money stays with you.',
          style: NestType.caption(color: tokens.ink2),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// MoneyChild is the display name only; the sheet needs the id, so the
/// signature takes the bloc + child id and stays out of the widget tree.
void _openSheet(
  BuildContext context,
  PocketMoneyBloc bloc,
  MoneyChild child,
  MoneyEditSheetMode mode,
) {
  final name = child.nickname;
  final isAdd = mode == MoneyEditSheetMode.addMoney;
  unawaited(
    showNestBottomSheet<void>(
      context,
      title: isAdd ? 'Add money for $name' : 'Record spending for $name',
      child: isAdd
          ? MoneyEditSheet.addMoney(
              onSubmit: (amountPence, note) {
                bloc.add(
                  PocketMoneyAddMoneySubmitted(child.id, amountPence, note),
                );
                showNestToast(
                  context,
                  'Added ${moneyPounds(amountPence)} for $name',
                );
              },
            )
          : MoneyEditSheet.recordSpending(
              onSubmit: (amountPence, note) {
                bloc.add(
                  PocketMoneySpendingSubmitted(child.id, amountPence, note),
                );
                showNestToast(
                  context,
                  'Spent ${moneyPounds(amountPence)} recorded',
                );
              },
            ),
    ),
  );
}

/// `.card .goal` — coin illustration, title + saved caption + progress.
/// Display-only: the card is not tappable.
class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final SavingsGoalData goal;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return NestCard(
      child: Row(
        children: <Widget>[
          ExcludeSemantics(
            child: SvgPicture.asset(
              NestlingIllustrations.coin,
              width: _LoadedBody._goalArt,
              height: _LoadedBody._goalArt,
            ),
          ),
          const SizedBox(width: NestSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '${goal.title} $kMoneyEmDash ${moneyPounds(goal.targetPence)}',
                  style: NestType.bodyStrong(color: tokens.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${moneyPounds(goal.savedPence)} saved'
                  ' $kMoneyDot ${(goal.fraction * 100).round()}%',
                  style: NestType.caption(color: tokens.ink2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: NestSpacing.s2),
                NestProgress(
                  fraction: goal.fraction,
                  semanticLabel: 'Savings goal progress',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// No children yet (fresh install): the scroll chrome + the shared empty
/// state. No hero / goal / history / row buttons in this state.
class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _scrollPadding,
      children: <Widget>[
        const NestStatusBar(),
        const SizedBox(height: NestSpacing.s4),
        const _PageTitle(),
        const SizedBox(height: NestSpacing.s4),
        NestEmptyState(
          art: SvgPicture.asset(NestlingIllustrations.coin),
          title: 'No pocket money yet',
          message: 'Add a child to start tracking pocket money.',
          action: NestButton(
            label: 'Add a child',
            fullWidth: false,
            onPressed: () => context.push(FamilyRoutePaths.addChildren),
          ),
        ),
      ],
    );
  }
}

/// Load failure: message + the only legal retry.
class _FailureBody extends StatelessWidget {
  const _FailureBody({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message ?? 'Something went wrong',
              style: NestType.bodySmall(color: tokens.ink2),
              textAlign: TextAlign.center,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: NestSpacing.s4),
            NestButton(
              label: 'Try again',
              variant: NestButtonVariant.secondary,
              fullWidth: false,
              onPressed: () => context.read<PocketMoneyBloc>().add(
                const PocketMoneyLoadRequested(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
