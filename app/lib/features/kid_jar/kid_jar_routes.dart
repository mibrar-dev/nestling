import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_bloc.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_event.dart';
import 'package:nestling/features/kid_jar/presentation/views/my_jar_view.dart';
import 'package:nestling/features/kid_jar/presentation/views/payout_day_view.dart';

abstract final class KidJarRouteNames {
  static const String jar = 'kid-my-jar';
  static const String payoutDay = 'kid-payout-day';
}

abstract final class KidJarRoutePaths {
  static const String jar = '/my-jar';
  static const String payoutDay = '/payout-day';
}

final GoRoute myJarRoute = GoRoute(
  path: KidJarRoutePaths.jar,
  name: KidJarRouteNames.jar,
  builder: (context, state) {
    return BlocProvider<KidJarBloc>(
      create: (_) =>
          GetIt.instance<KidJarBloc>()..add(const KidJarLoadRequested()),
      child: const MyJarView(),
    );
  },
);

final GoRoute payoutDayRoute = GoRoute(
  path: KidJarRoutePaths.payoutDay,
  name: KidJarRouteNames.payoutDay,
  builder: (context, state) {
    return BlocProvider<KidJarBloc>(
      create: (_) =>
          GetIt.instance<KidJarBloc>()..add(const KidJarPayoutRequested()),
      child: const PayoutDayView(),
    );
  },
);

final List<RouteBase> kidJarRoutes = <RouteBase>[myJarRoute, payoutDayRoute];
