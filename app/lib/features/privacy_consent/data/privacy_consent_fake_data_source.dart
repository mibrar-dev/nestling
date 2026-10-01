import 'package:nestling/features/privacy_consent/data/models/consent_option_model.dart';

class PrivacyConsentFakeDataSource {
  const new();

  List<ConsentOptionModel> getItems() {
    return const <ConsentOptionModel>[
      ConsentOptionModel(
        id: 'privacy-ads',
        title: 'No ads or tracking',
        detail: 'Children only need a nickname',
      ),
      ConsentOptionModel(
        id: 'privacy-data',
        title: 'Data stored in the UK',
        detail: 'Delete everything anytime',
      ),
    ];
  }
}
