import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:nestling/features/onboarding/presentation/views/value_tour_view.dart';
import 'package:nestling/features/onboarding/presentation/views/welcome_view.dart';

abstract final class OnboardingRouteNames {
  static const String welcome = 'onboarding-welcome';
  static const String valueTour = 'onboarding-value-tour';
}

abstract final class OnboardingRoutePaths {
  static const String welcome = '/welcome';
  static const String valueTour = '/value-tour';
}

final GoRoute welcomeRoute = GoRoute(
  path: OnboardingRoutePaths.welcome,
  name: OnboardingRouteNames.welcome,
  builder: (context, state) {
    return BlocProvider<OnboardingBloc>(
      create: (_) =>
          GetIt.instance<OnboardingBloc>()
            ..add(const OnboardingLoadRequested()),
      child: const WelcomeView(),
    );
  },
);

final GoRoute valueTourRoute = GoRoute(
  path: OnboardingRoutePaths.valueTour,
  name: OnboardingRouteNames.valueTour,
  builder: (context, state) {
    return BlocProvider<OnboardingBloc>(
      create: (_) =>
          GetIt.instance<OnboardingBloc>()
            ..add(const OnboardingLoadRequested()),
      child: const ValueTourView(),
    );
  },
);

final List<RouteBase> onboardingRoutes = <RouteBase>[
  welcomeRoute,
  valueTourRoute,
];
