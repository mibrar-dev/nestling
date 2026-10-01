import 'package:get_it/get_it.dart';
import 'package:nestling/features/pip/data/pip_fake_data_source.dart';
import 'package:nestling/features/pip/data/pip_repository_impl.dart';
import 'package:nestling/features/pip/domain/pip_repository.dart';
import 'package:nestling/features/pip/presentation/bloc/pip_bloc.dart';

void registerPip(GetIt sl) {
  if (!sl.isRegistered<PipFakeDataSource>()) {
    sl.registerLazySingleton<PipFakeDataSource>(
      () => const PipFakeDataSource(),
    );
  }
  if (!sl.isRegistered<PipRepository>()) {
    sl.registerLazySingleton<PipRepository>(
      () => PipRepositoryImpl(dataSource: sl<PipFakeDataSource>()),
    );
  }
  if (!sl.isRegistered<PipBloc>()) {
    sl.registerFactory<PipBloc>(() => PipBloc(repository: sl<PipRepository>()));
  }
}
