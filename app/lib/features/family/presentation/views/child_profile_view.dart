// P15 · Child profile (`/child-profile`, parent mode, feature `family`).
//
// The design is a tab-branch root (Family tab active): status-bar reserve,
// one scrolling column (see `child_profile_body.dart` for the measured
// anchors) and NO nav bar, back button or bottom CTA. The tab bar and the
// bottom edge belong to the shared `ParentShell`.
//
// States:
//   initial/loading → centred spinner (P05 pattern)
//   failure         → message + `Try again` (re-adds `FamilyLoadRequested`;
//                     the stream was closed by `_closeOnError`)
//   loaded, no child→ `NestEmptyState` with Pip stage-1 art and an
//                     `Add a child` CTA (`Seed.empty()`, or the last child
//                     was just removed)
//   loaded          → `ChildProfileBody`
//
// A remove failure keeps `status: loaded` and only sets `errorMessage`, so
// it surfaces as a toast (P12 precedent) instead of replacing the screen.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
// The v2 Pip widget is not in the design-system barrel.
import 'package:nestling/core/design_system/motion/pip_avatar.dart';
import 'package:nestling/features/family/family_routes.dart';
import 'package:nestling/features/family/presentation/bloc/family_bloc.dart';
import 'package:nestling/features/family/presentation/bloc/family_event.dart';
import 'package:nestling/features/family/presentation/bloc/family_state.dart';
import 'package:nestling/features/family/presentation/widgets/child_profile_body.dart';

class ChildProfileView extends StatefulWidget {
  const ChildProfileView({super.key});

  @override
  State<ChildProfileView> createState() => _ChildProfileViewState();
}

class _ChildProfileViewState extends State<ChildProfileView> {
  /// Last `?childId=` value dispatched to the bloc. The route's
  /// `BlocProvider.create` dispatches the first one; this state catches every
  /// later one.
  String? _seenChildId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // P15-BUG-9: this view is a page of a `StatefulShellRoute.indexedStack`,
    // so the Family branch stays alive — a later `go('/child-profile?childId=…')`
    // only updates the page with the new query; its `BlocProvider.create`
    // (and therefore its `FamilyChildSelected`) never re-runs. Reading
    // `GoRouterState.of(context)` registers a dependency on the router state,
    // so this method re-fires on the in-place update and the screen follows
    // the deep link instead of keeping the previous child. `selectChild` is
    // idempotent and membership-gated in the repository, so a duplicate
    // first-dispatch is harmless.
    final requested = GoRouterState.of(context).uri.queryParameters['childId'];
    if (requested != null && requested != _seenChildId) {
      _seenChildId = requested;
      context.read<FamilyBloc>().add(FamilyChildSelected(childId: requested));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Scaffold(
      backgroundColor: tokens.paper,
      body: BlocListener<FamilyBloc, FamilyState>(
        // Only the NON-destructive path toasts. `_closeOnError` sets
        // `errorMessage` on the `failure` state too, so an unscoped listener
        // printed the same raw exception twice — once in `_FailureBody` and
        // once in a snackbar on top of it (BUG P15-BUG-2). The failure state
        // has its own in-place retry, so it never needs a toast.
        //
        // A repeated IDENTICAL remove failure is still swallowed here
        // (Equatable drops the duplicate state) — clearing `errorMessage` needs
        // a new bloc event, so BUG P15-BUG-3 stays with the logic builder.
        listenWhen: (previous, current) =>
            current.status == FamilyStatus.loaded &&
            current.errorMessage != null &&
            previous.errorMessage != current.errorMessage,
        listener: (context, state) =>
            showNestToast(context, state.errorMessage!),
        child: BlocBuilder<FamilyBloc, FamilyState>(
          builder: (context, state) {
            switch (state.status) {
              case FamilyStatus.initial:
              case FamilyStatus.loading:
                return const _Pinned(
                  child: Center(child: CircularProgressIndicator()),
                );
              case FamilyStatus.failure:
                return _Pinned(
                  child: _FailureBody(
                    message: state.errorMessage,
                    onRetry: () => context.read<FamilyBloc>().add(
                      const FamilyLoadRequested(),
                    ),
                  ),
                );
              case FamilyStatus.loaded:
                final profile = state.profile;
                if (profile == null) return const _NoChildrenBody();
                return ChildProfileBody(profile: profile);
            }
          },
        ),
      ),
    );
  }
}

/// Keeps the 47 px status-bar reserve above whatever the screen renders, the
/// way `.status-bar` is a flex-shrink:0 sibling of `.scroll` in the design.
class _Pinned extends StatelessWidget {
  const _Pinned({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const NestStatusBar(),
        Expanded(child: child),
      ],
    );
  }
}

class _FailureBody extends StatelessWidget {
  const _FailureBody({required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: NestSpacing.padSide),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              message ?? 'Something went wrong',
              style: NestType.body(color: tokens.ink2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: NestSpacing.s4),
            NestButton(
              label: 'Try again',
              variant: NestButtonVariant.secondary,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

/// No children in the family (`Seed.empty()`): Pip stage-1 art with the
/// screen's own copy, and a CTA into the P05 funnel.
class _NoChildrenBody extends StatelessWidget {
  const _NoChildrenBody();

  @override
  Widget build(BuildContext context) {
    return _Pinned(
      child: SingleChildScrollView(
        child: NestEmptyState(
          // No child yet → the onboarding Pip look (mochi, sunny skin).
          art: const PipAvatar(style: PipStyle.mochi, stage: 1, size: 140),
          title: 'No children yet',
          message: 'Add your first child and their Pip will start to hatch.',
          action: NestButton(
            label: 'Add a child',
            onPressed: () => context.go(FamilyRoutePaths.addChildren),
          ),
        ),
      ),
    );
  }
}
