import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_bloc.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_event.dart';
import 'package:nestling/features/kid_home/presentation/views/kid_home_view.dart';
import 'package:nestling/features/kid_home/presentation/views/kid_pin_view.dart';
import 'package:nestling/features/kid_home/presentation/views/profile_picker_view.dart';
import 'package:nestling/features/kid_home/presentation/views/quest_complete_view.dart';
import 'package:nestling/features/kid_home/presentation/views/quest_detail_view.dart';

abstract final class KidHomeRouteNames {
  static const String picker = 'kid-who-is-playing';
  static const String pin = 'kid-pin';
  static const String home = 'kid-home';
  static const String homeDone = 'kid-home-done';
  static const String detail = 'kid-quest-detail';
  static const String complete = 'kid-quest-complete';
}

abstract final class KidHomeRoutePaths {
  static const String picker = '/who-is-playing';
  static const String pin = '/kid-pin';
  static const String home = '/kid-home';
  static const String homeDone = '/kid-home-done';
  static const String detail = '/quest-detail';
  static const String complete = '/quest-complete';
}

final GoRoute profilePickerRoute = GoRoute(
  path: KidHomeRoutePaths.picker,
  name: KidHomeRouteNames.picker,
  builder: (context, state) {
    return BlocProvider<KidHomeBloc>(
      create: (_) =>
          GetIt.instance<KidHomeBloc>()..add(const KidHomeLoadRequested()),
      child: const ProfilePickerView(),
    );
  },
);

final GoRoute kidPinRoute = GoRoute(
  path: KidHomeRoutePaths.pin,
  name: KidHomeRouteNames.pin,
  builder: (context, state) {
    return BlocProvider<KidHomeBloc>(
      create: (_) =>
          GetIt.instance<KidHomeBloc>()..add(const KidHomeLoadRequested()),
      child: const KidPinView(),
    );
  },
);

final GoRoute kidHomeRoute = GoRoute(
  path: KidHomeRoutePaths.home,
  name: KidHomeRouteNames.home,
  builder: (context, state) {
    return BlocProvider<KidHomeBloc>(
      create: (_) =>
          GetIt.instance<KidHomeBloc>()..add(const KidHomeLoadRequested()),
      child: const KidHomeView(),
    );
  },
);

final GoRoute kidHomeDoneRoute = GoRoute(
  path: KidHomeRoutePaths.homeDone,
  name: KidHomeRouteNames.homeDone,
  builder: (context, state) {
    return BlocProvider<KidHomeBloc>(
      create: (_) =>
          GetIt.instance<KidHomeBloc>()..add(const KidHomeLoadRequested()),
      child: const KidHomeView(),
    );
  },
);

final GoRoute questDetailRoute = GoRoute(
  path: KidHomeRoutePaths.detail,
  name: KidHomeRouteNames.detail,
  builder: (context, state) {
    return BlocProvider<KidHomeBloc>(
      create: (_) =>
          GetIt.instance<KidHomeBloc>()..add(const KidHomeLoadRequested()),
      child: const QuestDetailView(),
    );
  },
);

final GoRoute questCompleteRoute = GoRoute(
  path: KidHomeRoutePaths.complete,
  name: KidHomeRouteNames.complete,
  builder: (context, state) {
    return BlocProvider<KidHomeBloc>(
      create: (_) =>
          GetIt.instance<KidHomeBloc>()..add(const KidHomeLoadRequested()),
      child: const QuestCompleteView(),
    );
  },
);

final List<RouteBase> kidHomeRoutes = <RouteBase>[
  profilePickerRoute,
  kidPinRoute,
  kidHomeRoute,
  kidHomeDoneRoute,
  questDetailRoute,
  questCompleteRoute,
];
