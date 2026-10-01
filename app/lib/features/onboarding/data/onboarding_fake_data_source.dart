import 'package:nestling/features/onboarding/data/models/onboarding_step_model.dart';

class OnboardingFakeDataSource {
  const new();

  List<OnboardingStepModel> getItems() {
    return const <OnboardingStepModel>[
      OnboardingStepModel(
        id: 'onboarding-1',
        title: 'Chores that feel like a game',
        detail: 'Sarah sets quests for Maya 9 and Leo 6',
      ),
      OnboardingStepModel(
        id: 'onboarding-2',
        title: 'Pip grows as they help',
        detail: 'Biscuit the cat cheers the nest on',
      ),
    ];
  }
}
