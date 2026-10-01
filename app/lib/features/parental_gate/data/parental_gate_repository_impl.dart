import 'package:nestling/features/parental_gate/data/parental_gate_fake_data_source.dart';
import 'package:nestling/features/parental_gate/domain/entities/parental_gate_challenge.dart';
import 'package:nestling/features/parental_gate/domain/parental_gate_repository.dart';

class ParentalGateRepositoryImpl implements ParentalGateRepository {
  const new({required this._dataSource});

  final ParentalGateFakeDataSource _dataSource;

  @override
  Future<List<ParentalGateChallenge>> getItems() {
    return Future.value(_dataSource.getItems());
  }
}
