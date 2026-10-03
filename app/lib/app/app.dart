import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/app/router.dart';
import 'package:nestling/core/data/app_session.dart';
import 'package:nestling/core/data/env_flags.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:provider/provider.dart';

/// Clamps the ambient text scaler to the range the design system supports.
///
/// Chips, coin pills and tabular money use nowrap/ellipsis; beyond 1.3x they
/// would clip or force overflow, so the shell pins 1.0–1.3 (SPACING_SPEC §10).
MediaQueryData _clampTextScaler(BuildContext context, MediaQueryData data) {
  final scaler = data.textScaler.clamp(minScaleFactor: 1, maxScaleFactor: 1.3);
  return data.copyWith(textScaler: scaler);
}

class NestlingApp extends StatefulWidget {
  const new({super.key, this.initialRoute});

  /// INITIAL_ROUTE override from launch flags; null keeps the router default.
  final String? initialRoute;

  @override
  State<NestlingApp> createState() => _NestlingAppState();
}

class _NestlingAppState extends State<NestlingApp> with WidgetsBindingObserver {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _router = buildAppRouter(
      GetIt.instance<AppModeController>(),
      session: GetIt.instance<AppSession>(),
      initialLocation: widget.initialRoute,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Trial expiry at resume (shared_batch3): a trial that aged out while
    // the app was backgrounded persists as 'expired', and the session
    // notification re-evaluates the router guard.
    if (state == AppLifecycleState.resumed) {
      final getIt = GetIt.instance;
      if (getIt.isRegistered<AppSession>()) {
        unawaited(getIt<AppSession>().checkTrialExpiry());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppModeController>.value(
          value: GetIt.instance<AppModeController>(),
        ),
        ChangeNotifierProvider<ThemeModeController>.value(
          value: GetIt.instance<ThemeModeController>(),
        ),
      ],
      child: Consumer<ThemeModeController>(
        builder: (context, themeMode, child) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Nestling',
            theme: NestTheme.light(),
            darkTheme: NestTheme.dark(),
            themeMode: themeMode.mode,
            routerConfig: _router,
            builder: (context, child) {
              // DISABLE_ANIMATIONS (screenshots/QA) behaves exactly like the
              // OS Reduce Motion setting for every widget that honours it.
              final media = _clampTextScaler(context, MediaQuery.of(context));
              return MediaQuery(
                data: kDisableAnimations
                    ? media.copyWith(disableAnimations: true)
                    : media,
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
