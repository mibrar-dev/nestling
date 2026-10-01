import 'package:get_it/get_it.dart';
import 'package:nestling/app/controllers.dart';
import 'package:nestling/features/approvals/approvals_di.dart';
import 'package:nestling/features/auth/auth_di.dart';
import 'package:nestling/features/badges/badges_di.dart';
import 'package:nestling/features/design_system_gallery/design_system_gallery_di.dart';
import 'package:nestling/features/family/family_di.dart';
import 'package:nestling/features/kid_home/kid_home_di.dart';
import 'package:nestling/features/kid_jar/kid_jar_di.dart';
import 'package:nestling/features/kid_shop/kid_shop_di.dart';
import 'package:nestling/features/onboarding/onboarding_di.dart';
import 'package:nestling/features/parental_gate/parental_gate_di.dart';
import 'package:nestling/features/paywall/paywall_di.dart';
import 'package:nestling/features/pip/pip_di.dart';
import 'package:nestling/features/pocket_money/pocket_money_di.dart';
import 'package:nestling/features/privacy_consent/privacy_consent_di.dart';
import 'package:nestling/features/quests/quests_di.dart';
import 'package:nestling/features/rewards/rewards_di.dart';
import 'package:nestling/features/settings/settings_di.dart';
import 'package:nestling/features/today/today_di.dart';

Future<void> configureDependencies() async {
  final sl = GetIt.instance;
  if (!sl.isRegistered<AppModeController>()) {
    sl.registerLazySingleton<AppModeController>(AppModeController.new);
  }
  if (!sl.isRegistered<ThemeModeController>()) {
    sl.registerLazySingleton<ThemeModeController>(ThemeModeController.new);
  }
  registerOnboarding(sl);
  registerAuth(sl);
  registerPrivacyConsent(sl);
  registerFamily(sl);
  registerPocketMoney(sl);
  registerPaywall(sl);
  registerParentalGate(sl);
  registerToday(sl);
  registerQuests(sl);
  registerApprovals(sl);
  registerRewards(sl);
  registerSettings(sl);
  registerKidHome(sl);
  registerPip(sl);
  registerKidShop(sl);
  registerKidJar(sl);
  registerBadges(sl);
  registerDesignSystemGallery(sl);
}
