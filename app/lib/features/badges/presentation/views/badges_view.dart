import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/badges/domain/entities/badge.dart' as domain;
import 'package:nestling/features/badges/presentation/bloc/badges_bloc.dart';
import 'package:nestling/features/badges/presentation/bloc/badges_event.dart';
import 'package:nestling/features/badges/presentation/bloc/badges_state.dart';
import 'package:nestling/features/badges/presentation/widgets/badge_grid_cell.dart';
import 'package:nestling/features/badges/presentation/widgets/happy_week_card.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';

/// Screen copy, transcribed character-by-character from
/// `design/html-source/screens/K11-badges.html`. The design's own line is
/// `Four shiny ones already. Pip is very impressed.` (HTML line 40); the
/// count comes from the seeded database, so the word changes with it
/// (`1_plan.md` §c). The zero lines are the flagged kid-voice inventions the
/// planner recorded, because the design has no source for them.
abstract final class BadgesCopy {
  const BadgesCopy._();

  static const String title = 'My badges';
  static const String back = 'Back';
  static const String grownUps = 'Grown-ups';
  static const String loading = 'Loading badges';
  static const String loadError = 'Something went wrong';
  static const String tryAgain = 'Try again';
  static const String emptyTitle = 'No badges yet';

  /// Invented kid voice (`1_plan.md` §d — flagged): the design has no
  /// empty-shelf line because the demo family always has badges.
  static const String emptyMessage =
      'Finish a quest and your first badge will shine here.';

  /// Number words for 1…9, then digits (the shelf never reaches double
  /// figures in the design; the database is still the source either way).
  static const List<String> _numberWords = <String>[
    'One',
    'Two',
    'Three',
    'Four',
    'Five',
    'Six',
    'Seven',
    'Eight',
    'Nine',
  ];

  /// `.kcap` subtitle: the design's `Four shiny ones already. Pip is very
  /// impressed.` with the database's earned count substituted.
  static String subtitle(int earned) {
    if (earned <= 0) {
      return 'No shiny ones yet. Finish a quest to earn your first!';
    }
    final word = earned <= _numberWords.length
        ? _numberWords[earned - 1]
        : '$earned';
    final noun = earned == 1 ? 'one' : 'ones';
    return '$word shiny $noun already. Pip is very impressed.';
  }
}

/// K11 My badges (`/badges`): the child's badge shelf and happy-week
/// tracker over the shared kid sky + meadow (`KidScope`, never a local
/// hill).
///
/// Layout is the HTML's, not a guess: status reserve 47, `.krow-top`
/// 47…107 (56 px back / lock boxes, 4 px below), the scroll's 20 px gutters
/// and 16 px sibling rhythm put the title at 107…141, the subtitle at
/// 157…177, the 3-column grid at 193 (12 px row gap) and the week card at
/// 683…829. The scroll is clipped by the 34 px home-indicator reserve
/// (107…810), exactly as the HTML's flex column clips it, so the meadow — not
/// the card — shows under the home pill (measured on the design PNG: the
/// card's white face ends at y 810 and the meadow fills 810…844).
class BadgesView extends StatelessWidget {
  const BadgesView({super.key});

  @override
  Widget build(BuildContext context) {
    return const _BadgesChrome(body: _BadgesBody());
  }
}

/// Shared chrome for every K11 state: `KidScope` + transparent `Scaffold`,
/// the status-bar reserve, the `.krow-top` back/lock row and the
/// home-indicator reserve. The chrome stays mounted while the shelf loads or
/// fails, so a child can always get back or reach a grown-up.
class _BadgesChrome extends StatelessWidget {
  const _BadgesChrome({required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: <Widget>[
            const NestStatusBar(),
            const _BadgesTopRow(),
            Expanded(child: body),
            // `.home-indicator { height: var(--home-h) }`
            // (`K11-badges.html:138`, `components.css:51`): the HTML's flex
            // column clips the scroll 34 px above the physical edge, so the
            // week card is cut at 810 and the meadow shows under the OS home
            // pill (measured on the design PNG: the card's white face stops at
            // y 810, meadow fills 810…844). `NestHomeIndicator` paints nothing
            // in the app (it is the gallery mock only), so the reserve is
            // explicit — K03 profile-picker / kid-PIN precedent. Nothing is
            // painted here: BOTTOM EDGE owner rule — the meadow runs to the
            // edge.
            const SizedBox(height: NestDevice.homeH),
          ],
        ),
      ),
    );
  }
}

/// `.nav-back.lg` chevron, 26 px (`K11-badges.html:47`). No token carries 26.
const double _backIconSize = 26;

