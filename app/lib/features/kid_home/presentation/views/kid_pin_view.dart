import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/kid_home/domain/entities/kid_child.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_bloc.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_event.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_state.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';

/// K02 Kid PIN (`/kid-pin`): kid avatar, "Hi {name}!" greeting, 4-dot code
/// entry, kid keypad, and the "Forgot it?" caption. Local entry state only;
/// the bloc owns the check (`verifyPin`) and its one-shot outcomes.
class KidPinView extends StatefulWidget {
  const new({super.key});

  @override
  State<KidPinView> createState() => _KidPinViewState();
}

class _KidPinViewState extends State<KidPinView> {
  /// Digits entered locally (max 4). NOT in the bloc: keypad taps must not
  /// round-trip a stream emission.
  final List<String> _entered = <String>[];

  /// Local single-flight guard so a mid-check state emission cannot desync
  /// the keypad; driven from the view, not the bloc.
  bool _awaiting = false;

  /// No-PIN child auto-advance runs once (transient loading UI meanwhile).
  bool _noPinHandled = false;

  void _onKey(String digit) {
    if (_awaiting || _entered.length >= 4) return;
    setState(() => _entered.add(digit));
    if (_entered.length == 4) {
      final child = context.read<KidHomeBloc>().state.child;
      if (child == null) return;
      setState(() => _awaiting = true);
      context.read<KidHomeBloc>().add(
        KidHomePinSubmitted(childId: child.id, pin: _entered.join()),
      );
    }
  }

  void _onDelete() {
    if (_awaiting || _entered.isEmpty) return;
    setState(_entered.removeLast);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<KidHomeBloc, KidHomeState>(
      // No-PIN child (e.g. Leo): K01 sends every child through K02, so land
      // them straight on home, once.
      listenWhen: (previous, current) =>
          current.status == KidHomeStatus.loaded &&
          current.child != null &&
          !current.child!.pinSet,
      listener: (context, state) {
        if (_noPinHandled) return;
        _noPinHandled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(KidHomeRoutePaths.home);
        });
      },
      child: BlocListener<KidHomeBloc, KidHomeState>(
        listenWhen: (previous, current) =>
            previous.pinPassed != current.pinPassed && current.pinPassed,
        listener: (context, state) {
          context.go(KidHomeRoutePaths.home);
        },
        child: BlocListener<KidHomeBloc, KidHomeState>(
          listenWhen: (previous, current) =>
              previous.pinWrongNonce != current.pinWrongNonce,
          listener: (context, state) {
            setState(() {
              _entered.clear();
              _awaiting = false;
            });
            showNestToast(context, "That didn't work. Try again.");
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
                  if (!child.pinSet) {
                    // Auto-advance is scheduled by the listener above; show
                    // the transient loading UI meanwhile.
                    return const _KidLoading();
                  }
                  return _KidPinBody(
                    child: child,
                    enteredCount: _entered.length,
                    awaiting: _awaiting,
                    onKey: _onKey,
                    onDelete: _onDelete,
                  );
              }
            },
          ),
        ),
      ),
    );
  }
}

class _KidPinBody extends StatelessWidget {
  const new({
    required this.child,
    required this.enteredCount,
    required this.awaiting,
    required this.onKey,
    required this.onDelete,
  });

  final KidChild child;
  final int enteredCount;
  final bool awaiting;
  final ValueChanged<String> onKey;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final nickname = child.nickname;
    final initial = nickname.isEmpty ? '?' : nickname[0].toUpperCase();
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                NestSpacing.padSide,
                0,
                NestSpacing.padSide,
                NestSpacing.s1 + NestSpacing.gap2,
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
                        context.go(KidHomeRoutePaths.picker);
                      }
                    },
                  ),
                  const Spacer(),
                  const _GateLockButton(),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  NestSpacing.padSide,
                  0,
                  NestSpacing.padSide,
                  NestSpacing.s8,
                ),
                children: [
                  Column(
                    children: [
                      // `.k2-ava`: 128 tinted disc, inner `.avatar.s96`.
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: tokens.lilacTint,
                        ),
                        alignment: Alignment.center,
                        child: NestAvatar(
                          initial: initial,
                          size: NestAvatarSize.s96,
                          color: NestAvatarColor.lilac,
                        ),
                      ),
                      const SizedBox(height: NestSpacing.s5),
                      // `.k2-hi`: mark pill then the say line (`margin-top: 2`).
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: NestSpacing.s3,
                          vertical: NestSpacing.gap2,
                        ),
                        decoration: BoxDecoration(
                          color: tokens.lilacTint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'NESTLING',
                          // TODO(K02): SHARED_REQUEST #1 — shared
                          // `NestType.kidMark`; letter-spacing 1.28
                          // (.08em × 16) stays at this call site.
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            height: 22 / 16,
                            letterSpacing: 1.28,
                          ).copyWith(color: tokens.ink),
                        ),
                      ),
                      const SizedBox(height: NestSpacing.gap2),
                      Text(
                        'Hi $nickname! Enter your secret code',
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        // TODO(K02): SHARED_REQUEST #1 — shared
                        // `NestType.kidSay` (Nunito 800, 20/26).
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          height: 26 / 20,
                          letterSpacing: 0,
                          color: tokens.ink,
                        ),
                      ),
                      const SizedBox(height: NestSpacing.s5),
                      // While a check is in flight the dots announce the
                      // checking state; otherwise NestPinDots' own
                      // `N of 4 entered` label stands.
                      if (awaiting)
                        Semantics(
                          label: 'Checking your code',
                          child: ExcludeSemantics(
                            child: NestPinDots(total: 4, filled: enteredCount),
                          ),
                        )
                      else
                        NestPinDots(total: 4, filled: enteredCount),
                      const SizedBox(height: NestSpacing.s5),
                      // NOTE(K02): ORCHESTRATOR_NOTES (07:13) — NestKeypad
                      // pitch is being fixed on main (shared/keypad_grid)
                      // to match the CSS; do NOT re-space keys locally.
                      // After the merge, re-check key centres vs design.
                      NestKeypad(onKey: onKey, onDelete: onDelete, kid: true),
                      const SizedBox(height: NestSpacing.s5),
                      Text(
                        'Forgot it? Just ask a grown-up.',
                        textAlign: TextAlign.center,
                        style: NestType.kidCaption(color: tokens.ink2),
                      ),
                    ],
                  ),
                  // Home-indicator reserve: transparent, the shared meadow
                  // shows through to the physical screen edge (BOTTOM EDGE
                  // owner rule — K02 paints no bar).
                  SizedBox(height: MediaQuery.viewPaddingOf(context).bottom),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Parental-gate lock with a tap guard (same 20-line pattern as K03's
/// `_GateLockButton`): only one gate route per gesture burst, even on a
/// fast double tap.
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
                  label: 'Loading your secret code',
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
