import 'package:equatable/equatable.dart';

sealed class OnboardingEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => <Object?>[];
}

final class OnboardingLoadRequested extends OnboardingEvent {
  const new();
}
