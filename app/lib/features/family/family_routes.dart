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
      child: const ChildProfileView(),
    );
  },
);

final List<RouteBase> familyRoutes = <RouteBase>[
  addChildrenRoute,
  childProfileRoute,
];
