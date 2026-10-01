import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_bloc.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_event.dart';
import 'package:nestling/features/pocket_money/presentation/views/money_ledger_view.dart';
import 'package:nestling/features/pocket_money/presentation/views/payout_view.dart';
import 'package:nestling/features/pocket_money/presentation/views/pocket_money_setup_view.dart';

abstract final class PocketMoneyRouteNames {
  static const String setup = 'pocket-money-setup';
  static const String ledger = 'pocket-money-ledger';
  static const String payout = 'pocket-money-payout';
}

abstract final class PocketMoneyRoutePaths {
  static const String setup = '/pocket-money-setup';
  static const String ledger = '/money';
  static const String payout = '/payout';
}

final GoRoute pocketMoneySetupRoute = GoRoute(
  path: PocketMoneyRoutePaths.setup,
  name: PocketMoneyRouteNames.setup,
  builder: (context, state) {
    return BlocProvider<PocketMoneyBloc>(
      create: (_) =>
          GetIt.instance<PocketMoneyBloc>()
            ..add(const PocketMoneyLoadRequested()),
      child: const PocketMoneySetupView(),
    );
  },
);

final GoRoute moneyLedgerRoute = GoRoute(
  path: PocketMoneyRoutePaths.ledger,
  name: PocketMoneyRouteNames.ledger,
  builder: (context, state) {
    return BlocProvider<PocketMoneyBloc>(
      create: (_) =>
          GetIt.instance<PocketMoneyBloc>()
            ..add(const PocketMoneyLoadRequested()),
      child: const MoneyLedgerView(),
    );
  },
);

final GoRoute payoutRoute = GoRoute(
  path: PocketMoneyRoutePaths.payout,
  name: PocketMoneyRouteNames.payout,
  builder: (context, state) {
    return BlocProvider<PocketMoneyBloc>(
      create: (_) =>
          GetIt.instance<PocketMoneyBloc>()
            ..add(const PocketMoneyLoadRequested()),
      child: const PayoutView(),
    );
  },
);

final List<RouteBase> pocketMoneyRoutes = <RouteBase>[
  pocketMoneySetupRoute,
  moneyLedgerRoute,
  payoutRoute,
];
