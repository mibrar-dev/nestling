import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/core/data/app_session.dart';
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

/// Locations that belong to the P01→P07 onboarding flow. Anything else
/// redirects to `/welcome` until onboarding completes.
const Set<String> _onboardingLocations = <String>{
  '/welcome',
  '/value-tour',
  '/create-account',
  '/privacy',
  '/add-children',
  '/pocket-money-setup',
  '/paywall',
};

GoRouter buildAppRouter(
  AppModeController appMode, {
  AppSession? session,
  String? initialLocation,
}) {
  // Debug-only motion-QA entry: `--dart-define=MOTION_AUTOPLAY=<name>`
  // boots straight into the motion lab so `simctl recordVideo` captures a
  // single animation without manual navigation. `--dart-define=
  // PIP_LAB_AUTOPLAY=<style>` (mochi | bolt | storybook) boots into the Pip
  // lab, which runs Play-all for that style on launch.
  const autoplay = String.fromEnvironment('MOTION_AUTOPLAY');
  const pipAutoplay = String.fromEnvironment('PIP_LAB_AUTOPLAY');
  return GoRouter(
    initialLocation:
        initialLocation ??
        (pipAutoplay.isNotEmpty
            ? DesignSystemGalleryRoutePaths.pipLab
            : autoplay.isNotEmpty
            ? DesignSystemGalleryRoutePaths.motionLab
            : DesignSystemGalleryRoutePaths.gallery),
    refreshListenable: session == null
        ? appMode
        : Listenable.merge([appMode, session]),
    redirect: (context, state) {
      final location = state.matchedLocation;
      const parentOnly = <String>[
        '/today',
        '/today-empty',
        '/quest-editor',
        '/quests',
        '/money',
        '/child-profile',
        '/settings',
        '/approvals',
        '/rewards',
        '/payout',
        '/paywall',
      ];
      // Onboarding is the parent's setup flow: never reachable from kid mode.
      final isParentOnly =
          _onboardingLocations.contains(location) ||
          parentOnly.any(
            (prefix) => location == prefix || location.startsWith('$prefix/'),
          );
      // Kid-mode first (P07-BUG-9): a parent-only location in kid mode stops
      // at the gate even mid-onboarding. The gate itself is kid-reachable,
      // so this redirect sticks instead of bouncing to `/welcome`.
      if (appMode.isKid && isParentOnly) {
        return ParentalGateRoutePaths.gate;
      }
      if (session != null) {
        final onboarded = session.onboardingComplete;
        // The parental gate is exempt: without this, the redirect above
        // lands on the gate and is immediately re-evaluated back to
        // `/welcome` for an app that has not onboarded yet.
        if (!onboarded &&
            location != ParentalGateRoutePaths.gate &&
            !_onboardingLocations.contains(location)) {
          return OnboardingRoutePaths.welcome;
        }
        // Kid mode + expired trial: kids never see the paywall. Every
        // location funnels to the gate, which is EXEMPT here (like the
        // onboarding branch above exempts it) — otherwise /paywall is
        // parent-only in kid mode and the guard ping-pongs
        // /paywall => /parental-gate => /paywall (GoException redirect
        // loop). Passing the gate flips to parent mode, where the trial
        // branch below sends the parent to /paywall.
        if (onboarded &&
            session.trialExpired &&
            appMode.isKid &&
            location != ParentalGateRoutePaths.gate) {
          return ParentalGateRoutePaths.gate;
        }
        if (onboarded &&
            session.trialExpired &&
            !appMode.isKid &&
            location != PaywallRoutePaths.paywall) {
          return PaywallRoutePaths.paywall;
        }
      }
      return null;
    },
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) {
          return ParentShell(navigationShell: shell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(routes: <RouteBase>[todayRoute, todayEmptyRoute]),
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
