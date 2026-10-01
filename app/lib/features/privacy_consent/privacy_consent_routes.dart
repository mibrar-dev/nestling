import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_bloc.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_event.dart';
import 'package:nestling/features/privacy_consent/presentation/views/privacy_consent_view.dart';

abstract final class PrivacyConsentRouteNames {
  static const String privacy = 'privacy-consent';
}

abstract final class PrivacyConsentRoutePaths {
  static const String privacy = '/privacy';
}

final GoRoute privacyConsentRoute = GoRoute(
  path: PrivacyConsentRoutePaths.privacy,
  name: PrivacyConsentRouteNames.privacy,
  builder: (context, state) {
    return BlocProvider<PrivacyConsentBloc>(
      create: (_) =>
          GetIt.instance<PrivacyConsentBloc>()
            ..add(const PrivacyConsentLoadRequested()),
      child: const PrivacyConsentView(),
    );
  },
);

final List<RouteBase> privacyConsentRoutes = <RouteBase>[privacyConsentRoute];
