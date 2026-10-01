import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/features/badges/presentation/bloc/badges_bloc.dart';
import 'package:nestling/features/badges/presentation/bloc/badges_event.dart';
import 'package:nestling/features/badges/presentation/views/badges_view.dart';

abstract final class BadgesRouteNames {
  static const String badges = 'badges';
}

abstract final class BadgesRoutePaths {
  static const String badges = '/badges';
}

final GoRoute badgesRoute = GoRoute(
  path: BadgesRoutePaths.badges,
  name: BadgesRouteNames.badges,
  builder: (context, state) {
    return BlocProvider<BadgesBloc>(
      create: (_) =>
          GetIt.instance<BadgesBloc>()..add(const BadgesLoadRequested()),
      child: const BadgesView(),
    );
  },
);

final List<RouteBase> badgesRoutes = <RouteBase>[badgesRoute];
