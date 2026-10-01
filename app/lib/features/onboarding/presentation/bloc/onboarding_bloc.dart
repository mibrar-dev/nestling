import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/onboarding/domain/entities/onboarding_step.dart';
import 'package:nestling/features/onboarding/domain/onboarding_repository.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:nestling/features/onboarding/presentation/bloc/onboarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  new({required this._repository}) : super(const OnboardingState()) {
    on<OnboardingLoadRequested>(_onLoadRequested);
  }

  final OnboardingRepository _repository;

  Future<void> _onLoadRequested(
    OnboardingLoadRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(state.copyWith(status: OnboardingStatus.loading));
    await emit.forEach<List<OnboardingStep>>(
      _repository.watchItems(),
      onData: (items) =>
          state.copyWith(status: OnboardingStatus.loaded, items: items),
      onError: (error, _) => state.copyWith(
        status: OnboardingStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }
}
