import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/features/kid_shop/presentation/bloc/kid_shop_bloc.dart';
import 'package:nestling/features/kid_shop/presentation/bloc/kid_shop_event.dart';
import 'package:nestling/features/kid_shop/presentation/views/reward_shop_view.dart';

abstract final class KidShopRouteNames {
  static const String shop = 'kid-reward-shop';
}

abstract final class KidShopRoutePaths {
  static const String shop = '/reward-shop';
}

final GoRoute rewardShopRoute = GoRoute(
  path: KidShopRoutePaths.shop,
  name: KidShopRouteNames.shop,
  builder: (context, state) {
    return BlocProvider<KidShopBloc>(
      create: (_) =>
          GetIt.instance<KidShopBloc>()..add(const KidShopLoadRequested()),
      child: const RewardShopView(),
    );
  },
);

final List<RouteBase> kidShopRoutes = <RouteBase>[rewardShopRoute];
