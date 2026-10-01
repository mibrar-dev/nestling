import 'package:get_it/get_it.dart';
import 'package:nestling/features/family/data/family_fake_data_source.dart';
import 'package:nestling/features/family/data/family_repository_impl.dart';
import 'package:nestling/features/family/domain/family_repository.dart';
import 'package:nestling/features/family/presentation/bloc/family_bloc.dart';

void registerFamily(GetIt sl) {
  if (!sl.isRegistered<FamilyFakeDataSource>()) {
    sl.registerLazySingleton<FamilyFakeDataSource>(
      () => const FamilyFakeDataSource(),
    );
  }
  if (!sl.isRegistered<FamilyRepository>()) {
    sl.registerLazySingleton<FamilyRepository>(
      () => FamilyRepositoryImpl(dataSource: sl<FamilyFakeDataSource>()),
    );
  }
  if (!sl.isRegistered<FamilyBloc>()) {
    sl.registerFactory<FamilyBloc>(
      () => FamilyBloc(repository: sl<FamilyRepository>()),
    );
  }
}
