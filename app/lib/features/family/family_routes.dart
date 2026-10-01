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
    return BlocProvider<FamilyBloc>(
      create: (_) =>
          GetIt.instance<FamilyBloc>()..add(const FamilyLoadRequested()),
      child: const ChildProfileView(),
    );
  },
);

final List<RouteBase> familyRoutes = <RouteBase>[
  addChildrenRoute,
  childProfileRoute,
];
