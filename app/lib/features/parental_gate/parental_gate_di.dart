import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/features/parental_gate/data/parental_gate_repository_impl.dart';
import 'package:nestling/features/parental_gate/domain/parental_gate_repository.dart';
import 'package:nestling/features/parental_gate/presentation/bloc/parental_gate_bloc.dart';

/// Registers the ParentalGate feature. The repository is Drift-backed; the old
/// in-memory fake data source is kept on disk for reference but is NOT
/// wired into the app.
void registerParentalGate(GetIt sl) {
  if (!sl.isRegistered<ParentalGateRepository>()) {
    sl.registerLazySingleton<ParentalGateRepository>(
      () => ParentalGateRepositoryImpl(db: sl<AppDatabase>()),
    );
  }
  if (!sl.isRegistered<ParentalGateBloc>()) {
    sl.registerFactory<ParentalGateBloc>(
      () => ParentalGateBloc(repository: sl<ParentalGateRepository>()),
    );
  }
}
