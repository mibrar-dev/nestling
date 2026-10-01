import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/features/today/presentation/bloc/today_bloc.dart';
import 'package:nestling/features/today/presentation/bloc/today_event.dart';
import 'package:nestling/features/today/presentation/views/today_empty_view.dart';
import 'package:nestling/features/today/presentation/views/today_view.dart';

abstract final class TodayRouteNames {
  static const String today = 'today';
  static const String todayEmpty = 'today-empty';
}

abstract final class TodayRoutePaths {
  static const String today = '/today';
  static const String todayEmpty = '/today-empty';
}

final GoRoute todayRoute = GoRoute(
  path: TodayRoutePaths.today,
  name: TodayRouteNames.today,
  builder: (context, state) {
    return BlocProvider<TodayBloc>(
      create: (_) =>
          GetIt.instance<TodayBloc>()..add(const TodayLoadRequested()),
      child: const TodayView(),
    );
  },
);

final GoRoute todayEmptyRoute = GoRoute(
  path: TodayRoutePaths.todayEmpty,
  name: TodayRouteNames.todayEmpty,
  builder: (context, state) {
    return BlocProvider<TodayBloc>(
      create: (_) =>
          GetIt.instance<TodayBloc>()..add(const TodayLoadRequested()),
      child: const TodayEmptyView(),
    );
  },
);

final List<RouteBase> todayRoutes = <RouteBase>[todayRoute, todayEmptyRoute];
