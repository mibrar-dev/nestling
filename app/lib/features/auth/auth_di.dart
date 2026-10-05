import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/current_family.dart';
import 'package:nestling/features/auth/data/auth_repository_impl.dart';
import 'package:nestling/features/auth/domain/auth_repository.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_bloc.dart';

/// Registers the Auth feature. The repository is Drift-backed; the old
/// in-memory fake data source is kept on disk for reference but is NOT
/// wired into the app.
void registerAuth(GetIt sl) {
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        db: sl<AppDatabase>(),
        currentFamily: sl<CurrentFamily>(),
      ),
    );
  }
  if (!sl.isRegistered<AuthBloc>()) {
    sl.registerFactory<AuthBloc>(
      () => AuthBloc(repository: sl<AuthRepository>()),
    );
  }
}
