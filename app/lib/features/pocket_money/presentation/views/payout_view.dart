import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/family/family_routes.dart';
import 'package:nestling/features/pocket_money/domain/entities/money_ledger_data.dart';
import 'package:nestling/features/pocket_money/pocket_money_routes.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_bloc.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_event.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_state.dart';
import 'package:nestling/features/pocket_money/presentation/widgets/money_pounds.dart';
import 'package:nestling/features/pocket_money/presentation/widgets/payout_sheet.dart';

/// P13 · Payout (parent), route `/payout`.
///
/// A full-screen route (not inside `ParentShell` — the design shows no tab
/// bar): the P12 ledger dimmed behind a `--scrim`, with the feature-local
/// `.pay` sheet bottom-anchored on top. Tapping the scrim (or the system back
/// gesture) dismisses back to `/money` — or, when `/payout` was launched as
/// the initial route, straight to the ledger (see `_goBack`).
///
/// The sheet's ticked set, savings flag and the armed submit live in this
/// State; every amount comes from the seeded database through
/// `PocketMoneyState.data`.
class PayoutView extends StatefulWidget {
  const PayoutView({super.key});

  @override
  State<PayoutView> createState() => _PayoutViewState();
}

class _PayoutViewState extends State<PayoutView> {
  /// Child ids whose cash the parent ticked (design: Maya on, Leo off).
  final Set<String> _ticked = <String>{};

  /// `.saverow` toggle. The design ships it ON.
  bool _saveOn = true;

  /// Set once the first `loaded` emission has seeded [_ticked].
  bool _primed = false;

  /// Children whose payout is in flight. Cleared by the stream proof or by a
  /// write failure.
  final Set<String> _submitted = <String>{};

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Scaffold(
      backgroundColor: tokens.paper,
      body: BlocListener<PocketMoneyBloc, PocketMoneyState>(
        // A rejected write keeps `status: loaded` and only sets
        // `errorMessage`, so it surfaces as a toast and the sheet stays.
        listenWhen: (previous, current) =>
            _submitted.isNotEmpty &&
            current.status == PocketMoneyStatus.loaded &&
            previous.errorMessage != current.errorMessage &&
            current.errorMessage != null,
        listener: (context, state) {
          setState(_submitted.clear);
          showNestToast(context, state.errorMessage!);
        },
        child: BlocListener<PocketMoneyBloc, PocketMoneyState>(
          // The confirmation: the ledger stream re-emits once the payout row
          // landed, which is the only proof the write happened (P12
          // finding-6 pattern — never announce on the tap itself).
          listenWhen: (previous, current) =>
              _submitted.isNotEmpty &&
              current.status == PocketMoneyStatus.loaded &&
              current.errorMessage == null &&
              _payoutLanded(previous.data, current.data),
          listener: (context, state) {
            setState(_submitted.clear);
            showNestToast(context, _payoutToast);
            _goBack();
          },
          child: BlocBuilder<PocketMoneyBloc, PocketMoneyState>(
            buildWhen: (previous, current) =>
                previous.status != current.status ||
                previous.data != current.data ||
                previous.errorMessage != current.errorMessage,
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
                  _prime(data);
                  return Stack(
                    children: <Widget>[
                      Positioned.fill(
                        child: _DimmedLedger(data: data, onDismiss: _goBack),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: PayoutSheet(
                          data: data,
                          ticked: _ticked,
                          saveOn: _saveOn,
                          onToggled: _toggle,
                          onSaveChanged: (value) =>
                              setState(() => _saveOn = value),
                          onSubmit: () => _submit(data),
                        ),
                      ),
                    ],
                  );
              }
            },
          ),
        ),
      ),
    );
  }

  /// Seeds the ticked set from the first loaded emission: the first child in
  /// creation order that actually has money owed (the design shows Maya
  /// ticked). With nothing owed — a family that was just paid — the set stays
  /// empty and the CTA is disabled.
  void _prime(MoneyLedgerData data) {
    if (_primed) return;
    _primed = true;
    String? first;
    for (final child in data.children) {
      if (_owedOf(data, child.id) > 0) {
        first = child.id;
        break;
      }
    }
    if (first != null) _ticked.add(first);
  }

  /// Dismisses the sheet. `/payout` is normally pushed on top of `/money`, so
  /// the tap pops; launched as the initial route (`shot.sh`,
  /// `INITIAL_ROUTE=/payout`) there is nothing to pop and the parent still has
  /// to land on the ledger — `context.pop()` alone throws a `GoError` there.
  void _goBack() {
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(PocketMoneyRoutePaths.ledger);
    }
  }

  /// Flips one child's ticked state (a `.check` is a toggle).
  void _toggle(String childId) {
    setState(() {
      if (!_ticked.remove(childId)) _ticked.add(childId);
    });
  }

  /// One `PocketMoneyPayoutSubmitted` per ticked child. The £1.00 savings
  /// move belongs to the goal-bearing child alone, and only when that child
  /// is actually being paid (an unticked child's money never moved out).
  void _submit(MoneyLedgerData data) {
    final bloc = context.read<PocketMoneyBloc>();
    final saveChildId = payoutSaveChildId(data);
    for (final childId in _ticked) {
      final movesSavings = _saveOn && childId == saveChildId;
      bloc.add(
        PocketMoneyPayoutSubmitted(
          childId,
          _owedOf(data, childId),
          movesSavings ? PayoutSheet.savingsMovePence : 0,
          movesSavings ? data.goalFor(childId)?.id : null,
        ),
      );
    }
    setState(() => _submitted.addAll(_ticked));
  }

  /// True when every child whose payout is in flight now owes nothing AND
  /// the emission is not the one that armed the submit.
  bool _payoutLanded(MoneyLedgerData? previous, MoneyLedgerData? current) {
    if (current == null) return false;
    var changed = false;
    for (final childId in _submitted) {
      final was = previous == null ? null : _owedOf(previous, childId);
      final now = _owedOf(current, childId);
      if (was != now) changed = true;
      if (now > 0) return false;
    }
    return changed;
  }

  int _owedOf(MoneyLedgerData data, String childId) =>
      data.owedFor(childId)?.totalPence ?? 0;

  /// Toast after a proven write (U+2014 EM DASH, spaced, like `kMoneyEmDash`).
  static const String _payoutToast =
      'Payout recorded $kMoneyEmDash enjoy the celebration';
}

