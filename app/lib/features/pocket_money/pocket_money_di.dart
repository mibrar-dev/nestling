import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/current_family.dart';
import 'package:nestling/features/pocket_money/data/pocket_money_repository_impl.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_bloc.dart';

/// Registers the PocketMoney feature. The repository is Drift-backed; the old
/// in-memory fake data source is kept on disk for reference but is NOT
/// wired into the app.
void registerPocketMoney(GetIt sl) {
  if (!sl.isRegistered<PocketMoneyRepository>()) {
    sl.registerLazySingleton<PocketMoneyRepository>(
      () => PocketMoneyRepositoryImpl(
        db: sl<AppDatabase>(),
        currentFamily: sl<CurrentFamily>(),
      ),
    );
  }
  if (!sl.isRegistered<PocketMoneyBloc>()) {
    sl.registerFactory<PocketMoneyBloc>(
      () => PocketMoneyBloc(repository: sl<PocketMoneyRepository>()),
    );
  }
}
