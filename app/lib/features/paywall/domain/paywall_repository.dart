import 'package:nestling/features/paywall/domain/entities/paywall_plan.dart';
import 'package:nestling/features/paywall/domain/entities/subscription_status.dart';

/// Paywall (P07), backed by Drift. The plan is static; the subscription
/// state lives in `app_state` and drives the router's paywall redirect.
abstract class PaywallRepository {
  Future<List<PaywallPlan>> getItems();
  Stream<List<PaywallPlan>> watchItems();

  Stream<SubscriptionStatus> watchSubscription();
  Future<void> startTrial();
  Future<void> activate();
}
