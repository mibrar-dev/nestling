import 'package:get_it/get_it.dart';
import 'package:nestling/features/kid_jar/data/kid_jar_fake_data_source.dart';
import 'package:nestling/features/kid_jar/data/kid_jar_repository_impl.dart';
import 'package:nestling/features/kid_jar/domain/kid_jar_repository.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_bloc.dart';

void registerKidJar(GetIt sl) {
  if (!sl.isRegistered<KidJarFakeDataSource>()) {
    sl.registerLazySingleton<KidJarFakeDataSource>(
      () => const KidJarFakeDataSource(),
    );
  }
  if (!sl.isRegistered<KidJarRepository>()) {
    sl.registerLazySingleton<KidJarRepository>(
      () => KidJarRepositoryImpl(dataSource: sl<KidJarFakeDataSource>()),
    );
  }
  if (!sl.isRegistered<KidJarBloc>()) {
    sl.registerFactory<KidJarBloc>(
      () => KidJarBloc(repository: sl<KidJarRepository>()),
    );
  }
}
