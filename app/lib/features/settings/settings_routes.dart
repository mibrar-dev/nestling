import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_event.dart';
import 'package:nestling/features/settings/presentation/views/settings_view.dart';

abstract final class SettingsRouteNames {
  static const String settings = 'settings';
}

abstract final class SettingsRoutePaths {
  static const String settings = '/settings';
}

final GoRoute settingsRoute = GoRoute(
  path: SettingsRoutePaths.settings,
  name: SettingsRouteNames.settings,
  builder: (context, state) {
    return BlocProvider<SettingsBloc>(
      create: (_) =>
          GetIt.instance<SettingsBloc>()..add(const SettingsLoadRequested()),
      child: const SettingsView(),
    );
  },
);

final List<RouteBase> settingsRoutes = <RouteBase>[settingsRoute];
