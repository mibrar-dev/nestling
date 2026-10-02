import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/data/env_flags.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/auth/auth_routes.dart';

/// P02 Value tour — parent-mode marketing pager at `/value-tour`.
///
/// Static marketing screen (same pattern as P01 `WelcomeView`): three tour
/// cards in a clipped horizontal pager + dots + per-page title/body + a fixed
/// bottom CTA. The copy mirrors `OnboardingRepositoryImpl._steps` verbatim so
/// pre-load frames match loaded frames; the view subscribes to no bloc state
/// (the route-level `BlocProvider` in `onboarding_routes.dart` owns the
/// `OnboardingBloc` and its `watchItems()` subscription). Pager index is
/// ephemeral UI state owned here (`_page` + `PageController`).
class ValueTourView extends StatefulWidget {
  const ValueTourView({super.key});

  @override
  State<ValueTourView> createState() => _ValueTourViewState();
}

class _ValueTourViewState extends State<ValueTourView> {
  /// Design left inset of the first card (`.pg-card.c1 left 20`).
  static const double _pagerInsetLeft = 20;

  /// Card width clamp (`min(310, max(240, viewportW - 80))` per 1_plan §a:
  /// 390dp → 310; 320dp → 240; 430dp → 310).
  static const double _cardMaxW = 310;
  static const double _cardMinW = 240;
  static const double _cardSlack = 80;

  /// Inter-card gap (c2 left 342 = 20 + 310 + 12).
  static const double _cardGap = 12;

  /// Pager base height.
  ///
  /// 1_plan §a specifies `400 × ts` (design `.pager` 400), which assumes
  /// compact rows of 56px. `NestListRow` compact rows really are 60px (56
  /// min-height, but the 22px title + 18px subtitle lines plus 20px of row
  /// padding win), so card 1 needs 444px even before two further measured
  /// facts: (a) `Container` folds a decoration border into its effective
  /// padding, so the 1.5px-bordered chips are 35px, not 32 (+3); (b) under
  /// the widget-test fallback font the 26-char caption wraps to two lines
  /// (+18). Tallest measured content is 465px; the base grows 400 → 468 to
  /// fit it with 3px to spare. All plan spacings and components are kept;
  /// cards 2–3 absorb the extra via their `Spacer` (HTML `margin-top:
  /// auto`). The whole screen still fits 390×844 (the scroll region absorbs
  /// 3px of its bottom padding).
  static const double _pagerBaseH = 468;

  /// Below-pager rhythm (`.scroll > .pg-dots margin-top 22`, `.pg-title`
  /// margin-top 30, `.pg-body` margin-top 12).
  static const double _dotsTop = 22;
  static const double _titleGap = 30;

  /// Step copy, verbatim from `OnboardingRepositoryImpl._steps`.
  static const List<({String title, String detail})> _steps = [
    (
      title: 'Set quests in seconds',
      detail:
          "Pick from 40+ ready-made jobs like 'Put the bins out' or make "
          'your own.',
    ),
    (
      title: 'Pip grows as they help',
      detail: 'Every finished quest feeds Pip the bird, from egg to songbird.',
    ),
    (
      title: 'Pocket money, sorted',
      detail: 'No bank card needed — we keep score, you pay your way.',
    ),
  ];

  int _page = 0;
  PageController? _controller;
  double _fraction = 0;
  double _cardW = _cardMaxW;

