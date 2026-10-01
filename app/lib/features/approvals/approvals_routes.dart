import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_bloc.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_event.dart';
import 'package:nestling/features/approvals/presentation/views/approvals_view.dart';

abstract final class ApprovalsRouteNames {
  static const String approvals = 'approvals';
}

abstract final class ApprovalsRoutePaths {
  static const String approvals = '/approvals';
}

final GoRoute approvalsRoute = GoRoute(
  path: ApprovalsRoutePaths.approvals,
  name: ApprovalsRouteNames.approvals,
  builder: (context, state) {
    return BlocProvider<ApprovalsBloc>(
      create: (_) =>
          GetIt.instance<ApprovalsBloc>()..add(const ApprovalsLoadRequested()),
      child: const ApprovalsView(),
    );
  },
);

final List<RouteBase> approvalsRoutes = <RouteBase>[approvalsRoute];
