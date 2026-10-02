import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nestling/core/design_system/assets/nestling_assets.dart'
    as nest_assets;
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_bloc.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_event.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_state.dart';
import 'package:nestling/features/kid_home/presentation/widgets/kid_status_chip.dart';
import 'package:nestling/features/kid_jar/kid_jar_routes.dart';
import 'package:nestling/features/kid_shop/kid_shop_routes.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';
import 'package:nestling/features/pip/pip_routes.dart';

NestAvatarColor _avatarColor(String raw) {
  return switch (raw) {
    'lilac' => NestAvatarColor.lilac,
    'peach' => NestAvatarColor.peach,
    'sky' => NestAvatarColor.sky,
    'leaf' => NestAvatarColor.leaf,
    'coin' => NestAvatarColor.coin,
    _ => NestAvatarColor.neutral,
  };
}

/// The child's own Pip look from the database (ORCHESTRATOR_NOTES #1).
PipStyle _pipStyle(String raw) {
  return switch (raw) {
    'bolt' => PipStyle.bolt,
    'storybook' => PipStyle.storybook,
    _ => PipStyle.mochi,
  };
}

PipSkin _pipSkin(String raw) {
  return switch (raw) {
    'sky' => PipSkin.sky,
    'berry' => PipSkin.berry,
    'mint' => PipSkin.mint,
    _ => PipSkin.sunny,
  };
}

PipAccessory _pipAccessory(String raw) {
  return switch (raw) {
    'bow' => PipAccessory.bow,
    'cap' => PipAccessory.cap,
    'scarf' => PipAccessory.scarf,
    'glasses' => PipAccessory.glasses,
    _ => PipAccessory.none,
  };
}

/// Icon tile glyph per `KidQuest.icon` (K03 glyph per `nestling_assets.dart`).
String _iconFor(String raw) {
  return switch (raw) {
    'dishwasher' => NestIcons.dishwasher,
    'book' => NestIcons.book,
    'bed' => NestIcons.bedSit,
    'bins' => NestIcons.bin,
    'hoover' => NestIcons.hoover,
    'plate' => NestIcons.table,
    'table' => NestIcons.table,
    _ => NestIcons.questCard,
  };
}

bool _isDone(KidQuest item) =>
    item.status == 'approved' || item.status == 'done_pending';

/// Card-level status text for the `{title}, {status text}` semantics label.
String _statusText(KidQuest item) {
  return switch (item.status) {
    'done_pending' => 'Waiting for Mum\u2019s thumbs-up',
    'approved' => 'Done',
    _ => 'To do',
  };
}

/// K03 Kid home (`/kid-home`): greeting header, Pip stage, happiness hearts,
/// today's quests with live counts, and the Pip/Shop/My jar dock.
class KidHomeView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    // Celebration navigation is driven by success (K03-BUG-2): the bloc
    // emits `justCompletedQuestId` only after the write saves, so a failed
    // tap keeps the list and shows the SnackBar instead of celebrating.
    return BlocListener<KidHomeBloc, KidHomeState>(
      listenWhen: (previous, current) =>
          previous.justCompletedQuestId != current.justCompletedQuestId &&
          current.justCompletedQuestId != null,
      listener: (context, state) {
        final child = state.child;
        if (child == null) return;
        unawaited(
          context.push(
            KidHomeRoutePaths.complete,
            extra: <String, Object>{
              'questId': state.justCompletedQuestId!,
              'childId': child.id,
              'coins': state.justCompletedCoins ?? 0,
            },
          ),
        );
      },
      child: BlocListener<KidHomeBloc, KidHomeState>(
        listenWhen: (previous, current) =>
            (previous.actionError != current.actionError ||
                previous.actionNonce != current.actionNonce) &&
            current.actionError != null,
        listener: (context, state) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hmm, that did not work. Try again.')),
          );
        },
        child: BlocBuilder<KidHomeBloc, KidHomeState>(
          builder: (context, state) {
            switch (state.status) {
              case KidHomeStatus.initial:
              case KidHomeStatus.loading:
                return const _KidLoading();
              case KidHomeStatus.failure:
                return const _KidFailure();
              case KidHomeStatus.loaded:
                final child = state.child;
                if (child == null) {
                  return const _NoActiveChild();
                }
                return _KidHomeBody(child: child, state: state);
            }
          },
        ),
      ),
    );
  }
}

