// Nestling — hosted legal links (shared/release_prep).
//
// Both URLs live here so P03, P04, P07 and P16 can never drift apart.
// They open in the in-app browser (`LaunchMode.inAppBrowserView`) so the
// parent never leaves the app.
//
// Tests inject [launcherOverride] (a [LegalLauncher]) instead of hitting
// `url_launcher`; product code passes nothing and gets `launchUrl`.
import 'package:url_launcher/url_launcher.dart';

/// Opens a URL in the in-app browser. Matches the `launchUrl` shape so the
/// default is exactly `launchUrl` itself.
typedef LegalLauncher = Future<bool> Function(
  Uri url, {
  required LaunchMode mode,
});

abstract final class LegalLinks {
  /// Hosted privacy notice (published by the owner per SETUP_CHECKLIST).
  static const String privacyUrl = 'https://getnestling.co.uk/privacy';

  /// Hosted terms (published by the owner per SETUP_CHECKLIST).
  static const String termsUrl = 'https://getnestling.co.uk/terms';

  static Uri get privacyUri => Uri.parse(privacyUrl);
  static Uri get termsUri => Uri.parse(termsUrl);

  /// Test seam: when set, [openPrivacy]/[openTerms]/[open] call this instead
  /// of `launchUrl`. Widget tests set it to record the URL; product code
  /// never sets it.
  static LegalLauncher? launcherOverride;

  /// Opens the hosted privacy notice in the in-app browser.
  static Future<void> openPrivacy({LegalLauncher? launcher}) =>
      open(privacyUri, launcher: launcher);

  /// Opens the hosted terms in the in-app browser.
  static Future<void> openTerms({LegalLauncher? launcher}) =>
      open(termsUri, launcher: launcher);

  /// Opens [url] in the in-app browser via [launcher], the test override,
  /// or `launchUrl` (in that order).
  static Future<void> open(Uri url, {LegalLauncher? launcher}) {
    final call = launcher ?? launcherOverride ?? launchUrl;
    return call(url, mode: LaunchMode.inAppBrowserView);
  }
}
