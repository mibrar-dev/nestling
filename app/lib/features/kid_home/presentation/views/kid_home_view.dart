import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

/// Design-slot numbers (single place to change, cited to `.k3-pet` in
/// `design/html-source/screens/K03-kid-home.html` and to
/// `design/screens/light/K03-kid-home.png` ÷3).
///
/// SHARED_REQUEST #11 + #13 landed: the shared `NestPetStage` explicit size
/// mode composes the whole scene inside the ACTUAL parent box now (it is
/// centred there, never off-centre, and scales down instead of overflowing),
/// so the slot no longer needs a feature-local scene fork and no longer
/// derives its size from the incoming width. The numbers below are the call
/// `docs/screens/_shared/pet_stage_explicit_REPORT.md` asks for:
///
/// * `_kNestBoxWidth` is the nest BOX; `PipNestFallback.visibleNestRatio`
///   (202/240) makes it paint the design's 198 px visible outline
///   (x 96…294, centre 195) at any box height.
/// * `_kNestBoxHeight` is the box height, so the bowl outline is
///   `nestHeight × 110/240`: 188 paints the design's 86 px tall outline
///   (y 278…364), which needs a 236-tall block. Landed by
///   `shared/pet_stage_seat` — `docs/screens/_shared/pet_stage_seat_REPORT.md`
///   ("Replace `nestHeight: 156` with 188") and `ORCHESTRATOR_NOTES` 10:14.
/// * `_kPipSlotSize` is the design's ≈152 px Pip; its feet then land ≈23 px
///   inside the bowl (design y 301).
const double _kNestBoxWidth = 236;
const double _kNestBoxHeight = 188;
const double _kPipSlotSize = 152;

/// Scroll gap between the pet stage and the hearts row.
///
/// `.scroll > * + *` is `--s4` (16) in the HTML, but the shared pet stage
/// paints the bubble's 9 px tail and the design's `.k3-pet` 14 px top margin
/// inside its own block, so 16 here would push every row below the design down
/// by the same amount. Measured at real fonts
/// (`kid_home_geometry_test.dart`), 10.75 lands the hearts row centre on
/// 447.75 — the design's y 448 — and every row below it keeps the design's
/// `s4` rhythm. The orchestrator's last-pass note sanctions this lever ("fix
/// by sizing the NestPetStage box — pipSize / nest width / bottom gap — not by
/// negative margins"); the shared component owns the box now (exactly the
/// design's 236 px slot for `nestHeight: 188`), the gap is the only lever
/// left.
const double _kStageToHearts = 10.75;

/// Shadow room that `NestKidQuestCard` puts UNDER its own painted card
/// (`core/design_system/components/nest_quest_card.dart:168`,
/// `EdgeInsets.only(bottom: 6)`), so `tokens.kidShadow`'s offset never
/// collides with the next card.
///
/// The design's `.k3-quests { gap: 12px }`
/// (`design/html-source/screens/K03-kid-home.html:30`) is the gap between
/// PAINTED cards, so the column spacing has to hand those 6 px back or the
/// rects sit 18 px apart: card 2's top border then lands on y 665 instead of
/// the design's 659 (FIXES_8 finding 2 / 5_ui deviation 1), 6 px per card
/// further down, eating the card-2 peek above the dock.
///
/// REMOVE this subtraction when SHARED_REQUEST #16(b) lands (drop the
/// in-card padding, or add a `shadowPadding` parameter) — the column then
/// goes straight back to `NestSpacing.s3` and nothing else moves.
///
/// The value is `NestSpacing.gap6`, the token for that 6 px, so the view and
/// `kid_home_view_test.dart` name the same reserve the same way.
const double _kQuestCardShadowRoom = NestSpacing.gap6;

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
                            // SHARED_REQUEST #7 landed: screen-exact
                            // `.k3-name` is now NestType.kidName.
                            style: NestType.kidName(color: tokens.ink),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$done done today',
                            // SHARED_REQUEST #7 landed: screen-exact
                            // `.k3-sub` is now NestType.kidCaption.
                            style: NestType.kidCaption(color: tokens.ink2),
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
                        const SizedBox(height: _kStageToHearts),
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
                                  child: Padding(
                                    // K03-kid-home.html l.58: the caption
                                    // carries `margin-left:2px` on top of the
                                    // row's 8 px gap (review finding 8).
                                    padding: const EdgeInsets.only(
                                      left: NestSpacing.gap2,
                                    ),
                                    child: Text(
                                      'Pip is happy today',
                                      // SHARED_REQUEST #7 landed: screen-exact
                                      // `.kcap` is now NestType.kidCaption.
                                      style: NestType.kidCaption(
                                        color: tokens.ink2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                                child: NestBalancedText(
                                  "Today's quests",
                                  style: NestType.kidTitle(color: tokens.ink),
                                  textAlign: TextAlign.start,
                                  maxLines: 2,
                                ),
                              ),
                              KidStatusChip(label: '$done of $total done'),
                            ],
                          ),
                        ),
                        // 12 + the band's own 4 px top inset below, so the
                        // band's top edge lands on the design's 62 % horizon
                        // stop (`0.62 × NestDevice.height` ≈ y 523) and the
                        // progress bar still starts exactly `s4` (16) below
                        // the section title, as `.scroll > * + *` does. The
                        // band is the design's *screen background* there, so in
                        // the HTML it never pushes content; the inset
                        // reproduces that without moving anything.
                        const SizedBox(height: NestSpacing.s3),
                        // Meadow band behind progress + cards (FIXES_1 #1,
                        // review finding 4): in-flow full-bleed hill, so it
                        // scrolls with the content and needs no magic offsets.
                        // The tone is `kidHorizon`: pixel measurement of both
                        // design PNGs lands exactly on it (light #EAF7E2, dark
                        // within a few levels), and it grades to `kidMeadow`
                        // over the design's own 321 px gradient span
                        // (`components.css` l.25: kid-horizon at 62 %, kid-meadow at
                        // 100 % of the design height). The shared KidScope hill
                        // (untouched) stays `kidMeadow`.
                        CustomPaint(
                          painter: _MeadowPainter(
                            top: tokens.kidHorizon,
                            bottom: tokens.kidMeadow,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(
                              NestSpacing.padSide,
                              NestSpacing.s1,
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
                                  // `.k3-quests` gap 12, less the card's own
                                  // 6 px shadow room: see
                                  // `_kQuestCardShadowRoom`.
                                  spacing:
                                      NestSpacing.s3 - _kQuestCardShadowRoom,
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
                    // Dock bottom air is `s1`, not the HTML `gap10`: the 34 px
                    // OS inset below already belongs to this surface (owner
                    // rule), so 3+12+72+4+34 lands the dock top exactly on
                    // the design y≈720 (UI dev 3).
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        NestSpacing.padSide,
                        NestSpacing.s3,
                        NestSpacing.padSide,
                        NestSpacing.s1,
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
                              // Dock labels never wrap (review finding 5;
                              // SHARED_REQUEST #9 `wrapLabel` API now on main).
                              wrapLabel: false,
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
                              // Dock labels never wrap (review finding 5;
                              // SHARED_REQUEST #9 `wrapLabel` API now on main).
                              wrapLabel: false,
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
                              // Dock labels never wrap (review finding 5;
                              // SHARED_REQUEST #9 `wrapLabel` API now on main).
                              wrapLabel: false,
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

/// Pet stage: the child's own Pip seated in the nest, under the design
/// speech bubble.
///
/// Review finding 1 (iteration 6/7) asked for the HTML's own slot — the nest
/// with Pip 152 tall in a 236 px block. The shared `NestPetStage` explicit
/// size mode (SHARED_REQUEST #11, then #13) now expresses it and centres the
/// scene in the real content box, so the numbers are the design's own and
/// nothing local is derived from the incoming width. `pipSize` is dropped:
/// explicit mode ignores it. `inNest` remains omitted — it defaults to false
/// and the custom `pip:` path seats the avatar between the nest rims either
/// way (SHARED_REQUEST #8).
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
      nestWidth: _kNestBoxWidth,
      nestHeight: _kNestBoxHeight,
      fixedPipHeight: _kPipSlotSize,
      semanticLabel: 'Pip the ${_pipStageName(stage)}, stage $stage of 4',
    );
  }
}

