import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/current_family.dart';
import 'package:nestling/features/kid_home/data/kid_home_repository_impl.dart';
import 'package:nestling/features/kid_home/domain/kid_home_repository.dart';
import 'package:nestling/features/kid_home/presentation/bloc/kid_home_bloc.dart';

/// Registers the KidHome feature. The repository is Drift-backed; the old
/// in-memory fake data source is kept on disk for reference but is NOT
/// wired into the app.
void registerKidHome(GetIt sl) {
  if (!sl.isRegistered<KidHomeRepository>()) {
    sl.registerLazySingleton<KidHomeRepository>(
      () => KidHomeRepositoryImpl(
        db: sl<AppDatabase>(),
        currentFamily: sl<CurrentFamily>(),
      ),
    );
  }
  if (!sl.isRegistered<KidHomeBloc>()) {
    sl.registerFactory<KidHomeBloc>(
      () => KidHomeBloc(repository: sl<KidHomeRepository>()),
    );
  }
}
