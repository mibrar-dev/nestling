import 'package:get_it/get_it.dart';
import 'package:nestling/features/pocket_money/data/pocket_money_fake_data_source.dart';
import 'package:nestling/features/pocket_money/data/pocket_money_repository_impl.dart';
import 'package:nestling/features/pocket_money/domain/pocket_money_repository.dart';
import 'package:nestling/features/pocket_money/presentation/bloc/pocket_money_bloc.dart';

void registerPocketMoney(GetIt sl) {
  if (!sl.isRegistered<PocketMoneyFakeDataSource>()) {
    sl.registerLazySingleton<PocketMoneyFakeDataSource>(
      () => const PocketMoneyFakeDataSource(),
    );
  }
  if (!sl.isRegistered<PocketMoneyRepository>()) {
    sl.registerLazySingleton<PocketMoneyRepository>(
      () => PocketMoneyRepositoryImpl(
        dataSource: sl<PocketMoneyFakeDataSource>(),
      ),
    );
  }
  if (!sl.isRegistered<PocketMoneyBloc>()) {
    sl.registerFactory<PocketMoneyBloc>(
      () => PocketMoneyBloc(repository: sl<PocketMoneyRepository>()),
    );
  }
}
