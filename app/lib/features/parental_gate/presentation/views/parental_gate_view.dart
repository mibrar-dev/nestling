import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/parental_gate/presentation/bloc/parental_gate_bloc.dart';
import 'package:nestling/features/parental_gate/presentation/bloc/parental_gate_event.dart';
import 'package:nestling/features/parental_gate/presentation/bloc/parental_gate_state.dart';
import 'package:nestling/features/today/today_routes.dart';

class ParentalGateView extends StatefulWidget {
  const new({super.key});

  @override
  State<ParentalGateView> createState() => _ParentalGateViewState();
}

class _ParentalGateViewState extends State<ParentalGateView> {
  /// Set once the gate has been passed through automatically (disabled
  /// gate), so the navigation fires a single time.
  bool _didPassThrough = false;

  /// Highest [ParentalGateState.attempts] already announced, so each wrong
  /// answer is announced exactly once.
  int _announcedAttempts = 0;

  /// The challenge the counter above belongs to. `onData` resets `attempts`
  /// to 0 when the live challenge changes (P17-BUG-3), so without this the
  /// high-water mark would swallow the first announcement of the new
  /// challenge (6_bugs.md observation 1).
  String? _announcedChallengeId;

  void _unlock(BuildContext context) {
    context.read<ParentalGateBloc>().add(
      const ParentalGateUnlockAcknowledged(),
    );
    final canPop = Navigator.of(context).canPop();
    if (canPop) {
      // Pop FIRST, then rotate into parent mode (Stage-3 §3.1: flipping
      // the mode and starting the async session write while the imperative
      // route is mid-pop makes the router's refreshListenable restore the
      // /parental-gate route — the gate never closed).
      context.pop();
      GetIt.instance<AppModeController>().selectMode(AppMode.parent);
      final session = GetIt.instance<AppSession>();
      unawaited(session.setAppMode('parent').then((_) => session.refresh()));
    } else {
      // Parent mode FIRST so the router's kid-gate redirect stops firing
      // when we `go` to a parent-only route.
      GetIt.instance<AppModeController>().selectMode(AppMode.parent);
      final session = GetIt.instance<AppSession>();
      unawaited(session.setAppMode('parent').then((_) => session.refresh()));
      context.go(TodayRoutePaths.today);
    }
  }

