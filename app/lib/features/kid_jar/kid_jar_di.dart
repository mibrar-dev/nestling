import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/features/kid_jar/data/kid_jar_repository_impl.dart';
import 'package:nestling/features/kid_jar/domain/kid_jar_repository.dart';
import 'package:nestling/features/kid_jar/presentation/bloc/kid_jar_bloc.dart';

/// Registers the KidJar feature. The repository is Drift-backed; the old
/// in-memory fake data source is kept on disk for reference but is NOT
/// wired into the app.
void registerKidJar(GetIt sl) {
  if (!sl.isRegistered<KidJarRepository>()) {
    sl.registerLazySingleton<KidJarRepository>(
      () => KidJarRepositoryImpl(db: sl<AppDatabase>()),
    );
  }
  if (!sl.isRegistered<KidJarBloc>()) {
    sl.registerFactory<KidJarBloc>(
      () => KidJarBloc(repository: sl<KidJarRepository>()),
    );
  }
}
