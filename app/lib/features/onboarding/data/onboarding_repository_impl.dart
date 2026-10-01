import 'package:nestling/features/onboarding/data/onboarding_fake_data_source.dart';
import 'package:nestling/features/onboarding/domain/entities/onboarding_step.dart';
import 'package:nestling/features/onboarding/domain/onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  const new({required this._dataSource});

  final OnboardingFakeDataSource _dataSource;

  @override
  Future<List<OnboardingStep>> getItems() {
    return Future.value(_dataSource.getItems());
  }
}