/// Tall meadow band behind progress + cards (FIXES_1 #1, review finding 4).
// TODO(K03): this is still a feature-local band. The design paints it as the
// SCREEN background — `components.css` l.25
// `linear-gradient(180deg, kid-sky-top 0%, kid-sky-bottom 62%, kid-horizon 62%, kid-meadow 100%)`
// — and `KidScope` grew `meadowHeight`/`meadowBottom`/`meadowColor` for it
// (SHARED_REQUEST #6). What is still missing in `core/` is the third and
// fourth gradient stop: `KidScope`'s own background has only two
// (kidSkyTop → kidSkyBottom) and its hill SVG has a curved crest, while the
// design's horizon stop is a flat horizontal line 62 % down the screen. Until
// that lands the band is painted in flow behind the progress bar and the
// cards, with the design's tones over the design's gradient span.
class _MeadowPainter extends CustomPainter {
  const _MeadowPainter({required this.top, required this.bottom});

  final Color top;
  final Color bottom;

  /// The design's gradient run in logical px: the band starts at the 62 %
  /// horizon stop (`0.62 × NestDevice.height = 523.3`) and reaches
  /// `kid-meadow` at the design screen bottom (`NestDevice.height`) —
  /// ≈321 px. The in-flow band is far taller than that (progress bar plus every card), so the grade is
  /// compressed into the design's span and stays `kidMeadow` below it: that
  /// is what makes the visible part match both PNGs. Grading over the band's
  /// whole height (the old behaviour) left dark mode a flat navy block,
  /// three iterations running.
  ///
  /// The two stops are the design's own percentages of the design device
  /// height, so the whole run comes from `NestDevice.height` (FIXES_8 finding
  /// 5) rather than a repeated literal.
  static const double gradeSpan = NestDevice.height * (1 - 0.62);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, _kCrestLeftY)
      ..quadraticBezierTo(w * _kCrestBend, _kCrestControlY, w, _kCrestRightY)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[top, bottom],
        stops: <double>[0, (gradeSpan / h).clamp(0.0, 1.0)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MeadowPainter oldDelegate) =>
      oldDelegate.top != top || oldDelegate.bottom != bottom;
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
      // Design tints the tile per quest (review finding 5; tileBackground
      // landed on main): dishwasher is sky, reading lilac, tidy peach;
      // anything else keeps the neutral surface2 tile.
      tileBackground: switch (widget.item.icon) {
        'dishwasher' => tokens.skyTint,
        'book' => tokens.lilacTint,
        'bed' => tokens.peachTint,
        _ => null,
      },
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
