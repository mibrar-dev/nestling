import 'package:get_it/get_it.dart';
import 'package:nestling/features/rewards/data/rewards_fake_data_source.dart';
import 'package:nestling/features/rewards/data/rewards_repository_impl.dart';
import 'package:nestling/features/rewards/domain/rewards_repository.dart';
import 'package:nestling/features/rewards/presentation/bloc/rewards_bloc.dart';

void registerRewards(GetIt sl) {
  if (!sl.isRegistered<RewardsFakeDataSource>()) {
    sl.registerLazySingleton<RewardsFakeDataSource>(
      () => const RewardsFakeDataSource(),
    );
  }
  if (!sl.isRegistered<RewardsRepository>()) {
    sl.registerLazySingleton<RewardsRepository>(
      () => RewardsRepositoryImpl(dataSource: sl<RewardsFakeDataSource>()),
    );
  }
  if (!sl.isRegistered<RewardsBloc>()) {
    sl.registerFactory<RewardsBloc>(
      () => RewardsBloc(repository: sl<RewardsRepository>()),
    );
  }
}
