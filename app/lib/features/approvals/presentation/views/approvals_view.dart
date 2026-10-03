import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_event.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_state.dart';
import 'package:nestling/features/approvals/presentation/widgets/approvals_loaded_body.dart';

/// P11 · Approvals, route `/approvals`.
///
/// Pushed top-level (outside the tab shell), so this view owns its own
/// chrome: `NestStatusBar` + compact `NestNavBar` + the scroll body +
/// `NestBottomCta`. No `AppBar`, no `NestTabBar`.
///
/// The count in the title and in "Approve all (N)" is the live
/// `state.items.length` — DATA OVER MOCKS: the designs hard-code `(3)`, the
/// seeded inbox happens to hold 3 rows today, and the number must follow the
/// database as rows are approved.
class ApprovalsView extends StatelessWidget {
  const ApprovalsView({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.nest;
    return Scaffold(
      backgroundColor: tokens.paper,
      body: BlocListener<ApprovalsBloc, ApprovalsState>(
        // Approve / not-yet / approve-all failures arrive as `actionError`
        // (error path only — not in the design). Show each one once, then let
        // the bloc clear it so a rebuild cannot re-fire the SnackBar.
        listenWhen: (previous, current) =>
            current.actionError != null &&
            current.actionError != previous.actionError,
        listener: (context, state) {
          final message = state.actionError;
          if (message == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  message,
                  style: NestType.bodySmall(color: tokens.onLeaf),
                ),
                backgroundColor: tokens.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          context.read<ApprovalsBloc>().add(
            const ApprovalsActionErrorConsumed(),
          );
        },
        child: BlocBuilder<ApprovalsBloc, ApprovalsState>(
          builder: (context, state) {
            return Column(
              children: <Widget>[
                const NestStatusBar(),
                NestNavBar(
                  compact: true,
                  title: 'Waiting for you (${state.items.length})',
                  onBack: () {
                    // Pushed from Today's "Review" button. Falling back to
                    // Today keeps a cold `/approvals` launch (INITIAL_ROUTE)
                    // from trapping the parent on a dead end. `'/today'` is
                    // `TodayRoutePaths.today`; it is inlined on purpose so this
                    // feature does not import another feature's routes.
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/today');
                    }
                  },
                  backSemanticLabel: 'Back to Today',
                ),
                Expanded(child: _body(context, state)),
                // `NestBottomCta` paints `surface` to the physical screen edge
                // (owner bottom-edge rule) and disappears with the inbox: an
                // "Approve all (0)" bar over the empty state would be a lie.
                if (state.status == ApprovalsStatus.loaded &&
                    state.items.isNotEmpty)
                  NestBottomCta(
                    child: NestButton(
                      key: const ValueKey<String>('p11_approve_all'),
                      label: 'Approve all (${state.items.length})',
                      // 52 is NestButton's default; `.bottom-cta .btn`
                      // { min-height: 52px } restates it.
                      loading: state.approveAllBusy,
                      onPressed: state.approveAllBusy
                          ? null
                          : () => context.read<ApprovalsBloc>().add(
                              const ApprovalsApproveAllRequested(),
                            ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ApprovalsState state) {
    final tokens = context.nest;
    switch (state.status) {
      case ApprovalsStatus.initial:
      case ApprovalsStatus.loading:
        return Center(child: CircularProgressIndicator(color: tokens.leaf));
      case ApprovalsStatus.failure:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(NestSpacing.s5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: NestSpacing.s4,
              children: <Widget>[
                Text(
                  state.errorMessage ?? 'Something went wrong',
                  style: NestType.bodySmall(color: tokens.ink2),
                  textAlign: TextAlign.center,
                  softWrap: true,
                ),
                NestButton(
                  key: const ValueKey<String>('p11_try_again'),
                  label: 'Try again',
                  variant: NestButtonVariant.secondary,
                  onPressed: () => context.read<ApprovalsBloc>().add(
                    const ApprovalsLoadRequested(),
                  ),
                ),
              ],
            ),
          ),
        );
      case ApprovalsStatus.loaded:
        return ApprovalsLoadedBody(
          items: state.items,
          busyIds: state.busyIds,
          onNotYet: (id) => context.read<ApprovalsBloc>().add(
            ApprovalsNotYetRequested(completionId: id),
          ),
          onApprove: (id) => context.read<ApprovalsBloc>().add(
            ApprovalsApproveRequested(completionId: id),
          ),
        );
    }
  }
}
