import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/features/pip/data/pip_repository_impl.dart';
import 'package:nestling/features/pip/domain/pip_repository.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_bloc.dart';

/// Registers the Pip feature. The repository is Drift-backed; the old
/// in-memory fake data source is kept on disk for reference but is NOT
/// wired into the app.
void registerPip(GetIt sl) {
  if (!sl.isRegistered<PipRepository>()) {
    sl.registerLazySingleton<PipRepository>(
      () => PipRepositoryImpl(db: sl<AppDatabase>()),
    );
  }
  if (!sl.isRegistered<PipBloc>()) {
    sl.registerFactory<PipBloc>(() => PipBloc(repository: sl<PipRepository>()));
  }
}
