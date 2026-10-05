import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/current_family.dart';
import 'package:nestling/features/privacy_consent/data/privacy_consent_repository_impl.dart';
import 'package:nestling/features/privacy_consent/domain/privacy_consent_repository.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_bloc.dart';

/// Registers the PrivacyConsent feature. The repository is Drift-backed; the old
/// in-memory fake data source is kept on disk for reference but is NOT
/// wired into the app.
void registerPrivacyConsent(GetIt sl) {
  if (!sl.isRegistered<PrivacyConsentRepository>()) {
    sl.registerLazySingleton<PrivacyConsentRepository>(
      () => PrivacyConsentRepositoryImpl(
        db: sl<AppDatabase>(),
        currentFamily: sl<CurrentFamily>(),
      ),
    );
  }
  if (!sl.isRegistered<PrivacyConsentBloc>()) {
    sl.registerFactory<PrivacyConsentBloc>(
      () => PrivacyConsentBloc(repository: sl<PrivacyConsentRepository>()),
    );
  }
}
