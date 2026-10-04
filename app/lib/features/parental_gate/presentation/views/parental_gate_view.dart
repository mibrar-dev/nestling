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
              // 3. Modal anchored at the design's y 66 (NOT centred — the
              // centring path was producing a uniform shift). The
              // LayoutBuilder/ConstrainedBox pair that measured the viewport
              // stays — it is how the unpositioned slot on the gate Stack
              // learns its width/height; the top offset now comes from the
              // Padding above the scroll view instead of the center.
              LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      NestSpacing.s6,
                      66,
                      NestSpacing.s6,
                      0,
                    ),
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 66,
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
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
                                    style: NestType.h2(color: context.nest.ink),
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
                                          body = const _GateLoading();
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
                                                state.challenge?.question ?? '',
                                                style: NestType.h3(
                                                  color: context.nest.ink,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
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
                                                child: SizedBox(
                                                  width: 296,
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    // TODO(P17): shared NestKeypad
                                                    // hard-codes a 16px row gap +
                                                    // 8px bottom padding where the CSS
                                                    // grid is gap 10 / padding 8-24-0, so
                                                    // this slot is 26px taller than the
                                                    // design and every band below it
                                                    // drifts (+6/row). Needs the shared
                                                    // component (core) — see
                                                    // docs/screens/P17/SHARED_REQUEST.md
                                                    // #3. Do not fork a local keypad.
                                                    child: NestKeypad(
                                                      kid: true,
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
                                                    ),
                                                  ),
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
                                          if (state.status !=
                                              ParentalGateStatus.failure)
                                            Text(
                                              'This keeps settings and purchases safe.',
                                              style: NestType.caption(
                                                color: context.nest.ink2,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          if (state.status ==
                                              ParentalGateStatus.failure)
                                            const SizedBox.shrink(),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
  const new();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Equal-height placeholders for the instruction/question lines,
        // so the modal frame does not jump when data arrives.
        const SizedBox(height: 22),
        const SizedBox(height: 24),
        const SizedBox(height: NestSpacing.s4),
        const SizedBox(height: 64),
        const SizedBox(height: NestSpacing.s4),
        SizedBox(
          height: 352,
          child: Center(
            child: Semantics(
              label: 'Loading the grown-ups check',
              child: CircularProgressIndicator(color: context.nest.leaf),
            ),
          ),
        ),
        const SizedBox(height: NestSpacing.s3),
        const SizedBox(height: 56),
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
          minHeight: 44,
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
        const SizedBox(height: NestSpacing.s2 + NestSpacing.gap2),
        Text(
          'This keeps settings and purchases safe.',
          style: NestType.caption(color: tokens.ink2),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
