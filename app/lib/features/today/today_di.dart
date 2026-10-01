import 'package:get_it/get_it.dart';
import 'package:nestling/features/today/data/today_fake_data_source.dart';
import 'package:nestling/features/today/data/today_repository_impl.dart';
import 'package:nestling/features/today/domain/today_repository.dart';
import 'package:nestling/features/today/presentation/bloc/today_bloc.dart';

void registerToday(GetIt sl) {
  if (!sl.isRegistered<TodayFakeDataSource>()) {
    sl.registerLazySingleton<TodayFakeDataSource>(
      () => const TodayFakeDataSource(),
    );
  }
  if (!sl.isRegistered<TodayRepository>()) {
    sl.registerLazySingleton<TodayRepository>(
      () => TodayRepositoryImpl(dataSource: sl<TodayFakeDataSource>()),
    );
  }
  if (!sl.isRegistered<TodayBloc>()) {
    sl.registerFactory<TodayBloc>(
      () => TodayBloc(repository: sl<TodayRepository>()),
    );
  }
}
