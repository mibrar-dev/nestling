import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nestling/features/privacy_consent/domain/entities/consent_option.dart';
import 'package:nestling/features/privacy_consent/domain/privacy_consent_repository.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_event.dart';
import 'package:nestling/features/privacy_consent/presentation/bloc/privacy_consent_state.dart';

class PrivacyConsentBloc
    extends Bloc<PrivacyConsentEvent, PrivacyConsentState> {
  new({required this._repository}) : super(const PrivacyConsentState()) {
    on<PrivacyConsentLoadRequested>(_onLoadRequested);
    on<PrivacyConsentCrashToggled>(_onCrashToggled);
  }

  final PrivacyConsentRepository _repository;

  static bool _crashFrom(List<ConsentOption> items) {
    for (final item in items) {
      if (item.id == 'crash') return item.enabled;
    }
    return false;
  }

  Future<void> _onLoadRequested(
    PrivacyConsentLoadRequested event,
    Emitter<PrivacyConsentState> emit,
  ) async {
    emit(state.copyWith(status: PrivacyConsentStatus.loading));
    await emit.forEach<List<ConsentOption>>(
      _repository.watchItems(),
      onData: (items) => state.copyWith(
        status: PrivacyConsentStatus.loaded,
        items: items,
        crashConsent: _crashFrom(items),
      ),
      onError: (error, _) => state.copyWith(
        status: PrivacyConsentStatus.failure,
        errorMessage: error.toString(),
      ),
    );
  }

  Future<void> _onCrashToggled(
    PrivacyConsentCrashToggled event,
    Emitter<PrivacyConsentState> emit,
  ) async {
    try {
      await _repository.setCrashConsent(consent: event.value);
    } on Object catch (error) {
      emit(
        state.copyWith(
          status: PrivacyConsentStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
