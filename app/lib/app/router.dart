import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/design_system/design_system.dart';
import 'package:nestling/features/approvals/approvals_routes.dart';
import 'package:nestling/features/auth/auth_routes.dart';
import 'package:nestling/features/badges/badges_routes.dart';
import 'package:nestling/features/design_system_gallery/design_system_gallery_routes.dart';
import 'package:nestling/features/family/family_routes.dart';
import 'package:nestling/features/kid_home/kid_home_routes.dart';
import 'package:nestling/features/kid_jar/kid_jar_routes.dart';
import 'package:nestling/features/kid_shop/kid_shop_routes.dart';
import 'package:nestling/features/onboarding/onboarding_routes.dart';
import 'package:nestling/features/parental_gate/parental_gate_routes.dart';
import 'package:nestling/features/paywall/paywall_routes.dart';
import 'package:nestling/features/pip/pip_routes.dart';
import 'package:nestling/features/pocket_money/pocket_money_routes.dart';
import 'package:nestling/features/privacy_consent/privacy_consent_routes.dart';
import 'package:nestling/features/quests/quests_routes.dart';
import 'package:nestling/features/rewards/rewards_routes.dart';
import 'package:nestling/features/settings/settings_routes.dart';
import 'package:nestling/features/today/today_routes.dart';

class ParentShell extends StatelessWidget {
  const new({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NestTabBar(
        items: const [
          NestTabItem(label: 'Today', icon: NestIcons.home),
          NestTabItem(label: 'Quests', icon: NestIcons.quests),
          NestTabItem(label: 'Money', icon: NestIcons.money),
          NestTabItem(label: 'Family', icon: NestIcons.family),
        ],
        currentIndex: navigationShell.currentIndex,
        onTap: navigationShell.goBranch,
      ),
    );
  }
}

GoRouter buildAppRouter(AppModeController appMode) {
  // Debug-only motion-QA entry: `--dart-define=MOTION_AUTOPLAY=<name>`
  // boots straight into the motion lab so `simctl recordVideo` captures a
  // single animation without manual navigation.
  const autoplay = String.fromEnvironment('MOTION_AUTOPLAY');
  return GoRouter(
    initialLocation: autoplay.isNotEmpty
        ? DesignSystemGalleryRoutePaths.motionLab
        : DesignSystemGalleryRoutePaths.gallery,
    refreshListenable: appMode,
    redirect: (context, state) {
      final location = state.matchedLocation;
      const parentOnly = <String>[
        '/today',
        '/quests',
        '/money',
        '/child-profile',
        '/settings',
        '/approvals',
        '/rewards',
        '/payout',
        '/paywall',
      ];
      final isParentOnly = parentOnly.any(
        (prefix) => location == prefix || location.startsWith('$prefix/'),
      );
      if (appMode.isKid && isParentOnly) {
        return ParentalGateRoutePaths.gate;
      }
      return null;
    },
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) {
          return ParentShell(navigationShell: shell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(routes: <RouteBase>[todayRoute]),
          StatefulShellBranch(routes: <RouteBase>[questLibraryRoute]),
          StatefulShellBranch(routes: <RouteBase>[moneyLedgerRoute]),
          StatefulShellBranch(
            routes: <RouteBase>[childProfileRoute, settingsRoute],
          ),
        ],
      ),
      ...onboardingRoutes,
      ...authRoutes,
      ...privacyConsentRoutes,
      addChildrenRoute,
      pocketMoneySetupRoute,
      payoutRoute,
      ...paywallRoutes,
      ...parentalGateRoutes,
      todayEmptyRoute,
      questEditorRoute,
      ...approvalsRoutes,
      ...rewardsRoutes,
      ...kidHomeRoutes,
      ...pipRoutes,
      ...kidShopRoutes,
      ...kidJarRoutes,
      ...badgesRoutes,
      ...designSystemGalleryRoutes,
    ],
  );
}
