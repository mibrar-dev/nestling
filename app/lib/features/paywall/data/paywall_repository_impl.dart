import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/features/paywall/domain/entities/paywall_plan.dart';
import 'package:nestling/features/paywall/domain/entities/subscription_status.dart';
import 'package:nestling/features/paywall/domain/paywall_repository.dart';

/// Drift-backed [PaywallRepository].
class PaywallRepositoryImpl implements PaywallRepository {
  new({required this._db});

  final AppDatabase _db;

  @override
  Future<List<PaywallPlan>> getItems() => Future.value(_plans);

  @override
  Stream<List<PaywallPlan>> watchItems() => Stream.value(_plans);

  @override
  Stream<SubscriptionStatus> watchSubscription() {
    return _db.watchAppState().map(
      (s) => SubscriptionStatus(
        status: s?.subscriptionStatus ?? 'trial',
        trialStart: s?.trialStart,
      ),
    );
  }

  @override
  Future<void> startTrial() async {
    final zone = await _db.familyZoneId();
    await (_db.update(_db.appState)..where((a) => a.id.equals(1))).write(
      AppStateCompanion(
        subscriptionStatus: const Value('trial'),
        trialStart: Value(DateTime.now().toUtc()),
        trialStartTz: Value(zone),
      ),
    );
  }

  @override
  Future<void> activate() {
    return (_db.update(_db.appState)..where((a) => a.id.equals(1))).write(
      const AppStateCompanion(subscriptionStatus: Value('active')),
    );
  }

  static const List<PaywallPlan> _plans = <PaywallPlan>[
    PaywallPlan(
      id: 'annual',
      title: 'Annual — £29.99/year',
      detail:
          'Just £2.50 a month, billed yearly. '
          '£29.99/year after 14-day trial. Cancel anytime in Settings.',
    ),
  ];
}
