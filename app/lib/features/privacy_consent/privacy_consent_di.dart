import 'package:get_it/get_it.dart';
import 'package:nestling/features/privacy_consent/data/privacy_consent_fake_data_source.dart';
import 'package:nestling/features/privacy_consent/data/privacy_consent_repository_impl.dart';
import 'package:nestling/features/privacy_consent/domain/privacy_consent_repository.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_bloc.dart';

void registerPrivacyConsent(GetIt sl) {
  if (!sl.isRegistered<PrivacyConsentFakeDataSource>()) {
    sl.registerLazySingleton<PrivacyConsentFakeDataSource>(
      () => const PrivacyConsentFakeDataSource(),
    );
  }
  if (!sl.isRegistered<PrivacyConsentRepository>()) {
    sl.registerLazySingleton<PrivacyConsentRepository>(
      () => PrivacyConsentRepositoryImpl(
        dataSource: sl<PrivacyConsentFakeDataSource>(),
      ),
    );
  }
  if (!sl.isRegistered<PrivacyConsentBloc>()) {
    sl.registerFactory<PrivacyConsentBloc>(
      () => PrivacyConsentBloc(repository: sl<PrivacyConsentRepository>()),
    );
  }
}
