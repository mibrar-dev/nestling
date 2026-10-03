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
///
/// The vertical stack reproduces the design's arithmetic exactly — see
/// `_LoadedBody`'s anchors comment for the measured tops.
class MoneyLedgerView extends StatefulWidget {
  const MoneyLedgerView({super.key});

  @override
  State<MoneyLedgerView> createState() => _MoneyLedgerViewState();
}

class _MoneyLedgerViewState extends State<MoneyLedgerView> {
  /// Finding 6 (4_review.md): a write is only announced once the watch
  /// stream has actually re-emitted, so a rejected write shows the error
  /// toast instead of a false "Added £5.00 for Maya". The pending record is
  /// the child's ledger size at submit time plus the copy to show once it
  /// grows by a row.
  ///
  /// Finding 3 (iteration 2): it carries the **child id** (so a tap on the
  /// segment between submit and the stream round-trip cannot pop the old
  /// child's confirmation on the new child's next write) and it is a
  /// **list**, so a second submit before the first emission no longer
  /// overwrites the first confirmation.
  final List<_PendingWrite> _pendingWrites = <_PendingWrite>[];

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
        listener: (context, state) {
          // The write was rejected: drop every armed confirmation so the
          // error toast above is the only thing the parent is told.
          if (_pendingWrites.isNotEmpty) {
            setState(_pendingWrites.clear);
          }
          showNestToast(context, state.errorMessage!);
        },
        child: BlocListener<PocketMoneyBloc, PocketMoneyState>(
          // The confirmation half of finding 6: the ledger stream re-emits
          // after a successful write, which is the proof the row landed.
          // A selection change counts too — it is what retires the armed
          // writes belonging to the child the parent just left.
          listenWhen: (previous, current) =>
              _pendingWrites.isNotEmpty &&
              current.status == PocketMoneyStatus.loaded &&
              (_ledgerSize(current) != _ledgerSize(previous) ||
                  current.selectedChildId != previous.selectedChildId),
          listener: (context, state) {
            if (_pendingWrites.isEmpty) return;
            final data = state.data;
            final childId = state.selectedChildId;
            if (data == null || childId == null) return;
            final size = data.entriesFor(childId).length;
            // Anything armed for another child is stale the moment the
            // selection moves; retire it instead of letting it fire later.
            final confirmed = _pendingWrites
                .where(
                  (pending) =>
                      pending.childId == childId && size > pending.count,
                )
                .toList(growable: false);
            setState(
              () => _pendingWrites.removeWhere(
                (pending) =>
                    pending.childId != childId || confirmed.contains(pending),
              ),
            );
            for (final pending in confirmed) {
              showNestToast(context, pending.message);
            }
          },
          child: BlocBuilder<PocketMoneyBloc, PocketMoneyState>(
            // Finding 11: a rejected submit only changes `errorMessage`,
            // which the listener above already consumes. Without this the
            // whole ListView — title, segment, hero, goal card and every
            // history row — rebuilt for a message it does not render.
            buildWhen: (previous, current) =>
                previous.status != current.status ||
                previous.data != current.data ||
                previous.selectedChildId != current.selectedChildId,
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
                  return _LoadedBody(
                    state: state,
                    data: data,
                    onWrite: _recordWrite,
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  /// How many ledger rows the selected child has in [state] — the stream's
  /// own proof that a write landed.
  int _ledgerSize(PocketMoneyState state) {
    final data = state.data;
    final childId = state.selectedChildId;
    if (data == null || childId == null) return -1;
    return data.entriesFor(childId).length;
  }

  /// Dispatches the write and remembers what to say once it is confirmed.
  void _recordWrite(
    BuildContext context,
    PocketMoneyBloc bloc,
    MoneyChild child,
    MoneyEditSheetMode mode,
    int amountPence,
    String note,
  ) {
    final data = bloc.state.data;
    final before = data == null ? 0 : data.entriesFor(child.id).length;
    final message = mode == MoneyEditSheetMode.addMoney
        ? 'Added ${moneyPounds(amountPence)} for ${child.nickname}'
        : 'Spent ${moneyPounds(amountPence)} recorded';
    if (mode == MoneyEditSheetMode.addMoney) {
      bloc.add(PocketMoneyAddMoneySubmitted(child.id, amountPence, note));
    } else {
      bloc.add(PocketMoneySpendingSubmitted(child.id, amountPence, note));
    }
    setState(
      () => _pendingWrites.add(
        _PendingWrite(childId: child.id, count: before, message: message),
      ),
    );
  }
}

/// One armed confirmation (findings 6 and 3): the child it belongs to, how
/// many ledger rows that child had when the sheet was submitted, and the
/// copy to announce once the stream proves the row landed.
@immutable
class _PendingWrite {
  const _PendingWrite({
    required this.childId,
    required this.count,
    required this.message,
  });

  final String childId;
  final int count;
  final String message;
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
  const _LoadedBody({
    required this.state,
    required this.data,
    required this.onWrite,
  });

  final PocketMoneyState state;
  final MoneyLedgerData data;

  /// Writes a sheet's validated row through the bloc; the owning State keeps
  /// the confirmation copy (finding 6).
  final void Function(
    BuildContext context,
    PocketMoneyBloc bloc,
    MoneyChild child,
    MoneyEditSheetMode mode,
    int amountPence,
    String note,
  )
  onWrite;

  /// `.goal img` — the 56×56 coin illustration (design CSS).
  static const double _goalArt = 56;

  /// `.hero .lab` (`P12-money.html:5`) declares `font-size:14px` and **no**
  /// line-height, so the design render resolves the browser's `normal`:
  /// Inter's font metrics (ascender 0.969 em + descender 0.241 em, lineGap 0)
  /// at 14 px give a 16.94 ≈ 17 px line box — 3 px less than the 14/20
  /// `chipLabel` token.
  ///
  /// Measured off `design/screens/light/P12-money.png`: the hero fill runs
  /// 519…1151 px = 173…383.7 logical (a height of exactly 211 px) and the
  /// `Payout time` fill starts at 936 px = 312 logical, which only closes
  /// with a 17 px label:
  ///
  /// ```text
  /// 173 + 20 pad + 17 lab + 44 amt + 4 brk-top + 40 brk(2 × 20)
  ///     + 14 btn-top + 52 btn + 20 pad = 384
  /// ```
  ///
  /// (With a 20 px label the button lands at 315, three px below the design.)
  /// Pinned at the call site, like `.hero .amt`'s −0.4 tracking — the shared
  /// `NestType` styles are untouched.
  static const double _heroLabHeight = 17 / 14;

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

    // Finding 1 (4_review.md, iteration 2): the 47 px band is the `.scroll`'s
    // *preceding sibling* in `P12-money.html:17-20` (`components.css:46`
    // `.status-bar { min-height:47px; flex-shrink:0 }`, `:65`
    // `.scroll { flex:1; overflow-y:auto }`), so it is pinned above the
    // scroller here — exactly as P05/P06/K03 do it. Inside the scroller the
    // reserve scrolled away and the white history cards painted under the OS
    // clock as soon as the parent scrolled the ledger.
    return Column(
      children: <Widget>[
        const NestStatusBar(),
        Expanded(
          child: ListView(
            padding: _scrollPadding,
            // Design anchors at 390×844
            // (`design/screens/light/P12-money.png` ÷ 3), pinned by
            // `money_ledger_geometry_test.dart`:
            //
            // ```
            // 47  NestStatusBar          (.status-bar height 47)
            // +8  .ptitle padding-top    → title line box 55…89 (28/34)
            // +16 .scroll > * + *        → segmented track 105…157
            //                               (4 + 44 + 4)
            // +16                        → owed card 173…384  (211)
            // +16                        → goal card 400…488  (88)
            // +16                        → history card 504…
            // ```
            //
            // `.scroll`'s first child is `.ptitle`, so `.scroll > * + *`
            // gives it nothing: its only top spacing is its own
            // `padding-top:8px`. Nothing may be inserted between the band
            // and the title (P12-BUG-05).
            children: <Widget>[
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
                onChanged: (childId) =>
                    bloc.add(PocketMoneyChildSelected(childId)),
              ),
              const SizedBox(height: NestSpacing.s4),
              NestCard(
                variant: NestCardVariant.hero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      '$name is owed',
                      style: NestType.chipLabel(color: tokens.onHero2)
                          .copyWith(height: _heroLabHeight),
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
                      onPressed: () =>
                          context.push(PocketMoneyRoutePaths.payout),
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
                        MoneyHistoryRow(
                          entry: entry,
                          familyZoneId: data.zoneId,
                        ),
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
                        onWrite,
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
                        onWrite,
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
          ),
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
  _LoadedBodyWrite onWrite,
) {
  final isAdd = mode == MoneyEditSheetMode.addMoney;
  unawaited(
    showNestBottomSheet<void>(
      context,
      title: isAdd
          ? 'Add money for ${child.nickname}'
          : 'Record spending for ${child.nickname}',
      child: isAdd
          ? MoneyEditSheet.addMoney(
              onSubmit: (amountPence, note) =>
                  onWrite(context, bloc, child, mode, amountPence, note),
            )
          : MoneyEditSheet.recordSpending(
              onSubmit: (amountPence, note) =>
                  onWrite(context, bloc, child, mode, amountPence, note),
            ),
    ),
  );
}

/// The write seam between the sheet and the view's State, which holds the
/// confirmation copy until the ledger stream proves the row landed.
typedef _LoadedBodyWrite = void Function(
  BuildContext context,
  PocketMoneyBloc bloc,
  MoneyChild child,
  MoneyEditSheetMode mode,
  int amountPence,
  String note,
);

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
                  // `.goal .t` (`P12-money.html:11`) is a **22 px** line box;
                  // `NestType.bodyStrong` is 16/24. The card is
                  // `max(56 art, 22 + 18 + 8 + 8)` = 56 tall either way only
                  // with 22 — with 24 the column is 58 and the card renders
                  // 90, pushing the history card 2 px down (finding 2).
                  style: NestType.bodyStrong(color: tokens.ink)
                      .copyWith(height: 22 / 16),
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
    // Same pinned band as the loaded body (finding 1): the status-bar
    // reserve is the `.scroll`'s preceding sibling in the design, never a
    // row of it.
    return Column(
      children: <Widget>[
        const NestStatusBar(),
        Expanded(
          child: ListView(
            padding: _scrollPadding,
            // Same stack as the loaded body: the title gets only its own
            // 8 px padding (P12-BUG-05). Pinned by
            // `money_ledger_geometry_test.dart`.
            children: <Widget>[
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
