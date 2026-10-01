import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_bloc.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_event.dart';
import 'package:nestling/features/paywall/presentation/views/paywall_view.dart';

abstract final class PaywallRouteNames {
  static const String paywall = 'paywall';
}

abstract final class PaywallRoutePaths {
  static const String paywall = '/paywall';
}

final GoRoute paywallRoute = GoRoute(
  path: PaywallRoutePaths.paywall,
  name: PaywallRouteNames.paywall,
  builder: (context, state) {
    return BlocProvider<PaywallBloc>(
      create: (_) =>
          GetIt.instance<PaywallBloc>()..add(const PaywallLoadRequested()),
      child: const PaywallView(),
    );
  },
);

final List<RouteBase> paywallRoutes = <RouteBase>[paywallRoute];
