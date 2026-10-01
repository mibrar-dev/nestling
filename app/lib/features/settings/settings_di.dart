import 'package:get_it/get_it.dart';
import 'package:nestling/features/settings/data/settings_fake_data_source.dart';
import 'package:nestling/features/settings/data/settings_repository_impl.dart';
import 'package:nestling/features/settings/domain/settings_repository.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_bloc.dart';

void registerSettings(GetIt sl) {
  if (!sl.isRegistered<SettingsFakeDataSource>()) {
    sl.registerLazySingleton<SettingsFakeDataSource>(
      () => const SettingsFakeDataSource(),
    );
  }
  if (!sl.isRegistered<SettingsRepository>()) {
    sl.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(dataSource: sl<SettingsFakeDataSource>()),
    );
  }
  if (!sl.isRegistered<SettingsBloc>()) {
    sl.registerFactory<SettingsBloc>(
      () => SettingsBloc(repository: sl<SettingsRepository>()),
    );
  }
}
