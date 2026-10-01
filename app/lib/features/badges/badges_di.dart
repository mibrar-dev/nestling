import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/features/badges/data/badges_repository_impl.dart';
import 'package:nestling/features/badges/domain/badges_repository.dart';
import 'package:nestling/features/badges/presentation/bloc/badges_bloc.dart';

/// Registers the Badges feature. The repository is Drift-backed; the old
/// in-memory fake data source is kept on disk for reference but is NOT
/// wired into the app.
void registerBadges(GetIt sl) {
  if (!sl.isRegistered<BadgesRepository>()) {
    sl.registerLazySingleton<BadgesRepository>(
      () => BadgesRepositoryImpl(db: sl<AppDatabase>()),
    );
  }
  if (!sl.isRegistered<BadgesBloc>()) {
    sl.registerFactory<BadgesBloc>(
      () => BadgesBloc(repository: sl<BadgesRepository>()),
    );
  }
}
