import 'package:nestling/features/paywall/data/models/paywall_plan_model.dart';

class PaywallFakeDataSource {
  const new();

  List<PaywallPlanModel> getItems() {
    return const <PaywallPlanModel>[
      PaywallPlanModel(
        id: 'annual',
        title: 'Annual £29.99 per year',
        detail: '14-day free trial, cancel anytime',
      ),
      PaywallPlanModel(
        id: 'trial-timeline',
        title: 'Day 12 reminder',
        detail: 'Billed on day 14',
      ),
    ];
  }
}
