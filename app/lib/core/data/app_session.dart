// Nestling — app-wide session state, backed by the `app_state` table.
//
// The router listens to [AppSession]: onboarding completion and subscription
// status drive redirects (not onboarded → /welcome, expired → /paywall).
// Screen agents read (never duplicate) this for mode/child/subscription.

import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:nestling/core/data/app_database.dart';

class AppSession extends ChangeNotifier {
  AppSession(this._db) {
    _subscription = _db.watchAppState().listen((row) {
      _row = row;
      notifyListeners();
    });
  }

  final AppDatabase _db;
  late final StreamSubscription<AppStateData?> _subscription;
  AppStateData? _row;

  bool get onboardingComplete => _row?.onboardingComplete ?? false;
  String get subscriptionStatus => _row?.subscriptionStatus ?? 'trial';
  bool get trialExpired => subscriptionStatus == 'expired';
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
    await _write(
      AppStateCompanion(
        subscriptionStatus: const Value('trial'),
        trialStart: Value(DateTime.now().toUtc()),
        trialStartTz: Value(zone),
      ),
    );
  }

  /// Re-reads the `app_state` row immediately. The stream subscription
  /// delivers updates asynchronously, so launch code (seed → route) calls
  /// this to avoid reading a stale pre-seed row on first build.
  Future<void> refresh() async {
    _row = await (_db.select(
      _db.appState,
    )..where((a) => a.id.equals(1))).getSingleOrNull();
    notifyListeners();
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