/// The P12 ledger dimmed behind the scrim: status-bar reserve, title and the
/// "is owed" summary card. `ExcludeSemantics` — it is not actionable and a
/// modal sheet must not leave a focus trap behind itself.
class _DimmedLedger extends StatelessWidget {
  const _DimmedLedger({required this.data, required this.onDismiss});

  final MoneyLedgerData data;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const NestStatusBar(),
        Padding(
          // `.bg-fake .ptitle { padding-top: 8px }` inside a 20 px gutter.
          padding: const EdgeInsets.fromLTRB(
            NestSpacing.padSide,
            NestSpacing.s2,
            NestSpacing.padSide,
            0,
          ),
          child: Semantics(
            header: true,
            child: Text(
              'Pocket money',
              style: NestType.h1(color: tokens.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            NestSpacing.padSide,
            NestSpacing.s3,
            NestSpacing.padSide,
            0,
          ),
          child: NestCard(
            child: Text(
              _summary(data),
              style: NestType.caption(color: tokens.ink2),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        // `.scrim { position: absolute; inset: 0 }` — tapping it dismisses
        // the sheet and returns to `/money`.
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: ColoredBox(color: tokens.scrim),
          ),
        ),
      ],
    );
  }

  /// "Maya is owed £4.20 · Leo is owed £2.10", built from the database in
  /// creation order (U+00B7 separator, the P12 `kMoneyDot`).
  static String _summary(MoneyLedgerData data) {
    final parts = <String>[
      for (final child in data.children)
        '${child.nickname} is owed ${moneyPounds(_owedOf(data, child.id))}',
    ];
    return parts.join(' $kMoneyDot ');
  }

  static int _owedOf(MoneyLedgerData data, String childId) =>
      data.owedFor(childId)?.totalPence ?? 0;
}

/// No children yet (fresh install): the same chrome + the shared empty
/// state, no sheet and no scrim.
class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const NestStatusBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              NestSpacing.padSide,
              NestSpacing.s2,
              NestSpacing.padSide,
              NestSpacing.s8,
            ),
            children: <Widget>[
              Text(
                'Pocket money',
                style: NestType.h1(color: context.nest.ink),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: NestSpacing.s4),
              NestEmptyState(
                art: SvgPicture.asset(NestlingIllustrations.coin),
                title: 'No payouts yet',
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
