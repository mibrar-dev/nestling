// K04 Quest detail (`/quest-detail`, kid mode).
//
// One quest, big and legible: icon tile, title, coin reward, the checklist,
// Pip cheering, then the two big buttons ("I did it!" / "Back") in a
// bottom bar whose surface runs to the physical screen edge (owner rule).
//
// Geometry is transcribed from `design/html-source/screens/K04-quest-detail.html`
// and verified pixel-by-pixel against `design/screens/light/K04-quest-detail.png`
// ÷3 (every number in the comments below is that measurement):
//
//   y  47…103  `.k4-top` (56 px row, `padding: 0 20px 6px`)
//   y 109…229  `.k4-tile` 120×120, r24, peach tint, 3 px ink, kid shadow
//   y 233…267  `h1.kid-title` (`.k4-title { margin-top: 4 }`)
//   y 283…323  `.coin-pill.big` (`+15`)
//   y 339…359  `.kcap` hint
//   y 375…561  `.k4-steps` (3 + 60 + 60 + 60 + 3 = 186)
//   y 583…647  `.k4-cheer` (`.k4-cheer { margin-top: 22 }`), Pip 64 + 12 + bubble 240
//   y 647…810  `.kid-bar` (3 + 12 + 64 + 10 + 64 + 10), home indicator 810…844
//
// Copy is verbatim from the HTML (all ASCII on this screen).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// `hide PipMood`: the barrel exports the v1 `PipMood` from `pip_rive.dart`,
// which collides with the v2 one this screen uses (same shape as the gallery).
import 'package:nestling/core/design_system/design_system.dart' hide PipMood;
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_quest.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_bloc.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_event.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_state.dart';
import 'package:nestling/features/kid_home/presentation/widgets/kid_style_helpers.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';

/// `.k4-tile`: the design's 120×120 icon tile (PNG x 135…255, y 109…229).
const double _kTileSize = 120;

/// `.k4-dot`: the 40 px checklist ring (PNG leaf fill x 40…74 ⇒ box x 37…77).
const double _kDotSize = 40;

/// `.k4-step { min-height: 60px }`. The design's rows are border-box: the
/// 2 px `.k4-step + .k4-step` divider is INSIDE the 60, so rows 2 and 3 lay
/// out 58 + 2 (PNG: card 375…561 = 3 + 60 + 60 + 60 + 3 = 186).
const double _kStepHeight = 60;

/// `.k4-step + .k4-step { border-top: 2px solid var(--line) }` (PNG: the
/// dividers land at y 438…440 and 498…500).
const double _kStepDivider = 2;

/// `.k4-cheer { margin-top: 22px }` (PNG: card bottom 561 + 22 = row top
/// 583). No spacing token carries 22, so it is named here.
const double _kCheerGap = 22;

/// `.k4-cheer img`: the design's 64 px Pip slot (PNG ink x 49…89 inside a
/// slot at x 37…101).
const double _kPipSlot = 64;

/// `.kid-bar`'s 10 px gap and bottom air, less the 6 px shadow room
/// `NestKidButton` reserves under each painted button: the bar's painted
/// buttons land exactly on the design rects. See the bar comment in
/// `_QuestDetailBodyState.build`.
const double _kBarGap = NestSpacing.s1;

/// The quest the design shows, and the only fallback for a direct launch:
/// `shot.sh` opens `/quest-detail` with no route `extra`, and a detail screen
/// must show exactly one quest (the DB has no "selected quest" column). K03
/// always pushes `extra {'questId', 'childId'}`, so this branch only fires
/// outside the app.
const String _kDesignQuestId = 'q-tidy';

/// Glyph per `KidQuest.icon` — the KID designs' glyphs
/// (`K03-kid-home.html` / `K04-quest-detail.html`) via the shared single
/// source `questIconFor(key, audience: NestAudience.kid)`. Supersedes the
/// iteration-2 local mirror of P09's table: the 15:08 ruling moved every
/// kid screen to the per-audience helper, which for the hero key uses the
/// K04-hero-faithful `questBedKid` (with headboard post/pillow/legs) instead
/// of the P09 flat frame. Where K03/K04 draw no row for a key, the parent
/// glyph is shared for both audiences (see `quest_icons.dart`).
String _iconFor(String raw) {
  return questIconFor(raw, audience: NestAudience.kid);
}

