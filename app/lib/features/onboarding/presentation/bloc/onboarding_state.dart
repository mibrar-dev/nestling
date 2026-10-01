import 'package:equatable/equatable.dart';
import 'package:nestling/features/onboarding/domain/entities/onboarding_step.dart';

enum OnboardingStatus { initial, loading, loaded, failure }

final class OnboardingState extends Equatable {
  const new({
    this.status = OnboardingStatus.initial,
    this.items = const <OnboardingStep>[],
    this.errorMessage,
  });

  final OnboardingStatus status;
  final List<OnboardingStep> items;
  final String? errorMessage;

  OnboardingState copyWith({
    OnboardingStatus? status,
    List<OnboardingStep>? items,
    String? errorMessage,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => <Object?>[status, items, errorMessage];
}
