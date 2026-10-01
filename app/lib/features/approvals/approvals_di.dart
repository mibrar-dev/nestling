import 'package:get_it/get_it.dart';
import 'package:nestling/features/approvals/data/approvals_fake_data_source.dart';
import 'package:nestling/features/approvals/data/approvals_repository_impl.dart';
import 'package:nestling/features/approvals/domain/approvals_repository.dart';
import 'package:nestling/features/approvals/presentation/bloc/approvals_bloc.dart';

void registerApprovals(GetIt sl) {
  if (!sl.isRegistered<ApprovalsFakeDataSource>()) {
    sl.registerLazySingleton<ApprovalsFakeDataSource>(
      () => const ApprovalsFakeDataSource(),
    );
  }
  if (!sl.isRegistered<ApprovalsRepository>()) {
    sl.registerLazySingleton<ApprovalsRepository>(
      () => ApprovalsRepositoryImpl(dataSource: sl<ApprovalsFakeDataSource>()),
    );
  }
  if (!sl.isRegistered<ApprovalsBloc>()) {
    sl.registerFactory<ApprovalsBloc>(
      () => ApprovalsBloc(repository: sl<ApprovalsRepository>()),
    );
  }
}
