import 'package:nestling/features/onboarding/domain/entities/onboarding_step.dart';

/// Onboarding flow (P01–P07), backed by Drift. The tour cards are static;
/// progress lives in `app_state` (the router reads it for redirects).
abstract class OnboardingRepository {
  Future<List<OnboardingStep>> getItems();
  Stream<List<OnboardingStep>> watchItems();

  Stream<bool> watchComplete();
  Future<void> completeOnboarding();
}
