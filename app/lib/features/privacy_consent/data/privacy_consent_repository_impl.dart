import 'package:nestling/features/privacy_consent/data/privacy_consent_fake_data_source.dart';
import 'package:nestling/features/privacy_consent/domain/entities/consent_option.dart';
import 'package:nestling/features/privacy_consent/domain/privacy_consent_repository.dart';

class PrivacyConsentRepositoryImpl implements PrivacyConsentRepository {
  const new({required this._dataSource});

  final PrivacyConsentFakeDataSource _dataSource;

  @override
  Future<List<ConsentOption>> getItems() {
    return Future.value(_dataSource.getItems());
  }
}
