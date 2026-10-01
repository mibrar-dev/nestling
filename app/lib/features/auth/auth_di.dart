import 'package:get_it/get_it.dart';
import 'package:nestling/features/auth/data/auth_fake_data_source.dart';
import 'package:nestling/features/auth/data/auth_repository_impl.dart';
import 'package:nestling/features/auth/domain/auth_repository.dart';
import 'package:nestling/features/auth/presentation/bloc/auth_bloc.dart';

void registerAuth(GetIt sl) {
  if (!sl.isRegistered<AuthFakeDataSource>()) {
    sl.registerLazySingleton<AuthFakeDataSource>(
      () => const AuthFakeDataSource(),
    );
  }
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(dataSource: sl<AuthFakeDataSource>()),
    );
  }
  if (!sl.isRegistered<AuthBloc>()) {
    sl.registerFactory<AuthBloc>(
      () => AuthBloc(repository: sl<AuthRepository>()),
    );
  }
}
