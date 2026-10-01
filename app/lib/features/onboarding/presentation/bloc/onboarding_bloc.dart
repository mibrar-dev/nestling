import 'package:flutter_bloc/flutter_bloc.dart';
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
    try {
      final items = await _repository.getItems();
      emit(state.copyWith(status: OnboardingStatus.loaded, items: items));
    } on Exception catch (e) {
      emit(
        state.copyWith(
          status: OnboardingStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
