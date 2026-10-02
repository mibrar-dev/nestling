import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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

/// Design-slot numbers (review finding 2: single place to change, cited to
/// `.k3-pet` in `design/html-source/screens/K03-kid-home.html`):
/// Pip ≈152 px tall on the 260×236 nest. The shared `NestPetStage` scales
/// this cap by the available width, so the still frame keeps the slot
/// proportions at a smaller absolute size on 390 px screens.
const double _kPipSlotSize = 152;

/// v1 growth stage for the shared nest scene's feet-contact math, from the
/// DB integer (clamped: the suite probes 0 → egg and 9 → songbird).
PipStage _pipStage(int raw) {
  return switch (raw.clamp(1, 4)) {
    1 => PipStage.egg,
    2 => PipStage.hatchling,
    3 => PipStage.fledgling,
    _ => PipStage.songbird,
  };
}

/// Display name for the pet-stage semantics label (design alt text).
String _pipStageName(int stage) {
  return switch (stage) {
    1 => 'Egg',
    2 => 'Hatchling',
    4 => 'Songbird',
    _ => 'Fledgling',
  };
}

/// Meadow crest silhouette (review finding 2: single place to change).
/// Numbers cite the `.meadow` hill in
/// `design/html-source/screens/K03-kid-home.html`, flattened so the band
/// starts uniformly just above the progress bar like the design (green at
/// panel top, bar 4 px below it): the crest rises only a few px.
const double _kCrestLeftY = 6;
const double _kCrestBend = 0.5;
const double _kCrestControlY = 0;
const double _kCrestRightY = 5;

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
    'done_pending' => "Waiting for Mum's thumbs-up",
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
          // Design-system toast (review finding 7): token palette, floats
          // above the dock inset, and announces via a live region.
          showNestToast(context, 'Hmm, that did not work. Try again.');
        },
        child: BlocBuilder<KidHomeBloc, KidHomeState>(
          builder: (context, state) {
            switch (state.status) {
              case KidHomeStatus.initial:
              case KidHomeStatus.loading:
                return const _KidLoading();
              case KidHomeStatus.failure:
                return _KidFailure(child: state.child);
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
            // Parental gate on every kid screen (DESIGN_SPEC §5 Group C,
            // review finding 11), top-right like the loaded header.
            const Padding(
              padding: EdgeInsets.fromLTRB(
                NestSpacing.padSide,
                NestSpacing.s1,
                NestSpacing.padSide,
                0,
              ),
              child: Row(children: [Spacer(), _GateLockButton()]),
            ),
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
  const new({this.child});

  /// The last known child, when the stream failed after a load (review
  /// finding 9): the error card shows their own Pip, not a stranger's.
  final KidChild? child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final known = child;
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            // Parental gate on every kid screen (DESIGN_SPEC §5 Group C,
            // review finding 11), top-right like the loaded header.
            const Padding(
              padding: EdgeInsets.fromLTRB(
                NestSpacing.padSide,
                NestSpacing.s1,
                NestSpacing.padSide,
                0,
              ),
              child: Row(children: [Spacer(), _GateLockButton()]),
            ),
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
                      if (known != null)
                        PipAvatar(
                          style: _pipStyle(known.pipStyle),
                          stage: known.pipStage.clamp(1, 4),
                          skin: _pipSkin(known.pipSkin),
                          accessory: _pipAccessory(known.pipAccessory),
                          size: 140,
                        )
                      else
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
                        "Let's try again.",
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
            // Parental gate on every kid screen (DESIGN_SPEC §5 Group C,
            // review finding 11), top-right like the loaded header.
            const Padding(
              padding: EdgeInsets.fromLTRB(
                NestSpacing.padSide,
                NestSpacing.s1,
                NestSpacing.padSide,
                0,
              ),
              child: Row(children: [Spacer(), _GateLockButton()]),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: NestSpacing.s3,
                  children: [
                    Text(
                      "Who's playing?",
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
                                  NestHeart(filled: i < filledHearts),
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
                                  "Today's quests",
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
                                      "$done of $total of today's quests done",
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

/// Pet stage: the child's own Pip on the nest (review finding 1:
/// shared `NestPetStage` with a `PipAvatar` in its `pip:` slot — no local
/// scene fork). `pipSize: 152` is the design slot cap; the shared geometry
/// scales it by the available width (Pip ≈ 0.55 × nest), so on a 390 px
/// screen the still frame renders proportionally smaller — positions, not
/// pixels, are what carry over. `inNest` is intentionally omitted: it
/// defaults to false (lint forbids the redundant argument) and the custom
/// `pip:` path seats the avatar between the nest rims without the v1 Rive
/// artboard either way (inNest waiver: SHARED_REQUEST #8).
class _KidPetStage extends StatelessWidget {
  const new({required this.child});

  final KidChild child;

  @override
  Widget build(BuildContext context) {
    final stage = child.pipStage.clamp(1, 4);
    return NestPetStage(
      pip: PipAvatar(
        style: _pipStyle(child.pipStyle),
        stage: stage,
        skin: _pipSkin(child.pipSkin),
        accessory: _pipAccessory(child.pipAccessory),
      ),
      speech: "Let's do some quests!",
      pipSize: _kPipSlotSize,
      stage: _pipStage(stage),
      semanticLabel: 'Pip the ${_pipStageName(stage)}, stage $stage of 4',
    );
  }
}

/// Tall meadow band behind progress + cards (FIXES_1 #1).
// TODO(K03): replace with a `KidScope` meadow-band height/inset parameter
// once the design system owns one (SHARED_REQUEST #6) and delete this
// painter. The shared 136 px hill cannot cover the band: the design shows
/// green from just below the section row, so until the shared API exists
/// this in-flow full-bleed panel paints it. Tone is `kidHorizon` (pixel
/// measurement of both design PNGs lands on it); curve numbers below cite
/// the `.meadow` silhouette in `design/html-source/screens/K03-kid-home.html`.
class _MeadowPainter extends CustomPainter {
  const _MeadowPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
      Path()
        ..moveTo(0, _kCrestLeftY)
        ..quadraticBezierTo(w * _kCrestBend, _kCrestControlY, w, _kCrestRightY)
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
    // Release the latch on the next frame (K03-BUG-11): the bloc emits
    // nothing when a write lands without flipping (silent no-op), so a
    // state-driven reset would leave the check dead and unretryable.
    // Same-frame double taps are still blocked (no frame runs between
    // them); the idempotent repository guard plus the per-quest pending
    // map keep rapid taps to one row and one celebration either way.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _busy) setState(() => _busy = false);
    });
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
