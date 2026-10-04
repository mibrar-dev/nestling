import 'dart:async';
import 'dart:math' as math;

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
import 'package:nestling/features/kid_home/presentation/widgets/kid_style_helpers.dart';
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
      if (child == null) {
        // Revert the 4th digit instead of leaving 4 dots with no pending
        // outcome: adding is blocked at length 4, so only Delete would
        // recover without this edit (review finding 2 / FIXES_1 #2).
        setState(_entered.removeLast);
        return;
      }
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
          // K02-BUG-3: re-check the child at navigation time — a same-turn
          // swap to a PIN'd child must NOT skip the PIN.
          final current = context.read<KidHomeBloc>().state;
          final noPin = current.child;
          if (mounted) {
            if (noPin != null && !noPin.pinSet) {
              context.go(KidHomeRoutePaths.home);
            } else {
              // Declined (K02-BUG-3): release the latch so a LATER no-PIN
              // state can advance again (K02-BUG-5).
              setState(() => _noPinHandled = false);
            }
          }
        });
      },
      child: BlocListener<KidHomeBloc, KidHomeState>(
        listenWhen: (previous, current) =>
            previous.pinPassed != current.pinPassed && current.pinPassed,
        listener: (context, state) {
          // K02-BUG-4: a wrong-code toast must not outlive the successful
          // retry that navigates away.
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
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

  /// `.k2-ava` (`K02-pin.html:22`): the tinted disc that wraps `.avatar.s96`.
  /// Named because it is a screen-local design value, not a spacing token —
  /// another screen wanting it asks for a shared token (SHARED_REQUEST #1).
  static const double avatarDisc = 128;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    final nickname = child.nickname;
    final initial = kidAvatarInitial(nickname);
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
                        width: avatarDisc,
                        height: avatarDisc,
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
                          borderRadius: NestRadii.allPill,
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
                        // K02-BUG-2: at 320 px + 1.3 text scale a long
                        // nickname needs 3 lines — a hard cap of 2 silently
                        // drops the sentence's tail (RenderParagraph clips
                        // without an overflow error).
                        maxLines: 3,
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
                      // ORCHESTRATOR_NOTES 07:13 follow-up: the shared
                      // keypad-grid fix now governs pitch; K02 applies the
                      // documented shrink-wrap fit (the K02 body is the
                      // centred `.k2-body` flex column). No local spacing.
                      // While a check is in flight the keys are inert: both
                      // callbacks early-return on `_awaiting`, so a pointer tap
                      // AND a VoiceOver/TalkBack `SemanticsAction.tap` both
                      // change nothing and the code cannot pass four digits.
                      // Tried `AbsorbPointer(absorbing: awaiting)` for the
                      // RULES §8 disabled look (no ripple) — it also removes
                      // the keys' semantics nodes, which contradicts the same
                      // rule (every key must keep advertising `tap`) and
                      // `k02_bugs_test.dart`'s "dots stay non-interactive"
                      // probe, which taps `Digit 9` mid-check by label. Reverted.
                      // TODO(K02): SHARED_REQUEST #1 — a shared
                      // `NestKeypad(enabled: …)` (as `NestIconButton` has)
                      // would report `enabled: false` and drop the ripple while
                      // keeping each key's node addressable.
                      NestKeypad(
                        onKey: onKey,
                        onDelete: onDelete,
                        kid: true,
                        fit: NestKeypadFit.shrinkWrap,
                      ),
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

/// In-device-safe bottom reserve for the loading/failure fallbacks:
/// the loaded body's inset, with the 34 px design floor for devices that
/// report no bottom inset. `NestHomeIndicator` only reserves when the
/// mock-glyph flag is off, so it doesn't honour the real inset.
class _BottomInset extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: math.max(
        MediaQuery.viewPaddingOf(context).bottom,
        NestDevice.homeH,
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
            const _BottomInset(),
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
            const _BottomInset(),
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
            const _BottomInset(),
          ],
        ),
      ),
    );
  }
}
