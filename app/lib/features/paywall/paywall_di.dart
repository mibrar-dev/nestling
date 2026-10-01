import 'package:get_it/get_it.dart';
import 'package:nestling/features/paywall/data/paywall_fake_data_source.dart';
import 'package:nestling/features/paywall/data/paywall_repository_impl.dart';
import 'package:nestling/features/paywall/domain/paywall_repository.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_bloc.dart';

void registerPaywall(GetIt sl) {
  if (!sl.isRegistered<PaywallFakeDataSource>()) {
    sl.registerLazySingleton<PaywallFakeDataSource>(
      () => const PaywallFakeDataSource(),
    );
  }
  if (!sl.isRegistered<PaywallRepository>()) {
    sl.registerLazySingleton<PaywallRepository>(
      () => PaywallRepositoryImpl(dataSource: sl<PaywallFakeDataSource>()),
    );
  }
  if (!sl.isRegistered<PaywallBloc>()) {
    sl.registerFactory<PaywallBloc>(
      () => PaywallBloc(repository: sl<PaywallRepository>()),
    );
  }
}
