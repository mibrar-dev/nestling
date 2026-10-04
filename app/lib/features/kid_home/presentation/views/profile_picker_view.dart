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
import 'package:nestling/features/kid_home/presentation/widgets/profile_tile.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';

/// K01 Who's playing? (`/who-is-playing`): the family's kid profiles in
/// creation order. Tapping a tile persists it as the active child
/// (`setActiveChild`) and the bloc's one-shot `selectedProfileId` sends
/// the view on to PIN or home.
class ProfilePickerView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<KidHomeBloc, KidHomeState>(
      listenWhen: (previous, current) =>
          previous.selectedProfileId != current.selectedProfileId &&
          current.selectedProfileId != null,
      listener: (context, state) {
        final id = state.selectedProfileId!;
        KidChild? tapped;
        for (final profile in state.profiles) {
          if (profile.id == id) {
            tapped = profile;
            break;
          }
        }
        if (tapped == null) return;
        unawaited(
          context.push(
            tapped.pinSet ? KidHomeRoutePaths.pin : KidHomeRoutePaths.home,
            extra: <String, Object>{'childId': tapped.id},
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
                return const _PickerLoading();
              case KidHomeStatus.failure:
                return const _PickerFailure();
              case KidHomeStatus.loaded:
                return _PickerLoaded(profiles: state.profiles);
            }
          },
        ),
      ),
    );
  }
}

/// The shared kid-mode chrome (sky + meadow, status bar, parental lock,
/// home indicator). Mirrors K03's screens; the only variation is [body]
/// inside the [Expanded] band.
class _PickerChrome extends StatelessWidget {
  const new({required this.body});

  final Widget body;

  @override
  Widget build(BuildContext context) {
    return KidScope(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Column(
          children: [
            const NestStatusBar(),
            const Padding(
              padding: EdgeInsets.fromLTRB(
                NestSpacing.padSide,
                0,
                NestSpacing.padSide,
                NestSpacing.s1,
              ),
              child: Row(children: [Spacer(), _GateLockButton()]),
            ),
            Expanded(child: body),
            const NestHomeIndicator(),
          ],
        ),
      ),
    );
  }
}

/// Parental-gate lock with a tap guard (same pattern as K03's
/// `_GateLockButton`): only one gate route per gesture burst.
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

class _PickerLoading extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return _PickerChrome(
      body: Center(
        child: Semantics(
          label: 'Loading profiles',
          child: CircularProgressIndicator(color: tokens.leaf),
        ),
      ),
    );
  }
}

class _PickerFailure extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return _PickerChrome(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: NestSpacing.s2,
            children: [
              const PipAvatar(style: PipStyle.mochi, stage: 1, size: 140),
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
    );
  }
}

class _PickerLoaded extends StatelessWidget {
  const new({required this.profiles});

  final List<KidChild> profiles;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return _PickerChrome(
      body: Column(
        children: [
          const SizedBox(height: NestSpacing.s4),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NestSpacing.padSide,
            ),
            child: NestBalancedText(
              'Who’s playing?',
              style: NestType.kidTitle(color: tokens.ink),
              maxLines: 2,
            ),
          ),
          const SizedBox(height: NestSpacing.s4),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NestSpacing.padSide,
            ),
            child: Text(
              'Tap your face to start',
              style: NestType.kidBody(color: tokens.ink2),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
          const SizedBox(height: NestSpacing.s4),
          // `.k1-mid { flex: 1 }`: the tiles band takes the leftover
          // height and centres the tiles in it. The band scrolls if the
          // tiles can't fit (320 px + 1.3 scale); the title, sub and
          // caption stay put, matching the design at 390×844.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: NestSpacing.padSide,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: profiles.isEmpty
                            ? Text(
                                'Ask a grown-up to add your profile.',
                                style: NestType.kidBody(color: tokens.ink2),
                                textAlign: TextAlign.center,
                              )
                            : Row(
                                spacing: NestSpacing.s4,
                                children: [
                                  for (final child in profiles)
                                    Expanded(
                                      child: ProfileTile(
                                        key: ProfileTile.keyFor(child),
                                        child: child,
                                        onSelected: () =>
                                            context.read<KidHomeBloc>().add(
                                              KidHomeProfileSelected(
                                                childId: child.id,
                                                pinSet: child.pinSet,
                                              ),
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: NestSpacing.s4),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: NestSpacing.padSide,
            ),
            child: Text(
              'Grown-ups: tap the lock to get back to your dashboard.',
              style: NestType.kidCaption(color: tokens.ink2),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
          ),
          const SizedBox(height: NestSpacing.s8),
        ],
      ),
    );
  }
}