/// `.krow-top` (`K11-badges.html:14,47`): `padding: 0 20px 4px`, back on the
/// left (transparent — the shape is invisible in the design), the
/// parental-gate lock pushed to the right edge. Both boxes are 56
/// (`--tap-kid`).
class _BadgesTopRow extends StatelessWidget {
  const _BadgesTopRow();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        0,
        NestSpacing.padSide,
        NestSpacing.s1,
      ),
      child: Row(
        children: <Widget>[
          NestIconButton(
            icon: NestIcons.back,
            semanticLabel: BadgesCopy.back,
            size: NestDevice.tapKid,
            iconSize: _backIconSize,
            // `.nav-back { background: transparent; border: 0 }` — both
            // fills transparent matches the design's pressable area with no
            // visible shape.
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

/// Parental-gate lock with a tap guard: one `/parental-gate` push per
/// gesture burst, even on a fast double tap (K08 `_GateLockButton`
/// precedent).
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
    return NestLockButton(semanticLabel: BadgesCopy.grownUps, onPressed: _open);
  }
}

/// Loaded / loading / empty / failure body (`1_plan.md` §d). The chrome
/// stays put in every state.
class _BadgesBody extends StatelessWidget {
  const _BadgesBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BadgesBloc, BadgesState>(
      builder: (context, state) {
        switch (state.status) {
          case BadgesStatus.initial:
          case BadgesStatus.loading:
            return const _BadgesLoading();
          case BadgesStatus.failure:
            return const _BadgesFailure();
          case BadgesStatus.loaded:
            if (state.items.isEmpty) return const _BadgesEmpty();
            return _BadgesList(state: state);
        }
      },
    );
  }
}

/// Initial load and guarded reload: chrome + the kid spinner.
class _BadgesLoading extends StatelessWidget {
  const _BadgesLoading();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Center(
      child: Semantics(
        label: BadgesCopy.loading,
        child: CircularProgressIndicator(color: tokens.leaf),
      ),
    );
  }
}

/// Stream failure: chrome + the neutral ribbon art, the shared error line
/// and a `Try again` that re-requests the load (the bloc released its
/// subscription on the error, so the guard lets the event through).
class _BadgesFailure extends StatelessWidget {
  const _BadgesFailure();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
        child: NestEmptyState(
          art: NestIcon(NestIcons.ribbon, size: 96, color: tokens.ink3),
          title: BadgesCopy.loadError,
          action: NestKidButton(
            label: BadgesCopy.tryAgain,
            color: NestKidButtonColor.white,
            fullWidth: false,
            onPressed: () =>
                context.read<BadgesBloc>().add(const BadgesLoadRequested()),
          ),
        ),
      ),
    );
  }
}

/// Loaded but the shelf is empty (wiped database or a family with no badges
/// yet). The week card is hidden with it — there is nothing to celebrate.
class _BadgesEmpty extends StatelessWidget {
  const _BadgesEmpty();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
        child: NestEmptyState(
          art: NestIcon(NestIcons.ribbon, size: 96, color: tokens.ink3),
          title: BadgesCopy.emptyTitle,
          message: BadgesCopy.emptyMessage,
        ),
      ),
    );
  }
}

/// The scroll: title, DB-driven subtitle, the badge grid and the happy-week
/// card, `.scroll`'s 16 px sibling rhythm apart, with the design's 20 px
/// gutters and 32 px bottom padding (`K11-badges.html:16`).
class _BadgesList extends StatelessWidget {
  const _BadgesList({required this.state});

  final BadgesState state;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final earned = state.items.where((badge) => badge.earned).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        0,
        NestSpacing.padSide,
        NestSpacing.s8,
      ),
      children: <Widget>[
        // `.kid-title` is a balanced heading (`text-wrap: balance`,
        // components.css:36) — `NestBalancedText` keeps the copy and the
        // rect but breaks the lines the way the design does.
        NestBalancedText(
          BadgesCopy.title,
          style: NestType.kidTitle(color: tokens.ink),
          textAlign: TextAlign.start,
          maxLines: 2,
        ),
        const SizedBox(height: NestSpacing.s4),
        Text(
          BadgesCopy.subtitle(earned),
          style: NestType.kidCaption(color: tokens.ink2),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: NestSpacing.s4),
        // TODO(K11): the demo seed still carries 8 shelf rows
        // (`tidy-champion` / `super-saver` / `pet-friend` in place of the
        // design's `bins-out` / `biscuit-sitter` / `tidy-hero` /
        // `plant-waterer`); the grid renders whatever the database returns
        // in DB order. Seed correction filed as
        // `docs/screens/K11/SHARED_REQUEST.md` (blocks: no).
        _BadgeGrid(items: state.items),
        const SizedBox(height: NestSpacing.s4),
        HappyWeekCard(happyDays: state.happyDays),
      ],
    );
  }
}

/// `.k11-grid` (`K11-badges.html:21`): three equal columns, 12 px gaps.
///
/// Chunked into rows of three with `IntrinsicHeight` + `stretch` so every
/// cell in a row shares the row height (the CSS grid's `align-items:
/// stretch`), and column width comes from the slot, never a fixed 108.67
/// (SPACING_SPEC §10.2: `(W − 40 − 24) / 3`, 85.3 at 320 wide). The
/// trailing odd slots use `Expanded(SizedBox.shrink())`: an inert filler
/// that keeps the gutters aligned without the "competing ParentDataWidgets"
/// crash of `Expanded(child: Spacer())` (K08-BUG-2).
class _BadgeGrid extends StatelessWidget {
  const _BadgeGrid({required this.items});

  final List<domain.Badge> items;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 3) {
      final cells = <Widget>[];
      for (var j = 0; j < 3; j++) {
        if (j > 0) cells.add(const SizedBox(width: NestSpacing.s3));
        final index = i + j;
        cells.add(
          Expanded(
            child: index < items.length
                ? BadgeGridCell(badge: items[index])
                : const SizedBox.shrink(),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(const SizedBox(height: NestSpacing.s3));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
