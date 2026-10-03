import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/paywall/domain/entities/paywall_plan.dart';
import 'package:nestling/features/paywall/domain/paywall_repository.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_event.dart';
import 'package:nestling/features/paywall/presentation/bloc/paywall_state.dart';

class PaywallBloc extends Bloc<PaywallEvent, PaywallState> {
  new({required this._repository}) : super(const PaywallState()) {
    on<PaywallLoadRequested>(_onLoadRequested);
    on<PaywallTrialStarted>(_onTrialStarted);
    on<PaywallRestoreRequested>(_onRestoreRequested);
  }

  final PaywallRepository _repository;

  Future<void> _onLoadRequested(
    PaywallLoadRequested event,
    Emitter<PaywallState> emit,
  ) async {
    emit(state.copyWith(status: PaywallStatus.loading, clearError: true));
    await emit.forEach<List<PaywallPlan>>(
      _repository.watchItems(),
      onData: (items) => state.copyWith(
        status: PaywallStatus.loaded,
        items: items,
        clearError: true,
      ),
      onError: (error, _) => state.copyWith(
        status: PaywallStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onTrialStarted(
    PaywallTrialStarted event,
    Emitter<PaywallState> emit,
  ) async {
    // A second tap while the first request is still in flight is a no-op;
    // the view also disables the CTA while `action == working`.
    if (state.action == PaywallAction.working) return;
    emit(
      state.copyWith(
        action: PaywallAction.working,
        request: PaywallRequest.trial,
        clearError: true,
      ),
    );
    try {
      // P07-BUG-12: `/paywall` stays reachable for an onboarded app, so a
      // paying subscriber can tap the trial CTA. `startTrial()` (and the
      // view's `startTrialNow()`) would overwrite `active` with `trial` and
      // move `trial_start`. An already-active subscription is therefore
      // treated as "already subscribed": the repository write is skipped and
      // success is reported with `request: restore`, so the view takes its
      // restore branch (`setSubscription('active')` — a no-op here — +
      // `completeOnboarding()` → `/today`) instead of the trial branch.
      if (await _alreadySubscribed()) {
        emit(
          state.copyWith(
            action: PaywallAction.success,
            request: PaywallRequest.restore,
          ),
        );
        return;
      }
      await _repository.startTrial();
      emit(
        state.copyWith(
          action: PaywallAction.success,
          request: PaywallRequest.trial,
        ),
      );
    } on Object catch (error) {
      emit(
        state.copyWith(
          action: PaywallAction.failure,
          request: PaywallRequest.trial,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  /// Whether the family already pays. Read with the one-shot
  /// [PaywallRepository.readSubscription] (a fresh watch subscription never
  /// resolves inside a widget test). Fail-open: when the subscription
  /// cannot be read, the trial is attempted exactly as before this guard
  /// existed.
  Future<bool> _alreadySubscribed() async {
    try {
      final subscription = await _repository.readSubscription();
      return subscription.status == 'active';
    } on Object {
      return false;
    }
  }

  Future<void> _onRestoreRequested(
    PaywallRestoreRequested event,
    Emitter<PaywallState> emit,
  ) async {
    if (state.action == PaywallAction.working) return;
    emit(
      state.copyWith(
        action: PaywallAction.working,
        request: PaywallRequest.restore,
        clearError: true,
      ),
    );
    try {
      await _repository.activate();
      emit(
        state.copyWith(
          action: PaywallAction.success,
          request: PaywallRequest.restore,
        ),
      );
    } on Object catch (error) {
      emit(
        state.copyWith(
          action: PaywallAction.failure,
          request: PaywallRequest.restore,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
