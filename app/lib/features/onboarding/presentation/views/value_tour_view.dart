import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/data/env_flags.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/auth/auth_routes.dart';
import 'package:nestling/features/onboarding/onboarding_routes.dart';
import 'package:nestling/features/onboarding/presentation/widgets/value_tour_preview_row.dart';

/// P02 Value tour — parent-mode marketing pager at `/value-tour`.
///
/// Static marketing screen (same pattern as P01 `WelcomeView`): three tour
/// cards in a clipped horizontal pager + dots + per-page title/body + a fixed
/// bottom CTA. The step copy mirrors `OnboardingRepositoryImpl._steps`
/// verbatim so pre-load frames match loaded frames; the view subscribes to no
/// bloc state (the route-level `BlocProvider` in `onboarding_routes.dart`
/// owns the `OnboardingBloc` and its `watchItems()` subscription). Pager index
/// is ephemeral UI state owned here (`_page` + `PageController`).
class ValueTourView extends StatefulWidget {
  const ValueTourView({super.key});

  @override
  State<ValueTourView> createState() => _ValueTourViewState();
}

/// Head-chip width cap: content wider than this scales down instead of
/// overflowing narrow screens (SPACING_SPEC §10.3 scaleDown precedent for
/// tight chips). Above the cap nothing changes — the box shrink-wraps —
/// so design sizes render exactly as before.
const double _chipMaxW = 180;

/// Date/status chip for the card heads (`.chip` 32px).
Widget _headChip(String label, {bool selected = false}) {
  return ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: _chipMaxW),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: NestChip(label: label, selected: selected),
    ),
  );
}

/// Date chip: the design's static `Sat 4 Oct` (ORCHESTRATOR_NOTES 1 — the
/// tour is a marketing illustration, so the design copy is mandatory, not
/// the database).
const String _dateChipLabel = 'Sat 4 Oct';

class _ValueTourViewState extends State<ValueTourView> {
  /// Design left inset of the first card (`.pg-card.c1 left 20`, same 20px
  /// screen gutter used everywhere on this screen).
  static const double _pagerInsetLeft = NestSpacing.padSide;

  /// Card width clamp (`min(310, max(240, viewportW - 80))` per 1_plan §a:
  /// 390dp → 310; 320dp → 240; 430dp → 310).
  static const double _cardMaxW = 310;
  static const double _cardMinW = 240;
  static const double _cardSlack = 80;

  /// Inter-card gap (c2 left 342 = 20 + 310 + 12).
  static const double _cardGap = 12;

  /// Pager base height: the design's `.pager` 400 (SPACING_SPEC §7), scaled
  /// by the clamped text scaler. Card 1 fits because its preview rows use
  /// the feature-private `ValueTourPreviewRow` at the design's 38dp
  /// `.pv-row` metrics (see that widget and `SHARED_REQUEST.md`); cards 2–3
  /// absorb slack via their `Spacer` (HTML `margin-top: auto`).
  static const double _pagerBaseH = 400;

  /// Below-pager rhythm (`.scroll > .pg-dots margin-top 22`, `.pg-title`
  /// margin-top 30, `.pg-body` margin-top 12).
  static const double _dotsTop = 22;
  static const double _titleGap = 30;

