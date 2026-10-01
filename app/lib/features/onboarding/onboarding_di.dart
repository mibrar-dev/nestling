import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/features/onboarding/data/onboarding_repository_impl.dart';
import 'package:nestling/features/onboarding/domain/onboarding_repository.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_bloc.dart';

/// Registers the Onboarding feature. The repository is Drift-backed; the old
/// in-memory fake data source is kept on disk for reference but is NOT
/// wired into the app.
void registerOnboarding(GetIt sl) {
  if (!sl.isRegistered<OnboardingRepository>()) {
    sl.registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepositoryImpl(db: sl<AppDatabase>()),
    );
  }
  if (!sl.isRegistered<OnboardingBloc>()) {
    sl.registerFactory<OnboardingBloc>(
      () => OnboardingBloc(repository: sl<OnboardingRepository>()),
    );
  }
}
