import 'package:drift/drift.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/seed.dart';
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
  Future<SubscriptionStatus> readSubscription() async {
    final row = await (_db.select(
      _db.appState,
    )..where((a) => a.id.equals(1))).getSingleOrNull();
    return SubscriptionStatus(
      status: row?.subscriptionStatus ?? 'trial',
      trialStart: row?.trialStart,
    );
  }

  @override
  Future<void> startTrial() async {
    final zone = await _db.familyZoneId();
    await _upsert(
      AppStateCompanion(
        subscriptionStatus: const Value('trial'),
        trialStart: Value(DateTime.now().toUtc()),
        trialStartTz: Value(zone),
      ),
    );
  }

  @override
  Future<void> activate() {
    return _upsert(
      const AppStateCompanion(subscriptionStatus: Value('active')),
    );
  }

  /// The second parent member (`members.role = 'co-parent'`, insertion
  /// order) for the P07 benefit line. `Seed.demo` ships James; `fresh` and
  /// `empty` ship no co-parent (null → the "everyone" fallback).
  @override
  Future<String?> readCoParentName() async {
    final query = _db.select(_db.members)
      ..where(
        (m) => m.familyId.equals(Seed.familyId) & m.role.equals('co-parent'),
      )
      ..orderBy([
        (m) => OrderingTerm(expression: const CustomExpression<int>('rowid')),
      ]);
    final rows = await query.get();
    return rows.isEmpty ? null : rows.first.name;
  }

  /// Upserts the single `app_state` row (id 1). A plain UPDATE silently
  /// changes nothing when the row is missing (P01 BUG-4 class) — the same
  /// pattern as `AppSession._write`.
  Future<void> _upsert(AppStateCompanion companion) async {
    final updated = await (_db.update(
      _db.appState,
    )..where((a) => a.id.equals(1))).write(companion);
    if (updated == 0) {
      await _db
          .into(_db.appState)
          .insert(companion.copyWith(id: const Value(1)));
    }
  }

  /// The single annual plan (P07). `detail` carries every design string for
  /// the card — sub (no stray full stop, per `P07-paywall.html:86`), caption
  /// (with the article “the”, per `:105`) and tag (per `:87`) — joined with
  /// an em dash so no wrong punctuation variant can leak to a consumer. The
  /// view renders the three strings statically per `1_plan.md` §d.
  static const List<PaywallPlan> _plans = <PaywallPlan>[
    PaywallPlan(
      id: 'annual',
      title: 'Annual — £29.99/year',
      detail:
          'Just £2.50 a month, billed yearly — '
          '£29.99/year after the 14-day trial. Cancel anytime in Settings. '
          'One price, the whole family.',
    ),
  ];
}
