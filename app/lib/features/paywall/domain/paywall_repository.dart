import 'package:nestling/features/paywall/domain/entities/paywall_plan.dart';
import 'package:nestling/features/paywall/domain/entities/subscription_status.dart';

/// Paywall (P07), backed by Drift. The plan is static; the subscription
/// state lives in `app_state` and drives the router's paywall redirect.
abstract class PaywallRepository {
  Future<List<PaywallPlan>> getItems();
  Stream<List<PaywallPlan>> watchItems();

  Stream<SubscriptionStatus> watchSubscription();

  /// One-shot read of the current subscription (missing row → `trial` with
  /// no start date, same default as [watchSubscription]). The default reads
  /// the first watch emission; the Drift implementation overrides this with
  /// a direct SELECT because subscribing to a fresh watch stream inside a
  /// widget test never resolves (verified by probe: `watch().first` stays
  /// pending while the one-shot SELECT returns immediately).
  Future<SubscriptionStatus> readSubscription() => watchSubscription().first;

  Future<void> startTrial();
  Future<void> activate();

  /// Display name of the family's co-parent (the second parent member), or
  /// null when the family has none. The P07 benefit line renders
  /// "Co-parent sharing, so `Name` sees the same" / "... so everyone sees
  /// the same" from this (shared_batch3: the database is the source of
  /// truth). The bloc reads it one-shot at load; the Drift implementation
  /// queries `members`.
  Future<String?> readCoParentName() => Future<String?>.value();
}
