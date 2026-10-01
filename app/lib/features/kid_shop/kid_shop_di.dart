import 'package:get_it/get_it.dart';
import 'package:nestling/features/kid_shop/data/kid_shop_fake_data_source.dart';
import 'package:nestling/features/kid_shop/data/kid_shop_repository_impl.dart';
import 'package:nestling/features/kid_shop/domain/kid_shop_repository.dart';
import 'package:nestling/features/kid_shop/presentation/bloc/kid_shop_bloc.dart';

void registerKidShop(GetIt sl) {
  if (!sl.isRegistered<KidShopFakeDataSource>()) {
    sl.registerLazySingleton<KidShopFakeDataSource>(
      () => const KidShopFakeDataSource(),
    );
  }
  if (!sl.isRegistered<KidShopRepository>()) {
    sl.registerLazySingleton<KidShopRepository>(
      () => KidShopRepositoryImpl(dataSource: sl<KidShopFakeDataSource>()),
    );
  }
  if (!sl.isRegistered<KidShopBloc>()) {
    sl.registerFactory<KidShopBloc>(
      () => KidShopBloc(repository: sl<KidShopRepository>()),
    );
  }
}
