// Nestling — app-wide session state, backed by the `app_state` table.
//
// The router listens to [AppSession]: onboarding completion and subscription
// status drive redirects (not onboarded → /welcome, expired → /paywall).
// Screen agents read (never duplicate) this for mode/child/subscription.
//
// Trial expiry (shared_batch3): the 14-day trial is ELAPSED time from the
// `app_state.trialStart` UTC instant (DATETIME_STORAGE.md: trial length is
// elapsed, not calendar days). [trialExpired] is computed from the trial
// start so the router fires even before the status row is rewritten, and
// [refresh]/[checkTrialExpiry] persists `subscription_status = 'expired'`
// at launch/resume. An `active` subscriber never expires. Time comes from
// an injectable [clock] so tests can pin it.

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:nestling/core/data/app_clock.dart';
import 'package:nestling/core/data/app_database.dart';

/// Clock returning "now" (defaults to [appNowUtc], i.e. `clock.now()` pinned
/// to the seed anchor in tests). Tests pin this to a
/// fixed instant to prove the trial boundary deterministically.
typedef AppSessionClock = DateTime Function();

class AppSession extends ChangeNotifier {
  AppSession(this._db, {AppSessionClock? clock}) : _clock = clock ?? appNowUtc {
    _subscription = _db.watchAppState().listen((row) {
      _row = row;
      notifyListeners();
    });
  }

  final AppDatabase _db;
  final AppSessionClock _clock;
  late final StreamSubscription<AppStateData?> _subscription;
  AppStateData? _row;

  /// Elapsed trial length: 14 days from the `trialStart` UTC instant.
  static const Duration trialLength = Duration(days: 14);

  /// The clock's "now" as a UTC instant.
  DateTime get nowUtc => _clock().toUtc();

  /// Whether [trialStart] has aged out at [nowUtc] (elapsed-time rule).
  /// A null start (trial never begun) never expires.
  static bool isTrialStartExpired(DateTime? trialStart, DateTime nowUtc) {
    if (trialStart == null) return false;
    return !nowUtc.isBefore(trialStart.toUtc().add(trialLength));
  }

  bool get onboardingComplete => _row?.onboardingComplete ?? false;
  String get subscriptionStatus => _row?.subscriptionStatus ?? 'trial';

  /// True when the paywall redirect must fire: a persisted `'expired'`
  /// status, or a `'trial'` whose start is 14+ days in the past. Any other
  /// status (notably `'active'`) never counts as expired.
  bool get trialExpired {
    if (subscriptionStatus == 'expired') return true;
    if (subscriptionStatus != 'trial') return false;
    return isTrialStartExpired(_row?.trialStart, nowUtc);
  }

  String? get activeChildId => _row?.activeChildId;
  String get appMode => _row?.appMode ?? 'parent';
  bool get isKid => appMode == 'kid';

  Future<void> completeOnboarding() =>
      _write(const AppStateCompanion(onboardingComplete: Value(true)));

  Future<void> setAppMode(String mode) =>
      _write(AppStateCompanion(appMode: Value(mode)));

  Future<void> setActiveChild(String? childId) =>
      _write(AppStateCompanion(activeChildId: Value(childId)));

  Future<void> setSubscription(String status) =>
      _write(AppStateCompanion(subscriptionStatus: Value(status)));

  Future<void> startTrialNow() async {
    final zone = await _db.familyZoneId();
    final now = _clock().toUtc();
    await _write(
      AppStateCompanion(
        subscriptionStatus: const Value('trial'),
        trialStart: Value(now),
        trialStartTz: Value(zone),
      ),
    );
  }

  /// Re-reads the `app_state` row immediately. The stream subscription
  /// delivers updates asynchronously, so launch code (seed → route) calls
  /// this to avoid reading a stale pre-seed row on first build.
  ///
  /// Also enforces trial expiry (shared_batch3): a `'trial'` whose start is
  /// 14+ days in the past is persisted as `'expired'` so the router's
  /// paywall redirect — and any reader of the raw status column — sees it.
  Future<void> refresh() async {
    _row = await (_db.select(
      _db.appState,
    )..where((a) => a.id.equals(1))).getSingleOrNull();
    if (_row != null &&
        _row!.subscriptionStatus == 'trial' &&
        isTrialStartExpired(_row!.trialStart, nowUtc)) {
      await _write(
        const AppStateCompanion(subscriptionStatus: Value('expired')),
      );
      _row = await (_db.select(
        _db.appState,
      )..where((a) => a.id.equals(1))).getSingleOrNull();
    }
    notifyListeners();
  }

  /// Persists an aged-out trial as `'expired'` (launch/resume entry point).
  /// Returns true when this call flipped `'trial'` → `'expired'`. A no-op
  /// unless the status is still `'trial'` with a start 14+ days old —
  /// `'active'` is never touched.
  Future<bool> checkTrialExpiry() async {
    final before = _row?.subscriptionStatus;
    await refresh();
    return before == 'trial' && _row?.subscriptionStatus == 'expired';
  }

  /// Upserts the single `app_state` row (id 1). A real first install has no
  /// seeded row, so a plain UPDATE silently changed nothing (P01 BUG-4).
  Future<void> _write(AppStateCompanion companion) async {
    final updated = await (_db.update(
      _db.appState,
    )..where((a) => a.id.equals(1))).write(companion);
    if (updated == 0) {
      await _db
          .into(_db.appState)
          .insert(companion.copyWith(id: const Value(1)));
    }
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
