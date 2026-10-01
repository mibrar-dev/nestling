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

  Future<void> startTrialNow() => _write(
    AppStateCompanion(
      subscriptionStatus: const Value('trial'),
      trialStart: Value(DateTime.now().toUtc()),
    ),
  );

  /// Re-reads the `app_state` row immediately. The stream subscription
  /// delivers updates asynchronously, so launch code (seed → route) calls
  /// this to avoid reading a stale pre-seed row on first build.
  Future<void> refresh() async {
    _row = await (_db.select(
      _db.appState,
    )..where((a) => a.id.equals(1))).getSingleOrNull();
    notifyListeners();
  }

  Future<void> _write(AppStateCompanion companion) {
    return (_db.update(
      _db.appState,
    )..where((a) => a.id.equals(1))).write(companion);
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