  void _leave(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go(KidHomeRoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: BlocListener<ParentalGateBloc, ParentalGateState>(
        listenWhen: (previous, current) =>
            current.unlocked != previous.unlocked ||
            current.attempts != previous.attempts ||
            current.status != previous.status ||
            current.items != previous.items,
        listener: (context, state) {
          if (state.unlocked) {
            _unlock(context);
            return;
          }
          // A new challenge restarts the attempt counter (and therefore the
          // announcement counter) with it.
          final challengeId = state.challenge?.id;
          if (challengeId != _announcedChallengeId) {
            _announcedChallengeId = challengeId;
            _announcedAttempts = state.attempts;
          }
          if (state.attempts > _announcedAttempts) {
            _announcedAttempts = state.attempts;
            // Kind retry — announce, never a red/danger styling.
            unawaited(
              SemanticsService.sendAnnouncement(
                View.of(context),
                'That wasn’t right — try again',
                TextDirection.ltr,
              ),
            );
          }
          if (!_didPassThrough &&
              state.status == ParentalGateStatus.loaded &&
              state.items.isEmpty) {
            _didPassThrough = true;
            _unlock(context);
          }
        },
        child: KidScope(
          child: Stack(
            children: [
              // 1. Dimmed kid backdrop (scenery only — no semantics).
              Positioned.fill(child: ExcludeSemantics(child: _GateBackdrop())),
              // 2. Full-bleed scrim to every edge.
              Positioned.fill(child: ColoredBox(color: context.nest.scrim)),
              // 3. Modal. CSS truth is `.modal { top: 50%; transform:
              // translateY(-50%) }` (DESIGN_SPEC §5 P17: "as a centred
              // `.modal`"), so the card is CENTRED in the canvas rather than
              // hanging off a derived literal — the design's 712 px card then
              // lands on exactly y 66 with no 66 literal in the file.
              // `Column(mainAxisAlignment: center)` inside a
              // `ConstrainedBox(minHeight: viewport)` is deliberate: an
              // `Align(Alignment.center)`/`Center` shrink-wraps, so a card
              // taller than the canvas (large text scale) would hang off the
              // top with its first pixels unreachable; the Column grows past
              // the viewport instead, so the scroll view can still reach them.
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: NestSpacing.s6,
                            ),
                            child: Semantics(
                              label: 'Parental gate',
                              explicitChildNodes: true,
                              child: NestModal(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const _LockTile(),
                                    const SizedBox(height: NestSpacing.s3),
                                    Text(
                                      'Grown-ups only',
                                      style: NestType.h2(
                                        color: context.nest.ink,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: NestSpacing.s2),
                                    BlocBuilder<
                                      ParentalGateBloc,
                                      ParentalGateState
                                    >(
                                      buildWhen: (p, c) =>
                                          p.status != c.status ||
                                          p.items != c.items ||
                                          p.entered != c.entered ||
                                          p.errorMessage != c.errorMessage,
                                      builder: (context, state) {
                                        Widget body;
                                        switch (state.status) {
                                          case ParentalGateStatus.initial:
                                          case ParentalGateStatus.loading:
                                            body = _GateLoading(
                                              onLeave: () => _leave(context),
                                            );
                                          case ParentalGateStatus.failure:
                                            body = _GateFailure(
                                              message:
                                                  state.errorMessage ??
                                                  'Something went wrong',
                                              onRetry: () => context
                                                  .read<ParentalGateBloc>()
                                                  .add(
                                                    const ParentalGateLoadRequested(),
                                                  ),
                                              onLeave: () => _leave(context),
                                            );
                                          case ParentalGateStatus.loaded:
                                            if (state.items.isEmpty) {
                                              // Disabled gate passes straight
                                              // through (BlocListener) — no
                                              // visible empty state.
                                              return const SizedBox.shrink();
                                            }
                                            body = Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Type the answer in numbers:',
                                                  style: NestType.bodySmall(
                                                    color: context.nest.ink2,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(
                                                  height: NestSpacing.s1,
                                                ),
                                                Text(
                                                  state.challenge?.question ??
                                                      '',
                                                  style: NestType.h3(
                                                    color: context.nest.ink,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(
                                                  height: NestSpacing.s4,
                                                ),
                                                Semantics(
                                                  label:
                                                      'Answer, ${state.entered.length} of ${state.expectedLength} entered',
                                                  excludeSemantics: true,
                                                  child: _DigitsRow(
                                                    entered: state.entered,
                                                    total: state.expectedLength,
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: NestSpacing.s4,
                                                ),
                                                Semantics(
                                                  label: 'Number pad',
                                                  child: LayoutBuilder(
                                                    builder: (context, constraints) {
                                                      // The new shared
                                                      // NestKeypad_s Grid
                                                      // expands to the parent
                                                      // width via `fit: stretch`
                                                      // at the design width
                                                      // (≥ contentWidth). At
                                                      // narrower cards the
                                                      // shrinkWrap mode
                                                      // renders a fixed 280
                                                      // box that FittedBox
                                                      // can scale down safely.
                                                      final plenty =
                                                          constraints
                                                              .maxWidth >=
                                                          NestKeypad
                                                              .contentWidth;
                                                      final keypad = NestKeypad(
                                                        kid: true,
                                                        fit: plenty
                                                            ? NestKeypadFit
                                                                  .stretch
                                                            : NestKeypadFit
                                                                  .shrinkWrap,
                                                        onKey: (digit) => context
                                                            .read<
                                                              ParentalGateBloc
                                                            >()
                                                            .add(
                                                              ParentalGateDigitEntered(
                                                                digit,
                                                              ),
                                                            ),
                                                        onDelete: () => context
                                                            .read<
                                                              ParentalGateBloc
                                                            >()
                                                            .add(
                                                              const ParentalGateDeletePressed(),
                                                            ),
                                                      );
                                                      if (plenty) {
                                                        return keypad;
                                                      }
                                                      return FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: SizedBox(
                                                          width: NestKeypad
                                                              .contentWidth,
                                                          child: keypad,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: NestSpacing.s3,
                                                ),
                                                NestButton(
                                                  label: 'Back to Pip',
                                                  variant:
                                                      NestButtonVariant.ghost,
                                                  minHeight: 56,
                                                  fontSize: 15,
                                                  onPressed: () =>
                                                      _leave(context),
                                                ),
                                              ],
                                            );
                                        }
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            body,
                                            const SizedBox(
                                              height:
                                                  NestSpacing.s2 +
                                                  NestSpacing.gap2,
                                            ),
                                            // The enclosing column is the single owner of the caption
                                            // gap (`.gate-note { margin-top: 10 }`) and of the caption
                                            // itself, in every state. `failure` used to render a second
                                            // copy under a gap of its own and stand a `SizedBox.shrink()`
                                            // in for the one it skipped, which left a 10 px orphan gap
                                            // under the caption in that state alone.
                                            Text(
                                              'This keeps settings and purchases safe.',
                                              style: NestType.caption(
                                                color: context.nest.ink2,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ],
                                        );
                                      },
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
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Always-present backdrop header + Pip slot, dimmed under the scrim.
class _GateBackdrop extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final session = GetIt.instance<AppSession>();
    final db = GetIt.instance<AppDatabase>();
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        return StreamBuilder<List<ChildrenData>>(
          stream: db.watchChildren(Seed.familyId),
          builder: (context, snapshot) {
            final kids = snapshot.data ?? const <ChildrenData>[];
            ChildrenData? child;
            final activeId = session.activeChildId;
            if (activeId != null) {
              for (final candidate in kids) {
                if (candidate.id == activeId) {
                  child = candidate;
                  break;
                }
              }
            }
            child ??= kids.isEmpty ? null : kids.first;
            return _GateBackdropBody(child);
          },
        );
      },
    );
  }
}

class _GateBackdropBody extends StatelessWidget {
  const new(this.child);

  final ChildrenData? child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final kid = child;
    final rawName = kid?.nickname ?? '';
    final nickname = rawName.isEmpty ? null : rawName;
    final initial = nickname == null ? '•' : nickname[0].toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // OS draws the real status bar; reserve its height instead, then
        // the `kb-top` header starts at design y 55.
        const NestStatusBar(),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, NestSpacing.s2, 28, 0),
          child: Row(
            spacing: NestSpacing.s3,
            children: [
              NestAvatar(
                initial: initial,
                color: kid == null
                    ? NestAvatarColor.neutral
                    : _avatarColor(kid.avatarColour),
              ),
              Expanded(
                child: Text(
                  nickname == null ? 'Hi there!' : 'Hi $nickname!',
                  style: NestType.h1(color: tokens.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              NestCoinPill(amount: '${kid?.coins ?? 0}'),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Center(
          child: kid == null
              ? const PipAvatar(style: PipStyle.mochi, stage: 3, size: 200)
              : PipAvatar(
                  style: _pipStyle(kid.pipStyle),
                  stage: kid.pipStage.clamp(1, 4),
                  skin: _pipSkin(kid.pipSkin),
                  accessory: _pipAccessory(kid.pipAccessory),
                  size: 200,
                ),
        ),
      ],
    );
  }
}

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

class _LockTile extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: tokens.lilacTint,
        borderRadius: NestRadii.allM,
      ),
      child: Center(
        child: NestIcon(NestIcons.lock, size: 26, color: tokens.lilac),
      ),
    );
  }
}

class _DigitsRow extends StatelessWidget {
  const new({required this.entered, required this.total});

  final String entered;
  final int total;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: NestSpacing.s3,
      children: [
        for (var i = 0; i < total; i++)
          ExcludeSemantics(
            child: Container(
              width: 56,
              height: 64,
              decoration: BoxDecoration(
                color: i < entered.length ? tokens.surface : tokens.surface2,
                borderRadius: NestRadii.allM,
                border: Border.all(
                  color: i < entered.length ? tokens.ink : tokens.line,
                  width: 2,
                ),
              ),
              child: Center(
                child: i < entered.length
                    ? Text(entered[i], style: NestType.h1(color: tokens.ink))
                    : Container(
                        width: 3,
                        height: 24,
                        decoration: BoxDecoration(
                          color: tokens.leaf,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GateLoading extends StatelessWidget {
  const new({required this.onLeave});

  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Equal-height placeholders for the instruction/question lines,
        // so the modal frame does not jump when data arrives.
        const SizedBox(height: 22),
        const SizedBox(height: NestSpacing.s1),
        const SizedBox(height: 24),
        const SizedBox(height: NestSpacing.s4),
        const SizedBox(height: 64),
        const SizedBox(height: NestSpacing.s4),
        // The shared NestKeypad grid is 8 pad-top + 4x72 + 3x10 = 326 tall
        // (`gap: 10; padding: 8 24 0`), so the placeholder reserves the
        // design's 326 rather than the pre-merge 352.
        SizedBox(
          height: 326,
          child: Center(
            child: Semantics(
              label: 'Loading the grown-ups check',
              child: CircularProgressIndicator(color: context.nest.leaf),
            ),
          ),
        ),
        const SizedBox(height: NestSpacing.s3),
        // The escape is the same 56 px ghost `Back to Pip` the loaded card
        // shows, in the slot that was already reserved for it, so a kid (or a
        // VoiceOver user) can always leave the gate instead of waiting for the
        // system back gesture (3_test obs 3 / 6_bugs obs 1). Layout-neutral:
        // the button is exactly the 56 px the placeholder stood in for.
        NestButton(
          label: 'Back to Pip',
          variant: NestButtonVariant.ghost,
          minHeight: 56,
          fontSize: 15,
          onPressed: onLeave,
        ),
        // NB: the caption's own `s2 + gap2` gap and its 18 px line box are
        // added by the enclosing column, so this placeholder must NOT reserve
        // them again (it stood the card 28 px tall until iteration 3).
      ],
    );
  }
}

class _GateFailure extends StatelessWidget {
  const new({
    required this.message,
    required this.onRetry,
    required this.onLeave,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          style: NestType.bodySmall(color: tokens.ink2),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: NestSpacing.s2),
        NestButton(
          label: 'Try again',
          variant: NestButtonVariant.ghost,
          // Kid mode: DESIGN_SPEC §5 kid rules ask for >= 56 tap targets,
          // and the sibling `Back to Pip` in this same state is 56.
          // `1_plan.md` §(d) said 44; the spec wins on a kid screen
          // and no design PNG shows this state.
          minHeight: NestDevice.tapKid,
          onPressed: onRetry,
        ),
        const SizedBox(height: NestSpacing.s2),
        NestButton(
          label: 'Back to Pip',
          variant: NestButtonVariant.ghost,
          minHeight: 56,
          fontSize: 15,
          onPressed: onLeave,
        ),
        // No gap and no caption here — the enclosing column owns
        // the `.gate-note` rhythm in every state, so the copy has a
        // single owner and the failure card has no orphan gap.
      ],
    );
  }
}