  /// Card width and pitch for a full-bleed pager on a [screenW]-wide canvas.
  static double _cardWidthFor(double screenW) =>
      math.min(_cardMaxW, math.max(_cardMinW, screenW - _cardSlack));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The pager is full-bleed, so the MediaQuery width is the LayoutBuilder
    // width 1_plan §a derives `viewportW` from. The PageView itself sits
    // inside the 20px left inset (PageView has no padding slot), so the
    // controller fraction divides by the inset viewport: cards still span
    // 20 + pitch·i … + cardW exactly as planned.
    final screenW = MediaQuery.sizeOf(context).width;
    final cardW = _cardWidthFor(screenW);
    final fraction = (cardW + _cardGap) / (screenW - _pagerInsetLeft);
    if (_controller == null || (_fraction - fraction).abs() > 0.0001) {
      _fraction = fraction;
      _cardW = cardW;
      final old = _controller;
      _controller = PageController(
        viewportFraction: fraction,
        initialPage: _page,
      );
      old?.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _skip() => context.go(AuthRoutePaths.createAccount);

  void _goTo(int page) {
    final target = page.clamp(0, _steps.length - 1);
    final controller = _controller;
    if (controller == null || !controller.hasClients) {
      setState(() => _page = target);
      return;
    }
    // RULES §6 still-frame rule: jump when animations are disabled.
    final reduce =
        (MediaQuery.maybeOf(context)?.disableAnimations ?? false) ||
        kDisableAnimations;
    if (reduce) {
      controller.jumpToPage(target);
    } else {
      controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawScale = MediaQuery.textScalerOf(context).scale(100) / 100;
    final ts = rawScale.clamp(1.0, 1.3);
    final pagerH = _pagerBaseH * ts;
    final step = _steps[_page];
    return Scaffold(
      body: Column(
        children: <Widget>[
          const NestStatusBar(),
          _TourNav(onSkip: _skip),
          Semantics(
            label: 'Tour preview, step ${_page + 1} of ${_steps.length}',
            container: true,
            child: Padding(
              padding: const EdgeInsets.only(left: _pagerInsetLeft),
              child: SizedBox(
                height: pagerH,
                child: PageView.builder(
                  controller: _controller,
                  padEnds: false,
                  // Viewport edge clipping is PageView's default
                  // (Clip.hardEdge), matching the design's clipped peek.
                  itemCount: _steps.length,
                  onPageChanged: (index) => setState(() => _page = index),
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(right: _cardGap),
                    child: SizedBox(
                      width: _cardW,
                      height: pagerH,
                      child: const <Widget>[
                        _QuestPreviewCard(),
                        _PipPreviewCard(),
                        _JarPreviewCard(),
                      ][index],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                NestSpacing.padSide,
                0,
                NestSpacing.padSide,
                NestSpacing.s8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: _dotsTop),
                  NestPagerDots(count: _steps.length, index: _page),
                  const SizedBox(height: _titleGap),
                  Semantics(
                    header: true,
                    child: Text(step.title, style: context.nestText.h1),
                  ),
                  const SizedBox(height: NestSpacing.s3),
                  Text(
                    step.detail,
                    style: NestType.body(color: context.nest.ink2),
                  ),
                ],
              ),
            ),
          ),
          NestBottomCta(
            child: _page < _steps.length - 1
                ? NestButton(
                    key: const ValueKey('p02_next'),
                    label: 'Next',
                    onPressed: () => _goTo(_page + 1),
                  )
                : NestButton(
                    key: const ValueKey('p02_continue'),
                    label: 'Continue',
                    onPressed: _skip,
                  ),
          ),
          const NestHomeIndicator(),
        ],
      ),
    );
  }
}

/// Tour header: right-aligned Skip (1_plan §g).
//
// TODO(P02): `NestNavBar` compact traps the trailing action in a fixed 44px
// slot, so this feature-private 52px bar ships until the shared wide-action
// fix lands (see `docs/screens/P02/SHARED_REQUEST.md`).
class _TourNav extends StatelessWidget {
  const _TourNav({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Padding(
        padding: const EdgeInsets.only(right: NestSpacing.padSide),
        child: Row(
          children: <Widget>[
            const Expanded(child: SizedBox.shrink()),
            Semantics(
              key: const ValueKey('p02_skip'),
              button: true,
              container: true,
              label: 'Skip',
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: NestDevice.tapParent,
                  minHeight: NestDevice.tapParent,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onSkip,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: NestSpacing.s3,
                    ),
                    child: Center(
                      // Announced by the labeled button node above; keeping
                      // the raw text out of the tree avoids a 'Skip\nSkip'
                      // merge (sibling text always folds into the nearest
                      // actionless ancestor).
                      child: ExcludeSemantics(
                        child: Text(
                          'Skip',
                          style: NestType.buttonLabel(color: context.nest.leaf),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card 1 — "Today's quests" (static preview consts per 1_plan §a).
class _QuestPreviewCard extends StatelessWidget {
  const _QuestPreviewCard();

  /// Preview rows: icon, tile tint, title, subtitle, coin amount.
  static const List<
    ({String asset, NestTileTint tint, String title, String sub, String coins})
  >
  _rows = [
    (
      asset: NestIcons.target,
      tint: NestTileTint.sky,
      title: 'Empty the dishwasher',
      sub: 'Maya · weekly',
      coins: '15',
    ),
    (
      asset: NestIcons.bin,
      tint: NestTileTint.coin,
      title: 'Put the bins out',
      sub: 'Leo · once',
      coins: '15',
    ),
    (
      asset: NestIcons.bookOpen,
      tint: NestTileTint.lilac,
      title: 'Reading – 20 minutes',
      sub: 'Maya · daily',
      coins: '10',
    ),
    (
      asset: NestIcons.bed,
      tint: NestTileTint.peach,
      title: 'Tidy your bedroom',
      sub: 'Maya · weekly',
      coins: '15',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return NestCard(
      padding: const EdgeInsets.all(NestSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            spacing: NestSpacing.s2,
            children: <Widget>[
              Expanded(
                child: Text(
                  "Today's quests",
                  style: context.nestText.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const NestChip(label: 'Sat 4 Oct'),
            ],
          ),
          const SizedBox(height: NestSpacing.gap14),
          Column(
            spacing: NestSpacing.s3,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final row in _rows)
                NestListRow(
                  compact: true,
                  title: row.title,
                  subtitle: row.sub,
                  leadingAsset: row.asset,
                  tint: row.tint,
                  trailing: NestCoinPill(
                    amount: row.coins,
                    size: NestCoinPillSize.small,
                  ),
                ),
            ],
          ),
          const SizedBox(height: NestSpacing.gap14),
          const NestProgress(fraction: 4 / 6),
          const SizedBox(height: NestSpacing.gap6),
          Text('4 of 6 quests done today', style: context.nestText.caption),
          const Spacer(),
          const _DashedAddRow(iconAsset: NestIcons.plus, label: 'New quest'),
        ],
      ),
    );
  }
}

/// Card 2 — "Pip's nest" (mochi/sunny at the design's stage per the
/// orchestrator Pip rule: onboarding screens use the fledgling stage 3).
class _PipPreviewCard extends StatelessWidget {
  const _PipPreviewCard();

  /// Stage-dot visuals (`.pg-stage` 52, art 40).
  static const double _dotD = 52;
  static const double _artD = 40;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      padding: const EdgeInsets.all(NestSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            spacing: NestSpacing.s2,
            children: <Widget>[
              Expanded(
                child: Text(
                  "Pip's nest",
                  style: context.nestText.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const NestChip(label: 'Fledgling', selected: true),
            ],
          ),
          const SizedBox(height: NestSpacing.gap10),
          Center(
            child: Semantics(
              label: 'Pip the fledgling bird',
              image: true,
              container: true,
              child: const SizedBox.square(
                dimension: 158,
                child: PipAvatar(style: PipStyle.mochi, stage: 3),
              ),
            ),
          ),
          Text('Fledgling', style: context.nestText.h2),
          const NestProgress(fraction: 0.7),
          const SizedBox(height: NestSpacing.gap6),
          Text(
            '175 of 250 coins · Pip evolves at 250',
            style: context.nestText.caption,
          ),
          const SizedBox(height: NestSpacing.gap10),
          ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                for (var stage = 1; stage <= 3; stage++)
                  _StageDot(stage: stage, selected: stage == 3),
              ],
            ),
          ),
          const Spacer(),
          const _DashedAddRow(
            iconAsset: NestIcons.plus,
            label: 'Next stage: Songbird',
          ),
        ],
      ),
    );
  }
}

/// Decorative evolution stage dot (excluded from semantics by the parent).
class _StageDot extends StatelessWidget {
  const _StageDot({required this.stage, required this.selected});

  final int stage;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _PipPreviewCard._dotD,
      height: _PipPreviewCard._dotD,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? context.nest.leafTint : context.nest.lilacTint,
      ),
      child: PipAvatar(
        style: PipStyle.mochi,
        stage: stage,
        size: _PipPreviewCard._artD,
      ),
    );
  }
}

/// Card 3 — "Maya's jar" (static consts matching `Seed.demo`: base £3.00 +
/// quests £1.20).
class _JarPreviewCard extends StatelessWidget {
  const _JarPreviewCard();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return NestCard(
      padding: const EdgeInsets.all(NestSpacing.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            spacing: NestSpacing.s2,
            children: <Widget>[
              Expanded(
                child: Text(
                  "Maya's jar",
                  style: context.nestText.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const NestChip(label: 'Sat 4 Oct'),
            ],
          ),
          const SizedBox(height: NestSpacing.gap14),
          NestMoney(amount: 4.2, style: NestType.h1(color: tokens.ink)),
          const SizedBox(height: NestSpacing.gap2),
          Text(
            'coming on Saturday',
            style: NestType.bodySmall(color: tokens.ink2),
          ),
          const SizedBox(height: NestSpacing.s4),
          const _LedgerLine(label: 'Weekly base', amount: '£3.00'),
          const _LedgerLine(label: 'Quests (120 coins)', amount: '+£1.20'),
          Container(
            margin: const EdgeInsets.only(top: NestSpacing.s1),
            padding: const EdgeInsets.only(top: NestSpacing.gap6),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: tokens.line)),
            ),
            child: const _LedgerLine(
              label: 'Total',
              amount: '£4.20',
              total: true,
            ),
          ),
          const Spacer(),
          const _DashedAddRow(
            iconAsset: NestIcons.money,
            label: 'No bank card needed',
          ),
        ],
      ),
    );
  }
}

