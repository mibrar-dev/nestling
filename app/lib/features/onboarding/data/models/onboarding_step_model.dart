import 'package:nestling/features/onboarding/domain/entities/onboarding_step.dart';

class OnboardingStepModel extends OnboardingStep {
  const new({required super.id, required super.title, required super.detail});

  factory fromJson(Map<String, dynamic> json) {
    return OnboardingStepModel(
      id: json['id'] as String,
      title: json['title'] as String,
      detail: json['detail'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id, 'title': title, 'detail': detail};
  }
}
