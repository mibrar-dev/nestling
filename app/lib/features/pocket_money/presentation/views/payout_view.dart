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

  /// The last write-failure message this view actually surfaced. A retry after
  /// that visible failure re-arms the CTA (P13-BUG-01 keeps the double-tap
  /// guard for a genuinely in-flight write; a *failed* attempt must stay
  /// retryable, or the button would be dead for the rest of the visit).
  String? _lastFailure;

  @override
  void initState() {
    super.initState();
    // A route that is pumped onto an ALREADY loaded bloc (deep link, tests
    // that pre-load) has no future emission to prime from — seed here, before
    // the first build. `build` stays pure (review finding 5).
    final bloc = context.read<PocketMoneyBloc>();
    if (bloc.state.status == PocketMoneyStatus.loaded) {
      _prime(bloc.state.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Scaffold(
      backgroundColor: tokens.paper,
      body: BlocListener<PocketMoneyBloc, PocketMoneyState>(
        // Priming: the first `loaded` emission seeds the ticked set. It runs
        // in the listener (never in `build`) so no State is mutated during the
        // build phase (review finding 5).
        listenWhen: (previous, current) =>
            !_primed && current.status == PocketMoneyStatus.loaded,
        listener: (context, state) => setState(() => _prime(state.data)),
        child: BlocListener<PocketMoneyBloc, PocketMoneyState>(
          // A rejected write keeps `status: loaded` and only sets
          // `errorMessage`, so it surfaces as a toast and the sheet stays.
          listenWhen: (previous, current) =>
              _submitted.isNotEmpty &&
              current.status == PocketMoneyStatus.loaded &&
              previous.errorMessage != current.errorMessage &&
              current.errorMessage != null,
          listener: (context, state) {
            setState(() {
              _submitted.clear();
              _lastFailure = state.errorMessage;
            });
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
              setState(() {
                _submitted.clear();
                _lastFailure = null;
              });
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
                            busy: _submitted.isNotEmpty,
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
      ),
    );
  }

  /// Seeds the ticked set from the first loaded emission: the first child in
  /// creation order that actually has money owed (the design shows Maya
  /// ticked). With nothing owed — a family that was just paid — the set stays
  /// empty and the CTA is disabled.
  void _prime(MoneyLedgerData? data) {
    if (_primed) return;
    if (data == null) return;
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

  /// One `PocketMoneyPayoutSubmitted` per ticked child **that owes money**.
  /// The £1.00 savings move belongs to the goal-bearing child alone, only
  /// when that child is actually being paid (an unticked child's money never
  /// moved out), and never more than the amount handed over.
  ///
  /// Three guards, all from the iteration-1 review / bug hunt:
  /// * re-entrancy — a second tap while the first write is still in flight
  ///   must not dispatch again (P13-BUG-01: two `payout` rows, the goal
  ///   credited twice). The guard re-arms only after a failure the parent
  ///   actually saw, so retrying stays possible;
  /// * a ticked child who owes £0.00 is skipped — no "Paid · £0.00" row for
  ///   money that never moved (review finding 3);
  /// * the savings move is clamped to the money paid, so a £0.50 payout can
  ///   never conjure £1.00 in the jar (P13-BUG-02).
  void _submit(MoneyLedgerData data) {
    if (_submitted.isNotEmpty) {
      final error = context.read<PocketMoneyBloc>().state.errorMessage;
      if (error == null || error != _lastFailure) return;
      _submitted.clear();
    }
    final bloc = context.read<PocketMoneyBloc>();
    final saveChildId = payoutSaveChildId(data);
    final paying = <String, int>{
      for (final childId in _ticked)
        if (_owedOf(data, childId) > 0) childId: _owedOf(data, childId),
    };
    if (paying.isEmpty) return;
    for (final entry in paying.entries) {
      final movesSavings = _saveOn && entry.key == saveChildId;
      final move = movesSavings
          ? (PayoutSheet.savingsMovePence < entry.value
                ? PayoutSheet.savingsMovePence
                : entry.value)
          : 0;
      bloc.add(
        PocketMoneyPayoutSubmitted(
          entry.key,
          entry.value,
          move,
          move > 0 ? data.goalFor(entry.key)?.id : null,
        ),
      );
    }
    setState(() {
      _lastFailure = null;
      _submitted.addAll(paying.keys);
    });
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
/// "is owed" summary card.
///
/// The design stacks one `inset: 0` scrim OVER the whole backdrop
/// (`P13-payout.html:19-21`, `components.css:164` — `z-index: 20`, below the
/// `.pay` sheet's 30), so the status-bar reserve, the title and the summary
/// card all render dimmed and a tap anywhere above the sheet dismisses it.
/// The chrome is `ExcludeSemantics` — it is not actionable and a modal sheet
/// must not leave a focus trap behind itself; the scrim keeps its own
/// labelled dismiss node (review findings 1, 6 and 9, P13-BUG-03/05).
class _DimmedLedger extends StatelessWidget {
  const _DimmedLedger({required this.data, required this.onDismiss});

  final MoneyLedgerData data;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Stack(
      children: <Widget>[
        ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const NestStatusBar(),
              Padding(
                // `.bg-fake .ptitle { padding-top: 8px }` inside a 20 px
                // gutter.
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
                    // `.caption` sets no `text-align` in the design, so the
                    // summary starts at the card's padding edge (measured
                    // glyph origin x 37 in the light PNG) — never centred.
                    // (`1_plan.md` §(a) said "centered"; the HTML/CSS
                    // truth overrides the plan, 5_ui deviation 1.)
                    textAlign: TextAlign.start,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // `.bg-fake` then `<div style="flex:1">` — the ledger body is
              // not painted here, only reserved.
              const Spacer(),
            ],
          ),
        ),
        // `.scrim { position: absolute; inset: 0; z-index: 20 }` — full
        // bleed, and tapping it dismisses the sheet (back to `/money`).
        Positioned.fill(
          child: Semantics(
            button: true,
            label: 'Close payout',
            onTap: onDismiss,
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDismiss,
              child: ColoredBox(color: tokens.scrim),
            ),
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

/// Load failure: message + the only legal retry. Keeps the same
/// `NestStatusBar()` reserve as every other body on this route, so the two
/// states agree about the chrome (review finding 10).
class _FailureBody extends StatelessWidget {
  const _FailureBody({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const NestStatusBar(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: NestSpacing.padSide,
              ),
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
          ),
        ),
      ],
    );
  }
}
