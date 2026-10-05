// Nestling — launch flags (debug + profile only).
//
// Applies the compile-time `--dart-define` values from [LaunchFlags] to the
// service locator after [configureDependencies]:
//
//   SEED=demo|empty|fresh|onboarding_kids|new_family   reseed the database on launch when given
//   INITIAL_ROUTE=/today    returned so the router boots straight there
//   APP_MODE=parent|kid     controller + persisted app_state
//   THEME=light|dark|system  theme controller
//   CHILD=maya|leo          active child in app_state
//
// Returns the initial route override, or null to use the router default.

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/app/launch_flags.dart';
import 'package:nestling/core/data/app_database.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/seed.dart';

Future<String?> applyLaunchFlags() async {
  final sl = GetIt.instance;
  final db = sl<AppDatabase>();
  final session = sl<AppSession>();

  if (LaunchFlags.hasSeed) {
    switch (LaunchFlags.seed) {
      case 'demo':
        await Seed.demo(db);
      case 'empty':
        await Seed.empty(db);
      case 'new_family':
        await Seed.newFamily(db);
      case 'fresh':
        await Seed.fresh(db);
      case 'onboarding_kids':
        await Seed.onboardingKids(db);
    }
    await session.refresh();
  }

  const mode = LaunchFlags.appMode;
  if (mode == 'kid' || mode == 'parent') {
    sl<AppModeController>().selectMode(
      mode == 'kid' ? AppMode.kid : AppMode.parent,
    );
    await session.setAppMode(mode);
    await session.refresh();
  } else {
    final row = await (db.select(
      db.appState,
    )..where((a) => a.id.equals(1))).getSingleOrNull();
    if (row?.appMode == 'kid') {
      sl<AppModeController>().selectMode(AppMode.kid);
    }
  }

  if (LaunchFlags.child.isNotEmpty) {
    await session.setActiveChild(LaunchFlags.child);
    await session.refresh();
  }

  switch (LaunchFlags.theme) {
    case 'light':
      sl<ThemeModeController>().selectMode(ThemeMode.light);
    case 'dark':
      sl<ThemeModeController>().selectMode(ThemeMode.dark);
    case 'system':
      sl<ThemeModeController>().selectMode(ThemeMode.system);
  }

  await session.refresh();
  // Trial expiry (shared_batch3): an elapsed 14-day trial persists as
  // 'expired' at launch so the router's paywall redirect fires. Never
  // touches an 'active' subscriber. `refresh()` already enforces this;
  // the explicit call keeps the launch contract visible.
  await session.checkTrialExpiry();
  return LaunchFlags.initialRoute.isEmpty ? null : LaunchFlags.initialRoute;
}
