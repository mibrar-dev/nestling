import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/features/paywall/data/paywall_repository_impl.dart';
import 'package:nestling/features/paywall/domain/paywall_repository.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_bloc.dart';

/// Registers the Paywall feature. The repository is Drift-backed; the old
/// in-memory fake data source is kept on disk for reference but is NOT
/// wired into the app.
void registerPaywall(GetIt sl) {
  if (!sl.isRegistered<PaywallRepository>()) {
    sl.registerLazySingleton<PaywallRepository>(
      () => PaywallRepositoryImpl(db: sl<AppDatabase>()),
    );
  }
  if (!sl.isRegistered<PaywallBloc>()) {
    sl.registerFactory<PaywallBloc>(
      () => PaywallBloc(repository: sl<PaywallRepository>()),
    );
  }
}
