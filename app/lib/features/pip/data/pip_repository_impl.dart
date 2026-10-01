import 'package:nestling/features/pip/data/pip_fake_data_source.dart';
import 'package:nestling/features/pip/domain/entities/pip_stage.dart';
import 'package:nestling/features/pip/domain/pip_repository.dart';

class PipRepositoryImpl implements PipRepository {
  const new({required this._dataSource});

  final PipFakeDataSource _dataSource;

  @override
  Future<List<PipStage>> getItems() {
    return Future.value(_dataSource.getItems());
  }
}
