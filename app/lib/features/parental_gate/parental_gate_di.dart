import 'package:get_it/get_it.dart';
import 'package:nestling/features/parental_gate/data/parental_gate_fake_data_source.dart';
import 'package:nestling/features/parental_gate/data/parental_gate_repository_impl.dart';
import 'package:nestling/features/parental_gate/domain/parental_gate_repository.dart';
import 'package:nestling/features/parental_gate/presentation/bloc/parental_gate_bloc.dart';

void registerParentalGate(GetIt sl) {
  if (!sl.isRegistered<ParentalGateFakeDataSource>()) {
    sl.registerLazySingleton<ParentalGateFakeDataSource>(
      () => const ParentalGateFakeDataSource(),
    );
  }
  if (!sl.isRegistered<ParentalGateRepository>()) {
    sl.registerLazySingleton<ParentalGateRepository>(
      () => ParentalGateRepositoryImpl(
        dataSource: sl<ParentalGateFakeDataSource>(),
      ),
    );
  }
  if (!sl.isRegistered<ParentalGateBloc>()) {
    sl.registerFactory<ParentalGateBloc>(
      () => ParentalGateBloc(repository: sl<ParentalGateRepository>()),
    );
  }
}
