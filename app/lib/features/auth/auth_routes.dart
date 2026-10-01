import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_event.dart';
import 'package:nestling/features/auth/presentation/views/create_account_view.dart';

abstract final class AuthRouteNames {
  static const String createAccount = 'auth-create-account';
}

abstract final class AuthRoutePaths {
  static const String createAccount = '/create-account';
}

final GoRoute createAccountRoute = GoRoute(
  path: AuthRoutePaths.createAccount,
  name: AuthRouteNames.createAccount,
  builder: (context, state) {
    return BlocProvider<AuthBloc>(
      create: (_) => GetIt.instance<AuthBloc>()..add(const AuthLoadRequested()),
      child: const CreateAccountView(),
    );
  },
);

final List<RouteBase> authRoutes = <RouteBase>[createAccountRoute];
