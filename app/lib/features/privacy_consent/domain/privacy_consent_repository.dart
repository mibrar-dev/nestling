import 'package:nestling/features/privacy_consent/domain/entities/consent_option.dart';

abstract class PrivacyConsentRepository {
  Future<List<ConsentOption>> getItems();
}
