import 'package:nestling/features/paywall/domain/entities/paywall_plan.dart';

abstract class PaywallRepository {
  Future<List<PaywallPlan>> getItems();
}
