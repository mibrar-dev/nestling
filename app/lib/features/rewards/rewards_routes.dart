import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_bloc.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_event.dart';
import 'package:nestling/features/rewards/presentation/views/rewards_view.dart';

abstract final class RewardsRouteNames {
  static const String rewards = 'rewards';
}

abstract final class RewardsRoutePaths {
  static const String rewards = '/rewards';
}

final GoRoute rewardsRoute = GoRoute(
  path: RewardsRoutePaths.rewards,
  name: RewardsRouteNames.rewards,
  builder: (context, state) {
    return BlocProvider<RewardsBloc>(
      create: (_) =>
          GetIt.instance<RewardsBloc>()..add(const RewardsLoadRequested()),
      child: const RewardsView(),
    );
  },
);

final List<RouteBase> rewardsRoutes = <RouteBase>[rewardsRoute];
