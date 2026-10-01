import 'package:get_it/get_it.dart';
import 'package:nestling/features/kid_home/data/kid_home_fake_data_source.dart';
import 'package:nestling/features/kid_home/data/kid_home_repository_impl.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_bloc.dart';

void registerKidHome(GetIt sl) {
  if (!sl.isRegistered<KidHomeFakeDataSource>()) {
    sl.registerLazySingleton<KidHomeFakeDataSource>(
      () => const KidHomeFakeDataSource(),
    );
  }
  if (!sl.isRegistered<KidHomeRepository>()) {
    sl.registerLazySingleton<KidHomeRepository>(
      () => KidHomeRepositoryImpl(dataSource: sl<KidHomeFakeDataSource>()),
    );
  }
  if (!sl.isRegistered<KidHomeBloc>()) {
    sl.registerFactory<KidHomeBloc>(
      () => KidHomeBloc(repository: sl<KidHomeRepository>()),
    );
  }
}
