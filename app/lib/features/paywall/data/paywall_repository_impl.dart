import 'package:nestling/features/paywall/data/paywall_fake_data_source.dart';
import 'package:nestling/features/paywall/domain/entities/paywall_plan.dart';
import 'package:nestling/features/paywall/domain/paywall_repository.dart';

class PaywallRepositoryImpl implements PaywallRepository {
  const new({required this._dataSource});

  final PaywallFakeDataSource _dataSource;

  @override
  Future<List<PaywallPlan>> getItems() {
    return Future.value(_dataSource.getItems());
  }
}
