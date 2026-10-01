import 'package:get_it/get_it.dart';
import 'package:nestling/features/quests/data/quests_fake_data_source.dart';
import 'package:nestling/features/quests/data/quests_repository_impl.dart';
import 'package:nestling/features/quests/domain/quests_repository.dart';
import 'package:nestling/features/quests/presentation/bloc/quests_bloc.dart';

void registerQuests(GetIt sl) {
  if (!sl.isRegistered<QuestsFakeDataSource>()) {
    sl.registerLazySingleton<QuestsFakeDataSource>(
      () => const QuestsFakeDataSource(),
    );
  }
  if (!sl.isRegistered<QuestsRepository>()) {
    sl.registerLazySingleton<QuestsRepository>(
      () => QuestsRepositoryImpl(dataSource: sl<QuestsFakeDataSource>()),
    );
  }
  if (!sl.isRegistered<QuestsBloc>()) {
    sl.registerFactory<QuestsBloc>(
      () => QuestsBloc(repository: sl<QuestsRepository>()),
    );
  }
}
