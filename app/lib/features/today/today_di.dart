import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/features/today/data/today_repository_impl.dart';
import 'package:nestling/features/today/domain/today_repository.dart';
import 'package:nestling/features/today/presentation/bloc/today_bloc.dart';

/// Registers the Today feature. The repository is Drift-backed; the old
/// in-memory fake data source is kept on disk for reference but is NOT
/// wired into the app.
void registerToday(GetIt sl) {
  if (!sl.isRegistered<TodayRepository>()) {
    sl.registerLazySingleton<TodayRepository>(
      () => TodayRepositoryImpl(db: sl<AppDatabase>()),
    );
  }
  if (!sl.isRegistered<TodayBloc>()) {
    sl.registerFactory<TodayBloc>(
      () => TodayBloc(repository: sl<TodayRepository>()),
    );
  }
}