/// One ledger line (`.pg-line`: 15px rows, min-height 32, space-between;
/// tabular amounts via `NestType.money`).
class _LedgerLine extends StatelessWidget {
  const _LedgerLine({
    required this.label,
    required this.amount,
    this.total = false,
  });

  final String label;
  final String amount;
  final bool total;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: NestSpacing.s2,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: total
                  ? NestType.bodySmallStrong(color: tokens.ink)
                  : NestType.bodySmall(color: tokens.ink2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            amount,
            style: NestType.money(color: total ? tokens.ink : tokens.ink2),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Dashed preview add-row (`.pv-add`: min-height 44, r-m 16, 1.5px dashed
/// `line` border, 15 w600 ink2). Non-interactive.
class _DashedAddRow extends StatelessWidget {
  const _DashedAddRow({required this.iconAsset, required this.label});

  final String iconAsset;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return ExcludeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: NestDevice.tapParent),
        child: CustomPaint(
          painter: _DashedBorder(color: tokens.line, radius: NestRadii.m),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: NestSpacing.s3,
                vertical: NestSpacing.gap10,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: NestSpacing.s2,
                children: <Widget>[
                  NestIcon(iconAsset, size: 20, color: tokens.ink2),
                  Flexible(
                    child: Text(
                      label,
                      style: NestType.bodySmallStrong(color: tokens.ink2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 1.5px dashed rounded-rectangle border.
class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeW = 1.5;
    const dashW = 6.0;
    const gapW = 4.0;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(strokeW / 2),
          Radius.circular(radius),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    for (final metric in path.computeMetrics()) {
      var start = 0.0;
      while (start < metric.length) {
        final end = math.min(start + dashW, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        start += dashW + gapW;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorder oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