  /// Step copy, verbatim from `OnboardingRepositoryImpl._steps` (which mirrors
  /// the design's typographic punctuation per ORCHESTRATOR_NOTES 2).
  static const List<({String title, String detail})> _steps = [
    (
      title: 'Set quests in seconds',
      detail:
          'Pick from 40+ ready-made jobs like “Put the bins out” — or make '
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

  /// System back returns to `/welcome` (1_plan §c). P01 reaches the tour
  /// with `context.go`, so no `/welcome` sits below us on the stack — the
  /// pop is vetoed and re-routed instead. (Pushing from P01 was considered
  /// instead, but `push` routes through the engine echo and never lands in
  /// widget tests, so the BUG-6 proof could not observe it.)
  void _onSystemBack(bool didPop, Object? result) {
    if (!didPop && context.mounted) {
      context.go(OnboardingRoutePaths.welcome);
    }
  }

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
      // Retargetable: a second tap mid-animation heads for the same page
      // instead of skipping one (`nextPage` would advance from the current
      // offset).
      controller.animateToPage(
        target,
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
    // Pager + step copy share one scrollable (P02-BUG-3): fixed chrome is
    // only status + nav + CTA, so short screens scroll instead of
    // overflowing. At 390×844 the content is shorter than the viewport, so
    // every y matches the fixed-stack layout pixel-for-pixel.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onSystemBack,
      child: Scaffold(
        body: Column(
          children: <Widget>[
            const NestStatusBar(),
            // Shared compact bar: 4 + 44 + 12 = 60 with a content-sized
            // trailing slot. The outer 8px puts Skip on the 20px owner
            // gutter (the design nav inset is 12px, the cards/buttons sit
            // on 20px, and every right edge stays on the same gutter).
            Padding(
              padding: const EdgeInsets.only(right: NestSpacing.s2),
              child: NestNavBar(
                compact: true,
                actionLabel: 'Skip',
                onAction: _skip,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Semantics(
                      label:
                          'Tour preview, step ${_page + 1} of ${_steps.length}',
                      container: true,
                      child: Padding(
                        padding: const EdgeInsets.only(left: _pagerInsetLeft),
                        child: SizedBox(
                          height: pagerH,
                          child: PageView.builder(
                            controller: _controller,
                            padEnds: false,
                            // Viewport edge clipping is PageView's default
                            // (Clip.hardEdge), matching the design's clipped
                            // peek.
                            itemCount: _steps.length,
                            onPageChanged: (index) =>
                                setState(() => _page = index),
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
                    Padding(
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
                            child: NestBalancedText(
                              step.title,
                              style: context.nestText.h1,
                              textAlign: TextAlign.left,
                            ),
                          ),
                          const SizedBox(height: NestSpacing.s3),
                          Text(
                            step.detail,
                            style: NestType.body(color: context.nest.ink2),
                          ),
                        ],
                      ),
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
      ),
    );
  }
}

/// Card 1 — "Today's quests": the design's static illustration copy.
///
/// ORCHESTRATOR_NOTES 1 (mandatory) makes the design the spec for this
/// marketing illustration — the assignee/repeat strings below intentionally
/// mirror `P02-value-tour.html:72-88`, not `Seed.demo`.
class _QuestPreviewCard extends StatelessWidget {
  const _QuestPreviewCard();

  /// Preview rows: icon, tile tint, title, design subtitle, coin amount.
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            spacing: NestSpacing.s2,
            children: <Widget>[
              Expanded(
                child: Text(
                  'Today’s quests',
                  style: context.nestText.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _headChip(_dateChipLabel),
            ],
          ),
          const SizedBox(height: NestSpacing.gap14),
          Column(
            spacing: NestSpacing.s3,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              for (final row in _rows)
                ValueTourPreviewRow(
                  title: row.title,
                  subtitle: row.sub,
                  leadingAsset: row.asset,
                  tint: row.tint,
                  coins: row.coins,
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

  /// Stage-dot art: 40px Pip inside the 52px `NestPager.stage` circle (the
  /// only pager metric without a token; the rest come from `NestPager`).
  static const double _artD = 40;

  @override
  Widget build(BuildContext context) {
    return NestCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            spacing: NestSpacing.s2,
            children: <Widget>[
              Expanded(
                child: Text(
                  'Pip’s nest',
                  style: context.nestText.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _headChip('Fledgling', selected: true),
            ],
          ),
          const SizedBox(height: NestSpacing.gap10),
          Center(
            child: Semantics(
              label: 'Pip the fledgling bird',
              image: true,
              container: true,
              child: const SizedBox.square(
                dimension: NestPager.pet,
                child: PipAvatar(style: PipStyle.mochi, stage: 3),
              ),
            ),
          ),
          Text('Fledgling', style: context.nestText.h2),
          const NestProgress(fraction: 0.7),
          const SizedBox(height: NestSpacing.gap6),
          ValueTourFitText(
            text: '175 of 250 coins · Pip evolves at 250',
            style: context.nestText.caption,
          ),
          // 9dp, not the HTML 10: the bordered head chip (+3dp, shared
          // `NestChip` behaviour) leaves card 2 exactly 1dp over 400dp
          // otherwise — sub-perceptual, keeps the 158 Pip slot exact.
          const SizedBox(height: NestSpacing.gap9),
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
      width: NestPager.stage,
      height: NestPager.stage,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            spacing: NestSpacing.s2,
            children: <Widget>[
              Expanded(
                child: Text(
                  'Maya’s jar',
                  style: context.nestText.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _headChip(_dateChipLabel),
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

/// One ledger line (`.pg-line`: 15px rows, `NestPager.lineMinHeight`,
/// space-between; tabular amounts via `NestType.money`).
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
      constraints: const BoxConstraints(minHeight: NestPager.lineMinHeight),
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

/// Dashed preview add-row (`.pv-add`: `NestPager.addMinHeight`, r-m 16,
/// dashed `line` border per `NestPager.addDash*`, 15 w600 ink2).
/// Non-interactive, but the label stays a
/// plain-text semantics node (the HTML exposes it; the last one is a product
/// claim) while the leading icon is excluded as decorative.
class _DashedAddRow extends StatelessWidget {
  const _DashedAddRow({required this.iconAsset, required this.label});

  final String iconAsset;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: NestPager.addMinHeight),
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
                ExcludeSemantics(
                  child: NestIcon(iconAsset, size: 20, color: tokens.ink2),
                ),
                Flexible(
                  child: Semantics(
                    container: true,
                    child: Text(
                      label,
                      style: NestType.bodySmallStrong(color: tokens.ink2),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

/// Dashed rounded-rectangle border (`NestPager.addDash*` metrics).
class _DashedBorder extends CustomPainter {
  const _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeW = NestPager.addDashWidth;
    const dashW = NestPager.addDashLength;
    const gapW = NestPager.addDashGap;
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
