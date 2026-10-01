import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_bloc.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_event.dart';
import 'package:nestling/features/pip/presentation/views/pip_evolution_view.dart';
import 'package:nestling/features/pip/presentation/views/pip_nest_view.dart';

abstract final class PipRouteNames {
  static const String nest = 'pip-nest';
  static const String evolution = 'pip-evolution';
}

abstract final class PipRoutePaths {
  static const String nest = '/pip';
  static const String evolution = '/pip-evolution';
}

final GoRoute pipNestRoute = GoRoute(
  path: PipRoutePaths.nest,
  name: PipRouteNames.nest,
  builder: (context, state) {
    return BlocProvider<PipBloc>(
      create: (_) => GetIt.instance<PipBloc>()..add(const PipLoadRequested()),
      child: const PipNestView(),
    );
  },
);

final GoRoute pipEvolutionRoute = GoRoute(
  path: PipRoutePaths.evolution,
  name: PipRouteNames.evolution,
  builder: (context, state) {
    return BlocProvider<PipBloc>(
      create: (_) => GetIt.instance<PipBloc>()..add(const PipLoadRequested()),
      child: const PipEvolutionView(),
    );
  },
);

final List<RouteBase> pipRoutes = <RouteBase>[pipNestRoute, pipEvolutionRoute];
