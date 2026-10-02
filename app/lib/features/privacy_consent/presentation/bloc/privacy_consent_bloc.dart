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
      if (item.id == ConsentOptionIds.crash) return item.enabled;
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
        errorMessage: null,
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
    // Optimistic: the switch must answer instantly and a second tap must
    // read the new value, not the pre-round-trip one (P04-5). Writes start
    // in tap order on one event loop and the `watchItems` stream re-emits
    // after each, so the last tap wins and the stream reconciles; bloc
    // dedupes the identical state.
    final previous = state.crashConsent;
    emit(state.copyWith(crashConsent: event.value));
    try {
      await _repository.setCrashConsent(consent: event.value);
    } on Object catch (error) {
      emit(
        state.copyWith(
          status: PrivacyConsentStatus.failure,
          crashConsent: previous,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
