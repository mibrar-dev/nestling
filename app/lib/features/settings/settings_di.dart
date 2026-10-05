import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/current_family.dart';
import 'package:nestling/core/data/family_zone_service.dart';
import 'package:nestling/features/settings/data/settings_repository_impl.dart';
import 'package:nestling/features/settings/domain/settings_repository.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:nestling/features/settings/presentation/bloc/settings_session_store.dart';

/// Registers the Settings feature. The repository is Drift-backed; the old
/// in-memory fake data source is kept on disk for reference but is NOT
/// wired into the app. The bloc also takes the shared [FamilyZoneService]
/// (registered in `app/di.dart` before this runs) for the move prompt, and
/// the session-scoped [SettingsSessionStore] so "Not now" dismissals survive
/// across `/settings` visits (P16-B02).
void registerSettings(GetIt sl) {
  if (!sl.isRegistered<SettingsRepository>()) {
    sl.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(
        db: sl<AppDatabase>(),
        currentFamily: sl<CurrentFamily>(),
        zoneService: sl<FamilyZoneService>(),
      ),
    );
  }
  if (!sl.isRegistered<SettingsSessionStore>()) {
    sl.registerLazySingleton<SettingsSessionStore>(SettingsSessionStore.new);
  }
  if (!sl.isRegistered<SettingsBloc>()) {
    sl.registerFactory<SettingsBloc>(
      () => SettingsBloc(
        repository: sl<SettingsRepository>(),
        zoneService: sl<FamilyZoneService>(),
        sessionStore: sl<SettingsSessionStore>(),
      ),
    );
  }
}