class _KidLoading extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            Expanded(
              child: Center(
                child: Semantics(
                  label: 'Loading your quests',
                  child: CircularProgressIndicator(color: tokens.leaf),
                ),
              ),
            ),
            const NestHomeIndicator(),
          ],
        ),
      ),
    );
  }
}

class _KidFailure extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NestSpacing.padSide,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: NestSpacing.s2,
                    children: [
                      // No child is known here, so the neutral look
                      // (orchestrator rule for childless screens).
                      const PipAvatar(
                        style: PipStyle.mochi,
                        stage: 1,
                        size: 140,
                      ),
                      Text(
                        'Oh no! Pip got lost.',
                        style: NestType.h2(color: tokens.ink),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Let\u2019s try again.',
                        style: NestType.bodySmall(color: tokens.ink2),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: NestSpacing.s1),
                      NestKidButton(
                        label: 'Try again',
                        color: NestKidButtonColor.white,
                        fullWidth: false,
                        onPressed: () => context.read<KidHomeBloc>().add(
                          const KidHomeLoadRequested(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const NestHomeIndicator(),
          ],
        ),
      ),
    );
  }
}

class _NoActiveChild extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: NestSpacing.s3,
                  children: [
                    Text(
                      'Who\u2019s playing?',
                      style: NestType.h2(color: tokens.ink),
                      textAlign: TextAlign.center,
                    ),
                    NestKidButton(
                      label: 'Choose',
                      color: NestKidButtonColor.lilac,
                      fullWidth: false,
                      onPressed: () => context.go(KidHomeRoutePaths.picker),
                    ),
                  ],
                ),
              ),
            ),
            const NestHomeIndicator(),
          ],
        ),
      ),
    );
  }
}

class _KidHomeBody extends StatelessWidget {
  const new({required this.child, required this.state});

