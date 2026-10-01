import 'package:nestling/features/privacy_consent/domain/entities/consent_option.dart';

/// Privacy & consent (P04), backed by Drift. Crash-report consent lives in
/// `settings` and is OFF by default (ICO nudge rule).
abstract class PrivacyConsentRepository {
  Future<List<ConsentOption>> getItems();
  Stream<List<ConsentOption>> watchItems();

  Stream<bool> watchCrashConsent();
  Future<void> setCrashConsent({required bool consent});
}