/// Done = `approved` + `done_pending` (same rule as K03's card).
bool _isDone(KidQuest item) =>
    item.status == 'approved' || item.status == 'done_pending';

KidQuest? _firstWithQuestId(List<KidQuest> items, String questId) {
  for (final item in items) {
    if (item.questId == questId) return item;
  }
  return null;
}

/// Which quest this detail screen shows (K04 plan §b).
///
/// 1. The `extra` K03 pushes (`{'questId', 'childId'}`) when the id matches a
///    live item and the child is the one playing. An id that no longer
///    resolves is an unknown quest, NOT a licence to show a different one.
/// 2. The design's `q-tidy` when it is among the child's quests (direct
///    launch without `extra`).
/// 3. The first `to_do` / `not_yet` quest in list order.
/// 4. The first quest.
KidQuest? _resolveQuest(KidHomeState state, Object? extra) {
  final items = state.items;
  if (items.isEmpty) return null;
  final map = extra is Map<Object?, Object?>
      ? extra
      : const <Object?, Object?>{};
  final questId = map['questId'];
  final childId = map['childId'];
  // An explicit request must resolve to the playing child's own list — or to
  // the missing state. It must never silently swap in a different quest
  // (K04-BUG-2): an extra naming another child, or naming a quest the
  // playing child does not have, means the screen cannot honestly show one.
  // The q-tidy / first-to-do / first-item fallbacks below belong to the
  // direct-launch path (no questId in extra).
  if (questId is String) {
    if (childId is String && childId != state.child?.id) return null;
    return _firstWithQuestId(items, questId);
  }
  final designQuest = _firstWithQuestId(items, _kDesignQuestId);
  if (designQuest != null) return designQuest;
  for (final item in items) {
    if (item.status == 'to_do' || item.status == 'not_yet') return item;
  }
  return items.first;
}

/// K04 view root: the celebration + error channels, then the state switch.
class QuestDetailView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    // Celebration rides SUCCESS only (same rule as K03): the bloc emits
    // `justCompletedQuestId` once the write saved, so a failed tap keeps the
    // checklist and toasts instead.
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
                final quest = _resolveQuest(
                  state,
                  GoRouterState.of(context).extra,
                );
                if (quest == null) {
                  return _QuestMissing(child: child);
                }
                return _QuestDetailBody(
                  child: child,
                  quest: quest,
                  // `stepsFor` is a pure sync function of the quest id, read
                  // through the bloc's presentation-supporting getter (views
                  // never touch GetIt or the repository).
                  steps: context.read<KidHomeBloc>().stepsFor(quest.questId),
                  completionToken: state.actionNonce,
                );
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
            // The same top row as the loaded screen, so nothing jumps when
            // the quest arrives.
            const _TopBar(),
            Expanded(
              child: Center(
                child: Semantics(
                  label: 'Loading quest',
                  child: CircularProgressIndicator(color: tokens.leaf),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KidFailure extends StatelessWidget {
  const new({this.child});

  /// The last known child, when the stream failed after a load: the error
  /// card shows their own Pip, never a stranger's.
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
            const _TopBar(),
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
                      if (known != null)
                        PipAvatar(
                          style: pipStyleOf(known.pipStyle),
                          stage: known.pipStage.clamp(1, 4),
                          skin: pipSkinOf(known.pipSkin),
                          accessory: pipAccessoryOf(known.pipAccessory),
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
            const _TopBar(),
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
          ],
        ),
      ),
    );
  }
}

/// No quest to show: the child's list is empty, or the pushed quest id is no
/// longer live (deleted, or another child's).
class _QuestMissing extends StatelessWidget {
  const new({required this.child});

  final KidChild child;

