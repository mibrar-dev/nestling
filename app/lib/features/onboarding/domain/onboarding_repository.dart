import 'package:nestling/features/onboarding/domain/entities/onboarding_step.dart';

abstract class OnboardingRepository {
  Future<List<OnboardingStep>> getItems();
}
