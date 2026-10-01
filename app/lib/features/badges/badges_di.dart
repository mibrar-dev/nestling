import 'package:get_it/get_it.dart';
import 'package:nestling/features/badges/data/badges_fake_data_source.dart';
import 'package:nestling/features/badges/data/badges_repository_impl.dart';
import 'package:nestling/features/badges/domain/badges_repository.dart';
import 'package:nestling/features/badges/presentation/bloc/badges_bloc.dart';

void registerBadges(GetIt sl) {
  if (!sl.isRegistered<BadgesFakeDataSource>()) {
    sl.registerLazySingleton<BadgesFakeDataSource>(
      () => const BadgesFakeDataSource(),
    );
  }
  if (!sl.isRegistered<BadgesRepository>()) {
    sl.registerLazySingleton<BadgesRepository>(
      () => BadgesRepositoryImpl(dataSource: sl<BadgesFakeDataSource>()),
    );
  }
  if (!sl.isRegistered<BadgesBloc>()) {
    sl.registerFactory<BadgesBloc>(
      () => BadgesBloc(repository: sl<BadgesRepository>()),
    );
  }
}
