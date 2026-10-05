import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/current_family.dart';
import 'package:nestling/features/rewards/data/rewards_repository_impl.dart';
import 'package:nestling/features/rewards/domain/rewards_repository.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_bloc.dart';

/// Registers the Rewards feature. The repository is Drift-backed; the old
/// in-memory fake data source is kept on disk for reference but is NOT
/// wired into the app.
void registerRewards(GetIt sl) {
  if (!sl.isRegistered<RewardsRepository>()) {
    sl.registerLazySingleton<RewardsRepository>(
      () => RewardsRepositoryImpl(
        db: sl<AppDatabase>(),
        currentFamily: sl<CurrentFamily>(),
      ),
    );
  }
  if (!sl.isRegistered<RewardsBloc>()) {
    sl.registerFactory<RewardsBloc>(
      () => RewardsBloc(repository: sl<RewardsRepository>()),
    );
  }
}