  final KidChild child;
  final KidHomeState state;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final nickname = child.nickname;
    final initial = nickname.isEmpty ? '?' : nickname[0].toUpperCase();
    final done = state.doneCount;
    final total = state.totalCount;
    final filledHearts = child.happiness.clamp(0, 5);
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NestSpacing.padSide,
                NestSpacing.s1,
                NestSpacing.padSide,
                NestSpacing.gap10,
              ),
              child: Row(
                spacing: NestSpacing.s2,
                children: [
                  NestAvatar(
                    initial: initial,
                    size: NestAvatarSize.s64,
                    color: _avatarColor(child.avatarColour),
                  ),
                  Expanded(
                    child: Semantics(
                      label: 'Hi $nickname, $done done today',
                      excludeSemantics: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Hi $nickname!',
                            // Screen-exact `.k3-name`: Nunito 22/26 w900 ink.
                            style: GoogleFonts.nunito(
                              fontSize: 22,
                              height: 26 / 22,
                              fontWeight: FontWeight.w900,
                              color: tokens.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$done done today',
                            // Screen-exact `.k3-sub`: Nunito 15/20 w700 ink2.
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              height: 20 / 15,
                              fontWeight: FontWeight.w700,
                              color: tokens.ink2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  NestCoinPill(amount: '${child.coins}'),
                  const _GateLockButton(),
                ],
              ),
            ),
            Expanded(
              child: state.items.isEmpty
                  ? _KidEmptyQuests(child: child)
                  : ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: NestSpacing.padSide,
                          ),
                          child: _KidPetStage(child: child),
                        ),
                        const SizedBox(height: NestSpacing.s4),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: NestSpacing.padSide,
                          ),
                          child: Semantics(
                            image: true,
                            label:
                                'Pip is happy today, $filledHearts of 5 hearts',
                            excludeSemantics: true,
                            child: Row(
                              spacing: NestSpacing.s2,
                              children: [
                                for (var i = 0; i < 5; i++)
                                  _HeartIcon(filled: i < filledHearts),
                                Flexible(
                                  child: Text(
                                    'Pip is happy today',
                                    // Screen-exact `.kcap`: Nunito 15/20 w700.
                                    style: GoogleFonts.nunito(
                                      fontSize: 15,
                                      height: 20 / 15,
                                      fontWeight: FontWeight.w700,
                                      color: tokens.ink2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: NestSpacing.s4),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: NestSpacing.padSide,
                          ),
                          child: Row(
                            spacing: NestSpacing.gap10,
                            children: [
                              Expanded(
                                child: Text(
                                  'Today\u2019s quests',
                                  style: NestType.kidTitle(color: tokens.ink),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              KidStatusChip(label: '$done of $total done'),
                            ],
                          ),
                        ),
                        const SizedBox(height: NestSpacing.s4),
                        // Meadow band behind progress + cards (FIXES_1 #1):
                        // in-flow full-bleed hill, so it scrolls with
                        // the content and needs no magic offsets. The tone
                        // is `kidHorizon`: pixel measurement of both design
                        // PNGs lands exactly on it (light #EAF7E2, dark
                        // within a few levels), while the shared KidScope
                        // hill (untouched) stays `kidMeadow`.
                        CustomPaint(
                          painter: _MeadowPainter(color: tokens.kidHorizon),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              NestSpacing.padSide,
                              NestSpacing.gap10,
                              NestSpacing.padSide,
                              NestSpacing.s8,
                            ),
                            child: Column(
                              spacing: NestSpacing.s4,
                              children: [
                                NestProgress(
                                  fraction: state.fraction,
                                  kid: true,
                                  semanticLabel:
                                      '$done of $total of today\u2019s quests done',
                                ),
                                Column(
                                  spacing: NestSpacing.s3,
                                  children: [
                                    for (final item in state.items)
                                      _QuestCard(
                                        child: child,
                                        item: item,
                                        completionToken: state.actionNonce,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            // Bottom edge (owner rule, K03-BUG-10): the bar's own surface
            // runs to the physical screen edge — the `SafeArea` inset sits
            // INSIDE the surface box (same pattern as the shared
            // `NestBottomCta` on main), so no meadow/sky strip shows
            // under the dock. Buttons stay above the inset; the OS draws
            // the home pill. This supersedes the meadow-to-the-edge half of
            // ORCHESTRATOR_NOTES #8 (the inset half still holds).
            Container(
              decoration: BoxDecoration(
                color: tokens.surface,
                border: Border(top: BorderSide(color: tokens.ink, width: 3)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        NestSpacing.padSide,
                        NestSpacing.s3,
                        NestSpacing.padSide,
                        NestSpacing.gap10,
                      ),
                      child: Row(
                        spacing: NestSpacing.s3,
                        children: [
                          Expanded(
                            child: NestKidButton(
                              label: 'Pip',
                              color: NestKidButtonColor.lilac,
                              icon: NestIcon(
                                NestIcons.pipFace,
                                color: tokens.onAccent,
                              ),
                              axis: Axis.vertical,
                              gap: NestSpacing.s1,
                              minHeight: 66,
                              fontSize: 17,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: NestSpacing.gap6,
                              ),
                              onPressed: () => context.go(PipRoutePaths.nest),
                            ),
                          ),
                          Expanded(
                            child: NestKidButton(
                              label: 'Shop',
                              color: NestKidButtonColor.coin,
                              icon: NestIcon(
                                NestIcons.bag,
                                color: tokens.onWarm,
                              ),
                              axis: Axis.vertical,
                              gap: NestSpacing.s1,
                              minHeight: 66,
                              fontSize: 17,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: NestSpacing.gap6,
                              ),
                              onPressed: () =>
                                  context.go(KidShopRoutePaths.shop),
                            ),
                          ),
                          Expanded(
                            child: NestKidButton(
                              label: 'My jar',
                              icon: NestIcon(
                                NestIcons.jar,
                                color: tokens.onLeaf,
                              ),
                              axis: Axis.vertical,
                              gap: NestSpacing.s1,
                              minHeight: 66,
                              fontSize: 17,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: NestSpacing.gap6,
                              ),
                              onPressed: () => context.go(KidJarRoutePaths.jar),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const NestHomeIndicator(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Parental-gate lock with a tap guard (K03-BUG-9): only one gate route
/// per gesture burst, even on a fast double tap.
class _GateLockButton extends StatefulWidget {
  const new();

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
    return NestLockButton(semanticLabel: 'Grown-ups', onPressed: _open);
  }
}

/// Pet stage: speech bubble over the child's own Pip on the nest.
/// Geometry follows the HTML `.k3-pet` slot: 260x236 box, nest art filling
/// it, Pip 152 tall with its feet 96 from the nest bottom (so Pip overlaps
/// 12 above the box — the stack is unclipped). The nest SVG's visible rim
/// starts ~40% down the art, which lands the rim at nest top + ~94.
class _KidPetStage extends StatelessWidget {
  const new({required this.child});

  final KidChild child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _SpeechBubble(text: 'Let\u2019s do some quests!'),
        const SizedBox(height: NestSpacing.gap14),
        Semantics(
          image: true,
          label: 'Pip in the nest',
          child: SizedBox(
            width: 260,
            height: 236,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  nest_assets.NestlingIllustrations.nest,
                  width: 260,
                  height: 236,
                  fit: BoxFit.fill,
                  placeholderBuilder: (_) => const SizedBox.shrink(),
                ),
                Positioned(
                  left: 54,
                  bottom: 96,
                  child: PipAvatar(
                    style: _pipStyle(child.pipStyle),
                    stage: child.pipStage.clamp(1, 4),
                    skin: _pipSkin(child.pipSkin),
                    accessory: _pipAccessory(child.pipAccessory),
                    size: 152,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Speech bubble (`.speech` in K03-kid-home.html): surface, 3px ink border,
/// r18, padding 8x14, Nunito 16/24 w800, maxW 260 + tail.
class _SpeechBubble extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 260),
          padding: const EdgeInsets.symmetric(
            horizontal: NestSpacing.gap14,
            vertical: NestSpacing.s2,
          ),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: tokens.ink,
              width: context.nestKid.borderWidth,
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.nunito(
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.w800,
              color: tokens.ink,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        CustomPaint(
          painter: _TailPainter(
            inkColor: tokens.ink,
            fillColor: tokens.surface,
          ),
          size: const Size(18, 10),
        ),
      ],
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter({required this.inkColor, required this.fillColor});

  final Color inkColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final inkPaint = Paint()..color = inkColor;
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(18, 0)
        ..lineTo(9, 10)
        ..close(),
      inkPaint,
    );
    final fillPaint = Paint()..color = fillColor;
    canvas.drawPath(
      Path()
        ..moveTo(3.5, 0)
        ..lineTo(14.5, 0)
        ..lineTo(9, 6.5)
        ..close(),
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TailPainter oldDelegate) =>
      oldDelegate.inkColor != inkColor || oldDelegate.fillColor != fillColor;
}

/// Happiness heart (FIXES_1 #5): the `ic_heart` asset bakes fill and stroke
/// into one `currentColor`, so a single tint cannot render the HTML's coin
/// fill + 2px ink-2 stroke. Painted locally from the same 24-space path
/// with token colours instead.
class _HeartIcon extends StatelessWidget {
  const new({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return ExcludeSemantics(
      child: CustomPaint(
        painter: _HeartPainter(
          fill: filled ? tokens.coin : tokens.surface2,
          stroke: filled ? tokens.ink2 : tokens.ink3,
        ),
        size: const Size(26, 26),
      ),
    );
  }
}

class _HeartPainter extends CustomPainter {
  const _HeartPainter({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  static Path _path(double s) {
    return Path()
      ..moveTo(12 * s, 20.4 * s)
      ..lineTo(4.9 * s, 13.4 * s)
      ..arcToPoint(Offset(11.3 * s, 7 * s), radius: Radius.circular(4.5 * s))
      ..lineTo(12 * s, 7.7 * s)
      ..lineTo(12.7 * s, 7 * s)
      ..arcToPoint(Offset(19.1 * s, 13.4 * s), radius: Radius.circular(4.5 * s))
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final path = _path(s);
    final fillPaint = Paint()..color = fill;
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas
      ..drawPath(path, fillPaint)
      ..drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _HeartPainter oldDelegate) =>
      oldDelegate.fill != fill || oldDelegate.stroke != stroke;
}

/// Tall meadow band behind progress + cards (FIXES_1 #1). The shared
/// `KidScope` hill is only 136px at the very bottom, while the design shows
/// green from just below the section row; this in-flow full-bleed panel
/// paints the hill behind the scroll content. The tone is `kidHorizon`:
/// pixel measurement of both design PNGs lands on it, while the shared
/// hill (untouched) stays `kidMeadow`.
class _MeadowPainter extends CustomPainter {
  const _MeadowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(0, 24)
        ..quadraticBezierTo(w * 0.45, 2, w, 20)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _MeadowPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _QuestCard extends StatefulWidget {
  const new({
    required this.child,
    required this.item,
    required this.completionToken,
  });

  final KidChild child;
  final KidQuest item;

  /// Bumps whenever a completion fails; resets the tap guard so a retry is
  /// possible after an error (the success path resets via the status flip).
  final int completionToken;

  @override
  State<_QuestCard> createState() => _QuestCardState();
}

class _QuestCardState extends State<_QuestCard> {
  /// Tap guard (K03-BUG-1/6): only one event + one route per gesture burst,
  /// even before the stream round-trips.
  bool _busy = false;

  @override
  void didUpdateWidget(covariant _QuestCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.status != oldWidget.item.status ||
        widget.completionToken != oldWidget.completionToken) {
      _busy = false;
    }
  }

  void _complete() {
    if (_busy) return;
    setState(() => _busy = true);
    context.read<KidHomeBloc>().add(
      KidHomeQuestCompleted(
        childId: widget.child.id,
        questId: widget.item.questId,
        coins: widget.item.coins,
      ),
    );
  }

  Future<void> _openDetail() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context.push(
        KidHomeRoutePaths.detail,
        extra: <String, Object>{
          'questId': widget.item.questId,
          'childId': widget.child.id,
        },
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final done = _isDone(widget.item);
    return NestKidQuestCard(
      title: widget.item.title,
      icon: NestIcon(_iconFor(widget.item.icon), size: 28, color: tokens.ink),
      coinAmount: done ? null : '+${widget.item.coins}',
      metaChip: done
          ? KidStatusChip(
              label: widget.item.status == 'done_pending'
                  ? 'Waiting for Mum'
                  : 'Done',
            )
          : null,
      done: done,
      // Pending/approved checks are display-only; only `to_do` taps complete.
      onToggled: done ? null : (_) => _complete(),
      onTap: _openDetail,
      semanticLabel: '${widget.item.title}, ${_statusText(widget.item)}',
    );
  }
}

class _KidEmptyQuests extends StatelessWidget {
  const new({required this.child});

  final KidChild child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        0,
        NestSpacing.padSide,
        NestSpacing.s8,
      ),
      children: [
        NestEmptyState(
          art: PipAvatar(
            style: _pipStyle(child.pipStyle),
            stage: child.pipStage.clamp(1, 4),
            skin: _pipSkin(child.pipSkin),
            accessory: _pipAccessory(child.pipAccessory),
            size: 120,
          ),
          title: 'No quests today',
          message: 'Enjoy playing with Pip!',
        ),
      ],
    );
  }
}
