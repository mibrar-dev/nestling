import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/features/family/presentation/bloc/family_bloc.dart';
import 'package:nestling/features/family/presentation/bloc/family_event.dart';
import 'package:nestling/features/family/presentation/views/add_children_view.dart';
import 'package:nestling/features/family/presentation/views/child_profile_view.dart';

abstract final class FamilyRouteNames {
  static const String addChildren = 'family-add-children';
  static const String childProfile = 'family-child-profile';
}

abstract final class FamilyRoutePaths {
  static const String addChildren = '/add-children';
  static const String childProfile = '/child-profile';
}

final GoRoute addChildrenRoute = GoRoute(
  path: FamilyRoutePaths.addChildren,
  name: FamilyRouteNames.addChildren,
  builder: (context, state) {
    return BlocProvider<FamilyBloc>(
      create: (_) =>
          GetIt.instance<FamilyBloc>()..add(const FamilyLoadRequested()),
      child: const AddChildrenView(),
    );
  },
);

final GoRoute childProfileRoute = GoRoute(
  path: FamilyRoutePaths.childProfile,
  name: FamilyRouteNames.childProfile,
  builder: (context, state) {
    // P15-BUG-1: P05's Edit pencil (`kid_card_grid.dart`) and P08's kid
    // cards (`today_loaded_body.dart`) navigate with `?childId=`; persist a
    // valid id through the session BEFORE the first load so `watchProfile`
    // — and every sibling screen — follows it. The repository ignores
    // unknown ids, so they fall back to the first-created child. No P05/P08
    // change required.
    final requested = state.uri.queryParameters['childId'];
    return BlocProvider<FamilyBloc>(
      create: (_) {
        final bloc = GetIt.instance<FamilyBloc>();
        if (requested != null) {
          bloc.add(FamilyChildSelected(childId: requested));
        }
        bloc.add(const FamilyLoadRequested());
        return bloc;
      },
      // P15-BUG-9: the Family branch page stays alive inside the
      // `StatefulShellRoute`, so a later `go('/child-profile?childId=…')`
      // updates it in place and `create` above never re-runs. The wrapper
      // follows the *route*: it re-dispatches the selection whenever the
      // query id changes while mounted. `selectChild` is idempotent and
      // membership-gated, so re-dispatching is safe.
      child: _ChildProfileRoute(requested: requested),
    );
  },
);

/// Follows the route's `?childId=` for the lifetime of the branch page (see
/// above). Dispatch lives here — not in `ChildProfileView`, which the UI
/// builder owns — so the view never sees selection plumbing.
class _ChildProfileRoute extends StatefulWidget {
  const _ChildProfileRoute({required this.requested});

  /// The `?childId=` the route carries, if any.
  final String? requested;

  @override
  State<_ChildProfileRoute> createState() => _ChildProfileRouteState();
}

class _ChildProfileRouteState extends State<_ChildProfileRoute> {
  @override
  void didUpdateWidget(covariant _ChildProfileRoute oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requested != oldWidget.requested) {
      _select(widget.requested);
    }
  }

  void _select(String? requested) {
    if (requested == null) return;
    context.read<FamilyBloc>().add(FamilyChildSelected(childId: requested));
  }

  @override
  Widget build(BuildContext context) => const ChildProfileView();
}

final List<RouteBase> familyRoutes = <RouteBase>[
  addChildrenRoute,
  childProfileRoute,
];
