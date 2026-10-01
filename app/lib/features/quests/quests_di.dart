import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/features/quests/data/quests_repository_impl.dart';
import 'package:nestling/features/quests/domain/quests_repository.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_bloc.dart';

/// Registers the Quests feature. The repository is Drift-backed; the old
/// in-memory fake data source is kept on disk for reference but is NOT
/// wired into the app.
void registerQuests(GetIt sl) {
  if (!sl.isRegistered<QuestsRepository>()) {
    sl.registerLazySingleton<QuestsRepository>(
      () => QuestsRepositoryImpl(db: sl<AppDatabase>()),
    );
  }
  if (!sl.isRegistered<QuestsBloc>()) {
    sl.registerFactory<QuestsBloc>(
      () => QuestsBloc(repository: sl<QuestsRepository>()),
    );
  }
}
