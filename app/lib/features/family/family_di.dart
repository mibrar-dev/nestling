import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/features/family/data/family_repository_impl.dart';
import 'package:nestling/features/family/domain/family_repository.dart';
import 'package:nestling/features/family/presentation/bloc/family_bloc.dart';

/// Registers the Family feature. The repository is Drift-backed; the old
/// in-memory fake data source is kept on disk for reference but is NOT
/// wired into the app.
void registerFamily(GetIt sl) {
  if (!sl.isRegistered<FamilyRepository>()) {
    sl.registerLazySingleton<FamilyRepository>(
      () => FamilyRepositoryImpl(db: sl<AppDatabase>()),
    );
  }
  if (!sl.isRegistered<FamilyBloc>()) {
    sl.registerFactory<FamilyBloc>(
      () => FamilyBloc(repository: sl<FamilyRepository>()),
    );
  }
}