  @override
  Widget build(BuildContext context) {
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            const _TopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  NestSpacing.padSide,
                  0,
                  NestSpacing.padSide,
                  NestSpacing.s8,
                ),
                children: [
                  NestEmptyState(
                    art: PipAvatar(
                      style: pipStyleOf(child.pipStyle),
                      stage: child.pipStage.clamp(1, 4),
                      skin: pipSkinOf(child.pipSkin),
                      accessory: pipAccessoryOf(child.pipAccessory),
                      size: 120,
                    ),
                    title: 'Pick a quest',
                    message: 'Choose a quest to see its steps.',
                    action: NestKidButton(
                      label: 'Back home',
                      color: NestKidButtonColor.white,
                      fullWidth: false,
                      onPressed: () => context.go(KidHomeRoutePaths.home),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `.k4-top`: back on the left, the parental gate on the right — the gate is
/// on every kid screen (DESIGN_SPEC §5 Group C). Both are 56 px, the design's
/// `.nav-back.lg` / `.lock-btn.lg` (PNG y 47…103 for both).
class _TopBar extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        NestSpacing.padSide,
        0,
        NestSpacing.padSide,
        NestSpacing.gap6,
      ),
      child: Row(
        children: [
          NestIconButton(
            icon: NestIcons.back,
            semanticLabel: 'Back',
            size: NestDevice.tapKid,
            iconSize: 26,
            backgroundColor: Colors.transparent,
            borderColor: Colors.transparent,
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

/// The loaded screen: the design's `.scroll` between the top row and the
/// `.kid-bar`.
class _QuestDetailBody extends StatefulWidget {
  const new({
    required this.child,
    required this.quest,
    required this.steps,
    required this.completionToken,
  });

  final KidChild child;
  final KidQuest quest;
  final List<String> steps;

  /// Bumps whenever a completion fails; resets the tap guard so a retry is
  /// possible after an error (success resets via the status flip).
  final int completionToken;

  @override
  State<_QuestDetailBody> createState() => _QuestDetailBodyState();
}

class _QuestDetailBodyState extends State<_QuestDetailBody> {
  /// The working checklist: ticked step indices, fresh on every visit.
  ///
  /// KNOWN DEVIATION (K04 plan §d): the design PNG shows the first two steps
  /// ticked, but v1 has no per-quest step storage (`stepsFor` is a pure
  /// function of the quest id), so a fresh checklist is the honest render.
  /// Only the dot fill differs — 40 px dots, 60 px rows and the card rect are
  /// identical. Tapping never gates the primary button; the design shows it
  /// enabled at 2 of 3.
  final Set<int> _ticked = <int>{};

  /// Tap guard (K03-BUG-1/6 pattern): one completion event per gesture burst,
  /// even before the stream round-trips.
  bool _busy = false;

  @override
  void didUpdateWidget(covariant _QuestDetailBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quest.questId != oldWidget.quest.questId ||
        widget.steps.length != oldWidget.steps.length) {
      // A different quest (or a changed checklist) starts fresh.
      _ticked.clear();
      _busy = false;
    } else if (widget.quest.status != oldWidget.quest.status ||
        widget.completionToken != oldWidget.completionToken) {
      _busy = false;
    }
  }

  void _toggle(int index) {
    setState(() {
      if (!_ticked.remove(index)) _ticked.add(index);
    });
  }

  void _complete() {
    if (_busy) return;
    setState(() => _busy = true);
    context.read<KidHomeBloc>().add(
      KidHomeQuestCompleted(
        childId: widget.child.id,
        questId: widget.quest.questId,
        coins: widget.quest.coins,
      ),
    );
    // Release the latch on the next frame (K03-BUG-11): the bloc emits
    // nothing when a write lands without flipping (silent no-op), so a
    // state-driven reset alone would leave the button dead and unretryable.
    // Same-frame double taps are still blocked (no frame runs between them).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _busy) setState(() => _busy = false);
    });
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(KidHomeRoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final quest = widget.quest;
    final child = widget.child;
    final steps = widget.steps;
    final coins = quest.coins;
    final done = _isDone(quest);
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            const _TopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  NestSpacing.padSide,
                  0,
                  NestSpacing.padSide,
                  NestSpacing.s8,
                ),
                children: [
                  // `.k4-tile { margin: 0 auto }`.
                  Center(
                    child: Container(
                      width: _kTileSize,
                      height: _kTileSize,
                      decoration: BoxDecoration(
                        color: tokens.peachTint,
                        borderRadius: NestRadii.allL,
                        border: Border.all(
                          color: tokens.ink,
                          width: context.nestKid.borderWidth,
                        ),
                        boxShadow: tokens.kidShadow,
                      ),
                      alignment: Alignment.center,
                      // Decorative: the title below carries the same words.
                      child: ExcludeSemantics(
                        child: NestIcon(
                          _iconFor(quest.icon),
                          size: 64,
                          color: tokens.ink,
                        ),
                      ),
                    ),
                  ),
                  // `.k4-title { margin-top: 4px }` — the screen wins over
                  // the `.scroll > * + *` 16 px rhythm.
                  const SizedBox(height: NestSpacing.s1),
                  // `.kid-title` is `text-wrap: balance`, so the heading
                  // breaks like the design instead of orphaning a word.
                  NestBalancedText(
                    quest.title,
                    style: NestType.kidTitle(color: tokens.ink),
                    maxLines: 3,
                    // K04-BUG-4: when a DB-driven title needs more lines
                    // than the cap, cut with an ellipsis, never mid-word
                    // (the component default is TextOverflow.clip).
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: NestSpacing.s4),
                  Center(
                    child: NestCoinPill(
                      amount: '+$coins',
                      size: NestCoinPillSize.large,
                      semanticLabel: 'Plus $coins coins',
                    ),
                  ),
                  const SizedBox(height: NestSpacing.s4),
                  Text(
                    'Tick each bit off, then press the big button.',
                    style: NestType.kidCaption(color: tokens.ink2),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: NestSpacing.s4),
                  _StepsCard(steps: steps, ticked: _ticked, onToggle: _toggle),
                  // `.k4-cheer { margin-top: 22px }`.
                  const SizedBox(height: _kCheerGap),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: NestSpacing.s3,
                    children: [
                      // PIP rule: the child's OWN Pip from the DB row, never
                      // the v1 `pip_stage_*.svg` illustrations. The design's
                      // `alt` becomes the image label; because this node and
                      // the bubble's text are adjacent label-only siblings,
                      // the semantics compiler merges them ("Pip cheering you
                      // on\nPip is doing a happy dance!"), which is exactly
                      // what a screen reader should announce.
                      Semantics(
                        image: true,
                        label: 'Pip cheering you on',
                        excludeSemantics: true,
                        child: PipAvatar(
                          style: pipStyleOf(child.pipStyle),
                          stage: child.pipStage.clamp(1, 4),
                          skin: pipSkinOf(child.pipSkin),
                          accessory: pipAccessoryOf(child.pipAccessory),
                          mood: PipMood.happy,
                          size: _kPipSlot,
                        ),
                      ),
                      const Flexible(
                        child: NestSpeechBubble(
                          text: 'Pip is doing a happy dance!',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bottom edge (owner rule): the bar's own surface runs to the
            // physical screen edge — the `SafeArea` inset sits INSIDE the
            // surface box, so no meadow/sky strip shows under it. Buttons
            // stay above the inset; the OS draws the home pill.
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
                        NestSpacing.s1,
                      ),
                      // `.kid-bar { padding: 12px 20px 10px; gap: 10px }`
                      // measured against the PNG (bar 647…810, buttons
                      // 662…726 and 736…800). `NestKidButton` reserves its
                      // own 6 px shadow room per button, so the CSS 10 px
                      // gap and 10 px bottom air each hand 6 of those px back
                      // (gap and bottom padding = 4): the painted buttons land
                      // exactly on the design rects, and the bar stays 163
                      // tall. Same reasoning as the K03 dock's `s1` air.
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: _kBarGap,
                        children: [
                          NestKidButton(
                            label: 'I did it!',
                            icon: NestIcon(
                              NestIcons.check,
                              size: 26,
                              color: tokens.onLeaf,
                            ),
                            onPressed: done || _busy ? null : _complete,
                          ),
                          NestKidButton(
                            label: 'Back',
                            color: NestKidButtonColor.white,
                            onPressed: _goBack,
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

/// `.k4-steps`: the white checklist card — surface fill, 3 px ink border,
/// r24, chunky kid shadow, dividers bleeding to the card edge.
class _StepsCard extends StatelessWidget {
  const new({
    required this.steps,
    required this.ticked,
    required this.onToggle,
  });

  final List<String> steps;
  final Set<int> ticked;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.nest.surface,
        borderRadius: NestRadii.allL,
        border: Border.all(
          color: context.nest.ink,
          width: context.nestKid.borderWidth,
        ),
        boxShadow: context.nest.kidShadow,
      ),
      clipBehavior: Clip.hardEdge,
      // No `padding` here on purpose: this Flutter's `Container` already insets
      // the child by the decoration's border padding, which is exactly the CSS
      // content box — the rows measure 344 wide (x 23…367), the ring sits at
      // x 37 and the dividers bleed to the inner edge, like the PNG. Adding an
      // explicit `EdgeInsets.all(3)` would double it (the card measured 192
      // instead of 186).
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < steps.length; index++)
            _StepRow(
              label: steps[index],
              ticked: ticked.contains(index),
              // `.k4-step + .k4-step`: the divider belongs to the row below
              // it and sits INSIDE that row's 60 (see [_StepRow]).
              dividerAbove: index > 0,
              onTap: () => onToggle(index),
            ),
        ],
      ),
    );
  }
}

/// `.k4-step`: a full-width row — 60 px tall, `padding: 0 14px`, a 40 px ring
/// and the step text.
///
/// The design's rows are border-box: `.k4-step { min-height: 60 }` plus
/// `.k4-step + .k4-step { border-top: 2px }` gives 3 + 60 + 60 + 60 + 3 = 186
/// for the card (PNG y 375…561), so a row that carries the divider lays its
/// content out in 58 and the divider takes the first 2 of its 60.
class _StepRow extends StatelessWidget {
  const new({
    required this.label,
    required this.ticked,
    required this.dividerAbove,
    required this.onTap,
  });

  final String label;
  final bool ticked;
  final bool dividerAbove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Semantics(
      button: true,
      toggled: ticked,
      enabled: true,
      label: '$label, ${ticked ? 'ticked' : 'not ticked'}',
      // The accessibility rule: the wrapper must expose the tap action
      // itself, because `excludeSemantics` drops the InkWell's node.
      onTap: onTap,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dividerAbove)
              Container(height: _kStepDivider, color: tokens.line),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: dividerAbove
                        ? _kStepHeight - _kStepDivider
                        : _kStepHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: NestSpacing.gap14,
                    ),
                    child: Row(
                      spacing: NestSpacing.s3,
                      children: [
                        // `.k4-dot` / `.k4-dot.on`: 40 px ring, leaf fill with
                        // an on-leaf tick when ticked, surface with an ink
                        // tick otherwise. The same check glyph the quest
                        // cards use.
                        Container(
                          width: _kDotSize,
                          height: _kDotSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: ticked ? tokens.leaf : tokens.surface,
                            border: Border.all(
                              color: tokens.ink,
                              width: context.nestKid.borderWidth,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: NestIcon(
                            NestIcons.check,
                            size: 22,
                            color: ticked ? tokens.onLeaf : tokens.ink,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            label,
                            style: NestType.h3(color: tokens.ink),
                            softWrap: true,
                          ),
                        ),
                      ],
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

/// Parental-gate lock with a tap guard (K03-BUG-9): one gate route per
/// gesture burst, even on a fast double tap.
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
