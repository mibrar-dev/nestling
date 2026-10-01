import 'package:get_it/get_it.dart';
import 'package:nestling/features/onboarding/data/onboarding_fake_data_source.dart';
import 'package:nestling/features/onboarding/data/onboarding_repository_impl.dart';
import 'package:nestling/features/onboarding/domain/onboarding_repository.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_bloc.dart';

void registerOnboarding(GetIt sl) {
  if (!sl.isRegistered<OnboardingFakeDataSource>()) {
    sl.registerLazySingleton<OnboardingFakeDataSource>(
      () => const OnboardingFakeDataSource(),
    );
  }
  if (!sl.isRegistered<OnboardingRepository>()) {
    sl.registerLazySingleton<OnboardingRepository>(
      () =>
          OnboardingRepositoryImpl(dataSource: sl<OnboardingFakeDataSource>()),
    );
  }
  if (!sl.isRegistered<OnboardingBloc>()) {
    sl.registerFactory<OnboardingBloc>(
      () => OnboardingBloc(repository: sl<OnboardingRepository>()),
    );
  }
}
