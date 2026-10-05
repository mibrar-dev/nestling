import 'package:get_it/get_it.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/current_family.dart';
import 'package:nestling/features/approvals/data/approvals_repository_impl.dart';
import 'package:nestling/features/approvals/domain/approvals_repository.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_bloc.dart';

/// Registers the Approvals feature. The repository is Drift-backed; the old
/// in-memory fake data source is kept on disk for reference but is NOT
/// wired into the app.
void registerApprovals(GetIt sl) {
  if (!sl.isRegistered<ApprovalsRepository>()) {
    sl.registerLazySingleton<ApprovalsRepository>(
      () => ApprovalsRepositoryImpl(
        db: sl<AppDatabase>(),
        currentFamily: sl<CurrentFamily>(),
      ),
    );
  }
  if (!sl.isRegistered<ApprovalsBloc>()) {
    sl.registerFactory<ApprovalsBloc>(
      () => ApprovalsBloc(repository: sl<ApprovalsRepository>()),
    );
  }
}
