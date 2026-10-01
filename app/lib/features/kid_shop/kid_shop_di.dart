import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/features/kid_shop/data/kid_shop_repository_impl.dart';
import 'package:nestling/features/kid_shop/domain/kid_shop_repository.dart';
import 'package:nestling/features/kid_shop/presentation/bloc/kid_shop_bloc.dart';

/// Registers the KidShop feature. The repository is Drift-backed; the old
/// in-memory fake data source is kept on disk for reference but is NOT
/// wired into the app.
void registerKidShop(GetIt sl) {
  if (!sl.isRegistered<KidShopRepository>()) {
    sl.registerLazySingleton<KidShopRepository>(
      () => KidShopRepositoryImpl(db: sl<AppDatabase>()),
    );
  }
  if (!sl.isRegistered<KidShopBloc>()) {
    sl.registerFactory<KidShopBloc>(
      () => KidShopBloc(repository: sl<KidShopRepository>()),
    );
  }
}
