import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/features/parental_gate/presentation/bloc/parental_gate_bloc.dart';
import 'package:nestling/features/parental_gate/presentation/bloc/parental_gate_event.dart';
import 'package:nestling/features/parental_gate/presentation/views/parental_gate_view.dart';

abstract final class ParentalGateRouteNames {
  static const String gate = 'parental-gate';
}

abstract final class ParentalGateRoutePaths {
  static const String gate = '/parental-gate';
}

final GoRoute parentalGateRoute = GoRoute(
  path: ParentalGateRoutePaths.gate,
  name: ParentalGateRouteNames.gate,
  builder: (context, state) {
    return BlocProvider<ParentalGateBloc>(
      create: (_) =>
          GetIt.instance<ParentalGateBloc>()
            ..add(const ParentalGateLoadRequested()),
      child: const ParentalGateView(),
    );
  },
);

final List<RouteBase> parentalGateRoutes = <RouteBase>[parentalGateRoute];
